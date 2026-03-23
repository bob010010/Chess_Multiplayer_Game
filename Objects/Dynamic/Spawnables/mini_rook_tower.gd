extends StaticBody2D

@export var detection_radius: float = 400.0
var owner_peer_id: String = ""
var team_id: int = -1 

@onready var detection_area: Area2D = $Area2D
@onready var ranged_weapon: Node = $Components/BowComponent 
@onready var health_component: Node = $Components/HealthComponent

# Sets the initial identity and team data
func initialize(creator_id: String, creator_team: int) -> void:
	owner_peer_id = creator_id
	team_id = creator_team
	
	if not health_component.died.is_connected(on_tower_died):
		health_component.died.connect(on_tower_died)
	
	health_component.max_health = 100
	health_component.health = 100
	health_component.healing = false
	health_component.decaying = true
	health_component.decay_amount = 1
	health_component.decay_speed = 2.0
	health_component.decay_cooldown = 2.0
	
	apply_team_color()

# Processes targeting on the server and triggers visual updates on clients when data is synchronized.
func _process(_delta: float) -> void:
	if not multiplayer.is_server():
		# Updates the color only once the synchronized team_id arrives from the server.
		if team_id != -1 and $Sprite2D.modulate == Color(1.0, 1.0, 1.0, 1.0):
			apply_team_color()
		return
		
	var target: Node2D = _get_closest_target()
	if target and ranged_weapon and ranged_weapon.shot_cooldown <= 0.0:
		var direction: Vector2 = global_position.direction_to(target.global_position)
		ranged_weapon.shoot(global_position + direction)

# Triggered when health hits 0 to clean up the entity.
func on_tower_died(_attacker_id: String) -> void:
	queue_free()

# Colors the tower based on whether the local client shares the tower's team affiliation.
func apply_team_color() -> void:
	var local_id: String = str(multiplayer.get_unique_id())
	var local_player: Node2D = get_tree().current_scene.find_child(local_id, true, false) as Node2D
	
	if local_player and "team_id" in local_player:
		if self.team_id == local_player.get("team_id"):
			$Sprite2D.modulate = Color(0.0, 1.0, 0.0)
		else:
			$Sprite2D.modulate = Color(1.0, 0.0, 0.0)

# Identifies the nearest valid enemy target within the detection radius.
func _get_closest_target() -> Node2D:
	var closest: Node2D = null
	var min_dist: float = INF
	
	for body: Node2D in detection_area.get_overlapping_bodies():
		if body is CharacterBody2D and "team_id" in body:
			if body.get("team_id") != team_id: 
				var dist: float = global_position.distance_to(body.global_position)
				if dist < min_dist:
					min_dist = dist
					closest = body
					
	return closest
