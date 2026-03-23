extends Node
class_name ComponentManager

@onready var player: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
@onready var components_container: Node2D = get_parent() as Node2D
@onready var player_ui: Node2D = player.get_node("PlayerUI")

# Initializes the component states by hiding all equipment and processing the initial class setup.
func _ready() -> void:
	_hide_all_components()

# Disables only the non-essential equipment and ability components to ensure core player logic remains active.
func _hide_all_components() -> void:
	var essential_nodes: Array[String] = [
		"MovementComponent",
		"HealthComponent",
		"LevelingComponent",
		"PromotionComponent",
		"ComponentManager",
		"UIComponent"
	]
	
	for child: Node in components_container.get_children():
		if child.name in essential_nodes:
			continue
			
		if child is Node2D:
			child.hide()
			child.process_mode = Node.PROCESS_MODE_DISABLED

# Swaps the active melee weapon component and updates the associated UI labels.
func change_melee_weapon(weapon_type: String) -> void:
	var spear: Node2D = components_container.get_node_or_null("SpearComponent")
	var sword: Node2D = components_container.get_node_or_null("SwordComponent")
	
	if spear:
		spear.hide()
		spear.process_mode = Node.PROCESS_MODE_DISABLED
	if sword:
		sword.hide()
		sword.process_mode = Node.PROCESS_MODE_DISABLED
		
	match weapon_type:
		"Spear":
			player.melee_w_component = spear
			player_ui.melee_info_label.text = "Melee: Spear"
		"Sword":
			player.melee_w_component = sword
			player_ui.melee_info_label.text = "Melee: Sword"
		"None":
			player.melee_w_component = null
			player_ui.melee_info_label.text = "No Melee Weapon"
			
	if player.melee_w_component:
		player.melee_w_component.show()
		player.melee_w_component.process_mode = Node.PROCESS_MODE_INHERIT
		player_ui.melee_w_component = player.melee_w_component

# Swaps the active ranged weapon component and updates the associated UI labels.
func change_ranged_weapon(weapon_type: String) -> void:
	var fireball: Node = components_container.get_node_or_null("FireballShooterComponent")
	var bow: Node = components_container.get_node_or_null("BowComponent")
	var pin: Node = components_container.get_node_or_null("PinShooterComponent")
	
	for node: Node in [fireball, bow, pin]:
		if node:
			node.hide()
			node.process_mode = Node.PROCESS_MODE_DISABLED
			
	match weapon_type:
		"Fireball_Shooter":
			player.ranged_w_component = fireball
			player_ui.ranged_info_label.text = "Ranged: Fireball Shooter"
		"Bow":
			player.ranged_w_component = bow
			player_ui.ranged_info_label.text = "Ranged: Bow"
		"Pin_Shooter":
			player.ranged_w_component = pin
			player_ui.ranged_info_label.text = "Ranged: Pin Shooter"
		"None":
			player.ranged_w_component = null
			player_ui.ranged_info_label.text = "No Ranged Weapon"
			
	if player.ranged_w_component:
		player.ranged_w_component.show()
		player.ranged_w_component.process_mode = Node.PROCESS_MODE_INHERIT
		player_ui.ranged_w_component = player.ranged_w_component

# Swaps the active ability component and updates the associated UI labels and logic references.
func change_first_ability(ability_type: String) -> void:
	var abilities: Dictionary = {
		"Magic": components_container.get_node_or_null("MagicAreaWeaponComponent"),
		"Teleport": components_container.get_node_or_null("TeleportComponent"),
		"Illusion": components_container.get_node_or_null("IllusionComponent"),
		"Stealth": components_container.get_node_or_null("StealthComponent"),
		"Spawner": components_container.get_node_or_null("SpawnerComponent"),
		"Teleport_Crush": components_container.get_node_or_null("TeleportCrushComponent")
	}
	
	for key: String in abilities:
		if abilities[key]:
			abilities[key].hide()
			abilities[key].process_mode = Node.PROCESS_MODE_DISABLED
			
	if abilities.has(ability_type) and abilities[ability_type]:
		player.first_ability_component = abilities[ability_type]
		player.first_ability_component.show()
		player.first_ability_component.process_mode = Node.PROCESS_MODE_INHERIT
		player_ui.ability_info_label.text = "Ability: " + ability_type.replace("_", " ")
	else:
		player.first_ability_component = null
		player_ui.ability_info_label.text = "No First Ability"
		
	player_ui.first_ability_component = player.first_ability_component
	player_ui.current_first_ability = ability_type

# Swaps the active shield component and updates the associated physical state.
func change_shield(shield_type: String) -> void:
	var wooden: Node = components_container.get_node_or_null("WoodenShieldComponent")
	var magic: Node = components_container.get_node_or_null("MagicShieldComponent")
	
	if wooden:
		wooden.hide()
		wooden.process_mode = Node.PROCESS_MODE_DISABLED
	if magic:
		magic.hide()
		magic.process_mode = Node.PROCESS_MODE_DISABLED
		
	match shield_type:
		"Wooden":
			player.shield_component = wooden
		"Magic":
			player.shield_component = magic
		"None":
			player.shield_component = null
			
	if player.shield_component:
		player.shield_component.process_mode = Node.PROCESS_MODE_INHERIT
		player_ui.shield_component = player.shield_component
