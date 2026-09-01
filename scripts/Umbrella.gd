extends StaticBody3D

var is_open: bool = false

@onready var mesh_closed = get_node_or_null("MeshClosed")
@onready var mesh_open = get_node_or_null("MeshOpen")

func _ready():
	add_to_group("placed_structure")
	add_to_group("umbrella")
	add_to_group("interactive")
	_update_state()

func get_interaction_prompt() -> String:
	var state_str = "Rozłożony ⛱️" if is_open else "Złożony ☂️"
	return "☂️ PARASOL OCHRONNY [%s] [E - Przełącz]" % state_str

func interact(player_node = null):
	is_open = not is_open
	_update_state()
	if SoundManager: SoundManager.play_pick()
	if GameManager: GameManager.add_log("Base", "☂️ Przełączono stan parasola na: " + ("ROZŁOŻONY ⛱️" if is_open else "ZŁOŻONY ☂️"))

func _update_state():
	if mesh_closed: mesh_closed.visible = not is_open
	if mesh_open: mesh_open.visible = is_open
