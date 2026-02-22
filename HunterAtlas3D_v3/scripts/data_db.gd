extends Node
class_name DataDB

var biomes: Dictionary = {}
var hunters: Dictionary = {}

func load_all() -> void:
    biomes = _load_dir_json("res://data/biomes")
    hunters = _load_dir_json("res://data/hunters")

func _load_dir_json(dir_path: String) -> Dictionary:
    var out: Dictionary = {}

    var dir: DirAccess = DirAccess.open(dir_path)
    if dir == null:
        push_error("Dir not found: " + dir_path)
        return out

    dir.list_dir_begin()
    while true:
        var f: String = dir.get_next()
        if f == "":
            break
        if dir.current_is_dir():
            continue
        if not f.ends_with(".json"):
            continue

        var full: String = dir_path + "/" + f
        if not FileAccess.file_exists(full):
            push_error("File missing: " + full)
            continue

        var content: String = FileAccess.get_file_as_string(full)
        var parsed_any: Variant = JSON.parse_string(content)
        if typeof(parsed_any) != TYPE_DICTIONARY:
            push_error("Invalid JSON: " + full)
            continue

        var parsed: Dictionary = parsed_any
        if not parsed.has("id"):
            push_error("Missing id in: " + full)
            continue

        out[str(parsed["id"])] = parsed

    dir.list_dir_end()
    return out
