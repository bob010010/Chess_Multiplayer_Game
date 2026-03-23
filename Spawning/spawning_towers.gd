extends Node2D

@export var tower_scene: PackedScene = preload("res://Objects/Dynamic/Spawnables/mini_rook_tower.tscn")

# Instantiates a tower on the server and configures its initial state for synchronization.
func spawn_tower(spawn_pos: Vector2, owner_id: String, team: int) -> Node2D:
	if not multiplayer.is_server():
		return null
		
	var tower: StaticBody2D = tower_scene.instantiate() as StaticBody2D
	
	# Ensures the node name is unique so the MultiplayerSpawner can track it across peers.
	tower.name = "Tower_" + owner_id + "_" + str(Time.get_ticks_msec())
	tower.global_position = spawn_pos
	
	add_child(tower, true)
	
	if tower.has_method("initialize"):
		tower.initialize(owner_id, team)
		
	return tower
