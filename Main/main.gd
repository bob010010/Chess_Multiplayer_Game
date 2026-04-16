extends Node2D

@export var is_hosting: bool = false # Remove this?

var spectate_target: Node2D = null
var respawn_timer: float = 0.0
@onready var spectator_camera: Camera2D = $SpectatorCamera
@onready var respawn_button: Button = $RespawnLayer/RespawnPanel/RespawnButton
@onready var respawn_label: Label = $RespawnLayer/RespawnPanel/RespawnTimerLabel

@onready var ip_label: Label = $OverlayLayer/SharingIPLabel

@onready var setup_handler: GameSetupHandler = $Handlers/GameSetupHandler
@onready var player_handler: PlayerHandler = $Handlers/PlayerHandler
@onready var leaderboard_handler: LeaderboardHandler = $Handlers/LeaderboardHandler
@onready var multiplayer_handler: MultiplayerHandler = $Handlers/MultiplayerHandler

# Connects buttons and initializes the game boundary
func _ready() -> void:
	$TitleScreen/HostPanel/HostButton.pressed.connect(_on_host_pressed)
	$TitleScreen/HostPanel/HostOPButton.pressed.connect(_on_host_OP_pressed)
	$TitleScreen/JoinPanel/JoinButton.pressed.connect(_on_join_pressed)
	respawn_button.pressed.connect(_on_respawn_pressed)
	$RespawnLayer.hide()
	ip_label.hide()

# Handles the countdown timer and smoothly pans the spectator camera to the killer.
func _process(delta: float) -> void:
	# Lerp camera to target if it exists and hasn't disconnected/died
	if spectate_target and is_instance_valid(spectate_target) and spectate_target.is_inside_tree():
		spectator_camera.global_position = spectator_camera.global_position.lerp(spectate_target.global_position, delta * 5.0)
		
	# Handle the countdown sequence
	if respawn_timer > 0.0:
		respawn_timer -= delta
		respawn_label.text = "Respawning in: " + str(ceil(respawn_timer)) + "s"
		
		if respawn_timer <= 0.0:
			respawn_label.hide()
			respawn_button.show()

# Records player death data by routing the request to the player handler.
func player_died(player_id: String, player_score: int, killer_id: String) -> void:
	player_handler.player_died(player_id, player_score, killer_id)

# Commands the local client's UI and camera to enter the spectate phase.
@rpc("authority", "call_local", "reliable")
func start_spectating(killer_id: String) -> void:
	$RespawnLayer.show()
	respawn_button.hide()
	respawn_label.show()
	respawn_timer = 4.0
	
	# Swap the active camera to the main scene's spectator camera
	spectator_camera.enabled = true
	spectator_camera.make_current()

	# Attempt to find the killer. If environmental or missing, the camera stays where the player died.
	if killer_id != "":
		var killer_node: Node2D = $SpawnedPlayers.get_node_or_null(killer_id)
		if not killer_node:
			killer_node = $SpawnedNPCs.get_node_or_null(killer_id)
		if not killer_node:
			var npcs_to_spectate: Array = $SpawnedNPCs.get_children()
			if npcs_to_spectate.size() <= 0:
				printerr("No one to specate")
			else:
				killer_node = npcs_to_spectate[0]
		if killer_node:
			spectate_target = killer_node
			# Snap the camera to the killer immediately so it doesn't drag across the entire map
			spectator_camera.global_position = spectate_target.global_position

# Hides the button locally and asks the server for a new body.
func _on_respawn_pressed() -> void:
	spectate_target = null
	respawn_button.hide()
	$RespawnLayer.hide()
	player_handler.request_respawn.rpc_id(1)

func _on_host_OP_pressed() -> void:
	# Run the UPNP port forwarding before starting the server
	multiplayer_handler.setup_upnp()
	multiplayer_handler.host_game()

# Initiates the server and spawns the host player
func _on_host_pressed() -> void:
	multiplayer_handler.host_game()

# Attempts to connect to a server IP
func _on_join_pressed() -> void:
	multiplayer_handler.join_game()
