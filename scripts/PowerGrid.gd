extends Node

signal power_restored
signal power_outage
signal power_grid_updated(total_supply: float, total_demand: float, is_online: bool)

var total_supply: float = 0.0
var total_demand: float = 0.0
var is_online: bool = true

func _ready():
	_recalculate_grid()

func register_producer(amount: float):
	total_supply = max(0.0, total_supply + amount)
	_recalculate_grid()
	if GameManager: GameManager.add_log("Zasilanie", "⚡ Zwiększono produkcję energii: +%.1f kW [Suma: %.1f kW]" % [amount, total_supply])

func unregister_producer(amount: float):
	total_supply = max(0.0, total_supply - amount)
	_recalculate_grid()
	if GameManager: GameManager.add_log("Zasilanie", "⚡ Zmniejszono produkcję energii: -%.1f kW [Suma: %.1f kW]" % [amount, total_supply])

func register_consumer(amount: float):
	total_demand = max(0.0, total_demand + amount)
	_recalculate_grid()

func unregister_consumer(amount: float):
	total_demand = max(0.0, total_demand - amount)
	_recalculate_grid()

func is_power_online() -> bool:
	return total_supply >= total_demand

func _recalculate_grid():
	var prev_online = is_online
	is_online = total_supply >= total_demand

	emit_signal("power_grid_updated", total_supply, total_demand, is_online)

	if not prev_online and is_online:
		emit_signal("power_restored")
		if GameManager: GameManager.add_log("Zasilanie", "🟢 ZASILANIE BAZY PRZYWRÓCONE! (Produkcja: %.1f kW / Pobór: %.1f kW)" % [total_supply, total_demand])
	elif prev_online and not is_online:
		emit_signal("power_outage")
		if GameManager: GameManager.add_log("Zasilanie", "🔴 AWARIA ZASILANIE BAZY! PRZECIĄŻENIE SIECI! (Produkcja: %.1f kW / Pobór: %.1f kW)" % [total_supply, total_demand])
