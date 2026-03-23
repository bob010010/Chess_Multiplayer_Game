extends Node2D
class_name PointsUtil

# Gives points to the attacker upon death.
static func give_points_on_death(main: Node, attacker_id: String, points_value: int) -> void:
    if attacker_id != "":
        var attacker: Node = main.get_node_or_null("SpawnedPlayers/" + attacker_id)
        if attacker:
            var level_comp: Node = attacker.get_node_or_null("Components/LevelingComponent")
            if level_comp and level_comp.has_method("get_points"):
                level_comp.get_points(points_value)
            else:
                printerr("No LevelingComponent found on attacker")
        else:
            printerr("No person to give points to found with id: " + attacker_id)
