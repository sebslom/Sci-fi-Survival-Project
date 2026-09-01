extends StaticBody3D

@onready var label_3d = get_node_or_null("Label3D")

func _ready():
	if label_3d:
		label_3d.visible = false

func get_interaction_prompt() -> String:
	return "[E] Usiądź na Krześle Taktycznym 🪑"

func interact():
	if SoundManager: SoundManager.play_pick()
	GameManager.add_log("Odpoczynek", "🪑 Usiadłeś na krześle taktycznym w bazie. Odzyskiwanie kondycji...")
