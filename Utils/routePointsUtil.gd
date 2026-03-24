extends Node2D
class_name PointsUtil

# Iterates through player and NPC containers to award points to the identified attacker.
static func give_points_on_death(main: Node, attacker_id: String, points_value: int) -> void:
	if attacker_id == "" or not is_instance_valid(main):
		printerr("No attacker id (Trying to route points)")
		return
	
	var containers: Array[String] = ["SpawnedPlayers", "SpawnedNPCs"]
	for container_name: String in containers:
		var container: Node = main.get_node_or_null(container_name)
		if is_instance_valid(container):
			for entity: Node in container.get_children():
				if entity.name == attacker_id:
					var level_comp: Node = entity.get_node_or_null("Components/LevelingComponent")
					if is_instance_valid(level_comp) and level_comp.has_method("get_points"):
						level_comp.get_points(points_value)
						return				
					else:
						printerr("Attacker has no valid level component")
		else:
			printerr("No valid spawned: " + container_name)
