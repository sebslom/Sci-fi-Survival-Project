extends Area3D

var fall_speed: float = 22.0
var damage: int = 2

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	global_position.y -= fall_speed * delta
	if global_position.y <= 0.2:
		_explode()

func _on_body_entered(body):
	if body.is_in_group("player"):
		GameManager.player_stats.hp = max(0, GameManager.player_stats.hp - damage)
		if SoundManager:
			SoundManager.play_hit()
		GameManager.add_log("Wipeout", "🔥 METEORYT UDERZYŁ W CIEBIE! (-" + str(damage) + " HP)")
		GameManager.emit_signal("stats_changed")
		_explode()

func _explode():
	if SoundManager:
		SoundManager.play_wipeout()
	queue_free()
