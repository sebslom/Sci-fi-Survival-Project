extends CharacterBody3D

@export var clone_type: String = "assault" # "assault", "scout", "heavy"
@export var enemy_name = "Klon Szturmowiec"
@export var hp = 70
@export var max_hp = 70
@export var damage = 10
@export var move_speed = 7.0
@export var perception_range = 22.0
@export var attack_cooldown = 0.6

@onready var mesh_instance = get_node_or_null("MeshInstance3D")
@onready var muzzle_light = get_node_or_null("MuzzleLight")
@onready var label_3d = get_node_or_null("Label3D")

var player_ref = null
var attack_timer: float = 0.0

func _ready():
	add_to_group("enemy")
	_setup_clone_stats()
	_update_label()

func _setup_clone_stats():
	match clone_type:
		"scout":
			enemy_name = "Klon Zwiadowca"
			hp = 45; max_hp = 45; damage = 14; move_speed = 8.5
			perception_range = 28.0; attack_cooldown = 1.0
			scale = Vector3(0.85, 0.9, 0.85)
		"heavy":
			enemy_name = "Klon Ciężki Strażnik"
			hp = 140; max_hp = 140; damage = 25; move_speed = 3.5
			perception_range = 18.0; attack_cooldown = 1.8
			scale = Vector3(1.3, 1.2, 1.3)
		_: # "assault" default
			enemy_name = "Klon Szturmowiec"
			hp = 70; max_hp = 70; damage = 10; move_speed = 7.0
			perception_range = 22.0; attack_cooldown = 0.6
			scale = Vector3(1.0, 1.0, 1.0)

func _update_label():
	if label_3d:
		label_3d.text = "🧬 %s [HP: %d / %d]" % [enemy_name, hp, max_hp]
		label_3d.visible = false

func _physics_process(delta):
	attack_timer += delta

	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]

	if not player_ref: return

	var dist = global_position.distance_to(player_ref.global_position)
	if dist <= perception_range:
		var dir = (player_ref.global_position - global_position).normalized()
		dir.y = 0.0
		
		# Move towards player if not in shooting range
		var stop_dist = 4.0 if clone_type == "heavy" else 8.0
		if dist > stop_dist:
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
		else:
			velocity.x = 0
			velocity.z = 0

		if not is_on_floor():
			velocity.y -= 15.0 * delta

		move_and_slide()
		look_at(Vector3(player_ref.global_position.x, global_position.y, player_ref.global_position.z), Vector3.UP)

		# Fire weapon at player
		if dist <= 18.0 and attack_timer >= attack_cooldown:
			attack_timer = 0.0
			_fire_laser_at_player()

func _fire_laser_at_player():
	if not player_ref: return
	
	if muzzle_light:
		muzzle_light.visible = true
		get_tree().create_timer(0.06).timeout.connect(func(): muzzle_light.visible = false)

	if SoundManager: SoundManager.play_laser()

	if GameManager and GameManager.player_stats:
		GameManager.player_stats.hp = max(0, GameManager.player_stats.hp - damage)
		if SurvivalManager:
			SurvivalManager.inflict_damage(float(damage), false)

		if SoundManager: SoundManager.play_hit()
		GameManager.add_log("Walka", "⚡ ATAK (%s): -%d HP!" % [enemy_name, damage])
		GameManager.emit_signal("stats_changed")

func take_damage(dmg_amount: int):
	hp -= dmg_amount
	if SoundManager: SoundManager.play_hit()
	_update_label()
	if hp <= 0:
		_die()

func _die():
	if GameManager:
		var exp_reward = 40 if clone_type == "heavy" else (20 if clone_type == "scout" else 30)
		var gold_reward = 45 if clone_type == "heavy" else (15 if clone_type == "scout" else 25)
		
		GameManager.player_stats.gold += gold_reward
		GameManager.player_stats.exp += exp_reward
		GameManager.emit_signal("stats_changed")
	queue_free()
