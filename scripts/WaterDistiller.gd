extends StaticBody3D

var state: String = "empty" # "empty", "distilling", "ready"
var cycle_time_total: float = 120.0 # 2 minutes real-time
var time_remaining: float = 120.0
var is_powered: bool = true

@onready var mesh_inst = get_node_or_null("MeshInstance3D")
@onready var label_3d = get_node_or_null("Label3D")

func _ready():
	_update_visuals()

func get_interaction_prompt() -> String:
	if not BasePowerGrid.is_machine_powered(self):
		return "⚡ Brak Zasilania Destylarni"
	elif state == "empty":
		return "[E] Uruchom Destylarnię Wody 💧"
	elif state == "distilling":
		var m = int(time_remaining) / 60
		var s = int(time_remaining) % 60
		return "⏳ Destylacja w toku (%02d:%02d) 💧" % [m, s]
	else:
		return "[E] Odbierz 3x Czystą Wodę 💧"

func update_power_status(online: bool):
	is_powered = online
	_update_visuals()

func _process(delta):
	if state == "distilling":
		if not is_powered:
			return
			
		time_remaining -= delta
		if time_remaining <= 0:
			state = "ready"
			_update_visuals()
			if SoundManager: SoundManager.play_level_up()
			GameManager.add_log("Destylarnia", "💧 CZYSTA WODA GOTOWA! Naciśnij [E] na Destylarni Wody, aby odebrać zapasy.")

func _update_visuals():
	if label_3d:
		label_3d.visible = false

func interact():
	if not BasePowerGrid.is_machine_powered(self):
		if SoundManager: SoundManager.play_hit()
		GameManager.add_log("Power", "⚡ BRAK ZASILANIA! Maszyna wymaga prądu z Panela Słonecznego lub Reaktora!")
		return

	if state == "empty":
		state = "distilling"
		time_remaining = cycle_time_total
		_update_visuals()
		if SoundManager: SoundManager.play_pick()
		GameManager.add_log("Destylarnia", "💧 Uruchomiono cykl destylacji wody! Oczyszczanie trwa 2 minuty.")
	elif state == "distilling":
		var m = int(time_remaining) / 60
		var s = int(time_remaining) % 60
		GameManager.add_log("Destylarnia", "⏳ Oczyszczanie wody w toku... Pozostało: %02d:%02d" % [m, s])
	elif state == "ready":
		state = "empty"
		_update_visuals()
		
		GameManager.inventory.append({
			"id": "clean_water_" + str(randi()),
			"name": "Czysta Woda Oczyszczona",
			"type": "clean_water",
			"count": 3,
			"value": 50,
			"weight": 0.3,
			"color": "#38bdf8",
			"icon": "💧",
			"desc": "+50 Pragnienie i +15 HP (Z własnej Destylarni Bazy)"
		})
		
		if SoundManager: SoundManager.play_level_up()
		GameManager.add_log("Destylarnia", "💧 Zebrano 3x Czystą Wodę Oczyszczoną do ekwipunku!")
		GameManager.emit_signal("inventory_changed")
