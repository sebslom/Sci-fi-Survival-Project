extends Area3D

var damage_per_sec: float = 5.0

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		_check_protection()

func _physics_process(delta):
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			if GameManager.has_gas_mask_protection():
				# Mask protects completely from toxic gas!
				pass
			else:
				GameManager.player_stats.hp = max(0, GameManager.player_stats.hp - int(damage_per_sec * delta))
				if SoundManager and randf() < 0.1:
					SoundManager.play_hit()
				GameManager.add_log("Promieniowanie", "⚠️ TRUCIZNA GAZOWA! Brakuje Maski Gazowej (-5 HP/s)!")
				GameManager.emit_signal("stats_changed")

func _check_protection():
	if GameManager.has_gas_mask_protection():
		GameManager.add_log("Skafander", "😷 Maska Gazowa aktywowana: Pełna ochrona przed trującym gazem.")
	else:
		GameManager.add_log("Skafander", "⚠️ OSTRZEŻENIE! Wszedłeś w strefę toksycznego gazu! Załóż Maskę Gazową.")
