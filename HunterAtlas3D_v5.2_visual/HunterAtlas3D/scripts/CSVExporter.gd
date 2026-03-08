## CSVExporter.gd
## Simülasyon sonuçlarını CSV olarak kullanıcı dizinine yazar.

class_name CSVExporter
extends RefCounted

static func export_result(result: Dictionary) -> String:
	var ts: String = _timestamp()

	# Özet
	var spath: String = "user://hunter_atlas_ozet_%s.csv" % ts
	var sf: FileAccess = FileAccess.open(spath, FileAccess.WRITE)
	if sf != null:
		sf.store_line("alan,deger")
		sf.store_line("biom,%s"               % str(result.get("biome", "")))
		sf.store_line("arketip,%s"            % str(result.get("archetype", "")))
		sf.store_line("simulasyon_gunu,%d"    % int(result.get("days_simulated", 0)))
		sf.store_line("hayatta_kaldi,%s"      % ("evet" if bool(result.get("survived", false)) else "hayir"))
		sf.store_line("hayatta_kalma_orani,%.4f" % float(result.get("survival_probability", 0.0)))
		sf.store_line("son_enerji,%.2f"       % float(result.get("final_energy", 0.0)))
		sf.store_line("son_su,%.2f"           % float(result.get("final_water", 0.0)))
		sf.store_line("son_yorgunluk,%.2f"    % float(result.get("final_fatigue", 0.0)))
		sf.store_line("son_yaralanma,%.2f"    % float(result.get("final_injury", 0.0)))
		sf.close()

	# Saatlik adımlar
	var step_path: String = "user://hunter_atlas_adimlar_%s.csv" % ts
	var stf: FileAccess = FileAccess.open(step_path, FileAccess.WRITE)
	if stf != null:
		stf.store_line("saat,gun,enerji,su,yorgunluk,yaralanma,canli")
		var steps: Array = result.get("step_results", []) as Array
		for s: Variant in steps:
			var d: Dictionary = s as Dictionary
			stf.store_line("%d,%d,%.2f,%.2f,%.2f,%.2f,%s" % [
				int(d.get("hour", 0)), int(d.get("day", 0)),
				float(d.get("energy", 0.0)), float(d.get("water", 0.0)),
				float(d.get("fatigue", 0.0)), float(d.get("injury", 0.0)),
				"evet" if bool(d.get("alive", false)) else "hayir",
			])
		stf.close()

	# Olay kaydı
	var log_path: String = "user://hunter_atlas_log_%s.csv" % ts
	var lf: FileAccess = FileAccess.open(log_path, FileAccess.WRITE)
	if lf != null:
		lf.store_line("no,olay")
		var events: Array = result.get("event_log", []) as Array
		for i: int in range(events.size()):
			var entry: String = str(events[i]).replace(",", ";")
			lf.store_line("%d,%s" % [i, entry])
		lf.close()

	print("CSVExporter: Dışa aktarıldı → user:// [%s]" % ts)
	return spath

static func _timestamp() -> String:
	var t: Dictionary = Time.get_datetime_dict_from_system()
	return "%04d%02d%02d_%02d%02d%02d" % [
		int(t["year"]), int(t["month"]), int(t["day"]),
		int(t["hour"]), int(t["minute"]), int(t["second"])]
