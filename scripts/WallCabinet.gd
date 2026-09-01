extends StaticBody3D

@export var max_slots: int = 8
var stored_items: Array = []

func _ready():
	add_to_group("placed_structure")
	add_to_group("storage_chest")
	add_to_group("wall_cabinet")
	add_to_group("interactive")

func get_interaction_prompt() -> String:
	return "🗄️ WISZĄCA SZAFKA SCIENNA [%d/%d Slotów] [E]" % [stored_items.size(), max_slots]

func interact(player_node = null):
	if not GameManager: return
	var active_slot = GameManager.hotbar.get(GameManager.active_hotbar_slot)
	if active_slot and stored_items.size() < max_slots:
		stored_items.append(active_slot.duplicate(true))
		GameManager.hotbar.erase(GameManager.active_hotbar_slot)
		if SoundManager: SoundManager.play_pick()
		GameManager.add_log("Szafka", "🗄️ Schowano przedmiot do szafki wiszącej: " + active_slot.get("name", ""))
		GameManager.emit_signal("inventory_changed")
	elif stored_items.size() > 0:
		var item = stored_items.pop_back()
		GameManager.inventory.append(item)
		if SoundManager: SoundManager.play_pick()
		GameManager.add_log("Szafka", "🎒 Wyjęto z szafki wiszącej: " + item.get("name", ""))
		GameManager.emit_signal("inventory_changed")
	else:
		if SoundManager: SoundManager.play_hit()
		GameManager.add_log("Szafka", "ℹ️ Szafka jest pusta! Wybierz przedmiot na hotbarze [1-5] i wciśnij [E], aby go schować.")
