extends Node2D

@export var move_speed: int = 100
var input_dir: Vector2 = Vector2.ZERO
var movement_blocked: bool = false
var steering_offset: Vector2 = Vector2.ZERO

@onready var player: Node = get_parent().get_parent()

# Changes the input for movement (server side) after a client requests it
@rpc("any_peer", "call_remote", "unreliable")
func receive_input(dir: Vector2) -> void:
	if multiplayer.is_server():
		# Security: Ensure the client is only moving their own parent node
		if str(multiplayer.get_remote_sender_id()) == player.name:
			input_dir = dir

# The parent player script will call this to get the final maths
func get_movement_velocity() -> Vector2:
	return input_dir * move_speed

# Processes the movement direction received from either player input or AI logic.
func set_movement_direction(dir: Vector2) -> void:
	if movement_blocked:
		return
	
	input_dir = (dir + steering_offset).normalized()

	if dir != Vector2.ZERO:
		var looking_area: Node2D = player.get_node_or_null("LookingArea")
		if is_instance_valid(looking_area):
			looking_area.rotation = dir.angle()
