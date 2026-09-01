extends StaticBody3D

@export var is_open: bool = false
@export var open_angle_deg: float = 90.0

@onready var mesh_pivot = get_node_or_null("Pivot")
@onready var label_3d = get_node_or_null("Label3D")

var target_y_rot: float = 0.0

func _ready():
	add_to_group("placed_structure")
	add_to_group("interactive")
	add_to_group("door")
	_update_door_state()

func get_interaction_prompt() -> String:
	var state_str = "OPENED 🚪" if is_open else "CLOSED 🔒"
	return "🚪 BASE DOOR [%s] [E - Open/Close]" % state_str

func interact(player_node = null):
	is_open = not is_open
	_update_door_state()
	if SoundManager: SoundManager.play_pick()
	if GameManager: GameManager.add_log("Base", "🚪 " + ("OPENED" if is_open else "CLOSED") + " drzwi bazy.")

func _update_door_state():
	target_y_rot = deg_to_rad(open_angle_deg) if is_open else 0.0

func _process(delta):
	if mesh_pivot:
		mesh_pivot.rotation.y = lerp_angle(mesh_pivot.rotation.y, target_y_rot, delta * 8.0)
	elif self:
		rotation.y = lerp_angle(rotation.y, target_y_rot, delta * 8.0)
