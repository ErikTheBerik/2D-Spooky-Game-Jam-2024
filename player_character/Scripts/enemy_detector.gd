extends Area2D
@export var MIN_SCARE_SPEED := 5.0
@export var SLOWDOWN_DISTANCE := 40.0;
var m_Enemies: Array[Enemy] = []
var m_Character: Player

var m_Timer: Timer = null;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	m_Character = owner;
	m_Timer = Timer.new()
	m_Timer.wait_time = 2.0
	m_Timer.one_shot = true
	m_Timer.timeout.connect(CheckGameEnd)
	add_child(m_Timer);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	m_Character.m_SpeedOverride = 0.0;
	m_Character.animation.speed_scale = 1.0;
	for enemy in m_Enemies:
		if IsSneaking(enemy):
			m_Character.m_SpeedOverride = max(MIN_SCARE_SPEED, enemy.velocity.length());
			m_Character.animation.speed_scale = 0.3;
			return;

func _process(delta: float) -> void:
	if (Input.is_action_just_pressed("Scare")):
		if (m_Enemies.size() == 0):
			return;
		
		m_Character.isScaring = true;
		m_Character.animation.play("scare");
		var tween := get_tree().create_tween().bind_node(self)
		tween.tween_property(m_Character.animation, "scale", Vector2(2.0, 2.0), 0.7).set_trans(Tween.TRANS_EXPO)
		tween.tween_property(m_Character.animation, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_EXPO)
		tween.tween_callback(ResetScare)

		for enemy in m_Enemies:
			var dirToEnemy := global_position.direction_to(enemy.global_position);
			if Vector2.RIGHT.dot(dirToEnemy) < 0:
				m_Character.animation.flip_h = true;
				
			enemy.SetState(Enemy.State.Scared)
			
		var scared := m_Enemies.size();
		if (get_tree().get_nodes_in_group("Enemy").size() <= scared):
			m_Character.detected = true
		
		m_Enemies.clear();
		
		m_Timer.stop();
		m_Timer.start();

func CheckGameEnd() -> void:
	if (get_tree().get_nodes_in_group("Enemy").size() == 0):
		get_tree().root.get_child(0).OnLevelCleared();

func ResetScare() -> void:
	m_Character.isScaring = false
	
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
		
func _on_body_entered(body: Node2D) -> void:
	if (body.is_in_group("Enemy")):
		body.scare_icon.visible = true;
		m_Enemies.push_back(body)
		

func _on_body_exited(body: Node2D) -> void:
	var index := m_Enemies.find(body);
	if (index != -1):
		body.scare_icon.visible = false;
		
		m_Enemies.remove_at(index);
