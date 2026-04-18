extends Node2D

@export var player_scene: PackedScene = preload("res://Objects/Dynamic/Player/player.tscn")

@onready var main: Main = get_parent()

# Instantiates a player node using the technical peer ID as its unique name.
func add_player(id: int, start_score: int = 0) -> void:
	var player_instance: CharacterBody2D = player_scene.instantiate() as CharacterBody2D
	player_instance.name = str(id) 
	
	# Retrieves the cosmetic name from the registry and applies it to the instance.
	if owner.multiplayer_handler.player_names_dict.has(id):
		player_instance.player_username = owner.multiplayer_handler.player_names_dict[id]
	else:
		player_instance.player_username = "Guest_" + str(id)
	
	var arena_half: float = owner.setup_handler.arena_size / 2.0 - 50.0
	player_instance.global_position = Vector2(randf_range(-arena_half, arena_half), randf_range(-arena_half, arena_half))
	
	if not AbilityUtils.is_position_within_map(get_tree().current_scene, player_instance.global_position):
		printerr("Outside map")
		return
	
	if start_score > 0: # Gives the player score when they start
		player_instance.ready.connect(func() -> void: _apply_start_score(player_instance, start_score))
	
	player_instance.ready.connect(func() -> void: apply_spawn_immunity(player_instance, get_tree().current_scene.setup_handler.spawn_immunity_time))
	
	player_instance.team_id = main.get_team_from_game_type("Player")
	
	#printerr("REAL NAME: " + str(player_instance.name))
	#printerr("Username: " + player_instance.player_username)
	add_child(player_instance, true)

# Grants the previous score back
func _apply_start_score(player: CharacterBody2D, points: int) -> void:
	var level_comp: Node = player.get_node_or_null("Components/LevelingComponent")
	if is_instance_valid(level_comp) and level_comp.has_method("get_points"):
		level_comp.get_points(points)

# Makes the player immune for a while on spawn
func apply_spawn_immunity(player: CharacterBody2D, time: float) -> void:
	var health_comp: Node = player.get_node_or_null("Components/HealthComponent")
	if is_instance_valid(health_comp):
		health_comp.immune = true
		health_comp.immune_time = time
