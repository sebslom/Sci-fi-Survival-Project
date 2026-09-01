extends Node3D

@export var max_enemy_count: int = 8
@export var spawn_radius: float = 80.0

func _ready():
	add_to_group("expedition_spawner")
	call_deferred("_spawn_random_expedition_enemies")

func _spawn_random_expedition_enemies():
	var seed_val = GameManager.current_expedition_seed if GameManager else 1337
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val

	var enemy_script = load("res://scripts/Enemy.gd")
	if not enemy_script: return

	var enemy_types = ["bug", "tur", "bandit_scout", "bandit_assault", "bandit_heavy", "slime"]
	
	for i in range(max_enemy_count):
		var rx = rng.randf_range(-spawn_radius, spawn_radius)
		var rz = rng.randf_range(-spawn_radius, spawn_radius)
		# Keep away from safe spawn zone near (20, 20)
		if Vector2(rx, rz).length() < 15.0:
			rx += 25.0; rz += 25.0

		var spawn_pos = Vector3(20.0 + rx, 1.2, 20.0 + rz)
		var etype = enemy_types[rng.randi() % enemy_types.size()]

		var enemy_node = CharacterBody3D.new()
		enemy_node.set_script(enemy_script)
		enemy_node.enemy_type = etype

		# Visual Mesh
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.name = "MeshInstance"
		var capsule = CapsuleMesh.new()
		capsule.radius = 0.6; capsule.height = 1.8
		mesh_inst.mesh = capsule

		var mat = StandardMaterial3D.new()
		if etype == "bug": mat.albedo_color = Color("#a855f7") # Purple Bug
		elif etype == "tur": mat.albedo_color = Color("#d97706") # Amber Beast
		elif etype == "slime": mat.albedo_color = Color("#10b981") # Toxic Slime
		else: mat.albedo_color = Color("#ef4444") # Red Bandit
		mat.metallic = 0.3; mat.roughness = 0.5
		mesh_inst.material_override = mat
		enemy_node.add_child(mesh_inst)

		# Collision Shape
		var col = CollisionShape3D.new()
		var col_shape = CapsuleShape3D.new()
		col_shape.radius = 0.6; col_shape.height = 1.8
		col.shape = col_shape
		enemy_node.add_child(col)

		add_child(enemy_node)
		enemy_node.global_position = spawn_pos

	# Spawn Rusty Reaper mechs (Rdzawy Żniwiarz)
	var reaper_script = load("res://scripts/RustyReaper.gd")
	if reaper_script:
		for j in range(2):
			var r_rx = rng.randf_range(-spawn_radius * 0.7, spawn_radius * 0.7)
			var r_rz = rng.randf_range(-spawn_radius * 0.7, spawn_radius * 0.7)
			var r_pos = Vector3(20.0 + r_rx, 1.4, 20.0 + r_rz)

			var reaper = CharacterBody3D.new()
			reaper.set_script(reaper_script)

			var rmesh = MeshInstance3D.new()
			var rbox = BoxMesh.new(); rbox.size = Vector3(1.8, 2.2, 1.8)
			rmesh.mesh = rbox
			var rmat = StandardMaterial3D.new()
			rmat.albedo_color = Color("#c2410c") # Rusty Orange
			rmat.metallic = 0.8; rmat.roughness = 0.4
			rmesh.material_override = rmat
			reaper.add_child(rmesh)

			# Back Core Mesh (Weak Point!)
			var bcore = MeshInstance3D.new()
			bcore.name = "BackCoreMesh"
			var csphere = SphereMesh.new(); csphere.radius = 0.45; csphere.height = 0.9
			bcore.mesh = csphere
			bcore.transform.origin = Vector3(0, 0.2, 1.0)
			var bcmat = StandardMaterial3D.new()
			bcmat.albedo_color = Color("#00f3ff")
			bcmat.emission_enabled = true; bcmat.emission = Color("#00f3ff"); bcmat.emission_energy_multiplier = 3.0
			bcore.material_override = bcmat
			reaper.add_child(bcore)

			var rcol = CollisionShape3D.new()
			var rcol_shape = BoxShape3D.new(); rcol_shape.size = Vector3(1.8, 2.2, 1.8)
			rcol.shape = rcol_shape
			reaper.add_child(rcol)

			var rlbl = Label3D.new()
			rlbl.name = "Label3D"
			rlbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			rlbl.position = Vector3(0, 1.6, 0)
			rlbl.modulate = Color("#c2410c")
			reaper.add_child(rlbl)

			add_child(reaper)
			reaper.global_position = r_pos

	# Spawn Martian Jumpers (Marsjański Skakun)
	var jumper_script = load("res://scripts/MartianJumper.gd")
	if jumper_script:
		for k in range(3):
			var j_rx = rng.randf_range(-spawn_radius * 0.8, spawn_radius * 0.8)
			var j_rz = rng.randf_range(-spawn_radius * 0.8, spawn_radius * 0.8)
			var j_pos = Vector3(20.0 + j_rx, 1.2, 20.0 + j_rz)

			var jumper = CharacterBody3D.new()
			jumper.set_script(jumper_script)

			var jmesh = MeshInstance3D.new()
			var jprism = PrismMesh.new(); jprism.size = Vector3(1.2, 0.9, 1.6)
			jmesh.mesh = jprism
			var jmat = StandardMaterial3D.new()
			jmat.albedo_color = Color("#92400e") # Regolith Sand Brown
			jmat.roughness = 0.8
			jmesh.material_override = jmat
			jumper.add_child(jmesh)

			var jcol = CollisionShape3D.new()
			var jcol_shape = BoxShape3D.new(); jcol_shape.size = Vector3(1.2, 0.9, 1.6)
			jcol.shape = jcol_shape
			jumper.add_child(jcol)

			var jlbl = Label3D.new()
			jlbl.name = "Label3D"
			jlbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			jlbl.position = Vector3(0, 1.2, 0)
			jlbl.modulate = Color("#92400e")
			jumper.add_child(jlbl)

			add_child(jumper)
			jumper.global_position = j_pos

	if GameManager:
		GameManager.add_log("Ekspedycja", "👾 ZESPAWNOWANO PRZECIWNIKÓW, ŻNIWIARZY I SKAKUNÓW MARSJAŃSKICH (Seed #" + str(seed_val) + ")")
