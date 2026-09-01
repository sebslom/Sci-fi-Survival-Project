extends StaticBody3D

@onready var label_3d = get_node_or_null("Label3D")
var is_powered: bool = true

func _ready():
	_update_visuals()

func get_interaction_prompt() -> String:
	if not BasePowerGrid.is_machine_powered(self):
		return "⚡ Brak Zasilania Komory"
	return "[E] Use Decontamination Chamber (Cost: 1x Bio-Fuel) ✨"

func update_power_status(online: bool):
	is_powered = online
	_update_visuals()

func _update_visuals():
	if label_3d:
		label_3d.visible = false # Hide 3D world text; display prompt on HUD crosshair

func interact():
	if not BasePowerGrid.is_machine_powered(self):
		if SoundManager: SoundManager.play_hit()
		GameManager.add_log("Power", "⚡ NO POWER! Decontamination chamber requires base power.")
		return

	# Check for 1x Fuel in inventory
	var fuel_idx = -1
	for i in range(GameManager.inventory.size()):
		var item = GameManager.inventory[i]
		if item and item.get("type") == "item_fuel":
			fuel_idx = i
			break

	if fuel_idx < 0:
		if SoundManager: SoundManager.play_hit()
		GameManager.add_log("Decontamination", "⚠️ NO FUEL! Decontamination Chamber requires 1x Bio-Fuel canister.")
		return

	# Consume 1x Fuel
	var fuel_item = GameManager.inventory[fuel_idx]
	if fuel_item.get("count", 1) <= 1:
		GameManager.inventory.remove_at(fuel_idx)
	else:
		fuel_item["count"] -= 1

	# Perform complete bio-decontamination treatment
	GameManager.player_stats.hp = GameManager.player_stats.max_hp
	GameManager.player_stats.suit_integrity = 100
	GameManager.player_stats.radiation = 0

	if SurvivalManager:
		SurvivalManager.heal_all_limbs()
		SurvivalManager.is_bleeding = false
		SurvivalManager.food_poisoning = 0.0

	if SoundManager:
		SoundManager.play_level_up()

	GameManager.add_log("Decontamination", "✨ FULL BIO-MEDICAL DECONTAMINATION! Cured fractures, poisoning, and bleeding. Suit and health 100%.")
	GameManager.emit_signal("stats_changed")
	GameManager.emit_signal("inventory_changed")
