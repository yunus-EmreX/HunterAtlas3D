## HunterCharacter.gd
## Oyuncu kontrollü avcı karakteri.
## WASD → hareket  |  Fare → kamera  |  ESC → fare serbest bırak

class_name HunterCharacter
extends CharacterBody3D

@export var walk_speed: float    = 4.5
@export var sprint_speed: float  = 8.5
@export var cam_distance: float  = 5.5
@export var cam_height: float    = 2.0
@export var cam_sensitivity: float = 0.0028
@export var cam_min_pitch: float = -1.10
@export var cam_max_pitch: float =  0.55

var _model_root: Node3D  = null
var _camera: Camera3D    = null
var _leg_l: Node3D       = null
var _leg_r: Node3D       = null
var _arm_l: Node3D       = null
var _arm_r: Node3D       = null

var _cam_yaw: float   = 0.0
var _cam_pitch: float = -0.28
var _anim_t: float    = 0.0
var _moving: bool     = false
var _is_sprinting: bool = false

const GRAVITY: float  = 9.8

func _ready() -> void:
	_build_model()
	_build_camera()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("HunterCharacter: hazır.")

func _build_model() -> void:
	_model_root = Node3D.new()
	_model_root.name = "ModelRoot"
	add_child(_model_root)

	var hunter_visual: Node3D = ModelFactory.create_hunter()
	_model_root.add_child(hunter_visual)

	_leg_l = hunter_visual.get_node_or_null("Leg_L")
	_leg_r = hunter_visual.get_node_or_null("Leg_R")
	_arm_l = hunter_visual.get_node_or_null("Arm_L")
	_arm_r = hunter_visual.get_node_or_null("Arm_R")

	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: CapsuleShape3D = CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 1.75
	col.shape = shape
	col.position.y = 0.875
	add_child(col)

func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "PlayerCamera"
	_camera.fov  = 68.0
	_camera.near = 0.12
	_camera.far  = 280.0
	add_child(_camera)
	_camera.make_current()
	_update_camera_transform()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			var mm: InputEventMouseMotion = event as InputEventMouseMotion
			_cam_yaw   -= mm.relative.x * cam_sensitivity
			_cam_pitch -= mm.relative.y * cam_sensitivity
			_cam_pitch  = clampf(_cam_pitch, cam_min_pitch, cam_max_pitch)

	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and ke.keycode == KEY_ESCAPE:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0

	var input_x: float = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	var input_z: float = float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))

	_is_sprinting = Input.is_key_pressed(KEY_SHIFT)
	var speed: float = sprint_speed if _is_sprinting else walk_speed

	if abs(input_x) > 0.01 or abs(input_z) > 0.01:
		_moving = true
		var forward: Vector3 = Vector3(-sin(_cam_yaw), 0.0, -cos(_cam_yaw)).normalized()
		var right: Vector3   = Vector3( cos(_cam_yaw), 0.0, -sin(_cam_yaw)).normalized()
		var direction: Vector3 = (forward * (-input_z) + right * input_x).normalized()

		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

		if direction.length() > 0.1:
			var target_basis: Basis = Basis.looking_at(direction, Vector3.UP)
			_model_root.transform.basis = _model_root.transform.basis.slerp(target_basis, delta * 9.0)
	else:
		_moving = false
		velocity.x = move_toward(velocity.x, 0.0, speed * 3.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 3.0 * delta)

	move_and_slide()

func _process(delta: float) -> void:
	_update_camera_transform()
	_animate(delta)

func _update_camera_transform() -> void:
	var look_target: Vector3 = global_position + Vector3(0.0, 1.55, 0.0)

	var yaw_cos: float   = cos(_cam_yaw)
	var yaw_sin: float   = sin(_cam_yaw)
	var pitch_cos: float = cos(_cam_pitch)
	var pitch_sin: float = sin(_cam_pitch)

	var cam_offset: Vector3 = Vector3(
		yaw_sin  * pitch_cos * cam_distance,
		-pitch_sin * cam_distance + cam_height,
		yaw_cos  * pitch_cos * cam_distance
	)

	_camera.global_position = _camera.global_position.lerp(
		look_target + cam_offset, 0.18)
	_camera.look_at(look_target + Vector3(0.0, 0.2, 0.0), Vector3.UP)

func _animate(delta: float) -> void:
	if not _moving:
		_anim_t += delta * 1.2
		_model_root.position.y = sin(_anim_t * 1.8) * 0.012
		if _leg_l: _leg_l.rotation.x = move_toward(_leg_l.rotation.x, 0.0, delta * 4.0)
		if _leg_r: _leg_r.rotation.x = move_toward(_leg_r.rotation.x, 0.0, delta * 4.0)
		if _arm_l: _arm_l.rotation.x = move_toward(_arm_l.rotation.x, 0.0, delta * 4.0)
		if _arm_r: _arm_r.rotation.x = move_toward(_arm_r.rotation.x, 0.0, delta * 4.0)
		return

	var speed_factor: float = sprint_speed if _is_sprinting else walk_speed
	_anim_t += delta * speed_factor * 1.6

	_model_root.position.y = abs(sin(_anim_t * 2.0)) * 0.055

	var leg_swing: float = 0.52 if _is_sprinting else 0.38
	if _leg_l: _leg_l.rotation.x =  sin(_anim_t) * leg_swing
	if _leg_r: _leg_r.rotation.x = -sin(_anim_t) * leg_swing

	var arm_swing: float = 0.38 if _is_sprinting else 0.26
	if _arm_l: _arm_l.rotation.x = -sin(_anim_t) * arm_swing
	if _arm_r: _arm_r.rotation.x =  sin(_anim_t) * arm_swing

func get_camera() -> Camera3D:
	return _camera

func get_cam_yaw() -> float:
	return _cam_yaw
