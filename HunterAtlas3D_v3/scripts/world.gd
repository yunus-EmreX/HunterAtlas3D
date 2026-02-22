extends Node3D
class_name World

signal biome_selected(biome_id: String)

@export var markers_path: NodePath = NodePath("BiomeMarkers")
@export var diorama_path: NodePath = NodePath("Diorama")
@export var camera_path: NodePath = NodePath("Camera3D")
@export var env_path: NodePath = NodePath("Env")
@export var weather_path: NodePath = NodePath("WeatherParticles")

var _marker_nodes: Array = []
var _selected_id: String = "steppe"
var _current_biome: Dictionary = {}

func _ready() -> void:
	_build_markers()

func _build_markers() -> void:
	var markers: Node3D = get_node_or_null(markers_path) as Node3D
	if markers == null:
		push_error("BiomeMarkers node not found.")
		return

	for c in markers.get_children():
		c.queue_free()
	_marker_nodes.clear()

	var points: Array = [
		{"id":"steppe","pos":Vector3(1.05, 0.20, 0.55)},
		{"id":"savanna","pos":Vector3(0.30, -0.10, 1.02)},
		{"id":"taiga","pos":Vector3(-0.55, 0.35, 0.88)},
		{"id":"rainforest","pos":Vector3(-1.00, 0.05, -0.35)},
		{"id":"tundra","pos":Vector3(0.10, 0.62, -0.95)},
		{"id":"temperate_forest","pos":Vector3(0.85, 0.25, -0.65)},
		{"id":"germanic_north","pos":Vector3(0.55, 0.52, -0.60)},
		{"id":"roman_urban","pos":Vector3(0.72, 0.10, 0.88)}
	]

	for p_any in points:
		var p: Dictionary = p_any

		var area: Area3D = Area3D.new()
		area.name = "Marker_" + str(p["id"])
		area.position = p["pos"]
		area.set_meta("biome_id", str(p["id"]))

		var mi: MeshInstance3D = MeshInstance3D.new()
		var sm: SphereMesh = SphereMesh.new()
		sm.radius = 0.04
		sm.height = 0.08
		mi.mesh = sm

		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color(1, 0.25, 0.25)
		mat.emission_enabled = true
		mat.emission = Color(1, 0.35, 0.35)
		mat.emission_energy_multiplier = 1.0
		mi.material_override = mat
		area.add_child(mi)

		var cs: CollisionShape3D = CollisionShape3D.new()
		var shp: SphereShape3D = SphereShape3D.new()
		shp.radius = 0.10
		cs.shape = shp
		area.add_child(cs)

		area.input_event.connect(_on_marker_input.bind(area))

		markers.add_child(area)
		_marker_nodes.append(area)

	_highlight_selected(_selected_id)

func _on_marker_input(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int, area: Area3D) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var id: String = str(area.get_meta("biome_id"))
		_selected_id = id
		_highlight_selected(id)
		emit_signal("biome_selected", id)

func _highlight_selected(biome_id: String) -> void:
	for n_any in _marker_nodes:
		var n: Area3D = n_any as Area3D
		if n == null:
			continue
		var id: String = str(n.get_meta("biome_id"))
		var mi: MeshInstance3D = n.get_child(0) as MeshInstance3D
		if mi == null:
			continue
		var m_any: Variant = mi.material_override
		if m_any == null or not (m_any is StandardMaterial3D):
			continue
		var sm: StandardMaterial3D = m_any
		if id == biome_id:
			sm.emission = Color(1, 1, 1)
			sm.emission_energy_multiplier = 2.6
		else:
			sm.emission = Color(1, 0.35, 0.35)
			sm.emission_energy_multiplier = 1.0

func apply_biome_visual(biome: Dictionary) -> void:
	_current_biome = biome

	var vid: String = str(biome.get("id", ""))
	var col: Color = Color(0.7, 0.7, 0.7)

	match vid:
		"steppe": col = Color(0.75,0.70,0.45)
		"savanna": col = Color(0.78,0.62,0.35)
		"taiga": col = Color(0.35,0.55,0.40)
		"rainforest": col = Color(0.20,0.50,0.28)
		"tundra": col = Color(0.85,0.90,0.95)
		"temperate_forest": col = Color(0.30,0.60,0.35)
		"germanic_north": col = Color(0.35,0.55,0.55)
		"roman_urban": col = Color(0.55,0.55,0.60)

	_rebuild_diorama(vid, col)
	_apply_environment(biome)

func _rebuild_diorama(vid: String, col: Color) -> void:
	var diorama: Node3D = get_node_or_null(diorama_path) as Node3D
	if diorama == null:
		return

	for c in diorama.get_children():
		if c.name != "Center":
			c.queue_free()

	# Ground
	var ground: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(7, 7)
	ground.mesh = plane
	var gmat: StandardMaterial3D = StandardMaterial3D.new()
	gmat.albedo_color = col
	gmat.roughness = 1.0
	ground.material_override = gmat
	ground.rotation_degrees = Vector3(-90, 0, 0)
	ground.position = Vector3(0, 0, 0)
	diorama.add_child(ground)

	# Props
	if vid == "steppe" or vid == "savanna":
		_add_grass_clusters(diorama, 18, col, 2577)
		if vid == "savanna":
			_add_tree(diorama, Vector3(1.5,0, -0.6), 0.9, true)
	elif vid == "rainforest" or vid == "temperate_forest":
		_add_tree(diorama, Vector3(-1.2,0, 0.8), 1.2, false)
		_add_tree(diorama, Vector3(1.1,0, -0.9), 1.0, false)
		_add_tree(diorama, Vector3(0.3,0, 1.5), 1.4, false)
		_add_rocks(diorama, 10)
	elif vid == "taiga" or vid == "germanic_north":
		_add_tree(diorama, Vector3(-1.2,0, -0.8), 1.3, false)
		_add_tree(diorama, Vector3(1.3,0, 0.9), 1.1, false)
		_add_tree(diorama, Vector3(0.0,0, 1.6), 1.5, false)
		_add_rocks(diorama, 8)
	elif vid == "tundra":
		_add_rocks(diorama, 14)
		_add_snow_mounds(diorama, 8)
	elif vid == "roman_urban":
		_add_ruins(diorama)

	_spawn_animals(diorama, vid)

func _apply_environment(biome: Dictionary) -> void:
	var env_node: WorldEnvironment = get_node_or_null(env_path) as WorldEnvironment
	var weather: GPUParticles3D = get_node_or_null(weather_path) as GPUParticles3D
	if env_node == null:
		return

	var haz_any: Variant = biome.get("hazards", {})
	var climate_any: Variant = biome.get("climate", {})
	var haz: Dictionary = haz_any if typeof(haz_any) == TYPE_DICTIONARY else {}
	var climate: Dictionary = climate_any if typeof(climate_any) == TYPE_DICTIONARY else {}

	var exposure: float = float(haz.get("exposure", 0.5))
	var humidity: float = float(climate.get("humidity", 0.5))
	var wind: float = float(climate.get("wind", 0.5))
	var temp_avg: float = float(climate.get("temp_c_avg", 10.0))

	var e: Environment = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05,0.06,0.08)
	e.fog_enabled = true
	e.fog_light_color = Color(0.86,0.88,0.92)
	e.fog_density = clamp(0.010 + humidity * 0.030 + exposure * 0.020, 0.010, 0.080)
	env_node.environment = e

	if weather != null and weather.process_material is ParticleProcessMaterial:
		var pm: ParticleProcessMaterial = weather.process_material
		pm.direction = Vector3(0, -1, 0)
		pm.gravity = Vector3(0, -9.8, 0)
		pm.initial_velocity_min = 1.0 + wind * 2.0
		pm.initial_velocity_max = 2.0 + wind * 4.0

		var do_snow: bool = temp_avg <= 0.0
		var do_rain: bool = humidity >= 0.65 and not do_snow
		weather.emitting = do_snow or do_rain

		if do_snow:
			pm.scale_min = 0.08
			pm.scale_max = 0.14
			pm.initial_velocity_min = 0.7
			pm.initial_velocity_max = 1.3
		elif do_rain:
			pm.scale_min = 0.03
			pm.scale_max = 0.06
		else:
			pm.scale_min = 0.05
			pm.scale_max = 0.08

func _spawn_animals(parent: Node3D, vid: String) -> void:
	# clear existing animals
	for c in parent.get_children():
		if str(c.name).begins_with("Animal_"):
			c.queue_free()

	var animals: Array = []
	var animals_any: Variant = _current_biome.get("animals", [])
	if typeof(animals_any) == TYPE_ARRAY:
		animals = animals_any
	var count: int = clamp(animals.size(), 2, 6)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(hash(vid) & 0x7fffffff) + 1337

	for i in range(count):
		var species: String = "Hayvan"
		if i < animals.size():
			var a_any: Variant = animals[i]
			if typeof(a_any) == TYPE_DICTIONARY:
				species = str((a_any as Dictionary).get("name", "Hayvan"))
			else:
				species = str(a_any)

		var animal_node: Node3D = _make_animal_mesh(species)
		var ang: float = rng.randf() * TAU
		var rad: float = 1.2 + rng.randf() * 1.8
		animal_node.position = Vector3(cos(ang) * rad, 0.12, sin(ang) * rad)
		parent.add_child(animal_node)

		var a: Animal = Animal.new()
		animal_node.add_child(a)
		a.species = species
		a.speed = 0.25 + rng.randf() * 0.25
		a.wander_radius = 2.2
		a.init(Vector3(0, 0.12, 0), int(rng.randi()))

func _make_animal_mesh(species: String) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Animal_" + species

	var body: MeshInstance3D = MeshInstance3D.new()
	var cap: CapsuleMesh = CapsuleMesh.new()
	cap.radius = 0.10
	cap.height = 0.35
	body.mesh = cap
	body.rotation_degrees = Vector3(90, 0, 0)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.85,0.80,0.75)
	mat.roughness = 1.0
	body.material_override = mat
	root.add_child(body)

	var head: MeshInstance3D = MeshInstance3D.new()
	var sph: SphereMesh = SphereMesh.new()
	sph.radius = 0.09
	sph.height = 0.18
	head.mesh = sph
	head.position = Vector3(0, 0.0, 0.18)
	head.material_override = mat
	root.add_child(head)

	return root

func _add_grass_clusters(parent: Node3D, n: int, base_col: Color, seed: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed

	for i in range(n):
		var mi: MeshInstance3D = MeshInstance3D.new()
		var cm: CylinderMesh = CylinderMesh.new()
		cm.top_radius = 0.03
		cm.bottom_radius = 0.05
		cm.height = 0.20 + rng.randf() * 0.20
		mi.mesh = cm

		var m: StandardMaterial3D = StandardMaterial3D.new()
		m.albedo_color = base_col.lerp(Color(0.20,0.60,0.30), 0.35 + rng.randf() * 0.25)
		m.roughness = 1.0
		mi.material_override = m

		var ang: float = rng.randf() * TAU
		var rad: float = 0.8 + rng.randf() * 2.4
		mi.position = Vector3(cos(ang) * rad, cm.height * 0.5, sin(ang) * rad)
		parent.add_child(mi)

func _add_tree(parent: Node3D, pos: Vector3, scale: float, acacia: bool) -> void:
	var trunk: MeshInstance3D = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = 0.10 * scale
	cyl.bottom_radius = 0.12 * scale
	cyl.height = 1.2 * scale
	trunk.mesh = cyl
	trunk.position = pos + Vector3(0, cyl.height * 0.5, 0)
	var tmat: StandardMaterial3D = StandardMaterial3D.new()
	tmat.albedo_color = Color(0.35,0.26,0.18)
	tmat.roughness = 1.0
	trunk.material_override = tmat
	parent.add_child(trunk)

	var crown: MeshInstance3D = MeshInstance3D.new()
	var sm: SphereMesh = SphereMesh.new()
	sm.radius = (0.55 if not acacia else 0.75) * scale
	sm.height = sm.radius * 2.0
	crown.mesh = sm
	crown.position = pos + Vector3(0, cyl.height + sm.radius * 0.7, 0)
	var cmat: StandardMaterial3D = StandardMaterial3D.new()
	cmat.albedo_color = Color(0.20,0.50,0.28) if not acacia else Color(0.35,0.55,0.25)
	cmat.roughness = 1.0
	crown.material_override = cmat
	parent.add_child(crown)

func _add_rocks(parent: Node3D, n: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4207

	for i in range(n):
		var mi: MeshInstance3D = MeshInstance3D.new()
		var b: BoxMesh = BoxMesh.new()
		b.size = Vector3(0.25 + rng.randf() * 0.35, 0.15 + rng.randf() * 0.25, 0.25 + rng.randf() * 0.35)
		mi.mesh = b
		var m: StandardMaterial3D = StandardMaterial3D.new()
		m.albedo_color = Color(0.45,0.46,0.48)
		m.roughness = 1.0
		mi.material_override = m

		var ang: float = rng.randf() * TAU
		var rad: float = 0.7 + rng.randf() * 2.6
		mi.position = Vector3(cos(ang) * rad, b.size.y * 0.5, sin(ang) * rad)
		mi.rotation_degrees = Vector3(0, rng.randf() * 180.0, 0)
		parent.add_child(mi)

func _add_snow_mounds(parent: Node3D, n: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 9901

	for i in range(n):
		var mi: MeshInstance3D = MeshInstance3D.new()
		var sm: SphereMesh = SphereMesh.new()
		sm.radius = 0.18 + rng.randf() * 0.25
		sm.height = sm.radius * 2.0
		mi.mesh = sm
		var m: StandardMaterial3D = StandardMaterial3D.new()
		m.albedo_color = Color(0.90,0.93,0.98)
		m.roughness = 1.0
		mi.material_override = m

		var ang: float = rng.randf() * TAU
		var rad: float = 0.7 + rng.randf() * 2.3
		mi.position = Vector3(cos(ang) * rad, sm.radius * 0.65, sin(ang) * rad)
		parent.add_child(mi)

func _add_ruins(parent: Node3D) -> void:
	for x in range(-2, 3):
		for z in range(-2, 3):
			if (abs(x) == 2 or abs(z) == 2) and (x + z) % 2 == 0:
				var col: MeshInstance3D = MeshInstance3D.new()
				var cyl: CylinderMesh = CylinderMesh.new()
				cyl.top_radius = 0.10
				cyl.bottom_radius = 0.12
				cyl.height = 1.0
				col.mesh = cyl
				col.position = Vector3(float(x) * 0.8, cyl.height * 0.5, float(z) * 0.8)
				var m: StandardMaterial3D = StandardMaterial3D.new()
				m.albedo_color = Color(0.72,0.72,0.76)
				m.roughness = 1.0
				col.material_override = m
				parent.add_child(col)
