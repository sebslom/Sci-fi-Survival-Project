extends CharacterBody3D

@export var enemy_name = "Shield Guard Clone"
@export var hp = 160
@export var max_hp = 160
@export var damage = 18
@export var move_speed = 4.0
@export var perception_range = 24.0
@export var emp_cooldown = 8.0

@onready var shield_mesh = get_node_or_null("ShieldMesh")
@onready var label_3d = get_node_or_null("Label3D")

var player_ref = null
var attack_timer: float = 0.0
var emp_timer: float = 0.0

func _ready():
	add_to_group("enemy")
	add_to_group("shield_sentry")
	_update_label()

func _update_label():
	if label_3d:
		label_3d.text = "🛡️ %s [HP: %d / %d]\n[TARCZA BALISTYCZNA AKTYWNA]" % [enemy_name, hp, max_hp]
		label_3d.visible = false

func _physics_process(delta):
	attack_timer += delta
	emp_timer += delta

	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]

	if not player_ref: return

	var dist = global_position.distance_to(player_ref.global_position)
	if dist <= perception_range:
		var dir = (player_ref.global_position - global_position).normalized()
		dir.y = 0.0
		
		# Move slowly with shield raised
		if dist > 5.0:
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
		else:
			velocity.x = 0; velocity.z = 0

		if not is_on_floor():
			velocity.y -= 15.0 * delta

		move_and_slide()
		look_at(Vector3(player_ref.global_position.x, global_position.y, player_ref.global_position.z), Vector3.UP)

		# Throw EMP Grenade at player
		if dist <= 20.0 and emp_timer >= emp_cooldown:
			emp_timer = 0.0
			_throw_emp_grenade()

		# Standard attack
		if dist <= 12.0 and attack_timer >= 1.4:
			attack_timer = 0.0
			_fire_shot()

func _fire_shot():
	if not player_ref: return
	if SoundManager: SoundManager.play_laser()
	if GameManager and GameManager.player_stats:
		GameManager.player_stats.hp = max(0, GameManager.player_stats.hp - damage)
		if SurvivalManager:
			SurvivalManager.inflict_damage(float(damage), false)
		if SoundManager: SoundManager.play_hit()
		GameManager.add_log("Combat", "💥 GUARD SHOT: -%d HP!" % damage)
		GameManager.emit_signal("stats_changed")

func _throw_emp_grenade():
	if not player_ref: return
	
	if SoundManager: SoundManager.play_alarm()
	if GameManager:
		GameManager.add_log("Warning", "⚡ GUARD THREW EMP GRENADE! Flashlight, HUD, and energy weapons disabled for 5s!")

	# Disable player flashlight
	var flashlight = player_ref.get_node_or_null("Head/Camera3D/Flashlight")
	if flashlight:
		flashlight.visible = false
		get_tree().create_timer(5.0).timeout.connect(func(): flashlight.visible = true)

	# Trigger HUD glitch effect
	var h_nodes = get_tree().get_nodes_in_group("hud")
	if h_nodes.size() > 0 and h_nodes[0].has_method("trigger_emp_glitch"):
		h_nodes[0].trigger_emp_glitch(5.0)

	# Jam active energy weapon
	if WeaponManager and WeaponManager.has_method("jam_energy_weapons"):
		WeaponManager.jam_energy_weapons(5.0)

func take_damage_custom(dmg_amount: int, hit_from_pos: Vector3, is_leg_shot: bool = false):
	# Check if shot came from front aspect (Shield Defense)
	var forward_dir = -global_transform.basis.z.normalized()
	var shot_dir = (hit_from_pos - global_position).normalized()
	var dot = forward_dir.dot(shot_dir)

	if dot > 0.1 and not is_leg_shot:
		# Shield blocks damage!
		if SoundManager: SoundManager.play_pick()
		if GameManager:
			GameManager.add_log("Armor", "🛡️ GUARD BALISTIC SHIELD BLOCKED SHOT! (Aim for legs or flank from behind!)")
		return

	take_damage(dmg_amount)

func take_damage(dmg_amount: int):
	hp -= dmg_amount
	if SoundManager: SoundManager.play_hit()
	_update_label()
	if hp <= 0:
		_die()

func _die():
	if GameManager:
		GameManager.player_stats.gold += 60
		GameManager.player_stats.exp += 50
		GameManager.emit_signal("stats_changed")
	queue_free()
