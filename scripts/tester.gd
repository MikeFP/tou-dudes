extends Node2D

onready var controller = get_parent()

func _ready():
	test_routine()

func test_routine():
	yield(get_tree(), "idle_frame")
	controller.instance_powerup(2, 1, "ammo")
	controller.instance_powerup(2, 3, "intensity")