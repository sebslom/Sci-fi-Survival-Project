extends WorldEnvironment

@export var enable_bloom: bool = true
@export var enable_ssao: bool = true
@export var enable_fog: bool = true
@export var glow_intensity: float = 1.8
@export var glow_bloom_threshold: float = 0.7

func _ready():
	_setup_environment()

func _setup_environment():
	if not environment:
		environment = Environment.new()

	# 1. ACES Tonemapping (Cinematic Color Grade)
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = 1.0
	environment.tonemap_white = 6.0

	# 2. Martian Procedural Infinite Horizon Sky
	environment.background_mode = Environment.BG_SKY
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#0f0502")
	sky_mat.sky_horizon_color = Color("#9a3412")
	sky_mat.ground_horizon_color = Color("#9a3412")
	sky_mat.ground_bottom_color = Color("#1e0804")
	sky_mat.sky_energy_multiplier = 1.2
	
	var sky_obj = Sky.new()
	sky_obj.sky_material = sky_mat
	environment.sky = sky_obj

	# 3. Glow / Bloom Effect (Shining portals & energy lamps)
	if enable_bloom:
		environment.glow_enabled = true
		environment.glow_intensity = glow_intensity
		environment.glow_strength = 1.2
		environment.glow_bloom = 0.35
		environment.glow_hdr_threshold = glow_bloom_threshold
		environment.glow_hdr_scale = 2.0
		environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT

	# 4. SSAO (Screen Space Ambient Occlusion for contact shadows)
	if enable_ssao:
		environment.ssao_enabled = true
		environment.ssao_radius = 1.8
		environment.ssao_intensity = 2.8
		environment.ssao_power = 1.5
		environment.ssao_detail = 0.5
		environment.ssao_horizon = 0.06

	# 5. Volumetric Atmospheric Fog
	if enable_fog:
		environment.volumetric_fog_enabled = true
		environment.volumetric_fog_density = 0.025
		environment.volumetric_fog_albedo = Color("#7c2d12") # Dark Martian Rust Red Haze
		environment.volumetric_fog_emission = Color("#451a03")
		environment.volumetric_fog_emission_energy = 0.2

	if GameManager:
		GameManager.add_log("Render", "✨ Zaaplikowano post-processing Sci-Fi Survival Project (Bloom, SSAO, Martian Horizon Sky).")
