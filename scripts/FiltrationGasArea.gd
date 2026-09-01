extends Area3D

@export var required_filtration_grade: int = 2 # Grade 1, 2, or 3 gas vent

func _physics_process(delta):
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			var player_grade = GameManager.get_gas_mask_filtration_grade()
			if player_grade < required_filtration_grade:
				var grade_diff = required_filtration_grade - player_grade
				var dmg = grade_diff * 6.0 * delta
				GameManager.player_stats.hp = max(0, GameManager.player_stats.hp - int(ceil(dmg)))
				
				if SoundManager and randf() < 0.1:
					SoundManager.play_hit()
				GameManager.add_log("Mines", "☣️ TOXIC COLLECTOR GASA (Stopień " + str(required_filtration_grade) + ")! Your Mask (Grade " + str(player_grade) + ") is leaking toxins! (-" + str(int(ceil(dmg))) + " HP)")
				GameManager.emit_signal("stats_changed")
