extends Node3D
class_name Animal

@export var species: String = "Animal"
@export var speed: float = 0.35
@export var wander_radius: float = 2.5

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _center: Vector3 = Vector3.ZERO
var _goal: Vector3 = Vector3.ZERO

func init(center: Vector3, rng_seed: int) -> void:
    _center = center
    _rng.seed = rng_seed
    _pick_new_goal()

func _ready() -> void:
    if _goal == Vector3.ZERO:
        _pick_new_goal()

func _process(dt: float) -> void:
    var to_goal: Vector3 = _goal - global_transform.origin
    var dist: float = to_goal.length()
    if dist < 0.15:
        _pick_new_goal()
        return

    var dir: Vector3 = to_goal.normalized()
    global_translate(dir * speed * dt)
    look_at(global_transform.origin + dir, Vector3.UP)

    var p: Vector3 = global_transform.origin
    p.y = 0.12 + 0.03 * sin(Time.get_ticks_msec() * 0.003 + float(int(_rng.seed) % 1000))
    global_transform.origin = p

func _pick_new_goal() -> void:
    var ang: float = _rng.randf() * TAU
    var rad: float = sqrt(_rng.randf()) * wander_radius
    _goal = _center + Vector3(cos(ang) * rad, 0.12, sin(ang) * rad)
