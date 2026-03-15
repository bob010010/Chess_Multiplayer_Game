extends CharacterBody2D

const SPEED: int = 300

var input_dir: Vector2 = Vector2.ZERO
var knockback: Vector2 = Vector2.ZERO
var max_health: int = 500
var health: int = 500
var body_damage: int = 0

var shooting: bool = false
var reload_speed: float = 0.2
var shot_cooldown: float = reload_speed
var bullet_speed: int = 500
var bullet_damage: int = 0


func _ready():
	# Color ourselves green and enemies red
	if name == str(multiplayer.get_unique_id()):
		$Sprite2D.modulate = Color(0, 1, 0)
		$Camera2D.make_current()
		$HUD.show()
	else:
		$Sprite2D.modulate = Color(1, 0, 0)
		$HUD.hide()

func _process(_delta):
	# Only update the text on our own screen
	if name == str(multiplayer.get_unique_id()): 
		var health_text = "Health: " + str(health) + "\n"
		var pos_text = "Position: " + str(Vector2(int(position.x), int(position.y))) + "\n"
		var kb_text = "Knockback: " + str(Vector2(int(knockback.x), int(knockback.y))) + "\n"
		var body_dmg_text = "Body Damage: " + str(body_damage) + "\n"
		var bullet_dmg_text = "Bullet Damage: " + str(bullet_damage) + "\n"
		var bullet_speed_text = "Bullet Speed: " + str(bullet_speed) + "\n"
		var shoot_text = "Shooting: " + str(shooting) + "\n"
		var cooldown_text = "Cooldown: " + str(snapped(shot_cooldown, 0.01)) + "\n"
		
		$HUD/StatsLabel.text = health_text + pos_text + kb_text + body_dmg_text + bullet_dmg_text + bullet_speed_text + shoot_text + cooldown_text
		
			
func _physics_process(delta):
	if name == str(multiplayer.get_unique_id()):
		var x = Input.get_axis("move_left", "move_right")
		var y = Input.get_axis("move_up", "move_down")
		var new_dir = Vector2(x, y)
		
		if new_dir.length() > 0:
			new_dir = new_dir.normalized()
		
		if new_dir != input_dir:
			input_dir = new_dir
			if not multiplayer.is_server():
				rpc_id(1, "receive_input", new_dir)

	if multiplayer.is_server():
		knockback = knockback.move_toward(Vector2.ZERO, delta * 1500)
		velocity = (input_dir * SPEED) + knockback
		move_and_slide()

		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			var normal = collision.get_normal()
			
			velocity = Vector2.ZERO
			knockback = normal * 500 #Update here to use damage or size or something
			
			if collider and collider.has_method("apply_bounce"):
				collider.apply_bounce(-normal * 500)
				
				if collider.is_in_group("food"):
					collider.take_damage(body_damage)
					body_damage += 2
					bullet_damage += 2
					bullet_speed += 20
		
		if shot_cooldown > 0:
			shot_cooldown -= delta
			shooting = true
		else:
			shooting = false

func apply_bounce(force: Vector2):
	if multiplayer.is_server():
		knockback = force

func take_damage(amount: int):
	if multiplayer.is_server():
		health -= amount
		print(str(health))
		if health <= 0:
			queue_free()

func _input(event):
	# Only the local client window detects their own mouse clicks
	if name == str(multiplayer.get_unique_id()):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			
			var click_pos = get_global_mouse_position()
			var shoot_dir = (click_pos - global_position).normalized()
			shooting = true
			
			# NEW LOGIC: Separate the Host and the Client
			if multiplayer.is_server():
				# The Host is the server! Just spawn the bullet directly.
				get_tree().current_scene.get_node("SpawnedBullets").spawn_bullet(global_position, shoot_dir, name, bullet_speed, bullet_damage)
			else:
				# The Client asks the Server to shoot.
				rpc_id(1, "request_shoot", shoot_dir)

# Notice we changed "call_local" back to "call_remote" since the Host doesn't use this anymore
@rpc("any_peer", "call_remote", "reliable")
func request_shoot(dir: Vector2):
	if multiplayer.is_server():
		# Optional: A print statement so you can literally see the server hear the client!
		print("Server received shoot request from Client ID: ", multiplayer.get_remote_sender_id())
		
		# Security check: verify the person sending the RPC is actually this player
		if str(multiplayer.get_remote_sender_id()) == name:
			get_tree().current_scene.get_node("SpawnedBullets").spawn_bullet(global_position, dir, name, bullet_speed, bullet_damage)

# 3. THIS FUNCTION RUNS ON THE SERVER WHEN A CLIENT PRESSES A KEY
@rpc("any_peer", "call_remote", "unreliable")
func receive_input(dir: Vector2):
	if multiplayer.is_server():
		# Security check: Ensure the client is only moving their own node
		if str(multiplayer.get_remote_sender_id()) == name:
			input_dir = dir
