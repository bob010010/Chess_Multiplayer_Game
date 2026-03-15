extends Node2D

@export var bullet_scene: PackedScene = preload("res://bullet.tscn")
var bullet_counter = 0

func spawn_bullet(spawn_pos: Vector2, dir: Vector2, shooter_id: String, bullet_speed: int, bullet_damage: int):
	if multiplayer.is_server():
		var bullet = bullet_scene.instantiate()
		
		bullet_counter += 1
		bullet.name = "Bullet_" + str(bullet_counter)
		
		bullet.position = spawn_pos + (dir * 30) 
		bullet.direction = dir
		bullet.shooter_id = shooter_id
		
		bullet.speed = bullet_speed
		bullet.damage = bullet_damage
		# Add it directly to ourselves (the SpawnedBullets node)
		add_child(bullet, true)
