extends CharacterBody3D

@export var boss_name = "Prototyp \"GOLIAT\" (Hardcore Boss)"
@export var hp = 800
@export var max_hp = 800
@export var charge_damage = 45
@export var normal_damage = 25
@export var base_speed = 4.5
@export var charge_speed = 16.0

@onready var mesh_instance = get_node_or_null("MeshInstance3D")
@onready var boss_light = get_node_or_null("BossLight")
@onready var label_3d = get_node_or_null("Label3D")

enum State { CHASE, CHARGE_WINDUP, CHARGING, STUNNED }
var current_state: State = State.CHASE

var player_ref = null
var charge_cooldown_timer: float = 0.0
var acid_spit_timer: float = 0.0
var state_timer: float = 0.0
var charge_dir: Vector3 = Vector3.ZERO
var is_armor_cracked: bool = false

func _ready():
	add_to_group("enemy")
	add_to_group("boss")
	add_to_group("goliat")
	_update_label()

func _update_label():
	if label_3d:
		var phase_str = "FAZA 2: CRACKED ACID" if is_armor_cracked else "FAZA 1: ARMORED CHARGE"
		label_3d.text = "👹 %s\n[HP: %d / %d] (%s)" % [boss_name, hp, max_hp, phase_str]
		label_3d.visible = false

func _physics_process(delta):
	charge_cooldown_timer += delta
	acid_spit_timer += delta

	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]

	if not player_ref: return

	match current_state:
		State.CHASE:
			_process_chase(delta)
		State.CHARGE_WINDUP:
			_process_windup(delta)
		State.CHARGING:
			_process_charging(delta)
		State.STUNNED:
			_process_stunned(delta)

	# Phase 2 Acid Spit Mechanic (below 50% HP)
	if is_armor_cracked and acid_spit_timer >= 3.5 and current_state != State.STUNNED:
		acid_spit_timer = 0.0
		_spit_acid_pool()

func _process_chase(delta):
	var dist = global_position.distance_to(player_ref.global_position)
	var dir = (player_ref.global_position - global_position).normalized()
	dir.y = 0.0

	velocity.x = dir.x * base_speed
	velocity.z = dir.z * base_speed
	if not is_on_floor():
		velocity.y -= 15.0 * delta

	move_and_slide()
	look_at(Vector3(player_ref.global_position.x, global_position.y, player_ref.global_position.z), Vector3.UP)

	# Check for charge trigger (every 6 seconds)
	if dist <= 25.0 and dist >= 6.0 and charge_cooldown_timer >= 6.0:
		_start_charge_windup()

func _start_charge_windup():
	current_state = State.CHARGE_WINDUP
	state_timer = 1.0
	charge_cooldown_timer = 0.0
	velocity = Vector3.ZERO
	charge_dir = (player_ref.global_position - global_position).normalized()
	charge_dir.y = 0.0

	if boss_light: boss_light.light_color = Color("#ef4444"); boss_light.light_energy = 6.0
	if SoundManager: SoundManager.play_alarm()
	if GameManager: GameManager.add_log("Boss", "⚠️ PROTOTYP GOLIAT SZYKUJE NISZCZYCIELSKĄ SZARŻĘ! UNIKNIJ ATAKU!")

func _process_windup(delta):
	state_timer -= delta
	if state_timer <= 0.0:
		current_state = State.CHARGING
		state_timer = 1.5

func _process_charging(delta):
	state_timer -= delta
	velocity.x = charge_dir.x * charge_speed
	velocity.z = charge_dir.z * charge_speed
	if not is_on_floor():
		velocity.y -= 15.0 * delta

	var collided = move_and_slide()
	
	# Check collision with player during charge
	var dist = global_position.distance_to(player_ref.global_position)
	if dist <= 2.8:
		_hit_player_with_charge()
		current_state = State.CHASE
		return

	# If collided with arena walls, stun Goliat
	if collided and get_slide_collision_count() > 0:
		_stun_goliat()
		return

	if state_timer <= 0.0:
		current_state = State.CHASE
		if boss_light: boss_light.light_color = Color("#84cc16") if is_armor_cracked else Color("#ef4444")

func _hit_player_with_charge():
	if GameManager and GameManager.player_stats:
		GameManager.player_stats.hp = max(0, GameManager.player_stats.hp - charge_damage)
		if SurvivalManager:
			SurvivalManager.inflict_damage(float(charge_damage), true) # Causes severe bleeding!

		if SoundManager: SoundManager.play_hit()
		GameManager.add_log("Boss", "💥 NISZCZYCIELSKIE UDERZENIE SZARŻY GOLIATA: -%d HP i CIĘŻKIE KRWAWIENIE!" % charge_damage)
		GameManager.emit_signal("stats_changed")

func _stun_goliat():
	current_state = State.STUNNED
	state_timer = 2.0
	velocity = Vector3.ZERO
	if boss_light: boss_light.light_color = Color("#eab308"); boss_light.light_energy = 2.0
	if GameManager: GameManager.add_log("Boss", "💫 GOLIAT UDERZYŁ W ŚCIANĘ I ZOSTAŁ OGŁUSZONY NA 2 SEKUNDY!")

func _process_stunned(delta):
	state_timer -= delta
	velocity = Vector3.ZERO
	if state_timer <= 0.0:
		current_state = State.CHASE

func _spit_acid_pool():
	if not player_ref: return
	
	var acid_script = load("res://scripts/AcidPool.gd")
	var pool = Area3D.new()
	pool.set_script(acid_script)
	pool.global_position = player_ref.global_position

	# Visual Toxic Mesh
	var pmesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new(); cyl.top_radius = 2.5; cyl.bottom_radius = 2.5; cyl.height = 0.1
	pmesh.mesh = cyl
	var pmat = StandardMaterial3D.new()
	pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pmat.albedo_color = Color(0.5, 0.8, 0.1, 0.6)
	pmat.emission_enabled = true; pmat.emission = Color("#84cc16"); pmat.emission_energy_multiplier = 2.0
	pmesh.material_override = pmat
	pool.add_child(pmesh)

	var pcol = CollisionShape3D.new()
	var pcyl = CylinderShape3D.new(); pcyl.radius = 2.5; pcyl.height = 0.2
	pcol.shape = pcyl
	pool.add_child(pcol)

	get_parent().add_child(pool)
	if SoundManager: SoundManager.play_laser()
	if GameManager: GameManager.add_log("Boss", "☣️ GOLIAT PLUJE KWASEM! POWSTAŁA TOKSYCZNA STREFA KWASU!")

func take_damage(dmg_amount: int):
	hp -= dmg_amount
	if SoundManager: SoundManager.play_hit()

	# Check Armor Cracking (50% HP threshold)
	if hp <= 400 and not is_armor_cracked:
		is_armor_cracked = true
		if mesh_instance and mesh_instance.material_override:
			var mat = mesh_instance.material_override.duplicate() as StandardMaterial3D
			if mat:
				mat.albedo_color = Color("#84cc16")
				mat.emission = Color("#84cc16")
				mesh_instance.material_override = mat
		if GameManager: GameManager.add_log("Boss", "⚠️ PANCERZ PROTOTYPU GOLIAT PĘKŁ (50% HP)! BAZA ROZPOCZĘŁA ETAP PLUCIA TOKSYCZNYM KWASEM!")

	_update_label()
	if hp <= 0:
		_die()

func _die():
	if SoundManager: SoundManager.play_level_up()
	if GameManager:
		GameManager.add_log("Zwycięstwo", "🏆 POKONANO LEGIENDARNEGO BOSSA PROTOTYP GOLIAT!")
		GameManager.player_stats.gold += 800
		GameManager.player_stats.exp += 400
		
		# Drop rare legendary loot
		GameManager.inventory.append({ "id": "portal_core_goliat", "name": "Rdzeń Kwantowy Portalu", "type": "component_portal_core", "count": 2, "weight": 4.0, "icon": "🔮" })
		GameManager.inventory.append({ "id": "goliat_plate", "name": "Pancerz Goliata (Płyta)", "type": "material_steel", "count": 10, "weight": 8.0, "icon": "🛡️" })
		
		GameManager.emit_signal("inventory_changed")
		GameManager.emit_signal("stats_changed")

	queue_free()
