extends CharacterBody3D

@export var enemy_name = "Marsjański Skakun"
@export var hp = 55
@export var max_hp = 55
@export var damage = 18
@export var suit_damage = 15
@export var move_speed = 9.0
@export var perception_range = 14.0

@onready var mesh_instance = get_node_or_null("MeshInstance3D")
@onready var label_3d = get_node_or_null("Label3D")

var player_ref = null
var is_burrowed: bool = true
var attack_timer: float = 0.0
var is_leaping: bool = false

func _ready():
	add_to_group("enemy")
	add_to_group("martian_jumper")
	_burrow_underground()
	_update_label()

func _burrow_underground():
	is_burrowed = true
	visible = true
	if mesh_instance and mesh_instance.material_override:
		var mat = mesh_instance.material_override.duplicate() as StandardMaterial3D
		if mat:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.5
			mesh_instance.material_override = mat

func _unburrow_burst():
	is_burrowed = false
	visible = true
	if mesh_instance and mesh_instance.material_override:
		var mat = mesh_instance.material_override.duplicate() as StandardMaterial3D
		if mat:
			mat.albedo_color.a = 1.0
			mesh_instance.material_override = mat
	if SoundManager: SoundManager.play_alarm()
	if GameManager:
		GameManager.add_log("Ostrzeżenie", "🦂 MARSJAŃSKI SKAKUN WYSKOCZYŁ Z REGOLITU! ATAK Z DOSKOKU!")

func _update_label():
	if label_3d:
		label_3d.text = "🦂 %s [HP: %d / %d]" % [enemy_name, hp, max_hp]
		label_3d.visible = false

func _physics_process(delta):
	attack_timer += delta

	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]

	if not player_ref: return

	var dist = global_position.distance_to(player_ref.global_position)

	# Stealth adjustment during dust storms
	var effective_range = perception_range
	if WeatherManager:
		var weather_str = str(WeatherManager.get("current_weather"))
		if "dust_storm" in weather_str or weather_str == "2":
			effective_range = 8.0 # Stays burrowed until player gets very close in dust storm!

	if is_burrowed and dist <= effective_range:
		_unburrow_burst()

	if not is_burrowed:
		var dir = (player_ref.global_position - global_position).normalized()
		dir.y = 0.0

		if not is_leaping:
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
			look_at(Vector3(player_ref.global_position.x, global_position.y, player_ref.global_position.z), Vector3.UP)

		if not is_on_floor():
			velocity.y -= 18.0 * delta
		else:
			is_leaping = false

		move_and_slide()

		# Trigger Pounce / Leap attack when close
		if dist <= 8.0 and not is_leaping and attack_timer >= 2.0:
			_execute_pounce_leap(dir)

		# Damage player on collision
		if dist <= 2.2 and attack_timer >= 1.2:
			attack_timer = 0.0
			_execute_suit_puncture_attack()

func _execute_pounce_leap(dir: Vector3):
	is_leaping = true
	attack_timer = 0.0
	velocity.x = dir.x * 14.0
	velocity.z = dir.z * 14.0
	velocity.y = 7.0
	if SoundManager: SoundManager.play_hit()

func _execute_suit_puncture_attack():
	if not player_ref: return
	if SoundManager: SoundManager.play_hit()
	if GameManager and GameManager.player_stats:
		GameManager.player_stats.hp = max(0, GameManager.player_stats.hp - damage)
		if GameManager.has_method("damage_suit"):
			GameManager.damage_suit(suit_damage)
		if SurvivalManager:
			SurvivalManager.inflict_damage(float(damage), false)

		GameManager.add_log("Walka", "🦂 ATAK SKAKUNA: -%d HP i ROZSZCZELNIENIE SKAFANDRA (-%d%%)!" % [damage, suit_damage])
		GameManager.emit_signal("stats_changed")

func take_damage(dmg_amount: int):
	if is_burrowed:
		_unburrow_burst()
	hp -= dmg_amount
	if SoundManager: SoundManager.play_hit()
	_update_label()
	if hp <= 0:
		_die()

func _die():
	if GameManager:
		GameManager.player_stats.gold += 40
		GameManager.player_stats.exp += 35
		GameManager.inventory.append({ "id": "jumper_gland", "name": "Gruczoł Kwasowy Skakuna", "type": "material_polymer", "count": 2, "weight": 0.4, "icon": "🧪" })
		GameManager.emit_signal("inventory_changed")
		GameManager.emit_signal("stats_changed")
	queue_free()
