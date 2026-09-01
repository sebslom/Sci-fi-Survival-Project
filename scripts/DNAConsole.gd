extends StaticBody3D

@export var console_name: String = "Clone DNA Extraction Terminal"
var is_extracted: bool = false

@onready var label_3d = get_node_or_null("Label3D")

func _ready():
	add_to_group("dna_console")
	if label_3d: label_3d.visible = false

func get_interaction_prompt() -> String:
	if is_extracted:
		return "🧬 Terminal DNA [POBRANO DANE 🟢]"
	return "[E] Download Clone DNA Sequence 🧬"

func interact():
	if is_extracted:
		if GameManager: GameManager.add_log("Terminal", "ℹ️ DNA sequence has already been downloaded from this terminal.")
		return

	is_extracted = true
	if SoundManager: SoundManager.play_level_up()
	if GameManager:
		GameManager.add_log("Downloading", "🧬 Downloaded pure Clone DNA sequence (+150 EXP, +1x DNA Blueprint)!")
		GameManager.player_stats.exp += 150
		GameManager.inventory.append({
			"id": "blueprint_dna_console",
			"name": "DNA Cloning Blueprint",
			"type": "blueprint",
			"count": 1,
			"weight": 0.5,
			"icon": "🧬",
			"desc": "Genome data extracted from Clone Factory Terminal"
		})
		GameManager.emit_signal("inventory_changed")
		GameManager.emit_signal("stats_changed")

	if label_3d:
		label_3d.text = "🧬 TERMINAL DNA [POBRANO DANE 🟢]"
		label_3d.modulate = Color("#10b981")
