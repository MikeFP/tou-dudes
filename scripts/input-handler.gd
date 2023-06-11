extends Node2D

export var playerCount = 2
var bindings = [
	{
		"main_action_1": "F",
		"main_action_2": "G",
		"side_action_1": "H",
		"side_action_2": "Y",
		"move_up": "W",
		"move_down": "S",
		"move_left": "A",
		"move_right": "D"
	},
	{
		"main_action_1": "Comma",
		"main_action_2": "Period",
		"side_action_1": "Slash",
		"side_action_2": "Semicolon",
		"move_up": "8",
		"move_down": "5",
		"move_left": "4",
		"move_right": "6"
	}
]
var players

func _ready():
	players = get_parent().get_tree().get_nodes_in_group("players")
	var i = 0
	for p in players:
		p.id = i
		i += 1

func is_action_just_pressed(action: String, player: Node2D):
	return Input.is_action_just_pressed(action + "_p" + str(player.id + 1))

func is_action_pressed(action: String, player: Node2D):
	return Input.is_action_pressed(action + "_p" + str(player.id + 1))

func is_action_just_released(action: String, player: Node2D):
	return Input.is_action_just_released(action + "_p" + str(player.id + 1))

func is_event_action_pressed(event: InputEvent, action: String, player: Node2D):
	return event.is_action_pressed(action + "_p" + str(player.id + 1))

func is_event_action_released(event: InputEvent, action: String, player: Node2D):
	return event.is_action_released(action + "_p" + str(player.id + 1))
