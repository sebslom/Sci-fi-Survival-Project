extends StaticBody3D

var is_hacked: bool = false
@onready var label_3d = get_node_or_null("Label3D")

func _ready():
	_update_label()

func _update_label():
	if label_3d:
		if is_hacked:
			label_3d.text = "🖥️ TERMINAL LABORATORYJNY\n[ZHAKOWANY ✅]"
			label_3d.modulate = Color("#10b981")
		else:
			label_3d.text = "🖥️ TERMINAL LABORATORYJNY [E]\n(Wymaga Mini-Gry Hakerskiej)"
			label_3d.modulate = Color("#00f3ff")

func interact():
	if is_hacked:
		GameManager.add_log("Laboratorium", "🖥️ Terminal został już zhakowany!")
		return

	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("open_hacking_terminal"):
		hud.open_hacking_terminal(self)
	else:
		_complete_hack()

func _complete_hack():
	is_hacked = true
	_update_label()
	if SoundManager: SoundManager.play_level_up()
	
	GameManager.player_stats.gold += 150
	GameManager.add_exp(100)
	
	# Add unique blueprint item to inventory
	GameManager.inventory.append({
		"id": "blueprint_laser_rifle_" + str(randi()),
		"name": "📜 Schemat: Karabin Laserowy Spec-Ops",
		"type": "blueprint",
		"count": 1,
		"weight": 0.5,
		"color": "#a855f7",
		"icon": "📜",
		"desc": "Odblokowuje unikalne rzemiosło broni elitarnych"
	})
	
	GameManager.add_log("Laboratorium", "🔓 ZUPEŁNY SUKCES HAKOWANIA! Zdobyto Unikalny Schemat Karabiun Laserowego + 150 Złota!")
	GameManager.emit_signal("inventory_changed")
	GameManager.emit_signal("stats_changed")
