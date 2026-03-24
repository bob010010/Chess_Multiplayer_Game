extends Node
class_name LevelingComponent

signal update_ui_points(val: int)
signal show_upgrade_menu()

@export var points: int = 0:
	set(value):
		points = value
		# Ensures the multiplayer API and onready player reference are valid before attempting synchronization.
		if is_inside_tree() and entity != null and multiplayer.is_server():
			update_ui_points.emit(value)


@export var entity_level: int = 1
@export var next_level_points: int = 10

var total_score: int = 0
var pending_upgrades: int = 0

# The static increments applied to the multiplier pool upon upgrade selection.
var upgrade_increments: Dictionary = {
	"move_speed": 1.1,
	"body_damage": 1.2,
	
	#Health & Regen
	"max_health": 1.1,
	"regen_speed": 0.9,
	"regen_amount": 1.1,
	
	#Ranged
	"projectile_damage": 1.1,
	"projectile_speed": 1.1,
	"reload_speed": 0.9,
	"accuracy": 1.1,
	
	#Melee
	"melee_damage": 1.1,
	"melee_knockback": 1.1,
	"melee_cooldown": 0.9,
	
	#Area
	"area_damage": 1.1,
	"area_knockback": 1.1,
	"area_radius": 1.1,
	"area_cooldown": 0.9,
	
	#Teleport
	"teleport_cooldown": 0.9,
	"teleport_range": 1.1,

	#Illusion
	"illusion_cooldown": 0.9,
	"illusion_duration": 1.2,
	"illusion_amount": 1.2,

	#Stealth
	"stealth_cooldown": 0.9,
	"stealth_duration": 1.2,
	
	#Spawning
	"spawner_cooldown": 0.9,
	"max_spawns": 1.4,
	
	#Shield
	"shield_health": 1.2
}

# The cumulative multipliers tracked continuously throughout the player's life.
var stat_multipliers: Dictionary = {
	"move_speed": 1.0,
	"body_damage": 1.0,
	
	#Health & Regen
	"max_health": 1.0,
	"regen_speed": 1.0,
	"regen_amount": 1.0,
	
	#Ranged
	"projectile_damage": 1.0,
	"projectile_speed": 1.0,
	"reload_speed": 0.9,
	"accuracy": 1.0,
	
	#Melee
	"melee_damage": 1.0,
	"melee_knockback": 1.0,
	"melee_cooldown": 1.0,
	
	#Area
	"area_damage": 1.0,
	"area_knockback": 1.0,
	"area_radius": 1.0,
	"area_cooldown": 1.0,
	
	#Teleport
	"teleport_cooldown": 1.0,
	"teleport_range": 1.0,
	
	#Illusion
	"illusion_cooldown": 1.0,
	"illusion_duration": 1.0,
	"illusions_count": 1.0,

	#Stealth
	"stealth_cooldown": 1.0,
	"stealth_duration": 1.0,
	
	#Spawning
	"spawner_cooldown": 1.0,
	"max_spawns": 1.0,
	
	#Shield
	"shield_health": 1.0
}



@onready var entity: CharacterBody2D = get_parent().get_parent()

# Grants score and initiates level up verification.
func get_points(amount: int) -> void:
	if not multiplayer.is_server():
		return
		
	points += amount
	total_score += amount
	request_level_up_math()

# Calculates level thresholds and manages pending upgrades for both players and NPCs.
func request_level_up_math() -> void:
	if not multiplayer.is_server():
		return
	
	var is_player: bool = entity.is_in_group("player")
	var peer_id: int = entity.name.to_int() if is_player else -1
	
	while points >= next_level_points:
		entity_level += 1
		var leftover: int = points - next_level_points
		
		if is_player:
			sync_points_to_client.rpc_id(peer_id, next_level_points)
		
		next_level_points = int(pow(float(entity_level), 1.5) * 10.0)
		pending_upgrades += 1
		points = leftover
		
		if not is_player and entity_level % 5 == 0:
			var promo: Node = entity.get_node("Components/PromotionComponent")
			promo.add_pending_promotion(peer_id)

		if is_player and entity_level % 3 == 0:
			var promo: Node = entity.get_node("Components/PromotionComponent")
			promo.add_pending_promotion(peer_id)
		
		if is_player:
			sync_points_to_client.rpc_id(peer_id, leftover)
		
	if pending_upgrades > 0:
		if is_player:
			trigger_upgrade_ui.rpc_id(peer_id)
		else:
			_npc_auto_upgrade()

# Identifies non-maxed stats relevant to current equipment and applies a random upgrade for NPCs.
func _npc_auto_upgrade() -> void:
	var promo: PromotionComponent = entity.get_node("Components/PromotionComponent") as PromotionComponent
	var valid_stats: Array[String] = ["move_speed", "body_damage", "max_health", "regen_speed", "regen_amount"]
	
	if entity.get("melee_w_component") != null:
		valid_stats.append_array(["melee_damage", "melee_knockback", "melee_cooldown"])
	if entity.get("ranged_w_component") != null:
		valid_stats.append_array(["projectile_damage", "projectile_speed", "reload_speed", "accuracy"])
	
	var available_choices: Array[String] = []
	for stat: String in valid_stats:
		if not promo.is_stat_maxed(stat):
			available_choices.append(stat)
			
	if not available_choices.is_empty():
		var chosen: String = available_choices.pick_random()
		#print("Ai upgraded: " + chosen)
		apply_upgrade(chosen)

# Requests a specific stat upgrade from the server.
@rpc("any_peer", "call_remote", "reliable")
func request_upgrade(stat_name: String) -> void:
	if multiplayer.is_server():
		apply_upgrade(stat_name)

# Updates stat multipliers and refreshes the entity's base attributes.
func apply_upgrade(stat_name: String) -> void:
	if pending_upgrades > 0:
		pending_upgrades -= 1
		
		var increment: float = upgrade_increments.get(stat_name, 1.0)
		stat_multipliers[stat_name] *= increment
		
		var promo: PromotionComponent = entity.get_node("Components/PromotionComponent") as PromotionComponent
		promo.apply_promotion_stats(entity.get("current_class"))
		
		if entity.is_in_group("player"):
			if pending_upgrades > 0: 
				trigger_upgrade_ui.rpc_id(multiplayer.get_remote_sender_id()) # Notify the specific client's UI about the upgrade.
			var info: Node = entity.get_node_or_null("HUD/InfoLabel")
			if info:
				info.display_message.rpc_id(entity.name.to_int(), "Upgraded " + stat_name)


# Commands the local client to open the upgrade selection interface via signal.
@rpc("authority", "call_local", "reliable")
func trigger_upgrade_ui() -> void:
	show_upgrade_menu.emit()

# Commands the client to update the level bar
@rpc("authority", "call_local", "reliable")
func sync_points_to_client(val: int) -> void:
	update_ui_points.emit(val)
