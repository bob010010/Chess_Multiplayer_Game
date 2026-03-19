extends ProgressBar

@onready var parent: Node = get_parent()
var health_component: Node = null

# Finds the correct node to track health from
func _ready() -> void:
	# Look for the new component. If it doesn't exist, fallback to the parent!
	if parent.has_node("Components/HealthComponent"):
		health_component = parent.get_node("Components/HealthComponent")
	else:
		health_component = parent

	if "max_health" in health_component:
		max_value = health_component.max_health
	else:
		max_value = 100

# Continually updates the bar visually to match the entity's health
func _process(_delta: float) -> void:
	value = health_component.health
	max_value = health_component.max_health
	if value >= max_value:
		hide()
	else:
		show()
		#if not parent.has_method("show_debug_info"):
			#print("Non player node with less than full health")
			#print("Max health: " + str(max_value))
			#print("Health: " + str(value))
	
