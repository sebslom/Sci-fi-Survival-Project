extends StaticBody3D

@onready var sub_viewport = $SubViewport
@onready var mirror_quad = $MirrorQuad
@onready var preview_mesh = $SubViewport/PlayerPreviewMesh
@onready var preview_light = $SubViewport/DirectionalLight3D

func _ready():
	add_to_group("placed_structure")
	set("building_type", "mirror")
	_setup_viewport_texture()
	_update_character_preview()

	if GameManager:
		GameManager.player_model_changed.connect(func(_idx): _update_character_preview())
		GameManager.inventory_changed.connect(_update_character_preview)
		GameManager.stats_changed.connect(_update_character_preview)

func _setup_viewport_texture():
	if not sub_viewport or not mirror_quad: return
	
	var mat = StandardMaterial3D.new()
	mat.roughness = 0.05
	mat.metallic = 0.95
	
	var tex = sub_viewport.get_texture()
	mat.albedo_texture = tex
	mat.emission_enabled = true
	mat.emission_texture = tex
	mat.emission_energy_multiplier = 0.8
	
	mirror_quad.material_override = mat

func _update_character_preview():
	if not preview_mesh: return

	var model_idx = GameManager.selected_model_idx if GameManager else 0
	var mat = StandardMaterial3D.new()
	match model_idx:
		0: # Alpha Scout
			mat.albedo_color = Color("#06b6d4")
			mat.emission_enabled = true; mat.emission = Color("#00f3ff"); mat.emission_energy_multiplier = 0.5
		1: # Heavy Commando
			mat.albedo_color = Color("#f59e0b"); mat.roughness = 0.3; mat.metallic = 0.8
		2: # Bio-Hazard Suit
			mat.albedo_color = Color("#10b981"); mat.roughness = 0.9
		3: # Tech Engineer
			mat.albedo_color = Color("#a855f7")
			mat.emission_enabled = true; mat.emission = Color("#a855f7"); mat.emission_energy_multiplier = 0.6

	preview_mesh.material_override = mat

func interact():
	if SoundManager: SoundManager.play_pick()
	if GameManager:
		GameManager.add_log("Lustro", "🪞 Podgląd 3D: " + GameManager.player_name + " (Pancerz: " + str(GameManager.player_stats.suit_integrity) + "%)")
