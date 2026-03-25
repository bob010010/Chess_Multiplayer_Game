extends Area2D

@onready var npc: NPC = get_parent()
@onready var move_comp: Node2D
@onready var ai_comp: Node2D

const LAYER_AI_PLAYER_AND_FOOD: int = 1
const LAYER_WORLD_BOUNDARIES: int = 2

var active_obstacles: Dictionary = {}

var steering_power: float = 3.0

# Connects the collision signal on the server
func _ready() -> void:
	move_comp = npc.get_node_or_null("Components/MovementComponent")
	if not move_comp:
		printerr("No movement comp for steering")
	ai_comp = npc.get_node_or_null("Components/AIControllerComponent")
	if not ai_comp:
		printerr("No AI comp for steering")
		
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)

func _physics_process(_delta: float) -> void:
	_recalculate_steering()

func _on_body_entered(body: Node2D) -> void:
	if multiplayer.is_server():
		if body.name != get_parent().name and ai_comp.state != "Chasing": 
			active_obstacles[body] = get_steering_offset(global_position, body.global_position)
			_recalculate_steering()

func _on_body_exited(body: Node2D) -> void:
	active_obstacles.erase(body)
	_recalculate_steering()

func _recalculate_steering() -> void:
	var combined: Vector2 = Vector2.ZERO
	var valid_count: int = 0
	for body in active_obstacles:
		if is_instance_valid(body):
			active_obstacles[body] = get_steering_offset(global_position, body.global_position)
			combined += active_obstacles[body]
			valid_count += 1
	
	if valid_count > 0:
		combined = (combined / valid_count) * steering_power
	
	move_comp.steering_offset = combined

func get_steering_offset(npc_pos: Vector2, body_pos: Vector2) -> Vector2:
	var distance_weight: float = 0.7
	var cross_weight: float = 0.23
	
	var npc_to_body: Vector2 = (npc_pos - body_pos)
	var raw_cross: float = cross(move_comp.input_dir, npc_to_body.normalized())
	var mag: float = min(1.2, cross_weight / max(abs(raw_cross), 0.001))
	var dist: float = npc_to_body.length()
	var max_range: float = 900.0
	var normalized_dist: float = clamp(1.0 - (dist / max_range), 0.0, 1.0)
	var dist_adj: float = clamp(distance_weight * (normalized_dist * normalized_dist), 0.1, 2.0)
	
	#print("Magnitude: " + str(mag))
	#print("Distance adj: " + str(dist_adj))
	
	var offset: Vector2 = Vector2.ZERO
	if raw_cross > 0:
		var left_adjust: Vector2 = Vector2.LEFT * mag * dist_adj
		offset = left_adjust if left_adjust.length_squared() < (Vector2.LEFT * 2).length_squared() else Vector2.LEFT
		#print("Turning Left: " + str(offset.length()))
	elif raw_cross <= 0:
		var right_adjust: Vector2 = Vector2.RIGHT * mag * dist_adj
		offset = right_adjust if right_adjust.length_squared() < (Vector2.RIGHT * 2).length_squared() else Vector2.RIGHT
		#print("Turning Right: " + str(offset.length()))
	
	return offset

# Positive > B is to the left of A
func cross(a: Vector2, b: Vector2) -> float:
	return a.x * b.y - a.y * b.x
