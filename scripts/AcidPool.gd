extends Area3D

@export var lifetime: float = 8.0
@export var damage_per_sec: float = 8.0

var age: float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta):
	age += delta
	if age >= lifetime:
		queue_free()

func _on_body_entered(body):
	if body and body.is_in_group("player"):
		_apply_acid_damage()

func _apply_acid_damage():
	if GameManager and GameManager.player_stats:
		GameManager.player_stats.hp = max(0, GameManager.player_stats.hp - int(damage_per_sec))
		if GameManager.has_method("damage_suit"):
			GameManager.damage_suit(10)
		if SurvivalManager:
			SurvivalManager.inflict_damage(damage_per_sec, false)

		if SoundManager: SoundManager.play_hit()
		GameManager.add_log("Toxin", "☣️ STEPPED IN TOXIC GOLIATH ACID POOL! -8 HP and suit damage!")
		GameManager.emit_signal("stats_changed")
