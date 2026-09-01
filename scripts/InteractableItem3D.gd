extends RigidBody3D

@export var item_data: Dictionary = {}

@onready var mesh_instance: MeshInstance3D = get_node_or_null("MeshInstance3D")
@onready var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")

func _ready():
	add_to_group("interactable")
	add_to_group("interactive")
	add_to_group("physical_item")
	
	mass = 1.5
	contact_monitor = true
	max_contacts_reported = 4
	
	_setup_visual_and_collision()

func setup_item(data: Dictionary):
	item_data = data.duplicate(true)
	_setup_visual_and_collision()

func _setup_visual_and_collision():
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		add_child(mesh_instance)
		
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		add_child(collision_shape)

	var itype = item_data.get("type", "scrap")
	var iid = item_data.get("id", "")

	var mat = StandardMaterial3D.new()
	var shape_mesh: Mesh = null
	var col_shape: Shape3D = null

	if itype == "scrap" or itype == "scrap_metal" or iid == "scrap":
		var box = BoxMesh.new(); box.size = Vector3(0.4, 0.25, 0.4)
		shape_mesh = box
		var cbox = BoxShape3D.new(); cbox.size = box.size
		col_shape = cbox
		mat.albedo_color = Color("#94a3b8")
		mat.metallic = 0.85; mat.roughness = 0.3
	elif itype == "material_copper" or iid == "material_copper":
		var box = BoxMesh.new(); box.size = Vector3(0.35, 0.2, 0.35)
		shape_mesh = box
		var cbox = BoxShape3D.new(); cbox.size = box.size
		col_shape = cbox
		mat.albedo_color = Color("#b45309")
		mat.metallic = 0.9; mat.roughness = 0.2
	elif itype == "material_steel" or iid == "material_steel":
		var box = BoxMesh.new(); box.size = Vector3(0.5, 0.2, 0.3)
		shape_mesh = box
		var cbox = BoxShape3D.new(); cbox.size = box.size
		col_shape = cbox
		mat.albedo_color = Color("#475569")
		mat.metallic = 0.9; mat.roughness = 0.25
	elif itype == "material_polymer" or iid == "material_polymer":
		var sph = SphereMesh.new(); sph.radius = 0.2; sph.height = 0.4
		shape_mesh = sph
		var csph = SphereShape3D.new(); csph.radius = 0.2
		col_shape = csph
		mat.albedo_color = Color("#0284c7")
		mat.roughness = 0.1; mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat.albedo_color.a = 0.85
	elif itype == "battery" or iid == "battery":
		var cyl = CylinderMesh.new(); cyl.top_radius = 0.12; cyl.bottom_radius = 0.12; cyl.height = 0.45
		shape_mesh = cyl
		var ccyl = CylinderShape3D.new(); ccyl.radius = 0.12; ccyl.height = 0.45
		col_shape = ccyl
		mat.albedo_color = Color("#22c55e")
		mat.emission_enabled = true; mat.emission = Color("#22c55e"); mat.emission_energy_multiplier = 0.5
	elif itype in ["weapon", "melee"]:
		var box = BoxMesh.new(); box.size = Vector3(0.6, 0.18, 0.25)
		shape_mesh = box
		var cbox = BoxShape3D.new(); cbox.size = box.size
		col_shape = cbox
		mat.albedo_color = Color("#1e293b")
		mat.metallic = 0.8; mat.roughness = 0.4
	elif iid == "military_crate_item" or itype == "military_crate_item":
		var box = BoxMesh.new(); box.size = Vector3(0.8, 0.6, 0.8)
		shape_mesh = box
		var cbox = BoxShape3D.new(); cbox.size = box.size
		col_shape = cbox
		mat.albedo_color = Color("#0f766e")
		mat.metallic = 0.6; mat.roughness = 0.4
	else:
		var box = BoxMesh.new(); box.size = Vector3(0.35, 0.35, 0.35)
		shape_mesh = box
		var cbox = BoxShape3D.new(); cbox.size = box.size
		col_shape = cbox
		mat.albedo_color = Color("#f59e0b")
		mat.roughness = 0.5

	mesh_instance.mesh = shape_mesh
	mesh_instance.material_override = mat
	collision_shape.shape = col_shape

func get_interaction_prompt() -> String:
	var iname = item_data.get("name", "Przedmiot")
	var count = item_data.get("count", 1)
	if count > 1:
		return "[E] Podnieś: %s (x%d)" % [iname, count]
	return "[E] Podnieś: %s" % iname

func interact(player_node = null):
	if not GameManager: return
	if item_data.is_empty():
		queue_free()
		return

	var success = GameManager.add_item_to_inventory(item_data)
	if success:
		if SoundManager: SoundManager.play_pick()
		var iname = item_data.get("name", "Przedmiot")
		var count = item_data.get("count", 1)
		GameManager.add_log("Podnoszenie", "🎒 Podniesiono: %s%s" % [iname, (" (x" + str(count) + ")") if count > 1 else ""])
		queue_free()
	else:
		if SoundManager: SoundManager.play_hit()
		GameManager.add_log("Ekwipunek", "⚠️ Ekwipunek jest pełny! Brak miejsca w plecaku.")
