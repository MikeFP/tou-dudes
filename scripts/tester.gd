extends Node2D

onready var controller = get_parent()

func _ready():
	test_routine()

func test_routine():
	yield(get_tree(), "idle_frame")
	controller.instance_powerup(2, 1, "punch")
	controller.instance_powerup(2, 3, "intensity")
	controller.instance_powerup(2, 5, "speed")
	controller.instance_powerup(2, 7, "kick")
	controller.instance_powerup(2, 9, "ammo")