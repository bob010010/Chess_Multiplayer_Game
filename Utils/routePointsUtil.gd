extends Node2D
class_name PointsUtil


# Gives points to the attacker upon death.
static func give_points_on_death(main: Node, attacker_id: String, points_value: int) -> void:
    if attacker_id == "":
        printerr("No attacker id")
        return
	
    var spawned_players: Node = main.get_node_or_null("SpawnedPlayers")
    if not spawned_players:
        printerr("No spawned players node in main")
        return

    var attacker: Node = spawned_players.get_node_or_null(attacker_id)
	# Check if the attacker node still exists in the world
    if is_instance_valid(attacker):
        var level_comp: Node = attacker.get_node_or_null("Components/LevelingComponent")
        if level_comp and level_comp.has_method("get_points"):
            level_comp.get_points(points_value)
        else:
            printerr("Attacker has no valid level component")
    else:
        printerr("Instance of attacker is not valid")