extends Node2D
class_name AbilityBrain

@onready var main_brain: MainBrain = get_parent().get_node("MainBrain") as MainBrain

var min_food_to_spawn_tower: int = 2 

func _ready() -> void:
	min_food_to_spawn_tower = randi_range(2, 4)

# Spawn towers 
func _spawn_towers() -> bool:
	var spawn_comp: SpawnerComponent = main_brain.npc.get("first_ability_component")
	if is_instance_valid(spawn_comp) and spawn_comp.get("current_cooldown") <= 0.0 and main_brain.combat_brain.nearby_food_count >= min_food_to_spawn_tower:
		spawn_comp.request_spawn.rpc(main_brain.npc.global_position)
		return true
	return false

# Requests a stealth execution for applicable NPC classes.
func _action_stealth() -> bool:
	var stealth_comp: Node = main_brain.npc.get_node_or_null("Components/StealthComponent")
	if is_instance_valid(stealth_comp) and stealth_comp.get("current_cooldown") <= 0.0:
		stealth_comp.call("request_stealth")
		return true
	return false

# Requests an illusion scattered sequence for applicable NPC classes.
func _action_illusion() -> bool:
	var illusion_comp: Node = main_brain.npc.get_node_or_null("Components/IllusionComponent")
	if is_instance_valid(illusion_comp) and illusion_comp.get("current_cooldown") <= 0.0:
		illusion_comp.call("request_scattered_illusions")
		return true
	return false
