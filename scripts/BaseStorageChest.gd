extends StaticBody3D

@export var max_slots: int = 16
@export var hp: float = 100.0
@export var max_hp: float = 100.0

var stored_items: Array = []
var is_dead: bool = false

func _ready():
	add_to_group("interactable")
	add_to_group("interactive")
	add_to_group("storage_chest")
	add_to_group("placed_structure")

func get_interaction_prompt() -> String:
	return "[E] Open Storage Chest [%d/%d]" % [stored_items.size(), max_slots]

func interact(player_node = null):
	var hud_nodes = get_tree().get_nodes_in_group("hud")
	if hud_nodes.size() > 0 and hud_nodes[0].has_method("open_storage_chest_ui"):
		hud_nodes[0].open_storage_chest_ui(self)
	else:
		if GameManager:
			GameManager.add_log("Skrzynia", "📦 Otwieranie skrzyni magazynowej...")

func take_damage(amount: float):
	if is_dead: return
	hp -= amount
	if SoundManager: SoundManager.play_hit()
	if GameManager:
		GameManager.add_log("Skrzynia", "💥 Chest damaged: %d/%d HP" % [int(max(0, hp)), int(max_hp)])
	
	if hp <= 0.0:
		die()

func die():
	if is_dead: return
	is_dead = true
	
	if SoundManager: SoundManager.play_hit()
	if GameManager:
		GameManager.add_log("Skrzynia", "💥 CHEST DESTROYED! Loot dropped on ground!")

	# 1. Spawn all stored items onto the ground as physical InteractableItem3D objects
	for item in stored_items:
		if item and item is Dictionary:
			_spawn_scattered_physical_item(item)

	# 2. Spawn 1 physical "Skrzynia Wojskowa" item on the ground for player to collect
	var chest_item = {
		"id": "military_crate_item_" + str(randi()),
		"name": "Skrzynia Wojskowa",
		"type": "furniture",
		"furnitureType": "military_crate",
		"count": 1,
		"weight": 8.0,
		"icon": "📦",
		"desc": "Pojemna skrzynia wojskowa do stawiania w bazie [C]"
	}
	_spawn_scattered_physical_item(chest_item)

	queue_free()

func _spawn_scattered_physical_item(item_dict: Dictionary):
	if not GameManager: return
	var item_scene = load("res://scenes/prefabs/InteractableItem3D.tscn")
	if not item_scene: return

	var item_inst = item_scene.instantiate()
	item_inst.set("item_data", item_dict.duplicate(true))

	var offset = Vector3(randf_range(-0.8, 0.8), 0.5, randf_range(-0.8, 0.8))
	item_inst.global_position = global_position + offset

	get_parent().add_child(item_inst)

	if item_inst is RigidBody3D:
		item_inst.apply_central_impulse(Vector3(randf_range(-1.5, 1.5), randf_range(2.0, 3.5), randf_range(-1.5, 1.5)))
