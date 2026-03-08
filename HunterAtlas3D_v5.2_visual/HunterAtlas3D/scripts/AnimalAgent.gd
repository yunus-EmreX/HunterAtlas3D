## AnimalAgent.gd
## ModelFactory modellerini kullanan otonom hayvan ajan. Bacak animasyonu dahil.

class_name AnimalAgent
extends CharacterBody3D

signal animal_fled(agent: AnimalAgent)

@export var wander_speed: float  = 1.8
@export var flee_speed: float    = 6.5
@export var flee_radius: float   = 9.0
@export var wander_radius: float = 22.0
@export var dir_change_time: float = 4.0
@export var biome_name: String   = ""

enum AgentState { WANDER, FLEE, IDLE }
var _state: AgentState = AgentState.WANDER

var _origin: Vector3      = Vector3.ZERO
var _move_dir: Vector3    = Vector3.ZERO
var _dir_timer: float     = 0.0
var _flee_target: Node3D  = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _model: Node3D    = null
var _leg_fl: Node3D   = null
var _leg_fr: Node3D   = null
var _leg_rl: Node3D   = null
var _leg_rr: Node3D   = null
var _tail_root: Node3D = null
var _anim_t: float    = 0.0
var _bob_t: float     = 0.0

func _ready() -> void:
	_rng.randomize()
	_origin = global_position
	_pick_direction()
	_build_model()
	add_to_group("animal_agents")

func _build_model() -> void:
	_model = ModelFactory.create_animal_for_biome(biome_name, _rng)
	add_child(_model)

	_leg_fl    = _model.get_node_or_null("Leg_FL")
	_leg_fr    = _model.get_node_or_null("Leg_FR")
	_leg_rl    = _model.get_node_or_null("Leg_RL")
	_leg_rr    = _model.get_node_or_null("Leg_RR")
	_tail_root = _model.get_node_or_null("TailRoot")

	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: CapsuleShape3D = CapsuleShape3D.new()
	shape.radius = 0.22
	shape.height = 0.60
	col.shape = shape
	col.position.y = 0.30
	add_child(col)

func _physics_process(delta: float) -> void:
	match _state:
		AgentState.WANDER: _do_wander(delta)
		AgentState.FLEE:   _do_flee(delta)
		AgentState.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0

	if not is_on_floor():
		velocity.y -= 9.8 * delta

	move_and_slide()
	_animate(delta)

func _do_wander(delta: float) -> void:
	_dir_timer -= delta
	if _dir_timer <= 0.0:
		_pick_direction()

	var dist_from_origin: float = global_position.distance_to(_origin)
	if dist_from_origin > wander_radius:
		_move_dir = (_origin - global_position).normalized()
		_move_dir.y = 0.0

	velocity.x = _move_dir.x * wander_speed
	velocity.z = _move_dir.z * wander_speed
	_face_velocity(delta, 3.5)

func _do_flee(delta: float) -> void:
	if _flee_target == null or not is_instance_valid(_flee_target):
		_state = AgentState.WANDER
		return
	var dist: float = global_position.distance_to(_flee_target.global_position)
	if dist > flee_radius * 2.2:
		_state = AgentState.WANDER
		return
	var fdir: Vector3 = (global_position - _flee_target.global_position)
	fdir.y = 0.0
	fdir   = fdir.normalized()
	velocity.x = fdir.x * flee_speed
	velocity.z = fdir.z * flee_speed
	_face_velocity(delta, 7.0)

func _animate(delta: float) -> void:
	var spd: float = velocity.length()
	if spd < 0.15:
		_bob_t += delta * 0.9
		if _model: _model.position.y = sin(_bob_t) * 0.008
		if _leg_fl: _leg_fl.rotation.x = move_toward(_leg_fl.rotation.x, 0.0, delta * 3.0)
		if _leg_fr: _leg_fr.rotation.x = move_toward(_leg_fr.rotation.x, 0.0, delta * 3.0)
		if _leg_rl: _leg_rl.rotation.x = move_toward(_leg_rl.rotation.x, 0.0, delta * 3.0)
		if _leg_rr: _leg_rr.rotation.x = move_toward(_leg_rr.rotation.x, 0.0, delta * 3.0)
		if _tail_root: _tail_root.rotation.z = sin(_bob_t * 0.8) * 0.18
		return

	_anim_t += delta * spd * 1.8
	var swing: float = 0.42
	if _leg_fl: _leg_fl.rotation.x =  sin(_anim_t) * swing
	if _leg_rr: _leg_rr.rotation.x =  sin(_anim_t) * swing
	if _leg_fr: _leg_fr.rotation.x = -sin(_anim_t) * swing
	if _leg_rl: _leg_rl.rotation.x = -sin(_anim_t) * swing
	if _model:  _model.position.y  = abs(sin(_anim_t * 2.0)) * 0.038
	if _tail_root:
		var tf: float = 2.0 if _state == AgentState.FLEE else 1.0
		_tail_root.rotation.z = sin(_anim_t * tf) * 0.28

func trigger_flee(threat: Node3D) -> void:
	if _state != AgentState.FLEE:
		_flee_target = threat
		_state = AgentState.FLEE
		animal_fled.emit(self)

func place_at(pos: Vector3) -> void:
	global_position = pos
	_origin = pos

func _face_velocity(delta: float, speed: float) -> void:
	var flat: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if flat.length() < 0.1: return
	flat = flat.normalized()
	var tb: Basis = Basis.looking_at(flat, Vector3.UP)
	transform.basis = transform.basis.slerp(tb, delta * speed)

func _pick_direction() -> void:
	var angle: float = _rng.randf_range(0.0, TAU)
	_move_dir = Vector3(cos(angle), 0.0, sin(angle))
	_dir_timer = _rng.randf_range(dir_change_time * 0.5, dir_change_time * 2.2)
