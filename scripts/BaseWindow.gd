extends StaticBody3D

@export var is_reinforced: bool = true

func _ready():
	add_to_group("placed_structure")
	add_to_group("window")
