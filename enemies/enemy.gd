@tool
 
class_name Enemy extends CharacterBody2D

enum State {
	Idle,
	Walking,
	Talking,
	Scared,
	PlayerDetected
}

@export var MIN_SPEED: float = 100.0
@export var MAX_SPEED: float = 200.0

@export var ROTATION_SPEED: float= 5.0
@export var alert_color: Color
@export var vision_color: Color

@export_group("Idle")
@export var MIN_IDLE_TIME: float = 2.0
@export var MAX_IDLE_TIME: float = 5.0

@export_group("Talking")
@export var MIN_TALK_TIME: float = 3.0
@export var MAX_TALK_TIME: float = 8.0

@export_group("Walking")
@export var POINTS_A: Array[Vector2] = []
@export var POINTS_B: Array[Vector2] = []

@export_group("Debug")
@export var RENDER_POINTS: bool = true
@export var RENDER_POINT_LINES: bool = true

@onready var navigation: NavigationAgent2D = $NavigationAgent2D
@onready var vision_cone: VisionCone2D = $VisionCone2D
@onready var vision_renderer: Polygon2D = $VisionCone2D/VisionConeRenderer
@onready var m_Speed := randf_range(MIN_SPEED, MAX_SPEED)
@onready var animation: AnimatedSprite2D = $Animation
@onready var scare_icon: Sprite2D = $ScareIcon
@onready var exclamation: Sprite2D = $Exclamation
@onready var idle_vfx: GPUParticles2D = $idle_vfx

var m_DetectionValue := 0.0;
var m_Detecting := false;
var pointRadius: float = 10.0;

var m_State: State = State.Idle;
var m_Timer: float = 0.0;
var m_GoingToA: bool = true;
var m_Direction := Vector2.ZERO;
var m_TargetPos := Vector2.ZERO;
var m_Height := 0.0;
var DETECTION_TIME: float = 0.3;


func _ready() -> void:
	exclamation.visible = false;
	scare_icon.visible = false
	m_Direction = Vector2.RIGHT;
	vision_renderer.color = vision_color
	InputMap.load_from_project_settings()
	
	
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return;
	
	if (m_State != State.Idle):
		idle_vfx.emitting = false;
		
	ProcessDetection(delta)
	animation.flip_h = false;
	
	match m_State:
		State.Idle:
			ProcessIdleAnimation(delta);
		State.Walking:
			ProcessWalkingAnimation(delta);
		State.Talking:
			return;
		State.Scared:
			return;	
	
func ProcessDetection(delta: float) -> void:
	if (m_State == State.PlayerDetected or m_State == State.Scared):
		return;
		
	if (m_Detecting):
		m_DetectionValue += delta;
		if (m_DetectionValue >= DETECTION_TIME):
			get_tree().call_group("Enemy", "OnDetect")
			get_tree().call_group("Player", "StopFuckingMoving");
			get_tree().call_group("Player", "PlaySolidSnakeSoundPrettyPlease");
	else:
		m_DetectionValue -= delta;
		m_DetectionValue = maxf(0.0, m_DetectionValue);	
		
	vision_renderer.color = lerp(vision_color, alert_color, m_DetectionValue/DETECTION_TIME)
		
func OnDetect() -> void:
	SetState(State.PlayerDetected)
	ClearNodes();
	velocity = Vector2.ZERO;
	animation.stop();
	vision_renderer.color = alert_color;
	m_DetectionValue = DETECTION_TIME;
	TweenExclamation(20);
	
	
func TweenExclamation(height: float) -> void:
	exclamation.visible = true;
	var pos := exclamation.position
	var scale := exclamation.scale;
	var tween := get_tree().create_tween().bind_node(self);
	
	tween.tween_property(exclamation, "position", pos + Vector2(0.0, -35.0), 0.8).set_trans(Tween.TRANS_ELASTIC);
	tween.parallel().tween_property(exclamation, "scale", scale*1.8, 0.8).set_trans(Tween.TRANS_ELASTIC);
	tween.parallel().tween_property(animation, "position", pos + Vector2(0.0, -height), 0.8).set_trans(Tween.TRANS_ELASTIC);
	
	tween.tween_property(exclamation, "position", pos, 0.3).set_trans(Tween.TRANS_LINEAR);
	tween.parallel().tween_property(exclamation, "scale", scale, 0.3).set_trans(Tween.TRANS_LINEAR);
	tween.parallel().tween_property(animation, "position", pos, 0.3).set_trans(Tween.TRANS_LINEAR);
	tween.tween_callback(TimedRestart)
	
func TimedRestart() -> void:
	var timer := Timer.new()
	timer.wait_time = 1.0  # Set delay to 1 second
	timer.one_shot = true  # Run only once
	add_child(timer)       # Add to the scene tree
	timer.start()
	timer.timeout.connect(Restart);
	
	
func DoSomeMagic() -> void:
	var tween := Jump(100);
	tween.tween_property($Animation, "scale", Vector2(2.0, 2.0), 0.5).set_trans(Tween.TRANS_ELASTIC)
	tween.parallel().tween_property($Animation, "rotation", deg_to_rad(360), 0.5);
	tween.tween_property($Animation, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property($Animation, "rotation", deg_to_rad(0), 0.5);
	
func Restart() -> void:
	get_tree().root.get_child(0).OnGameOver();

func Jump(height: float, tween: Tween = null) -> Tween:
	if !tween:
		tween = get_tree().create_tween().bind_node(self)
		
	var pos := animation.position
	tween.tween_property(animation, "position", pos + Vector2(0.0, -height), 0.8).set_trans(Tween.TRANS_ELASTIC);
	tween.tween_property(animation, "position", pos, 0.3).set_trans(Tween.TRANS_LINEAR);
	
	return tween;

func Scare() -> void:
	var tween := get_tree().create_tween().bind_node(self)
	tween.tween_property($Animation, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_EXPO)
	tween.tween_callback(PlayScare)
	tween.tween_property($Animation, "scale", Vector2(1.5, 1.5), 0.5).set_trans(Tween.TRANS_EXPO)
	tween.tween_property($Animation, "scale", Vector2(), 0.8).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_callback(queue_free)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw();
		if SelectedInEditor():
			if Input.is_action_just_pressed("NEW_POINT_A"):
				if POINTS_A.size() == 0:
					POINTS_A = [];
				HandleNewPosition(POINTS_A);
			elif Input.is_action_just_pressed("NEW_POINT_B"):
				if POINTS_B.size() == 0:
					POINTS_B = [];
				HandleNewPosition(POINTS_B)
		return;
		
	RotateConeVision();
	
	match m_State:
		State.Idle:
			ProcessIdle(delta);
		State.Walking:
			ProcessWalking(delta);
		State.Talking:
			return;
		State.Scared:
			ProcessScared(delta);
			
	move_and_slide()

func RotateConeVision() -> void:
	vision_cone.rotation = m_Direction.angle() + deg_to_rad(270)

## REMOVE THIS BEFORE EXPORT!!
func SelectedInEditor() -> bool:
	#if !Engine.is_editor_hint():
		#return false;
	#var nodes := EditorInterface.get_selection().get_selected_nodes();
	#return nodes.size() > 0 && nodes[0] == self;
	return false;

func _draw() -> void:		
	if SelectedInEditor():
		DrawPoints(POINTS_A, Color.RED);
		DrawLines(POINTS_A, Color.RED);
		
		DrawPoints(POINTS_B, Color.BLUE);
		DrawLines(POINTS_B, Color.BLUE);


func HandleNewPosition(points: Array[Vector2]) -> void:
	var pos := get_global_mouse_position();
	for i in points.size():
		var point := points[i]
		if ((point - pos).length() <= pointRadius):
			points.remove_at(i)
			return;
			
	points.push_back(pos)

func DrawPoints(points: Array[Vector2], color: Color) -> void:
	if !RENDER_POINTS:
		return;
		
	for pos in points:
		draw_circle(pos - global_position, pointRadius, color)
	
func DrawLines(points: Array[Vector2], color: Color) -> void:
	if !RENDER_POINT_LINES:
		return;
	
	color.a = 0.5
	for pos in points:
		draw_line(Vector2.ZERO, pos - global_position, color, 1.0, true)

func GetBasicDirectionVector() -> Vector2:
	var angle := m_Direction.angle()

	if abs(angle) <= PI / 4:  # Right
		return Vector2.RIGHT
	elif angle > PI / 4 and angle <= 3 * PI / 4:  # Down
		return Vector2.DOWN
	elif abs(angle) > 3 * PI / 4:  # Left
		return Vector2.LEFT
	elif angle < -PI / 4 and angle >= -3 * PI / 4:  # Up
		return Vector2.UP
	
	return Vector2.RIGHT
	
func GetDirectionString() -> String:
	var angle := m_Direction.angle()

	if abs(angle) <= PI / 4:  # Right
		return "right";
	elif angle > PI / 4 and angle <= 3 * PI / 4:  # Down
		return "down"
	elif abs(angle) > 3 * PI / 4:  # Left
		return "left"
	elif angle < -PI / 4 and angle >= -3 * PI / 4:  # Up
		return "up"
	
	return "right"

func SetWalkingPosition(somePoints: Array[Vector2]) -> void:
	var size := somePoints.size();
	if (size == 0):
		return;
	
	var index := randi_range(0, size-1);
	m_TargetPos = somePoints[index];
	

func SetState(newState: State) -> void:
	m_State = newState;
	match m_State:
		State.Idle:
			OnEnteredIdle();
		State.Walking:
			OnEnteredWalking();
		State.Talking:
			OnEnteredTalking();
		State.Scared:
			OnEnteredScared();


func SetDesiredDirectionOverTime(desiredDirection: Vector2, delta: float) -> void:
	m_Direction = m_Direction.slerp(desiredDirection, ROTATION_SPEED * delta).normalized()

## ON ENTER STATES ##
func OnEnteredIdle() -> void:
	m_Timer = randf_range(MIN_IDLE_TIME, MAX_IDLE_TIME)
	idle_vfx.emitting = true;
	
func OnEnteredWalking() -> void:
	m_GoingToA = !m_GoingToA
	var points := POINTS_A if m_GoingToA else POINTS_B;
	if points.size() == 0:
		SetState(State.Idle);
		return;
		
	SetWalkingPosition(points);
	

func OnEnteredTalking() -> void:
	m_Timer = randf_range(MIN_TALK_TIME, MAX_TALK_TIME)
	
func OnEnteredScared() -> void:
	ClearNodes();
	Jump(35);
	Scare();

func ClearNodes() -> void:
	$CollisionShape2D.disabled = true
	remove_child(vision_cone)
	remove_child(navigation)
	remove_child(scare_icon)

func PlayScare() -> void:
	animation.play("scare")
	
func OnTargetReached() -> void:
	SetState(State.Idle);
	
## PROCESS STATES ##
func ProcessIdle(delta: float) -> void:
	velocity = Vector2.ZERO
	m_Timer -= delta;
	if (m_Timer <= 0):
		SetState(State.Walking);

	var desiredDirection := GetBasicDirectionVector();
	SetDesiredDirectionOverTime(desiredDirection, delta)
		

func ProcessWalking(delta: float) -> void:
	navigation.target_position = m_TargetPos;
	var target: Vector2 = navigation.get_next_path_position()
	var desiredDirection := global_position.direction_to(target)
	
	SetDesiredDirectionOverTime(desiredDirection, delta)
	
	var newVelocity := m_Direction * m_Speed
	if navigation.avoidance_enabled:
		navigation.set_velocity_forced(newVelocity)
	else:
		velocity = newVelocity
		
func ProcessScared(delta: float) -> void:
	velocity = Vector2.ZERO;

func ProcessIdleAnimation(delta: float) -> void:
	animation.play("idle")
	
func ProcessWalkingAnimation(delta: float) -> void:
	var animDir := GetDirectionString();
	if (animDir == "left"):
		animation.flip_h = true;
		animDir = "right";
	
	animation.play("walk_" + animDir)

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	if m_State == State.Walking:
		velocity = safe_velocity


func _on_vision_cone_area_body_entered(body: Node2D) -> void:
	m_Detecting = true;


func _on_vision_cone_area_body_exited(body: Node2D) -> void:
	m_Detecting = false;
