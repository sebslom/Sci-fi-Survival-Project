extends CharacterBody3D

@export var boss_name = "Clone Overseer ALPHA (Hardcore Boss)"
@export var hp = 500
@export var max_hp = 500
@export var damage = 22
@export var move_speed = 5.5
@export var perception_range = 25.0
@export var attack_cooldown = 1.0

@onready var mesh_instance = get_node_or_null("MeshInstance3D")
@onready var boss_light = get_node_or_null("BossLight")
@onready var label_3d = get_node_or_null("Label3D")

var player_ref = null
var is_alerted: bool = false
var attack_timer: float = 0.0
var phase: int = 1

func _ready():
	add_to_group("enemy")
	add_to_group("boss")
	_update_boss_label()

func _update_boss_label():
	if label_3d:
		label_3d.text = "👹 %s\n[HP: %d / %d] (FAZA %d)" % [boss_name, hp, max_hp, phase]
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
		is_alerted = true

	if is_alerted:
		var dir = (player_ref.global_position - global_position).normalized()
		dir.y = 0.0
		
		# Move towards player
		var cur_speed = move_speed * (1.4 if phase == 2 else (1.8 if phase == 3 else 1.0))
		velocity.x = dir.x * cur_speed
		velocity.z = dir.z * cur_speed
		if not is_on_floor():
			velocity.y -= 15.0 * delta

		move_and_slide()
		look_at(Vector3(player_ref.global_position.x, global_position.y, player_ref.global_position.z), Vector3.UP)

		# Attack player when in melee range
		if dist <= 2.8 and attack_timer >= attack_cooldown:
			attack_timer = 0.0
			_execute_boss_attack()

func _execute_boss_attack():
	if not player_ref: return
	
	var dmg = damage * (1.3 if phase >= 2 else 1.0)
	if GameManager and GameManager.player_stats:
		GameManager.player_stats.hp = max(0, GameManager.player_stats.hp - int(dmg))
		if SurvivalManager:
			SurvivalManager.inflict_damage(dmg, false)

		if SoundManager: SoundManager.play_hit()
		GameManager.add_log("Combat", "💥 BOSS UDERZENIE: -" + str(int(dmg)) + " HP! (Ostrzeżenie: Atak Klonu!)")
		GameManager.emit_signal("stats_changed")

func take_damage(dmg_amount: int):
	hp -= dmg_amount
	if SoundManager: SoundManager.play_hit()

	# Phase Transitions
	if hp <= 125 and phase < 3:
		phase = 3
		move_speed = 7.5
		attack_cooldown = 0.7
		if boss_light: boss_light.light_color = Color("#ef4444"); boss_light.light_energy = 5.0
		if GameManager: GameManager.add_log("Boss", "🔥 BOSS FAZA 3 (OVERDRIVE BERSERK)! Szczytowa Emisja!")
	elif hp <= 300 and phase < 2:
		phase = 2
		move_speed = 6.2
		attack_cooldown = 0.85
		if boss_light: boss_light.light_color = Color("#f59e0b"); boss_light.light_energy = 3.5
		if GameManager: GameManager.add_log("Boss", "⚡ BOSS PHASE 2 (ENRAGED SPEED)! Attack speed increased!")

	_update_boss_label()

	if hp <= 0:
		_die()

func _die():
	if SoundManager: SoundManager.play_level_up()
	if GameManager:
		GameManager.add_log("Victory", "🏆 DEFEATED HARDCORE BOSS: " + boss_name + "!")
		GameManager.player_stats.gold += 500
		GameManager.player_stats.exp += 250
		
		# Drop rare loot items
		GameManager.inventory.append({ "id": "portal_core_boss", "name": "Rdzeń Kwantowy Portalu", "type": "component_portal_core", "count": 2, "weight": 4.0, "icon": "🔮", "desc": "Rare core harvested from defeated Clone Boss" })
		GameManager.inventory.append({ "id": "blueprint_dna", "name": "DNA Cloning Blueprint", "type": "blueprint", "count": 1, "weight": 0.5, "icon": "🧬", "desc": "Unique genetic engineering blueprint" })
		
		GameManager.emit_signal("inventory_changed")
		GameManager.emit_signal("stats_changed")

	queue_free()
