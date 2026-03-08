## EnvironmentSpawner.gd
## FastNoiseLite ile 100x100 arazi + ModelFactory ağaç/kaya + hayvanlar.

class_name EnvironmentSpawner
extends Node

const TERRAIN_SIZE: float = 100.0
const TERRAIN_SEGS: int   = 52
const HEIGHT_SCALE: float = 2.8
const MAX_ANIMALS: int    = 10
const MAX_TREES: int      = 42
const MAX_ROCKS: int      = 22
const FLAT_RADIUS: float  = 14.0  # merkez düz alan (oyuncu spawn)

var _world_root: Node3D       = null
var _biome_manager: BiomeManager = null
var _spawned_animals: Array   = []
var _terrain_noise: FastNoiseLite = null
var _terrain_h_scale: float   = HEIGHT_SCALE
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func setup(world_root: Node3D, biome_manager: BiomeManager) -> void:
	_world_root    = world_root
	_biome_manager = biome_manager

func spawn_biome(biome_name: String) -> void:
	_clear_world()
	_rng.randomize()

	if _biome_manager == null or _world_root == null:
		push_error("EnvironmentSpawner: setup() çağrılmadı.")
		return

	var biome: Dictionary = _biome_manager.get_biome(biome_name)
	if biome.is_empty():
		push_error("EnvironmentSpawner: '%s' bulunamadı." % biome_name)
		return

	_terrain_h_scale = float(biome.get("terrain_difficulty", 1.0)) * HEIGHT_SCALE

	_spawn_terrain(biome)
	_spawn_rocks(biome)
	_spawn_vegetation(biome)
	_spawn_animals(biome)
	_setup_atmosphere(biome)
	_setup_weather(biome)
	_setup_lighting(biome)
	print("EnvironmentSpawner: '%s' hazır." % biome_name)

func get_animals() -> Array:
	return _spawned_animals.duplicate()

func alert_animals_near(pos: Vector3, radius: float, threat: Node3D) -> void:
	for entry: Variant in _spawned_animals:
		var agent: AnimalAgent = entry as AnimalAgent
		if not is_instance_valid(agent): continue
		if agent.global_position.distance_to(pos) <= radius:
			agent.trigger_flee(threat)

func get_height_at(x: float, z: float) -> float:
	if _terrain_noise == null: return 0.0
	var raw: float = _terrain_noise.get_noise_2d(x, z) * _terrain_h_scale
	var dist: float = Vector2(x, z).length()
	if dist < FLAT_RADIUS:
		var flatten: float = clampf((dist - FLAT_RADIUS * 0.4) / (FLAT_RADIUS * 0.6), 0.0, 1.0)
		raw *= flatten
	return raw

# ─── Arazi ────────────────────────────────────────────────────────────────────
func _spawn_terrain(biome: Dictionary) -> void:
	_terrain_noise = FastNoiseLite.new()
	_terrain_noise.seed = _rng.randi()
	_terrain_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_terrain_noise.frequency = 0.022
	_terrain_noise.fractal_octaves = 4
	_terrain_noise.fractal_gain = 0.48

	var half: float = TERRAIN_SIZE / 2.0
	var step: float = TERRAIN_SIZE / float(TERRAIN_SEGS)
	var ground_col: Color = _ground_color(biome)

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for zi: int in range(TERRAIN_SEGS):
		for xi: int in range(TERRAIN_SEGS):
			var x0: float = -half + xi * step
			var z0: float = -half + zi * step
			var x1: float = x0 + step
			var z1: float = z0 + step

			var y00: float = get_height_at(x0, z0)
			var y10: float = get_height_at(x1, z0)
			var y01: float = get_height_at(x0, z1)
			var y11: float = get_height_at(x1, z1)

			# Renk yüksekliğe göre varyasyon
			var avg_h: float = (y00 + y10 + y01 + y11) / 4.0
			var h_norm: float = clampf((avg_h / _terrain_h_scale + 1.0) / 2.0, 0.0, 1.0)
			var col: Color = ground_col.lerp(ground_col.lightened(0.18), h_norm)

			st.set_color(col)
			st.set_uv(Vector2(float(xi)/TERRAIN_SEGS, float(zi)/TERRAIN_SEGS))
			st.add_vertex(Vector3(x0, y00, z0))
			st.set_color(col)
			st.set_uv(Vector2(float(xi+1)/TERRAIN_SEGS, float(zi)/TERRAIN_SEGS))
			st.add_vertex(Vector3(x1, y10, z0))
			st.set_color(col)
			st.set_uv(Vector2(float(xi)/TERRAIN_SEGS, float(zi+1)/TERRAIN_SEGS))
			st.add_vertex(Vector3(x0, y01, z1))

			st.set_color(col)
			st.set_uv(Vector2(float(xi+1)/TERRAIN_SEGS, float(zi)/TERRAIN_SEGS))
			st.add_vertex(Vector3(x1, y10, z0))
			st.set_color(col)
			st.set_uv(Vector2(float(xi+1)/TERRAIN_SEGS, float(zi+1)/TERRAIN_SEGS))
			st.add_vertex(Vector3(x1, y11, z1))
			st.set_color(col)
			st.set_uv(Vector2(float(xi)/TERRAIN_SEGS, float(zi+1)/TERRAIN_SEGS))
			st.add_vertex(Vector3(x0, y01, z1))

	st.generate_normals()
	var arr_mesh: ArrayMesh = st.commit()

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = ground_col
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.94

	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	mesh_inst.name = "TerrainMesh"
	mesh_inst.mesh = arr_mesh
	mesh_inst.material_override = mat

	var static_body: StaticBody3D = StaticBody3D.new()
	static_body.name = "TerrainBody"
	var col_shape: CollisionShape3D = CollisionShape3D.new()
	col_shape.shape = arr_mesh.create_trimesh_shape()
	static_body.add_child(col_shape)

	_world_root.add_child(mesh_inst)
	_world_root.add_child(static_body)

func _ground_color(biome: Dictionary) -> Color:
	match str(biome.get("name", "")):
		"Steppe":                    return Color(0.70, 0.63, 0.40)
		"Savanna":                   return Color(0.73, 0.65, 0.33)
		"Taiga":                     return Color(0.32, 0.42, 0.28)
		"Rainforest":                return Color(0.20, 0.40, 0.18)
		"Tundra":                    return Color(0.80, 0.85, 0.88)
		"Temperate Forest":          return Color(0.36, 0.50, 0.26)
		"Northern Maritime":         return Color(0.40, 0.52, 0.46)
		"Proto-Urban Mediterranean": return Color(0.70, 0.65, 0.52)
	return Color(0.48, 0.50, 0.38)

# ─── Kayalar ──────────────────────────────────────────────────────────────────
func _spawn_rocks(biome: Dictionary) -> void:
	var density: float = float(biome.get("rock_density", 0.4))
	var count: int = int(MAX_ROCKS * density)
	var half: float = TERRAIN_SIZE * 0.44

	for _i: int in range(count):
		var x: float = _rng.randf_range(-half, half)
		var z: float = _rng.randf_range(-half, half)
		var y: float = get_height_at(x, z)
		if Vector2(x, z).length() < FLAT_RADIUS * 0.8: continue

		var size: float = _rng.randf_range(0.25, 1.2)
		var rock: Node3D = ModelFactory.create_rock(size)
		rock.position = Vector3(x, y + size * 0.28, z)
		rock.rotation.y = _rng.randf_range(0.0, TAU)
		_world_root.add_child(rock)

# ─── Bitki Örtüsü ─────────────────────────────────────────────────────────────
func _spawn_vegetation(biome: Dictionary) -> void:
	var veg_density: float = float(biome.get("vegetation_density", 0.5))
	var count: int = int(MAX_TREES * veg_density)
	var bname: String = str(biome.get("name", ""))
	var half: float = TERRAIN_SIZE * 0.44

	for _i: int in range(count):
		var x: float = _rng.randf_range(-half, half)
		var z: float = _rng.randf_range(-half, half)
		var y: float = get_height_at(x, z)
		if Vector2(x, z).length() < FLAT_RADIUS * 0.7: continue

		# Çim kümeleri her zaman, ağaçlar yoğunluğa göre
		if _rng.randf() < 0.35:
			_spawn_grass_clump(x, y, z, bname)
		else:
			var height: float = _rng.randf_range(2.5, 6.5)
			var tree: Node3D = ModelFactory.create_tree_for_biome(bname, height)
			tree.position = Vector3(x, y, z)
			tree.rotation.y = _rng.randf_range(0.0, TAU)
			_world_root.add_child(tree)

func _spawn_grass_clump(x: float, y: float, z: float, bname: String) -> void:
	var grass_colors: Dictionary = {
		"Steppe": Color(0.68, 0.60, 0.28),
		"Savanna": Color(0.72, 0.62, 0.25),
		"Tundra": Color(0.50, 0.58, 0.45),
		"Rainforest": Color(0.15, 0.52, 0.18),
	}
	var grass_col: Color = grass_colors.get(bname, Color(0.32, 0.55, 0.22)) as Color

	var blade_count: int = _rng.randi_range(3, 8)
	for _bi: int in range(blade_count):
		var bx: float = x + _rng.randf_range(-0.3, 0.3)
		var bz: float = z + _rng.randf_range(-0.3, 0.3)
		var h: float  = _rng.randf_range(0.18, 0.52)

		var mi: MeshInstance3D = MeshInstance3D.new()
		var cm: CylinderMesh = CylinderMesh.new()
		cm.top_radius    = _rng.randf_range(0.01, 0.04)
		cm.bottom_radius = _rng.randf_range(0.05, 0.11)
		cm.height = h
		mi.mesh = cm
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = grass_col.lerp(grass_col.darkened(0.2), _rng.randf_range(0.0, 0.4))
		mi.material_override = mat
		mi.position = Vector3(bx, y + h * 0.5, bz)
		mi.rotation.z = _rng.randf_range(-0.18, 0.18)
		_world_root.add_child(mi)

# ─── Hayvanlar ────────────────────────────────────────────────────────────────
func _spawn_animals(biome: Dictionary) -> void:
	_spawned_animals.clear()
	var density: float = float(biome.get("game_density", 0.5))
	var count: int  = int(MAX_ANIMALS * density)
	var bname: String = str(biome.get("name", ""))
	var half: float = TERRAIN_SIZE * 0.35

	for i: int in range(count):
		var agent: AnimalAgent = AnimalAgent.new()
		agent.name = "Animal_%d" % i
		agent.biome_name = bname

		var rx: float = _rng.randf_range(-half, half)
		var rz: float = _rng.randf_range(-half, half)
		# Oyuncudan uzakta spawn
		while Vector2(rx, rz).length() < 12.0:
			rx = _rng.randf_range(-half, half)
			rz = _rng.randf_range(-half, half)

		var ry: float = get_height_at(rx, rz) + 1.5
		agent.position = Vector3(rx, ry, rz)
		_world_root.add_child(agent)
		_spawned_animals.append(agent)

# ─── Atmosfer ─────────────────────────────────────────────────────────────────
func _setup_atmosphere(biome: Dictionary) -> void:
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	var sky_col: Color  = _sky_color(str(biome.get("name", "")))
	env.background_color = sky_col

	var fog_den: float = float(biome.get("fog_density", 0.008))
	env.fog_enabled     = fog_den > 0.004
	env.fog_density     = fog_den
	env.fog_light_color = sky_col.lightened(0.15)
	env.fog_depth_end   = 180.0

	var we: WorldEnvironment = WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	_world_root.add_child(we)

func _sky_color(bname: String) -> Color:
	match bname:
		"Tundra":            return Color(0.50, 0.60, 0.74)
		"Rainforest":        return Color(0.26, 0.50, 0.36)
		"Steppe":            return Color(0.68, 0.76, 0.90)
		"Savanna":           return Color(0.88, 0.74, 0.50)
		"Northern Maritime": return Color(0.42, 0.52, 0.64)
		"Taiga":             return Color(0.56, 0.65, 0.75)
	return Color(0.52, 0.70, 0.90)

# ─── Hava ─────────────────────────────────────────────────────────────────────
func _setup_weather(biome: Dictionary) -> void:
	var precip: String = str(biome.get("precipitation_type", "none"))
	if precip == "none": return

	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.name     = "WeatherParticles"
	particles.amount   = 400
	particles.lifetime = 3.5
	particles.preprocess = 2.0
	particles.emitting = true

	var pmat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pmat.emission_shape       = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pmat.emission_box_extents = Vector3(30.0, 1.0, 30.0)
	pmat.direction            = Vector3(0.0, -1.0, 0.0)
	pmat.spread               = 3.0

	if precip == "snow":
		pmat.initial_velocity_min = 1.2
		pmat.initial_velocity_max = 2.8
		pmat.gravity = Vector3(0.08, -2.0, 0.05)
		pmat.scale_min = 0.04; pmat.scale_max = 0.10
	else:
		pmat.initial_velocity_min = 6.0
		pmat.initial_velocity_max = 10.0
		pmat.gravity = Vector3(0.0, -9.8, 0.0)
		pmat.scale_min = 0.02; pmat.scale_max = 0.04

	particles.process_material = pmat

	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(0.05, 0.18) if precip == "rain" else Vector2(0.08, 0.08)
	var smat: StandardMaterial3D = StandardMaterial3D.new()
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.cull_mode    = BaseMaterial3D.CULL_DISABLED
	smat.albedo_color = Color(0.75, 0.82, 0.94, 0.65) if precip == "rain" else Color(0.95, 0.97, 1.0, 0.80)
	quad.surface_set_material(0, smat)
	particles.draw_pass_1 = quad
	particles.position = Vector3(0.0, 18.0, 0.0)
	_world_root.add_child(particles)

# ─── Işık ─────────────────────────────────────────────────────────────────────
func _setup_lighting(biome: Dictionary) -> void:
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy  = float(biome.get("light_intensity", 1.0))
	sun.light_color   = _light_color(str(biome.get("name", "")))
	sun.shadow_enabled = false
	sun.rotation_degrees = Vector3(-52.0, 38.0, 0.0)
	_world_root.add_child(sun)

	var fill: OmniLight3D = OmniLight3D.new()
	fill.name = "AmbientFill"
	fill.light_energy = 0.32
	fill.omni_range = 120.0
	fill.position = Vector3(0.0, 15.0, 0.0)
	_world_root.add_child(fill)

func _light_color(bname: String) -> Color:
	match bname:
		"Savanna": return Color(1.0, 0.88, 0.66)
		"Tundra":  return Color(0.85, 0.92, 1.00)
	return Color(1.0, 0.97, 0.90)

# ─── Temizlik ─────────────────────────────────────────────────────────────────
func _clear_world() -> void:
	if _world_root == null: return
	for child: Variant in _world_root.get_children():
		(child as Node).queue_free()
	_spawned_animals.clear()
	_terrain_noise = null
