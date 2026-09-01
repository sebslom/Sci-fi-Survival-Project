@tool
class_name AssetStructureGenerator
extends EditorScript

# Narzędzie EditorScript dla Godot Engine 4.6
# Automatycznie generuje pełną strukturę folderów zasobów w projekcie oraz tworzy pliki placeholderów:
# - Modele 3D (.glb) w res://assets/models/
# - Tekstury (.png) w res://assets/textures/
# - Efekty audio (.wav) w res://assets/sounds/

func _run():
	print("🚀 [AssetStructureGenerator] Rozpoczynanie generowania pełnej struktury zasobów i placeholderów...")
	generate_asset_structure()

static func generate_asset_structure():
	var dirs_to_create = [
		"res://assets/models/characters/",
		"res://assets/models/weapons/",
		"res://assets/models/environment/",
		"res://assets/models/structures/",
		"res://assets/models/base_building/",
		"res://assets/models/items_weapons/",
		"res://assets/models/props/",
		"res://assets/textures/terrain/",
		"res://assets/textures/environment/",
		"res://assets/textures/decorations/",
		"res://assets/textures/ui/",
		"res://assets/textures/ui_icons/",
		"res://assets/textures/items/",
		"res://assets/textures/materials/",
		"res://assets/sounds/sfx/weapons/",
		"res://assets/sounds/sfx/footsteps/",
		"res://assets/sounds/sfx/ui/",
		"res://assets/sounds/sfx/ambience/",
		"res://assets/sounds/weapons/",
		"res://assets/sounds/ambient/",
		"res://assets/sounds/ui/",
		"res://assets/sounds/music/"
	]

	for d in dirs_to_create:
		var err = DirAccess.make_dir_recursive_absolute(d)
		if err == OK:
			print("📁 Utworzono folder: ", d)

	# 1. Modele 3D Placeholder .glb (Format GLTF v2)
	var glb_placeholders = [
		"res://assets/models/characters/scout_alpha.glb",
		"res://assets/models/characters/player_body.glb",
		"res://assets/models/characters/clone_defect.glb",
		"res://assets/models/characters/clone_guard.glb",
		"res://assets/models/characters/mutant_beast.glb",
		"res://assets/models/characters/clone_sentry.glb",
		"res://assets/models/characters/goliat_boss.glb",
		"res://assets/models/characters/boss_goliat.glb",
		"res://assets/models/characters/boss_architect.glb",
		"res://assets/models/characters/npc_merchant.glb",
		"res://assets/models/characters/space_bug.glb",
		"res://assets/models/characters/mars_jumper.glb",
		"res://assets/models/base_building/dome_shield.glb",
		"res://assets/models/base_building/wall_scrap.glb",
		"res://assets/models/base_building/mirror_frame.glb",
		"res://assets/models/base_building/wall_shelf.glb",
		"res://assets/models/base_building/wall_cabinet.glb",
		"res://assets/models/base_building/military_crate.glb",
		"res://assets/models/base_building/umbrella_closed.glb",
		"res://assets/models/base_building/umbrella_open.glb",
		"res://assets/models/base_building/light_bulb.glb",
		"res://assets/models/base_building/generator_isotope.glb",
		"res://assets/models/base_building/battery_bank.glb",
		"res://assets/models/base_building/portal_frame.glb",
		"res://assets/models/base_building/boss_portal.glb",
		"res://assets/models/items_weapons/laser_pistol.glb",
		"res://assets/models/items_weapons/tactical_flashlight.glb",
		"res://assets/models/items_weapons/scrap_metal.glb",
		"res://assets/models/items_weapons/battery_cell.glb",
		"res://assets/models/items_weapons/plastic_parts.glb",
		"res://assets/models/items_weapons/alien_core.glb",
		"res://assets/models/environment/crystal_node.glb",
		"res://assets/models/environment/factory_conveyor.glb",
		"res://assets/models/environment/merchant_stall.glb",
		"res://assets/models/weapons/rifle_plasma.glb",
		"res://assets/models/weapons/laser_pistol.glb",
		"res://assets/models/weapons/tactical_flashlight.glb",
		"res://assets/models/environment/rock_boulder_01.glb",
		"res://assets/models/environment/martian_crystal.glb",
		"res://assets/models/structures/wall_module.glb",
		"res://assets/models/structures/floor_module.glb",
		"res://assets/models/structures/decon_chamber.glb",
		"res://assets/models/props/crate_military.glb",
		"res://assets/models/props/storage_chest.glb",
		"res://assets/models/props/light_bulb.glb",
		"res://assets/models/props/painting.glb",
		"res://assets/models/props/umbrella.glb"
	]
	for path in glb_placeholders:
		_create_glb_placeholder(path)

	# 2. Tekstury Placeholder .png (Klasa Image PNG)
	var png_placeholders = [
		"res://assets/textures/terrain/martian_sand_albedo.png",
		"res://assets/textures/terrain/martian_rock_normal.png",
		"res://assets/textures/terrain/canyon_rock_albedo.png",
		"res://assets/textures/terrain/shelter_floor_albedo.png",
		"res://assets/textures/terrain/city_floor_albedo.png",
		"res://assets/textures/terrain/ice_surface_albedo.png",
		"res://assets/textures/environment/mars_sand_albedo.png",
		"res://assets/textures/environment/space_skybox.png",
		"res://assets/textures/environment/factory_floor.png",
		"res://assets/textures/environment/toxic_acid_puddle.png",
		"res://assets/textures/decorations/painting_1.png",
		"res://assets/textures/decorations/painting_2.png",
		"res://assets/textures/decorations/painting_3.png",
		"res://assets/textures/ui/crosshair_dot.png",
		"res://assets/textures/ui/hud_health_bar.png",
		"res://assets/textures/ui/chat_background.png",
		"res://assets/textures/ui/paperdoll_frame.png",
		"res://assets/textures/ui/hotbar_slot.png",
		"res://assets/textures/ui_icons/icon_health.png",
		"res://assets/textures/ui_icons/icon_hunger.png",
		"res://assets/textures/ui_icons/icon_flashlight.png",
		"res://assets/textures/ui_icons/icon_scrap.png",
		"res://assets/textures/ui_icons/icon_alien_core.png",
		"res://assets/textures/items/icon_flashlight.png",
		"res://assets/textures/items/icon_bandage.png",
		"res://assets/textures/items/icon_battery.png",
		"res://assets/textures/items/icon_keycard.png",
		"res://assets/textures/items/icon_scrap.png",
		"res://assets/textures/items/icon_crystal.png",
		"res://assets/textures/materials/metal_rust_albedo.png",
		"res://assets/textures/materials/plastic_dark_albedo.png",
		"res://assets/textures/materials/glass_window_albedo.png"
	]
	for path in png_placeholders:
		_create_png_placeholder(path)

	# 3. Audio Placeholder .wav (Nagłówek RIFF/WAVE PCM) w res://assets/sounds/
	var wav_placeholders = [
		"res://assets/sounds/weapons/laser_shot.wav",
		"res://assets/sounds/weapons/melee_swing.wav",
		"res://assets/sounds/weapons/flashlight_click.wav",
		"res://assets/sounds/sfx/weapons/shoot_laser.wav",
		"res://assets/sounds/sfx/weapons/melee_hit.wav",
		"res://assets/sounds/sfx/footsteps/step_sand.wav",
		"res://assets/sounds/sfx/footsteps/step_metal.wav",
		"res://assets/sounds/ambient/wind_mars.wav",
		"res://assets/sounds/ambient/sandstorm_loop.wav",
		"res://assets/sounds/ambient/shelter_generator.wav",
		"res://assets/sounds/sfx/ambience/wind_dust_storm.wav",
		"res://assets/sounds/sfx/ambience/shelter_hum.wav",
		"res://assets/sounds/ui/click.wav",
		"res://assets/sounds/ui/craft_success.wav",
		"res://assets/sounds/ui/error_buzz.wav",
		"res://assets/sounds/sfx/ui/button_click.wav",
		"res://assets/sounds/sfx/ui/item_pickup.wav",
		"res://assets/sounds/sfx/ui_click.wav",
		"res://assets/sounds/sfx/flashlight_toggle.wav",
		"res://assets/sounds/sfx/gun_shoot_laser.wav",
		"res://assets/sounds/sfx/gun_jam_error.wav",
		"res://assets/sounds/sfx/portal_activate.wav",
		"res://assets/sounds/sfx/clone_explode.wav",
		"res://assets/sounds/sfx/error_no_power.wav",
		"res://assets/sounds/music/ambient_mars_theme.wav",
		"res://assets/sounds/music/ambient_mars_surface.wav",
		"res://assets/sounds/music/clone_factory_theme.wav",
		"res://assets/sounds/music/boss_fight_goliat.wav",
		"res://assets/sounds/music/safezone_merchant.wav"
	]
	for path in wav_placeholders:
		_create_wav_placeholder(path)

	print("✨ [AssetStructureGenerator] SUKCES! Pełna struktura zasobów i pliki placeholderów zostały pomyślnie wygenerowane.")

static func _create_png_placeholder(path: String):
	if FileAccess.file_exists(path): return
	var img = Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.95, 1.0, 0.8)) # Cyan placeholder color
	var err = img.save_png(path)
	if err == OK:
		print("🖼️ Utworzono plik PNG: ", path)

static func _create_glb_placeholder(path: String):
	if FileAccess.file_exists(path): return
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		# Prawidłowy nagłówek binarny pliku GLB (GLTF v2)
		file.store_32(0x46544C67) # Magiczna wartość "glTF"
		file.store_32(2)          # Wersja 2
		file.store_32(20)         # Całkowita długość pliku
		file.store_32(0)          # Długość pierwszego chunka (JSON)
		file.store_32(0x4E4F534A) # Typ chunka "JSON"
		file.close()
		print("📦 Utworzono plik GLB: ", path)

static func _create_wav_placeholder(path: String, force_overwrite: bool = false):
	if not force_overwrite and FileAccess.file_exists(path):
		var check_file = FileAccess.open(path, FileAccess.READ)
		if check_file and check_file.get_length() > 200:
			check_file.close()
			return
		if check_file: check_file.close()

	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var data_samples = 512
		var data_bytes = data_samples * 2 # 1024 bytes

		file.store_string("RIFF")
		file.store_32(36 + data_bytes) # Total file size - 8
		file.store_string("WAVE")
		file.store_string("fmt ")
		file.store_32(16)          # PCM format chunk size
		file.store_16(1)           # Audio format PCM = 1
		file.store_16(1)           # Mono = 1
		file.store_32(22050)       # Sample Rate = 22050 Hz
		file.store_32(22050 * 2)   # Byte Rate = 44100
		file.store_16(2)           # Block Align = 2 bytes
		file.store_16(16)          # Bits Per Sample = 16
		file.store_string("data")
		file.store_32(data_bytes)   # Subchunk2 size

		# Store 512 16-bit PCM silent samples
		for i in range(data_samples):
			file.store_16(0)

		file.close()
		print("🔊 Utworzono poprawny plik WAV z samplami: ", path)
