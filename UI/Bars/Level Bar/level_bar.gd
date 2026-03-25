extends EntityBar

@onready var player: Node = get_parent().get_parent()
@onready var leveling_component: Node = player.get_node("Components/LevelingComponent")

# Initializes the bar's maximum value based on the synchronized leveling component.
func _ready() -> void:
	value = 0.0
	leveling_component.update_ui_points.connect(queue_points)
	if "next_level_points" in leveling_component:
		max_value = float(leveling_component.next_level_points)


# Triggers a visual tween sequence to match the server's absolute points value.
func queue_points(new_points: int) -> void:
	var target_max: float = float(leveling_component.next_level_points)
	
	# Keep the underlying EntityBar max_value updated 
	max_value = target_max
	
	# Animate to the new absolute point total 
	animate_value(float(new_points), target_max, 0.4)
