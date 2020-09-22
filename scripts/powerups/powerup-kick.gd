extends Powerup

func _physics_process(_delta):
	if player != null:
		var count = player.get_slide_count()
		for i in range(count):
			var col = player.get_slide_collision(i)
			if col.collider.is_in_group("bombs"):
				kick(col.collider)

func kick(bomb):
	var dir = player.lastVelocity.normalized().snapped(Vector2(1,1))
	if dir != Vector2():
		if abs(dir.x) == abs(dir.y):
			dir.y = 0
		print(dir)
		bomb.slide(dir)
