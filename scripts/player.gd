extends KinematicBody2D
var bomb_scene = preload("res://scenes/bomb.tscn")

# Member variables
const MOTION_SPEED = 48 # Pixels/second
var id
var gaze = 0
var isIdle = true
var intensity = 2
var anim
var alive = true
var maxBombs = 1
var bombCount = 0
var isOverBomb = false

onready var controller = get_parent()

func _ready():
	anim = get_node("Sprite/AnimationPlayer")

func handle_action(action: String):
	pass

func _process(delta):
	z_index = position.y
	if InputHandler.is_action_pressed("main_action_1", self):
		try_spawn_bomb()

func _physics_process(_delta):
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
	
	motion = (yInput + xInput).normalized() * MOTION_SPEED
	
	var newV = move_and_slide(motion, Vector2(), false, 1)
	position = oldPos
	
	isIdle = true
	
	if motion.length() > 0:
		isIdle = false
		if abs(motion.x) > abs(motion.y):
			if xInput.x > 0:
				gaze = 1 # facing right
			else:
				gaze = -1 # facing left
		else:
			if yInput.y < 0:
				gaze = 2 # facing up
			else:
				gaze = 0 # facing down
	
	motion = newV.normalized() * MOTION_SPEED
	
	if newV.dot(motion.normalized()) >= 1:
		newV = move_and_slide(motion).normalized()
		
		if (gaze == 1 or gaze == -1) and abs(newV.y) - abs(newV.x) > 0.5:
			if newV.y < 0:
				gaze = 2
			else:
				gaze = 0
		elif (gaze == 0 or gaze == 2) and abs(newV.x) - abs(newV.y) > 0.5:
			if newV.x < 0:
				gaze = -1
			else:
				gaze = 1
		
		position.x = round(position.x)
		position.y = round(position.y)
	
	var stance = "Idle";
	if !isIdle:
		stance = "Walk";

	match gaze:
		0:
			anim.play(stance)
		1:
			anim.play(stance + " Right")
		-1:
			anim.play(stance + " Left")
		2:
			anim.play(stance + " Back")

func try_spawn_bomb():
	if bombCount < maxBombs:
		var gridPosition = controller.world_to_map(position)
		
		var canSpawn = true
		var bombs = get_parent().get_tree().get_nodes_in_group("bomb scripts")
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
			
			var tilePos: Vector2 = controller.map_to_world(gridPosition)
			var pos = tilePos + Vector2(8, 8)
			
			bomb.gridPosition = gridPosition
			bomb.spawn(pos)
			bombCount += 1

func die():
	if alive:
		alive = false

func increase_max_bombs():
	maxBombs += 1

func increase_intensity(quantity = 1):
	intensity += quantity
