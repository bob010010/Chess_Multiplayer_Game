extends Node2D
class_name ShieldComponent

@onready var entity: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/Collision
@onready var health_comp: HealthComponent = $Components/HealthComponent

var shield_knockback: float = 1000.0

var is_active: bool = false

# Initializes the shield state, groups, and connects collision signals.
func _ready() -> void:
	add_to_group("shield")
	if is_node_ready():
		health_comp.decay_amount = 1
		health_comp.decay_speed = 2.0
		health_comp.regen_amount = 1
		health_comp.regen_speed = 2.0

	hitbox.monitoring = true
	hitbox_shape.disabled = false
	hitbox.body_entered.connect(_on_body_entered)
	hitbox.area_entered.connect(_on_body_entered)
	health_comp.died.connect(deactivate_shield)
	

# Validates activation criteria and starts the shield timer on the server.
@rpc("any_peer", "call_local", "reliable")
func request_shield_activation() -> void:
	if not multiplayer.is_server() or is_active:
		return
	print(str(health_comp.health))
	if health_comp.health >= health_comp.max_health/10:
		health_comp.decaying = true
		health_comp.healing = false

		trigger_shield_visuals.rpc(true)

# Validates deactivation criteria and stops the shield on the server.
@rpc("any_peer", "call_local", "reliable")
func request_shield_deactivation() -> void:
	if not multiplayer.is_server() or not is_active:
		return
	deactivate_shield()

# Deactivates the shield when the active duration timer finishes.
func on_shield_broken() -> void:
	if is_active:
		deactivate_shield()

# Triggers network-wide deactivation of the shield visuals and state.
func deactivate_shield() -> void:
	trigger_shield_visuals.rpc(false)
	health_comp.decaying = false
	health_comp.healing = true

# Toggles the active state, player variable, and visibility of the shield across all clients.
@rpc("authority", "call_local", "reliable")
func trigger_shield_visuals(activate: bool) -> void:
	is_active = activate
	entity.shielding = activate
	if activate:
		show()
		queue_redraw()
	else:
		hide()

# Evaluates incoming collisions to reduce health, retract melee weapons, or reflect projectiles.
func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server() or not is_active or body == entity:
		return

	if body.is_in_group("shield_blockable"):
		var potential_entity = body.get_parent().get_parent().get_parent() # Can be anything
		if is_instance_valid(potential_entity) and potential_entity == entity: # It is another component e.g weapon 
			print("Not blocking same")
			return
		
		health_comp.take_damage(1)
		
		if body.has_method("apply_bounce"):
			var direction: Vector2 = global_position.direction_to(body.global_position)
			body.apply_bounce(direction * shield_knockback)
			
		var parent_node: Node = body.get_parent()
		if parent_node and parent_node.has_method("trigger_visual_retract"):
			parent_node.has_hit = true
			parent_node.is_attacking = false
			parent_node.trigger_visual_retract.rpc()
