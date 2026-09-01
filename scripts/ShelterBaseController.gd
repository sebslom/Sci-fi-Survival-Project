extends Node3D

@onready var power_console_label = get_node_or_null("PowerSubstation/ConsoleLabel")
@onready var base_light1 = get_node_or_null("CeilingLights/Light1")
@onready var base_light2 = get_node_or_null("CeilingLights/Light2")
@onready var base_light3 = get_node_or_null("CeilingLights/Light3")

func _ready():
	if BasePowerGrid:
		BasePowerGrid.power_state_changed.connect(_on_power_state_changed)
	
	# Register default pre-installed solar panels
	var solar_container = get_node_or_null("OutdoorSolarFarm")
	if solar_container:
		for child in solar_container.get_children():
			BasePowerGrid.register_solar_panel(child)

	# Register default batteries
	var battery_container = get_node_or_null("BatteryBank")
	if battery_container:
		for child in battery_container.get_children():
			BasePowerGrid.register_battery(child)

	# Register pre-installed base machines
	var machine_container = get_node_or_null("LogisticsModules")
	if machine_container:
		for child in machine_container.get_children():
			if child.has_method("update_power_status"):
				BasePowerGrid.register_machine(child)

	_update_power_display(BasePowerGrid.is_power_online, BasePowerGrid.total_generated, BasePowerGrid.total_demand)

func get_interaction_prompt() -> String:
	var state_str = "ONLINE 🟢" if BasePowerGrid.is_power_online else "OFFLINE 🔴"
	return "[E] Konsola Zasilania (Stan: %s) ⚡" % state_str

func _on_power_state_changed(is_online: bool, generated: float, demand: float):
	_update_power_display(is_online, generated, demand)

func _update_power_display(is_online: bool, generated: float, demand: float):
	if power_console_label:
		if is_online:
			power_console_label.text = "⚡ SIEC ZASILANIA BAZY\nProdukcja: %.1f kW | Pobór: %.1f kW\n[STAN: ONLINE 🟢]" % [generated, demand]
			power_console_label.modulate = Color("#38bdf8")
		else:
			power_console_label.text = "⚡ SIEC ZASILANIA BAZY\nProdukcja: %.1f kW | Pobór: %.1f kW\n[STAN: BRAK ZASILANIA 🔴]" % [generated, demand]
			power_console_label.modulate = Color("#ef4444")

	# Update ambient lighting
	var light_col = Color("#38bdf8") if is_online else Color("#ef4444")
	var light_energy = 1.8 if is_online else 0.4
	
	for light in [base_light1, base_light2, base_light3]:
		if light and light is OmniLight3D:
			light.light_color = light_col
			light.light_energy = light_energy

func interact():
	if SoundManager: SoundManager.play_pick()
	var state_str = "AKTYWNA 🟢" if BasePowerGrid.is_power_online else "OFFLINE 🔴"
	GameManager.add_log("Zasilanie", "⚡ KONSOLA SIECI ZASILANIA BAZY: Wygenerowano %.1f kW | Pobór: %.1f kW (Stan: %s)" % [BasePowerGrid.total_generated, BasePowerGrid.total_demand, state_str])
