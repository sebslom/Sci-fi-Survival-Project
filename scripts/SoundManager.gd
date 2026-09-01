extends Node

const SFX_CHANNELS_COUNT: int = 12

var sfx_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var current_sfx_index: int = 0

var sound_cache: Dictionary = {}

const SOUND_PATHS = {
	"shoot": "res://assets/sounds/sfx/gun_shoot_laser.wav",
	"laser": "res://assets/sounds/sfx/weapons/shoot_laser.wav",
	"plasma": "res://assets/sounds/weapons/laser_shot.wav",
	"shotgun": "res://assets/sounds/sfx/gun_shoot_laser.wav",
	"blade": "res://assets/sounds/weapons/melee_swing.wav",
	"hit": "res://assets/sounds/sfx/weapons/melee_hit.wav",
	"enemy_death": "res://assets/sounds/sfx/clone_explode.wav",
	"pick": "res://assets/sounds/sfx/ui/item_pickup.wav",
	"click": "res://assets/sounds/sfx/ui_click.wav",
	"craft": "res://assets/sounds/ui/craft_success.wav",
	"teleport": "res://assets/sounds/sfx/portal_activate.wav",
	"flashlight": "res://assets/sounds/sfx/flashlight_toggle.wav",
	"error": "res://assets/sounds/sfx/error_no_power.wav",
	"jam": "res://assets/sounds/sfx/gun_jam_error.wav",
	"step_sand": "res://assets/sounds/sfx/footsteps/step_sand.wav",
	"step_metal": "res://assets/sounds/sfx/footsteps/step_metal.wav",
	"wind": "res://assets/sounds/sfx/ambience/wind_dust_storm.wav"
}

const MUSIC_PATHS = {
	"mars_surface": "res://assets/sounds/music/ambient_mars_surface.wav",
	"clone_factory": "res://assets/sounds/music/clone_factory_theme.wav",
	"boss_fight": "res://assets/sounds/music/boss_fight_goliat.wav",
	"merchant": "res://assets/sounds/music/safezone_merchant.wav"
}

func _ready():
	for i in range(SFX_CHANNELS_COUNT):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)

	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)

	_preload_sounds()

func _preload_sounds():
	for key in SOUND_PATHS.keys():
		var path = SOUND_PATHS[key]
		if ResourceLoader.exists(path):
			var stream = load(path)
			if stream:
				sound_cache[key] = stream

	for key in MUSIC_PATHS.keys():
		var path = MUSIC_PATHS[key]
		if ResourceLoader.exists(path):
			var stream = load(path)
			if stream:
				sound_cache["music_" + key] = stream

func play_sfx(key: String, pitch_range: float = 0.0, volume_db: float = 0.0):
	var stream = sound_cache.get(key)
	if not stream and SOUND_PATHS.has(key):
		var path = SOUND_PATHS[key]
		if ResourceLoader.exists(path):
			stream = load(path)
			if stream: sound_cache[key] = stream

	if not stream:
		return

	var player = sfx_players[current_sfx_index]
	current_sfx_index = (current_sfx_index + 1) % SFX_CHANNELS_COUNT

	player.stream = stream
	player.volume_db = volume_db
	if pitch_range > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
	else:
		player.pitch_scale = 1.0

	player.play()

func play_shoot(): play_sfx("shoot", 0.05)
func play_laser(): play_sfx("laser", 0.05)
func play_plasma(): play_sfx("plasma", 0.08)
func play_shotgun(): play_sfx("shotgun", 0.1)
func play_blade(): play_sfx("blade", 0.08)
func play_walk(): play_sfx("step_sand", 0.1, -6.0)
func play_jump(): play_sfx("step_sand", 0.15)
func play_pick(): play_sfx("pick")
func play_teleport(): play_sfx("teleport")
func play_alarm(): play_sfx("wind", 0.0, 3.0)
func play_wipeout(): play_sfx("wind", 0.0, 6.0)
func play_hit(): play_sfx("hit", 0.1)
func play_enemy_death(): play_sfx("enemy_death", 0.1)
func play_level_up(): play_sfx("craft", 0.05)
func play_craft(): play_sfx("craft")
func play_mining(): play_sfx("hit", 0.15)
func play_click(): play_sfx("click")
func play_flashlight(): play_sfx("flashlight")
func play_error(): play_sfx("error")
func play_jam(): play_sfx("jam")

func play_music(track_key: String):
	var stream = sound_cache.get("music_" + track_key)
	if not stream and MUSIC_PATHS.has(track_key):
		var path = MUSIC_PATHS[track_key]
		if ResourceLoader.exists(path):
			stream = load(path)
			if stream: sound_cache["music_" + track_key] = stream

	if not stream: return

	if music_player.stream == stream and music_player.playing:
		return

	music_player.stream = stream
	music_player.volume_db = -4.0
	music_player.play()

func stop_music():
	if music_player:
		music_player.stop()
