extends StaticBody2D

@export var detection_radius: float = 400.0
var owner_peer_id: String = ""
var team_id: int = -1 

@onready var detection_area: Area2D = $Area2D
@onready var ranged_weapon: Node = $Components/BowComponent 

func initialize(creator_id: String, creator_team: int) -> void:
	owner_peer_id = creator_id
	team_id = creator_team
	
	apply_team_color()
	print(team_id)

# Colors the tower based on whether the local client is on its team
func apply_team_color() -> void:
	var local_id: String = str(multiplayer.get_unique_id())
	print("L: " + local_id)
	var local_player: Node = get_tree().current_scene.find_child(local_id, true, false)
	
	if local_player and "team_id" in local_player:
		if self.team_id == local_player.team_id:
			print("T")
			$Sprite2D.modulate = Color(0, 1, 0)
		else:
			print("NT")
			$Sprite2D.modulate = Color(1, 0, 0)

# Server handles the AI targeting and shooting
func _process(_delta: float) -> void:
	if not multiplayer.is_server():
		return
		
	var target: Node2D = _get_closest_target()
	if target and ranged_weapon and ranged_weapon.shot_cooldown <= 0.0:
		var direction: Vector2 = global_position.direction_to(target.global_position)
		ranged_weapon.request_shoot(direction)

func _get_closest_target() -> Node2D:
	var closest: Node2D = null
	var min_dist: float = INF
	
	for body in detection_area.get_overlapping_bodies():
		if body is CharacterBody2D and "team_id" in body and body.team_id != team_id: 
			var dist: float = global_position.distance_to(body.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = body
				
	return closest
