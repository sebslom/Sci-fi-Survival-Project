extends Node

signal power_state_changed(is_online, generated, demand)

var solar_panels: Array = []
var isotope_generators: Array = []
var batteries: Array = []
var machines: Array = []

var total_generated: float = 0.0
var total_demand: float = 0.0
var is_power_online: bool = false

func _ready():
	_recalculate_power()

func register_solar_panel(panel_node):
	if not solar_panels.has(panel_node):
		solar_panels.append(panel_node)
		_recalculate_power()

func unregister_solar_panel(panel_node):
	solar_panels.erase(panel_node)
	_recalculate_power()

func register_isotope_generator(generator_node):
	if not isotope_generators.has(generator_node):
		isotope_generators.append(generator_node)
		_recalculate_power()

func unregister_isotope_generator(generator_node):
	isotope_generators.erase(generator_node)
	_recalculate_power()

func register_machine(machine_node):
	if not machines.has(machine_node):
		machines.append(machine_node)
		_recalculate_power()

func unregister_machine(machine_node):
	machines.erase(machine_node)
	_recalculate_power()

func register_battery(battery_node):
	if not batteries.has(battery_node):
		batteries.append(battery_node)
		_recalculate_power()

func _recalculate_power():
	total_generated = (solar_panels.size() * 15.0) + (isotope_generators.size() * 60.0) # Solar: +15 kW, Isotope: +60 kW
	total_demand = machines.size() * 7.0 # Average machine demand 7 kW
	
	is_power_online = (total_generated > 0.0 and total_generated >= total_demand) or (solar_panels.size() > 0 or isotope_generators.size() > 0)
	
	emit_signal("power_state_changed", is_power_online, total_generated, total_demand)
	
	# Update 3D labels on all machines
	for machine in machines:
		if is_instance_valid(machine) and machine.has_method("update_power_status"):
			machine.update_power_status(is_power_online)

func is_machine_powered(_machine_node) -> bool:
	return is_power_online
