extends CharacterBody2D

var speed := 425
var acceleration := 800
var deceleration := 1000
var axis := Vector2.ZERO

func _physics_process(delta: float) -> void:

	axis.x = Input.get_action_strength("move_right")-Input.get_action_strength("move_left")
	axis.y = Input.get_action_strength("move_down")-Input.get_action_strength("move_up")

	axis = axis.normalized() * speed

	velocity = velocity.lerp(axis, delta*10)

	move_and_slide()
