extends Node2D

@export var player_scene: PackedScene = preload("res://Objects/Dynamic/Player/player.tscn")


func add_player(id: int, start_score: int = 0) -> void:
	var player_instance: CharacterBody2D = player_scene.instantiate() as CharacterBody2D
	player_instance.name = str(id) 
	
	var random_x: float = randf_range(-(owner.arena_size/2 - 50), (owner.arena_size/2 - 50))
	var random_y: float = randf_range(-(owner.arena_size/2 - 50), (owner.arena_size/2 - 50))
	player_instance.position = Vector2(random_x, random_y)
	
	match owner.game_type:
		"FFA":
			player_instance.team_id = 1 if id == 1 else get_child_count() + 1
		"2_Teams":
			player_instance.team_id = 1 if id == 1 else (get_child_count() % 2) + 1

	
	add_child(player_instance, true)
	
	if start_score != 0:
		get_tree().create_timer(1.0).timeout.connect(func(): give_player_points_on_start(player_instance, start_score))

	if owner != null:
		owner.max_food = get_child_count() * owner.food_per_player
		owner.max_bots = get_child_count() * owner.bots_per_player

func give_player_points_on_start(player: Node2D, points: int):
	var level_comp: Node2D = player.get_node_or_null("Components/LevelingComponent")
	level_comp.get_points(points)
