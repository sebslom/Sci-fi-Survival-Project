extends Node3D

@onready var exit_portal = get_node_or_null("AirlockPortal")
@onready var boss_node = get_node_or_null("BossArena/CloneBoss")
@onready var minion_spawns = get_node_or_null("IncubationSector")

var portal_col_shape: CollisionShape3D = null

func _ready():
	_setup_locked_exit_portal()
	_spawn_clone_minions()
	_connect_boss_signals()

func _setup_locked_exit_portal():
	if exit_portal:
		portal_col_shape = exit_portal.get_node_or_null("CollisionShape3D") as CollisionShape3D
		
		# Lock exit portal on start (hide and disable collision)
		exit_portal.visible = false
		if portal_col_shape:
			portal_col_shape.disabled = true

		if GameManager:
			GameManager.add_log("Misja", "🔒 DROGA UCIECZKI ZABROKOWANA! Pokonaj Nadzorcę Klonów ALPHA, aby odblokować Portal Powrotny!")

func _spawn_clone_minions():
	var minion_script = load("res://scripts/CloneMinion.gd")
	var defect_script = load("res://scripts/CloneDefect.gd")

	var squads = [
		{"pos": Vector3(12, 1.2, 18), "type": "scout", "color": Color("#10b981")},
		{"pos": Vector3(25, 1.2, 20), "type": "assault", "color": Color("#00f3ff")},
		{"pos": Vector3(38, 1.2, 20), "type": "assault", "color": Color("#00f3ff")},
		{"pos": Vector3(25, 1.2, 32), "type": "heavy", "color": Color("#dc2626")}
	]
	
	for s_info in squads:
		var minion = CharacterBody3D.new()
		minion.set_script(minion_script)
		minion.clone_type = s_info["type"]
		minion.global_position = s_info["pos"]

		# Minion Visual Mesh
		var mesh_inst = MeshInstance3D.new()
		var capsule = CapsuleMesh.new()
		capsule.radius = 0.5; capsule.height = 1.8
		mesh_inst.mesh = capsule

		var mat = StandardMaterial3D.new()
		mat.albedo_color = s_info["color"]
		mat.emission_enabled = true; mat.emission = s_info["color"]; mat.emission_energy_multiplier = 0.8
		mesh_inst.material_override = mat
		minion.add_child(mesh_inst)

		# Collision Shape
		var col = CollisionShape3D.new()
		var col_capsule = CapsuleShape3D.new()
		col_capsule.radius = 0.5; col_capsule.height = 1.8
		col.shape = col_capsule
		minion.add_child(col)

		# Muzzle Light
		var m_light = OmniLight3D.new()
		m_light.name = "MuzzleLight"
		m_light.light_color = s_info["color"]
		m_light.light_energy = 3.0
		m_light.visible = false
		minion.add_child(m_light)

		# Label 3D
		var lbl = Label3D.new()
		lbl.name = "Label3D"
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position = Vector3(0, 1.4, 0)
		lbl.modulate = s_info["color"]
		minion.add_child(lbl)

		add_child(minion)

	# Spawn Explosive Clone Defects (Odrzut)
	var defect_positions = [Vector3(18, 1.2, 28), Vector3(32, 1.2, 28)]
	for dpos in defect_positions:
		var defect = CharacterBody3D.new()
		defect.set_script(defect_script)
		defect.global_position = dpos

		var dmesh = MeshInstance3D.new()
		var dcapsule = CapsuleMesh.new()
		dcapsule.radius = 0.55; dcapsule.height = 1.6
		dmesh.mesh = dcapsule

		var dmat = StandardMaterial3D.new()
		dmat.albedo_color = Color("#ec4899") # Unstable Toxic Magenta
		dmat.emission_enabled = true; dmat.emission = Color("#ec4899"); dmat.emission_energy_multiplier = 2.0
		dmesh.material_override = dmat
		defect.add_child(dmesh)

		var dcol = CollisionShape3D.new()
		var dcol_shape = CapsuleShape3D.new()
		dcol_shape.radius = 0.55; dcol_shape.height = 1.6
		dcol.shape = dcol_shape
		defect.add_child(dcol)

		var dlbl = Label3D.new()
		dlbl.name = "Label3D"
		dlbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		dlbl.position = Vector3(0, 1.4, 0)
		dlbl.modulate = Color("#ec4899")
		defect.add_child(dlbl)

		add_child(defect)

	# Spawn Clone Shield Sentry (Klon Strażniczy z Tarczną)
	var shield_script = load("res://scripts/CloneShieldSentry.gd")
	var shield_sentry = CharacterBody3D.new()
	shield_sentry.set_script(shield_script)
	shield_sentry.global_position = Vector3(25, 1.2, 40)

	var smesh = MeshInstance3D.new()
	var scapsule = CapsuleMesh.new()
	scapsule.radius = 0.6; scapsule.height = 2.0
	smesh.mesh = scapsule
	var smat = StandardMaterial3D.new()
	smat.albedo_color = Color("#eab308") # Golden Shield Armor
	smat.metallic = 0.9; smat.roughness = 0.2
	smesh.material_override = smat
	shield_sentry.add_child(smesh)

	# Shield Mesh Attachment
	var shield_box = MeshInstance3D.new()
	shield_box.name = "ShieldMesh"
	var box_m = BoxMesh.new(); box_m.size = Vector3(1.4, 1.8, 0.2)
	shield_box.mesh = box_m
	shield_box.transform.origin = Vector3(0, 0, -0.6)
	var sh_mat = StandardMaterial3D.new()
	sh_mat.albedo_color = Color("#f59e0b"); sh_mat.metallic = 0.9
	shield_box.material_override = sh_mat
	shield_sentry.add_child(shield_box)

	var scol = CollisionShape3D.new()
	var scol_shape = CapsuleShape3D.new(); scol_shape.radius = 0.6; scol_shape.height = 2.0
	scol.shape = scol_shape
	shield_sentry.add_child(scol)

	var slbl = Label3D.new()
	slbl.name = "Label3D"
	slbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	slbl.position = Vector3(0, 1.5, 0)
	slbl.modulate = Color("#eab308")
	shield_sentry.add_child(slbl)

	add_child(shield_sentry)

func _connect_boss_signals():
	if boss_node:
		boss_node.tree_exited.connect(_on_boss_defeated)

func _on_boss_defeated():
	if exit_portal:
		exit_portal.visible = true
		if portal_col_shape:
			portal_col_shape.disabled = false

		if SoundManager:
			SoundManager.play_level_up()

		if GameManager:
			GameManager.add_log("Zwycięstwo", "🏆 BOSS POKONANY! Portal Powrotny do Schronu Bazy został odblokowany [E]! 🚀")
