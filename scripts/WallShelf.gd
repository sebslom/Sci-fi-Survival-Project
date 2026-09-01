extends StaticBody3D

func _ready():
	add_to_group("placed_structure")
	add_to_group("wall_shelf")
	add_to_group("interactive")

func get_interaction_prompt() -> String:
	return "📐 WISZĄCA PÓŁKA SCIENNA [Platforma Kolizyjna]"

func interact(player_node = null):
	if GameManager: GameManager.add_log("Base", "📐 Półka ścienna gotowa do układania przedmiotów.")
