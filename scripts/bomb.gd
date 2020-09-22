extends KinematicBody2D
var explosion_scene = preload("res://scenes/explosion.tscn")

var timer
var area2d
var collider
var anim
var controller

var activateCollision = false
var intensity = 2
var gridPosition = Vector2()
var exploded = false
var player

export var slide_speed = 64.0
export var delay = 2.25
var move_direction = Vector2()

func _ready():

	anim = get_node("Sprite/AnimationPlayer")
	anim.play("Charging")
	
	timer = $Timer
	timer.connect("timeout", self, "explode")
	
	area2d = $Area2D
	area2d.connect("body_entered", self, "_on_body_enter")
	area2d.connect("body_exited", self, "_on_body_exit")
	
	collider = get_node("CollisionShape2D")
	_disable_collision()
	
	$Sprite.visible = false
	activateCollision = false
	exploded = false

func _process(_delta):
	if collider.disabled and activateCollision:
		activateCollision = false
		_enable_collision()

func _physics_process(_delta):
	if move_direction != Vector2():
		var vel = move_and_slide(move_direction * slide_speed)

		if vel.length() < 5:
			stop_slide()

		gridPosition = controller.world_to_map(position)

func _on_body_enter(body: PhysicsBody2D):
	if move_direction == Vector2() && body != null and body.is_in_group("players"):
		body.add_collision_exception_with(self)
		body.isOverBomb = true

func _on_body_exit(body: PhysicsBody2D):
	if body != null:
		body.remove_collision_exception_with(self)
		if body.is_in_group("players"):
			body.isOverBomb = false

func _enable_collision():
	collider.disabled = false
	collider.set_deferred("disabled", false)

func _disable_collision():
	collider.disabled = true
	collider.set_deferred("disabled", true)

func spawn(pos: Vector2):
	position = pos
	activateCollision = true
	$Sprite.visible = true
	timer.start(delay)

func explode():
	if not exploded:
		_disable_collision()
		exploded = true
		
		anim.stop()
		timer.stop()
		
		_instance_explosion_sprites()
		hide()
		player.bombCount -= 1
	

func _instance_explosion_sprites():	
	var directions = [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)]
	
	var dist = 0
	var over = false
	var i = 0
	var dir
	var relPos
	var absPos
	var isBody = false
	
	while not over:
		dir = directions[i]
		var anim = "Center"
		relPos = dist * dir
		isBody = true
		
		if dir != Vector2(0,0):
			if dist < intensity:
				anim = "Body H"
				dist += 1
				
				if dir.y != 0:
					anim = "Body V"
			else:
				anim = "Edge "
				i += 1
				dist = 1
				isBody = false
				
				match dir:
					Vector2(1, 0):
						anim += "Right"
					Vector2(-1, 0):
						anim += "Left"
					Vector2(0, 1):
						anim += "Down"
					Vector2(0, -1):
						anim += "Up"
		else:
			i += 1
			dist = 1
			isBody = false
		
		absPos = gridPosition + relPos
		var finalPos = controller.map_to_world(absPos) + Vector2(8, 8)
		
		var content = controller.get_cell_content(int(absPos.x), int(absPos.y))
		
		if len(content) > 0:
			var what = content[-1]
			if typeof(what) != TYPE_STRING and what.has_method("destroy"):
				what.destroy()
				
			if isBody:
				i += 1
				dist = 1

		else:
			var explosion = explosion_scene.instance()
			explosion.animation = anim
			explosion.bomb = self
			get_parent().add_child(explosion)
			explosion.position = finalPos
			explosion.start()
		
		if i >= directions.size():
			over = true

func slide(direction: Vector2):
	move_direction = direction

func stop_slide():
	move_direction = Vector2()
