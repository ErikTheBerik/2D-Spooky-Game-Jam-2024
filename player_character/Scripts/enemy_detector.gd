extends Area2D
@export var MIN_SCARE_SPEED := 5.0
@export var SLOWDOWN_DISTANCE := 40.0;
var m_Enemies: Array[Enemy] = []
var m_Character: Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	m_Character = owner;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	m_Character.m_SpeedOverride = 0.0;
	for enemy in m_Enemies:
		if IsSneaking(enemy):
			m_Character.m_SpeedOverride = max(MIN_SCARE_SPEED, enemy.velocity.length());
			return;

func _process(delta: float) -> void:
	if (Input.is_action_just_pressed("Scare")):
		for enemy in m_Enemies:
			enemy.SetState(Enemy.State.Scared)

func IsSneaking(enemy: Enemy) -> bool:
	var dir := m_Character.velocity.normalized();
	if (dir == Vector2.ZERO):
		return false;
		
	var enemyPos := enemy.global_position;
	if (m_Character.global_position.distance_to(enemyPos) > SLOWDOWN_DISTANCE):
		return false;
		
	var dirToEnemy := m_Character.global_position.direction_to(enemyPos);
	
	var dot := dir.dot(dirToEnemy);
	return dot >= 0.3;
		
func _on_body_entered(body: Enemy) -> void:
	if (body && body.is_in_group("Enemy")):
		body.scare_icon.visible = true;
		m_Enemies.push_back(body)
		

func _on_body_exited(body: Enemy) -> void:
	if (!body):
		return;
		
	var index := m_Enemies.find(body);
	if (index != -1):
		body.scare_icon.visible = false;
		
		m_Enemies.remove_at(index);