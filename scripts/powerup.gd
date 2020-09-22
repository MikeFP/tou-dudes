extends Node2D
class_name Powerup

var consumed = false

signal taken
signal destroyed

func _ready():
	$Area2D.connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body: KinematicBody2D):
	if !consumed && body != null && body.is_in_group("players"):
		on_player_consumed(body)
		consumed = true
		hide()
		emit_signal("taken", self)
		queue_free()

func on_player_consumed(_player):
	pass

func destroy():
	consumed = true
	hide()
	emit_signal("destroyed", self)
	queue_free()
