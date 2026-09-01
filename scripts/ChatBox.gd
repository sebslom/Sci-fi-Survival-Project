extends CanvasLayer

@onready var chat_panel = get_node_or_null("Panel")
@onready var chat_history = get_node_or_null("Panel/VBoxContainer/ChatHistory")
@onready var chat_input = get_node_or_null("Panel/VBoxContainer/ChatInput")

var is_chat_active: bool = false

func _ready():
	add_to_group("chat_box")
	if chat_input:
		chat_input.text_submitted.connect(_on_chat_submitted)
	add_chat_message("SYSTEM", "Witaj w komunikatorze taktycznym Sci-Fi Survival Project! Naciśnij [Enter] lub [T], aby pisać.", true)

func is_typing_active() -> bool:
	return is_chat_active or (chat_input and chat_input.has_focus())

func _unhandled_input(event):
	if is_typing_active():
		if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			_close_chat_input()
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_T and not is_typing_active()):
		if not is_typing_active():
			_open_chat_input()
			get_viewport().set_input_as_handled()

func _open_chat_input():
	is_chat_active = true
	if chat_input:
		chat_input.grab_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _close_chat_input():
	is_chat_active = false
	if chat_input:
		chat_input.release_focus()
		chat_input.text = ""
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_chat_submitted(text: String):
	var clean_text = text.strip_edges()
	if not clean_text.is_empty():
		if clean_text.begins_with("/"):
			_parse_local_slash_command(clean_text)
		else:
			var sender_name = GameManager.player_name if GameManager and GameManager.get("player_name") else "Gracz"
			var peer_id = 1
			if multiplayer and multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer:
				peer_id = multiplayer.get_unique_id()
				rpc("rpc_send_chat_message", peer_id, sender_name, clean_text)
			else:
				rpc_send_chat_message(peer_id, sender_name, clean_text)
	_close_chat_input()

func _parse_local_slash_command(command_text: String):
	var parts = command_text.split(" ", false)
	if parts.size() == 0: return
	var cmd = parts[0].to_lower()

	match cmd:
		"/clear":
			if chat_history:
				chat_history.text = ""
			add_chat_message("SYSTEM", "🧹 Wyczyszczono historię czatu.", true)
		"/suicide":
			add_chat_message("SYSTEM", "⚠️ WYKONANO KOMENDĘ SAMOBÓJSTWA (/suicide)!", true)
			if GameManager and GameManager.player_stats:
				GameManager.player_stats.hp = 0
				var players = get_tree().get_nodes_in_group("player")
				var p_node = players[0] if players.size() > 0 else null
				GameManager.handle_player_death(p_node)
		"/devroom", "/dev":
			add_chat_message("SYSTEM", "🔧 PRZENOSZENIE DO PRYWATNEJ SESJI TESTOWEJ DEVROOM...", true)
			if GameManager:
				GameManager.is_private_server = true
				GameManager.travel_to("expedition")
		_:
			add_chat_message("SYSTEM", "⚠️ Unknown komenda: %s. Dostępne: /clear, /suicide, /devroom" % cmd, true)

@rpc("any_peer", "call_local", "reliable")
func rpc_send_chat_message(sender_peer_id: int, sender_name: String, message_text: String):
	if not chat_history: return

	var formatted_line = "[color=#00f3ff][b][Gracz %d (%s)][/b][/color]: %s\n" % [sender_peer_id, sender_name, message_text]
	chat_history.text += formatted_line
	chat_history.scroll_to_line(chat_history.get_line_count())

	if GameManager and GameManager.has_method("add_log"):
		GameManager.add_log("Czat", "[Gracz %d]: %s" % [sender_peer_id, message_text])

func add_chat_message(sender_name: String, message_text: String, is_system: bool = false):
	if not chat_history: return

	var color_hex = "#f59e0b" if is_system else "#00f3ff"
	var formatted_line = "[color=%s][b][%s][/b][/color]: %s\n" % [color_hex, sender_name, message_text]
	
	chat_history.text += formatted_line
	chat_history.scroll_to_line(chat_history.get_line_count())
