extends Node

signal died(attacker_id: String)

@export var max_health: int = 500
var health: int = 500
@export var regen_amount: int = 2
@export var regen_speed: float = 10.0
var regen_cooldown: float = regen_speed

@onready var object: Node = get_parent().get_parent()
var health_bar: ProgressBar 

var active_dmg_label: Label = null
var active_heal_label: Label = null
var current_dmg: int = 0
var current_heal: int = 0
var dmg_tween: Tween = null
var heal_tween: Tween = null

# Sets initial health to max health.
func _ready() -> void:
	health_bar = object.get_node("HealthBar") as ProgressBar
	if not health_bar:
		printerr("No health bar")

# Deducts health, emits death signal if empty, and triggers floating damage text.
func take_damage(amount: int, attacker_id: String = "") -> void:
	if multiplayer.is_server():
		health -= amount
		spawn_floating_text.rpc(amount, false)
		if health <= 0:
			died.emit(attacker_id)

# Restores health up to the maximum limit and triggers floating heal text.
func heal(amount: int) -> void:
	if multiplayer.is_server():
		var actual_heal: int = amount
		if health + amount > max_health:
			actual_heal = max_health - health
			
		if actual_heal > 0:
			health += actual_heal
			spawn_floating_text.rpc(actual_heal, true)

# Handles passive health regeneration exclusively on the server.
func _process(delta: float) -> void:
	if multiplayer.is_server() and health < max_health:
		regen_cooldown -= delta
		if regen_cooldown <= 0.0:
			regen_cooldown = regen_speed
			heal(regen_amount)

# Spawns or updates a floating, vanishing label on all clients to stack health changes dynamically from the base position.
@rpc("authority", "call_local", "unreliable")
func spawn_floating_text(amount: int, is_heal: bool) -> void:
	if not object:
		return
		
	var active_label: Label = active_heal_label if is_heal else active_dmg_label
	var active_tween: Tween = heal_tween if is_heal else dmg_tween
	
	var vertical_offset: float = -20.0 * object.scale.y
	var random_offset_x: float = randf_range(-15.0, 15.0) - 18.0 
	
	if is_instance_valid(active_label):
		if is_heal:
			current_heal += amount
			active_label.text = "+" + str(current_heal)
		else:
			current_dmg += amount
			active_label.text = "-" + str(current_dmg)
			
		active_label.scale = Vector2(1.5, 1.5)
		active_label.modulate.a = 1.0
		
		active_label.global_position.y = object.global_position.y + vertical_offset
		active_label.global_position.x = object.global_position.x + random_offset_x
		
		if active_tween and active_tween.is_valid():
			active_tween.kill()
			
		var new_tween: Tween = create_tween()
		new_tween.set_parallel(true)
		new_tween.tween_property(active_label, "global_position:y", active_label.global_position.y - 50.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		new_tween.tween_property(active_label, "scale", Vector2(0.5, 0.5), 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		new_tween.tween_property(active_label, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		new_tween.chain().tween_callback(active_label.queue_free)
		
		if is_heal:
			heal_tween = new_tween
		else:
			dmg_tween = new_tween
		return
		
		# V If there is no label V
		
	var label: Label = Label.new()
	label.top_level = true 
	
	if is_heal:
		current_heal = amount
		active_heal_label = label
		label.text = "+" + str(amount)
		label.modulate = Color(0.0, 1.0, 0.0)
	else:
		current_dmg = amount
		active_dmg_label = label
		label.text = "-" + str(amount)
		label.modulate = Color(1.0, 0.0, 0.0)
	
	label.global_position = object.global_position + Vector2(random_offset_x, vertical_offset)
	
	object.add_child(label)
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 50.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(0.5, 0.5), 1.0).from(Vector2(1.5, 1.5)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)
	
	if is_heal:
		heal_tween = tween
	else:
		dmg_tween = tween
