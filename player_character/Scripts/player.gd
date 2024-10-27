class_name Player extends CharacterBody2D

@export var MAX_SPEED := 150.0
@export var ACCELERATION := 6.0
@export var DECELERATION := 15.0

var m_Speed := 0.0;
var m_SpeedOverride := 0.0
@onready var animation: AnimatedSprite2D = $Animation

var epsilon := 0.5; # close enough to 0
var isScaring := false;

func _physics_process(delta: float) -> void:
	if (!isScaring):
		animation.flip_h = false;
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	var isAccelerating := direction != Vector2.ZERO;

	if (!isAccelerating):
		direction = velocity.normalized()

	CalculateSpeed(delta, isAccelerating);
			
	velocity = direction * m_Speed
	if (isScaring):
		velocity = Vector2.ZERO;
	else:
		if velocity.length() <= epsilon:
			animation.play("idle");
		else:
			PlayWalkAnimation();
		
	move_and_slide()

func PlayWalkAnimation() -> void:
	var animDir := GetDirectionString();
	if (animDir == "left"):
		animation.flip_h = true;
		animDir = "right";
	
	animation.play("walk_" + animDir)
	
func GetDirectionString() -> String:
	var angle := velocity.angle()

	if abs(angle) <= (PI / 4)+0.1:  # Right
		return "right";
	elif abs(angle) > (3 * PI / 4)-0.1:  # Left
		return "left"
	elif angle > PI / 4 and angle <= 3 * PI / 4:  # Down
		return "down"
	elif angle < -PI / 4 and angle >= -3 * PI / 4:  # Up
		return "up"
	
	return "right"

	
func CalculateSpeed(delta: float, isAccelerating: bool) -> void:
	if (m_SpeedOverride && isAccelerating):
		m_Speed = m_SpeedOverride
		return;
		
	var desiredSpeed := MAX_SPEED if isAccelerating else 0.0
	var acceleration := ACCELERATION if isAccelerating else DECELERATION
	m_Speed = lerp(m_Speed, desiredSpeed, acceleration*delta);
	
	if (abs(desiredSpeed - m_Speed) <= epsilon):
		m_Speed = desiredSpeed;
