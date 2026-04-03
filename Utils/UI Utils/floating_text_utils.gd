class_name FloatingTextUtils

# Instantiates a label with standard physics-based animations for world-space feedback.
static func create_label(parent: Node, entity: Node2D, text: String, color: Color, size: int, offset: Vector2, duration: float) -> Label:
	var label: Label = Label.new()
	label.top_level = true
	label.text = text
	label.modulate = color
	label.add_theme_font_size_override("font_size", size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var spawn_pos: Vector2 = entity.global_position + (offset * entity.scale)
	label.global_position = spawn_pos
	
	parent.add_child(label)
	
	var tween: Tween = parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", spawn_pos.y - 60.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)
	
	return label
