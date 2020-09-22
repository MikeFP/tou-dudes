extends Node2D

var animation = "Center"
var calculated = false
var bomb

func start():
	$AnimationPlayer.play(animation)
	$AnimationPlayer.connect("animation_finished", self, "_on_animation_finished")

func _physics_process(_delta):
	for bodyInArea in $Area2D.get_overlapping_bodies():
		_on_body_entered(bodyInArea)

func _on_animation_finished(_anim_name: String):
	hide()
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
	bomb.queue_free()
	queue_free()

func _on_body_entered(body: PhysicsBody2D):	
	if body != null:
		if body.is_in_group("players"):
			body.die()
		if body.is_in_group("bombs"):
			body.explode()
