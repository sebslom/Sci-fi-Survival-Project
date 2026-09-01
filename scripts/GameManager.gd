extends Node

signal stats_changed
signal inventory_changed
signal location_changed(new_location)
signal wipeout_timer_updated(time_left)
signal log_added(category, message)
signal player_model_changed(model_idx)

const TILE_SIZE = 2.0
const SHELTER_SIZE = 32
const SURFACE_SIZE = 400
const CITY_SIZE = 30

var player_stats = {
	"level": 1,
	"exp": 0,
	"hp": 100,
	"max_hp": 100,
	"shield": 0,
	"max_shield": 50,
	"suit_integrity": 100,
	"gold": 150,
	"attack": 10,
	"defense": 5,
	"hunger": 100,
	"thirst": 100,
	"radiation": 0
}

var hunger_float: float = 100.0
var thirst_float: float = 100.0
var starve_timer: int = 0

var active_location = "house" # "house", "expedition", "town", "dev"

var expedition_scenes = [
	"res://scenes/locations/ExpeditionMars.tscn",
	"res://scenes/locations/ExpeditionCanyon.tscn",
	"res://scenes/locations/ExpeditionRuins.tscn",
	"res://scenes/locations/ExpeditionIce.tscn",
	"res://scenes/locations/ExpeditionMines.tscn"
]
var current_expedition_scene = "res://scenes/locations/ExpeditionMars.tscn"

# Player Customization & Nickname
var player_name: String = "Zwiadowca_Alpha"
var selected_model_idx: int = 0 # 0..3 (4 Placeholders)
var model_placeholders = [
	"Alpha Scout 🛡️ (#00f3ff)",
	"Ciężki Komandos 💣 (#f59e0b)",
	"Bio-Hazard Suit ☣️ (#10b981)",
	"Technical Engineer ⚙️ (#a855f7)"
]

# Multiplayer & Server Settings
var is_private_server: bool = true
var server_password: String = "1337"
var room_code: String = "MARS-7829"
var connected_players = ["Zwiadowca_Alpha (Host)"]

# Audio & Render Settings
var master_volume: float = 1.0
var render_scale: float = 1.0
var current_resolution_idx: int = 0

# Procedural Expedition Seed & Emission System
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var current_expedition_seed: int = 0
var total_emissions_survived: int = 0
var timer_node: Timer = null

# Functional Equipment
var equipment = {
	"helmet": null,
	"mask": { "id": "gas_mask_default", "name": "Gas Mask (Grade 1)", "type": "gas_mask", "filter_grade": 1, "icon": "😷", "desc": "Basic gas protection" },
	"armor": null,
	"boots": null,
	"backpack": { "id": "bp_travel", "name": "Hiking Backpack", "type": "backpack", "extra_slots": 8, "max_weight": 180.0, "icon": "🎒", "desc": "+8 Slotów, Limit 180kg" }
}

# Cosmetic Equipment
var cosmetic_equipment = {
	"helmet": null,
	"mask": null,
	"armor": null,
	"boots": null
}

# 5 Artifact Slots
var artifact_slots = [null, null, null, null, null]

# Limited Ammo Inventory (No infinite ammo!)
var ammo_inventory = {
	"standard": 60,
	"ap": 20,
	"incendiary": 10
}

var inventory = [
	{ "id": "watch_1", "name": "Tactical Watch", "type": "watch", "count": 1, "weight": 0.1, "color": "#00f3ff", "icon": "⌚", "desc": "Displays emission timer" },
	{ "id": "gps_1", "name": "GPS / Map Module", "type": "gps", "count": 1, "weight": 0.1, "color": "#10b981", "icon": "🗺️", "desc": "Unlocks map view [M]" },
	{ "id": "w_laser", "name": "Laser Pistol", "type": "weapon", "weaponType": "laser", "count": 1, "ammo_type": "standard", "damage": 18, "weight": 1.5, "color": "#00f3ff", "icon": "🔫", "desc": "Fast energy pistol using STD ammo" },
	{ "id": "machete_1", "name": "Tactical Machete", "type": "melee", "count": 1, "damage": 35, "weight": 1.5, "color": "#06b6d4", "icon": "🗡️", "desc": "Melee weapon for close combat. Requires repair when worn out!" },
	{ "id": "rep_kit_start", "name": "Weapon Repair Kit", "type": "repair_kit", "count": 1, "weight": 1.0, "color": "#f59e0b", "icon": "🛠️", "desc": "Repairs firearms and melee weapons to 100% condition" },
	{ "id": "boots_tactical", "name": "Desert Tactical Boots", "type": "boots", "count": 1, "speed_bonus": 0.8, "weight": 1.2, "color": "#10b981", "icon": "🥾", "desc": "+0.8 m/s Movement speed" },
	{ "id": "helm_composite", "name": "Composite Helmet", "type": "helmet", "count": 1, "defense_bonus": 12, "weight": 2.0, "color": "#00f3ff", "icon": "🪖", "desc": "+12 Head Protection" }
]

var hotbar = {
	1: { "id": "w_laser", "name": "Laser Pistol", "type": "weapon", "weaponType": "laser", "count": 1, "ammo_type": "standard", "damage": 18, "weight": 1.5, "color": "#00f3ff", "icon": "🔫" },
	2: { "id": "machete_1", "name": "Tactical Machete", "type": "melee", "count": 1, "damage": 35, "weight": 1.5, "color": "#06b6d4", "icon": "🗡️" },
	3: null,
	4: null,
	5: null
}
var active_hotbar_slot: int = 1

var wipeout_timer: int = 300
var wipeout_active: bool = true

var crafting_recipes = []
var quests = []

func _ready():
	rng.randomize()
	_init_crafting_recipes()
	_init_quests()
	
	reroll_expedition_seed()
	
	timer_node = Timer.new()
	timer_node.wait_time = 1.0
	timer_node.autostart = true
	timer_node.timeout.connect(_on_wipeout_second_tick)
	add_child(timer_node)
	
	inventory.append(generate_random_artifact())

var custom_destination_scene: String = ""

func travel_to(new_location: String):
	custom_destination_scene = ""
	active_location = new_location
	emit_signal("location_changed", new_location)
	add_log("Podróż", "🌀 Traveling to location: " + new_location.to_upper())

func travel_to_custom_scene(scene_path: String):
	custom_destination_scene = scene_path
	active_location = "custom_scene"
	emit_signal("location_changed", "custom_scene")
	add_log("Podróż", "🌀 Podróż do Sceny Dedykowanej: " + scene_path.get_file())

func set_player_nickname(new_name: String):
	if new_name.strip_edges() != "":
		player_name = new_name.strip_edges()
		connected_players[0] = player_name + " (Host)"
		add_log("Gracz", "Wybrano Nick: " + player_name)

func set_player_model(idx: int):
	if idx >= 0 and idx < model_placeholders.size():
		selected_model_idx = idx
		emit_signal("player_model_changed", selected_model_idx)
		add_log("Gracz", "Wybrano Model: " + model_placeholders[idx])

func set_master_volume(val: float):
	master_volume = val
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(val))

func save_game_state() -> bool:
	var save_data = {
		"player_name": player_name,
		"selected_model_idx": selected_model_idx,
		"player_stats": player_stats,
		"hunger_float": hunger_float,
		"thirst_float": thirst_float,
		"inventory": inventory,
		"hotbar": hotbar,
		"equipment": equipment,
		"cosmetic_equipment": cosmetic_equipment,
		"artifact_slots": artifact_slots,
		"ammo_inventory": ammo_inventory,
		"current_expedition_seed": current_expedition_seed,
		"wipeout_timer": wipeout_timer,
		"is_private_server": is_private_server,
		"server_password": server_password,
		"room_code": room_code,
		"placed_structures": _get_placed_structures_save_data()
	}

	var file = FileAccess.open("user://save_game.json", FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(save_data, "  ")
		file.store_string(json_str)
		file.close()
		if SoundManager: SoundManager.play_level_up()
		add_log("Save", "💾 GAME STATE AND BASE SUCCESSFULLY SAVED TO FILE!")
		return true
	return false

func load_game_state() -> bool:
	if not FileAccess.file_exists("user://save_game.json"):
		add_log("Save", "⚠️ Brak zapisanej gry (user://save_game.json)")
		return false

	var file = FileAccess.open("user://save_game.json", FileAccess.READ)
	if not file: return false

	var json_str = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_str)
	if parse_result != OK:
		add_log("Save", "⚠️ JSON save file parse error.")
		return false

	var data = json.get_data()
	if data and data is Dictionary:
		player_name = data.get("player_name", player_name)
		selected_model_idx = data.get("selected_model_idx", selected_model_idx)
		player_stats = data.get("player_stats", player_stats)
		hunger_float = data.get("hunger_float", hunger_float)
		thirst_float = data.get("thirst_float", thirst_float)
		inventory = data.get("inventory", inventory)
		hotbar = data.get("hotbar", hotbar)
		equipment = data.get("equipment", equipment)
		cosmetic_equipment = data.get("cosmetic_equipment", cosmetic_equipment)
		artifact_slots = data.get("artifact_slots", artifact_slots)
		ammo_inventory = data.get("ammo_inventory", ammo_inventory)
		current_expedition_seed = data.get("current_expedition_seed", current_expedition_seed)
		wipeout_timer = data.get("wipeout_timer", wipeout_timer)
		is_private_server = data.get("is_private_server", is_private_server)
		server_password = data.get("server_password", server_password)
		room_code = data.get("room_code", room_code)

		set_player_model(selected_model_idx)
		_restore_placed_structures(data.get("placed_structures", []))

		if SoundManager: SoundManager.play_level_up()
		add_log("Save", "📂 ZALADOWANO STAN GRY Z PLIKU ZAPISU!")
		emit_signal("inventory_changed")
		emit_signal("stats_changed")
		emit_signal("wipeout_timer_updated", wipeout_timer)
		return true
	return false

func save_and_exit_to_menu():
	save_game_state()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/MainMenuScene.tscn")

var base_placed_structures: Array = []

func save_base_structures():
	if active_location == "house":
		base_placed_structures = _get_placed_structures_save_data()

func restore_base_structures(target_container: Node):
	if not target_container or base_placed_structures.size() == 0: return

	for struct_data in base_placed_structures:
		var f_type = struct_data.get("type", "floor")
		var pos_arr = struct_data.get("pos", [0, 0, 0])
		var pos = Vector3(pos_arr[0], pos_arr[1], pos_arr[2])
		_instantiate_structure_into_container(f_type, pos, target_container)

func _instantiate_structure_into_container(f_type: String, pos: Vector3, container: Node):
	if f_type == "mirror":
		var mirror_scene = load("res://scenes/prefabs/Mirror.tscn")
		if mirror_scene:
			var inst = mirror_scene.instantiate()
			inst.global_position = pos
			container.add_child(inst)
			return
	elif f_type == "door":
		var scene = load("res://scenes/prefabs/Door.tscn")
		if scene:
			var inst = scene.instantiate()
			inst.global_position = pos
			container.add_child(inst)
			return
	elif f_type == "military_crate" or f_type == "chest":
		var scene = load("res://scenes/prefabs/MilitaryCrate.tscn")
		if scene:
			var inst = scene.instantiate()
			inst.global_position = pos
			container.add_child(inst)
			return
	elif f_type == "window_glass":
		var scene = load("res://scenes/prefabs/WindowGlass.tscn")
		if scene:
			var inst = scene.instantiate()
			inst.global_position = pos
			container.add_child(inst)
			return
	elif f_type == "light_bulb":
		var scene = load("res://scenes/prefabs/LightBulb.tscn")
		if scene:
			var inst = scene.instantiate()
			inst.global_position = pos
			container.add_child(inst)
			return
	elif f_type in ["portal_station", "portal_mobile", "portal_clone_factory", "portal_bazar"]:
		var portal_scene = load("res://scenes/prefabs/CustomPortal.tscn")
		if portal_scene:
			var p_inst = portal_scene.instantiate()
			p_inst.global_position = pos
			p_inst.is_mobile = (f_type == "portal_mobile")
			if f_type == "portal_clone_factory":
				p_inst.target_biome = "clone_factory"
			elif f_type == "portal_bazar":
				p_inst.target_biome = "bazar"
			container.add_child(p_inst)
			return

	var struct_node = StaticBody3D.new()
	struct_node.add_to_group("placed_structure")
	struct_node.set("building_type", f_type)

	var mesh_inst = MeshInstance3D.new()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("#475569")
	mat.roughness = 0.4
	mat.metallic = 0.8

	if f_type == "floor" or f_type == "roof":
		var box = BoxMesh.new(); box.size = Vector3(2.0, 0.2, 2.0)
		mesh_inst.mesh = box
	elif f_type == "stairs":
		var prism = PrismMesh.new(); prism.size = Vector3(2.0, 3.0, 2.0)
		mesh_inst.mesh = prism
	elif f_type in ["wall_doorway", "wall_window"]:
		var box = BoxMesh.new(); box.size = Vector3(2.0, 3.0, 0.2)
		mesh_inst.mesh = box
	else:
		var box = BoxMesh.new(); box.size = Vector3(1.5, 1.5, 1.5)
		mesh_inst.mesh = box

	mesh_inst.material_override = mat
	struct_node.add_child(mesh_inst)

	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = mesh_inst.mesh.get("size") if mesh_inst.mesh.get("size") else Vector3(1.5, 1.5, 1.5)
	col.shape = box_shape
	struct_node.add_child(col)

	struct_node.global_position = pos
	container.add_child(struct_node)

func _get_placed_structures_save_data() -> Array:
	var list = []
	var nodes = get_tree().get_nodes_in_group("placed_structure")
	for node in nodes:
		if node and is_instance_valid(node):
			list.append({
				"type": node.get("building_type") if node.get("building_type") else "furniture",
				"pos": [node.global_position.x, node.global_position.y, node.global_position.z],
				"rot": [node.global_rotation.x, node.global_rotation.y, node.global_rotation.z]
			})
	return list

func _restore_placed_structures(list: Array):
	base_placed_structures = list

func reroll_expedition_seed():
	rng.randomize()
	current_expedition_seed = rng.randi()
	wipeout_timer = 300

	var portals = get_tree().get_nodes_in_group("portal")
	for portal in portals:
		if portal and portal.has_method("set_expedition_seed"):
			portal.set_expedition_seed(current_expedition_seed)

	add_log("Emission", "☄️ EMISSION WAVE CHANGED PLANETARY SURFACE! Generated New Expedition Seed #" + str(current_expedition_seed))
	emit_signal("wipeout_timer_updated", wipeout_timer)

func _on_wipeout_second_tick():
	if active_location == "custom_scene" and "CloneFactory" in custom_destination_scene:
		emit_signal("wipeout_timer_updated", -1)
		return

	if wipeout_active:
		wipeout_timer -= 1
		emit_signal("wipeout_timer_updated", wipeout_timer)
		
		if wipeout_timer == 60:
			add_log("Ostrzeżenie", "⚠️ EMISSION WARNING: Anomaly Wave Hits In 60 Seconds! Evacuate to Base Airlock!")
			if SoundManager: SoundManager.play_alarm()
		elif wipeout_timer <= 0:
			trigger_emission_wave()

func trigger_emission_wave():
	total_emissions_survived += 1
	if SoundManager: SoundManager.play_alarm()

	if active_location == "expedition":
		var dmg = 45
		player_stats.hp = max(0, player_stats.hp - dmg)
		damage_suit(30)
		player_stats.radiation = min(100, player_stats.radiation + 50)
		add_log("Emission", "💥 MARTIAN EMISSION WAVE HIT! Took -" + str(dmg) + " HP i Jump Promieniowania (+50 Rad)!")
		if SoundManager: SoundManager.play_hit()
		if player_stats.hp <= 0:
			var players = get_tree().get_nodes_in_group("player")
			var p_node = players[0] if players.size() > 0 else null
			handle_player_death(p_node)
	else:
		add_log("Emission", "🛡️ BASE SHELTER PROTECTED YOU FROM EMISSION WAVE! Planet surface terrain regenerated.")

	reroll_expedition_seed()

var is_player_dying: bool = false
var peer_saved_states: Dictionary = {}

func handle_player_death(player_node = null):
	if is_player_dying: return
	is_player_dying = true

	var death_pos = Vector3.ZERO
	var parent_scene = null
	if player_node and is_instance_valid(player_node):
		death_pos = player_node.global_position
		parent_scene = player_node.get_parent()

	# 1. Spawn PlayerDeathBackpack at death position
	var backpack_script = load("res://scripts/PlayerDeathBackpack.gd")
	var backpack = StaticBody3D.new()
	backpack.set_script(backpack_script)
	backpack.set("owner_name", player_name)

	var mesh_inst = MeshInstance3D.new()
	var bmesh = BoxMesh.new()
	bmesh.size = Vector3(0.8, 0.9, 0.5)
	mesh_inst.mesh = bmesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("#0284c7") # Cyan Backpack
	mat.roughness = 0.5
	mesh_inst.material_override = mat
	backpack.add_child(mesh_inst)

	var col = CollisionShape3D.new()
	var cshape = BoxShape3D.new(); cshape.size = bmesh.size
	col.shape = cshape
	backpack.add_child(col)

	var lbl = Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0, 0.8, 0)
	lbl.text = "🎒 DEATH BACKPACK (%s)" % player_name
	lbl.modulate = Color("#00f3ff")
	backpack.add_child(lbl)

	backpack.set("backpack_items", inventory.duplicate(true))
	backpack.set("backpack_gold", player_stats.get("gold", 0))

	if parent_scene:
		parent_scene.add_child(backpack)
		backpack.global_position = death_pos + Vector3(0, 0.45, 0)

	# 2. Reset inventory and stats
	inventory.clear()
	player_stats.gold = 0
	player_stats.hp = player_stats.max_hp
	player_stats.radiation = 0
	hunger_float = 100.0
	thirst_float = 100.0

	emit_signal("stats_changed")
	emit_signal("inventory_changed")

	add_log("Death", "💀 YOU DIED! Your backpack with all items remains at death location. Respawning in Shelter!")
	if SoundManager: SoundManager.play_hit()

	# 3. Respawn in Shelter
	travel_to("house")

	is_player_dying = false

func save_peer_state(peer_id: int):
	var p_data = {
		"player_name": player_name,
		"selected_model_idx": selected_model_idx,
		"player_stats": player_stats.duplicate(true),
		"inventory": inventory.duplicate(true),
		"hotbar": hotbar.duplicate(true),
		"equipment": equipment.duplicate(true),
		"ammo_inventory": ammo_inventory.duplicate(true)
	}
	peer_saved_states[peer_id] = p_data
	
	var file_path = "user://multiplayer_peer_%d.json" % peer_id
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(p_data, "  "))
		file.close()

func load_peer_state(peer_id: int) -> bool:
	var file_path = "user://multiplayer_peer_%d.json" % peer_id
	var data = null
	if peer_saved_states.has(peer_id):
		data = peer_saved_states[peer_id]
	elif FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var json_str = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(json_str) == OK:
				data = json.get_data()

	if data and data is Dictionary:
		player_name = data.get("player_name", player_name)
		selected_model_idx = data.get("selected_model_idx", selected_model_idx)
		player_stats = data.get("player_stats", player_stats)
		inventory = data.get("inventory", inventory)
		hotbar = data.get("hotbar", hotbar)
		equipment = data.get("equipment", equipment)
		ammo_inventory = data.get("ammo_inventory", ammo_inventory)
		emit_signal("stats_changed")
		emit_signal("inventory_changed")
		add_log("Multiplayer", "🎮 Wczytano zapisany stan gracza [Peer #%d] z serwera!" % peer_id)
		return true
	return false

func on_peer_joined(peer_id: int):
	add_log("Multiplayer", "🌐 Player [Peer #%d] joined server. Respawning in Shelter..." % peer_id)
	load_peer_state(peer_id)
	travel_to("house")

func on_peer_disconnected(peer_id: int):
	add_log("Multiplayer", "🔌 Player [Peer #%d] disconnected. Saving state on server..." % peer_id)
	save_peer_state(peer_id)
	save_game_state()

func generate_random_artifact() -> Dictionary:
	var names = ["Gravity Crystal", "Anomaly Ember", "Martian Metamorph", "Isotope Stone", "Shadow Herald", "Desert Gold Star"]
	var selected_name = names[rng.randi() % names.size()]

	var buffs = {}
	var debuffs = {}

	var possible_buffs = [
		{"key": "jump_boost", "name": "Jump", "min": 0.6, "max": 1.2, "unit": "m"},
		{"key": "speed_boost", "name": "Speed", "min": 0.4, "max": 0.8, "unit": "m/s"},
		{"key": "rad_drain", "name": "Radiation Drain", "min": 0.3, "max": 0.7, "unit": "rad/s"},
		{"key": "hp_regen", "name": "HP Regen", "min": 0.3, "max": 0.6, "unit": "HP/s"},
		{"key": "carry_capacity", "name": "Carry Capacity", "min": 4.0, "max": 8.0, "unit": "kg"}
	]

	var possible_debuffs = [
		{"key": "hp_drain", "name": "Damage", "min": 0.2, "max": 0.5, "unit": "HP/s"},
		{"key": "rad_growth", "name": "Radiation Growth", "min": 0.3, "max": 0.6, "unit": "rad/s"},
		{"key": "weight_penalty", "name": "Spadek Carry Capacityu", "min": 3.0, "max": 6.0, "unit": "kg"},
		{"key": "speed_penalty", "name": "Slowdown", "min": 0.3, "max": 0.6, "unit": "m/s"}
	]

	possible_buffs.shuffle()
	var buff_count = rng.randi_range(1, 2)
	for b in range(buff_count):
		var item_trait = possible_buffs[b]
		buffs[item_trait["key"]] = snappedf(rng.randf_range(item_trait["min"], item_trait["max"]), 0.1)

	possible_debuffs.shuffle()
	var debuff_count = rng.randi_range(1, 2)
	for d in range(debuff_count):
		var item_trait = possible_debuffs[d]
		debuffs[item_trait["key"]] = snappedf(rng.randf_range(item_trait["min"], item_trait["max"]), 0.1)

	return {
		"id": "artifact_" + str(rng.randi()),
		"name": selected_name,
		"type": "artifact",
		"icon": "🔮",
		"weight": 0.5,
		"color": "#a855f7",
		"buffs": buffs,
		"debuffs": debuffs,
		"desc": "Rzadki artefakt z cyklu Emisji #" + str(current_expedition_seed)
	}

func get_total_artifact_effects() -> Dictionary:
	var total = {
		"jump_boost": 0.0,
		"speed_boost": 0.0,
		"rad_drain": 0.0,
		"hp_regen": 0.0,
		"carry_capacity": 0.0,
		"hp_drain": 0.0,
		"rad_growth": 0.0,
		"weight_penalty": 0.0,
		"speed_penalty": 0.0
	}

	for art in artifact_slots:
		if art and art is Dictionary:
			var buffs = art.get("buffs", {})
			for k in buffs.keys():
				if total.has(k): total[k] += buffs[k]

			var debuffs = art.get("debuffs", {})
			for k in debuffs.keys():
				if total.has(k): total[k] += debuffs[k]

	return total

# Hardcore Economy System (15% Sell Price, 300% Buy Price)
const HARDCORE_SELL_MULTIPLIER: float = 0.15
const HARDCORE_BUY_MULTIPLIER: float = 3.0

func get_item_base_value(item: Dictionary) -> int:
	if item.has("base_value"):
		return item.get("base_value", 50)
	var itype = item.get("type", "")
	if itype == "weapon": return 120
	elif itype == "helmet" or itype == "boots": return 80
	elif itype == "artifact": return 200
	elif itype == "repair_kit": return 50
	elif itype == "component_portal_core": return 300
	elif itype == "blueprint": return 150
	elif itype == "scrap" or itype == "material_steel": return 20
	return 40

func get_item_sell_price(item: Dictionary) -> int:
	var base_val = get_item_base_value(item)
	return max(1, int(ceil(base_val * HARDCORE_SELL_MULTIPLIER)))

func get_item_buy_price(item: Dictionary) -> int:
	var base_val = get_item_base_value(item)
	return int(round(base_val * HARDCORE_BUY_MULTIPLIER))

func sell_item_to_merchant(inventory_idx: int) -> bool:
	if inventory_idx < 0 or inventory_idx >= inventory.size(): return false
	var item = inventory[inventory_idx]
	if not item: return false

	var sell_price = get_item_sell_price(item)
	var item_name = item.get("name", "Przedmiot")
	var base_val = get_item_base_value(item)

	inventory.remove_at(inventory_idx)
	player_stats.gold += sell_price

	if SoundManager: SoundManager.play_pick()
	add_log("Handel", "💰 SOLD [%s]: +%d Gold! (15%% wartości bazowej %d💰)" % [item_name, sell_price, base_val])

	emit_signal("inventory_changed")
	emit_signal("stats_changed")
	return true

func equip_functional_gear(inventory_idx: int, slot_type: String):
	if inventory_idx < 0 or inventory_idx >= inventory.size(): return
	var item = inventory[inventory_idx]
	if not item: return

	var prev = equipment.get(slot_type)
	equipment[slot_type] = item
	inventory.remove_at(inventory_idx)
	if prev: inventory.append(prev)

	if SoundManager: SoundManager.play_pick()
	add_log("Inventory", "Equipped item:: " + item.get("name", ""))
	emit_signal("inventory_changed")
	emit_signal("stats_changed")

func unequip_functional_gear(slot_type: String):
	var item = equipment.get(slot_type)
	if item:
		equipment[slot_type] = null
		inventory.append(item)
		if SoundManager: SoundManager.play_pick()
		add_log("Inventory", "Unequipped item:: " + item.get("name", ""))
		emit_signal("inventory_changed")
		emit_signal("stats_changed")

func equip_cosmetic_gear(inventory_idx: int, slot_type: String):
	if inventory_idx < 0 or inventory_idx >= inventory.size(): return
	var item = inventory[inventory_idx]
	if not item: return

	var prev = cosmetic_equipment.get(slot_type)
	cosmetic_equipment[slot_type] = item
	inventory.remove_at(inventory_idx)
	if prev: inventory.append(prev)

	if SoundManager: SoundManager.play_pick()
	add_log("Cosmetics", "Equipped item: kosmetyczny: " + item.get("name", ""))
	emit_signal("inventory_changed")

func unequip_cosmetic_gear(slot_type: String):
	var item = cosmetic_equipment.get(slot_type)
	if item:
		cosmetic_equipment[slot_type] = null
		inventory.append(item)
		if SoundManager: SoundManager.play_pick()
		add_log("Cosmetics", "Unequipped item: kosmetyczny: " + item.get("name", ""))
		emit_signal("inventory_changed")

func equip_artifact(inventory_idx: int, artifact_slot_idx: int):
	if inventory_idx < 0 or inventory_idx >= inventory.size(): return
	if artifact_slot_idx < 0 or artifact_slot_idx >= 5: return

	var item = inventory[inventory_idx]
	if not item or item.get("type") != "artifact": return

	var prev = artifact_slots[artifact_slot_idx]
	artifact_slots[artifact_slot_idx] = item
	inventory.remove_at(inventory_idx)
	if prev: inventory.append(prev)

	if SoundManager: SoundManager.play_level_up()
	add_log("Artifact", "🔮 Equipped artifact w slocie #" + str(artifact_slot_idx + 1) + ": " + item.get("name", ""))
	emit_signal("inventory_changed")
	emit_signal("stats_changed")

func unequip_artifact(artifact_slot_idx: int):
	if artifact_slot_idx < 0 or artifact_slot_idx >= 5: return
	var item = artifact_slots[artifact_slot_idx]
	if item:
		artifact_slots[artifact_slot_idx] = null
		inventory.append(item)
		if SoundManager: SoundManager.play_pick()
		add_log("Artifact", "🔮 Removed artifact ze mebla #" + str(artifact_slot_idx + 1))
func consume_hotbar_item(slot_num: int):
	var item = hotbar.get(slot_num)
	if not item: return

	var count = item.get("count", 1)
	if count > 1:
		item["count"] = count - 1
	else:
		hotbar.erase(slot_num)
		var idx = inventory.find(item)
		if idx != -1:
			inventory.remove_at(idx)

	emit_signal("inventory_changed")

func add_item_to_inventory(item_dict: Dictionary) -> bool:
	if inventory.size() >= 30:
		return false

	var is_stackable = item_dict.get("type") in ["scrap", "material", "component", "ammo", "consumable", "cloth", "wood"] or item_dict.get("stackable", false)
	if is_stackable:
		var item_id = item_dict.get("id", "")
		var item_name = item_dict.get("name", "")
		for inv_item in inventory:
			if (item_id != "" and inv_item.get("id") == item_id) or (inv_item.get("name") == item_name and inv_item.get("type") == item_dict.get("type")):
				inv_item["count"] = inv_item.get("count", 1) + item_dict.get("count", 1)
				emit_signal("inventory_changed")
				return true

	inventory.append(item_dict.duplicate(true))
	emit_signal("inventory_changed")
	return true

func drop_physical_item(item_data: Dictionary, player_node = null) -> Node3D:
	var item_scene = load("res://scenes/prefabs/InteractableItem3D.tscn")
	if not item_scene: return null

	var item_inst = item_scene.instantiate()
	item_inst.set("item_data", item_data.duplicate(true))

	var spawn_pos = Vector3.ZERO
	var spawn_dir = Vector3.FORWARD
	var parent_scene = get_tree().current_scene

	var p = player_node
	if not p:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0: p = players[0]

	if p and is_instance_valid(p):
		spawn_pos = p.global_position + Vector3(0, 1.2, 0)
		spawn_dir = -p.global_transform.basis.z.normalized()
		spawn_pos += spawn_dir * 1.2
	else:
		spawn_pos = Vector3(0, 1.5, 0)

	item_inst.global_position = spawn_pos
	parent_scene.add_child(item_inst)

	if item_inst is RigidBody3D:
		item_inst.apply_central_impulse(spawn_dir * 2.5 + Vector3(0, 1.0, 0))

	return item_inst

func _init_crafting_recipes():
	crafting_recipes = [
		{ "id": "rec_repair_kit", "name": "Weapon Repair Kit", "cost": { "material_steel": 2, "material_polymer": 2 }, "result": { "id": "rep_kit_1", "name": "Weapon Repair Kit", "type": "repair_kit", "count": 1, "weight": 1.0, "icon": "🛠️", "desc": "Repairs any firearm or melee weapon to 100% condition" }, "desc": "Weapon repair kit", "icon": "🛠️" },
		{ "id": "rec_machete", "name": "Tactical Machete (Melee)", "cost": { "material_steel": 3, "cloth": 1 }, "result": { "id": "melee_machete", "name": "Tactical Machete", "type": "melee", "count": 1, "damage": 35, "weight": 1.5, "icon": "🗡️", "desc": "Melee weapon for close combat" }, "desc": "Forge a tactical steel machete", "icon": "🗡️" },
		{ "id": "rec_ammo_std", "name": "Standard Ammo Pack (x30)", "cost": { "scrap": 4, "wood": 1 }, "result": { "id": "ammo_std_craft", "name": "Standard Ammo Pack (x30)", "type": "ammo_std_pack", "count": 1, "weight": 0.5, "icon": "📦", "desc": "Daje +30x Standard Ammo" }, "desc": "Craft 30 rounds of Standard Ammo", "icon": "📦" },
		{ "id": "rec_ammo_ap", "name": "Armor-Piercing AP Ammo Pack (x20)", "cost": { "material_steel": 2, "scrap": 2 }, "result": { "id": "ammo_ap_craft", "name": "AP Ammo Pack (x20)", "type": "ammo_ap_pack", "count": 1, "weight": 0.5, "icon": "💥", "desc": "Grants +20 AP Ammo" }, "desc": "Craft 20 rounds of AP Ammo", "icon": "💥" },
		{ "id": "rec_ammo_fire", "name": "Incendiary Ammo Pack (x15)", "cost": { "material_polymer": 2, "wood": 1 }, "result": { "id": "ammo_fire_craft", "name": "Incendiary Ammo Pack (x15)", "type": "ammo_fire_pack", "count": 1, "weight": 0.5, "icon": "🔥", "desc": "Daje +15x Incendiary Ammo" }, "desc": "Craft 15 rounds of Incendiary Ammo", "icon": "🔥" },
		{ "id": "rec_bandage", "name": "Cloth Bandage", "cost": { "cloth": 2 }, "result": { "id": "bandage_1", "name": "Cloth Bandage", "type": "bandage", "count": 1, "weight": 0.2, "icon": "🩹", "desc": "Stops open wound bleeding" }, "desc": "Basic dressing to stop bleeding", "icon": "🩹" },
		{ "id": "rec_rag", "name": "Cloth Rags", "cost": { "clothing": 1 }, "result": { "id": "cloth_1", "name": "Fabric Rags", "type": "cloth", "count": 3, "weight": 0.1, "icon": "🧵", "desc": "Crafting material for bandages and ropes" }, "desc": "Shred clothing into 3x Rags", "icon": "🧵" },
		{ "id": "rec_rope", "name": "Climbing Rope", "cost": { "cloth": 4 }, "result": { "id": "rope_1", "name": "Strong Synthetic Rope", "type": "rope", "count": 1, "weight": 0.8, "icon": "🪢", "desc": "Heavy rope for construction and climbing" }, "desc": "Twist 4x Rags into rope", "icon": "🪢" },
		{ "id": "rec_charcoal", "name": "Activated Charcoal", "cost": { "wood": 2 }, "result": { "id": "charcoal_1", "name": "Medical Activated Charcoal", "type": "charcoal", "count": 1, "weight": 0.2, "icon": "🖤", "desc": "Cures food poisoning (-60%)" }, "desc": "Smelt 2x Wood into medical charcoal", "icon": "🖤" },
		{ "id": "rec_suppressor", "name": "Tactical Sound Suppressor", "cost": { "part_barrel": 1, "material_steel": 2 }, "result": { "id": "attachment_supp", "name": "Tactical Sound Suppressor", "type": "attachment_suppressor", "count": 1, "weight": 0.4, "icon": "🔇", "desc": "Silences gunfire and reduces weapon recoil" }, "desc": "Requires Barrel Part and 2x Steel", "icon": "🔇" },
		{ "id": "rec_scope", "name": "Sniper Optical Scope", "cost": { "part_receiver": 1, "material_polymer": 2 }, "result": { "id": "attachment_sc", "name": "Sniper Optical Scope", "type": "attachment_scope", "count": 1, "weight": 0.5, "icon": "🔭", "desc": "Sniper zoom on RMB" }, "desc": "Requires Receiver Part and 2x Polymers", "icon": "🔭" },
		{ "id": "rec_bio_engine", "name": "Decontamination Bio-Engine", "cost": { "scrap": 7, "material_copper": 2, "material_steel": 2 }, "result": { "id": "component_bio_eng", "name": "Decontamination Bio-Engine", "type": "component_bio_engine", "count": 1, "weight": 4.0, "icon": "⚙️", "desc": "Core power module for Decontamination Chamber" }, "desc": "Bio-medical chamber engine", "icon": "⚙️" },
		{ "id": "rec_bio_fuel", "name": "Decontamination Bio-Fuel", "cost": { "wood": 2, "scrap": 4 }, "result": { "id": "fuel_1", "name": "Decontamination Bio-Fuel", "type": "item_fuel", "count": 1, "weight": 1.0, "icon": "🛢️", "desc": "Fuel canister for 1 Decontamination cycle" }, "desc": "Decontamination fuel for airlock", "icon": "🛢️" },
		{ "id": "rec_decon_chamber", "name": "Advanced Decontamination Chamber", "cost": { "component_bio_engine": 1, "material_steel": 6, "material_polymer": 4 }, "result": { "id": "decon_item", "name": "Decontamination Chamber (Airlock)", "type": "furniture", "furnitureType": "decon_chamber", "count": 1, "weight": 12.0, "icon": "✨", "desc": "Heals fractures, bleeding, and poisoning for 1 fuel" }, "desc": "Medical airlock structure for base", "icon": "✨" },
		{ "id": "rec_bed", "name": "Military Bed", "cost": { "material_steel": 3, "cloth": 3 }, "result": { "id": "bed_item", "name": "Military Bed", "type": "furniture", "furnitureType": "bed", "count": 1, "weight": 6.0, "icon": "🛏️", "desc": "Sleeping bunk for HP recovery" }, "desc": "Comfortable bed for rest", "icon": "🛏️" },
		{ "id": "rec_chair", "name": "Tactical Chair", "cost": { "material_steel": 2, "material_polymer": 1 }, "result": { "id": "chair_item", "name": "Tactical Chair", "type": "furniture", "furnitureType": "chair", "count": 1, "weight": 3.0, "icon": "🪑", "desc": "Base seating furniture" }, "desc": "Tactical base chair", "icon": "🪑" },
		{ "id": "rec_floor", "name": "Base Floor Panel", "cost": { "material_steel": 1 }, "result": { "id": "floor_item", "name": "Base Floor Panel", "type": "furniture", "furnitureType": "floor", "count": 1, "weight": 2.0, "icon": "⬛", "desc": "Steel floor panel" }, "desc": "Modular base floor construction", "icon": "⬛" },
		{ "id": "rec_roof", "name": "Base Roof Ceiling", "cost": { "material_steel": 2 }, "result": { "id": "roof_item", "name": "Base Roof Ceiling", "type": "furniture", "furnitureType": "roof", "count": 1, "weight": 3.0, "icon": "🏠", "desc": "Protective steel ceiling" }, "desc": "Base roof construction", "icon": "🏠" },
		{ "id": "rec_stairs", "name": "Base Stairs", "cost": { "material_steel": 2 }, "result": { "id": "stairs_item", "name": "Base Stairs", "type": "furniture", "furnitureType": "stairs", "count": 1, "weight": 4.0, "icon": "🪜", "desc": "Steel stairs to upper floor" }, "desc": "Stairs for multi-level building", "icon": "🪜" },
		{ "id": "rec_distiller", "name": "Water Distiller", "cost": { "material_steel": 4, "material_copper": 2 }, "result": { "id": "distiller_item", "name": "Water Distiller", "type": "furniture", "furnitureType": "distiller", "count": 1, "weight": 8.0, "icon": "💧", "desc": "Produces purified drinking water using base power" }, "desc": "Water purifying machine", "icon": "💧" },
		{ "id": "rec_isotope", "name": "Isotope Generator (+60 kW)", "cost": { "material_steel": 6, "material_copper": 4, "material_polymer": 4 }, "result": { "id": "isotope_item", "name": "Isotope Generator (+60 kW)", "type": "furniture", "furnitureType": "isotope", "count": 1, "weight": 15.0, "icon": "☢️", "desc": "Provides +60 kW power, emits radiation within 10m" }, "desc": "High-output nuclear power generator", "icon": "☢️" },
		{ "id": "rec_hydro_shelf", "name": "Hydroponic Shelf", "cost": { "material_steel": 3, "material_polymer": 3 }, "result": { "id": "hydro_shelf_item", "name": "Hydroponic Shelf", "type": "furniture", "furnitureType": "hydro_shelf", "count": 1, "weight": 6.0, "icon": "🌾", "desc": "Vertical farming unit producing 6x Food Rations every 3 mins" }, "desc": "Hydroponic food rack", "icon": "🌾" },
		{ "id": "rec_mirror", "name": "Craftsman Mirror (3D Preview)", "cost": { "scrap": 4 }, "result": { "id": "mirror_item", "name": "Craftsman Mirror", "type": "furniture", "furnitureType": "mirror", "count": 1, "weight": 4.0, "icon": "🪞", "desc": "Scrap mirror with 3D character and armor preview" }, "desc": "Build scrap mirror (4x Scrap)", "icon": "🪞" },
		{ "id": "rec_portal_core", "name": "Quantum Portal Core", "cost": { "crystal": 3, "scrap": 4, "material_polymer": 2 }, "result": { "id": "portal_core_item", "name": "Quantum Portal Core", "type": "component_portal_core", "count": 1, "weight": 2.0, "icon": "🔮", "desc": "High-energy subspace core crafted from anomaly crystals" }, "desc": "Key component powering quantum portals", "icon": "🔮" },
		{ "id": "rec_portal_stacjonarny", "name": "Stationary Quantum Portal", "cost": { "component_portal_core": 1, "material_steel": 4, "material_copper": 2 }, "result": { "id": "portal_station_item", "name": "Stationary Quantum Portal", "type": "furniture", "furnitureType": "portal_station", "count": 1, "weight": 12.0, "icon": "🌀", "desc": "Stationary portal with biome selector and manual jump coords" }, "desc": "Build advanced base jump gate", "icon": "🌀" },
		{ "id": "rec_portal_mobilny", "name": "Portable Expedition Portal", "cost": { "component_portal_core": 1, "scrap": 4 }, "result": { "id": "portal_mobile_item", "name": "Portable Expedition Portal", "type": "furniture", "furnitureType": "portal_mobile", "count": 1, "weight": 5.0, "icon": "⚡", "desc": "Compact emergency escape portal" }, "desc": "Compact jump gate", "icon": "⚡" },
		{ "id": "rec_portal_clone_factory", "name": "Mission Portal: Clone Factory", "cost": { "component_portal_core": 2, "material_steel": 8, "material_polymer": 6, "material_copper": 4 }, "result": { "id": "portal_clone_item", "name": "Mission Portal: Clone Factory", "type": "furniture", "furnitureType": "portal_clone_factory", "count": 1, "weight": 18.0, "icon": "🧬", "desc": "Combat portal to Clone Factory complex and Anomaly Bosses" }, "desc": "Large gate to cloning complex and combat missions", "icon": "🧬" },
		{ "id": "rec_portal_bazar", "name": "Trade Portal: Interstellar Basear", "cost": { "component_portal_core": 2, "material_steel": 6, "material_copper": 6, "scrap": 18 }, "result": { "id": "portal_bazar_item", "name": "Trade Portal: Interstellar Basear", "type": "furniture", "furnitureType": "portal_bazar", "count": 1, "weight": 16.0, "icon": "🏪", "desc": "Subspace trade tunnel connecting base to Interstellar Basear" }, "desc": "Trade gate to Interstellar Basear", "icon": "🏪" },
		{ "id": "rec_painting", "name": "Obraz na Ścianę", "cost": { "cloth": 2, "wood": 1 }, "result": { "id": "painting_item", "name": "Obraz na Ścianę", "type": "furniture", "furnitureType": "painting", "count": 1, "weight": 1.5, "icon": "🖼️", "desc": "Decorative painting with toggleable artwork on [E]" }, "desc": "Decorative wall art", "icon": "🖼️" },
		{ "id": "rec_wall_cabinet", "name": "Hanging Wall Cabinet", "cost": { "material_steel": 3, "scrap": 4 }, "result": { "id": "wall_cabinet_item", "name": "Hanging Wall Cabinet", "type": "furniture", "furnitureType": "wall_cabinet", "count": 1, "weight": 5.0, "icon": "🗄️", "desc": "Hanging wall storage container" }, "desc": "Hanging wall cabinet", "icon": "🗄️" },
		{ "id": "rec_military_crate", "name": "Military Storage Crate", "cost": { "material_steel": 4 }, "result": { "id": "military_crate_item", "name": "Military Storage Crate", "type": "furniture", "furnitureType": "military_crate", "count": 1, "weight": 8.0, "icon": "📦", "desc": "Heavy-duty military storage container" }, "desc": "Spacious military crate for items", "icon": "📦" },
		{ "id": "rec_wall_shelf", "name": "Hanging Wall Shelf", "cost": { "wood": 2, "material_steel": 1 }, "result": { "id": "wall_shelf_item", "name": "Hanging Wall Shelf", "type": "furniture", "furnitureType": "wall_shelf", "count": 1, "weight": 2.0, "icon": "📐", "desc": "Wall shelf for placing props and objects" }, "desc": "Wall shelf for decorations", "icon": "📐" },
		{ "id": "rec_umbrella", "name": "Protective Canopy", "cost": { "cloth": 3, "material_steel": 2 }, "result": { "id": "umbrella_item", "name": "Protective Canopy", "type": "furniture", "furnitureType": "umbrella", "count": 1, "weight": 3.5, "icon": "☂️", "desc": "Canopy with toggleable state (Folded / Unfolded)" }, "desc": "Base protective canopy", "icon": "☂️" },
		{ "id": "rec_light_bulb", "name": "Base Lighting Lightbulb", "cost": { "material_copper": 1, "scrap": 2 }, "result": { "id": "light_bulb_item", "name": "Base Lighting Lightbulb", "type": "furniture", "furnitureType": "light_bulb", "count": 1, "weight": 0.5, "icon": "💡", "desc": "Ceiling light bulb with toggle switch on [E]" }, "desc": "Lightbulb for ceiling and wall mounting", "icon": "💡" },
		{ "id": "rec_table", "name": "Wooden Table", "cost": { "wood": 3 }, "result": { "id": "table_item", "name": "Wooden Table", "type": "furniture", "furnitureType": "table", "count": 1, "weight": 5.0, "icon": "🟫", "desc": "Base table for placing items" }, "desc": "Base furniture table", "icon": "🟫" },
		{ "id": "rec_planter", "name": "Crop Planter Box", "cost": { "wood": 2, "scrap": 2 }, "result": { "id": "planter_item", "name": "Crop Planter Box", "type": "furniture", "furnitureType": "planter", "count": 1, "weight": 3.0, "icon": "🌱", "desc": "Planter box for growing seeds" }, "desc": "Agricultural planter box", "icon": "🌱" },
		{ "id": "rec_seed_pack", "name": "Crop Seed Pack", "cost": { "wood": 1 }, "result": { "id": "seed_pack_1", "name": "Crop Seed Pack", "type": "seed_pack", "count": 1, "weight": 0.2, "icon": "🌱", "desc": "Seeds for planting in Crop Planter Box" }, "desc": "Seed pack for crops", "icon": "🌱" },
		{ "id": "rec_fertilizer", "name": "Organic Fertilizer (+20% Growth)", "cost": { "charcoal": 1, "wood": 1 }, "result": { "id": "fertilizer_1", "name": "Organic Fertilizer", "type": "fertilizer", "count": 1, "weight": 0.5, "icon": "🧪", "desc": "Accelerates plant growth in planter by +20%" }, "desc": "Agricultural fertilizer for faster growth", "icon": "🧪" },
		{ "id": "rec_wardrobe", "name": "Industrial Wardrobe", "cost": { "material_steel": 5 }, "result": { "id": "wardrobe_item", "name": "Industrial Wardrobe", "type": "furniture", "furnitureType": "wardrobe", "count": 1, "weight": 10.0, "icon": "🚪", "desc": "Large industrial wardrobe for armor and suits" }, "desc": "Industrial shelter wardrobe", "icon": "🚪" },
		{ "id": "rec_tv", "name": "Retro Television", "cost": { "material_copper": 3, "material_polymer": 2 }, "result": { "id": "tv_item", "name": "Retro Television", "type": "furniture", "furnitureType": "tv", "count": 1, "weight": 6.0, "icon": "📺", "desc": "TV with toggleable glowing screen" }, "desc": "Retro base TV", "icon": "📺" },
		{ "id": "rec_radio", "name": "Martian Radio", "cost": { "material_copper": 2, "scrap": 4 }, "result": { "id": "radio_item", "name": "Martian Radio", "type": "furniture", "furnitureType": "radio", "count": 1, "weight": 2.5, "icon": "📻", "desc": "Radio receiver playing colonial broadcasts" }, "desc": "Radio playing Martian broadcasts", "icon": "📻" },
		{ "id": "rec_boar_hide", "name": "Boar Hide Rug", "cost": { "cloth": 5 }, "result": { "id": "boar_hide_item", "name": "Boar Hide Rug", "type": "furniture", "furnitureType": "boar_hide", "count": 1, "weight": 4.0, "icon": "🐗", "desc": "Hunting hide rug for base floor" }, "desc": "Hunting hide floor rug", "icon": "🐗" },
		{ "id": "rec_wall_window", "name": "Base Wall with Window Frame", "cost": { "material_steel": 3, "material_polymer": 1 }, "result": { "id": "wall_window_item", "name": "Base Wall with Window Frame", "type": "furniture", "furnitureType": "wall_window", "count": 1, "weight": 5.0, "icon": "🖼️", "desc": "Steel wall module with window frame cutout" }, "desc": "Wall with window frame", "icon": "🖼️" },
		{ "id": "rec_wall_doorway", "name": "Base Wall with Doorway", "cost": { "material_steel": 3, "scrap": 2 }, "result": { "id": "wall_doorway_item", "name": "Base Wall with Doorway", "type": "furniture", "furnitureType": "wall_doorway", "count": 1, "weight": 5.0, "icon": "🚪", "desc": "Steel wall module with doorway cutout" }, "desc": "Wall with doorway cutout", "icon": "🚪" },
		{ "id": "rec_door", "name": "Steel Base Door", "cost": { "material_steel": 2, "scrap": 2 }, "result": { "id": "door_item", "name": "Steel Base Door", "type": "furniture", "furnitureType": "door", "count": 1, "weight": 4.0, "icon": "🚪", "desc": "Interactive hinged door on [E] fitting doorway wall" }, "desc": "Door for installation in doorway wall", "icon": "🚪" },
		{ "id": "rec_window_glass", "name": "Glass Window Pane", "cost": { "material_polymer": 2 }, "result": { "id": "window_glass_item", "name": "Glass Window Pane", "type": "furniture", "furnitureType": "window_glass", "count": 1, "weight": 1.5, "icon": "🪟", "desc": "Clear window pane fitting window frame wall" }, "desc": "Window glass for window frame wall", "icon": "🪟" },
		{ "id": "rec_battery", "name": "Lithium Battery (Power)", "cost": { "material_copper": 1, "scrap": 2 }, "result": { "id": "battery_item", "name": "Lithium Battery", "type": "battery", "count": 1, "weight": 0.2, "icon": "🔋", "desc": "Lithium battery for powering devices" }, "desc": "Lithium cell for electronic equipment", "icon": "🔋" },
		{ "id": "rec_flashlight", "name": "Tactical Flashlight", "cost": { "scrap": 4, "material_polymer": 1, "battery": 1 }, "result": { "id": "flashlight_item", "name": "Tactical Flashlight", "type": "flashlight", "count": 1, "weight": 0.6, "icon": "🔦", "desc": "Powerful tactical flashlight activated with [F]" }, "desc": "Requires 4x Scrap, 1x Polymer, 1x Battery", "icon": "🔦" }
	]

func _init_quests():
	quests = [
		{ "id": "q1", "title": "First Steps", "desc": "Collect 5 units of industrial scrap on the surface", "reward_gold": 100, "completed": false },
		{ "id": "q2", "title": "Clean Energy", "desc": "Activate the Isotope Generator in your base", "reward_gold": 250, "completed": false },
		{ "id": "q3", "title": "Mutant Hunt", "desc": "Eliminate the Heavy Martian Mutant", "reward_gold": 500, "completed": false }
	]

func get_max_inventory_slots() -> int:
	var slots = 20
	if equipment["backpack"]:
		slots += equipment["backpack"].get("extra_slots", 8)
	return slots

func get_max_carry_weight() -> float:
	var base_limit = 60.0
	if equipment["backpack"]:
		base_limit = equipment["backpack"].get("max_weight", 180.0)

	var art_effects = get_total_artifact_effects()
	base_limit += art_effects["carry_capacity"] - art_effects["weight_penalty"]
	return max(20.0, base_limit)

func get_total_inventory_weight() -> float:
	var total = 0.0
	for item in inventory:
		if item:
			total += get_item_unit_weight(item) * item.get("count", 1)
	return total

func get_item_unit_weight(item: Dictionary) -> float:
	return item.get("weight", 0.5)

func get_weight_percentage() -> float:
	var max_w = get_max_carry_weight()
	if max_w <= 0: return 100.0
	return (get_total_inventory_weight() / max_w) * 100.0

func has_gas_mask_protection() -> bool:
	return equipment["mask"] != null or equipment["helmet"] != null

func damage_suit(amount: float):
	player_stats.suit_integrity = max(0, player_stats.suit_integrity - int(amount))
	emit_signal("stats_changed")

func assign_to_hotbar(inventory_idx: int, hotbar_slot: int):
	if inventory_idx < 0 or inventory_idx >= inventory.size(): return
	var item = inventory[inventory_idx]
	hotbar[hotbar_slot] = item
	if SoundManager: SoundManager.play_pick()
	add_log("Hotbar", "Przypisano " + item.get("name", "") + " do slotu [" + str(hotbar_slot) + "]")
	emit_signal("inventory_changed")

func craft_recipe(recipe_id: String) -> bool:
	var recipe = null
	for r in crafting_recipes:
		if r["id"] == recipe_id:
			recipe = r; break
	if not recipe: return false

	var cost_dict = recipe["cost"]
	for mat in cost_dict.keys():
		var req = cost_dict[mat]
		var player_has = 0
		for item in inventory:
			if item and item.get("type") == mat:
				player_has += item.get("count", 1)
		if player_has < req:
			add_log("Rzemiosło", "⚠️ Missing material: " + mat)
			if SoundManager: SoundManager.play_hit()
			return false

	for mat in cost_dict.keys():
		var remaining = cost_dict[mat]
		var i = inventory.size() - 1
		while i >= 0 and remaining > 0:
			var item = inventory[i]
			if item and item.get("type") == mat:
				var count = item.get("count", 1)
				if count <= remaining:
					remaining -= count
					inventory.remove_at(i)
				else:
					item["count"] = count - remaining
					remaining = 0
			i -= 1

	var result_item = recipe["result"].duplicate()
	var res_type = result_item.get("type", "")
	if res_type == "ammo_std_pack":
		ammo_inventory["standard"] += 30
		if SoundManager: SoundManager.play_craft()
		add_log("Rzemiosło", "📦 Crafted: 30x Standard Ammo")
	elif res_type == "ammo_ap_pack":
		ammo_inventory["ap"] += 20
		if SoundManager: SoundManager.play_craft()
		add_log("Rzemiosło", "💥 Crafted: 20x Amunicja AP")
	elif res_type == "ammo_fire_pack":
		ammo_inventory["incendiary"] += 15
		if SoundManager: SoundManager.play_craft()
		add_log("Rzemiosło", "🔥 Crafted: 15x Incendiary Ammo")
	else:
		inventory.append(result_item)
		if SoundManager: SoundManager.play_craft()
		add_log("Rzemiosło", "🔨 Created: " + result_item.get("name", ""))

	emit_signal("inventory_changed")
	return true

func add_exp(amount: int):
	player_stats.exp += amount
	if player_stats.exp >= player_stats.level * 100:
		player_stats.exp -= player_stats.level * 100
		player_stats.level += 1
		player_stats.max_hp += 10
		player_stats.hp = player_stats.max_hp
		if SoundManager: SoundManager.play_level_up()
		add_log("Awans", "🎉 LEVELED UP TO LEVEL " + str(player_stats.level) + "! Max HP increased.")
	emit_signal("stats_changed")

func add_log(category: String, message: String):
	emit_signal("log_added", category, message)

func has_item_type(type_name: String) -> bool:
	for item in inventory:
		if item and item.get("type") == type_name: return true
	return false

func cycle_ammo_type(hotbar_slot: int):
	var item = hotbar.get(hotbar_slot)
	if not item or item.get("type") != "weapon": return
	var current = item.get("ammo_type", "standard")
	var types = ["standard", "ap", "incendiary"]
	var next_idx = (types.find(current) + 1) % types.size()
	item["ammo_type"] = types[next_idx]
	if SoundManager: SoundManager.play_pick()
	add_log("Amunicja", "Przełączono typ amunicji na: " + item["ammo_type"].to_upper())
	emit_signal("inventory_changed")
