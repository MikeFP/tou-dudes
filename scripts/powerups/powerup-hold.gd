extends Powerup

var bomb
var valid_input = false
onready var timer := $Timer

func on_player_consumed():
	player.connect("planted_bomb", self, "_player_planted_bomb")
	player.connect("grid_position_changed", self, "_lift_window_over")
	player.connect("animation_started", self, "_check_animation")

func _player_planted_bomb(new_bomb):
	bomb = new_bomb
	timer.connect("timeout", self, "_lift_window_over", [null])
	timer.start()

	yield(get_tree(), "idle_frame")
	valid_input = true

func _check_animation(anim):
	if !player.holdingBomb && player.is_animating && anim.find("Lifting") == -1:
		_lift_window_over(null)

func _lift_window_over(_obj):
	if player.liftingBomb == null && bomb != null:
		bomb = null
		timer.disconnect("timeout", self, "_lift_window_over")
		timer.stop()
		valid_input = false

func _unhandled_key_input(event):
	if bomb != null:
		if valid_input && InputHandler.is_event_action_pressed(event, "main_action_1", player):
			player.lift(bomb)

			valid_input = false
			timer.disconnect("timeout", self, "_lift_window_over")
			timer.stop()
		elif player.holdingBomb && InputHandler.is_event_action_released(event, "main_action_1", player):
			player.throw()

			bomb = null

func _process(_delta):
	if bomb != null && player.holdingBomb && !InputHandler.is_action_pressed("main_action_1", player):
		player.throw()
		bomb = null
