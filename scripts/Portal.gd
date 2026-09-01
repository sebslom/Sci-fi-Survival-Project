extends Area3D

var active_seed: int = 0
var is_teleporting: bool = false

func _ready():
	add_to_group("portal")
	body_entered.connect(_on_body_entered)
	if GameManager:
		active_seed = GameManager.current_expedition_seed

func set_expedition_seed(new_seed: int):
	active_seed = new_seed

func get_interaction_prompt() -> String:
	if GameManager and GameManager.active_location == "house":
		return "[E] Skok na Ekspedycję Marsjańską 🚀"
	else:
		return "[E] Powrót do Schronu Bazy 🛡️"

func _on_body_entered(body):
	if body and body.is_in_group("player") and not is_teleporting:
		interact()

func interact():
	if is_teleporting: return
	is_teleporting = true
	
	if SoundManager:
		SoundManager.play_teleport()

	if GameManager:
		if GameManager.active_location == "house":
			GameManager.add_log("Portal", "🌀 Aktywacja Portalu: Podróż na Ekspedycję Marsjańską...")
			GameManager.travel_to("expedition")
		else:
			GameManager.add_log("Portal", "🏠 Aktywacja Portalu: Powrót do Schronu Bazy...")
			GameManager.travel_to("house")

	get_tree().create_timer(1.5).timeout.connect(func(): is_teleporting = false)
