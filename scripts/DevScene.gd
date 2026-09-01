extends Node3D

@onready var map_builder = $MapBuilder
@onready var spawner_container = $Spawners

var is_god_mode: bool = false
var healing_timer: float = 0.0
var damage_timer: float = 0.0

func _ready():
	reset_dev_scene()

func reset_dev_scene():
	GameManager.player_stats.hp = GameManager.player_stats.max_hp
	GameManager.player_stats.hunger = 100
	GameManager.player_stats.thirst = 100
	GameManager.add_log("Dev", "🛠️ Loaded Dev Scene! State reset.")

func _process(delta):
	_process_zones(delta)

func _process_zones(delta):
	# Healing Zone Check
	var heal_zone = get_node_or_null("HealingZone")
	if heal_zone:
		for body in heal_zone.get_overlapping_bodies():
			if body.is_in_group("player"):
				healing_timer += delta
				if healing_timer >= 0.5:
					healing_timer = 0.0
					GameManager.player_stats.hp = min(GameManager.player_stats.max_hp, GameManager.player_stats.hp + 10)
					GameManager.player_stats.hunger = min(100, GameManager.player_stats.hunger + 5)
					GameManager.player_stats.thirst = min(100, GameManager.player_stats.thirst + 5)
					GameManager.emit_signal("stats_changed")

	# Damage Zone Check
	var dmg_zone = get_node_or_null("DamageZone")
	if dmg_zone:
		for body in dmg_zone.get_overlapping_bodies():
			if body.is_in_group("player") and not is_god_mode:
				damage_timer += delta
				if damage_timer >= 0.5:
					damage_timer = 0.0
					GameManager.player_stats.hp = max(0, GameManager.player_stats.hp - 10)
					GameManager.emit_signal("stats_changed")
					if SoundManager: SoundManager.play_hit()
					GameManager.add_log("Dev", "⚠️ Damage Zone (-10 HP)!")

# Spawning Functions
func spawn_enemy(enemy_type: String):
	var enemy_script = load("res://scripts/Enemy.gd")
	var enemy_body = CharacterBody3D.new()
	enemy_body.set_script(enemy_script)
	enemy_body.enemy_type = enemy_type

	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "MeshInstance"
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1.4, 1.4, 1.4)
	mesh_inst.mesh = box_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("#f59e0b")
	mesh_inst.material_override = mat
	enemy_body.add_child(mesh_inst)

	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(1.4, 1.4, 1.4)
	col.shape = box
	enemy_body.add_child(col)

	var spawn_pos = Vector3(25.0 + randf_range(-5, 5), 0.7, 10.0 + randf_range(-5, 5))
	enemy_body.global_position = spawn_pos
	spawner_container.add_child(enemy_body)

	if SoundManager: SoundManager.play_pick()
	GameManager.add_log("Dev", "Zespawnowano przeciwnika: " + enemy_type)

func spawn_prefab(prefab_type: String):
	var scene_path = ""
	if prefab_type == "bandit_camp":
		scene_path = "res://scenes/prefabs/BanditCampPrefab.tscn"
	elif prefab_type == "boss_arena":
		scene_path = "res://scenes/prefabs/BossArenaPrefab.tscn"

	if ResourceLoader.exists(scene_path):
		var packed = load(scene_path)
		if packed:
			var inst = packed.instantiate()
			inst.global_position = Vector3(30.0 + randf_range(-6, 6), 0.0, 35.0 + randf_range(-6, 6))
			spawner_container.add_child(inst)
			if SoundManager: SoundManager.play_level_up()
			GameManager.add_log("Dev", "Zespawnowano Prefab / Puzzle: " + prefab_type)

func spawn_crystal():
	var crystal_script = load("res://scripts/Crystal.gd")
	var crystal_body = StaticBody3D.new()
	crystal_body.set_script(crystal_script)

	var mesh_inst = MeshInstance3D.new()
	var prism = PrismMesh.new()
	prism.size = Vector3(1.2, 1.6, 1.2)
	mesh_inst.mesh = prism

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("#10b981")
	mat.emission_enabled = true
	mat.emission = Color("#10b981")
	mesh_inst.material_override = mat
	crystal_body.add_child(mesh_inst)

	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(1.2, 1.6, 1.2)
	col.shape = box
	crystal_body.add_child(col)

	crystal_body.global_position = Vector3(10.0 + randf_range(-4, 4), 0.8, 25.0 + randf_range(-4, 4))
	spawner_container.add_child(crystal_body)

	if SoundManager: SoundManager.play_pick()
	GameManager.add_log("Dev", "Spawned Alien Crystal")

func add_dev_materials():
	GameManager.inventory.append({"id": "scrap_dev_" + str(randi()), "name": "Scrap Metalowy", "type": "scrap", "count": 99, "color": "#94a3b8", "icon": "⚙️", "desc": "Dev Surowiec"})
	GameManager.inventory.append({"id": "wood_dev_" + str(randi()), "name": "Drewno Obcego", "type": "wood", "count": 99, "color": "#b45309", "icon": "🪵", "desc": "Dev Surowiec"})
	if SoundManager: SoundManager.play_level_up()
	GameManager.add_log("Dev", "Dodano 99x Scrap i Drewno do ekwipunku!")
	GameManager.emit_signal("inventory_changed")

func toggle_god_mode():
	is_god_mode = not is_god_mode
	if is_god_mode:
		GameManager.player_stats.max_hp = 9999
		GameManager.player_stats.hp = 9999
		GameManager.add_log("Dev", "🛡️ Invincibility Mode (Godmode) Enabled!")
	else:
		GameManager.player_stats.max_hp = 100
		GameManager.player_stats.hp = 100
		GameManager.add_log("Dev", "Invincibility Mode Disabled.")
	GameManager.emit_signal("stats_changed")
