extends CharacterBody3D

@export var enemy_name = "Klon-Defekt (Odrzut)"
@export var hp = 35
@export var max_hp = 35
@export var explosion_damage = 35
@export var explosion_radius = 4.5
@export var move_speed = 9.5
@export var perception_range = 30.0

@onready var mesh_instance = get_node_or_null("MeshInstance3D")
@onready var label_3d = get_node_or_null("Label3D")

var player_ref = null
var is_exploded: bool = false
var time_elapsed: float = 0.0

func _ready():
	add_to_group("enemy")
	add_to_group("clone_defect")
	_update_label()

func _update_label():
	if label_3d:
		label_3d.text = "☣️ %s [HP: %d / %d]\n[ODRZUT - SAMOBÓJCZA EKSPLOZJA]" % [enemy_name, hp, max_hp]
		label_3d.visible = false

func _physics_process(delta):
	time_elapsed += delta

	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]

	if not player_ref: return

	var dist = global_position.distance_to(player_ref.global_position)
	if dist <= perception_range and not is_exploded:
		var dir_to_player = (player_ref.global_position - global_position).normalized()
		dir_to_player.y = 0.0

		# Zigzag Motion Offset (Perpendicular vector)
		var perp_dir = Vector3(-dir_to_player.z, 0.0, dir_to_player.x)
		var zigzag_offset = perp_dir * sin(time_elapsed * 8.0) * 3.5
		var move_dir = (dir_to_player * move_speed) + zigzag_offset

		velocity.x = move_dir.x
		velocity.z = move_dir.z
		if not is_on_floor():
			velocity.y -= 15.0 * delta

		move_and_slide()
		look_at(Vector3(player_ref.global_position.x, global_position.y, player_ref.global_position.z), Vector3.UP)

		# Trigger explosive blast if reached player
		if dist <= 1.8:
			_explode()

func take_damage(dmg_amount: int):
	if is_exploded: return
	hp -= dmg_amount
	if SoundManager: SoundManager.play_hit()
	_update_label()
	if hp <= 0:
		_explode()

func _explode():
	if is_exploded: return
	is_exploded = true

	if SoundManager: SoundManager.play_alarm()

	if GameManager:
		GameManager.add_log("EKSPLOZJA", "💥 EKSPLOZJA NIESTABILNEJ KRWI KLONA-DEFEKTA! Obrażenia obszarowe w promieniu 4.5m!")

	# AOE Damage calculation
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if p and is_instance_valid(p):
			var d = global_position.distance_to(p.global_position)
			if d <= explosion_radius:
				if GameManager and GameManager.player_stats:
					GameManager.player_stats.hp = max(0, GameManager.player_stats.hp - explosion_damage)
					if SurvivalManager:
						SurvivalManager.inflict_damage(float(explosion_damage), false)
					GameManager.emit_signal("stats_changed")

	# Destroy nearby cover or destructible obstacles
	var destructibles = get_tree().get_nodes_in_group("destructible")
	for obj in destructibles:
		if obj and is_instance_valid(obj) and obj != self:
			if global_position.distance_to(obj.global_position) <= explosion_radius:
				if obj.has_method("take_damage"):
					obj.take_damage(50)

	if GameManager:
		GameManager.player_stats.gold += 20
		GameManager.player_stats.exp += 25
		GameManager.emit_signal("stats_changed")

	queue_free()
