extends Control

@onready var biome_label: Label = %BiomeLabel
@onready var hunter_picker: OptionButton = %HunterPicker
@onready var hunter_label: Label = %HunterLabel
@onready var seed_spin: SpinBox = %SeedSpin
@onready var hours_spin: SpinBox = %HoursSpin
@onready var activity_slider: HSlider = %ActivitySlider
@onready var activity_label: Label = %ActivityLabel
@onready var run_button: Button = %RunButton
@onready var log_box: RichTextLabel = %LogBox
@onready var biome_info: RichTextLabel = %BiomeInfo

var db: Object
var sim: Object

var selected_biome_id: String = "steppe"
var selected_hunter_id: String = "steppe_hunter"

func init(_db: Object, _sim: Object) -> void:
    db = _db
    sim = _sim
    _populate_hunters()
    _refresh()

func _ready() -> void:
    run_button.pressed.connect(_on_run)
    hunter_picker.item_selected.connect(_on_hunter_selected)
    activity_slider.value_changed.connect(_on_activity_changed)
    _on_activity_changed(activity_slider.value)

func _populate_hunters() -> void:
    hunter_picker.clear()

    var hunters_dict: Dictionary = db.get("hunters")
    var ids: Array = hunters_dict.keys()
    ids.sort()

    for i in range(ids.size()):
        var id: String = str(ids[i])
        var hunter_any: Variant = hunters_dict.get(id, {})
        var hunter_dict: Dictionary = hunter_any if typeof(hunter_any) == TYPE_DICTIONARY else {}
        var display_name: String = str(hunter_dict.get("name", id))

        hunter_picker.add_item(display_name)
        hunter_picker.set_item_metadata(hunter_picker.item_count - 1, id)

    for idx in range(hunter_picker.item_count):
        if str(hunter_picker.get_item_metadata(idx)) == selected_hunter_id:
            hunter_picker.select(idx)
            break

func _on_hunter_selected(index: int) -> void:
    selected_hunter_id = str(hunter_picker.get_item_metadata(index))
    _refresh()

func set_selected_biome(biome_id: String) -> void:
    var biomes_dict: Dictionary = db.get("biomes")
    if not biomes_dict.has(biome_id):
        return
    selected_biome_id = biome_id
    _refresh()

func _refresh() -> void:
    var biomes_dict: Dictionary = db.get("biomes")
    var hunters_dict: Dictionary = db.get("hunters")

    var b_any: Variant = biomes_dict.get(selected_biome_id, {})
    var h_any: Variant = hunters_dict.get(selected_hunter_id, {})

    var b: Dictionary = b_any if typeof(b_any) == TYPE_DICTIONARY else {}
    var h: Dictionary = h_any if typeof(h_any) == TYPE_DICTIONARY else {}

    biome_label.text = "Biyom: " + str(b.get("name", "?"))
    hunter_label.text = "Avcı: " + str(h.get("name", "?"))

    var summary: String = str(b.get("summary", ""))
    var animals_line: String = _format_animals(b)
    biome_info.text = summary + "\n\nAv Hayvanları:\n" + animals_line

func _format_animals(b: Dictionary) -> String:
    var out: String = ""
    var animals_any: Variant = b.get("animals", [])
    if typeof(animals_any) != TYPE_ARRAY:
        return "-"

    var animals: Array = animals_any
    for i in range(animals.size()):
        var a_any: Variant = animals[i]
        if typeof(a_any) == TYPE_DICTIONARY:
            var a: Dictionary = a_any
            out += "• " + str(a.get("name","Hayvan")) + " (zorluk " + str(a.get("difficulty", 0.5)) + ")\n"
        else:
            out += "• " + str(a_any) + "\n"
    if out == "":
        out = "-"
    return out

func _on_activity_changed(v: float) -> void:
    activity_label.text = "Aktivite: %.0f%%" % (v * 100.0)

func _on_run() -> void:
    log_box.clear()

    var biomes_dict: Dictionary = db.get("biomes")
    var hunters_dict: Dictionary = db.get("hunters")

    var b_any: Variant = biomes_dict.get(selected_biome_id, {})
    var h_any: Variant = hunters_dict.get(selected_hunter_id, {})

    var b: Dictionary = b_any if typeof(b_any) == TYPE_DICTIONARY else {}
    var h: Dictionary = h_any if typeof(h_any) == TYPE_DICTIONARY else {}

    var scenario: Dictionary = {
        "start_calories": 1700.0,
        "start_water": 1.6,
        "activity": float(activity_slider.value)
    }

    var hours: int = int(hours_spin.value)
    var seed: int = int(seed_spin.value)

    var result_any: Variant = sim.call("run_sim", b, h, hours, seed, scenario)
    if typeof(result_any) != TYPE_DICTIONARY:
        log_box.append_text("Sim çalıştırılamadı (geçersiz sonuç).\n")
        return

    var result: Dictionary = result_any
    var state_any: Variant = result.get("state", {})
    var state: Dictionary = state_any if typeof(state_any) == TYPE_DICTIONARY else {}

    var alive: bool = bool(state.get("alive", false))
    var final_cal: float = float(state.get("calories", 0.0))
    var final_water: float = float(state.get("water", 0.0))

    log_box.append_text("Sim (%ds) bitti.\n" % hours)
    log_box.append_text("Hayatta: %s\n" % ("EVET" if alive else "HAYIR"))
    log_box.append_text("Kalan kalori: %.0f\n" % final_cal)
    log_box.append_text("Kalan su(L): %.2f\n\n" % final_water)

    var events_any: Variant = result.get("events", [])
    var events: Array = events_any if typeof(events_any) == TYPE_ARRAY else []

    if events.is_empty():
        log_box.append_text("(Olay yok)\n")
    else:
        for i in range(events.size()):
            var e_any: Variant = events[i]
            var e: Dictionary = e_any if typeof(e_any) == TYPE_DICTIONARY else {}
            log_box.append_text("[saat %d] %s\n" % [int(e.get("hour", 0)), str(e.get("text", ""))])
