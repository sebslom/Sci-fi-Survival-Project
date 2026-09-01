extends StaticBody3D

@export var artwork_colors: Array[Color] = [
	Color("#00f3ff"), # Cyberpunk Neon
	Color("#f59e0b"), # Martian Sunset
	Color("#10b981"), # Bio-Dome Forest
	Color("#ef4444"), # Emission Anomaly
	Color("#a855f7")  # Deep Space Nebula
]

@export var artwork_titles: Array[String] = [
	"🖼️ Neonowa Pustynia",
	"🖼️ Zachód Słońca na Marsie",
	"🖼️ Ziemie Odrzucone",
	"🖼️ Fala Emisji #09",
	"🖼️ Mgławica Sci-Fi Survival"
]

var current_idx: int = 0
@onready var mesh_inst = get_node_or_null("MeshInstance3D")

func _ready():
	add_to_group("placed_structure")
	add_to_group("painting")
	add_to_group("interactive")
	_update_artwork()

func get_interaction_prompt() -> String:
	return "%s [E - Zmień Obraz]" % artwork_titles[current_idx]

func interact(player_node = null):
	current_idx = (current_idx + 1) % artwork_colors.size()
	_update_artwork()
	if SoundManager: SoundManager.play_pick()
	if GameManager: GameManager.add_log("Base", "🖼️ Zmieniono wygląd obrazu na: " + artwork_titles[current_idx])

func _update_artwork():
	if not mesh_inst: return
	var mat = StandardMaterial3D.new()
	var col = artwork_colors[current_idx]
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.4
	mat.roughness = 0.2
	mesh_inst.material_override = mat
