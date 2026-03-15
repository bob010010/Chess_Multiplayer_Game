extends Node2D

var peer = ENetMultiplayerPeer.new()

# These are our shared variables that the child spawners read/write
@export var max_food = 0
@export var is_hosting: bool = false 

func _ready():
	$CanvasLayer/HostButton.pressed.connect(_on_host_pressed)
	$CanvasLayer/JoinButton.pressed.connect(_on_join_pressed)
	_create_boundaries()

func _create_boundaries():
	var boundary_body = StaticBody2D.new()
	boundary_body.add_to_group("boundary")
	
	var rects = [
		Rect2(-2550, -2550, 5100, 50),
		Rect2(-2550, 2500, 5100, 50),  
		Rect2(-2550, -2500, 50, 5000), 
		Rect2(2500, -2500, 50, 5000)   
	]
	
	for rect in rects:
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		collision.position = rect.position + (rect.size / 2.0)
		boundary_body.add_child(collision)
		
	add_child(boundary_body)
	
func _on_host_pressed():
	peer.create_server(135)
	multiplayer.multiplayer_peer = peer
	
	# Tell the SpawnedPlayers node to handle new connections
	multiplayer.peer_connected.connect($SpawnedPlayers.add_player)
	
	# Tell the SpawnedPlayers node to add the host
	$SpawnedPlayers.add_player(multiplayer.get_unique_id())
	
	$CanvasLayer.hide()
	is_hosting = true 

func _on_join_pressed():
	peer.create_client("127.0.0.1", 135)
	multiplayer.multiplayer_peer = peer
	$CanvasLayer.hide()
