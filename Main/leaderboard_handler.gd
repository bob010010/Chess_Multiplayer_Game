extends Node
class_name LeaderboardHandler

var leaderboard_timer: float = 0.0

@onready var main: Node = get_parent().get_parent()

# Handles the timing for leaderboard updates on the server.
func _process(delta: float) -> void:
	if multiplayer.is_server():
		leaderboard_timer -= delta
		if leaderboard_timer <= 0.0:
			leaderboard_timer = 1.0 # Update the leaderboard every 1 second and broadcasts to players
			broadcast_leaderboard()

# Gathers all active players, sorts them by total score, and broadcasts the list.
func broadcast_leaderboard() -> void:
	var scores: Array = []
	
	for player: CharacterBody2D in main.get_node("SpawnedPlayers").get_children():
		if not is_instance_valid(player) or player.is_queued_for_deletion():
			continue
		var leveling_comp: Node = player.get_node_or_null("Components/LevelingComponent")
		if leveling_comp:
			scores.append({"id": player.player_username, "score": leveling_comp.total_score, "team_id": player.team_id})
	
	for npc: Node in main.get_node("SpawnedNPCs").get_children():
		if not is_instance_valid(npc) or npc.is_queued_for_deletion():
			continue
		var leveling_comp: Node = npc.get_node_or_null("Components/LevelingComponent")
		if leveling_comp:
			scores.append({"id": npc.name, "score": leveling_comp.total_score, "team_id": npc.team_id})
	
	scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
	
	var lb_data_slice: Array = []
	for i: int in range(min(scores.size(), 10)):
		lb_data_slice.append(scores[i])
		
	update_leaderboard_rpc.rpc(lb_data_slice)

# Sends the leaderboard list to players
@rpc("authority", "call_local", "unreliable")
func update_leaderboard_rpc(leaderboard_data: Array) -> void:
	var local_id: String = str(multiplayer.get_unique_id())
	var local_player: Node = main.get_node("SpawnedPlayers").get_node_or_null(local_id)
	
	if local_player:
		var ui_comp: Node = local_player.get_node_or_null("UIComponent")
		if ui_comp and ui_comp.has_method("update_leaderboard_ui"):
			ui_comp.update_leaderboard_ui(leaderboard_data)
