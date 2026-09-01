extends Node

signal survival_stats_updated
signal log_requested(category, message)

# Limb Integrity (0 - 100%)
var limbs = {
	"head": 100.0,
	"torso": 100.0,
	"left_arm": 100.0,
	"right_arm": 100.0,
	"left_leg": 100.0,
	"right_leg": 100.0
}

# Survival Status Effects
var is_bleeding: bool = false
var bleeding_rate: float = 0.0 # HP loss per second
var accumulated_bleeding_damage: float = 0.0 # Tracks total HP lost to bleeding (max 25 HP)

var mask_durability: float = 100.0 # 0 - 100%
var food_poisoning: float = 0.0 # 0 - 100%

var timer: Timer

func _ready():
	timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_tick)
	add_child(timer)

func has_broken_leg() -> bool:
	return limbs["left_leg"] < 30.0 or limbs["right_leg"] < 30.0

func heal_all_limbs():
	for key in limbs.keys():
		limbs[key] = 100.0
	is_bleeding = false
	bleeding_rate = 0.0
	accumulated_bleeding_damage = 0.0
	food_poisoning = 0.0
	emit_signal("survival_stats_updated")

func _on_tick():
	# 1. Bleeding TICK (Pauses at 5 HP, Stops naturally after dealing 25 HP total)
	if is_bleeding and bleeding_rate > 0.0:
		if GameManager.player_stats.hp > 5:
			var actual_loss = min(float(GameManager.player_stats.hp - 5), bleeding_rate)
			if actual_loss > 0.0:
				GameManager.player_stats.hp -= int(actual_loss)
				accumulated_bleeding_damage += actual_loss
				if SoundManager: SoundManager.play_hit()
				emit_signal("log_requested", "Bleeding", "🩸 BLEEDING! Lost -%d HP/s [Total: %.0f/25 HP]! (Min. 5 HP - Use BANDAGE)" % [int(actual_loss), accumulated_bleeding_damage])
		else:
			# HP is <= 5: Bleeding HP damage pauses at 5 HP
			if randf() < 0.2:
				emit_signal("log_requested", "Bleeding", "🩸 CRITICAL BLEEDING (5 HP)! Damage paused - Use BANDAGE or MEDKIT!")

		# Natural clotting after dealing 25 HP total damage
		if accumulated_bleeding_damage >= 25.0:
			is_bleeding = false
			bleeding_rate = 0.0
			accumulated_bleeding_damage = 0.0
			emit_signal("log_requested", "Bleeding", "🩹 Bleeding has naturally clotted after 25 HP loss!")

	# 2. Food Poisoning TICK
	if food_poisoning > 0.0:
		food_poisoning = max(0.0, food_poisoning - 0.5) # Natural recovery over time
		if randf() < 0.25 and food_poisoning > 20.0:
			GameManager.player_stats.hp = max(0, GameManager.player_stats.hp - 2)
			emit_signal("log_requested", "Poisoning", "🤢 Food poisoning nausea (-2 HP)! Take CHARCOAL or MEDICINE.")
			if GameManager.player_stats.hp <= 0:
				var players = get_tree().get_nodes_in_group("player")
				var p_node = players[0] if players.size() > 0 else null
				GameManager.handle_player_death(p_node)

	# 3. Mask Durability Decay in Gas/Sandstorms
	if GameManager.active_location in ["expedition", "dev"]:
		if WeatherManager:
			var w = str(WeatherManager.get("current_weather"))
			if "sandstorm" in w or "dust_storm" in w or w == "2":
				degrade_mask(0.5)

	# 4. Artifact Effects TICK (Regen/Drain HP, Radiation Drain/Growth)
	var art_effects = GameManager.get_total_artifact_effects()
	var net_hp = art_effects["hp_regen"] - art_effects["hp_drain"]
	if net_hp > 0.0:
		GameManager.player_stats.hp = min(GameManager.player_stats.max_hp, GameManager.player_stats.hp + 1)
	elif net_hp < 0.0:
		GameManager.player_stats.hp = max(0, GameManager.player_stats.hp - 1)

	var net_rad = art_effects["rad_growth"] - art_effects["rad_drain"]
	if net_rad > 0.0:
		GameManager.player_stats.radiation = min(100, GameManager.player_stats.radiation + 1)
	elif net_rad < 0.0:
		GameManager.player_stats.radiation = max(0, GameManager.player_stats.radiation - 1)

	GameManager.emit_signal("stats_changed")
	emit_signal("survival_stats_updated")

func inflict_damage(amount: float, is_fall: bool = false, bleed_chance: float = 0.35):
	if is_fall:
		limbs["left_leg"] = max(0.0, limbs["left_leg"] - (amount * 1.5))
		limbs["right_leg"] = max(0.0, limbs["right_leg"] - (amount * 1.5))
		if has_broken_leg():
			if SoundManager: SoundManager.play_hit()
			emit_signal("log_requested", "Injury", "🦴 BROKEN LEGS! Sprint and jump disabled! Take Painkillers!")
		if randf() < 0.20:
			is_bleeding = true
			bleeding_rate = min(5.0, bleeding_rate + 1.5)
			emit_signal("log_requested", "Wound", "🩸 Open bleeding from fall! Use a Bandage!")
	else:
		var target_limb = ["head", "torso", "left_arm", "right_arm", "left_leg", "right_leg"][randi() % 6]
		limbs[target_limb] = max(0.0, limbs[target_limb] - amount)
		
		# Randomized Bleed Chance depending on enemy / attack type (bounded 20% - 50%)
		var final_chance = clamp(bleed_chance, 0.20, 0.50)
		if randf() < final_chance:
			is_bleeding = true
			bleeding_rate = min(5.0, bleeding_rate + 2.0)
			emit_signal("log_requested", "Wound", "🩸 Open wound bleeding (%d%% chance)! Use a Cloth Bandage!" % int(final_chance * 100))

	emit_signal("survival_stats_updated")

func use_bandage() -> bool:
	if not is_bleeding and limbs["left_arm"] > 80.0 and limbs["right_arm"] > 80.0 and limbs["left_leg"] > 80.0 and limbs["right_leg"] > 80.0:
		emit_signal("log_requested", "Medical", "⚠️ No open wounds or active bleeding.")
		return false
		
	is_bleeding = false
	bleeding_rate = 0.0
	accumulated_bleeding_damage = 0.0
	limbs["torso"] = min(100.0, limbs["torso"] + 25.0)
	limbs["left_arm"] = min(100.0, limbs["left_arm"] + 20.0)
	limbs["right_arm"] = min(100.0, limbs["right_arm"] + 20.0)
	limbs["left_leg"] = min(100.0, limbs["left_leg"] + 20.0)
	limbs["right_leg"] = min(100.0, limbs["right_leg"] + 20.0)
	
	if SoundManager: SoundManager.play_level_up()
	emit_signal("log_requested", "Medical", "🩹 Bleeding stopped with bandage! Wounds dressed.")
	emit_signal("survival_stats_updated")
	return true

func use_charcoal() -> bool:
	if food_poisoning <= 0.0:
		emit_signal("log_requested", "Medical", "⚠️ No symptoms of food poisoning.")
		return false
		
	food_poisoning = max(0.0, food_poisoning - 60.0)
	if SoundManager: SoundManager.play_level_up()
	emit_signal("log_requested", "Medical", "🖤 Activated Charcoal taken! Toxin neutralization (-60%).")
	emit_signal("survival_stats_updated")
	return true

func use_painkillers() -> bool:
	food_poisoning = max(0.0, food_poisoning - 40.0)
	limbs["head"] = min(100.0, limbs["head"] + 40.0)
	limbs["left_leg"] = min(100.0, limbs["left_leg"] + 45.0)
	limbs["right_leg"] = min(100.0, limbs["right_leg"] + 45.0)
	
	if SoundManager: SoundManager.play_level_up()
	emit_signal("log_requested", "Medical", "💊 Painkillers taken! Pain relieved in legs and head.")
	emit_signal("survival_stats_updated")
	return true

func degrade_mask(amount: float):
	if GameManager.has_gas_mask_protection():
		mask_durability = max(0.0, mask_durability - amount)
		if mask_durability < 20.0 and randf() < 0.1:
			emit_signal("log_requested", "Mask", "⚠️ WARNING: Gas Mask integrity degrading (%d%% integrity)!" % int(mask_durability))
		emit_signal("survival_stats_updated")

func repair_mask(amount: float = 100.0):
	mask_durability = min(100.0, mask_durability + amount)
	if SoundManager: SoundManager.play_pick()
	emit_signal("log_requested", "Mask", "🔧 Gas mask filters replaced! Integrity: 100%.")
	emit_signal("survival_stats_updated")
