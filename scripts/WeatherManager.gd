extends Node

signal weather_changed(new_weather_type)

enum WeatherType { CLEAR, SANDSTORM, TOXIC_FOG }

var current_weather: WeatherType = WeatherType.CLEAR
var weather_timer: float = 0.0
var weather_duration: float = 0.0
var is_transitioning: bool = false

var target_fog_density: float = 0.005
var target_fog_color: Color = Color("#202530")

func _ready():
	_schedule_next_weather_cycle()

func _schedule_next_weather_cycle():
	weather_timer = 0.0
	weather_duration = randf_range(40.0, 80.0)

func _process(delta):
	# Only run weather shifts in expedition maps or dev scene
	if GameManager.active_location in ["expedition", "dev"]:
		weather_timer += delta
		if weather_timer >= weather_duration:
			_schedule_next_weather_cycle()
			_trigger_random_weather_change()
			
		_update_environment_fog(delta)

func _trigger_random_weather_change():
	if current_weather == WeatherType.CLEAR:
		# 60% chance to start a Sandstorm on Mars/Canyon expeditions
		if randf() < 0.65:
			start_sandstorm()
	else:
		# Return to clear weather
		start_clear_weather()

func start_sandstorm():
	current_weather = WeatherType.SANDSTORM
	target_fog_density = 0.06
	target_fog_color = Color("#d97706") # Reddish-orange sandstorm tint
	
	if SoundManager:
		SoundManager.play_alarm()
	GameManager.add_log("Pogoda", "🌪️ OSTRZEŻENIE! NADCIĄGA BURZA PIASKOWA (SANDSTORM)! Widoczność spada do minimum.")
	emit_signal("weather_changed", "SANDSTORM")

func start_clear_weather():
	current_weather = WeatherType.CLEAR
	target_fog_density = 0.002
	target_fog_color = Color("#202530")
	
	GameManager.add_log("Pogoda", "🌤️ Burza piaskowa ustępuje. Przejrzystość nieba wraca do normy.")
	emit_signal("weather_changed", "CLEAR")

func _update_environment_fog(delta: float):
	var world_env = get_tree().root.find_child("WorldEnvironment", true, false)
	if not world_env or not world_env.environment:
		return

	var env = world_env.environment
	env.fog_enabled = true
	
	# Smoothly interpolate fog density & color
	env.fog_density = lerp(env.fog_density, target_fog_density, delta * 0.8)
	env.fog_light_color = env.fog_light_color.lerp(target_fog_color, delta * 0.8)
