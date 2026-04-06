extends Node2D

@onready var entity: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
@onready var ui_comp: Node = entity.get_node_or_null("UIComponent")

@export var wof_cooldown: float = 5.0
var current_cooldown: float = 0.0

var start_pos: Vector2
var end_pos: Vector2
var max_length: float = 400
var max_damage: int = 10

var waiting_for_end: bool = false

var active_walls: Array[Node2D] = []

func _process(delta: float) -> void:
	if multiplayer.is_server() and current_cooldown > 0.0:
		current_cooldown -= delta
	if waiting_for_end:
		queue_redraw()

# Starts the ability and shows the range in which to pick a 2nd point
@rpc("any_peer", "call_local", "reliable")
func request_wof(input_pos: Vector2) -> void:
	if not multiplayer.is_server():
		return
		
	if current_cooldown <= 0.0 and AbilityUtils.is_position_within_map(get_tree().current_scene, input_pos):
		var peer_id: int = entity.name.to_int()
		start_pos = input_pos
		# Notifies the specific client to begin drawing the placement radius and lock movement.
		trigger_waiting_for_end_lock.rpc_id(peer_id, true)
		
		if ui_comp and entity.is_in_group("player"):
			ui_comp.display_message.rpc_id(peer_id, "Pick the second point!")

# Gets the second position and spawns the wall
@rpc("any_peer", "call_local", "reliable")
func request_second_pos(input_pos: Vector2) -> void:
	if not multiplayer.is_server():
		return
		
	if current_cooldown <= 0.0 and AbilityUtils.is_position_within_map(get_tree().current_scene, start_pos):
		if start_pos.distance_to(input_pos) > max_length:
			if ui_comp and entity.is_in_group("player"):
				ui_comp.display_message.rpc_id(entity.name.to_int(), "The wall is too long!")
			return
		
		var peer_id: int = entity.name.to_int()
		end_pos = input_pos
		current_cooldown = wof_cooldown
		# Notifies the client to stop drawing and release the movement lock.
		trigger_waiting_for_end_lock.rpc_id(peer_id, false)
		
		if is_instance_valid(ui_comp):
			ui_comp.handle_ability_activated(self, "WOF", wof_cooldown)
			
		var trap_manager: Node = get_tree().current_scene.get_node_or_null("SpawnedTraps")
		if is_instance_valid(trap_manager) and trap_manager.has_method("spawn_wof"):
			var new_wall: Node2D = trap_manager.spawn_wof(start_pos, end_pos, entity.name, entity.team_id)
			if new_wall:
				active_walls.append(new_wall)
				new_wall.set("base_contact_damage", max_damage)

# Synchronizes the waiting state (and entity lock that comes with) and boundary visuals to the owner client.
@rpc("authority", "call_local", "reliable")
func trigger_waiting_for_end_lock(is_active: bool) -> void:
	waiting_for_end = is_active
	entity.input_needed = is_active
	queue_redraw()

# Removes all active walls of fire currently tracked by this component.
func cleanup() -> void:
	for wall: Node2D in active_walls:
		if is_instance_valid(wall):
			wall.queue_free()
	active_walls.clear()

# Renders the placement boundary circle with scale-adjusted dimensions.
func _draw() -> void:
	if waiting_for_end and entity.name == str(multiplayer.get_unique_id()):
		draw_circle(to_local(start_pos), max_length, Color(0.608, 0.0, 0.0, 0.341), false, 6.0)
