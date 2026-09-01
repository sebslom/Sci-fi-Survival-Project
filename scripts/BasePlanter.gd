extends StaticBody3D

var is_planted: bool = false
var has_fertilizer: bool = false
var growth_progress: float = 0.0 # 0.0 to 100.0
var base_growth_rate: float = 2.0 # % per second
var crop_name: String = "Zioła Marsjańskie"

@onready var label_3d = get_node_or_null("Label3D")

func _ready():
	add_to_group("placed_structure")
	add_to_group("planter")
	add_to_group("interactive")

func _process(delta):
	if is_planted and growth_progress < 100.0:
		var speed_mult = 1.20 if has_fertilizer else 1.0
		growth_progress = min(100.0, growth_progress + base_growth_rate * speed_mult * delta)

func get_interaction_prompt() -> String:
	if not is_planted:
		return "🌱 DONICZKA UPRAWNA [Wymagane Nasiona] [E]"
	elif growth_progress < 100.0:
		var fert_str = " (+20% NAWÓZ)" if has_fertilizer else ""
		return "🌿 UPRAWA: %s [%d%%]%s (Użyj Nawozu [E])" % [crop_name, int(growth_progress), fert_str]
	else:
		return "🌾 DOJRZAŁE PLONY: %s! [E - ZBIERZ]" % crop_name

func interact(player_node = null):
	if not is_planted:
		# Check if player has seeds
		if GameManager and GameManager.has_item_type("seed_pack"):
			_consume_player_item("seed_pack")
			is_planted = true
			growth_progress = 0.0
			crop_name = "Zioła Marsjańskie"
			if SoundManager: SoundManager.play_pick()
			GameManager.add_log("Uprawa", "🌱 Posadzono nasiona w doniczce! Wzrost rozpoczęty.")
		else:
			if SoundManager: SoundManager.play_hit()
			GameManager.add_log("Uprawa", "⚠️ Wymagane nasiona (`seed_pack`)! Wytwórz je w Craftingu lub znajdź w skrzyniach.")
	elif growth_progress < 100.0:
		# Apply fertilizer if available
		if not has_fertilizer and GameManager and GameManager.has_item_type("fertilizer"):
			_consume_player_item("fertilizer")
			has_fertilizer = true
			if SoundManager: SoundManager.play_level_up()
			GameManager.add_log("Uprawa", "🧪 Zastosowano Nawóz Organiczny! Szybkość wzrostu +20%!")
		else:
			GameManager.add_log("Uprawa", "⏳ Roślina rośnie... [%d%%]" % int(growth_progress))
	else:
		# Harvest mature crops!
		var crop_item = {
			"id": "crop_herbs_" + str(randi()),
			"name": "🌾 " + crop_name,
			"type": "food",
			"hunger_restore": 35,
			"hp_restore": 15,
			"description": "Świeże zbiory z doniczki w schronie."
		}
		GameManager.inventory.append(crop_item)
		is_planted = false
		has_fertilizer = false
		growth_progress = 0.0
		if SoundManager: SoundManager.play_pick()
		GameManager.add_log("Uprawa", "🌾 Zebrano świeże plony z doniczki!")
		GameManager.emit_signal("inventory_changed")

func _consume_player_item(item_type: String):
	for i in range(GameManager.inventory.size() - 1, -1, -1):
		var item = GameManager.inventory[i]
		if item and item.get("type") == item_type:
			GameManager.inventory.remove_at(i)
			GameManager.emit_signal("inventory_changed")
			return
