@tool

extends CharacterBody2D

enum State {
	Idle,
	Walking,
	Talking,
	Scared
}

@export var MAX_SPEED: float = 100.0
@export var ROTATION_SPEED: float = 5.0
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

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var vision_cone: VisionCone2D = $VisionCone2D
@onready var vision_renderer: Polygon2D = $VisionCone2D/VisionConeRenderer

var rng := RandomNumberGenerator.new()
var pointRadius: float = 10.0;

var m_State: State = State.Idle;
var m_Timer: float = 0.0;
var m_GoingToA: bool = true;
var m_Direction: Vector2 = Vector2.ZERO;

func _ready() -> void:
	m_Direction = Vector2.RIGHT;
	vision_renderer.color = vision_color
	InputMap.load_from_project_settings()
	
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw();
		var nodes := EditorInterface.get_selection().get_selected_nodes();
		if nodes.size() > 0 && nodes[0] == self:
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
			return;
			
	move_and_slide()

func RotateConeVision() -> void:
	vision_cone.rotation = m_Direction.angle() + deg_to_rad(270)

func _draw() -> void:
	if Engine.is_editor_hint():
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

func SetWalkingPosition(somePoints: Array[Vector2]) -> void:
	var size := somePoints.size();
	if (size == 0):
		return;
	
	var index := rng.randi_range(0, size-1);
	navigation_agent_2d.target_position = somePoints[index];
	

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


## ON ENTER STATES ##
func OnEnteredIdle() -> void:
	print("ENTERED IDLE");
	m_Timer = rng.randf_range(MIN_IDLE_TIME, MAX_IDLE_TIME)
	velocity = Vector2.ZERO;
	
func OnEnteredWalking() -> void:
	print("ENTERED WALKING");
	m_GoingToA = !m_GoingToA
	var points := POINTS_A if m_GoingToA else POINTS_B;
	SetWalkingPosition(points);
	

func OnEnteredTalking() -> void:
	m_Timer = rng.randf_range(MIN_TALK_TIME, MAX_TALK_TIME)
	
func OnEnteredScared() -> void:
	pass;

func OnTargetReached() -> void:
	SetState(State.Walking);
	
## PROCESS STATES ##
func ProcessIdle(delta: float) -> void:
	m_Timer -= delta;
	if (m_Timer > 0):
		return;
		
	SetState(State.Walking);

func ProcessWalking(delta: float) -> void:
	var navWorks: bool = navigation_agent_2d.get_current_navigation_path().size() > 0
	var target: Vector2 = navigation_agent_2d.get_next_path_position() if navWorks else navigation_agent_2d.target_position
	var desiredDirection := global_position.direction_to(target)
	
	m_Direction = m_Direction.slerp(desiredDirection, ROTATION_SPEED * delta).normalized()
	
	var newVelocity := m_Direction * MAX_SPEED
	if navWorks && navigation_agent_2d.avoidance_enabled:
		navigation_agent_2d.set_velocity_forced(newVelocity)
	else:
		velocity = newVelocity
		
	if !navWorks:
		if (global_position.distance_squared_to(target) <= 25.0):
			OnTargetReached();

func _on_idle_timer_end() -> void:
	m_State = State.Walking;


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity


func _on_vision_cone_area_body_entered(body: Node2D) -> void:
	vision_renderer.color = alert_color


func _on_vision_cone_area_body_exited(body: Node2D) -> void:
	vision_renderer.color = vision_color


func _on_vision_cone_area_mouse_entered() -> void:
	vision_renderer.color = alert_color


func _on_vision_cone_area_mouse_exited() -> void:
	vision_renderer.color = vision_color
