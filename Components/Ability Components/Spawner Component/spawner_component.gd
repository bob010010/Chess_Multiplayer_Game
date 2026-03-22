# Components/Ability Components/spawner_component.gd
extends Node2D
class_name SpawnerComponent

@export var max_cooldown: float = 15.0
var current_cooldown: float = 0.0
@export var max_spawns: int = 2

@onready var player: CharacterBody2D = get_parent().get_parent() as CharacterBody2D

var tower_scene: PackedScene = preload("res://Objects/Dynamic/Spawnables/mini_rook_tower.tscn")
var active_towers: Array[Node2D] = []

func _process(delta: float) -> void:
	if multiplayer.is_server() and current_cooldown > 0.0:
		current_cooldown -= delta

@rpc("any_peer", "call_local", "reliable")
func request_spawn(spawn_pos: Vector2) -> void:
	if not multiplayer.is_server():
		return
		
	_cleanup_dead_towers()
	
	if current_cooldown <= 0.0 and active_towers.size() < max_spawns:
		current_cooldown = max_cooldown
		
		var info_label: Node = player.get_node_or_null("HUD/InfoLabel")
		if info_label:
			info_label.display_message.rpc_id(player.name.to_int(), "Ability Used: Spawn Tower")
			
		trigger_tower_spawn.rpc(spawn_pos, player.name, player.team_id)

@rpc("authority", "call_local", "reliable")
func trigger_tower_spawn(spawn_pos: Vector2, owner_id: String, team: int) -> void:
	var main_scene: Node = get_tree().current_scene
	if not main_scene:
		return
		
	var tower: Node2D = tower_scene.instantiate()
	tower.global_position = spawn_pos
	
	main_scene.add_child(tower)
	
	if tower.has_method("initialize"):
		tower.initialize(owner_id, team)
		
	active_towers.append(tower)

# Cleans up the array so players can spawn more if old ones were destroyed
func _cleanup_dead_towers() -> void:
	for i in range(active_towers.size() - 1, -1, -1):
		if not is_instance_valid(active_towers[i]):
			active_towers.remove_at(i)
