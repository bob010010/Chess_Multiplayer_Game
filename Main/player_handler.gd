extends Node
class_name PlayerHandler

var dead_scores_dict: Dictionary

@onready var main: Node = get_parent().get_parent()

# Records the player's score on the server and initiates the spectate sequence for the client.
func player_died(player_id: String, player_score: int, killer_id: String) -> void:
	# Records score on the server for the upcoming respawn request.
	if multiplayer.is_server():
		dead_scores_dict[player_id] = player_score
	
	# Commands the local client to initiate spectating.
	main.start_spectating.rpc_id(player_id.to_int(), killer_id)

# Handles the server-side logic for cleaning up the dead body and spawning a new entity with the saved score.
@rpc("any_peer", "call_local", "reliable")
func request_respawn() -> void:
	if not multiplayer.is_server():
		return
		
	var sender_id: int = multiplayer.get_remote_sender_id()
	var player_key: String = str(sender_id)
	var old_player: Node = main.get_node("SpawnedPlayers").get_node_or_null(player_key)
	
	# Renames and frees the old node immediately to start the network deletion process.
	if is_instance_valid(old_player):
		old_player.name = player_key + "_dying_" + str(Time.get_ticks_msec())
		old_player.queue_free()
	
	# Delays the new spawn by a few frames to ensure the MultiplayerSpawner clears the previous node name.
	get_tree().create_timer(0.1).timeout.connect(func() -> void: _execute_respawn_spawn(sender_id))

# Finalizes the respawn by instantiating the new player and restoring their authoritative score.
func _execute_respawn_spawn(id: int) -> void:
	var player_key: String = str(id)
	if dead_scores_dict.has(player_key):
		var previous_score: int = dead_scores_dict[player_key]
		main.get_node("SpawnedPlayers").add_player(id, previous_score)
		dead_scores_dict.erase(player_key)
	else:
		main.get_node("SpawnedPlayers").add_player(id)
