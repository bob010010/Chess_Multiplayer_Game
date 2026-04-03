extends Node2D
class_name UIComponent

@onready var entity: Node2D = get_parent() as Node2D

var active_labels: Dictionary = {}
var label_values: Dictionary = {}

# Manages stacked numeric indicators for damage, healing, and level changes across the network.
@rpc("authority", "call_local", "unreliable")
func spawn_floating_number(amount: int, category: String) -> void:
	var color: Color = Color.WHITE
	var prefix: String = ""
	print(category + str(amount))
	match category:
		"damage":
			color = Color.RED
			prefix = "-"
		"heal":
			color = Color.GREEN
			prefix = "+"
		"level":
			color = Color.BLUE
			prefix = "LVL +"

	if active_labels.has(category) and is_instance_valid(active_labels[category]):
		var label: Label = active_labels[category]
		label_values[category] += amount
		label.text = prefix + str(label_values[category])
		label.scale = Vector2(1.3, 1.3)
		create_tween().tween_property(label, "scale", Vector2.ONE, 0.1)
		return

	label_values[category] = amount
	var new_label: Label = FloatingTextUtils.create_label(self, entity, prefix + str(amount), color, 20, Vector2(-50, -40), 5.0)
	active_labels[category] = new_label

# Displays high-priority status text like promotions or upgrades above the entity.
@rpc("any_peer", "call_local", "reliable")
func display_message(message: String, pos_offset: Vector2 = Vector2(-400, -200), font_size: int = 20, override_color: Color = Color(0, 0, 0, 0)) -> void:
	var color: Color = override_color if override_color.a > 0.0 else Color.RED
	var message_formatted: String = message
	
	if message.contains("Upgraded"):
		color = ColourUtils.get_colour_based_on_type(message.split(" ")[1])
		color.a = 1.0
		var upgrade_split: PackedStringArray = message.split(" ")[1].split("_") # "Upgraded regen_speed" > "regen", "speed"
		message_formatted = "Upgraded: " + upgrade_split[0].capitalize() + " " + upgrade_split[1].capitalize()
	elif message.contains("Promoted"):
		color = Color.GREEN
	
	var label: Label = FloatingTextUtils.create_label(self, entity, message_formatted, color, font_size, pos_offset, 1.5)
	label.scale = Vector2(0.5, 0.5)
	create_tween().tween_property(label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
