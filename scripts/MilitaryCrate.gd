extends "res://scripts/BaseStorageChest.gd"

func _ready():
	super._ready()
	max_slots = 16
	hp = 120.0
	max_hp = 120.0
	add_to_group("military_crate")

func get_interaction_prompt() -> String:
	return "[E] Otwórz Wojskową Skrzynię Przemysłową [%d/%d]" % [stored_items.size(), max_slots]
