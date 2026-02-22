extends Node

var db: DataDB
var sim: SimEngine

@onready var world: World = $World
@onready var hud: Control = $HUD

func _ready() -> void:
    db = DataDB.new()
    sim = SimEngine.new()
    add_child(db)
    add_child(sim)
    db.load_all()

    hud.call("init", db, sim)

    world.biome_selected.connect(_on_biome_selected)

    var b0_any: Variant = db.biomes.get("steppe", {})
    if typeof(b0_any) == TYPE_DICTIONARY:
        world.apply_biome_visual(b0_any)

func _on_biome_selected(biome_id: String) -> void:
    hud.call("set_selected_biome", biome_id)
    var b_any: Variant = db.biomes.get(biome_id, {})
    if typeof(b_any) == TYPE_DICTIONARY:
        world.apply_biome_visual(b_any)
