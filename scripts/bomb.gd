extends KinematicBody2D
var explosion_scene = preload("res://scenes/explosion.tscn")

var controller

var activateCollision = false
var intensity = 2
var gridPosition = Vector2()
var has_exploded = false
var player

var players_in_area = []

export var slide_speed = 64.0
export var delay = 2.25
var move_direction = Vector2()

var throw_distance = Vector2()
var original_position = Vector2()
var throw_duration
var throw_height

onready var tween: Tween = $Tween
onready var anim := $"Sprite/AnimationPlayer"
onready var timer := $Timer
onready var area2d := $Area2D
onready var collider := $CollisionShape2D

signal exploded

func _ready():
	anim.play("Charging")
	
	timer.connect("timeout", self, "explode")
	
	area2d.connect("body_entered", self, "_on_body_enter")
	area2d.connect("body_exited", self, "_on_body_exit")
	
	disable_collision()
	
	$Sprite.visible = false
	activateCollision = false
	has_exploded = false

func _process(_delta):
	if collider.disabled and activateCollision:
		activateCollision = false
		enable_collision()

func _physics_process(delta):
	if move_direction != Vector2():
		var col = move_and_collide(move_direction * slide_speed * delta, true, true, true)

		var angle
		if col:
			angle = rad2deg(col.normal.angle_to(move_direction))

		if !col || (abs(angle) > 60 && abs(angle) < 120):
			position += move_direction * slide_speed * delta
		else:
			stop_slide()

		update_grid_position()
	
	if throw_distance != Vector2():
		if controller.is_out_of_bounds(controller.world_to_map(position)) != Vector2():
			var warp_dir = controller.is_out_of_bounds(controller.world_to_map(throw_distance + original_position))
			if warp_dir != Vector2():
				warp_throw(original_position + warp_dir * (controller.world_columns + 1) * controller.CELL_WIDTH)

func _on_body_enter(body: PhysicsBody2D):
	if body != null and body.is_in_group("players") && move_direction == Vector2():
		if throw_distance == Vector2():
			body.add_collision_exception_with(self)
			body.isOverBomb = true
		players_in_area.append(body)

func _on_body_exit(body: PhysicsBody2D):
	if body != null:
		body.remove_collision_exception_with(self)
		if body.is_in_group("players"):
			body.isOverBomb = false
			players_in_area.remove(players_in_area.find(body))

func enable_collision():
	collider.set_deferred("disabled", false)

func disable_collision():
	collider.set_deferred("disabled", true)

func spawn(pos: Vector2):
	position = pos
	snap_to_grid()

	activateCollision = true
	$Sprite.visible = true
	timer.start(delay)

func explode():
	if !has_exploded:
		disable_collision()
		has_exploded = true
		
		anim.stop()
		timer.stop()
		
		controller.delete_cell_content(gridPosition.x, gridPosition.y, self)
		hide()
		_instance_explosion_sprites()

		player.bombCount -= 1

		emit_signal("exploded")
		queue_free()
	

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
		
		var content = controller.get_cell_content(absPos)
		var is_obstacle = false
		for c in content:
			if typeof(c) == TYPE_INT:
				is_obstacle = true
			elif !c.is_in_group("bombs") && c.has_method("destroy"):
				is_obstacle = true
				c.destroy()
				break
		
		if is_obstacle && isBody:
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
	snap_to_grid()

func throw(target: Vector2, duration := 0.25, height := 1.0, upwards_motion = true):
	
	disable_collision()
	suspend_timer()
	
	original_position = position
	throw_distance = target - position
	throw_duration = duration
	throw_height = null
	if upwards_motion:
		throw_height = height
	
	_setup_throw_animation()
			
	tween.start()
	yield(tween, "tween_all_completed")

	position = original_position + throw_distance
	snap_to_grid()

	var content = controller.get_cell_content(gridPosition)
	for i in content:
		if typeof(i) == TYPE_INT || (i.is_in_group("bombs") && i != self):
			bounce((throw_distance).normalized().snapped(Vector2(1, 1)))
			return
	
	for p in players_in_area:
		p.add_collision_exception_with(self)
		p.isOverBomb = true
		p.stun()
	
	throw_distance = Vector2()
	resume_timer()
	enable_collision()

func _setup_throw_animation():
	var target = original_position + throw_distance

	tween.interpolate_property(self, "position:x",
		original_position.x, target.x, throw_duration, Tween.TRANS_LINEAR, Tween.EASE_IN)
	
	if throw_height != null:
		var max_y = original_position.y - controller.CELL_WIDTH * throw_height
		tween.interpolate_property(self, "position:y",
			original_position.y, max_y, throw_duration/2, Tween.TRANS_QUAD, Tween.EASE_OUT)
		tween.interpolate_property(self, "position:y",
			max_y, target.y, throw_duration/2, Tween.TRANS_QUAD, Tween.EASE_IN, throw_duration/2)
			
	else:
		tween.interpolate_property(self, "position:y",
			original_position.y, target.y, throw_duration, Tween.TRANS_QUAD, Tween.EASE_IN)

func bounce(direction: Vector2):
	throw(position + direction.normalized() * controller.CELL_WIDTH, 0.15, 0.5)

func warp_throw(new_origin: Vector2):
	original_position = new_origin
	_setup_throw_animation()
	
func snap_to_grid():
	update_grid_position()
	position = controller.map_to_world(gridPosition) + Vector2(8, 8)

func update_grid_position():
	var oldPos = gridPosition
	gridPosition = controller.world_to_map(position)
	if oldPos != gridPosition:
		controller.move_cell_content(self, gridPosition, oldPos)

func suspend_timer():
	timer.paused = true

func resume_timer():
	timer.paused = false
