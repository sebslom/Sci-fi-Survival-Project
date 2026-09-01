extends StaticBody3D

@export var hp: int = 500
@export var max_hp: int = 500

var spawn_timer: float = 0.0
var is_destroyed: bool = false

@onready var label_3d = get_node_or_null("Label3D")
@onready var mesh_inst = get_node_or_null("MeshInstance3D")

func _ready():
	_update_label()

func _physics_process(delta):
	if is_destroyed:
		return
		
	spawn_timer += delta
	if spawn_timer >= 15.0:
		spawn_timer = 0.0
		_spawn_acid_slime()

func _spawn_acid_slime():
	var enemy_script = load("res://scripts/Enemy.gd")
	var slime = CharacterBody3D.new()
	slime.set_script(enemy_script)
	slime.set("enemy_type", "slime")
	slime.set("enemy_name", "Kwasowy Slime")
	slime.set("hp", 30)
	slime.set("max_hp", 30)
	slime.set("damage", 6)
	slime.set("exp_reward", 25)
	slime.set("move_speed", 3.0)
	slime.scale = Vector3(0.9, 0.9, 0.9)
	
	var mesh = MeshInstance3D.new()
	mesh.name = "MeshInstance"
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	mesh.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("#84cc16") # Toxic lime green
	mat.emission_enabled = true
	mat.emission = Color("#84cc16")
	mat.emission_energy_multiplier = 1.2
	mesh.material_override = mat
	slime.add_child(mesh)
	
	var col = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.5
	col.shape = sphere_shape
	slime.add_child(col)
	
	# Position near egg core
	slime.global_position = global_position + Vector3(randf_range(-2.0, 2.0), 0.5, randf_range(-2.0, 2.0))
	get_parent().add_child(slime)
	
	if SoundManager: SoundManager.play_pick()
	GameManager.add_log("Gniazdo", "☣️ Wykluł się Kwasowy Slime z Gniazda Obcych!")
	
	# Slime lives for 60 seconds then melts/despawns
	get_tree().create_timer(60.0).timeout.connect(func():
		if is_instance_valid(slime):
			slime.queue_free()
	)

func take_damage(amount: int, ammo_type: String = "standard"):
	if is_destroyed:
		return
		
	hp -= amount
	_update_label()
	if SoundManager: SoundManager.play_hit()
	GameManager.add_log("Gniazdo", "Zaatakowałeś Jajo Obcego за " + str(amount) + " HP! (" + str(max(0, hp)) + " / " + str(max_hp) + ")")
	
	if hp <= 0:
		_destroy_egg()

func _update_label():
	if label_3d:
		label_3d.text = "🥚 JAJO OBCEGO (CORE)\nHP: " + str(max(0, hp)) + " / " + str(max_hp)

func _destroy_egg():
	is_destroyed = true
	if SoundManager: SoundManager.play_level_up()
	GameManager.add_log("Gniazdo", "🏆 ZNISZCZONO CENTRALNE JAJO OBCEGO! Wyrzucono wartościowe plony!")
	
	# Drop loot: 5x Alien Crystals, +100 Gold, +150 EXP
	GameManager.player_stats.gold += 100
	GameManager.add_exp(150)
	GameManager.inventory.append({
		"id": "alien_crystal_" + str(randi()),
		"name": "Kryształ Obcego",
		"type": "scrap",
		"count": 5,
		"weight": 2.0,
		"color": "#a855f7",
		"icon": "💎",
		"desc": "Cenny rzadki surowiec z gniazda"
	})
	
	GameManager.emit_signal("inventory_changed")
	GameManager.emit_signal("stats_changed")
	queue_free()
