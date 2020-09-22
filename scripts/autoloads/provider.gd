extends Node

var scenes_map = {}

func instance_powerup(powerup_name):
	if not scenes_map.has(powerup_name):
		scenes_map[powerup_name] = load("res://scenes/powerups/powerup-" + powerup_name + ".tscn")
	return scenes_map[powerup_name].instance()
