extends Node2D
class_name CandDUtils

# Applies knockback to the hit entity then damages
static func knockback_and_damage(target: Node, damage: int, attacker_name: String, dir: Vector2, knockback_force: float) -> void:
	var health_comp: Node2D = target.get_node_or_null("Components/HealthComponent")
	if target.has_method("apply_bounce"):
		if is_instance_valid(health_comp) and health_comp.immune:
			return
		target.apply_bounce(dir * knockback_force)
	damage_on_collide(target, damage, attacker_name)

# Applies damage to the hit entity
static func damage_on_collide(target: Node, damage: int, attacker_name: String) -> void:
	var health_comp: Node2D = target.get_node_or_null("Components/HealthComponent")
	#print("UTIL " + str(target.get_groups()))
	if health_comp:
		health_comp.take_damage(damage, attacker_name)
	elif not target.is_in_group("boundary"):
		printerr("Trying to do damage to something without a health component" + str(target.get_groups()))
