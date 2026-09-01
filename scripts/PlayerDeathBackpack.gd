extends StaticBody3D

@export var owner_name: String = "Gracz"
var backpack_items: Array = []
var backpack_gold: int = 0

func _ready():
	add_to_group("placed_structure")
	add_to_group("death_backpack")
	add_to_group("interactive")

func get_interaction_prompt() -> String:
	var item_cnt = backpack_items.size()
	return "🎒 DEATH BACKPACK (%s) [%d przedmiotów, 💰 %d Złota] [E]" % [owner_name, item_cnt, backpack_gold]

func interact(player_node = null):
	if backpack_items.size() == 0 and backpack_gold == 0:
		if SoundManager: SoundManager.play_hit()
		if GameManager: GameManager.add_log("Plecak", "🎒 Plecak po śmierci jest pusty!")
		queue_free()
		return

	# Transfer gold
	if backpack_gold > 0:
		if GameManager and GameManager.player_stats:
			GameManager.player_stats.gold += backpack_gold
			if GameManager: GameManager.add_log("Plecak", "💰 Odzyskano 💰 %d Złota z plecaka po śmierci!" % backpack_gold)
			backpack_gold = 0
			GameManager.emit_signal("stats_changed")

	# Transfer items one by one if space available
	var items_transferred = 0
	var remaining_items = []

	for item in backpack_items:
		var current_slots = GameManager.inventory.size()
		var max_slots = GameManager.get_max_inventory_slots()
		if current_slots < max_slots:
			GameManager.inventory.append(item)
			items_transferred += 1
			if GameManager: GameManager.add_log("Plecak", "🎒 Odzyskano przedmiot: " + item.get("name", "Przedmiot"))
		else:
			remaining_items.append(item)

	backpack_items = remaining_items
	if GameManager: GameManager.emit_signal("inventory_changed")
	if SoundManager: SoundManager.play_pick()

	if items_transferred > 0:
		if GameManager: GameManager.add_log("Plecak", "✨ Transferred %d przedmiotów do ekwipunku!" % items_transferred)

	if backpack_items.size() == 0:
		if GameManager: GameManager.add_log("Plecak", "🎒 Odzyskano wszystkie przedmioty z plecaka po śmierci!")
		queue_free()
	else:
		if GameManager: GameManager.add_log("Warning", "⚠️ Brak miejsca w ekwipunku na resztę przedmiotów! Zwolnij miejsce i naciśnij [E] ponownie.")
