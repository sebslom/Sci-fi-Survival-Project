extends Node

signal weapon_state_changed
signal log_requested(category, message)

var weapon_conditions = {} # weapon_id -> float (0.0 to 100.0)
var weapon_attachments = {} # weapon_id -> { "suppressor": bool, "scope": bool }
var jammed_weapons = {} # weapon_id -> bool

const MAX_CONDITION: float = 500.0

func get_condition(weapon_dict: Dictionary) -> float:
	var w_id = weapon_dict.get("id", "default_weapon")
	if not weapon_conditions.has(w_id):
		weapon_conditions[w_id] = weapon_dict.get("condition", MAX_CONDITION)
	return weapon_conditions[w_id]

func has_attachment(weapon_dict: Dictionary, attach_type: String) -> bool:
	var w_id = weapon_dict.get("id", "default_weapon")
	if not weapon_attachments.has(w_id):
		weapon_attachments[w_id] = { "suppressor": false, "scope": false }
	return weapon_attachments[w_id].get(attach_type, false)

func is_jammed(weapon_dict: Dictionary) -> bool:
	var w_id = weapon_dict.get("id", "default_weapon")
	return jammed_weapons.get(w_id, false)

func degrade_weapon(weapon_dict: Dictionary, amount: float = 0.1):
	var w_id = weapon_dict.get("id", "default_weapon")
	var cond = get_condition(weapon_dict)
	weapon_conditions[w_id] = max(0.0, cond - amount)
	emit_signal("weapon_state_changed")

func repair_weapon(weapon_dict: Dictionary, inventory_idx: int = -1) -> bool:
	var w_id = weapon_dict.get("id", "default_weapon")
	weapon_conditions[w_id] = MAX_CONDITION
	jammed_weapons[w_id] = false
	if inventory_idx >= 0 and inventory_idx < GameManager.inventory.size():
		GameManager.inventory.remove_at(inventory_idx)
	if SoundManager: SoundManager.play_level_up()
	emit_signal("log_requested", "Naprawa", "🛠️ UŻYTO ZESTAW DOZBRAJAJĄCY! Broń naprawiona do 100% kondycji (500/500)!")
	GameManager.emit_signal("inventory_changed")
	emit_signal("weapon_state_changed")
	return true

func try_fire_weapon(weapon_dict: Dictionary) -> Dictionary:
	var w_id = weapon_dict.get("id", "default_weapon")
	var cond = get_condition(weapon_dict)

	if is_jammed(weapon_dict):
		if SoundManager: SoundManager.play_hit()
		emit_signal("log_requested", "Broń", "⚠️ BROŃ ZACIĘTA! Naciśnij [R], aby odblokować zamek!")
		return { "can_fire": false, "is_jammed": true, "suppressed": false, "scope": false }

	if cond <= 0.0 or (cond < 100.0 and randf() < ((100.0 - cond) / 100.0) * 0.45):
		jammed_weapons[w_id] = true
		if SoundManager: SoundManager.play_hit()
		emit_signal("log_requested", "Broń", "💥 ZACIĘCIE BRONI! Naciśnij [R], aby usunąć zacięcie!")
		emit_signal("weapon_state_changed")
		return { "can_fire": false, "is_jammed": true, "suppressed": false, "scope": false }

	degrade_weapon(weapon_dict, 0.08)

	return {
		"can_fire": true,
		"is_jammed": false,
		"suppressed": has_attachment(weapon_dict, "suppressor"),
		"scope": has_attachment(weapon_dict, "scope")
	}

func unjam_weapon(weapon_dict: Dictionary) -> bool:
	var w_id = weapon_dict.get("id", "default_weapon")
	if jammed_weapons.get(w_id, false):
		jammed_weapons[w_id] = false
		if SoundManager: SoundManager.play_pick()
		emit_signal("log_requested", "Broń", "🔧 Odblokowano komorę zamkową! Broń gotowa do strzału.")
		emit_signal("weapon_state_changed")
		return true
	return false

func toggle_suppressor(weapon_dict: Dictionary, inventory_idx: int = -1) -> bool:
	var w_id = weapon_dict.get("id", "default_weapon")
	if not weapon_attachments.has(w_id):
		weapon_attachments[w_id] = { "suppressor": false, "scope": false }

	var current = weapon_attachments[w_id]["suppressor"]
	if current:
		weapon_attachments[w_id]["suppressor"] = false
		GameManager.inventory.append({
			"id": "suppressor_" + str(randi()),
			"name": "Tłumik Taktyczny Dźwięku",
			"type": "attachment_suppressor",
			"count": 1,
			"weight": 0.4,
			"color": "#475569",
			"icon": "🔇",
			"desc": "Wycisza strzały i redukuje odrzut broni"
		})
		emit_signal("log_requested", "Modyfikacje", "🔇 Zdemontowano Tłumik z broni.")
	else:
		weapon_attachments[w_id]["suppressor"] = true
		if inventory_idx >= 0 and inventory_idx < GameManager.inventory.size():
			GameManager.inventory.remove_at(inventory_idx)
		emit_signal("log_requested", "Modyfikacje", "🔇 Zamontowano Tłumik Taktyczny Dźwięku!")

	GameManager.emit_signal("inventory_changed")
	emit_signal("weapon_state_changed")
	return true

func toggle_scope(weapon_dict: Dictionary, inventory_idx: int = -1) -> bool:
	var w_id = weapon_dict.get("id", "default_weapon")
	if not weapon_attachments.has(w_id):
		weapon_attachments[w_id] = { "suppressor": false, "scope": false }

	var current = weapon_attachments[w_id]["scope"]
	if current:
		weapon_attachments[w_id]["scope"] = false
		GameManager.inventory.append({
			"id": "scope_" + str(randi()),
			"name": "Celownik Optyczny Snajperski",
			"type": "attachment_scope",
			"count": 1,
			"weight": 0.5,
			"color": "#475569",
			"icon": "🔭",
			"desc": "Przybliżenie snajperskie pod PPM"
		})
		emit_signal("log_requested", "Modyfikacje", "🔭 Zdemontowano Celownik Optyczny z broni.")
	else:
		weapon_attachments[w_id]["scope"] = true
		if inventory_idx >= 0 and inventory_idx < GameManager.inventory.size():
			GameManager.inventory.remove_at(inventory_idx)
		emit_signal("log_requested", "Modyfikacje", "🔭 Zamontowano Celownik Optyczny Snajperski!")

	GameManager.emit_signal("inventory_changed")
	emit_signal("weapon_state_changed")
	return true
