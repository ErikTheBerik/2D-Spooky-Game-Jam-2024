extends CharacterBody2D

@export var MAX_SPEED := 150.0
@export var ACCELERATION := 6.0
@export var DECELERATION := 10.0

var m_Speed := 0.0;
var m_SpeedOverride := 0.0

var epsilon := 0.5; # close enough to 0


func _physics_process(delta: float) -> void:

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	var isAccelerating := direction != Vector2.ZERO;

	if (!isAccelerating):
		direction = velocity.normalized()

	CalculateSpeed(delta, isAccelerating);
			
	velocity = direction * m_Speed
	move_and_slide()

func CalculateSpeed(delta: float, isAccelerating: bool) -> void:
	if (m_SpeedOverride && isAccelerating):
		m_Speed = m_SpeedOverride
		return;
		
	var desiredSpeed := MAX_SPEED if isAccelerating else 0.0
	var acceleration := ACCELERATION if isAccelerating else DECELERATION
	m_Speed = lerp(m_Speed, desiredSpeed, acceleration*delta);
	
	if (abs(desiredSpeed - m_Speed) <= epsilon):
		m_Speed = desiredSpeed;
