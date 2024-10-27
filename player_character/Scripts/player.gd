class_name Player extends CharacterBody2D

@export var MAX_SPEED := 150.0
@export var ACCELERATION := 6.0
@export var DECELERATION := 15.0

var m_Speed := 0.0;
var m_SpeedOverride := 0.0
@onready var animation: AnimatedSprite2D = $Animation
@onready var spotted_sound: AudioStreamPlayer = $SpottedSound

var epsilon := 0.5; # close enough to 0s
var isScaring := false;
var detected := false;

var m_Keys: Array[Key] = [KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT, KEY_B, KEY_A, KEY_ENTER]
var m_KeyIndex: int = 0;

func StopFuckingMoving() -> void:
	detected = true;
	animation.stop();
	Input.is_physical_key_pressed(KEY_UP)
	
func _physics_process(delta: float) -> void:
	if (detected):
		return;
		
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

func _input(event: InputEvent) -> void:
	var just_pressed := event.is_pressed() and not event.is_echo()
	if (!just_pressed):
		return;
	
	var key := m_Keys[m_KeyIndex];			
	if Input.is_physical_key_pressed(key):
		m_KeyIndex += 1;
		if (m_KeyIndex >= m_Keys.size()):
			DoSomeMagic();
			m_KeyIndex = 0
	else:
		m_KeyIndex = 0

func DoSomeMagic() -> void:
	var tween := get_tree().create_tween().bind_node(self)
	tween.tween_property($Animation, "scale", Vector2(2.0, 2.0), 0.5).set_trans(Tween.TRANS_ELASTIC)
	tween.parallel().tween_property($Animation, "rotation", deg_to_rad(360), 0.5);
	tween.tween_property($Animation, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property($Animation, "rotation", deg_to_rad(0), 0.5);
	
	get_tree().call_group("Enemy", "DoSomeMagic");

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

	
	
func PlaySolidSnakeSoundPrettyPlease() -> void:
	spotted_sound.play();
	
func CalculateSpeed(delta: float, isAccelerating: bool) -> void:
	if (m_SpeedOverride && isAccelerating):
		m_Speed = m_SpeedOverride
		return;
		
	var desiredSpeed := MAX_SPEED if isAccelerating else 0.0
	var acceleration := ACCELERATION if isAccelerating else DECELERATION
	m_Speed = lerp(m_Speed, desiredSpeed, acceleration*delta);
	
	if (abs(desiredSpeed - m_Speed) <= epsilon):
		m_Speed = desiredSpeed;
