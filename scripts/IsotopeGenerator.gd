extends StaticBody3D

@onready var label_3d = get_node_or_null("Label3D")
@onready var mesh_inst = get_node_or_null("MeshInstance3D")

var radiation_radius: float = 10.0
var timer: Timer

func _ready():
	BasePowerGrid.register_isotope_generator(self)
	if PowerGrid:
		PowerGrid.register_producer(60.0)
	
	timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_radiation_tick)
	add_child(timer)
	
	_update_visuals()

func _exit_tree():
	if PowerGrid:
		PowerGrid.unregister_producer(60.0)

func _update_visuals():
	if label_3d:
		label_3d.text = "☢️ GENERATOR IZOTOPOWY (+60 kW)\n⚠️ PROMIENIOWANIE W PROMIENIU 10m ⚠️"
		label_3d.modulate = Color("#a855f7")

func _on_radiation_tick():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var player = players[0]
	var dist = global_position.distance_to(player.global_position)
	
	if dist <= radiation_radius:
		var has_hazmat = GameManager.get_gas_mask_filtration_grade() >= 3
		if not has_hazmat:
			GameManager.player_stats.radiation = min(100, GameManager.player_stats.radiation + 3)
			GameManager.emit_signal("stats_changed")
			if SoundManager and randf() < 0.3: SoundManager.play_hit()
			GameManager.add_log("Promieniowanie", "☢️ OSTRZEŻENIE: Znajdujesz się w strefie promieniowania Reaktora Izotopowego!")

func interact():
	if SoundManager: SoundManager.play_pick()
	GameManager.add_log("Zasilanie", "☢️ GENERATOR IZOTOPOWY: Generuje +60 kW czystej energii jądrowej dla bazy.")
