extends StaticBody3D

var state: String = "empty" # "empty", "processing", "ready"
var processing_time_total: float = 20.0 # 20 seconds processing time
var time_remaining: float = 20.0
var is_powered: bool = true

@onready var mesh_inst = get_node_or_null("MeshInstance3D")
@onready var label_3d = get_node_or_null("Label3D")

var mat_empty: StandardMaterial3D
var mat_processing: StandardMaterial3D
var mat_ready: StandardMaterial3D

func _ready():
	_setup_materials()
	_update_visuals()

func get_interaction_prompt() -> String:
	if not BasePowerGrid.is_machine_powered(self):
		return "⚡ Brak Zasilania Stacji Recyclingu"
	elif state == "empty":
		return "[E] Wrzuć 3x Scrap do Recyclingu ⚙️"
	elif state == "processing":
		return "⏳ Recycling w toku (%d sek) ⚙️" % [int(ceil(time_remaining))]
	else:
		return "[E] Odbierz Przetworzone Materiały (Steel, Polimery, Copper) 🔩"

func _setup_materials():
	mat_empty = StandardMaterial3D.new()
	mat_empty.albedo_color = Color("#0284c7")
	
	mat_processing = StandardMaterial3D.new()
	mat_processing.albedo_color = Color("#f59e0b")
	mat_processing.emission_enabled = true
	mat_processing.emission = Color("#f59e0b")
	mat_processing.emission_energy_multiplier = 1.0
	
	mat_ready = StandardMaterial3D.new()
	mat_ready.albedo_color = Color("#10b981")
	mat_ready.emission_enabled = true
	mat_ready.emission = Color("#10b981")
	mat_ready.emission_energy_multiplier = 2.0

func update_power_status(online: bool):
	is_powered = online
	_update_visuals()

func _process(delta):
	if state == "processing":
		if not is_powered:
			return
			
		time_remaining -= delta
		if time_remaining <= 0:
			state = "ready"
			_update_visuals()
			if SoundManager: SoundManager.play_level_up()
			GameManager.add_log("Recycling", "📦 MATERIAŁY GOTOWE! Naciśnij [E] na Stacji Recyclingu, aby odebrać Polimery, Steel i Copper.")

func _update_visuals():
	if mesh_inst:
		if state == "empty": mesh_inst.material_override = mat_empty
		elif state == "processing": mesh_inst.material_override = mat_processing
		elif state == "ready": mesh_inst.material_override = mat_ready
		
	if label_3d:
		label_3d.visible = false

func interact():
	if not BasePowerGrid.is_machine_powered(self):
		if SoundManager: SoundManager.play_hit()
		GameManager.add_log("Power", "⚡ BRAK ZASILANIA! Maszyna wymaga prądu z Panela Słonecznego i Akumulatora!")
		return

	if state == "empty":
		var scrap_count = 0
		for item in GameManager.inventory:
			if item and item.get("type") in ["scrap", "trash"]:
				scrap_count += item.get("count", 1)
				
		if scrap_count < 3:
			if SoundManager: SoundManager.play_hit()
			GameManager.add_log("Recycling", "⚠️ Brak wystarczającej ilości Scrapu! Wymagane min. 3x Scrap Metalowy.")
			return

		var remaining_to_deduct = 3
		var i = GameManager.inventory.size() - 1
		while i >= 0 and remaining_to_deduct > 0:
			var item = GameManager.inventory[i]
			if item and item.get("type") in ["scrap", "trash"]:
				var count = item.get("count", 1)
				if count <= remaining_to_deduct:
					remaining_to_deduct -= count
					GameManager.inventory.remove_at(i)
				else:
					item["count"] = count - remaining_to_deduct
					remaining_to_deduct = 0
			i -= 1

		state = "processing"
		time_remaining = processing_time_total
		_update_visuals()
		if SoundManager: SoundManager.play_craft()
		GameManager.add_log("Recycling", "⚙️ Wrzucono 3x Scrap! Rozpoczęto recykling (czas: 20 sekund).")
		GameManager.emit_signal("inventory_changed")

	elif state == "processing":
		GameManager.add_log("Recycling", "⏳ Recycling w toku... Pozostało: %d sek" % [int(ceil(time_remaining))])
	elif state == "ready":
		state = "empty"
		_update_visuals()
		
		GameManager.inventory.append({
			"id": "steel_" + str(randi()),
			"name": "Steel Rzemieślnicza",
			"type": "material_steel",
			"count": 2,
			"weight": 1.5,
			"color": "#94a3b8",
			"icon": "🔩",
			"desc": "Czysta czarna stal przemysłowa"
		})
		GameManager.inventory.append({
			"id": "polymer_" + str(randi()),
			"name": "Polimery Syntetyczne",
			"type": "material_polymer",
			"count": 2,
			"weight": 1.0,
			"color": "#38bdf8",
			"icon": "🧪",
			"desc": "Wytrzymałe polimery syntetyczne"
		})
		GameManager.inventory.append({
			"id": "copper_" + str(randi()),
			"name": "Copper Przewodząca",
			"type": "material_copper",
			"count": 1,
			"weight": 1.0,
			"color": "#b45309",
			"icon": "⚡",
			"desc": "Czysta miedź przewodząca prąd"
		})
		
		if SoundManager: SoundManager.play_level_up()
		GameManager.add_log("Recycling", "🔩 ODBIERANO PRZETWORZONE MATERIAŁY! Dodano 2x Steel, 2x Polimery i 1x Copper do ekwipunku.")
		GameManager.emit_signal("inventory_changed")
