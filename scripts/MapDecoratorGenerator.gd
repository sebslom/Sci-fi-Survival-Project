extends Node3D

@export var map_radius: float = 180.0
@export var mountain_count: int = 14
@export var wreck_count: int = 8
@export var rock_count: int = 25
@export var crate_count: int = 12
@export var scrap_count: int = 20
@export var flora_count: int = 18

func _ready():
	add_to_group("map_decorator")
	call_deferred("_generate_procedural_environment_assets")

func _generate_procedural_environment_assets():
	var seed_val = GameManager.current_expedition_seed if GameManager else 1337
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val

	# 1. 🏔️ Góry i Skalne Filary (Mountains & Rock Pillars)
	for i in range(mountain_count):
		var pos = _get_random_valid_pos(rng, map_radius * 0.9, 30.0)
		_spawn_mountain_placeholder(rng, pos)

	# 2. 🛸 Wraki Maszyn i Łazików (Machine Wrecks & Crashed Hull Parts)
	for i in range(wreck_count):
		var pos = _get_random_valid_pos(rng, map_radius * 0.85, 20.0)
		_spawn_wreck_placeholder(rng, pos)

	# 3. 🪨 Kamienie i Głazy (Boulders & Rocks)
	for i in range(rock_count):
		var pos = _get_random_valid_pos(rng, map_radius * 0.95, 10.0)
		_spawn_rock_placeholder(rng, pos)

	# 4. 📦 Skrzynie i Kontenery Zapasów (Cargo Crates & Drums)
	for i in range(crate_count):
		var pos = _get_random_valid_pos(rng, map_radius * 0.8, 15.0)
		_spawn_crate_placeholder(rng, pos)

	# 5. 🗑️ Fizyczny Scrap i Materiały na Ziemi (Physical Items & Materials Drop)
	_spawn_physical_world_loot(rng, seed_val)

	# 6. 🌿 Bioluminescencyjna Roślinność Kosmiczna (Alien Flora & Fungi)
	for i in range(flora_count):
		var pos = _get_random_valid_pos(rng, map_radius * 0.85, 12.0)
		_spawn_flora_placeholder(rng, pos)

	if GameManager:
		GameManager.add_log("Environment", "🏔️ GENERATED WORLD ASSETS AND PHYSICAL ITEM LOOT (Seed #" + str(seed_val) + "]")

func _spawn_physical_world_loot(rng: RandomNumberGenerator, seed_val: int):
	var item_scene = load("res://scenes/prefabs/InteractableItem3D.tscn")
	var chest_scene = load("res://scenes/prefabs/StorageChest.tscn")

	# 1. Spawn 35-50 Physical InteractableItem3D Ground Drops
	var physical_items_pool = [
		{ "id": "scrap", "name": "Industrial Scrap", "type": "scrap", "count": 1, "weight": 0.5, "icon": "⚙️", "desc": "Podstawowy surowiec do rzemiosła i budowania" },
		{ "id": "material_copper", "name": "Copper Ore", "type": "material_copper", "count": 1, "weight": 0.6, "icon": "🟧", "desc": "Copper przemysłowa pod przewodniki i elektronikę" },
		{ "id": "material_steel", "name": "Steel Bar", "type": "material_steel", "count": 1, "weight": 1.2, "icon": "⬛", "desc": "Wytrzymały stop stali konstrukcyjnej" },
		{ "id": "material_polymer", "name": "Synthetic Polymer", "type": "material_polymer", "count": 1, "weight": 0.4, "icon": "🧪", "desc": "Lekkie tworzywo sztuczne do skafandrów i narzędzi" },
		{ "id": "battery", "name": "Lithium Battery", "type": "battery", "count": 1, "weight": 0.3, "icon": "🔋", "desc": "Zasilanie urządzeń elektronicznych i latarki" },
		{ "id": "crystal", "name": "Anomaly Crystal", "type": "crystal", "count": 1, "weight": 0.8, "icon": "🔮", "desc": "Rzadki kryształ podprzestrzenny" }
	]

	var total_items = rng.randi_range(35, 50)
	for i in range(total_items):
		var pos = _get_random_valid_pos(rng, map_radius * 0.88, 8.0)
		pos.y = 0.5
		if item_scene:
			var item_inst = item_scene.instantiate()
			var template = physical_items_pool[rng.randi() % physical_items_pool.size()]
			var idata = template.duplicate(true)
			if idata["type"] == "scrap":
				idata["count"] = rng.randi_range(1, 3)
			item_inst.set("item_data", idata)
			add_child(item_inst)
			item_inst.global_position = pos

	# 2. Spawn 6-10 Physical Storage Chests with pre-filled loot
	if chest_scene:
		var total_chests = rng.randi_range(6, 10)
		for c in range(total_chests):
			var pos = _get_random_valid_pos(rng, map_radius * 0.8, 12.0)
			pos.y = 0.0
			var chest_inst = chest_scene.instantiate()
			add_child(chest_inst)
			chest_inst.global_position = pos
			
			# Pre-fill chest inventory
			var stored = []
			var loot_count = rng.randi_range(2, 5)
			for l in range(loot_count):
				var template = physical_items_pool[rng.randi() % physical_items_pool.size()].duplicate(true)
				stored.append(template)
			chest_inst.set("stored_items", stored)

func _get_random_valid_pos(rng: RandomNumberGenerator, radius: float, safe_dist: float) -> Vector3:
	var rx = rng.randf_range(-radius, radius)
	var rz = rng.randf_range(-radius, radius)
	if Vector2(rx, rz).length() < safe_dist:
		rx += safe_dist + 15.0; rz += safe_dist + 15.0
	return Vector3(20.0 + rx, 0.0, 20.0 + rz)

func _spawn_mountain_placeholder(rng: RandomNumberGenerator, pos: Vector3):
	var body = StaticBody3D.new()
	var mesh_inst = MeshInstance3D.new()
	
	var width = rng.randf_range(12.0, 24.0)
	var height = rng.randf_range(14.0, 32.0)
	var depth = rng.randf_range(12.0, 24.0)

	var pmesh = PrismMesh.new()
	pmesh.size = Vector3(width, height, depth)
	mesh_inst.mesh = pmesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("#451a03") if rng.randf() > 0.4 else Color("#1e293b")
	mat.roughness = 0.95
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	var col = CollisionShape3D.new()
	var cshape = BoxShape3D.new()
	cshape.size = Vector3(width * 0.8, height, depth * 0.8)
	col.shape = cshape
	body.add_child(col)

	add_child(body)
	body.global_position = pos + Vector3(0, height * 0.5, 0)
	body.rotation_degrees.y = rng.randf_range(0.0, 360.0)

func _spawn_wreck_placeholder(rng: RandomNumberGenerator, pos: Vector3):
	var body = StaticBody3D.new()
	var mesh_inst = MeshInstance3D.new()
	
	var cmesh = CylinderMesh.new()
	cmesh.top_radius = rng.randf_range(1.5, 3.0)
	cmesh.bottom_radius = rng.randf_range(2.0, 4.0)
	cmesh.height = rng.randf_range(4.0, 8.0)
	mesh_inst.mesh = cmesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("#9a3412") # Rusty Hull Metallic
	mat.metallic = 0.85; mat.roughness = 0.4
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	var col = CollisionShape3D.new()
	var cshape = CylinderShape3D.new()
	cshape.radius = cmesh.top_radius; cshape.height = cmesh.height
	col.shape = cshape
	body.add_child(col)

	# Label indicator
	var lbl = Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0, cmesh.height * 0.6, 0)
	lbl.text = "🛸 [WRAK MASZYNY]"
	lbl.modulate = Color("#f97316")
	body.add_child(lbl)

	add_child(body)
	body.global_position = pos + Vector3(0, cmesh.height * 0.4, 0)
	body.rotation_degrees = Vector3(rng.randf_range(-15, 15), rng.randf_range(0, 360), rng.randf_range(-25, 25))

func _spawn_rock_placeholder(rng: RandomNumberGenerator, pos: Vector3):
	var body = StaticBody3D.new()
	var mesh_inst = MeshInstance3D.new()
	
	var bmesh = BoxMesh.new()
	var sz = Vector3(rng.randf_range(1.5, 4.5), rng.randf_range(1.0, 3.0), rng.randf_range(1.5, 4.5))
	bmesh.size = sz
	mesh_inst.mesh = bmesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("#78350f") # Martian Rock Red
	mat.roughness = 0.9
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	var col = CollisionShape3D.new()
	var cshape = BoxShape3D.new(); cshape.size = sz
	col.shape = cshape
	body.add_child(col)

	add_child(body)
	body.global_position = pos + Vector3(0, sz.y * 0.5, 0)
	body.rotation_degrees = Vector3(rng.randf_range(-10, 10), rng.randf_range(0, 360), rng.randf_range(-10, 10))

func _spawn_crate_placeholder(rng: RandomNumberGenerator, pos: Vector3):
	var body = StaticBody3D.new()
	var mesh_inst = MeshInstance3D.new()
	
	var bmesh = BoxMesh.new()
	bmesh.size = Vector3(1.6, 1.4, 1.6)
	mesh_inst.mesh = bmesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("#f59e0b") if rng.randf() > 0.5 else Color("#0284c7") # Supply Box Colors
	mat.roughness = 0.4
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	var col = CollisionShape3D.new()
	var cshape = BoxShape3D.new(); cshape.size = bmesh.size
	col.shape = cshape
	body.add_child(col)

	# Label indicator
	var lbl = Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0, 1.2, 0)
	lbl.text = "📦 [SKRZYNIA]"
	lbl.modulate = Color("#f59e0b")
	body.add_child(lbl)

	add_child(body)
	body.global_position = pos + Vector3(0, 0.7, 0)
	body.rotation_degrees.y = rng.randf_range(0.0, 360.0)

func _spawn_scrap_placeholder(rng: RandomNumberGenerator, pos: Vector3):
	var body = StaticBody3D.new()
	var mesh_inst = MeshInstance3D.new()
	
	var bmesh = BoxMesh.new()
	var sz = Vector3(rng.randf_range(0.8, 2.0), 0.3, rng.randf_range(0.8, 2.0))
	bmesh.size = sz
	mesh_inst.mesh = bmesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("#334155") # Dark Scrap Metal
	mat.metallic = 0.75; mat.roughness = 0.5
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	var col = CollisionShape3D.new()
	var cshape = BoxShape3D.new(); cshape.size = sz
	col.shape = cshape
	body.add_child(col)

	add_child(body)
	body.global_position = pos + Vector3(0, 0.15, 0)
	body.rotation_degrees.y = rng.randf_range(0.0, 360.0)

func _spawn_flora_placeholder(rng: RandomNumberGenerator, pos: Vector3):
	var body = Node3D.new()
	var mesh_inst = MeshInstance3D.new()
	
	var cmesh = CylinderMesh.new()
	cmesh.top_radius = 0.8; cmesh.bottom_radius = 0.2; cmesh.height = rng.randf_range(1.5, 3.5)
	mesh_inst.mesh = cmesh

	var mat = StandardMaterial3D.new()
	var is_cyan = rng.randf() > 0.5
	var color = Color("#00f3ff") if is_cyan else Color("#ec4899")
	mat.albedo_color = color
	mat.emission_enabled = true; mat.emission = color; mat.emission_energy_multiplier = 2.5
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	var lbl = Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0, cmesh.height * 0.6, 0)
	lbl.text = "🌿 [ROŚLINNOŚĆ KOSMICZNA]"
	lbl.modulate = color
	body.add_child(lbl)

	add_child(body)
	body.global_position = pos + Vector3(0, cmesh.height * 0.5, 0)
