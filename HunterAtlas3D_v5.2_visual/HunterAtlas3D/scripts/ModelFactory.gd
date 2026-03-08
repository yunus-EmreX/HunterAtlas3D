## ModelFactory.gd
## Tüm karakterlerin ve çevre nesnelerinin detaylı prosedürel 3D modellerini üretir.
## Her model çoklu parçadan oluşan Node3D hiyerarşisidir.
## Animasyon için bacak node'larına isimle erişilebilir.

class_name ModelFactory
extends RefCounted

# ─── Materyal Yardımcıları ────────────────────────────────────────────────────

static func _mat(c: Color, roughness: float = 0.82) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = roughness
	return m

static func _mat_emit(c: Color, strength: float = 0.6) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = strength
	m.roughness = 0.3
	return m

static func _mat_shiny(c: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.2
	m.metallic = 0.1
	return m

# Mesh + materyal + transform ile MeshInstance3D ekler, referansı döndürür
static func _mi(parent: Node3D, mesh: Mesh, mat: Material,
		pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	if rot_deg != Vector3.ZERO:
		mi.rotation_degrees = rot_deg
	if scl != Vector3.ONE:
		mi.scale = scl
	parent.add_child(mi)
	return mi

static func _sphere(r: float) -> SphereMesh:
	var m: SphereMesh = SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 12
	m.rings = 8
	return m

static func _capsule(r: float, h: float) -> CapsuleMesh:
	var m: CapsuleMesh = CapsuleMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 10
	return m

static func _cylinder(top_r: float, bot_r: float, h: float) -> CylinderMesh:
	var m: CylinderMesh = CylinderMesh.new()
	m.top_radius = top_r
	m.bottom_radius = bot_r
	m.height = h
	m.radial_segments = 10
	return m

static func _box(sx: float, sy: float, sz: float) -> BoxMesh:
	var m: BoxMesh = BoxMesh.new()
	m.size = Vector3(sx, sy, sz)
	return m

# ═══════════════════════════════════════════════════════════════════════════════
# KAPLAN  (Bengal Tiger)
# ═══════════════════════════════════════════════════════════════════════════════
## Kaplan oluşturur. Kök Node3D döndürür; bacaklar isme göre erişilebilir.
## Animasyon node'ları: "Leg_FL", "Leg_FR", "Leg_RL", "Leg_RR", "TailRoot"
static func create_tiger() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Tiger"

	# ── Renkler ───────────────────────────────────────────────────────────────
	var orange: StandardMaterial3D  = _mat(Color(0.86, 0.43, 0.09))
	var stripe: StandardMaterial3D  = _mat(Color(0.12, 0.06, 0.03))
	var cream: StandardMaterial3D   = _mat(Color(0.93, 0.85, 0.70))
	var eye_m: StandardMaterial3D   = _mat_emit(Color(0.18, 0.78, 0.12), 0.8)
	var pupil_m: StandardMaterial3D = _mat(Color(0.04, 0.02, 0.02))
	var nose_m: StandardMaterial3D  = _mat(Color(0.80, 0.42, 0.42))
	var ear_in: StandardMaterial3D  = _mat(Color(0.78, 0.28, 0.22))
	var dark_m: StandardMaterial3D  = _mat(Color(0.18, 0.09, 0.04))

	# ── Gövde (yatay kapsül) ──────────────────────────────────────────────────
	_mi(root, _capsule(0.24, 1.30), orange,
		Vector3(0.0, 0.78, 0.0),
		Vector3(0.0, 0.0, 90.0),
		Vector3(1.0, 0.88, 1.0))

	# Alt karın (krem)
	_mi(root, _box(0.40, 0.07, 0.70), cream, Vector3(0.0, 0.54, 0.02))

	# Göğüs dolgusu
	_mi(root, _sphere(0.19), cream,
		Vector3(0.0, 0.72, -0.52), Vector3.ZERO, Vector3(1.1, 0.85, 0.7))

	# ── Boyun ─────────────────────────────────────────────────────────────────
	_mi(root, _cylinder(0.16, 0.19, 0.35), orange,
		Vector3(0.0, 0.90, -0.52), Vector3(28.0, 0.0, 0.0))

	# ── Kafa ──────────────────────────────────────────────────────────────────
	_mi(root, _sphere(0.20), orange,
		Vector3(0.0, 1.07, -0.76), Vector3.ZERO, Vector3(1.05, 0.96, 1.08))

	# Alın çizgisi
	_mi(root, _box(0.30, 0.05, 0.09), stripe,
		Vector3(0.0, 1.18, -0.74), Vector3(-12.0, 0.0, 0.0))

	# Yanak pulları (krem)
	for sx: float in [-1.0, 1.0]:
		_mi(root, _sphere(0.10), cream,
			Vector3(sx * 0.155, 0.98, -0.86), Vector3.ZERO, Vector3(0.7, 0.8, 0.6))

	# Burun köprüsü çizgisi
	_mi(root, _box(0.06, 0.14, 0.06), stripe,
		Vector3(0.0, 1.08, -0.88))

	# ── Burun ─────────────────────────────────────────────────────────────────
	_mi(root, _sphere(0.12), cream,
		Vector3(0.0, 1.00, -0.94), Vector3.ZERO, Vector3(0.90, 0.75, 1.05))

	# Burun ucu
	_mi(root, _sphere(0.038), nose_m,
		Vector3(0.0, 1.01, -1.04), Vector3.ZERO, Vector3(1.3, 0.7, 0.8))

	# Alt çene
	_mi(root, _sphere(0.09), cream,
		Vector3(0.0, 0.92, -0.93), Vector3.ZERO, Vector3(1.1, 0.6, 0.9))

	# ── Gözler ────────────────────────────────────────────────────────────────
	for sx2: float in [-1.0, 1.0]:
		_mi(root, _sphere(0.044), eye_m,
			Vector3(sx2 * 0.122, 1.10, -0.920))
		_mi(root, _sphere(0.022), pupil_m,
			Vector3(sx2 * 0.130, 1.10, -0.954),
			Vector3.ZERO, Vector3(0.45, 1.0, 0.45))
		# Göz parlak noktası
		_mi(root, _sphere(0.009), _mat(Color(1, 1, 1)),
			Vector3(sx2 * 0.138 - sx2 * 0.01, 1.115, -0.960))

	# ── Kulaklar ──────────────────────────────────────────────────────────────
	for sx3: float in [-1.0, 1.0]:
		_mi(root, _cylinder(0.015, 0.075, 0.125), orange,
			Vector3(sx3 * 0.145, 1.255, -0.755), Vector3(0.0, 0.0, sx3 * 14.0))
		_mi(root, _cylinder(0.008, 0.048, 0.095), ear_in,
			Vector3(sx3 * 0.145, 1.255, -0.753), Vector3(0.0, 0.0, sx3 * 14.0))

	# ── Bıyıklar ──────────────────────────────────────────────────────────────
	for bx: int in range(3):
		for sx4: float in [-1.0, 1.0]:
			_mi(root, _cylinder(0.004, 0.003, 0.22), cream,
				Vector3(sx4 * (0.12 + bx * 0.04), 1.00, -0.92),
				Vector3(90.0, sx4 * (20.0 + bx * 15.0), 0.0))

	# ── Çizgiler (vücutta) ────────────────────────────────────────────────────
	var stripe_data: Array = [
		[Vector3(0.0, 0.78, -0.38), Vector3(0.0, 8.0, 0.0),  Vector3(0.55, 0.50, 0.085)],
		[Vector3(0.0, 0.78, -0.14), Vector3(0.0, -5.0, 0.0), Vector3(0.55, 0.50, 0.092)],
		[Vector3(0.0, 0.78,  0.10), Vector3(0.0, 6.0, 0.0),  Vector3(0.55, 0.50, 0.085)],
		[Vector3(0.0, 0.78,  0.34), Vector3(0.0, -8.0, 0.0), Vector3(0.55, 0.50, 0.090)],
		[Vector3(0.0, 0.78,  0.54), Vector3(0.0, 4.0, 0.0),  Vector3(0.50, 0.48, 0.078)],
	]
	for sd: Variant in stripe_data:
		var d: Array = sd as Array
		_mi(root, _box(1.0, 1.0, 1.0), stripe,
			d[0] as Vector3, d[1] as Vector3, d[2] as Vector3)

	# Omuz çizgileri (her iki yan)
	for sx5: float in [-1.0, 1.0]:
		_mi(root, _box(0.07, 0.40, 0.38), stripe,
			Vector3(sx5 * 0.245, 0.78, -0.28), Vector3(0.0, 0.0, sx5 * 16.0))

	# ── Bacaklar ──────────────────────────────────────────────────────────────
	_add_cat_leg(root, "Leg_FL", Vector3(-0.195, 0.68, -0.36), orange, cream, dark_m)
	_add_cat_leg(root, "Leg_FR", Vector3( 0.195, 0.68, -0.36), orange, cream, dark_m)
	_add_cat_leg(root, "Leg_RL", Vector3(-0.195, 0.68,  0.40), orange, cream, dark_m)
	_add_cat_leg(root, "Leg_RR", Vector3( 0.195, 0.68,  0.40), orange, cream, dark_m)

	# ── Kuyruk ────────────────────────────────────────────────────────────────
	var tail_root: Node3D = Node3D.new()
	tail_root.name = "TailRoot"
	tail_root.position = Vector3(0.0, 0.82, 0.66)
	root.add_child(tail_root)

	var tail_curve: Array = [
		[Vector3(0.0, 0.00, 0.00), 0.092],
		[Vector3(0.0, 0.10, 0.17), 0.082],
		[Vector3(0.0, 0.24, 0.30), 0.070],
		[Vector3(0.0, 0.40, 0.36), 0.058],
		[Vector3(0.0, 0.54, 0.35), 0.046],
		[Vector3(0.0, 0.64, 0.27), 0.036],
		[Vector3(0.0, 0.68, 0.17), 0.028],  # tip
	]
	for ti: int in range(tail_curve.size()):
		var td: Array = tail_curve[ti] as Array
		var tc: StandardMaterial3D = stripe if (ti == tail_curve.size()-1 or ti % 2 == 0) else orange
		if ti < tail_curve.size() - 1:
			tc = orange
		if ti >= tail_curve.size() - 2:
			tc = stripe
		_mi(tail_root, _sphere(float(td[1])), tc, td[0] as Vector3)

	return root

## Kedi bacağı ekler (kaplan, aslan, jaguar paylaşır)
static func _add_cat_leg(parent: Node3D, leg_name: String,
		attach_pos: Vector3,
		body_mat: StandardMaterial3D,
		paw_mat: StandardMaterial3D,
		stripe_mat: StandardMaterial3D) -> Node3D:

	var leg: Node3D = Node3D.new()
	leg.name = leg_name
	leg.position = attach_pos
	parent.add_child(leg)

	# Üst uyluk
	_mi(leg, _capsule(0.078, 0.38), body_mat, Vector3(0.0, -0.19, 0.0))
	# Diz eklemi
	_mi(leg, _sphere(0.072), body_mat, Vector3(0.0, -0.38, 0.0))
	# Alt bacak (hafif öne eğik)
	_mi(leg, _capsule(0.058, 0.32), body_mat, Vector3(0.0, -0.54, 0.03), Vector3(8.0, 0.0, 0.0))
	# Pençe (oval)
	_mi(leg, _sphere(0.090), paw_mat,
		Vector3(0.0, -0.68, 0.06), Vector3.ZERO, Vector3(1.25, 0.50, 1.35))
	# Pençe çizgisi
	_mi(leg, _box(0.01, 0.06, 0.09), stripe_mat,
		Vector3(0.0, -0.69, 0.09))
	return leg

# ═══════════════════════════════════════════════════════════════════════════════
# ASLAN  (renk varyantı: sarı-kahve, mane)
# ═══════════════════════════════════════════════════════════════════════════════
static func create_lion() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Lion"

	var tan_m: StandardMaterial3D  = _mat(Color(0.82, 0.68, 0.38))
	var dark_m: StandardMaterial3D = _mat(Color(0.28, 0.18, 0.08))
	var cream_m: StandardMaterial3D = _mat(Color(0.92, 0.83, 0.62))
	var eye_m: StandardMaterial3D  = _mat_emit(Color(0.88, 0.62, 0.08), 0.7)
	var mane_m: StandardMaterial3D = _mat(Color(0.42, 0.25, 0.10))
	var nose_m: StandardMaterial3D = _mat(Color(0.72, 0.35, 0.35))

	# Gövde
	_mi(root, _capsule(0.26, 1.35), tan_m,
		Vector3(0.0, 0.80, 0.0), Vector3(0.0, 0.0, 90.0), Vector3(1.0, 0.9, 1.0))
	_mi(root, _box(0.42, 0.07, 0.72), cream_m, Vector3(0.0, 0.55, 0.02))

	# Yele
	for i: int in range(10):
		var angle: float = TAU / 10.0 * i
		var mx: float = cos(angle) * 0.28
		var my: float = 1.05 + sin(angle) * 0.18
		var mz: float = -0.72 + sin(angle) * 0.06
		_mi(root, _sphere(0.12), mane_m,
			Vector3(mx, my, mz), Vector3.ZERO, Vector3(1.0, 1.0, 0.5))

	# Kafa
	_mi(root, _sphere(0.22), tan_m,
		Vector3(0.0, 1.06, -0.78), Vector3.ZERO, Vector3(1.08, 0.98, 1.10))

	# Yüz detayları
	_mi(root, _sphere(0.13), cream_m,
		Vector3(0.0, 1.00, -0.97), Vector3.ZERO, Vector3(0.90, 0.78, 1.05))
	_mi(root, _sphere(0.040), nose_m,
		Vector3(0.0, 1.01, -1.07), Vector3.ZERO, Vector3(1.3, 0.7, 0.8))
	_mi(root, _sphere(0.09), cream_m,
		Vector3(0.0, 0.92, -0.96), Vector3.ZERO, Vector3(1.1, 0.6, 0.9))

	# Boyun
	_mi(root, _cylinder(0.18, 0.21, 0.36), tan_m,
		Vector3(0.0, 0.92, -0.54), Vector3(28.0, 0.0, 0.0))

	# Kulaklar
	for ex: float in [-1.0, 1.0]:
		_mi(root, _cylinder(0.018, 0.078, 0.12), tan_m,
			Vector3(ex * 0.17, 1.26, -0.77), Vector3(0.0, 0.0, ex * 12.0))

	# Gözler
	for ex2: float in [-1.0, 1.0]:
		_mi(root, _sphere(0.046), eye_m,
			Vector3(ex2 * 0.125, 1.10, -0.935))
		_mi(root, _sphere(0.024), dark_m,
			Vector3(ex2 * 0.133, 1.10, -0.968), Vector3.ZERO, Vector3(0.5, 1.0, 0.5))

	# Bacaklar
	_add_cat_leg(root, "Leg_FL", Vector3(-0.20, 0.70, -0.38), tan_m, cream_m, dark_m)
	_add_cat_leg(root, "Leg_FR", Vector3( 0.20, 0.70, -0.38), tan_m, cream_m, dark_m)
	_add_cat_leg(root, "Leg_RL", Vector3(-0.20, 0.70,  0.42), tan_m, cream_m, dark_m)
	_add_cat_leg(root, "Leg_RR", Vector3( 0.20, 0.70,  0.42), tan_m, cream_m, dark_m)

	# Kuyruk
	var tr: Node3D = Node3D.new(); tr.name = "TailRoot"
	tr.position = Vector3(0.0, 0.84, 0.68)
	root.add_child(tr)
	var t_pts: Array = [
		[Vector3(0,0,0), 0.09], [Vector3(0,0.1,0.17), 0.08],
		[Vector3(0,0.25,0.31), 0.07], [Vector3(0,0.42,0.37), 0.055],
		[Vector3(0,0.56,0.32), 0.042], [Vector3(0,0.65,0.18), 0.06], # bushy tip
	]
	for tp: Variant in t_pts:
		var tpa: Array = tp as Array
		var tc: StandardMaterial3D = mane_m if t_pts.find(tp) == t_pts.size()-1 else tan_m
		_mi(tr, _sphere(float(tpa[1])), tc, tpa[0] as Vector3)

	return root

# ═══════════════════════════════════════════════════════════════════════════════
# GEYİK  (kırmızı geyik / deer)
# ═══════════════════════════════════════════════════════════════════════════════
static func create_deer() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Deer"

	var brown: StandardMaterial3D = _mat(Color(0.62, 0.35, 0.15))
	var cream: StandardMaterial3D = _mat(Color(0.90, 0.80, 0.62))
	var dark: StandardMaterial3D  = _mat(Color(0.20, 0.12, 0.06))
	var eye_m: StandardMaterial3D = _mat_emit(Color(0.08, 0.08, 0.08), 0.2)
	var antler: StandardMaterial3D = _mat(Color(0.58, 0.42, 0.22))

	# Gövde
	_mi(root, _capsule(0.18, 1.10), brown,
		Vector3(0.0, 0.72, 0.0), Vector3(0.0, 0.0, 90.0), Vector3(1.0, 0.82, 1.0))
	_mi(root, _box(0.30, 0.06, 0.60), cream, Vector3(0.0, 0.55, 0.02))

	# Boyun (uzun ve ince)
	_mi(root, _cylinder(0.10, 0.12, 0.42), brown,
		Vector3(0.0, 0.92, -0.48), Vector3(35.0, 0.0, 0.0))

	# Kafa
	_mi(root, _sphere(0.145), brown,
		Vector3(0.0, 1.12, -0.74), Vector3.ZERO, Vector3(0.90, 0.85, 1.05))

	# Uzun burun
	_mi(root, _cylinder(0.055, 0.070, 0.22), brown,
		Vector3(0.0, 1.06, -0.90), Vector3(80.0, 0.0, 0.0))
	_mi(root, _sphere(0.062), cream,
		Vector3(0.0, 1.01, -1.01), Vector3.ZERO, Vector3(0.88, 0.72, 0.80))
	_mi(root, _sphere(0.025), dark,
		Vector3(0.0, 1.03, -1.06), Vector3.ZERO, Vector3(1.2, 0.6, 0.8))

	# Büyük gözler
	for ex: float in [-1.0, 1.0]:
		_mi(root, _sphere(0.048), eye_m,
			Vector3(ex * 0.098, 1.14, -0.80))
		_mi(root, _sphere(0.014), _mat(Color(0.9,0.9,0.9)),
			Vector3(ex * 0.108, 1.148, -0.840))

	# Kulaklar (büyük, yatay)
	for ex2: float in [-1.0, 1.0]:
		_mi(root, _sphere(0.078), brown,
			Vector3(ex2 * 0.20, 1.14, -0.73), Vector3.ZERO, Vector3(0.45, 1.6, 0.55))

	# Beyaz yanak/çene
	_mi(root, _sphere(0.072), cream,
		Vector3(0.0, 1.02, -0.87), Vector3.ZERO, Vector3(1.1, 0.7, 0.7))

	# Boynuzlar
	for ax: float in [-1.0, 1.0]:
		# Ana gövde
		_mi(root, _cylinder(0.008, 0.016, 0.38), antler,
			Vector3(ax * 0.10, 1.24, -0.73),
			Vector3(-20.0, 0.0, ax * -22.0))
		# Ön dal
		_mi(root, _cylinder(0.006, 0.012, 0.22), antler,
			Vector3(ax * 0.18, 1.44, -0.76),
			Vector3(10.0, 0.0, ax * -30.0))
		# Arka dal
		_mi(root, _cylinder(0.006, 0.012, 0.20), antler,
			Vector3(ax * 0.22, 1.50, -0.68),
			Vector3(-30.0, 0.0, ax * -10.0))
		# Üst dal
		_mi(root, _cylinder(0.005, 0.010, 0.18), antler,
			Vector3(ax * 0.26, 1.56, -0.72),
			Vector3(5.0, 0.0, ax * -40.0))

	# Beyaz popo lekesi
	_mi(root, _sphere(0.16), cream,
		Vector3(0.0, 0.74, 0.54), Vector3.ZERO, Vector3(1.1, 0.9, 0.6))

	# Bacaklar (uzun ve ince)
	_add_deer_leg(root, "Leg_FL", Vector3(-0.14, 0.64, -0.30), brown, cream)
	_add_deer_leg(root, "Leg_FR", Vector3( 0.14, 0.64, -0.30), brown, cream)
	_add_deer_leg(root, "Leg_RL", Vector3(-0.14, 0.64,  0.35), brown, cream)
	_add_deer_leg(root, "Leg_RR", Vector3( 0.14, 0.64,  0.35), brown, cream)

	# Kuyruk (kısa, beyaz)
	_mi(root, _sphere(0.06), cream,
		Vector3(0.0, 0.80, 0.57), Vector3.ZERO, Vector3(0.8, 0.7, 0.6))

	return root

static func _add_deer_leg(parent: Node3D, leg_name: String,
		pos: Vector3, body_m: StandardMaterial3D,
		hoof_m: StandardMaterial3D) -> Node3D:
	var leg: Node3D = Node3D.new()
	leg.name = leg_name
	leg.position = pos
	parent.add_child(leg)
	_mi(leg, _capsule(0.048, 0.38), body_m, Vector3(0.0, -0.19, 0.0))
	_mi(leg, _capsule(0.038, 0.30), body_m, Vector3(0.0, -0.46, 0.02), Vector3(5.0,0,0))
	_mi(leg, _box(0.072, 0.09, 0.060), hoof_m, Vector3(0.0, -0.63, 0.02))  # toynak
	return leg

# ═══════════════════════════════════════════════════════════════════════════════
# KURT  (wolf)
# ═══════════════════════════════════════════════════════════════════════════════
static func create_wolf() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Wolf"

	var grey: StandardMaterial3D  = _mat(Color(0.55, 0.52, 0.48))
	var dark_g: StandardMaterial3D = _mat(Color(0.32, 0.30, 0.27))
	var cream: StandardMaterial3D = _mat(Color(0.88, 0.82, 0.70))
	var eye_m: StandardMaterial3D = _mat_emit(Color(0.68, 0.58, 0.08), 0.6)
	var nose_m: StandardMaterial3D = _mat(Color(0.12, 0.12, 0.12))

	# Gövde
	_mi(root, _capsule(0.185, 1.05), grey,
		Vector3(0.0, 0.68, 0.0), Vector3(0.0, 0.0, 90.0), Vector3(1.0, 0.80, 1.0))
	_mi(root, _box(0.32, 0.06, 0.55), cream, Vector3(0.0, 0.50, 0.02))

	# Sırt koyu rengi
	_mi(root, _box(0.24, 0.08, 0.90), dark_g,
		Vector3(0.0, 0.82, 0.0))

	# Boyun
	_mi(root, _cylinder(0.115, 0.14, 0.32), grey,
		Vector3(0.0, 0.80, -0.44), Vector3(28.0, 0.0, 0.0))

	# Kafa
	_mi(root, _sphere(0.155), grey,
		Vector3(0.0, 0.96, -0.66), Vector3.ZERO, Vector3(1.0, 0.90, 1.10))

	# Sivri burun
	_mi(root, _cylinder(0.030, 0.080, 0.30), grey,
		Vector3(0.0, 0.90, -0.85), Vector3(82.0, 0.0, 0.0))
	_mi(root, _sphere(0.044), cream,
		Vector3(0.0, 0.85, -1.00), Vector3.ZERO, Vector3(0.9, 0.7, 0.8))
	_mi(root, _sphere(0.032), nose_m,
		Vector3(0.0, 0.87, -1.05), Vector3.ZERO, Vector3(1.2, 0.7, 0.8))

	# Gözler
	for ex: float in [-1.0, 1.0]:
		_mi(root, _sphere(0.038), eye_m,
			Vector3(ex * 0.098, 0.98, -0.758))
		_mi(root, _sphere(0.018), nose_m,
			Vector3(ex * 0.104, 0.98, -0.788), Vector3.ZERO, Vector3(0.5,1.0,0.5))

	# Sivri kulaklar
	for ex2: float in [-1.0, 1.0]:
		_mi(root, _cylinder(0.008, 0.065, 0.15), grey,
			Vector3(ex2 * 0.12, 1.10, -0.66), Vector3(0.0, 0.0, ex2 * 10.0))
		_mi(root, _cylinder(0.004, 0.040, 0.11), dark_g,
			Vector3(ex2 * 0.12, 1.10, -0.659), Vector3(0.0, 0.0, ex2 * 10.0))

	# Bacaklar
	_add_wolf_leg(root, "Leg_FL", Vector3(-0.155, 0.58, -0.30), grey, dark_g)
	_add_wolf_leg(root, "Leg_FR", Vector3( 0.155, 0.58, -0.30), grey, dark_g)
	_add_wolf_leg(root, "Leg_RL", Vector3(-0.155, 0.58,  0.34), grey, dark_g)
	_add_wolf_leg(root, "Leg_RR", Vector3( 0.155, 0.58,  0.34), grey, dark_g)

	# Kuyruk (tüylü, kıvrık)
	var tr: Node3D = Node3D.new(); tr.name = "TailRoot"
	tr.position = Vector3(0.0, 0.75, 0.55)
	root.add_child(tr)
	var pts: Array = [
		[Vector3(0,0,0), 0.070], [Vector3(0,0.12,0.14), 0.065],
		[Vector3(0,0.28,0.22), 0.058], [Vector3(0,0.42,0.22), 0.052],
		[Vector3(0,0.52,0.14), 0.060],
	]
	var tip_mat: StandardMaterial3D = cream
	for pi: int in range(pts.size()):
		var pa: Array = pts[pi] as Array
		_mi(tr, _sphere(float(pa[1])), tip_mat if pi == pts.size()-1 else grey, pa[0] as Vector3)

	return root

static func _add_wolf_leg(parent: Node3D, leg_name: String,
		pos: Vector3, body_m: StandardMaterial3D,
		dark_m: StandardMaterial3D) -> Node3D:
	var leg: Node3D = Node3D.new()
	leg.name = leg_name
	leg.position = pos
	parent.add_child(leg)
	_mi(leg, _capsule(0.062, 0.32), body_m, Vector3(0.0, -0.16, 0.0))
	_mi(leg, _capsule(0.050, 0.28), dark_m, Vector3(0.0, -0.38, 0.02), Vector3(6.0,0,0))
	_mi(leg, _sphere(0.068), dark_m, Vector3(0.0, -0.54, 0.04), Vector3.ZERO, Vector3(1.2, 0.45, 1.3))
	return leg

# ═══════════════════════════════════════════════════════════════════════════════
# AYAK  (brown bear / polar bear)
# ═══════════════════════════════════════════════════════════════════════════════
static func create_bear(polar: bool = false) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "PolarBear" if polar else "Bear"

	var body_c: Color = Color(0.92, 0.90, 0.88) if polar else Color(0.35, 0.22, 0.10)
	var body_m: StandardMaterial3D = _mat(body_c)
	var dark_m: StandardMaterial3D = _mat(Color(0.12, 0.10, 0.08))
	var eye_m: StandardMaterial3D  = _mat_emit(Color(0.08, 0.08, 0.08), 0.3)
	var nose_c: Color = Color(0.12, 0.10, 0.10) if polar else Color(0.22, 0.14, 0.08)
	var nose_m: StandardMaterial3D = _mat(nose_c)

	# Büyük gövde (küçük kambur omuz)
	_mi(root, _capsule(0.30, 1.30), body_m,
		Vector3(0.0, 0.80, 0.0), Vector3(0.0, 0.0, 90.0), Vector3(1.0, 0.92, 1.0))
	_mi(root, _sphere(0.32), body_m,
		Vector3(0.0, 0.90, -0.42), Vector3.ZERO, Vector3(1.0, 1.0, 0.8))  # omuz kamburu

	# Boyun
	_mi(root, _cylinder(0.20, 0.24, 0.32), body_m,
		Vector3(0.0, 0.95, -0.62), Vector3(22.0, 0.0, 0.0))

	# Büyük yuvarlak kafa
	_mi(root, _sphere(0.245), body_m,
		Vector3(0.0, 1.05, -0.88), Vector3.ZERO, Vector3(1.0, 0.92, 1.05))

	# Burun (uzun)
	_mi(root, _capsule(0.10, 0.28), body_m,
		Vector3(0.0, 1.00, -1.10), Vector3(80.0, 0.0, 0.0))
	_mi(root, _sphere(0.072), nose_m,
		Vector3(0.0, 0.99, -1.22), Vector3.ZERO, Vector3(1.3, 0.7, 0.9))

	# Gözler (küçük)
	for ex: float in [-1.0, 1.0]:
		_mi(root, _sphere(0.042), eye_m,
			Vector3(ex * 0.14, 1.10, -0.932))
		_mi(root, _sphere(0.012), _mat(Color(1,1,1)),
			Vector3(ex * 0.148, 1.110, -0.970))

	# Kulaklar (küçük yuvarlak)
	for ex2: float in [-1.0, 1.0]:
		_mi(root, _sphere(0.078), body_m,
			Vector3(ex2 * 0.185, 1.24, -0.870))
		_mi(root, _sphere(0.042), dark_m,
			Vector3(ex2 * 0.188, 1.244, -0.892))

	# Kalın bacaklar
	_add_bear_leg(root, "Leg_FL", Vector3(-0.22, 0.72, -0.40), body_m, dark_m)
	_add_bear_leg(root, "Leg_FR", Vector3( 0.22, 0.72, -0.40), body_m, dark_m)
	_add_bear_leg(root, "Leg_RL", Vector3(-0.22, 0.72,  0.44), body_m, dark_m)
	_add_bear_leg(root, "Leg_RR", Vector3( 0.22, 0.72,  0.44), body_m, dark_m)

	# Kısa kuyruk
	_mi(root, _sphere(0.08), body_m, Vector3(0.0, 0.82, 0.68))

	return root

static func _add_bear_leg(parent: Node3D, leg_name: String,
		pos: Vector3, body_m: StandardMaterial3D,
		paw_m: StandardMaterial3D) -> Node3D:
	var leg: Node3D = Node3D.new()
	leg.name = leg_name
	leg.position = pos
	parent.add_child(leg)
	_mi(leg, _capsule(0.105, 0.36), body_m, Vector3(0.0, -0.18, 0.0))
	_mi(leg, _capsule(0.092, 0.30), body_m, Vector3(0.0, -0.40, 0.0))
	_mi(leg, _sphere(0.115), paw_m,
		Vector3(0.0, -0.58, 0.04), Vector3.ZERO, Vector3(1.3, 0.45, 1.5))
	# Pençe izleri
	for ci: int in range(4):
		_mi(leg, _cylinder(0.012, 0.009, 0.06), _mat(Color(0.05,0.03,0.02)),
			Vector3(-0.03 + ci * 0.02, -0.60, 0.12),
			Vector3(-20.0, float(ci) * 5.0 - 7.0, 0.0))
	return leg

# ═══════════════════════════════════════════════════════════════════════════════
# AVCIL KARAKTERİ  (hunter)
# ═══════════════════════════════════════════════════════════════════════════════
## Avcı karakterinin görsel modelini döndürür.
## Node'lar: "Leg_L", "Leg_R", "Arm_L", "Arm_R", "SpearArm"
static func create_hunter() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "HunterModel"

	var skin: StandardMaterial3D   = _mat(Color(0.75, 0.52, 0.32))
	var leather: StandardMaterial3D = _mat(Color(0.38, 0.24, 0.12))
	var fur: StandardMaterial3D    = _mat(Color(0.52, 0.40, 0.26))
	var hair: StandardMaterial3D   = _mat(Color(0.22, 0.16, 0.10))
	var spear_wood: StandardMaterial3D = _mat(Color(0.55, 0.36, 0.18))
	var flint: StandardMaterial3D  = _mat_shiny(Color(0.42, 0.42, 0.48))
	var belt: StandardMaterial3D   = _mat(Color(0.28, 0.16, 0.08))
	var eye_m: StandardMaterial3D  = _mat(Color(0.25, 0.18, 0.10))
	var tooth: StandardMaterial3D  = _mat(Color(0.90, 0.86, 0.72))

	# ── Bacaklar ──────────────────────────────────────────────────────────────
	for side: float in [-1.0, 1.0]:
		var leg: Node3D = Node3D.new()
		leg.name = "Leg_L" if side < 0 else "Leg_R"
		leg.position = Vector3(side * 0.13, 0.0, 0.0)
		root.add_child(leg)
		# Üst bacak (deri pantolon)
		_mi(leg, _capsule(0.095, 0.48), leather, Vector3(0.0, 0.56, 0.0))
		# Diz
		_mi(leg, _sphere(0.085), leather, Vector3(0.0, 0.32, 0.0))
		# Alt bacak
		_mi(leg, _capsule(0.078, 0.40), fur, Vector3(0.0, 0.10, 0.0))
		# Ayak
		_mi(leg, _box(0.11, 0.072, 0.18), leather,
			Vector3(0.0, -0.09, 0.04), Vector3(-8.0, 0.0, 0.0))

	# ── Gövde ─────────────────────────────────────────────────────────────────
	_mi(root, _capsule(0.175, 0.68), leather, Vector3(0.0, 1.12, 0.0))
	# Kemer
	_mi(root, _cylinder(0.185, 0.190, 0.06), belt, Vector3(0.0, 0.88, 0.0))
	# Omuz levhası
	_mi(root, _box(0.58, 0.06, 0.28), fur, Vector3(0.0, 1.42, 0.0))
	# Göğüs kemiği detayı (kemer süsü)
	_mi(root, _sphere(0.030), tooth, Vector3(0.0, 1.38, 0.17))
	_mi(root, _sphere(0.028), tooth, Vector3(0.08, 1.34, 0.16))
	_mi(root, _sphere(0.028), tooth, Vector3(-0.08, 1.34, 0.16))

	# ── Kafa ──────────────────────────────────────────────────────────────────
	_mi(root, _sphere(0.188), skin,
		Vector3(0.0, 1.72, 0.0), Vector3.ZERO, Vector3(1.0, 1.05, 1.0))
	# Saç
	_mi(root, _sphere(0.198), hair,
		Vector3(0.0, 1.76, -0.02), Vector3.ZERO, Vector3(1.0, 0.62, 1.0))
	# Yüz detayları
	_mi(root, _sphere(0.100), skin,
		Vector3(0.0, 1.69, 0.15), Vector3.ZERO, Vector3(0.88, 0.72, 0.80))  # burun bölgesi
	_mi(root, _cylinder(0.030, 0.025, 0.06), skin,
		Vector3(0.0, 1.70, 0.19), Vector3(85.0, 0.0, 0.0))  # burun
	# Gözler
	for ex: float in [-1.0, 1.0]:
		_mi(root, _sphere(0.030), eye_m,
			Vector3(ex * 0.072, 1.735, 0.158))
		_mi(root, _sphere(0.010), _mat(Color(0.9,0.9,0.9)),
			Vector3(ex * 0.080, 1.742, 0.165))
	# Kaşlar
	for ex2: float in [-1.0, 1.0]:
		_mi(root, _box(0.08, 0.016, 0.020), hair,
			Vector3(ex2 * 0.072, 1.770, 0.160))
	# Çene
	_mi(root, _sphere(0.085), skin,
		Vector3(0.0, 1.635, 0.12), Vector3.ZERO, Vector3(0.9, 0.6, 0.85))

	# ── Kollar ────────────────────────────────────────────────────────────────
	# Sol kol (serbest)
	var arm_l: Node3D = Node3D.new()
	arm_l.name = "Arm_L"
	arm_l.position = Vector3(-0.265, 1.42, 0.0)
	root.add_child(arm_l)
	_mi(arm_l, _capsule(0.072, 0.38), leather, Vector3(0.0, -0.19, 0.0))
	_mi(arm_l, _capsule(0.058, 0.32), skin, Vector3(0.0, -0.46, 0.0))
	_mi(arm_l, _sphere(0.060), skin, Vector3(0.0, -0.64, 0.0), Vector3.ZERO, Vector3(1.0,0.9,1.2))

	# Sağ kol (mızrak tutar)
	var arm_r: Node3D = Node3D.new()
	arm_r.name = "Arm_R"
	arm_r.position = Vector3(0.265, 1.42, 0.0)
	root.add_child(arm_r)
	arm_r.rotation_degrees.x = -28.0  # mızrağı tutar poz
	_mi(arm_r, _capsule(0.072, 0.38), leather, Vector3(0.0, -0.19, 0.0))
	_mi(arm_r, _capsule(0.058, 0.32), skin, Vector3(0.0, -0.46, 0.0))
	_mi(arm_r, _sphere(0.060), skin, Vector3(0.0, -0.64, 0.0), Vector3.ZERO, Vector3(1.0,0.9,1.2))

	# Mızrak (sağ koldan yukarı uzanır)
	var spear: Node3D = Node3D.new()
	spear.name = "SpearArm"
	spear.position = Vector3(0.28, 1.40, 0.02)
	spear.rotation_degrees.x = -15.0
	root.add_child(spear)
	_mi(spear, _cylinder(0.018, 0.022, 1.55), spear_wood, Vector3(0.0, 0.0, 0.0))
	# Çakmaktaşı uç
	_mi(spear, _cylinder(0.012, 0.032, 0.14), flint,
		Vector3(0.0, 0.82, 0.0), Vector3(0.0, 0.0, 0.0))
	# Bağlama kordonu
	_mi(spear, _cylinder(0.025, 0.025, 0.04), leather, Vector3(0.0, 0.70, 0.0))

	return root

# ═══════════════════════════════════════════════════════════════════════════════
# AĞAÇLAR
# ═══════════════════════════════════════════════════════════════════════════════

static func create_pine_tree(height: float = 4.0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "PineTree"

	var trunk_m: StandardMaterial3D  = _mat(Color(0.30, 0.20, 0.12))
	var needle_m: StandardMaterial3D = _mat(Color(0.14, 0.35, 0.18))
	var snow_m: StandardMaterial3D   = _mat(Color(0.92, 0.95, 0.98))

	# Gövde
	_mi(root, _cylinder(0.06, 0.14, height * 0.55), trunk_m,
		Vector3(0.0, height * 0.275, 0.0))

	# 3 katlı üçgen çalı (aşağıdan yukarı küçülür)
	var layer_h: float = height
	for i: int in range(3):
		var ly: float = height * 0.28 + i * height * 0.22
		var lr: float = (0.82 - i * 0.22) * height * 0.28
		var lh: float = height * 0.30 - i * height * 0.04
		_mi(root, _cylinder(0.02, lr, lh), needle_m,
			Vector3(0.0, ly, 0.0))
		# Kar hafif üste
		_mi(root, _cylinder(0.01, lr * 0.75, lh * 0.18), snow_m,
			Vector3(0.0, ly + lh * 0.44, 0.0))
	layer_h = height * 0.92
	# Tepe
	_mi(root, _cylinder(0.01, 0.14, height * 0.18), needle_m,
		Vector3(0.0, layer_h, 0.0))

	return root

static func create_oak_tree(height: float = 5.0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "OakTree"

	var trunk_m: StandardMaterial3D = _mat(Color(0.32, 0.22, 0.14))
	var bark_m: StandardMaterial3D  = _mat(Color(0.26, 0.18, 0.11))
	var leaf_m: StandardMaterial3D  = _mat(Color(0.22, 0.48, 0.18))
	var leaf2_m: StandardMaterial3D = _mat(Color(0.18, 0.42, 0.14))

	# Ana gövde
	_mi(root, _cylinder(0.08, 0.18, height * 0.50), trunk_m,
		Vector3(0.0, height * 0.25, 0.0))
	# Kabuk dokusu (ince üst tabakalar)
	for i: int in range(4):
		var bh: float = height * 0.08 + i * height * 0.10
		_mi(root, _cylinder(0.185 - i * 0.01, 0.185 - i * 0.01, height * 0.03), bark_m,
			Vector3(0.0, bh, 0.0))

	# Dallar (2 yanda)
	for bx: float in [-1.0, 1.0]:
		_mi(root, _cylinder(0.030, 0.055, height * 0.20), trunk_m,
			Vector3(bx * height * 0.14, height * 0.52, 0.0),
			Vector3(0.0, 0.0, bx * 40.0))

	# Yaprak kümesi (çok katlı küre)
	var canopy_positions: Array = [
		[Vector3(0.0,    height * 0.82, 0.0),    height * 0.28],
		[Vector3(-height*0.18, height * 0.72, 0.0), height * 0.20],
		[Vector3( height*0.18, height * 0.72, 0.0), height * 0.20],
		[Vector3(0.0,    height * 0.68, height * 0.16), height * 0.19],
		[Vector3(0.0,    height * 0.68,-height * 0.16), height * 0.18],
		[Vector3(0.0,    height * 0.93, 0.0),    height * 0.18],
	]
	for ci: int in range(canopy_positions.size()):
		var cp: Array = canopy_positions[ci] as Array
		var cm: StandardMaterial3D = leaf_m if ci % 2 == 0 else leaf2_m
		_mi(root, _sphere(float(cp[1])), cm, cp[0] as Vector3)

	return root

static func create_savanna_tree(height: float = 4.5) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "SavannaTree"

	var trunk_m: StandardMaterial3D  = _mat(Color(0.40, 0.28, 0.16))
	var flat_m: StandardMaterial3D   = _mat(Color(0.28, 0.52, 0.18))
	var flat2_m: StandardMaterial3D  = _mat(Color(0.22, 0.44, 0.14))

	# Eğri gövde (akasya gibi)
	_mi(root, _cylinder(0.07, 0.16, height * 0.65), trunk_m,
		Vector3(0.0, height * 0.32, 0.0), Vector3(0.0, 0.0, 3.5))

	# Dal ağı
	for i: int in range(3):
		var ba: float = TAU / 3.0 * i + 0.3
		_mi(root, _cylinder(0.025, 0.048, height * 0.22), trunk_m,
			Vector3(cos(ba) * height * 0.08, height * 0.70, sin(ba) * height * 0.08),
			Vector3(0.0, rad_to_deg(ba), 42.0))

	# Düz tablo tepe (akasya karakteristiği)
	for i2: int in range(2):
		var fy: float = height * 0.76 + i2 * height * 0.08
		var fr: float = height * 0.32 - i2 * height * 0.06
		var m: StandardMaterial3D = flat_m if i2 == 0 else flat2_m
		_mi(root, _cylinder(0.02, fr, height * 0.07 - i2 * height * 0.01), m,
			Vector3(0.0, fy, 0.0))

	return root

static func create_tropical_tree(height: float = 6.0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "TropicalTree"

	var trunk_m: StandardMaterial3D  = _mat(Color(0.28, 0.18, 0.10))
	var leaf_m: StandardMaterial3D   = _mat(Color(0.10, 0.48, 0.15))
	var leaf2_m: StandardMaterial3D  = _mat(Color(0.08, 0.38, 0.12))
	var vine_m: StandardMaterial3D   = _mat(Color(0.18, 0.36, 0.14))

	# Kalın gövde + payanda kökleri
	_mi(root, _cylinder(0.10, 0.22, height * 0.70), trunk_m,
		Vector3(0.0, height * 0.35, 0.0))
	for bi: int in range(4):
		var ba: float = TAU / 4.0 * bi + 0.5
		_mi(root, _cylinder(0.04, 0.09, height * 0.25), trunk_m,
			Vector3(cos(ba) * height * 0.12, height * 0.08, sin(ba) * height * 0.12),
			Vector3(0.0, rad_to_deg(ba), 32.0))

	# Geniş tropikal yaprak kümesi
	var cp_list: Array = [
		[Vector3(0, height*0.88, 0), height*0.30],
		[Vector3(0, height*0.75, 0), height*0.26],
		[Vector3(-height*0.22, height*0.72, height*0.08), height*0.20],
		[Vector3( height*0.22, height*0.72, height*0.08), height*0.20],
		[Vector3(0, height*0.70, -height*0.18), height*0.19],
		[Vector3(0, height*0.98, 0), height*0.15],
	]
	for pi: int in range(cp_list.size()):
		var pd: Array = cp_list[pi] as Array
		var pm: StandardMaterial3D = leaf_m if pi % 2 == 0 else leaf2_m
		_mi(root, _sphere(float(pd[1])), pm, pd[0] as Vector3)

	# Sarmaşıklar
	for vi: int in range(3):
		var vx: float = cos(TAU / 3.0 * vi) * 0.18
		var vz: float = sin(TAU / 3.0 * vi) * 0.18
		_mi(root, _cylinder(0.018, 0.014, height * 0.55), vine_m,
			Vector3(vx, height * 0.30, vz), Vector3(4.0, 0.0, 5.0))

	return root

# ═══════════════════════════════════════════════════════════════════════════════
# KAYA
# ═══════════════════════════════════════════════════════════════════════════════
static func create_rock(size: float = 1.0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Rock"

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(size * 1000.0) % 9999

	var base_c: Color = Color(
		rng.randf_range(0.36, 0.54),
		rng.randf_range(0.33, 0.50),
		rng.randf_range(0.28, 0.44))
	var dark_c: Color = base_c.darkened(0.25)

	var base_m: StandardMaterial3D = _mat(base_c, 0.95)
	var dark_m: StandardMaterial3D = _mat(dark_c, 0.95)

	# Ana kütle
	_mi(root, _sphere(size), base_m,
		Vector3.ZERO, Vector3.ZERO,
		Vector3(rng.randf_range(0.7, 1.3), rng.randf_range(0.5, 0.9), rng.randf_range(0.7, 1.3)))

	# Yan parçalar
	for i: int in range(rng.randi_range(2, 4)):
		var angle: float = TAU / 3.0 * i + rng.randf_range(-0.4, 0.4)
		var dist: float = size * rng.randf_range(0.4, 0.75)
		var sub_size: float = size * rng.randf_range(0.30, 0.60)
		_mi(root, _sphere(sub_size),
			dark_m if i % 2 == 0 else base_m,
			Vector3(cos(angle) * dist, -size * 0.15, sin(angle) * dist),
			Vector3.ZERO,
			Vector3(rng.randf_range(0.8, 1.2), rng.randf_range(0.4, 0.8), rng.randf_range(0.8, 1.2)))

	return root

# ═══════════════════════════════════════════════════════════════════════════════
# BİYOMA GÖRE HAYVAN SEÇİMİ
# ═══════════════════════════════════════════════════════════════════════════════
## Biyom adına göre uygun hayvan model oluşturur.
static func create_animal_for_biome(biome_name: String, rng: RandomNumberGenerator) -> Node3D:
	match biome_name:
		"Savanna":
			if rng.randf() < 0.40:
				return create_lion()
			return create_deer()
		"Steppe":
			if rng.randf() < 0.30:
				return create_wolf()
			return create_deer()
		"Taiga":
			if rng.randf() < 0.25:
				return create_bear(false)
			elif rng.randf() < 0.35:
				return create_wolf()
			return create_deer()
		"Rainforest":
			if rng.randf() < 0.35:
				return create_tiger()
			return create_deer()
		"Tundra":
			if rng.randf() < 0.45:
				return create_bear(true)
			return create_wolf()
		"Temperate Forest":
			if rng.randf() < 0.20:
				return create_wolf()
			return create_deer()
		"Northern Maritime":
			if rng.randf() < 0.30:
				return create_bear(false)
			return create_wolf()
		"Proto-Urban Mediterranean":
			if rng.randf() < 0.15:
				return create_wolf()
			return create_deer()
		_:
			return create_deer()

## Biyoma göre ağaç oluşturur.
static func create_tree_for_biome(biome_name: String, height: float) -> Node3D:
	match biome_name:
		"Taiga", "Tundra": return create_pine_tree(height)
		"Savanna": return create_savanna_tree(height)
		"Rainforest": return create_tropical_tree(height)
		_: return create_oak_tree(height)
