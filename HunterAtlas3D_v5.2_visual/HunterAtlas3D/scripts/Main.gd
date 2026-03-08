## Main.gd
## HunterAtlas3D orkestrasyonu.
## HunterCharacter oyuncu kontrolü — otomatik kamera yok.

extends Node

var _biome_mgr: BiomeManager         = null
var _sim_engine: SimulationEngine    = null
var _env_spawner: EnvironmentSpawner = null
var _tracking: TrackingSystem        = null
var _ui: UIController                = null
var _hunter: HunterCharacter         = null
var _world: Node3D                   = null

var _selected_biome: String    = ""
var _selected_archetype: String = "Generalist"
var _last_result: Dictionary   = {}

func _ready() -> void:
	_build_world()
	_build_systems()
	_wire_signals()
	_populate_ui()
	print("HunterAtlas3D v1.2 — Godot 4.6")

func _process(_delta: float) -> void:
	# Oyuncunun yakınındaki hayvanları uyar
	if _hunter != null and is_instance_valid(_hunter):
		_env_spawner.alert_animals_near(
			_hunter.global_position, 7.0, _hunter)

# ─── İnşaat ───────────────────────────────────────────────────────────────────
func _build_world() -> void:
	_world = Node3D.new()
	_world.name = "WorldRoot"
	add_child(_world)

func _build_systems() -> void:
	_biome_mgr = BiomeManager.new()
	_biome_mgr.name = "BiomeManager"
	add_child(_biome_mgr)

	_sim_engine = SimulationEngine.new()
	_sim_engine.name = "SimulationEngine"
	add_child(_sim_engine)
	_sim_engine.setup(_biome_mgr)

	_env_spawner = EnvironmentSpawner.new()
	_env_spawner.name = "EnvironmentSpawner"
	add_child(_env_spawner)
	_env_spawner.setup(_world, _biome_mgr)

	_tracking = TrackingSystem.new()
	_tracking.name = "TrackingSystem"
	add_child(_tracking)

	_ui = UIController.new()
	_ui.name  = "UIController"
	_ui.layer = 10
	add_child(_ui)

func _wire_signals() -> void:
	_ui.biome_selected.connect(_on_biome_selected)
	_ui.archetype_selected.connect(_on_archetype_selected)
	_ui.simulation_requested.connect(_on_simulation_requested)
	_ui.export_requested.connect(_on_export_requested)

	_sim_engine.log_event.connect(_ui.append_log)
	_sim_engine.step_processed.connect(_on_step_processed)
	_sim_engine.simulation_complete.connect(_on_simulation_complete)

	_biome_mgr.biomes_loaded.connect(_on_biomes_loaded)
	_tracking.tracking_skill_updated.connect(_on_tracking_updated)

func _populate_ui() -> void:
	if _biome_mgr.is_loaded():
		_ui.populate_biomes(_biome_mgr.get_biome_names())
		_load_first_biome()
	_ui.populate_archetypes(_sim_engine.get_archetype_names())

func _load_first_biome() -> void:
	var names: Array = _biome_mgr.get_biome_names()
	if names.is_empty(): return
	_selected_biome = str(names[0])
	_do_spawn_biome(_selected_biome)

# ─── Biyom Sahne Yönetimi ─────────────────────────────────────────────────────
func _do_spawn_biome(biome_name: String) -> void:
	# Önce avcı karakterini temizle
	if _hunter != null and is_instance_valid(_hunter):
		_hunter.queue_free()
		_hunter = null

	_tracking.deactivate()
	_env_spawner.spawn_biome(biome_name)
	_tracking.setup(_world, biome_name)

	# Avcı karakterini merkeze spawn et
	_spawn_hunter()

# ─── Avcı Karakteri ───────────────────────────────────────────────────────────
func _spawn_hunter() -> void:
	_hunter = HunterCharacter.new()
	_hunter.name = "HunterCharacter"
	# Merkeze spawn, yeterince yüksek ki arazi var olsun
	_hunter.position = Vector3(0.0, 5.0, 0.0)
	_world.add_child(_hunter)

# ─── Olay İşleyiciler ─────────────────────────────────────────────────────────
func _on_biomes_loaded(biome_names: Array) -> void:
	_ui.populate_biomes(biome_names)
	_load_first_biome()

func _on_biome_selected(biome_name: String) -> void:
	_selected_biome = biome_name
	_do_spawn_biome(biome_name)
	_ui.set_status("Biyom: %s" % biome_name)

func _on_archetype_selected(archetype_name: String) -> void:
	_selected_archetype = archetype_name

func _on_simulation_requested(days: int) -> void:
	if _selected_biome.is_empty():
		_ui.set_status("Önce biyom seçin.")
		_ui.set_run_button_enabled(true)
		return
	_sim_engine.configure(_selected_biome, _selected_archetype, days)
	_ui.set_status("Simülasyon: %s | %s | %d gün" % [_selected_biome, _selected_archetype, days])
	await get_tree().process_frame
	_last_result = _sim_engine.run()

func _on_step_processed(step: int, state: Dictionary) -> void:
	_ui.update_vitals(
		float(state.get("energy", 0.0)), float(state.get("water", 0.0)),
		float(state.get("fatigue", 0.0)), float(state.get("injury", 0.0)))
	_ui.update_day(int(state.get("day", 0)), step)

func _on_simulation_complete(result: Dictionary) -> void:
	_last_result = result
	_ui.show_result(result)
	var survived: bool = bool(result.get("survived", false))
	_ui.set_status("Tamamlandı — %s" % ("HAYATTA KALDI" if survived else "ÖLDÜ"))
	_ui.set_run_button_enabled(true)

func _on_tracking_updated(modifier: float) -> void:
	_ui.update_tracking(modifier, _tracking.get_active_track_count())

func _on_export_requested() -> void:
	if _last_result.is_empty():
		_ui.set_status("Dışa aktarılacak sonuç yok.")
		return
	var path: String = CSVExporter.export_result(_last_result)
	_ui.set_status("Dışa aktarıldı: %s" % path)
