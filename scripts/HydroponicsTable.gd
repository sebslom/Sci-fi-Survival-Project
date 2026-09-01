extends StaticBody3D

var state: String = "empty" # "empty", "growing", "ready"
var growth_time_total: float = 300.0 # 5 minutes real-time
var time_remaining: float = 300.0
var is_powered: bool = true

@onready var mesh_inst = get_node_or_null("MeshInstance3D")
@onready var label_3d = get_node_or_null("Label3D")

var mat_empty: StandardMaterial3D
var mat_growing: StandardMaterial3D
var mat_ready: StandardMaterial3D

func _ready():
	_setup_materials()
	_update_visuals()

func get_interaction_prompt() -> String:
	if not BasePowerGrid.is_machine_powered(self):
		return "⚡ Brak Zasilania Stołu Hydroponicznego"
	elif state == "empty":
		return "[E] Zasiej Rośliny Hydroponiczne 🌱"
	elif state == "growing":
		var m = int(floor(time_remaining / 60.0))
		var s = int(floor(fmod(time_remaining, 60.0)))
		return "⏳ Wegetacja w toku (%02d:%02d) 🌱" % [m, s]
	else:
		return "[E] Odbierz Plony (3x Racje) 🌾"

func _setup_materials():
	mat_empty = StandardMaterial3D.new()
	mat_empty.albedo_color = Color("#1e293b")
	
	mat_growing = StandardMaterial3D.new()
	mat_growing.albedo_color = Color("#f59e0b")
	mat_growing.emission_enabled = true
	mat_growing.emission = Color("#f59e0b")
	mat_growing.emission_energy_multiplier = 0.8
	
	mat_ready = StandardMaterial3D.new()
	mat_ready.albedo_color = Color("#10b981")
	mat_ready.emission_enabled = true
	mat_ready.emission = Color("#10b981")
	mat_ready.emission_energy_multiplier = 2.0

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
			GameManager.add_log("Uprawy", "🌾 PLONY DOJRZAŁE! Naciśnij [E] na Stole Hydroponicznym, aby zebrać jedzenie.")

func _update_visuals():
	if mesh_inst:
		if state == "empty": mesh_inst.material_override = mat_empty
		elif state == "growing": mesh_inst.material_override = mat_growing
		elif state == "ready": mesh_inst.material_override = mat_ready
		
	if label_3d:
		label_3d.visible = false

func interact():
	if not BasePowerGrid.is_machine_powered(self):
		if SoundManager: SoundManager.play_hit()
		GameManager.add_log("Zasilanie", "⚡ BRAK ZASILANIA! Maszyna wymaga prądu z Panela Słonecznego i Akumulatora!")
		return

	if state == "empty":
		state = "growing"
		time_remaining = growth_time_total
		_update_visuals()
		if SoundManager: SoundManager.play_pick()
		GameManager.add_log("Uprawy", "🌱 Posadzono nasiona w Stole Hydroponicznym! Plon gotowy za 5 minut.")
	elif state == "growing":
		var m = int(floor(time_remaining / 60.0))
		var s = int(floor(fmod(time_remaining, 60.0)))
		GameManager.add_log("Uprawy", "⏳ Rośliny rosną... Pozostało: %02d:%02d" % [m, s])
	elif state == "ready":
		state = "empty"
		_update_visuals()
		
		GameManager.inventory.append({
			"id": "ration_farmed_" + str(randi()),
			"name": "Food Ration",
			"type": "food",
			"count": 3,
			"value": 40,
			"weight": 0.5,
			"color": "#f59e0b",
			"icon": "🥪",
			"desc": "+40 Głód i +20 HP (Z własnej uprawy)"
		})
		
		if SoundManager: SoundManager.play_level_up()
		GameManager.add_log("Uprawy", "🌾 Zebrano plony! Dodano 3x Food Ration do ekwipunku.")
		GameManager.emit_signal("inventory_changed")
