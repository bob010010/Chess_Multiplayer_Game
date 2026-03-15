extends Node2D

@export var player_scene: PackedScene = preload("res://player.tscn")

const food_per_player: int = 500

func add_player(id):
	var player_instance = player_scene.instantiate()
	player_instance.name = str(id) 
	
	var random_x = randf_range(-2000, 2000)
	var random_y = randf_range(-2000, 2000)
	player_instance.position = Vector2(random_x, random_y)
	
	add_child(player_instance, true)
	
	# Update the max_food variable stored on the Main node
	if owner != null:
		owner.max_food = get_child_count() * food_per_player
