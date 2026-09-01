extends CharacterBody3D

@export var enemy_name = "Rdzawy Żniwiarz"
@export var hp = 200
@export var max_hp = 200
@export var damage = 30
@export var patrol_speed = 2.0
@export var harvest_speed = 8.5
@export var perception_range = 28.0

@onready var mesh_instance = get_node_or_null("MeshInstance3D")
@onready var back_core_mesh = get_node_or_null("BackCoreMesh")
@onready var label_3d = get_node_or_null("Label3D")

var player_ref = null
var is_aggroed: bool = false
var attack_timer: float = 0.0
var patrol_timer: float = 0.0
var patrol_dir: Vector3 = Vector3.FORWARD

func _ready():
	add_to_group("enemy")
	add_to_group("reaper_mech")
	_update_label()

func _update_label():
	if label_3d:
		var status = " ⚔️ [AKTYWNY HARVEST]" if is_aggroed else " 💤 [PATROL TERRAFORMACJI]"
		label_3d.text = "⚙️ %s [HP: %d / %d]%s" % [enemy_name, hp, max_hp, status]
		label_3d.visible = false

func _physics_process(delta):
	attack_timer += delta
	patrol_timer += delta

	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]

	if player_ref and not is_aggroed:
		_check_player_sound_or_laser_activity()

	if is_aggroed and player_ref:
		_process_harvest_attack(delta)
	else:
		_process_patrol(delta)

func _check_player_sound_or_laser_activity():
	var dist = global_position.distance_to(player_ref.global_position)
	if dist <= perception_range:
		var player_vel = player_ref.velocity.length() if player_ref.get("velocity") else 0.0
		var is_laser_active = false
		if WeaponManager and WeaponManager.get("current_weapon"):
			var w = WeaponManager.get("current_weapon")
			if w and w.get("weaponType") == "laser" and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				is_laser_active = true

		# Aggro trigger: Sprinting (vel > 5.5 m/s) OR Laser mining tool active
		if player_vel > 5.5 or is_laser_active:
			is_aggroed = true
			if SoundManager: SoundManager.play_alarm()
			if GameManager:
				GameManager.add_log("Ostrzeżenie", "⚙️ RDZAWY ŻNIWIARZ WYKRYŁ HUK/LASER! Aktywacja Agresywnej Szarży 'Harvest'!")
			_update_label()

func _process_harvest_attack(delta):
	var dist = global_position.distance_to(player_ref.global_position)
	var dir = (player_ref.global_position - global_position).normalized()
	dir.y = 0.0

	velocity.x = dir.x * harvest_speed
	velocity.z = dir.z * harvest_speed
	if not is_on_floor():
		velocity.y -= 15.0 * delta

	move_and_slide()
	look_at(Vector3(player_ref.global_position.x, global_position.y, player_ref.global_position.z), Vector3.UP)

	if dist <= 3.2 and attack_timer >= 1.5:
		attack_timer = 0.0
		_execute_reaper_harvest_strike()

func _process_patrol(delta):
	if patrol_timer >= 4.0:
		patrol_timer = 0.0
		var rx = randf_range(-1.0, 1.0)
		var rz = randf_range(-1.0, 1.0)
		patrol_dir = Vector3(rx, 0.0, rz).normalized()

	velocity.x = patrol_dir.x * patrol_speed
	velocity.z = patrol_dir.z * patrol_speed
	if not is_on_floor():
		velocity.y -= 15.0 * delta

	move_and_slide()

func _execute_reaper_harvest_strike():
	if not player_ref: return
	if SoundManager: SoundManager.play_hit()
	if GameManager and GameManager.player_stats:
		GameManager.player_stats.hp = max(0, GameManager.player_stats.hp - damage)
		if SurvivalManager:
			SurvivalManager.inflict_damage(float(damage), false)
		GameManager.add_log("Walka", "⚙️ UDERZENIE RDZAWEGO ŻNIWIARZA: -%d HP!" % damage)
		GameManager.emit_signal("stats_changed")

func take_damage_custom(dmg_amount: int, hit_from_pos: Vector3):
	# Check if shot hit the exposed Back Power Cell
	var back_dir = global_transform.basis.z.normalized()
	var shot_dir = (hit_from_pos - global_position).normalized()
	var dot = back_dir.dot(shot_dir)

	if dot > 0.3:
		# Hit Weak Point Back Cell: 300% Critical Damage!
		var crit_dmg = int(dmg_amount * 3.0)
		if SoundManager: SoundManager.play_level_up()
		if GameManager:
			GameManager.add_log("Krytyk", "💥 KRYTYCZNE TRAFIENIE W OGNIWO ZASILAJĄCE NA PLECACH ŻNIWIARZA! -%d HP!" % crit_dmg)
		take_damage(crit_dmg)
	else:
		# Front/Side Heavy Armor: 90% Damage Absorption (10% damage taken)
		var armored_dmg = max(1, int(dmg_amount * 0.1))
		if SoundManager: SoundManager.play_pick()
		if GameManager:
			GameManager.add_log("Pancerz", "🛡️ GRUBY PANCERZ TERRAFORMERA POCHŁONĄŁ STRZAŁ (-90%%)! (Traf w plecy!)")
		take_damage(armored_dmg)

func take_damage(dmg_amount: int):
	hp -= dmg_amount
	is_aggroed = true
	_update_label()
	if SoundManager: SoundManager.play_hit()
	if hp <= 0:
		_die()

func _die():
	if SoundManager: SoundManager.play_level_up()
	if GameManager:
		GameManager.add_log("Zwycięstwo", "⚙️ ZNISZCZONO STAROŻYTNEGO RDZAWEGO ŻNIWIARZA!")
		GameManager.player_stats.gold += 120
		GameManager.player_stats.exp += 90
		
		# Drop rare metals and scrap
		GameManager.inventory.append({ "id": "reaper_steel", "name": "Steel Starożytna", "type": "material_steel", "count": 4, "weight": 2.0, "icon": "🪙" })
		GameManager.inventory.append({ "id": "reaper_core", "name": "Uszkodzone Ogniwo Terraformera", "type": "scrap", "count": 3, "weight": 1.5, "icon": "⚙️" })
		
		GameManager.emit_signal("inventory_changed")
		GameManager.emit_signal("stats_changed")

	queue_free()
