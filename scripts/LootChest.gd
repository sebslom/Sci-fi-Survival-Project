extends StaticBody3D

var is_opened: bool = false
@onready var label_3d = get_node_or_null("Label3D")

func _ready():
	_update_label()

func get_interaction_prompt() -> String:
	if is_opened:
		return "📦 Chest Opened"
	return "[E] Open Rare Loot Chest 📦"

func _update_label():
	if label_3d:
		label_3d.visible = false

func interact():
	if is_opened:
		GameManager.add_log("Skrzynia", "Chest has already been looted.")
		return

	is_opened = true
	_update_label()
	if SoundManager: SoundManager.play_level_up()

	# Give rare loot
	var loot_gold = randi_range(80, 220)
	GameManager.player_stats.gold += loot_gold
	GameManager.add_exp(80)

	# Give AP Ammo or Repair Kit or Rare Crystals
	var roll = randf()
	if randf() < 0.30:
		GameManager.inventory.append({
			"id": "flashlight_looted_" + str(randi()),
			"name": "Latarka Taktyczna",
			"type": "flashlight",
			"count": 1,
			"weight": 0.6,
			"icon": "🔦",
			"desc": "Mocne oświetlenie taktyczne pod [F]"
		})
		GameManager.add_log("Skrzynia", "🔦 Znaleziono Latarkę Taktyczną!")

	if roll < 0.4:
		GameManager.ammo_inventory["ap"] += 30
		GameManager.add_log("Skrzynia", "📦 Otworzono skrzynię! Znaleziono 30x Amunicję AP i " + str(loot_gold) + " Złota!")
	elif roll < 0.7:
		GameManager.inventory.append({
			"id": "repair_kit_looted_" + str(randi()),
			"name": "Zestaw Naprawczy Skafandra",
			"type": "repair_kit",
			"count": 1,
			"weight": 2.5,
			"icon": "🧰",
			"desc": "Przywraca szczelność skafandra do 100%"
		})
		GameManager.add_log("Skrzynia", "📦 Otworzono skrzynię! Znaleziono Zestaw Naprawczy i " + str(loot_gold) + " Złota!")
	else:
		GameManager.inventory.append({
			"id": "alien_crystal_" + str(randi()),
			"name": "Kryształ Obcego",
			"type": "scrap",
			"count": 4,
			"weight": 1.5,
			"color": "#a855f7",
			"icon": "💎",
			"desc": "Rzadki kryształ z Zanieczyszczonych Kopalni"
		})
		GameManager.add_log("Skrzynia", "📦 Otworzono skrzynię! Znaleziono 4x Kryształ Obcego i " + str(loot_gold) + " Złota!")

	GameManager.emit_signal("inventory_changed")
	GameManager.emit_signal("stats_changed")
