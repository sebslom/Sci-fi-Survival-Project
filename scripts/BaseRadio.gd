extends StaticBody3D

var is_playing: bool = false
var channels = ["📻 Sygnał Nadawczy Sci-Fi Survival FM", "📻 Szum Stosowy Marsa", "📻 Stacja Kolonialna 88.4", "📻 Odczyt Anomalityczny"]
var current_channel: int = 0

func _ready():
	add_to_group("placed_structure")
	add_to_group("radio")
	add_to_group("interactive")

func get_interaction_prompt() -> String:
	var state = "ONLINE [" + channels[current_channel] + "]" if is_playing else "OFFLINE"
	return "📻 RADIO MARSJAŃSKIE [%s] [E]" % state

func interact(player_node = null):
	if not is_playing:
		is_playing = true
		if SoundManager: SoundManager.play_pick()
		GameManager.add_log("Base", "📻 Włączono Radio: " + channels[current_channel])
	else:
		current_channel = (current_channel + 1) % channels.size()
		if current_channel == 0:
			is_playing = false
			if SoundManager: SoundManager.play_hit()
			GameManager.add_log("Base", "📻 Wyłączono Radio.")
		else:
			if SoundManager: SoundManager.play_pick()
			GameManager.add_log("Base", "📻 Przełączono kanał Radia: " + channels[current_channel])
