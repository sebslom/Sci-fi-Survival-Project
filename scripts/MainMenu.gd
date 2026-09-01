extends Control

@onready var camera_pivot = get_node_or_null("SubViewportContainer/SubViewport/CameraPivot")

@onready var join_dialog = $JoinDialog
@onready var ip_input = $JoinDialog/VBoxContainer/IPInput
@onready var port_input = $JoinDialog/VBoxContainer/PortInput

@onready var controls_dialog = $ControlsDialog
@onready var settings_dialog = $SettingsDialog

@onready var volume_slider = $SettingsDialog/VBoxContainer/VolumeBox/VolumeSlider
@onready var pixel_slider = $SettingsDialog/VBoxContainer/PixelBox/PixelSlider
@onready var resolution_option = $SettingsDialog/VBoxContainer/ResBox/ResolutionOption

@onready var menu_vbox = $CenterContainer/VBoxContainer
@onready var load_button = get_node_or_null("CenterContainer/VBoxContainer/LoadButton")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_setup_settings_ui()
	_setup_button_styles_and_sfx()
	_setup_dialog_close_handlers()
	if load_button and not load_button.pressed.is_connected(_on_load_button_pressed):
		load_button.pressed.connect(_on_load_button_pressed)

func _setup_dialog_close_handlers():
	for win in [join_dialog, controls_dialog, settings_dialog]:
		if win and not win.close_requested.is_connected(_on_dialog_close_requested):
			win.close_requested.connect(_on_dialog_close_requested)

func _on_dialog_close_requested():
	if SoundManager: SoundManager.play_pick()
	if join_dialog: join_dialog.hide()
	if controls_dialog: controls_dialog.hide()
	if settings_dialog: settings_dialog.hide()

func _process(delta):
	if camera_pivot:
		camera_pivot.rotation.y += delta * 0.15

func _setup_button_styles_and_sfx():
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.06, 0.1, 0.18, 0.75)
	style_normal.border_color = Color(0.2, 0.3, 0.45, 0.6)
	style_normal.border_width_left = 2; style_normal.border_width_top = 2
	style_normal.border_width_right = 2; style_normal.border_width_bottom = 2
	style_normal.corner_radius_top_left = 8; style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_left = 8; style_normal.corner_radius_bottom_right = 8

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.12, 0.22, 0.38, 0.9)
	style_hover.border_color = Color(0.0, 0.95, 1.0, 1.0)
	style_hover.border_width_left = 2; style_hover.border_width_top = 2
	style_hover.border_width_right = 2; style_hover.border_width_bottom = 2
	style_hover.corner_radius_top_left = 8; style_hover.corner_radius_top_right = 8
	style_hover.corner_radius_bottom_left = 8; style_hover.corner_radius_bottom_right = 8

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.02, 0.52, 0.8, 0.95)
	style_pressed.border_color = Color(0.0, 0.95, 1.0, 1.0)
	style_pressed.border_width_left = 2; style_pressed.border_width_top = 2
	style_pressed.border_width_right = 2; style_pressed.border_width_bottom = 2
	style_pressed.corner_radius_top_left = 8; style_pressed.corner_radius_top_right = 8
	style_pressed.corner_radius_bottom_left = 8; style_pressed.corner_radius_bottom_right = 8

	for child in menu_vbox.get_children():
		if child is Button:
			child.add_theme_stylebox_override("normal", style_normal)
			child.add_theme_stylebox_override("hover", style_hover)
			child.add_theme_stylebox_override("pressed", style_pressed)
			child.add_theme_stylebox_override("focus", style_hover)
			
			child.mouse_entered.connect(func():
				if SoundManager: SoundManager.play_pick()
			)

func _setup_settings_ui():
	if volume_slider:
		volume_slider.value = GameManager.master_volume
		volume_slider.value_changed.connect(_on_volume_changed)
	if pixel_slider:
		pixel_slider.value = GameManager.render_scale
		pixel_slider.value_changed.connect(_on_pixel_scale_changed)
	if resolution_option:
		resolution_option.clear()
		resolution_option.add_item("1920 x 1080 (FHD)")
		resolution_option.add_item("1600 x 900")
		resolution_option.add_item("1280 x 720 (HD)")
		resolution_option.add_item("1024 x 576")
		resolution_option.selected = GameManager.current_resolution_idx
		resolution_option.item_selected.connect(_on_resolution_selected)

func _on_volume_changed(val: float):
	GameManager.set_master_volume(val)

func _on_pixel_scale_changed(val: float):
	GameManager.render_scale = val
	get_viewport().scaling_3d_scale = val

func _on_resolution_selected(idx: int):
	GameManager.current_resolution_idx = idx
	var sizes = [Vector2i(1920, 1080), Vector2i(1600, 900), Vector2i(1280, 720), Vector2i(1024, 576)]
	if idx >= 0 and idx < sizes.size():
		DisplayServer.window_set_size(sizes[idx])

func _on_host_button_pressed():
	if SoundManager: SoundManager.play_pick()
	get_tree().change_scene_to_file("res://scenes/MainScene.tscn")

func _on_load_button_pressed():
	if SoundManager: SoundManager.play_pick()
	if GameManager.load_game_state():
		get_tree().change_scene_to_file("res://scenes/MainScene.tscn")
	else:
		if SoundManager: SoundManager.play_hit()

func _on_join_button_pressed():
	if SoundManager: SoundManager.play_pick()
	join_dialog.popup_centered()

func _on_confirm_join_pressed():
	var ip = ip_input.text.strip_edges()
	if ip.is_empty(): ip = "127.0.0.1"
	var port = int(port_input.text.strip_edges())
	if port <= 0: port = 8910
		
	if SoundManager: SoundManager.play_teleport()
	get_tree().change_scene_to_file("res://scenes/MainScene.tscn")

func _on_settings_button_pressed():
	if SoundManager: SoundManager.play_pick()
	settings_dialog.popup_centered()

func _on_controls_button_pressed():
	if SoundManager: SoundManager.play_pick()
	controls_dialog.popup_centered()

func _on_quit_button_pressed():
	if SoundManager: SoundManager.play_hit()
	get_tree().quit()
