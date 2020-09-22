extends Sprite

signal destroyed

func _ready():
	$AnimationPlayer.play("Idle")

func destroy():
	$AnimationPlayer.connect("animation_finished", self, "_on_animation_finished")
	$AnimationPlayer.play("Destroy")
	emit_signal("destroyed", self)

func _on_animation_finished(_anim):
	hide()
	queue_free()
