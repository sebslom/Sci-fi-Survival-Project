class_name CustomPortal extends Area3D

@export var portal_name: String = "Stacjonarny Portal Kwantowy"
@export var target_scene_path: String = "" # Hardcoded scene path for DLC/Special portals (e.g. "res://scenes/locations/CloneFactory.tscn")
@export var bypass_procedural_seed: bool = false # True for hardcoded non-procedural mission portals
@export var target_biome: String = "mars" # "mars", "canyon", "ice", "town", "custom", "clone_factory", "bazar"
@export var custom_seed: int = 133742
@export var is_mobile: bool = false

@onready var mesh_ring = get_node_or_null("RingMesh")
@onready var mesh_vortex = get_node_or_null("VortexMesh")
@onready var portal_light = get_node_or_null("PortalLight")
@onready var label_3d = get_node_or_null("Label3D")

var is_teleporting: bool = false
var anim_timer: float = 0.0

func _ready():
	add_to_group("portal")
	add_to_group("custom_portal")
	if label_3d: label_3d.visible = false
	body_entered.connect(_on_body_entered)
	_update_portal_visuals()

func _process(delta):
	anim_timer += delta * 2.0
	if mesh_ring:
		mesh_ring.rotate_y(delta * 1.5)
	if mesh_vortex:
		mesh_vortex.rotation.z = sin(anim_timer) * 0.1

func _update_portal_visuals():
	var color = Color("#00f3ff") # Cyan default
	match target_biome:
		"mars": color = Color("#f97316") # Mars Red-Orange
		"canyon": color = Color("#d97706") # Canyon Amber
		"ice": color = Color("#38bdf8") # Ice Blue
		"town": color = Color("#10b981") # Settlement Emerald
		"custom": color = Color("#a855f7") # Anomaly Purple
		"clone_factory": color = Color("#dc2626") # Deep Crimson Bio Red
		"bazar": color = Color("#eab308") # Golden Trade Yellow

	if portal_light:
		portal_light.light_color = color

	if mesh_vortex and mesh_vortex.material_override:
		var mat = mesh_vortex.material_override.duplicate() as StandardMaterial3D
		if mat:
			mat.albedo_color = color
			mat.emission = color
			mesh_vortex.material_override = mat

func tune_portal(biome: String, target_seed: int):
	target_biome = biome
	custom_seed = target_seed
	_update_portal_visuals()
	if GameManager:
		GameManager.add_log("Portal", "🌀 Dostrojono portal [%s] do biomu [%s] z seedem #%d" % [portal_name, biome.to_upper(), target_seed])

func get_interaction_prompt() -> String:
	if bypass_procedural_seed or not target_scene_path.is_empty():
		return "[E] Wejdź do: %s 🌀" % portal_name
	var biome_title = target_biome.to_upper()
	return "[E] Otwórz Konfigurator Portalu Kwantowego (%s) 🌀" % biome_title

func _on_body_entered(body):
	if body and body.is_in_group("player") and not is_teleporting:
		execute_jump()

func interact():
	if is_teleporting: return
	
	if bypass_procedural_seed or not target_scene_path.is_empty():
		execute_jump()
	else:
		var hud_nodes = get_tree().get_nodes_in_group("hud")
		if hud_nodes.size() > 0 and hud_nodes[0].has_method("open_portal_tuning_dialog"):
			hud_nodes[0].open_portal_tuning_dialog(self)
		else:
			execute_jump()

func execute_jump():
	if is_teleporting: return
	is_teleporting = true

	if SoundManager: SoundManager.play_teleport()

	if GameManager:
		if bypass_procedural_seed or not target_scene_path.is_empty():
			var scene_to_load = target_scene_path
			if scene_to_load.is_empty():
				if target_biome == "clone_factory": scene_to_load = "res://scenes/locations/CloneFactory.tscn"
				elif target_biome == "bazar": scene_to_load = "res://scenes/locations/MerchantHub.tscn"

			GameManager.add_log("Portal", "🌀 Aktywacja Portalu Dedykowanego -> %s..." % portal_name)
			GameManager.travel_to_custom_scene(scene_to_load)
		else:
			GameManager.current_expedition_seed = custom_seed
			var dest_scene = "res://scenes/locations/ExpeditionMars.tscn"
			if target_biome == "canyon": dest_scene = "res://scenes/locations/ExpeditionCanyon.tscn"
			elif target_biome == "ice": dest_scene = "res://scenes/locations/ExpeditionIce.tscn"
			elif target_biome == "town": dest_scene = "res://scenes/locations/City.tscn"

			GameManager.current_expedition_scene = dest_scene
			GameManager.add_log("Portal", "🌀 Otwieranie Tunelu Podprzestrzennego -> Biom: %s (Seed: #%d)..." % [target_biome.to_upper(), custom_seed])

			if GameManager.active_location == "house":
				GameManager.travel_to("expedition")
			else:
				GameManager.travel_to("house")

	get_tree().create_timer(2.0).timeout.connect(func(): is_teleporting = false)
