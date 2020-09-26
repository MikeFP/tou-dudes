extends Powerup

var bombsInPunchArea = []

func _unhandled_key_input(event):
	if player != null && InputHandler.is_event_action_pressed(event, "side_action_1", player):
		player.punch()

func on_player_consumed():
	player.punch_area.connect("body_entered", self, "_on_punch_entered")
	player.punch_area.connect("body_exited", self, "_on_punch_exited")
	player.connect("animation_started", self, "_check_animation")

func _check_animation(anim):
	if anim.find("Punch") != -1:
		_check_punch_hit()

func _check_punch_hit():
	if len(bombsInPunchArea) > 0:
		var bomb = bombsInPunchArea[-1]
		bomb.throw(bomb.position + player.get_gaze_vector() * player.controller.CELL_WIDTH * 3)

func _on_punch_entered(body):
	if body.is_in_group("bombs"):
		bombsInPunchArea.append(body)
	
func _on_punch_exited(body):
	if body in bombsInPunchArea:
		bombsInPunchArea.remove(bombsInPunchArea.find(body))