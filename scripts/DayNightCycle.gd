extends DirectionalLight3D

@export var day_length_minutes: float = 24.0 # 24 real minutes = 24 in-game hours
@export var max_sun_energy: float = 1.2
@export var max_ambient_energy: float = 0.6
@export var night_fog_density: float = 0.04
@export var day_fog_density: float = 0.008

@export var world_environment: WorldEnvironment

var time_of_day: float = 12.0 # 12.0 = Noon, 0.0 = Midnight

func _ready():
	add_to_group("day_night_cycle")
	_find_world_environment()

func _find_world_environment():
	if not world_environment:
		var envs = get_tree().get_nodes_in_group("world_environment")
		if envs.size() > 0:
			world_environment = envs[0]
		else:
			world_environment = get_parent().get_node_or_null("WorldEnvironment")

func _process(delta):
	# 1 real minute = 1 in-game hour -> 24 real mins = 24 in-game hours
	var time_speed = 24.0 / (day_length_minutes * 60.0)
	time_of_day = fmod(time_of_day + time_speed * delta, 24.0)

	# Sun rotation: 0h = -90 deg (night), 6h = 0 deg (sunrise), 12h = 90 deg (noon), 18h = 180 deg (sunset)
	var sun_angle_rad = deg_to_rad((time_of_day / 24.0) * 360.0 - 90.0)
	rotation.x = sun_angle_rad

	# Calculate day factor: 1.0 at noon, 0.0 at night
	var day_factor = clamp(sin(sun_angle_rad), 0.0, 1.0)

	light_energy = max_sun_energy * day_factor
	light_color = Color("#ffedd5").lerp(Color("#f97316"), 1.0 - day_factor) # Warm orange sunset to bright daylight

	if world_environment and world_environment.environment:
		var env = world_environment.environment
		env.ambient_light_energy = max_ambient_energy * day_factor
		
		if env.fog_enabled:
			env.fog_density = lerp(night_fog_density, day_fog_density, day_factor)

	if GameManager and randf() < 0.005:
		var hour_int = int(time_of_day)
		var min_int = int(fmod(time_of_day * 60.0, 60.0))
		# Log time occasionally
