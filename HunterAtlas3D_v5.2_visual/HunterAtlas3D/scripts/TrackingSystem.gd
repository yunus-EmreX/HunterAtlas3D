## TrackingSystem.gd
## Zemin substratına göre iz bozunması ve iz yoğunluğu hesabı.

class_name TrackingSystem
extends Node

signal track_found(position: Vector3, quality: float)
signal tracking_skill_updated(score: float)

const MAX_TRACKS: int        = 35
const TRACK_Y_OFFSET: float  = 0.015

const DECAY_RATE: Dictionary = {
	"snow":       0.007,
	"mud":        0.018,
	"dry_grass":  0.055,
	"rainforest": 0.130,
	"default":    0.025,
}

# ─── İç Sınıf ─────────────────────────────────────────────────────────────────
class Track:
	var node: MeshInstance3D
	var quality: float = 1.0
	var age: float     = 0.0
	var decay: float   = 0.025

	func _init(n: MeshInstance3D, d: float) -> void:
		node  = n
		decay = d

# ─── Durum ────────────────────────────────────────────────────────────────────
var _world_root: Node3D  = null
var _substrate: String   = "default"
var _tracks: Array       = []
var _tracking_score: float = 0.0
var _spawn_timer: float  = 0.0
var _spawn_interval: float = 2.2
var _active: bool        = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func setup(world_root: Node3D, biome_name: String) -> void:
	_world_root = world_root
	_substrate  = _biome_substrate(biome_name)
	_active     = true
	_tracks.clear()
	_rng.randomize()
	print("TrackingSystem: substrat = %s" % _substrate)

func deactivate() -> void:
	_active = false
	_clear_all()

func _process(delta: float) -> void:
	if not _active:
		return

	_spawn_timer += delta
	if _spawn_timer >= _spawn_interval:
		_spawn_timer = 0.0
		_place_random_track()

	var to_remove: Array = []
	for entry: Variant in _tracks:
		var t: Track = entry as Track
		t.age     += delta
		t.quality -= t.decay * delta
		t.quality  = clampf(t.quality, 0.0, 1.0)

		if is_instance_valid(t.node):
			var m: StandardMaterial3D = t.node.material_override as StandardMaterial3D
			if m != null:
				m.albedo_color.a = t.quality * 0.80

		if t.quality <= 0.0:
			to_remove.append(t)

	for entry: Variant in to_remove:
		var t: Track = entry as Track
		if is_instance_valid(t.node):
			t.node.queue_free()
		_tracks.erase(t)

	_recalculate()

func _place_random_track() -> void:
	if _tracks.size() >= MAX_TRACKS or _world_root == null:
		return
	var half: float = 14.0
	var pos: Vector3 = Vector3(
		_rng.randf_range(-half, half),
		TRACK_Y_OFFSET,
		_rng.randf_range(-half, half))
	_create_track(pos)

func _create_track(pos: Vector3) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(_rng.randf_range(0.12, 0.28), _rng.randf_range(0.09, 0.18))
	mi.mesh = quad

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = _track_color()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode    = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat

	mi.position = pos
	mi.rotation_degrees.x = -90.0
	mi.rotation_degrees.y = _rng.randf_range(0.0, 360.0)
	_world_root.add_child(mi)

	var decay: float = float(DECAY_RATE.get(_substrate, DECAY_RATE["default"]))
	var t: Track = Track.new(mi, decay)
	_tracks.append(t)
	track_found.emit(pos, t.quality)

func get_tracking_modifier() -> float:
	return clampf(_tracking_score, 0.0, 1.0)

func get_active_track_count() -> int:
	return _tracks.size()

func _recalculate() -> void:
	if _tracks.is_empty():
		_tracking_score = 0.0
		return
	var total: float = 0.0
	for entry: Variant in _tracks:
		var t: Track = entry as Track
		total += t.quality
	_tracking_score = clampf((total / float(MAX_TRACKS)) * 1.6, 0.0, 1.0)
	tracking_skill_updated.emit(_tracking_score)

func _biome_substrate(bname: String) -> String:
	match bname:
		"Tundra":                    return "snow"
		"Rainforest":                return "rainforest"
		"Northern Maritime", "Taiga", "Temperate Forest": return "mud"
		"Steppe", "Savanna", "Proto-Urban Mediterranean": return "dry_grass"
	return "default"

func _track_color() -> Color:
	match _substrate:
		"snow":       return Color(0.74, 0.82, 0.90, 0.85)
		"mud":        return Color(0.36, 0.26, 0.16, 0.85)
		"dry_grass":  return Color(0.54, 0.46, 0.28, 0.70)
		"rainforest": return Color(0.26, 0.20, 0.13, 0.60)
	return Color(0.40, 0.35, 0.25, 0.75)

func _clear_all() -> void:
	for entry: Variant in _tracks:
		var t: Track = entry as Track
		if is_instance_valid(t.node):
			t.node.queue_free()
	_tracks.clear()
	_tracking_score = 0.0
