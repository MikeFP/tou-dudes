extends KinematicBody2D
var bomb_scene = preload("res://scenes/bomb.tscn")

enum Gaze { RIGHT, LEFT, DOWN, UP }

var speed = 48
var id
var gaze = Gaze.DOWN
var stance = "Idle"
var isIdle = true
var intensity = 2
var anim
var alive = true
var maxBombs = 1
var bombCount = 0
var isOverBomb = false
var lastXInput = Vector2()
var lastYInput = Vector2()
var lastVelocity = Vector2()

var is_animating = false

onready var controller = get_parent()
onready var punch_area = $"Punch Hitbox"

func _ready():
	anim = get_node("Sprite/AnimationPlayer")
	anim.connect("animation_finished", self, "_on_animation_finished")

func _process(_delta):
	z_index = int(position.y)
	if InputHandler.is_action_pressed("main_action_1", self):
		try_spawn_bomb()

func _physics_process(_delta):
	if !is_animating:
		var motion = Vector2()
		var yInput = Vector2()
		var xInput = Vector2()
		var oldPos = position
		
		if InputHandler.is_action_pressed("move_down", self):
			yInput = Vector2(0, 1)
		elif InputHandler.is_action_pressed("move_up", self):
			yInput = Vector2(0, -1)
		if InputHandler.is_action_pressed("move_right", self):
			xInput = Vector2(1, 0)
		elif InputHandler.is_action_pressed("move_left", self):
			xInput = Vector2(-1, 0)
		
		motion = (yInput + xInput).normalized() * speed
		
		var newV = move_and_slide(motion, Vector2(), false, 1)
		position = oldPos
		
		isIdle = true
		
		if motion.length() > 0:
			isIdle = false
			if abs(motion.x) > abs(motion.y):
				if xInput.x > 0:
					gaze = Gaze.RIGHT # facing right
				else:
					gaze = Gaze.LEFT # facing left
			else:
				if yInput.y < 0:
					gaze = Gaze.UP # facing up
				else:
					gaze = Gaze.DOWN # facing down
		
		motion = newV.normalized() * speed
		
		if newV.dot(motion.normalized()) >= 1:
			newV = move_and_slide(motion).normalized()
			
			if (gaze == Gaze.RIGHT or gaze == Gaze.LEFT) and abs(newV.y) - abs(newV.x) > 0.5:
				if newV.y < 0:
					gaze = Gaze.UP
				else:
					gaze = Gaze.DOWN
			elif (gaze == Gaze.UP or gaze == Gaze.DOWN) and abs(newV.x) - abs(newV.y) > 0.5:
				if newV.x < 0:
					gaze = Gaze.LEFT
				else:
					gaze = Gaze.RIGHT
			
			position.x = round(position.x)
			position.y = round(position.y)
		
		stance = "Idle";
		if !isIdle:
			stance = "Walk";

		anim.play(stance + get_animation_complement())

		lastXInput = xInput
		lastYInput = yInput
		lastVelocity = newV

func try_spawn_bomb():
	if bombCount < maxBombs:
		var gridPosition = controller.world_to_map(position)
		
		var canSpawn = true
		var bombs = get_parent().get_tree().get_nodes_in_group("bombs")
		for b in bombs:
			if b.gridPosition == gridPosition:
				canSpawn = false
				break
		
		if canSpawn and not isOverBomb:
			var bomb = bomb_scene.instance()
			bomb.player = self
			bomb.intensity = intensity
			bomb.controller = get_parent()
			get_parent().add_child(bomb)

			bomb.spawn(position)
			bombCount += 1

func die():
	if alive:
		alive = false

func increase_max_bombs():
	maxBombs += 1

func increase_intensity(quantity = 1):
	intensity += quantity

func increase_speed(units_per_second = 8):
	speed += units_per_second

func get_animation_complement():
	match gaze:
		Gaze.DOWN:
			return ""
		Gaze.RIGHT:
			return " Right"
		Gaze.LEFT:
			return " Left"
		Gaze.UP:
			return " Back"

func get_gaze_vector():
	match gaze:
		Gaze.DOWN:
			return Vector2.DOWN
		Gaze.RIGHT:
			return Vector2.RIGHT
		Gaze.LEFT:
			return Vector2.LEFT
		Gaze.UP:
			return Vector2.UP
			
func punch():
	if !is_animating:
		is_animating = true
		anim.play("Punch" + get_animation_complement())

func _check_punch_hit():
	punch_area.connect("body_entered", self, "_on_punch_hit")

func _on_punch_hit(body):
	if body.is_in_group("bombs"):
		body.throw(position + get_gaze_vector() * controller.CELL_WIDTH * 4)

func _on_animation_finished(anim_name):
	if is_animating:
		is_animating = false

	if anim_name.match("Punch*"):
		punch_area.disconnect("body_entered", self, "_on_punch_hit")
