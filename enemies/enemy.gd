@tool

extends CharacterBody2D

enum State {
	Idle,
	Walking,
	Talking,
	Scared
}

@export var RENDER_POINTS: bool = true
@export var RENDER_POINT_LINES: bool = true

@export var MIN_IDLE_TIME: float = 2.0
@export var MAX_IDLE_TIME: float = 5.0

@export var MIN_TALK_TIME: float = 3.0
@export var MAX_TALK_TIME: float = 8.0

@export var POINTS_A: Array[Vector2] = []
@export var POINTS_B: Array[Vector2] = []

@export var MAX_SPEED: float = 100.0

var rng := RandomNumberGenerator.new()

var pointRadius: float = 10.0;

var m_State: State = State.Idle;
var m_Timer: float = 0.0;
var m_GoingToA: bool = true;
var m_WalkingToPos: Vector2 = Vector2.ZERO;

func _ready() -> void:
	InputMap.load_from_project_settings()
	
func _process(delta: float) -> void:
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
		
	match m_State:
		State.Idle:
			ProcessIdle(delta);
		State.Walking:
			ProcessWalking(delta);
		State.Talking:
			return;
		State.Scared:
			return;
			
	pass;

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
	m_WalkingToPos = somePoints[index];
	
	
func _physics_process(delta: float) -> void:
	move_and_slide()

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

## PROCESS STATES ##
func ProcessIdle(delta: float) -> void:
	m_Timer -= delta;
	if (m_Timer > 0):
		return;
		
	SetState(State.Walking);

func ProcessWalking(delta: float) -> void:
	var toPos := m_WalkingToPos - global_position;
	if (toPos.length() <= 20.0):
		SetState(State.Idle);
		return;
		
	velocity = (m_WalkingToPos - global_position).normalized() * MAX_SPEED

func _on_idle_timer_end() -> void:
	m_State = State.Walking;
