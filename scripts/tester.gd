extends Node2D

onready var controller = get_parent()

func _ready():
	test_routine()

func test_routine():
	yield(get_tree(), "idle_frame")
	controller.instance_powerup(1, 1, "speed")
	controller.instance_powerup(1, 1, "hold")
	controller.instance_powerup(1, 1, "punch")
	controller.instance_powerup(2, 3, "kick")
	controller.instance_powerup(1, 1, "ammo")

	controller.instance_powerup(13, 1, "speed")
	controller.instance_powerup(13, 1, "hold")
	controller.instance_powerup(13, 1, "punch")
	controller.instance_powerup(12, 3, "kick")
	controller.instance_powerup(13, 1, "ammo")