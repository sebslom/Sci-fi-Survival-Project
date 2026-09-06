extends Node3D

@onready var map_builder = $MapBuilder
@onready var player = $Player

var current_location_instance: Node = null

func _ready():
	AssetStructureGenerator.generate_asset_structure()
	GameManager.location_changed.connect(_on_location_changed)
	load_active_location()
	clean_debug_meshes()

func load_active_location():
	if GameManager and GameManager.has_method("save_base_structures"):
		GameManager.save_base_structures()

	if current_location_instance:
		current_location_instance.queue_free()
		current_location_instance = null

	var scene_path = ""
	var loc = GameManager.active_location

	if loc == "house":
		scene_path = "res://scenes/locations/Shelter.tscn"
	elif loc == "town":
		scene_path = "res://scenes/locations/City.tscn"
	elif loc == "expedition":
		scene_path = GameManager.current_expedition_scene
	elif loc == "dev":
		scene_path = "res://scenes/locations/DevScene.tscn"
	elif loc == "custom_scene" and not GameManager.custom_destination_scene.is_empty():
		scene_path = GameManager.custom_destination_scene

	if ResourceLoader.exists(scene_path):
		var packed_scene = load(scene_path)
		if packed_scene:
			current_location_instance = packed_scene.instantiate()
			map_builder.add_child(current_location_instance)

	if loc == "house":
		player.global_position = Vector3(16.0, 1.2, 25.0)
		if GameManager and GameManager.has_method("restore_base_structures"):
			GameManager.restore_base_structures(current_location_instance)
	elif loc == "expedition":
		player.global_position = Vector3(20.0, 1.2, 20.0)
	elif loc == "town":
		player.global_position = Vector3(15.0, 1.2, 22.0)
	elif loc == "dev":
		player.global_position = Vector3(30.0, 1.2, 30.0)
	else:
		player.global_position = Vector3(20.0, 1.2, 20.0)

	if loc != "house":
		_spawn_expedition_return_portal()

	clean_debug_meshes()

func _spawn_expedition_return_portal():
	var existing = get_tree().get_nodes_in_group("return_portal")
	for p in existing:
		if is_instance_valid(p):
			return

	var portal_scene = load("res://scenes/prefabs/CustomPortal.tscn")
	if portal_scene and current_location_instance:
		var p_inst = portal_scene.instantiate()
		p_inst.add_to_group("return_portal")
		p_inst.portal_name = "Return Portal to Base"
		p_inst.target_scene_path = "res://scenes/locations/Shelter.tscn"
		p_inst.bypass_procedural_seed = true
		p_inst.target_biome = "town"
		
		var spawn_pos = player.global_position + Vector3(-3.5, 0.0, 3.5)
		p_inst.global_position = spawn_pos
		current_location_instance.add_child(p_inst)
		if GameManager:
			GameManager.add_log("Portal", "🌀 Return Portal to Base spawned at " + str(spawn_pos))

func clean_debug_meshes():
	# 1. Ensure only 1 player node exists in scene tree
	var player_nodes = get_tree().get_nodes_in_group("player")
	for p in player_nodes:
		if p and is_instance_valid(p) and p != player:
			p.queue_free()

	# 2. Remove all debug nodes in group 'debug'
	var debug_nodes = get_tree().get_nodes_in_group("debug")
	for node in debug_nodes:
		if node and is_instance_valid(node):
			node.queue_free()

	# 3. Hide blue multiplayer secondary player placeholders in singleplayer mode
	var mp_placeholders = get_tree().get_nodes_in_group("multiplayer_placeholder")
	for p in mp_placeholders:
		if p and is_instance_valid(p) and not p.is_in_group("player"):
			p.visible = false

func _on_location_changed(_new_loc):
	load_active_location()
