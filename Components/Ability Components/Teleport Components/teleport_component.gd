extends Node2D
class_name TeleportComponent

@export var max_range: float = 50.0:
	set(value):
		max_range = value
		queue_redraw()

var teleport_cooldown: float = 5.0
var current_cooldown: float = 0.0
var teleport_time: float = 1.0

@onready var entity: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
@onready var move_comp: Node2D = entity.get_node("Components/MovementComponent")
@onready var ui_comp: Node2D = entity.get_node("UIComponent")

var active_illusion: Node2D = null
var active_tween_sprite: Tween
var active_tween_components: Tween

# Initializes the component and refreshes the visual range indicator.
func _ready() -> void:
	queue_redraw()

# Manages the reduction of the active cooldown timer on the server.
func _process(delta: float) -> void:
	if multiplayer.is_server() and current_cooldown > 0.0:
		current_cooldown -= delta

# Validates the teleportation request and checks arena boundaries before execution.
@rpc("any_peer", "call_local", "reliable")
func request_teleport(target_pos: Vector2) -> void:
	if not multiplayer.is_server() or current_cooldown > 0.0:
		return
		
	if not AbilityUtils.is_position_within_map(get_tree().current_scene, target_pos):
		if is_instance_valid(ui_comp) and entity.is_in_group("player"):
			ui_comp.display_message.rpc_id(entity.name.to_int(), "Naughty Naughty, Cant teleport outside the arena")
		return
		
	if is_instance_valid(ui_comp) and entity.is_in_group("player"):
		ui_comp.handle_ability_activated(self, "Teleport", get_cooldown_duration() + teleport_time)
		
	_perform_teleport(target_pos)

# Calculates the destination and manages the physical relocation and movement lockout.
func _perform_teleport(target_pos: Vector2) -> void:
	var start_pos: Vector2 = entity.global_position
	var direction: Vector2 = start_pos.direction_to(target_pos)
	var distance: float = minf(start_pos.distance_to(target_pos), max_range)
	var final_position: Vector2 = start_pos + (direction * distance)
	
	move_comp.movement_blocked = true
	current_cooldown = get_cooldown_duration() + teleport_time
	
	trigger_teleport_visuals.rpc(true, final_position) 
	await get_tree().create_timer(teleport_time + 0.1).timeout
	
	if is_instance_valid(entity):
		entity.global_position = final_position
		trigger_teleport_visuals.rpc(false, final_position) 
		_on_teleport_finished()
		move_comp.movement_blocked = false

# Provides a virtual hook for the specific cooldown variable used by the leveling system.
func get_cooldown_duration() -> float:
	return teleport_cooldown

# Serves as a virtual hook for arrival effects in inherited classes.
func _on_teleport_finished() -> void:
	pass

# Controls the scaling animations and destination illusions across all clients.
@rpc("authority", "call_local", "reliable")
func trigger_teleport_visuals(going_out: bool, target_pos: Vector2 = Vector2.ZERO) -> void:
	var sprite: Sprite2D = entity.get_node_or_null("SpriteComponent") as Sprite2D
	var components: Node2D = entity.get_node_or_null("Components") as Node2D
	if not sprite or not components:
		return

	if active_tween_sprite and active_tween_sprite.is_valid():
		active_tween_sprite.kill()
	if active_tween_components and active_tween_components.is_valid():
		active_tween_components.kill()
		
	if going_out:
		active_tween_sprite = create_tween()
		active_tween_components = create_tween() 
		active_tween_sprite.tween_property(sprite, "scale", Vector2(0.1, 0.1), teleport_time).from(Vector2(1.5, 1.5))
		active_tween_components.tween_property(components, "scale", Vector2(0.1, 0.1), teleport_time).from(Vector2(1.0, 1.0))
		_spawn_teleport_illusion(target_pos)
	else:
		sprite.scale = Vector2(1.5, 1.5)
		components.scale = Vector2(1.0, 1.0)
		if is_instance_valid(active_illusion):
			active_illusion.queue_free()

# Creates a temporary visual copy of the entity and its equipment at the teleport target.
func _spawn_teleport_illusion(spawn_pos: Vector2) -> void:
	var main_scene: Node = get_tree().current_scene
	if not main_scene or is_instance_valid(active_illusion):
		if is_instance_valid(active_illusion): active_illusion.queue_free()

	active_illusion = Node2D.new()
	active_illusion.global_position = spawn_pos
	main_scene.add_child(active_illusion)
	
	var entity_sprite: Sprite2D = entity.get_node_or_null("SpriteComponent") as Sprite2D
	if entity_sprite:
		var sprite_dup: Sprite2D = entity_sprite.duplicate(0) as Sprite2D
		sprite_dup.scale = Vector2(0.1, 0.1)
		AbilityUtils.strip_physics_and_scripts(sprite_dup)
		active_illusion.add_child(sprite_dup)
		create_tween().bind_node(active_illusion).tween_property(sprite_dup, "scale", Vector2(0.3, 0.3), teleport_time)
		
	var comp_container: Node2D = Node2D.new()
	comp_container.name = "Components"
	comp_container.scale = Vector2(0.1, 0.1)
	active_illusion.add_child(comp_container)
	
	var active_comps: Array[Node] = [
		entity.get("melee_w_component"),
		entity.get("ranged_w_component"),
		entity.get("first_ability_component"),
		entity.get("second_ability_component"),
		entity.get("shield_component")
	]
	
	for comp: Node in active_comps:
		if is_instance_valid(comp) and comp.get("visible"):
			var comp_dup: Node = comp.duplicate(0)
			AbilityUtils.strip_physics_and_scripts(comp_dup)
			comp_container.add_child(comp_dup)
			
	create_tween().bind_node(active_illusion).tween_property(comp_container, "scale", Vector2(0.3, 0.3), teleport_time)

# Renders the maximum range boundary scaled to the entity's current size.
func _draw() -> void:
	if entity.name == str(multiplayer.get_unique_id()):
		var draw_radius: float = max_range / entity.scale.x
		draw_arc(Vector2.ZERO, draw_radius, 0.0, TAU, 100, Color(1.0, 0.0, 1.0, 0.5), 2.0 / entity.scale.x)
