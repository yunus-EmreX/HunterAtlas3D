extends Node

@export var camera_path: NodePath
@export var target_path: NodePath
@export var distance: float = 3.2
@export var min_distance: float = 1.6
@export var max_distance: float = 6.0
@export var yaw: float = 0.0
@export var pitch: float = -0.15
@export var pitch_min: float = -1.2
@export var pitch_max: float = 0.2
@export var rotate_speed: float = 0.008
@export var zoom_speed: float = 0.35

var _dragging: bool = false
var _last_mouse: Vector2 = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mb: InputEventMouseButton = event
        if mb.button_index == MOUSE_BUTTON_RIGHT:
            _dragging = mb.pressed
            _last_mouse = mb.position
        elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
            distance = max(min_distance, distance - zoom_speed)
        elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
            distance = min(max_distance, distance + zoom_speed)

    if event is InputEventMouseMotion and _dragging:
        var mm: InputEventMouseMotion = event
        var delta: Vector2 = mm.position - _last_mouse
        _last_mouse = mm.position
        yaw -= delta.x * rotate_speed
        pitch = clamp(pitch - delta.y * rotate_speed, pitch_min, pitch_max)

func _process(_dt: float) -> void:
    var cam: Camera3D = get_node_or_null(camera_path) as Camera3D
    var target: Node3D = get_node_or_null(target_path) as Node3D
    if cam == null or target == null:
        return

    var tpos: Vector3 = target.global_transform.origin

    var x: float = distance * cos(pitch) * cos(yaw)
    var y: float = distance * sin(pitch)
    var z: float = distance * cos(pitch) * sin(yaw)

    cam.global_transform.origin = tpos + Vector3(x, y, z)
    cam.look_at(tpos, Vector3.UP)
