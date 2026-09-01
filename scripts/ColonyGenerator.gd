extends Node3D

@export var building_count: int = 16
@export var bandit_camp_count: int = 6
@export var crystal_cluster_count: int = 8
@export var anomaly_field_count: int = 5
@export var chest_count: int = 12
@export var enemy_count: int = 20

const PREFAB_BANDIT_CAMP = preload("res://scenes/prefabs/BanditCampPrefab.tscn")
const PREFAB_CRYSTAL_CLUSTER = preload("res://scenes/prefabs/CrystalClusterPrefab.tscn")
const PREFAB_ANOMALY_FIELD = preload("res://scenes/prefabs/AnomalyFieldPrefab.tscn")

func _ready():
	_generate_abandoned_colony()

func generate_with_seed(p_seed: int):
	seed(p_seed)
	_generate_abandoned_colony()

func _generate_abandoned_colony():
	# Clear previous generated children
	for child in get_children():
		child.queue_free()

	# Seed procedural generator with active GameManager Expedition Seed
	seed(GameManager.current_expedition_seed)

	# 1. Deterministic Placement of Modular Bandit Camps
	for i in range(bandit_camp_count):
		var pos = Vector3(randf_range(-170.0, 170.0), 0.0, randf_range(-170.0, 170.0))
		var camp = PREFAB_BANDIT_CAMP.instantiate()
		add_child(camp)
		camp.global_position = pos

	# 2. Deterministic Placement of Modular Crystal Clusters
	for i in range(crystal_cluster_count):
		var pos = Vector3(randf_range(-170.0, 170.0), 0.0, randf_range(-170.0, 170.0))
		var cluster = PREFAB_CRYSTAL_CLUSTER.instantiate()
		add_child(cluster)
		cluster.global_position = pos

	# 3. Deterministic Placement of Modular Anomaly Fields
	for i in range(anomaly_field_count):
		var pos = Vector3(randf_range(-170.0, 170.0), 0.0, randf_range(-170.0, 170.0))
		var anomaly = PREFAB_ANOMALY_FIELD.instantiate()
		add_child(anomaly)
		anomaly.global_position = pos

	# 4. Procedural Placement of Ruined Colony Structures & Labs
	for i in range(building_count):
		var pos = Vector3(randf_range(-180.0, 180.0), 0.7, randf_range(-180.0, 180.0))
		_spawn_ruined_hab(pos)

	# 5. Spawn Standalone Rare Loot Chests
	for i in range(chest_count):
		var pos = Vector3(randf_range(-170.0, 170.0), 0.7, randf_range(-170.0, 170.0))
		_spawn_loot_chest(pos)

	# 6. Spawn Enemy Patrol Squads
	for i in range(enemy_count):
		var pos = Vector3(randf_range(-180.0, 180.0), 0.5, randf_range(-180.0, 180.0))
		_spawn_colony_enemy(pos)

func _spawn_ruined_hab(pos: Vector3):
	var hab = StaticBody3D.new()
	var mesh_inst = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(6.0, 3.5, 6.0)
	mesh_inst.mesh = box_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("#334155")
	mesh_inst.material_override = mat
	hab.add_child(mesh_inst)

	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(6.0, 3.5, 6.0)
	col.shape = box_shape
	hab.add_child(col)

	add_child(hab)
	hab.global_position = pos

func _spawn_loot_chest(pos: Vector3):
	var chest = StaticBody3D.new()
	chest.set_script(load("res://scripts/LootChest.gd"))

	var mesh_inst = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1.2, 1.0, 1.2)
	mesh_inst.mesh = box_mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("#f59e0b")
	mat.emission_enabled = true
	mat.emission = Color("#f59e0b")
	mat.emission_energy_multiplier = 0.5
	mesh_inst.material_override = mat
	chest.add_child(mesh_inst)

	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(1.2, 1.0, 1.2)
	col.shape = box_shape
	chest.add_child(col)

	add_child(chest)
	chest.global_position = pos

func _spawn_colony_enemy(pos: Vector3):
	var enemy_script = load("res://scripts/Enemy.gd")
	var enemy = CharacterBody3D.new()
	enemy.set_script(enemy_script)
	
	var types = ["spec_ops", "bandit_heavy", "bandit_assault", "tur"]
	var selected_type = types[randi() % types.size()]
	enemy.set("enemy_type", selected_type)
	
	var mesh = MeshInstance3D.new()
	var box = CapsuleMesh.new()
	box.radius = 0.5
	box.height = 1.8
	mesh.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("#ef4444")
	mesh.material_override = mat
	enemy.add_child(mesh)
	
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.5
	cap.height = 1.8
	col.shape = cap
	enemy.add_child(col)
	
	add_child(enemy)
	enemy.global_position = pos
