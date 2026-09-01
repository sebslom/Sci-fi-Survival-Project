extends CharacterBody3D

@export var enemy_name = "Bandyta Kosmiczny Zwiadowca"
@export var enemy_type = "bandit_scout" # "bug", "tur", "spec_ops", "bandit_scout", "bandit_assault", "bandit_heavy", "boss_mutant", "slime", "drone"
@export var hp = 45
@export var max_hp = 45
@export var damage = 8
@export var exp_reward = 35
@export var move_speed = 4.0
@export var perception_range = 18.0 # Enemy sight/detection distance
@export var deaggro_range = 35.0    # Distance at which enemy gives up chase
@export var attack_cooldown = 1.2    # Time between attacks in seconds
@export var is_boss = false
@export var is_armored = false

@onready var mesh_instance = get_node_or_null("MeshInstance")
var player_ref = null

var is_alerted: bool = false
var attack_timer: float = 0.0

var is_burning = false
var burn_timer = 0.0

func _ready():
	_setup_enemy_stats()

func _setup_enemy_stats():
	if enemy_type == "bug":
		enemy_name = "Kosmiczny Robal"
		hp = 18; max_hp = 18; damage = 3; exp_reward = 10; move_speed = 2.5
		perception_range = 14.0
		scale = Vector3(0.7, 0.7, 0.7)
	elif enemy_type == "tur":
		enemy_name = "Kosmiczny Tur (Obcy Zwierz)"
		hp = 85; max_hp = 85; damage = 14; exp_reward = 60; move_speed = 3.8
		perception_range = 20.0
		is_armored = true
		scale = Vector3(1.6, 1.4, 1.6)
	elif enemy_type == "spec_ops":
		enemy_name = "Kosmiczna Jednostka Specjalna"
		hp = 100; max_hp = 100; damage = 18; exp_reward = 90; move_speed = 4.2
		perception_range = 22.0
		is_armored = true
		scale = Vector3(1.1, 1.1, 1.1)
	elif enemy_type == "bandit_scout":
		enemy_name = "Bandyta Zwiadowca"
		hp = 40; max_hp = 40; damage = 7; exp_reward = 30; move_speed = 4.5
		perception_range = 18.0
	elif enemy_type == "bandit_assault":
		enemy_name = "Bandyta Szturmowiec"
		hp = 70; max_hp = 70; damage = 12; exp_reward = 50; move_speed = 3.6
		perception_range = 18.0
	elif enemy_type == "bandit_heavy":
		enemy_name = "Bandyta Ciężki Pancerz"
		hp = 110; max_hp = 110; damage = 18; exp_reward = 80; move_speed = 2.8
		perception_range = 16.0
		is_armored = true
	elif enemy_type == "boss_mutant":
		enemy_name = "👹 HEAVY MARTIAN MUTANT (BOSS)"
		hp = 250; max_hp = 250; damage = 25; exp_reward = 200; move_speed = 3.2
		perception_range = 30.0
		is_boss = true
		is_armored = true
		scale = Vector3(2.2, 2.2, 2.2)

func _physics_process(delta):
	_process_burning(delta)
	
	if attack_timer > 0.0:
		attack_timer -= delta

	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]
		return

	var dist = global_position.distance_to(player_ref.global_position)
	
	# Check sight/perception trigger
	if dist <= perception_range:
		is_alerted = true
	elif dist >= deaggro_range:
		is_alerted = false

	# Only move/chase if alerted and player is in sight range
	if is_alerted:
		if dist > 2.0:
			var dir = (player_ref.global_position - global_position).normalized()
			dir.y = 0
			velocity = dir * move_speed
			move_and_slide()
		elif dist <= 2.0 and attack_timer <= 0.0:
			attack_player()
			attack_timer = attack_cooldown

func _process_burning(delta):
	if is_burning:
		burn_timer -= delta
		if burn_timer <= 0:
			is_burning = false
		else:
			hp -= int(6 * delta)
			if hp <= 0:
				take_damage(0, "incendiary")

func attack_player():
	GameManager.player_stats.hp = max(0, GameManager.player_stats.hp - damage)
	
	if enemy_type in ["bandit_scout", "bandit_assault", "bandit_heavy", "spec_ops", "tur", "boss_mutant"]:
		var suit_dmg = damage * 0.8
		GameManager.damage_suit(suit_dmg)

	# Determine enemy-specific bleed chance (20% to 50%)
	var b_chance = 0.25 # Default 25%
	if is_boss or enemy_type in ["boss_mutant", "boss_goliat", "boss_architect"]:
		b_chance = 0.50 # Bosses have 50% bleed chance!
	elif enemy_type in ["slime", "space_bug", "mutant_beast"]:
		b_chance = 0.35 # Mutant beasts & Slimes have 35% bleed/acid chance!
	elif enemy_type in ["bandit_heavy", "clone_sentry"]:
		b_chance = 0.30 # Heavy troops have 30% bleed chance!
	elif enemy_type in ["bandit_scout", "clone_defect"]:
		b_chance = 0.20 # Light scouts & defects have 20% bleed chance!

	if SurvivalManager:
		SurvivalManager.inflict_damage(damage, false, b_chance)
		
	GameManager.emit_signal("stats_changed")
	if SoundManager:
		SoundManager.play_hit()
	
	if is_boss:
		GameManager.add_log("Boss", "💥 " + enemy_name + " ZATRATOWAŁ CIĘ! (-" + str(damage) + " HP)")
	else:
		GameManager.add_log("Combat", "⚠️ " + enemy_name + " zaatakował Cię! (-" + str(damage) + " HP)")

func take_damage(amount: int, ammo_type: String = "standard"):
	# Being shot alerts the enemy immediately regardless of distance
	is_alerted = true
	
	var final_damage = float(amount)
	
	if is_armored:
		if ammo_type == "ap":
			final_damage = final_damage * 1.25 # AP ignores armor and deals +25% bonus
			GameManager.add_log("Combat", "🎯 ARMOR PIERCED with AP ammo!")
		elif ammo_type == "standard":
			final_damage = final_damage * 0.5 # Standard ammo reduced by 50% on armored targets
			GameManager.add_log("Combat", "🛡️ Armor reduced damage by 50%! Use AP ammo [R].")

	if ammo_type == "incendiary":
		is_burning = true
		burn_timer = 3.0
		GameManager.add_log("Combat", "🔥 Target ignited with incendiary ammo!")

	hp -= int(final_damage)
	if SoundManager:
		SoundManager.play_hit()
	
	if is_boss:
		GameManager.add_log("Boss", "Trafiłeś Bossa za " + str(int(final_damage)) + " HP! (" + str(max(0, hp)) + " / " + str(max_hp) + ")")
	else:
		GameManager.add_log("Combat", "Trafiłeś " + enemy_name + " za " + str(int(final_damage)) + " obrażeń!")
	
	if hp <= 0:
		if SoundManager:
			SoundManager.play_enemy_death()
		if is_boss:
			GameManager.add_log("Boss", "🏆 POKONAŁEŚ DUŻEGO MUTANTA MARSJAŃSKIEGO! (+" + str(exp_reward) + " EXP)")
		else:
			GameManager.add_log("Combat", "Pokonałeś " + enemy_name + "! (+" + str(exp_reward) + " EXP)")
		
		GameManager.add_exp(exp_reward)
		queue_free()
