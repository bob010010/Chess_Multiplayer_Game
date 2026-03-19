extends Node

signal update_ui_points(val: int)
signal show_upgrade_menu()
signal show_promotion_menu()


@export var points: int = 0:
	set(value):
		points = value
		update_ui_points.emit(points)

@export var player_level: int = 1
@export var next_level_points: int = 10

var total_score: int = 0
var pending_upgrades: int = 0
var pending_promotions: int = 0

var upgradeable_stats: Dictionary = {
	"player_speed": 1.1,
	"max_health": 1.1,
	"body_damage": 1.2,
	"regen_speed": 1.1,
	"regen_amount": 1.1,
	"bullet_damage": 1.1,
	"bullet_speed": 1.1,
	"reload_speed": 0.9,
	"accuracy": 1.1,
	"melee_damage": 1.1,
	"melee_knockback": 1.1,
	"melee_cooldown": 0.9,
	"area_damage": 1.1,
	"area_knockback": 1.1,
	"area_radius": 1.1,
	"area_cooldown": 0.9
}

@onready var player: CharacterBody2D = get_parent().get_parent()

# Grants score and initiates level up verification.
func get_points_from_kill(amount: int) -> void:
	if not multiplayer.is_server():
		return
		
	points += amount
	total_score += amount
	# update_ui_points.emit(points) is removed from here because the setter now handles it automatically.
	request_level_up_math()

# Evaluates if current points meet the threshold for the next level.
@rpc("any_peer", "call_local", "reliable")
func request_level_up_math() -> void:
	if not multiplayer.is_server():
		return
	
	if points >= next_level_points:
		player_level += 1
		points -= next_level_points
		next_level_points = int(pow(player_level, 1.5) * 10)
		#print("In Component: " + str(next_level_points)) 
		pending_upgrades += 1
		
		if player_level % 8 == 0:
			pending_promotions += 1
			
		if pending_promotions > 0:
			trigger_promotion_ui.rpc_id(multiplayer.get_remote_sender_id())
		if pending_upgrades > 0:
			trigger_upgrade_ui.rpc_id(multiplayer.get_remote_sender_id())

# Requests a specific stat upgrade from the server.
@rpc("any_peer", "call_remote", "reliable")
func request_upgrade(stat_name: String) -> void:
	if multiplayer.is_server():
		apply_upgrade(stat_name)

# Applies a standard multiplicative stat increase to the appropriate player component.
func apply_upgrade(stat_name: String) -> void:
	if pending_upgrades > 0:
		pending_upgrades -= 1
		
		print("Trying to upgrade: " + str(stat_name))
		
		if pending_upgrades > 0:
			trigger_upgrade_ui.rpc_id(multiplayer.get_remote_sender_id())
			
		var multiplier: float = upgradeable_stats.get(stat_name, 1.0)
		
		match stat_name:
			"player_speed":
				if player.movement_component:
					player.movement_component.player_speed = player.movement_component.player_speed * multiplier
			
			"max_health", "regen_speed", "regen_amount":
				if player.health_component:
					match stat_name:
						"max_health":
							player.health_component.max_health = int(player.health_component.max_health * multiplier)
							player.health_component.health = int(player.health_component.health * multiplier)
						"regen_speed":
							player.health_component.regen_speed = player.health_component.regen_speed * multiplier
						"regen_amount":
							player.health_component.regen_amount = player.health_component.regen_amount * multiplier
							
			"body_damage":
				player.body_damage = int(player.body_damage * multiplier) # Needs a fix for when it doesnt make it to the next int
				
			"bullet_damage", "bullet_speed", "reload_speed", "accuracy":
				if player.ranged_w_component:
					match stat_name:
						"bullet_damage":
							player.ranged_w_component.bullet_damage = int(player.ranged_w_component.bullet_damage * multiplier)
						"bullet_speed":
							player.ranged_w_component.bullet_speed = min(int(player.ranged_w_component.bullet_speed * multiplier), 2500)
						"reload_speed":
							player.ranged_w_component.reload_speed = max(player.ranged_w_component.reload_speed*multiplier, 0.2)
						"accuracy":
							player.ranged_w_component.accuracy = player.ranged_w_component.accuracy*multiplier
							if player.ranged_w_component.accuracy >= 100.0:
								player.ranged_w_component.accuracy = 100.0
							
			"melee_damage", "melee_knockback", "melee_cooldown":
				if player.melee_w_component:
					match stat_name:
						"melee_damage":
							player.melee_w_component.melee_damage = int(player.melee_w_component.melee_damage * multiplier)
						"melee_knockback":
							player.melee_w_component.knockback_force = min(player.melee_w_component.knockback_force * multiplier, 4000)
						"melee_cooldown":
							player.melee_w_component.attack_cooldown *= multiplier
							
			"area_damage", "area_knockback", "area_radius", "area_cooldown":
				if player.area_w_component:
					match stat_name:
						"area_damage":
							player.area_w_component.area_damage = int(player.area_w_component.area_damage * multiplier)
						"area_knockback":
							player.area_w_component.knockback_force *= multiplier
						"area_radius":
							player.area_w_component.max_radius *= multiplier
						"area_cooldown":
							player.area_w_component.attack_cooldown *= multiplier
	
# Processes the class choice and applies stats on the server, relying on synchronizers for the client.
@rpc("any_peer", "call_local", "reliable")
func request_promotion(choice: String) -> void:
	if not multiplayer.is_server():
		return
		
	if pending_promotions > 0:
		pending_promotions -= 1
		
		# Change weapons and apply stats on the Server
		change_weapon(choice)
		apply_promotion_stats(choice)
		
		# Update the synchronized variable so clients update their visual sprites
		player.current_class = choice 
		
		if pending_promotions > 0:
			trigger_promotion_ui.rpc_id(multiplayer.get_remote_sender_id())

# Commands the local client to open the upgrade selection interface via signal.
@rpc("authority", "call_local", "reliable")
func trigger_upgrade_ui() -> void:
	show_upgrade_menu.emit()

# Commands the local client to open the promotion selection interface via signal.
@rpc("authority", "call_local", "reliable")
func trigger_promotion_ui() -> void:
	show_promotion_menu.emit()

# Updates the synchronized weapon variables on the server so all clients receive the change.
func change_weapon(class_choice: String) -> void:
	var new_m_weapon: String = "None"
	var new_r_weapon: String = "None"
	var new_a_weapon: String = "None"
	
	match class_choice:
		"Knight":
			new_m_weapon = "Sword"
			new_r_weapon = "None"
			new_a_weapon = "None"
		"Rook":
			new_m_weapon = "Spear"
			new_r_weapon = "None"
			new_a_weapon = "None"
		"Bishop":
			new_m_weapon = "None"
			new_r_weapon = "Ranged_Spell" # Assuming this is the actual name in your player.gd
			new_a_weapon = "Magic"

	# Directly update the synchronized variables rather than using signals
	player.current_melee_weapon = new_m_weapon
	player.current_ranged_weapon = new_r_weapon
	player.current_area_weapon = new_a_weapon

# Applies default and specific stat packages based on the chosen chess class.
func apply_promotion_stats(class_choice: String) -> void:
	var components: Node = player.get_node("Components")
	var health_comp: Node = components.get_node("HealthComponent")
	var move_comp: Node = components.get_node("MovementComponent")
	var r_weapon_comp: Node = player.ranged_w_component
	var m_weapon_comp: Node = player.melee_w_component
	var a_weapon_comp: Node = player.area_w_component
	

	# print("Applying stats for: " + str(class_choice))
	
	match class_choice:
		"Knight": #Knights are faster (Swords are naturally faster so no change to melee speed)
			move_comp.player_speed += 300.0
			health_comp.max_health = health_comp.max_health * 0.8
			health_comp.health = health_comp.max_health
			m_weapon_comp.melee_damage = m_weapon_comp.melee_damage * 1.5
			
		"Rook": #Rooks are tanks, High health high damage
			health_comp.max_health = health_comp.max_health * 2
			move_comp.player_speed = move_comp.player_speed * 0.5
			m_weapon_comp.melee_damage = m_weapon_comp.melee_damage * 1.5
			m_weapon_comp.knockback_force = min(m_weapon_comp.knockback_force * 2, 4000)
			player.knockback_force = player.knockback_force * 2

		"Bishop": #Bishops are ranged with magic and area attack
			r_weapon_comp.bullet_speed = min(r_weapon_comp.bullet_speed * 2, 2500)
			r_weapon_comp.reload_speed = max(r_weapon_comp.reload_speed * 0.5, 0.25)
			a_weapon_comp.max_radius = a_weapon_comp.max_radius * 1.15
			a_weapon_comp.attack_cooldown = a_weapon_comp.attack_cooldown * 0.9
