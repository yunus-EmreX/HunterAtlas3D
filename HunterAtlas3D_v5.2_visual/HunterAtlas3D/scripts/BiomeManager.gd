## BiomeManager.gd
## Biome JSON verilerini yükler ve sorgular.

class_name BiomeManager
extends Node

signal biomes_loaded(biome_names: Array)

const BIOME_DATA_PATH: String = "res://data/biomes.json"

var _biomes: Dictionary = {}
var _loaded: bool = false

func _ready() -> void:
	load_biomes()

func load_biomes() -> void:
	if _loaded:
		return

	if not FileAccess.file_exists(BIOME_DATA_PATH):
		push_error("BiomeManager: Dosya bulunamadı: %s" % BIOME_DATA_PATH)
		return

	var file: FileAccess = FileAccess.open(BIOME_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("BiomeManager: Açılamadı: %s" % BIOME_DATA_PATH)
		return

	var raw: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_error("BiomeManager: JSON parse hatası.")
		return

	var data: Dictionary = parsed as Dictionary
	if not data.has("biomes"):
		push_error("BiomeManager: 'biomes' anahtarı bulunamadı.")
		return

	var biome_list: Array = data["biomes"] as Array
	for entry: Variant in biome_list:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var b: Dictionary = entry as Dictionary
		var name_key: String = str(b.get("name", "Bilinmiyor"))
		_biomes[name_key] = b

	_loaded = true
	print("BiomeManager: %d biome yüklendi." % _biomes.size())
	biomes_loaded.emit(get_biome_names())

func get_biome_names() -> Array:
	return _biomes.keys()

func get_biome(biome_name: String) -> Dictionary:
	if _biomes.has(biome_name):
		return _biomes[biome_name] as Dictionary
	return {}

func get_float(biome_name: String, param: String, default_val: float = 0.0) -> float:
	var biome: Dictionary = get_biome(biome_name)
	if biome.has(param):
		return float(biome[param])
	return default_val

func get_string(biome_name: String, param: String, default_val: String = "") -> String:
	var biome: Dictionary = get_biome(biome_name)
	if biome.has(param):
		return str(biome[param])
	return default_val

func is_loaded() -> bool:
	return _loaded
