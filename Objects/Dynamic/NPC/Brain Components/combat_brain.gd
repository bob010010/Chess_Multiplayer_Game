extends Node2D
class_name CombatBrain

@onready var main_brain: MainBrain = get_parent().get_node("MainBrain") as MainBrain
@onready var move_comp: Node2D = main_brain.npc.get_node("Components/MovementComponent")
@onready var kill_zone: Area2D = main_brain.npc.get_node("KillArea") as Area2D
@onready var active_melee: MeleeWeaponComponent = main_brain.npc.get("melee_w_component")
@onready var active_ranged: RangedWeaponComponent = main_brain.npc.get("ranged_w_component")

# Ranges
var melee_range: float = 110.0
var comfortable_melee_range: float = 75
var max_shoot_range: float = 300.0
var min_shoot_range: float = 150.0

# Factors that affect whether to take a fight
var kindness_factor: float = 1.0 

var current_target: Node2D = null
var combat_state: String = ""
var blacklisted_target: Node2D = null 
var blacklist_timer: float = 0.0
var last_dist_to_target: float = INF 


var target_out_of_range_timer: float = 5.0 # TODO

var give_up_attack_time: float = 30.0 # TODO

func _ready() -> void:
	kindness_factor = randf_range(0.01, 0.2) 

# Re target to higher priority targets, or get new target from the best visible ones
func _process_targeting(best_visible_target: Node2D) -> bool:
	var target_points: int = TargetingUtils.get_entity_score(best_visible_target)
	print("Best visible target: " + str(best_visible_target.get_groups()[0]))
	print("Target is worth: " + str(target_points))
	if main_brain.my_score * main_brain.kindness_factor > target_points:
		return false
	current_target = best_visible_target
	target_out_of_range_timer = 3.0
	last_dist_to_target = INF
	return true

# Handles taking final stands when being hunted down
func _last_stand(threat: Node2D) -> bool:
	if threat in kill_zone.get_overlapping_bodies():
		current_target = threat
		_update_weapons()
		_ranged_attack(threat, false)
		_melee_attack(threat, false)
		#print(combat_state, str(threat.get_groups()))
		if combat_state in ["Melee_Attack", "Ranged_Attack", "Ranged_Attack-TC", "Chasing"]:
			return true
	return false

# Evaluates targets and manages the progress-based abandonment timer while executing combat logic.
func _process_combat_state(delta: float) -> bool:
	_update_chase_timers(delta)
	_update_weapons()
	#print("Processing combat with: " + str(current_target.get_groups()[0]))
	_melee_attack(current_target)
	_ranged_attack(current_target)
	if combat_state in ["Melee_Attack", "Ranged_Attack", "Ranged_Attack-TC", "Chasing"]:
		return true
	else:
		return false

# Tries to do a melee attack
func _melee_attack(target: Node2D, chase: bool = true) -> bool:
	if is_instance_valid(active_melee):
		print("Trying to melee")
		var dist: float = main_brain.npc.global_position.distance_to(target.global_position)
		# If in range, stop moving, set state and request an attack
		if dist <= melee_range:
			combat_state = "Melee_Attack"
			move_comp.set_movement_direction(Vector2.ZERO)
			if active_melee.can_attack: 
				active_melee.request_melee_attack(target.global_position)
			if dist <= comfortable_melee_range: # Moves towards if they are in the outer part of the melee range
				move_comp.set_movement_direction(main_brain.npc.global_position.direction_to(target.global_position))
			return true
		elif chase:
			#If not in range, chase the target
			combat_state = "Chasing"
			move_comp.set_movement_direction(main_brain.npc.global_position.direction_to(target.global_position))
			return true
	return false


# Trie to do a ranged attack
func _ranged_attack(target: Node2D, chase: bool = true) -> bool:
	if is_instance_valid(active_ranged):
		#print("Trying to ranged")
		var dist: float = main_brain.npc.global_position.distance_to(target.global_position)
		if dist <= max_shoot_range:
			move_comp.set_movement_direction(Vector2.ZERO)
			# If in range, shoot and stop moving
			if active_ranged.get("shot_cooldown") <= 0.0: 
				active_ranged.shoot(target.global_position)
				combat_state = "Ranged_Attack"
			if dist <= min_shoot_range: # This is still moving towards the player _----------------------------
				combat_state = "Ranged_Attack-TC"
			return true
		elif chase:
			# Out of range, chase
			combat_state = "Chasing"
			move_comp.set_movement_direction(main_brain.npc.global_position.direction_to(target.global_position))
			return true
	return false

# Handles chasing 
func _update_chase_timers(delta: float) -> void:
	var dist: float = main_brain.npc.global_position.distance_to(current_target.global_position)
	if dist < last_dist_to_target:
		target_out_of_range_timer = 3.0
	elif not current_target.is_in_group("food"):
		target_out_of_range_timer -= delta
	last_dist_to_target = dist
	if target_out_of_range_timer <= 0.0:
		blacklisted_target = current_target
		blacklist_timer = 5.0
		current_target = null 

# Clears the blacklisted targets
func _clear_blacklist(delta: float) -> void:
	if blacklist_timer > 0.0:
		blacklist_timer -= delta
		if blacklist_timer <= 0.0: blacklisted_target = null

func _update_weapons() -> void:
	active_melee = main_brain.npc.get("melee_w_component")
	active_ranged = main_brain.npc.get("ranged_w_component")

#func _draw() -> void:


# # ACTION
# # Moves away if too close whilst shooting
# func _action_reposition(from_pos: Vector2) -> void:
# 	var move_dir: Vector2 = from_pos.direction_to(main_brain.npc.global_position)
# 	var probe_pos: Vector2 = main_brain.npc.global_position + (move_dir * 50.0)
# 	if not AbilityUtils.is_position_within_map(get_tree().current_scene, probe_pos):
# 		move_dir = Vector2(-move_dir.y, move_dir.x)
# 	main_brain.move_comp.set_movement_direction(move_dir)
