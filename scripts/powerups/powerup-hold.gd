extends Powerup

var bomb
var valid_input = false
onready var timer := $Timer

func on_player_consumed():
	player.connect("planted_bomb", self, "_player_planted_bomb")
	player.connect("grid_position_changed", self, "_player_moved_away")
	player.connect("animation_started", self, "_check_animation")

func _player_planted_bomb(new_bomb):
	bomb = new_bomb

	if !timer.is_connected("timeout", self, "_check_timer"):
		timer.connect("timeout", self, "_check_timer")
	timer.start()
	bomb.connect("exploded", self, "_cancel_hold")

	yield(get_tree(), "idle_frame")
	valid_input = true

func _check_animation(anim):
	if !player.holdingBomb && player.is_animating && anim.find("Lifting") == -1:
		print("called from anim")
		_cancel_hold()

func _check_timer():
	timer.disconnect("timeout", self, "_check_timer")
	timer.stop()
	if player.liftingBomb == null:
		_cancel_hold()

func _player_moved_away(_pos):
	if !player.liftingBomb:
		_cancel_hold()

func _cancel_hold():
	if bomb != null:
		valid_input = false
		bomb.disconnect("exploded", self, "_cancel_hold")
		bomb = null
		player.stop_holding()

func throw():
	player.throw()
	bomb.disconnect("exploded", self, "_cancel_hold")
	bomb = null

func _unhandled_key_input(event):
	if bomb != null:
		if valid_input && InputHandler.is_event_action_pressed(event, "main_action_1", player):
			player.lift(bomb)
			valid_input = false
		elif player.holdingBomb && InputHandler.is_event_action_released(event, "main_action_1", player):
			throw()

func _process(_delta):
	if bomb != null && player.holdingBomb && !InputHandler.is_action_pressed("main_action_1", player):
		throw()
