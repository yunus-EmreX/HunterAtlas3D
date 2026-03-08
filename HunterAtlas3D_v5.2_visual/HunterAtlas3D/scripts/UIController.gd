## UIController.gd
## Tüm arayüzü kod içinde inşa eder. Godot 4.6 uyumlu.

class_name UIController
extends CanvasLayer

signal biome_selected(biome_name: String)
signal archetype_selected(archetype_name: String)
signal simulation_requested(days: int)
signal export_requested()

# Widget referansları
var _biome_option: OptionButton       = null
var _archetype_option: OptionButton   = null
var _days_spinbox: SpinBox            = null
var _run_button: Button               = null
var _export_button: Button            = null
var _log_text: RichTextLabel          = null
var _energy_bar: ProgressBar          = null
var _water_bar: ProgressBar           = null
var _fatigue_bar: ProgressBar         = null
var _injury_bar: ProgressBar          = null
var _result_label: Label              = null
var _track_label: Label               = null
var _status_label: Label              = null
var _day_label: Label                 = null

const PANEL_WIDTH: float = 310.0

func _ready() -> void:
	_build_ui()

# ─── UI İnşaası ───────────────────────────────────────────────────────────────
func _build_ui() -> void:
	# Sol panel container
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "SidePanel"

	# Anchor: sol üst köşeye sabitle, genişlik sabitleme offset ile
	panel.set_anchor(SIDE_LEFT,   0.0)
	panel.set_anchor(SIDE_TOP,    0.0)
	panel.set_anchor(SIDE_RIGHT,  0.0)
	panel.set_anchor(SIDE_BOTTOM, 1.0)
	panel.set_offset(SIDE_LEFT,   0.0)
	panel.set_offset(SIDE_RIGHT,  PANEL_WIDTH)
	panel.set_offset(SIDE_TOP,    0.0)
	panel.set_offset(SIDE_BOTTOM, 0.0)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color           = Color(0.07, 0.07, 0.10, 0.95)
	style.border_color       = Color(0.22, 0.30, 0.40)
	style.border_width_right = 1
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	# MarginContainer içinde ScrollContainer + VBox
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_top",    10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	# ── Başlık ────────────────────────────────────────────────────────────────
	var title: Label = Label.new()
	title.text = "🌍  HunterAtlas3D"
	title.add_theme_color_override("font_color", Color(0.92, 0.86, 0.68))
	title.add_theme_font_size_override("font_size", 17)
	vbox.add_child(title)

	var sub: Label = Label.new()
	sub.text = "Antropolojik Hayatta Kalma Simülatörü"
	sub.add_theme_color_override("font_color", Color(0.55, 0.58, 0.65))
	sub.add_theme_font_size_override("font_size", 10)
	vbox.add_child(sub)

	_add_sep(vbox)

	# ── Seçimler ──────────────────────────────────────────────────────────────
	_add_lbl(vbox, "BİYOM")
	_biome_option = OptionButton.new()
	_biome_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_biome_option)
	_biome_option.item_selected.connect(_on_biome_selected)

	_add_lbl(vbox, "AVCIL ARKETİP")
	_archetype_option = OptionButton.new()
	_archetype_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_archetype_option)
	_archetype_option.item_selected.connect(_on_archetype_selected)

	_add_lbl(vbox, "SİMÜLASYON GÜNLERİ")
	_days_spinbox = SpinBox.new()
	_days_spinbox.min_value = 1
	_days_spinbox.max_value = 30
	_days_spinbox.value     = 7
	_days_spinbox.step      = 1
	_days_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_days_spinbox)

	_add_sep(vbox)

	# ── Çalıştır ──────────────────────────────────────────────────────────────
	_run_button = Button.new()
	_run_button.text = "▶  SİMÜLASYONU BAŞLAT"
	_run_button.add_theme_color_override("font_color", Color(0.22, 0.90, 0.55))
	vbox.add_child(_run_button)
	_run_button.pressed.connect(_on_run_pressed)

	_add_sep(vbox)

	# ── Durum ─────────────────────────────────────────────────────────────────
	_status_label = Label.new()
	_status_label.text = "Hazır."
	_status_label.add_theme_color_override("font_color", Color(0.65, 0.68, 0.75))
	_status_label.add_theme_font_size_override("font_size", 10)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_status_label)

	_day_label = Label.new()
	_day_label.text = "Gün —"
	_day_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(_day_label)

	_add_sep(vbox)

	# ── Vitaller ──────────────────────────────────────────────────────────────
	_add_lbl(vbox, "CAN GÖSTERGELERİ")
	_energy_bar  = _add_bar(vbox, "Enerji",    Color(0.28, 0.82, 0.42))
	_water_bar   = _add_bar(vbox, "Su",        Color(0.22, 0.55, 0.92))
	_fatigue_bar = _add_bar(vbox, "Yorgunluk", Color(0.88, 0.65, 0.18))
	_injury_bar  = _add_bar(vbox, "Yaralanma", Color(0.92, 0.22, 0.22))

	_add_sep(vbox)

	# ── İz Takibi ─────────────────────────────────────────────────────────────
	_add_lbl(vbox, "İZ TAKİBİ")
	_track_label = Label.new()
	_track_label.text = "İz yoğunluğu: —"
	_track_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(_track_label)

	_add_sep(vbox)

	# ── Sonuç ─────────────────────────────────────────────────────────────────
	_result_label = Label.new()
	_result_label.text = "Hayatta Kalma Oranı: —"
	_result_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.52))
	_result_label.add_theme_font_size_override("font_size", 13)
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_result_label)

	_add_sep(vbox)

	# ── Log ───────────────────────────────────────────────────────────────────
	_add_lbl(vbox, "OLAY KAYDI")
	_log_text = RichTextLabel.new()
	_log_text.custom_minimum_size = Vector2(0, 160)
	_log_text.scroll_following    = true
	_log_text.bbcode_enabled      = true
	_log_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_text.add_theme_font_size_override("normal_font_size", 9)
	vbox.add_child(_log_text)

	_add_sep(vbox)

	# ── Export ────────────────────────────────────────────────────────────────
	_export_button = Button.new()
	_export_button.text     = "💾  CSV Dışa Aktar"
	_export_button.disabled = true
	vbox.add_child(_export_button)
	_export_button.pressed.connect(_on_export_pressed)

# ─── Doldurma ─────────────────────────────────────────────────────────────────
func populate_biomes(names: Array) -> void:
	if _biome_option == null:
		return
	_biome_option.clear()
	for n: Variant in names:
		_biome_option.add_item(str(n))

func populate_archetypes(names: Array) -> void:
	if _archetype_option == null:
		return
	_archetype_option.clear()
	for n: Variant in names:
		_archetype_option.add_item(str(n))

# ─── Canlı Güncelleme ─────────────────────────────────────────────────────────
func update_vitals(energy: float, water: float, fatigue: float, injury: float) -> void:
	if _energy_bar:  _energy_bar.value  = energy
	if _water_bar:   _water_bar.value   = water
	if _fatigue_bar: _fatigue_bar.value = fatigue
	if _injury_bar:  _injury_bar.value  = injury

func update_day(day: int, hour: int) -> void:
	if _day_label:
		_day_label.text = "Gün %d — Saat %02d:00" % [day + 1, hour % 24]

func update_tracking(modifier: float, count: int) -> void:
	if _track_label:
		_track_label.text = "İz yoğunluğu: %.0f%%  (%d aktif)" % [modifier * 100.0, count]

func append_log(msg: String) -> void:
	if _log_text == null:
		return
	var color: String = "[color=#999999]"
	if "ÖLÜM" in msg or "DEATH" in msg:
		color = "[color=#ff4444]"
	elif "BAŞARILI" in msg or "SUCCESS" in msg:
		color = "[color=#44ff88]"
	elif "başarısız" in msg or "FAILED" in msg:
		color = "[color=#ffaa44]"
	elif "YIRTICI" in msg or "HASTALIK" in msg or "MARUZ" in msg:
		color = "[color=#ff8888]"
	_log_text.append_text("%s%s[/color]\n" % [color, msg])

func set_status(msg: String) -> void:
	if _status_label:
		_status_label.text = msg

func show_result(result: Dictionary) -> void:
	if _result_label == null:
		return
	var survived: bool = bool(result.get("survived", false))
	var prob: float    = float(result.get("survival_probability", 0.0))
	var energy: float  = float(result.get("final_energy", 0.0))
	var water: float   = float(result.get("final_water", 0.0))
	var outcome: String = "HAYATTA KALDI ✓" if survived else "ÖLDÜ ✗"
	_result_label.text = "%s\nHayatta Kalma: %.1f%%\nEnerji: %.1f | Su: %.1f" % [
		outcome, prob * 100.0, energy, water]
	_result_label.add_theme_color_override(
		"font_color",
		Color(0.28, 0.90, 0.45) if survived else Color(0.92, 0.28, 0.28))
	if _export_button: _export_button.disabled = false
	if _run_button:    _run_button.disabled    = false

func set_run_button_enabled(enabled: bool) -> void:
	if _run_button:
		_run_button.disabled = not enabled

func get_selected_biome() -> String:
	if _biome_option == null or _biome_option.item_count == 0:
		return ""
	return _biome_option.get_item_text(_biome_option.selected)

func get_selected_archetype() -> String:
	if _archetype_option == null or _archetype_option.item_count == 0:
		return "Generalist"
	return _archetype_option.get_item_text(_archetype_option.selected)

# ─── Olay İşleyiciler ─────────────────────────────────────────────────────────
func _on_biome_selected(index: int) -> void:
	if _biome_option == null: return
	biome_selected.emit(_biome_option.get_item_text(index))

func _on_archetype_selected(index: int) -> void:
	if _archetype_option == null: return
	archetype_selected.emit(_archetype_option.get_item_text(index))

func _on_run_pressed() -> void:
	var days: int = int(_days_spinbox.value) if _days_spinbox != null else 7
	simulation_requested.emit(days)
	if _run_button:    _run_button.disabled    = true
	if _export_button: _export_button.disabled = true
	if _log_text:      _log_text.clear()
	set_status("Simülasyon çalışıyor...")

func _on_export_pressed() -> void:
	export_requested.emit()

# ─── Yardımcı Widget Fabrika ──────────────────────────────────────────────────
func _add_lbl(parent: Control, text: String) -> void:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color(0.50, 0.75, 0.92))
	l.add_theme_font_size_override("font_size", 9)
	parent.add_child(l)

func _add_sep(parent: Control) -> void:
	parent.add_child(HSeparator.new())

func _add_bar(parent: Control, label_text: String, fill: Color) -> ProgressBar:
	var hb: HBoxContainer = HBoxContainer.new()
	parent.add_child(hb)

	var lbl: Label = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 60
	lbl.add_theme_font_size_override("font_size", 9)
	hb.add_child(lbl)

	var bar: ProgressBar = ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value     = 100.0
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.show_percentage = false

	var fill_style: StyleBoxFlat = StyleBoxFlat.new()
	fill_style.bg_color = fill
	bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.13, 0.13, 0.17)
	bar.add_theme_stylebox_override("background", bg_style)

	hb.add_child(bar)
	return bar
