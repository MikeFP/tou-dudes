extends Node2D
class_name Powerup

var consumed = false
var player = null

signal taken
signal destroyed

func _ready():
	reappear()

func _on_body_entered(body: KinematicBody2D):
	if !consumed && body != null && body.is_in_group("players"):
		player = body
		on_player_consumed()
		consumed = true
		hide()
		$Area2D.disconnect("body_entered", self, "_on_body_entered")
		emit_signal("taken", self)
	
func reappear():
	$Area2D.connect("body_entered", self, "_on_body_entered")

func on_player_consumed():
	pass

func destroy():
	consumed = true
	hide()
	emit_signal("destroyed", self)
	queue_free()
