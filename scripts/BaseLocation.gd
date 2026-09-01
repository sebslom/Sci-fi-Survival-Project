class_name BaseLocation
extends Node3D

@export var map_name = "Wyprawa Obca"
@export var map_size = Vector2i(120, 120)
@export var tile_size = 2.0

var prefabs = [
	"res://scenes/prefabs/BanditCampPrefab.tscn",
	"res://scenes/prefabs/BossArenaPrefab.tscn",
	"res://scenes/prefabs/CraterPrefab.tscn",
	"res://scenes/prefabs/MilitaryBasePrefab.tscn",
	"res://scenes/prefabs/CrystalClusterPrefab.tscn"
]

func _ready():
	generate_expedition_world()

func generate_expedition_world():
	var prefabs_container = Node3D.new()
	prefabs_container.name = "ProceduralPrefabs"
	add_child(prefabs_container)

	# Place 10+ modular puzzle prefabs across the 120x120 map
	for i in range(12):
		var prefab_path = prefabs[i % prefabs.size()]
		if ResourceLoader.exists(prefab_path):
			var packed = load(prefab_path)
			if packed:
				var inst = packed.instantiate()
				var px = randf_range(15.0, (map_size.x * tile_size) - 15.0)
				var pz = randf_range(15.0, (map_size.y * tile_size) - 15.0)
				inst.global_position = Vector3(px, 0.0, pz)
				prefabs_container.add_child(inst)

	# Spawn wild alien bugs & turs roaming randomly across the wilderness
	var wild_container = Node3D.new()
	wild_container.name = "WildAlienFauna"
	add_child(wild_container)

	var enemy_script = load("res://scripts/Enemy.gd")
	for i in range(15):
		var bug = CharacterBody3D.new()
		bug.set_script(enemy_script)
		bug.enemy_type = "bug"
		
		var mesh_inst = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.8, 0.6, 0.8)
		mesh_inst.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color("#22c55e")
		mesh_inst.material_override = mat
		bug.add_child(mesh_inst)

		var col = CollisionShape3D.new()
		var bshape = BoxShape3D.new()
		bshape.size = Vector3(0.8, 0.6, 0.8)
		col.shape = bshape
		bug.add_child(col)

		bug.global_position = Vector3(randf_range(10, 220), 0.4, randf_range(10, 220))
		wild_container.add_child(bug)

	for i in range(8):
		var tur = CharacterBody3D.new()
		tur.set_script(enemy_script)
		tur.enemy_type = "tur"

		var mesh_inst = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(1.6, 1.4, 1.6)
		mesh_inst.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color("#b45309")
		mesh_inst.material_override = mat
		tur.add_child(mesh_inst)

		var col = CollisionShape3D.new()
		var bshape = BoxShape3D.new()
		bshape.size = Vector3(1.6, 1.4, 1.6)
		col.shape = bshape
		tur.add_child(col)

		tur.global_position = Vector3(randf_range(15, 210), 0.7, randf_range(15, 210))
		wild_container.add_child(tur)
