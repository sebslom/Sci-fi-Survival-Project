extends StaticBody3D

var state: String = "empty" # "empty", "growing", "ready"
var cycle_time_total: float = 180.0 # 3 minutes real-time
var time_remaining: float = 180.0
var is_powered: bool = true

@onready var mesh_inst = get_node_or_null("MeshInstance3D")
@onready var label_3d = get_node_or_null("Label3D")

func _ready():
	_update_visuals()

func get_interaction_prompt() -> String:
	if not BasePowerGrid.is_machine_powered(self):
		return "⚡ Brak Zasilania Półki Hydroponicznej"
	elif state == "empty":
		return "[E] Zasiej Uprawy Hydroponiczne 🌱"
	elif state == "growing":
		var m = int(time_remaining) / 60
		var s = int(time_remaining) % 60
		return "⏳ Wzrost upraw (%02d:%02d) 🌱" % [m, s]
	else:
		return "[E] Odbierz Plony (6x Rations Żywnościowej) 🌾"

func update_power_status(online: bool):
	is_powered = online
	_update_visuals()

func _process(delta):
	if state == "growing":
		if not is_powered:
			return
			
		time_remaining -= delta
		if time_remaining <= 0:
			state = "ready"
			_update_visuals()
			if SoundManager: SoundManager.play_level_up()
			GameManager.add_log("Uprawy", "🌾 BOGATE PLONY GOTOWE! Naciśnij [E] na Półce Hydroponicznej, aby odebrać 6x Rację Żywnościową.")

func _update_visuals():
	if label_3d:
		label_3d.visible = false

func interact():
	if not BasePowerGrid.is_machine_powered(self):
		if SoundManager: SoundManager.play_hit()
		GameManager.add_log("Zasilanie", "⚡ BRAK ZASILANIA! Maszyna wymaga prądu z Panela Słonecznego lub Reaktora!")
		return

	if state == "empty":
		state = "growing"
		time_remaining = cycle_time_total
		_update_visuals()
		if SoundManager: SoundManager.play_pick()
		GameManager.add_log("Uprawy", "🌱 Zasiano nasiona na Półce Hydroponicznej! Plon (x6) za 3 minuty.")
	elif state == "growing":
		var m = int(time_remaining) / 60
		var s = int(time_remaining) % 60
		GameManager.add_log("Uprawy", "⏳ Rośliny rosną na półce... Pozostało: %02d:%02d" % [m, s])
	elif state == "ready":
		state = "empty"
		_update_visuals()
		
		GameManager.inventory.append({
			"id": "ration_shelf_" + str(randi()),
			"name": "Food Ration",
			"type": "food",
			"count": 6,
			"value": 40,
			"weight": 0.5,
			"color": "#f59e0b",
			"icon": "🥪",
			"desc": "+40 Głód i +20 HP (Z Półki Hydroponicznej)"
		})
		
		if SoundManager: SoundManager.play_level_up()
		GameManager.add_log("Uprawy", "🌾 Zebrano bogate plony! Dodano 6x Rację Żywnościową do ekwipunku.")
		GameManager.emit_signal("inventory_changed")
