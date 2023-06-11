extends KinematicBody2D
var bomb_scene = preload("res://scenes/bomb.tscn")

enum Gaze { RIGHT, LEFT, DOWN, UP }

var id

var speed = 48
var intensity = 2
var maxBombs = 1
var bombCount = 0
var gaze = Gaze.DOWN
var stance = "Idle"

var alive = true
var isIdle = true
var isOverBomb = false
var is_animating = false
var holdingBomb = false

var gridPosition = Vector2()
var lastXInput = Vector2()
var lastYInput = Vector2()
var lastVelocity = Vector2()
var liftingBomb

var bombsInPunchArea = []

onready var anim = $"Sprite/AnimationPlayer"
onready var controller = get_parent()
onready var punch_area = $"Punch Hitbox"

signal planted_bomb
signal grid_position_changed
signal animation_started
signal animation_finished

func _ready():
	anim.connect("animation_started", self, "_on_animation_started")
	anim.connect("animation_finished", self, "_on_animation_finished")

func _process(_delta):
	if !alive:
		return

	z_index = int(position.y)

	if InputHandler.is_action_pressed("main_action_1", self):
		try_spawn_bomb()

	_update_holding_item_position()

func _physics_process(_delta):
	if !alive:
		return

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
		
		# FIXME: For some reason, this movement logic makes the Speed
		# powerup bugged. The speed increase is only noticeable once
		# the speed changes to a multiple of the initial speed
		# (that is, `speed = initial_speed * n`). The problem might be
		# linked to the amount of collisions around the player, which
		# could be limiting the slide vector somehow.
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
		
		stance = "Idle"
		if !isIdle:
			stance = "Walk"
			if holdingBomb:
				stance = "Walking Holding"
		elif holdingBomb:
			stance = "Holding"

		anim.play(stance + get_animation_complement())

		lastXInput = xInput
		lastYInput = yInput
		lastVelocity = newV

		_update_punch_hitbox_position()

	update_grid_position()

func try_spawn_bomb():
	if !isOverBomb && !holdingBomb && bombCount < maxBombs:		
		var canSpawn = true
		var content = controller.get_cell_content(gridPosition)
		for item in content:
			if item != null && typeof(item) != TYPE_INT && item.is_in_group("bombs"):
				canSpawn = false
				break
		
		if canSpawn:
			var bomb = bomb_scene.instance()
			bomb.player = self
			bomb.intensity = intensity
			bomb.controller = controller
			controller.add_child(bomb)

			bomb.spawn(position)
			bombCount += 1

			emit_signal("planted_bomb", bomb)

func update_grid_position():
	var old_pos = gridPosition
	gridPosition = controller.world_to_map(position)
	if gridPosition != old_pos:
		emit_signal("grid_position_changed", gridPosition)

func die():
	if alive:
		alive = false
	hide()
	collision_layer = 0
	collision_mask = 0

func increase_max_bombs():
	maxBombs += 1

func increase_intensity(quantity = 1):
	intensity += quantity

func increase_speed(units_per_second = 12):
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
	if !is_animating && !holdingBomb:
		is_animating = true
		anim.play("Punch" + get_animation_complement())

func _update_punch_hitbox_position():
	punch_area.position = get_gaze_vector() * 12

func _on_animation_started(anim_name):
	emit_signal("animation_started", anim_name)

func _on_animation_finished(anim_name):
	if is_animating:
		is_animating = false
	
	emit_signal("animation_finished", anim_name)

func lift(bomb):
	if !is_animating:
		is_animating = true
		anim.play("Lifting" + get_animation_complement())
		liftingBomb = bomb
		controller.delete_cell_content(bomb.gridPosition.x, bomb.gridPosition.y, bomb)

func _start_holding():
	if liftingBomb != null:
		holdingBomb = true
		liftingBomb.suspend_timer()
		liftingBomb.disable_collision()
		_update_holding_item_position()

func _update_holding_item_position():
	if holdingBomb:
		liftingBomb.position = position + Vector2(0, -16)
		liftingBomb.z_index = z_index + 10

func throw():
	if liftingBomb != null:
		# is_animating = true
		# anim.play("Lifting" + get_animation_complement())
		liftingBomb.throw(position + get_gaze_vector() * controller.CELL_WIDTH * 3, 0.25, 1.0, false)
		liftingBomb = null
		stop_holding()

func stop_holding():
	holdingBomb = false
	throw()

func stun():
	stop_holding()
	is_animating = true
	anim.play("Stun")
