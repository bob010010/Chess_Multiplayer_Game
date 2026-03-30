extends Area2D

var start_pos: Vector2
var end_pos: Vector2
var starting_length: float
var wall_length: float
var wof_rot: float

var total_lifetime: float = 20.0
var time_to_live: float = 20.0
var elapsed_time: float = 0.0
var base_contact_damage: int = 10
var contact_damage: int = 1
var damage_timer: float = 1.0
var damage_freq: float = 0.7

var team_id: int = -1
var owner_id: String = ""

@onready var hitbox: CollisionShape2D = $"WOFHitbox"
var hitbox_width: float = 20.0

@onready var particles: GPUParticles2D = $"FireParticles"
var mat: ParticleProcessMaterial
var base_particle_amount: int = 0
var particle_scale_min: float = 3.0
var particle_scale_max: float = 8.0

# Initializes the unique collision shape for the instance.
func _ready() -> void:
	# Makes the hibox shape unique
	if hitbox and hitbox.shape:
		hitbox.shape = hitbox.shape.duplicate()

# Sets up the wall properties, calculates dimensions, and configures the fire particle system.
func initialise(p_owner_id: String, p_team_id: int, s_p: Vector2, e_p: Vector2) -> void:
	owner_id = p_owner_id
	team_id = p_team_id
	start_pos = s_p
	end_pos = e_p
	
	rotation = start_pos.angle_to_point(end_pos)
	global_position = (start_pos + end_pos)/2

	wall_length = start_pos.distance_to(end_pos)
	starting_length = wall_length
	hitbox.shape.size = Vector2(0.0, hitbox_width)
	
	# Position at midpoint, rotated to face point_b
	particles.global_position = start_pos.lerp(end_pos, 0.5)
	particles.rotation = wof_rot
	
	# Set up the material
	mat = ParticleProcessMaterial.new()
	particles.process_material = mat
	
	#print(str(max(1, int(wall_length * 0.5))))
	base_particle_amount = max(1, int(wall_length * 0.5))
	particles.amount = base_particle_amount
	
	# Spread particles along the wall length (x axis after rotation)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(0.0, 2.0, 0.0)
	
	# Flame movement - rise upward (local -Y after rotation)
	mat.direction = Vector3(0, -1, 0)
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 60.0
	mat.spread = 5.0
	
	# Flame appearance
	mat.scale_min = particle_scale_min
	mat.scale_max = particle_scale_max
	mat.gravity = Vector3.ZERO
	
	# Color gradient - yellow at base, red/transparent at top
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 0.8, 0.0, 1.0))
	gradient.add_point(0.4, Color(1.0, 0.3, 0.0, 0.8))
	gradient.add_point(1.0, Color(0.5, 0.0, 0.0, 0.0))
	var gradient_tex: GradientTexture1D = GradientTexture1D.new()
	gradient_tex.gradient = gradient
	mat.color_ramp = gradient_tex
	
	particles.lifetime = 1.0
	particles.emitting = true

# Manages the life cycle phases, scales physical and visual intensity, and handles server-side damage timers.
func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	
	queue_redraw()
	
	# Handle Lifetime
	elapsed_time += delta
	time_to_live -= delta
	
	if time_to_live <= 0.0:
		queue_free()
		return
	
	_update_wall_progression()
	
	# Applies damage to all every 
	damage_timer -= delta
	if damage_timer <= 0.0:
		damage_timer = damage_freq
		_apply_fire_damage()

# Calculates current intensity based on elapsed time and updates damage, collision size, and particle density.
func _update_wall_progression() -> void:
	var phase_duration: float = total_lifetime / 20.0
	var intensity: float = 0.0
	contact_damage = 0
	
	if elapsed_time < phase_duration: # First 20th
		intensity = elapsed_time / phase_duration
	elif elapsed_time < 19.0 * phase_duration: # Middle 18/20ths
		intensity = 1.0
	else: # Last 20th
		intensity = 1.0 - ((elapsed_time - 19.0 * phase_duration) / phase_duration)
	
	intensity = clampf(intensity, 0.0, 1.0)
	
	if elapsed_time < phase_duration or elapsed_time < phase_duration * 19: # No damage right at the start and the end
		contact_damage = 0
		
	contact_damage = int(float(base_contact_damage) * intensity)
	
	var current_length: float = starting_length * intensity
	hitbox.shape.size = Vector2(current_length, hitbox_width)
	
	if mat:
		mat.emission_box_extents = Vector3(current_length / 2.0, 2.0, 0.0)
		
		mat.scale_min = particle_scale_min * intensity
		mat.scale_max = particle_scale_max * intensity
	
	if particles:
		particles.modulate.a = intensity

# Detects and damages valid overlapping bodies while filtering for teammates and owner.
func _apply_fire_damage() -> void:
	# Get everything currently overlapping the fire
	var targets: Array[Node2D] = get_overlapping_bodies()
	for body: Node2D in targets:
		# Don't damage teammates
		if body.get("team_id") == team_id and team_id != -1:
			print("Same team or no team")
			continue
		
		# Use your existing utility to apply damage
		CandDUtils.damage_on_collide(body, contact_damage, owner_id)

func _draw() -> void:
	var extents = particles.process_material.emission_box_extents
	draw_rect(Rect2(-extents.x, -extents.y, extents.x * 2, extents.y * 2), Color(0.435, 0.0, 0.0, 0.902), false, 2.0)
