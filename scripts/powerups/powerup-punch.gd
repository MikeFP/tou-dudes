extends Powerup

func _unhandled_key_input(event):
	if player != null && InputHandler.is_event_action_pressed(event, "side_action_1", player):
		player.punch()