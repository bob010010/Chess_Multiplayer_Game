extends Label

@onready var entity: CharacterBody2D = get_parent().get_parent()
var active_tween: Tween

func _ready() -> void:
	# Ensure it starts completely invisible
	modulate.a = 0.0
	text = ""

@rpc("any_peer", "call_local", "reliable")
func display_message(message: String) -> void:
	var label = Label.new()
	get_parent().get_parent().add_child(label)
	print(message)
	
	if message.contains("Upgraded"):
		var stat_button: Node = get_parent().get_node_or_null("UpgradeUI/StatButton")
		if stat_button:
			label.text = stat_button.format_stat_name(message)
			label.modulate = stat_button.get_colour_based_on_type(message.split(" ")[1])
			print(label.text)
		else:
			label.text = message
	else:
		label.text = message
		label.modulate = Color(1.0, 1.0, 1.0, 1.0)

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_font_size_override("font_size", 70)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	var vertical_offset: float = -200.0 * entity.scale.y
	
	label.global_position = entity.global_position + Vector2(-100, vertical_offset)
	
	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(label, "global_position:y", label.global_position.y - 50.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	label.scale = Vector2(0.5, 0.5)
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.chain().tween_property(label, "scale", Vector2(1.0, 1.0), 0.2)
	
	var fade_tween = create_tween()
	fade_tween.tween_interval(1.0)
	fade_tween.tween_property(label, "modulate:a", 0.0, 2.0)

	tween.chain().tween_callback(label.queue_free)
