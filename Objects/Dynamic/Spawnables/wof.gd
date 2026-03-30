extends StaticBody2D

var start_pos: Vector2
var end_pos: Vector2
var starting_length: float
var wall_length: float
var wof_rot: float
var contact_damage: int
var time_to_live: float = 100.0

@onready var hitbox: CollisionShape2D = self.get_node("WOFHitbox")

func initialise(owner_id: String, _creator_team_id: int, s_p: Vector2, e_p: Vector2):
	name = "WOF_" + owner_id + "_" + str(Time.get_ticks_msec()) # Unique name assigned
	print("Spawned: " + name)
	start_pos = s_p
	end_pos = e_p
	
	rotation = start_pos.angle_to_point(end_pos)
	global_position = (start_pos + end_pos)/2

	wall_length = start_pos.distance_to(end_pos)
	starting_length = wall_length
	print(str("Starting: " + str(starting_length)))
	
	var particles = GPUParticles2D.new()
	add_child(particles)
	
	# Position at midpoint, rotated to face point_b
	particles.global_position = start_pos.lerp(end_pos, 0.5)
	particles.rotation = wof_rot
	
	# Set up the material
	var mat = ParticleProcessMaterial.new()
	particles.process_material = mat
	
	#print(str(max(1, int(wall_length * 0.5))))
	particles.amount = max(1, int(wall_length * 0.5))
	
	# Spread particles along the wall length (x axis after rotation)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(wall_length * 0.5, 2.0, 0.0)
	
	# Flame movement - rise upward (local -Y after rotation)
	mat.direction = Vector3(0, -1, 0)
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 60.0
	mat.spread = 5.0
	
	# Flame appearance
	mat.scale_min = 3.0
	mat.scale_max = 8.0
	mat.gravity = Vector3.ZERO
	
	# Color gradient - yellow at base, red/transparent at top
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 0.8, 0.0, 1.0))
	gradient.add_point(0.4, Color(1.0, 0.3, 0.0, 0.8))
	gradient.add_point(1.0, Color(0.5, 0.0, 0.0, 0.0))
	var gradient_tex = GradientTexture1D.new()
	gradient_tex.gradient = gradient
	mat.color_ramp = gradient_tex
	
	particles.lifetime = 1.0
	particles.emitting = true

#func _physics_process(delta: float) -> void:
	#var current_size = hitbox.shape.size
	#var amount_to_decr = starting_length/100
	#print("Decreasing: " + str(amount_to_decr))
	#hitbox.shape.size = Vector2(current_size.x - (amount_to_decr * delta), current_size.y)
	#print("Now: " + str(current_size.x))

func _process(delta: float) -> void:
	time_to_live -= delta
	if time_to_live <= 0.0:
		queue_free()
