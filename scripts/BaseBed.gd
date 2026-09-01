extends StaticBody3D

@onready var label_3d = get_node_or_null("Label3D")

func _ready():
	if label_3d:
		label_3d.visible = false

func get_interaction_prompt() -> String:
	return "[E] Odpocznij na Pryczy (+50 HP) 🛏️"

func interact():
	GameManager.player_stats.hp = min(GameManager.player_stats.max_hp, GameManager.player_stats.hp + 50)
	if SoundManager: SoundManager.play_level_up()
	GameManager.add_log("Rest", "😴 RESTED ON BUNK: Regenerated +50 HP and recovered energy.")
	GameManager.emit_signal("stats_changed")
