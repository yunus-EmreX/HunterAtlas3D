## SimulationEngine.gd
## Saatlik zaman adımlarında hayatta kalma simülasyonu.

class_name SimulationEngine
extends Node

signal step_processed(step: int, state: Dictionary)
signal simulation_complete(result: Dictionary)
signal log_event(message: String)

const MAX_ENERGY: float    = 100.0
const MAX_WATER: float     = 100.0
const MAX_FATIGUE: float   = 100.0
const CRITICAL_ENERGY: float = 10.0
const CRITICAL_WATER: float  = 5.0

const ARCHETYPES: Dictionary = {
	"Generalist": {
		"base_metabolism": 2.0,
		"tracking_skill": 0.55,
		"habitat_familiarity": 0.50,
		"injury_resistance": 0.50,
		"adaptation_modifier": 0.40,
	},
	"Bozkır Göçebesi": {
		"base_metabolism": 1.8,
		"tracking_skill": 0.75,
		"habitat_familiarity": 0.85,
		"injury_resistance": 0.60,
		"adaptation_modifier": 0.65,
	},
	"Orman Avcısı": {
		"base_metabolism": 1.9,
		"tracking_skill": 0.80,
		"habitat_familiarity": 0.80,
		"injury_resistance": 0.55,
		"adaptation_modifier": 0.60,
	},
	"Tundra Hayatta Kalan": {
		"base_metabolism": 2.2,
		"tracking_skill": 0.65,
		"habitat_familiarity": 0.75,
		"injury_resistance": 0.70,
		"adaptation_modifier": 0.70,
	},
	"Tropik Toplayıcı": {
		"base_metabolism": 1.7,
		"tracking_skill": 0.60,
		"habitat_familiarity": 0.70,
		"injury_resistance": 0.50,
		"adaptation_modifier": 0.55,
	},
}

var _biome_manager: BiomeManager = null
var _current_biome: String = ""
var _current_archetype: String = "Generalist"
var _simulation_days: int = 7

var _energy: float = MAX_ENERGY
var _water: float  = MAX_WATER
var _fatigue: float = 0.0
var _injury: float  = 0.0
var _alive: bool    = true

var _event_log: Array    = []
var _step_results: Array = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func setup(biome_manager: BiomeManager) -> void:
	_biome_manager = biome_manager

func configure(biome_name: String, archetype: String, days: int) -> void:
	_current_biome     = biome_name
	_current_archetype = archetype
	_simulation_days   = days

func run() -> Dictionary:
	if _biome_manager == null:
		push_error("SimulationEngine: BiomeManager atanmamış.")
		return {}

	_reset_state()
	_rng.randomize()

	var biome: Dictionary    = _biome_manager.get_biome(_current_biome)
	var archetype: Dictionary = _get_archetype(_current_archetype)
	var total_hours: int      = _simulation_days * 24

	_log("=== Simülasyon: %s | %s | %d gün ===" % [_current_biome, _current_archetype, _simulation_days])

	for hour: int in range(total_hours):
		if not _alive:
			break
		_process_hour(hour, biome, archetype)
		var state: Dictionary = _capture_state(hour)
		_step_results.append(state)
		step_processed.emit(hour, state)

	var result: Dictionary = _build_result()
	simulation_complete.emit(result)
	return result

func _process_hour(hour: int, biome: Dictionary, archetype: Dictionary) -> void:
	var day: int = hour / 24
	var h: int   = hour % 24
	var is_night: bool = (h < 6 or h >= 22)

	# ─── Enerji ───────────────────────────────────────────────────────────────
	var base_met: float    = float(archetype.get("base_metabolism", 2.0))
	var terrain_dif: float = float(biome.get("terrain_difficulty", 1.0)) * 0.8
	var climate_str: float = float(biome.get("climate_stress", 0.5))
	var adapt_mod: float   = float(archetype.get("adaptation_modifier", 0.4))

	var energy_cost: float = base_met + terrain_dif + climate_str - adapt_mod
	energy_cost = clampf(energy_cost, 0.5, 8.0)
	if is_night:
		energy_cost *= 0.3
	_energy -= energy_cost

	# ─── Su Kaybı ─────────────────────────────────────────────────────────────
	var activity: float   = 0.3 if is_night else 1.0
	var temp_norm: float  = float(biome.get("temperature", 15.0)) / 40.0
	var wind: float       = float(biome.get("wind_exposure", 0.5))
	var humidity: float   = float(biome.get("humidity", 0.5))
	var hum_grad: float   = 1.0 - humidity

	var water_loss: float = activity * (0.5 + temp_norm) * (0.5 + wind * 0.5) * (0.5 + hum_grad * 0.5)
	water_loss = clampf(water_loss, 0.05, 4.0)
	_water -= water_loss

	# ─── Av ───────────────────────────────────────────────────────────────────
	var is_hunt_hour: bool = (h >= 7 and h <= 10) or (h >= 16 and h <= 19)
	if is_hunt_hour and _rng.randf() < 0.45:
		_attempt_hunt(biome, archetype, day, h)

	# ─── Su Arama ─────────────────────────────────────────────────────────────
	if _water < 35.0 and not is_night and _rng.randf() < 0.35:
		_attempt_water_foraging(biome, day, h)

	# ─── Yorgunluk ────────────────────────────────────────────────────────────
	_fatigue += energy_cost * 0.15
	if is_night:
		_fatigue -= 1.8
	_fatigue = clampf(_fatigue, 0.0, MAX_FATIGUE)

	# ─── Tehlikeler ───────────────────────────────────────────────────────────
	_evaluate_hazards(biome, archetype, day, h)

	# ─── Kritik Durum ─────────────────────────────────────────────────────────
	if _energy <= CRITICAL_ENERGY:
		_injury += 0.5
		if hour % 6 == 0:
			_log("[G%d S%02d] Kritik enerji — açlık riski." % [day + 1, h])
	if _water <= CRITICAL_WATER:
		_injury += 1.0
		if hour % 3 == 0:
			_log("[G%d S%02d] Şiddetli dehidrasyon." % [day + 1, h])

	# ─── Ölüm Kontrolü ────────────────────────────────────────────────────────
	if _energy <= 0.0:
		_alive = false
		_log("[G%d S%02d] *** ÖLÜM: Enerji tükendi — açlık. ***" % [day + 1, h])
	elif _water <= 0.0:
		_alive = false
		_log("[G%d S%02d] *** ÖLÜM: Su tükendi — susuzluk. ***" % [day + 1, h])
	elif _injury >= 100.0:
		_alive = false
		_log("[G%d S%02d] *** ÖLÜM: Birikimli yaralanmalar. ***" % [day + 1, h])

	_energy = clampf(_energy, 0.0, MAX_ENERGY)
	_water  = clampf(_water,  0.0, MAX_WATER)

func _attempt_hunt(biome: Dictionary, archetype: Dictionary, day: int, h: int) -> void:
	var tracking: float   = float(archetype.get("tracking_skill", 0.5))
	var game_den: float   = float(biome.get("game_density", 0.5))
	var famil: float      = float(archetype.get("habitat_familiarity", 0.5))
	var prob: float       = clampf(tracking * game_den * famil, 0.0, 1.0)

	if _rng.randf() < prob:
		var gain: float = _rng.randf_range(15.0, 35.0)
		_energy = minf(_energy + gain, MAX_ENERGY)
		_log("[G%d S%02d] AV BAŞARILI +%.1f enerji (p=%.2f)" % [day + 1, h, gain, prob])
	else:
		var cost: float = _rng.randf_range(2.0, 5.0)
		_energy -= cost
		_log("[G%d S%02d] Av başarısız −%.1f enerji (p=%.2f)" % [day + 1, h, cost, prob])

func _attempt_water_foraging(biome: Dictionary, day: int, h: int) -> void:
	var avail: float = float(biome.get("water_availability", 0.5))
	if _rng.randf() < avail:
		var gain: float = _rng.randf_range(10.0, 25.0)
		_water = minf(_water + gain, MAX_WATER)
		_log("[G%d S%02d] Su bulundu +%.1f hidrasyon." % [day + 1, h, gain])

func _evaluate_hazards(biome: Dictionary, archetype: Dictionary, day: int, h: int) -> void:
	var predator: float = float(biome.get("predator_pressure", 0.1))
	var disease: float  = float(biome.get("disease_risk", 0.05))
	var exposure: float = float(biome.get("exposure_risk", 0.1))
	var resist: float   = float(archetype.get("injury_resistance", 0.5))

	if _rng.randf() < predator * 0.05:
		var dmg: float = _rng.randf_range(5.0, 20.0) * (1.0 - resist)
		_injury += dmg
		_log("[G%d S%02d] YIRTICI SALDIRISI — yaralanma +%.1f" % [day + 1, h, dmg])

	if _rng.randf() < disease * 0.02:
		var dmg: float = _rng.randf_range(2.0, 8.0)
		_energy -= dmg
		_injury += dmg * 0.5
		_log("[G%d S%02d] HASTALIK — enerji −%.1f" % [day + 1, h, dmg])

	if _rng.randf() < exposure * 0.03:
		var dmg: float = _rng.randf_range(1.0, 6.0) * (1.0 - resist * 0.5)
		_injury += dmg
		_log("[G%d S%02d] MARUZ KALMA — yaralanma +%.1f" % [day + 1, h, dmg])

func _get_archetype(name: String) -> Dictionary:
	if ARCHETYPES.has(name):
		return ARCHETYPES[name] as Dictionary
	return ARCHETYPES["Generalist"] as Dictionary

func _reset_state() -> void:
	_energy = MAX_ENERGY
	_water  = MAX_WATER
	_fatigue = 0.0
	_injury  = 0.0
	_alive   = true
	_event_log.clear()
	_step_results.clear()

func _capture_state(hour: int) -> Dictionary:
	return {
		"hour": hour, "day": hour / 24,
		"energy": _energy, "water": _water,
		"fatigue": _fatigue, "injury": _injury,
		"alive": _alive,
	}

func _log(msg: String) -> void:
	_event_log.append(msg)
	log_event.emit(msg)

func _build_result() -> Dictionary:
	var mortality: float = 0.0
	if not _alive:
		mortality = 1.0
	else:
		mortality = (_injury / 100.0 + (1.0 - _energy / MAX_ENERGY) * 0.3 + (1.0 - _water / MAX_WATER) * 0.3) / 3.0
	var survival_prob: float = clampf(1.0 - mortality, 0.0, 1.0)
	return {
		"survived": _alive,
		"survival_probability": survival_prob,
		"final_energy": _energy,
		"final_water": _water,
		"final_fatigue": _fatigue,
		"final_injury": _injury,
		"biome": _current_biome,
		"archetype": _current_archetype,
		"days_simulated": _simulation_days,
		"event_log": _event_log.duplicate(),
		"step_results": _step_results.duplicate(),
	}

func get_archetype_names() -> Array:
	return ARCHETYPES.keys()
