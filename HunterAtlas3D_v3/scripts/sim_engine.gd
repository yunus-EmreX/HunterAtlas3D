extends Node
class_name SimEngine

func run_sim(biome: Dictionary, hunter: Dictionary, hours: int, seed: int, scenario: Dictionary) -> Dictionary:
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = seed

    var state: Dictionary = {
        "hour": 0,
        "calories": float(scenario.get("start_calories", 1800.0)),
        "water": float(scenario.get("start_water", 1.8)),
        "fatigue": 0.0,
        "injury": 0.0,
        "alive": true
    }

    var series: Dictionary = {
        "calories": [],
        "water": [],
        "risk": []
    }

    var events: Array = []

    for h in range(hours):
        if not bool(state["alive"]):
            break
        state["hour"] = h

        var risk: float = _tick(rng, biome, hunter, scenario, state, events)
        (series["calories"] as Array).append(float(state["calories"]))
        (series["water"] as Array).append(float(state["water"]))
        (series["risk"] as Array).append(risk)

    return {"state": state, "series": series, "events": events}

func _pick_animal_name(rng: RandomNumberGenerator, biome: Dictionary) -> String:
    var animals_any: Variant = biome.get("animals", [])
    if typeof(animals_any) != TYPE_ARRAY:
        return "av"
    var animals: Array = animals_any
    if animals.is_empty():
        return "av"
    var idx: int = int(floor(rng.randf() * float(animals.size())))
    idx = clamp(idx, 0, animals.size() - 1)
    var a_any: Variant = animals[idx]
    if typeof(a_any) == TYPE_DICTIONARY:
        var a: Dictionary = a_any
        return str(a.get("name", "av"))
    return str(a_any)

func _tick(rng: RandomNumberGenerator, biome: Dictionary, hunter: Dictionary, scenario: Dictionary, state: Dictionary, events: Array) -> float:
    var b_res_any: Variant = biome.get("resources", {})
    var b_haz_any: Variant = biome.get("hazards", {})
    var climate_any: Variant = biome.get("climate", {})
    var stats_any: Variant = hunter.get("stats", {})
    var affinity_any: Variant = hunter.get("affinity", {})

    var b_res: Dictionary = b_res_any if typeof(b_res_any) == TYPE_DICTIONARY else {}
    var b_haz: Dictionary = b_haz_any if typeof(b_haz_any) == TYPE_DICTIONARY else {}
    var climate: Dictionary = climate_any if typeof(climate_any) == TYPE_DICTIONARY else {}
    var stats: Dictionary = stats_any if typeof(stats_any) == TYPE_DICTIONARY else {}
    var affinity: Dictionary = affinity_any if typeof(affinity_any) == TYPE_DICTIONARY else {}

    var biome_id: String = str(biome.get("id", ""))
    var aff: float = float(affinity.get(biome_id, 0.0))

    var activity: float = float(scenario.get("activity", 0.65))
    var exposure: float = float(b_haz.get("exposure", 0.5))
    var cold_res: float = float(stats.get("cold_resist", 0.5))
    var heat_res: float = float(stats.get("heat_resist", 0.5))
    var endurance: float = float(stats.get("endurance", 0.5))
    var tracking: float = float(stats.get("tracking", 0.5))
    var stealth: float = float(stats.get("stealth", 0.5))

    var base_burn: float = 90.0
    var move_burn: float = 260.0 * activity * (1.05 - endurance * 0.25)
    var stress_burn: float = 120.0 * exposure * (1.0 - (cold_res + heat_res) * 0.5)
    var burn: float = (base_burn + move_burn + stress_burn) * (1.0 - aff * 0.08)
    state["calories"] = max(0.0, float(state.get("calories", 0.0)) - burn)

    var humidity: float = float(climate.get("humidity", 0.5))
    var wind: float = float(climate.get("wind", 0.5))
    var water_burn: float = (0.08 + 0.18 * activity + 0.06 * wind) * (1.15 - humidity * 0.3)
    state["water"] = max(0.0, float(state.get("water", 0.0)) - water_burn)

    var water_avail: float = float(b_res.get("water", 0.5))
    var game_avail: float = float(b_res.get("game", 0.5))

    var water_skill: float = (tracking * 0.25 + endurance * 0.15 + stealth * 0.10) + aff * 0.35
    var hunt_skill: float = (tracking * 0.40 + stealth * 0.25 + endurance * 0.15) + aff * 0.35

    var p_water: float = clamp(water_avail * 0.55 + water_skill * 0.35, 0.02, 0.85)
    if rng.randf() < p_water:
        var found: float = 0.25 + rng.randf() * 0.45
        state["water"] = min(3.0, float(state["water"]) + found)
        if rng.randf() < 0.35:
            events.append({"hour": int(state["hour"]), "type": "water", "text": "Su kaynağı bulundu (+%.2f L)." % found})

    var p_food: float = clamp(game_avail * 0.45 + hunt_skill * 0.40 - float(state.get("fatigue", 0.0)) * 0.15, 0.01, 0.75)
    if rng.randf() < p_food:
        var gained: float = 350.0 + rng.randf() * 650.0
        state["calories"] = min(2600.0, float(state["calories"]) + gained)
        var animal: String = _pick_animal_name(rng, biome)
        events.append({"hour": int(state["hour"]), "type": "food", "text": "Avlandı: %s (+kalori)." % animal})

    var predators: float = float(b_haz.get("predators", 0.3))
    var parasites: float = float(b_haz.get("parasites", 0.3))
    var risk_tol: float = float(stats.get("risk_tolerance", 0.5))

    var injury_risk: float = clamp(predators * 0.10 + activity * 0.06 + float(state.get("fatigue", 0.0)) * 0.08 - stealth * 0.06 - risk_tol * 0.03, 0.005, 0.25)
    if rng.randf() < injury_risk:
        state["injury"] = min(1.0, float(state.get("injury", 0.0)) + 0.18 + rng.randf() * 0.20)
        events.append({"hour": int(state["hour"]), "type": "injury", "text": "Yaralanma olayı (hareket/tehlike)."})

    var illness_risk: float = clamp(parasites * 0.06 + (1.0 - float(state.get("water", 0.0))) * 0.04, 0.002, 0.18)
    if rng.randf() < illness_risk:
        state["fatigue"] = min(1.0, float(state.get("fatigue", 0.0)) + 0.10 + rng.randf() * 0.10)
        if rng.randf() < 0.5:
            events.append({"hour": int(state["hour"]), "type": "illness", "text": "Hastalık/yorgunluk artışı (parazit/koşul)."})

    var fatigue_gain: float = clamp(0.03 + activity * 0.06 + float(state.get("injury", 0.0)) * 0.08 - endurance * 0.05, 0.0, 0.18)
    state["fatigue"] = clamp(float(state.get("fatigue", 0.0)) + fatigue_gain - 0.02, 0.0, 1.0)

    var risk: float = 0.0
    if float(state.get("water", 0.0)) <= 0.05:
        risk += 0.55
    if float(state.get("calories", 0.0)) <= 50.0:
        risk += 0.30
    risk += float(state.get("injury", 0.0)) * 0.35 + float(state.get("fatigue", 0.0)) * 0.20 + exposure * 0.10

    if risk > 0.95 and rng.randf() < (risk - 0.85):
        state["alive"] = false
        events.append({"hour": int(state["hour"]), "type": "death", "text": "Kritik risk eşiği aşıldı; sim sonlandı."})

    return clamp(risk, 0.0, 1.0)
