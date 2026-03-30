extends Node2D

@onready var entity: CharacterBody2D = get_parent().get_parent() as CharacterBody2D

@export var max_cooldown: float = 15.0
var current_cooldown: float = 0.0

var start_pos: Vector2
var end_pos: Vector2

var active_walls: Array[Node2D] = []

func _process(delta: float) -> void:
	if multiplayer.is_server() and current_cooldown > 0.0:
		current_cooldown -= delta

# Starts the ability and requests the wall of fire
@rpc("any_peer", "call_local", "reliable")
func request_wof(input_pos: Vector2) -> void:
	if multiplayer.is_server() and current_cooldown <= 0.0 and AbilityUtils.is_position_within_map(get_tree().current_scene, start_pos):
		start_pos = input_pos

		entity.input_needed = true
		
		var ui_comp: Node = entity.get_node_or_null("UIComponent")
		if ui_comp and entity.is_in_group("player"):
			ui_comp.display_message.rpc_id(entity.name.to_int(), "Used Wall of Fire!")

@rpc("any_peer", "call_local", "reliable")
func request_second_pos(input_pos: Vector2) -> void:
	if multiplayer.is_server() and current_cooldown <= 0.0 and AbilityUtils.is_position_within_map(get_tree().current_scene, start_pos):
		end_pos = input_pos
		current_cooldown = max_cooldown

		entity.input_needed = false
		
		var ui_comp: Node = entity.get_node_or_null("UIComponent")
		if ui_comp and entity.is_in_group("player"):
			ui_comp.display_message.rpc_id(entity.name.to_int(), "Starting the wall of fire!")
			
		var trap_manager: Node = get_tree().current_scene.get_node_or_null("SpawnedTraps")
		
		if trap_manager and trap_manager.has_method("spawn_wof"):
			current_cooldown = max_cooldown
			
			var new_wall: Node2D = trap_manager.spawn_wof(start_pos, end_pos, entity.name, entity.team_id)
			if new_wall:
				active_walls.append(new_wall)

func _draw() -> void:
	draw_line(start_pos, end_pos, Color(0, 0, 1, 1), 5)
