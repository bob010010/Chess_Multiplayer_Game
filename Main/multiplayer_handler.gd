extends Node
class_name MultiplayerHandler

var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new() 
const PORT: int = 8910 

# Stores authoritative usernames mapped to integer peer IDs.
var player_names_dict: Dictionary = {}

@onready var main: Node = get_parent().get_parent()

# Registers a player's cosmetic name and triggers the spawning process on the server.
@rpc("any_peer", "call_local", "reliable")
func register_player_name(username: String) -> void:
	if not multiplayer.is_server():
		return
		
	var sender_id: int = multiplayer.get_remote_sender_id()
	# The technical ID is 1 for the host; handle local calls that might return 0.
	if sender_id == 0:
		sender_id = 1
		
	var final_name: String = username.strip_edges()
	if final_name == "":
		final_name = "Guest_" + str(sender_id)
	
	player_names_dict[sender_id] = final_name
	
	# Clients are spawned only after their name is authoritatively registered.
	if sender_id != 1:
		main.get_node("SpawnedPlayers").add_player(sender_id)

# Attempts to automatically forward the game port on the host's router.
func setup_upnp() -> void:
	var upnp: UPNP = UPNP.new()
	
	# Ask the network to find the local router (This will be blocked by many networks)
	var discover_result: int = upnp.discover()
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP Discover Failed! Error: %s" % discover_result)
		main.ip_label.text = "UPNP Discover Failed! Error: %s" % discover_result
		return

	# Verify the router is a valid gateway that accepts commands
	if not upnp.get_gateway() or not upnp.get_gateway().is_valid_gateway():
		print("UPNP Invalid Gateway!")
		main.ip_label.text = "UPNP Invalid Gateway!"
		return

	# Ask the router to open the UDP port (ENet uses UDP)
	var map_result: int = upnp.add_port_mapping(PORT, PORT, "My Godot Game", "UDP")
	if map_result != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP Port Mapping Failed! Error: %s" % map_result)
		main.ip_label.text = "UPNP Port Mapping Failed! Error: %s" % map_result
		return
		
	# Prints the public IP so the host can share it
	print("UPNP Success! Port %s is open." % PORT)
	print("Your public IP to give to friends is: %s" % upnp.query_external_address())
	main.ip_label.text = "Your public IP to give to friends is: %s" % upnp.query_external_address()
	
	main.ip_label.show()

# Initiates the server and spawns the host player
func host_game() -> void:
	peer.create_server(PORT) 
	multiplayer.multiplayer_peer = peer
		
	var username: String = main.get_node("TitleScreen/JoinPanel/UsernameInput").text
	register_player_name(username)
	
	# Set up the game
	main.setup_handler._apply_preset_or_custom()
	main.get_node("TitleScreen").hide()
	main.setup_handler._create_boundaries()
	main.get_node("Tiles").size = Vector2(main.setup_handler.arena_size, main.setup_handler.arena_size)
	main.get_node("Tiles").position = Vector2(-main.setup_handler.arena_size/2, -main.setup_handler.arena_size/2)
	main.is_hosting = true	
	new_player_joined()
	
	# Spawn the host
	main.get_node("SpawnedPlayers").add_player(1)

# Attempts to connect to a server IP
func join_game() -> void:
	var username: String = main.get_node("TitleScreen/JoinPanel/UsernameInput").text
	var ip_to_join: String = main.get_node("TitleScreen/JoinPanel/InputIP").text
	if ip_to_join == "":
		ip_to_join = "127.0.0.1"
		
	peer.create_client(ip_to_join, PORT)
	multiplayer.multiplayer_peer = peer

	multiplayer.connected_to_server.connect(func() -> void:
		register_player_name.rpc_id(1, username)
		new_player_joined()
	)
	
	main.get_node("TitleScreen").hide()

# Increases the food and bots supply when a new player joins
func new_player_joined() -> void:
	main.setup_handler.max_food += main.setup_handler.food_per_player
	main.setup_handler.max_bots += main.setup_handler.bots_per_player
