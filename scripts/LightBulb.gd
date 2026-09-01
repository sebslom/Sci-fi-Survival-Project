extends StaticBody3D

@export var power_consumption: float = 1.0 # 1.0 kW

var is_switched_on: bool = false
var is_physically_lit: bool = false

@onready var omni_light = get_node_or_null("OmniLight3D")
@onready var mesh_inst = get_node_or_null("MeshInstance3D")

func _ready():
	add_to_group("placed_structure")
	add_to_group("light_bulb")
	add_to_group("interactive")

	if PowerGrid:
		PowerGrid.power_outage.connect(_on_power_outage)
		PowerGrid.power_restored.connect(_on_power_restored)

	_update_visuals()

func _exit_tree():
	if is_switched_on and PowerGrid:
		PowerGrid.unregister_consumer(power_consumption)

func get_interaction_prompt() -> String:
	var online_str = " (BRAK PRĄDU ⚡)" if (is_switched_on and not is_physically_lit) else ""
	var state_str = ("WŁĄCZONA 💡" if is_switched_on else "WYŁĄCZONA 🔌") + online_str
	return "💡 OŚWIETLENIE BAZY (%.1f kW) [%s] [E]" % [power_consumption, state_str]

func interact(player_node = null):
	is_switched_on = not is_switched_on

	if PowerGrid:
		if is_switched_on:
			PowerGrid.register_consumer(power_consumption)
		else:
			PowerGrid.unregister_consumer(power_consumption)

	if is_switched_on:
		if PowerGrid and PowerGrid.is_power_online():
			is_physically_lit = true
			if SoundManager: SoundManager.play_pick()
			if GameManager: GameManager.add_log("Power", "💡 Włączono oświetlenie żarówki (Pobór: %.1f kW)." % power_consumption)
		else:
			is_physically_lit = false
			if SoundManager: SoundManager.play_hit()
			if GameManager: GameManager.add_log("Power", "⚠️ OSTRZEŻENIE: Brak wystarczającego prądu w sieci bazy!")
	else:
		is_physically_lit = false
		if SoundManager: SoundManager.play_pick()
		if GameManager: GameManager.add_log("Power", "🔌 Wyłączono żarówkę.")

	_update_visuals()

func _on_power_outage():
	is_physically_lit = false
	_update_visuals()

func _on_power_restored():
	if is_switched_on:
		is_physically_lit = true
		_update_visuals()

func _update_visuals():
	if omni_light:
		omni_light.visible = is_physically_lit

	if mesh_inst:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color("#fef08a") if is_physically_lit else Color("#475569")
		mat.emission_enabled = is_physically_lit
		mat.emission = Color("#fef08a")
		mat.emission_energy_multiplier = 2.5 if is_physically_lit else 0.0
		mesh_inst.material_override = mat
