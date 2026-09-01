extends CanvasLayer

@onready var crosshair = $Control/Crosshair
@onready var location_label = $Control/HeaderLeftPanel/LocationLabel
@onready var timer_label = $Control/HeaderRightPanel/TimerLabel

# Left-Bottom Vitals Panel & VBox
@onready var vitals_panel = get_node_or_null("Control/VitalsMarginContainer/VitalsPanel")
@onready var vitals_vbox = get_node_or_null("Control/VitalsMarginContainer/VitalsPanel/Margin/VitalsVBox")
@onready var hp_text = get_node_or_null("Control/VitalsMarginContainer/VitalsPanel/Margin/VitalsVBox/HPBox/HPText")
@onready var suit_text = get_node_or_null("Control/VitalsMarginContainer/VitalsPanel/Margin/VitalsVBox/SuitBox/SuitText")
@onready var weight_text = get_node_or_null("Control/VitalsMarginContainer/VitalsPanel/Margin/VitalsVBox/WeightText")
@onready var hunger_text = get_node_or_null("Control/VitalsMarginContainer/VitalsPanel/Margin/VitalsVBox/HungerBox/HungerText")
@onready var thirst_text = get_node_or_null("Control/VitalsMarginContainer/VitalsPanel/Margin/VitalsVBox/ThirstBox/ThirstText")
@onready var gold_text = get_node_or_null("Control/VitalsMarginContainer/VitalsPanel/Margin/VitalsVBox/GoldText")

# Right-Bottom Active Item Preview
@onready var active_item_panel = $Control/ActiveItemBottomRightPanel
@onready var active_item_icon = $Control/ActiveItemBottomRightPanel/VBoxContainer/HBoxTop/IconLabel
@onready var active_item_count = $Control/ActiveItemBottomRightPanel/VBoxContainer/HBoxTop/CountLabel
@onready var active_item_name = $Control/ActiveItemBottomRightPanel/VBoxContainer/NameLabel

# Left Log Panel & Toggle Button
@onready var log_panel = $Control/LogPanel
@onready var log_box = $Control/LogPanel/LogBox/TextEdit
@onready var toggle_log_btn = $Control/ToggleLogButton
@onready var notification_label = $Control/NotificationLabel
@onready var target_inspect_label = get_node_or_null("Control/TargetInspectLabel")

func update_target_inspection(info_text: String):
	if target_inspect_label:
		if info_text.is_empty():
			target_inspect_label.hide()
		else:
			target_inspect_label.text = info_text
			target_inspect_label.show()

# Modals
@onready var modal_pause = $Modals/ModalPause
@onready var modal_inventory = $Modals/ModalInventory
@onready var modal_crafting = $Modals/ModalCrafting
@onready var modal_map = $Modals/ModalMap
@onready var modal_portal = get_node_or_null("Modals/ModalPortal")
@onready var modal_npc_quest = $Modals/ModalNpcQuest
@onready var modal_npc_merchant = $Modals/ModalNpcMerchant

@onready var quest_vbox = $Modals/ModalNpcQuest/QuestVBox
@onready var merchant_vbox = $Modals/ModalNpcMerchant/MerchantVBox

@onready var inventory_grid = $Modals/ModalInventory/HBoxMain/InventoryPanel/ScrollContainer/GridContainer
@onready var capacity_label = $Modals/ModalInventory/HBoxMain/EquipmentPanel/CapacityLabel
@onready var crafting_grid = get_node_or_null("Modals/ModalCrafting/VBoxContainer/CraftingScroll/CraftingMargin/CraftingVBox")

# Equipment Nodes
@onready var helmet_btn = get_node_or_null("Modals/ModalInventory/HBoxMain/EquipmentPanel/HBoxColumns/FuncVBox/HelmetSlot")
@onready var mask_btn = get_node_or_null("Modals/ModalInventory/HBoxMain/EquipmentPanel/HBoxColumns/FuncVBox/MaskSlot")
@onready var armor_btn = get_node_or_null("Modals/ModalInventory/HBoxMain/EquipmentPanel/HBoxColumns/FuncVBox/ArmorSlot")
@onready var boots_btn = get_node_or_null("Modals/ModalInventory/HBoxMain/EquipmentPanel/HBoxColumns/FuncVBox/BootsSlot")
@onready var backpack_btn = get_node_or_null("Modals/ModalInventory/HBoxMain/EquipmentPanel/HBoxColumns/FuncVBox/BackpackSlot")

@onready var cosm_helmet_btn = get_node_or_null("Modals/ModalInventory/HBoxMain/EquipmentPanel/HBoxColumns/CosmVBox/CosmHelmetSlot")
@onready var cosm_mask_btn = get_node_or_null("Modals/ModalInventory/HBoxMain/EquipmentPanel/HBoxColumns/CosmVBox/CosmMaskSlot")
@onready var cosm_armor_btn = get_node_or_null("Modals/ModalInventory/HBoxMain/EquipmentPanel/HBoxColumns/CosmVBox/CosmArmorSlot")
@onready var cosm_boots_btn = get_node_or_null("Modals/ModalInventory/HBoxMain/EquipmentPanel/HBoxColumns/CosmVBox/CosmBootsSlot")

@onready var art_slot1_btn = get_node_or_null("Modals/ModalInventory/HBoxMain/EquipmentPanel/ArtifactHBox/ArtSlot1")
@onready var art_slot2_btn = get_node_or_null("Modals/ModalInventory/HBoxMain/EquipmentPanel/ArtifactHBox/ArtSlot2")
@onready var art_slot3_btn = get_node_or_null("Modals/ModalInventory/HBoxMain/EquipmentPanel/ArtifactHBox/ArtSlot3")
@onready var art_slot4_btn = get_node_or_null("Modals/ModalInventory/HBoxMain/EquipmentPanel/ArtifactHBox/ArtSlot4")
@onready var art_slot5_btn = get_node_or_null("Modals/ModalInventory/HBoxMain/EquipmentPanel/ArtifactHBox/ArtSlot5")

@onready var volume_slider = $Modals/ModalPause/VBoxContainer/VolumeBox/VolumeSlider
@onready var pixel_slider = $Modals/ModalPause/VBoxContainer/PixelBox/PixelSlider
@onready var resolution_option = $Modals/ModalPause/VBoxContainer/ResBox/ResolutionOption

# Graphical ProgressBars
var hp_bar: ProgressBar = null
var suit_bar: ProgressBar = null
var hunger_bar: ProgressBar = null
var thirst_bar: ProgressBar = null

# Crosshair Interaction Prompt Label
var prompt_label: Label = null

var context_menu: PopupMenu = null
var selected_inventory_idx: int = -1
var active_terminal_ref = null

func _ready():
	add_to_group("hud")
	_apply_glassmorphism_styles()
	_setup_progress_bars()
	_setup_crosshair_prompt()

	# Explicitly hide all modal panels on start to guarantee mouse capture in FPS mode
	if modal_pause: modal_pause.hide()
	if modal_inventory: modal_inventory.hide()
	if modal_crafting: modal_crafting.hide()
	if modal_map: modal_map.hide()
	if modal_portal: modal_portal.hide()
	if modal_npc_quest: modal_npc_quest.hide()
	if modal_npc_merchant: modal_npc_merchant.hide()
	if log_panel: log_panel.hide()

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	GameManager.stats_changed.connect(_on_stats_changed)
	GameManager.location_changed.connect(_on_location_changed)
	GameManager.wipeout_timer_updated.connect(_on_timer_updated)
	GameManager.log_added.connect(_on_log_added)
	GameManager.inventory_changed.connect(_update_inventory_ui)
	
	if SurvivalManager:
		SurvivalManager.survival_stats_updated.connect(_on_stats_changed)
		SurvivalManager.log_requested.connect(_on_log_added)

	if WeaponManager:
		WeaponManager.weapon_state_changed.connect(_update_inventory_ui)
		WeaponManager.log_requested.connect(_on_log_added)

	_bind_equipment_buttons()

	if toggle_log_btn:
		toggle_log_btn.pressed.connect(_toggle_log_panel)

	_setup_context_menu()
	_setup_settings_ui()
	_on_stats_changed()
	_on_location_changed(GameManager.active_location)
	_on_timer_updated(GameManager.wipeout_timer)
	_update_inventory_ui()

func _bind_equipment_buttons():
	if helmet_btn: helmet_btn.pressed.connect(func(): GameManager.unequip_functional_gear("helmet"))
	if mask_btn: mask_btn.pressed.connect(func(): GameManager.unequip_functional_gear("mask"))
	if armor_btn: armor_btn.pressed.connect(func(): GameManager.unequip_functional_gear("armor"))
	if boots_btn: boots_btn.pressed.connect(func(): GameManager.unequip_functional_gear("boots"))
	if backpack_btn: backpack_btn.pressed.connect(func(): GameManager.unequip_functional_gear("backpack"))

	if cosm_helmet_btn: cosm_helmet_btn.pressed.connect(func(): GameManager.unequip_cosmetic_gear("helmet"))
	if cosm_mask_btn: cosm_mask_btn.pressed.connect(func(): GameManager.unequip_cosmetic_gear("mask"))
	if cosm_armor_btn: cosm_armor_btn.pressed.connect(func(): GameManager.unequip_cosmetic_gear("armor"))
	if cosm_boots_btn: cosm_boots_btn.pressed.connect(func(): GameManager.unequip_cosmetic_gear("boots"))

	var art_btns = [art_slot1_btn, art_slot2_btn, art_slot3_btn, art_slot4_btn, art_slot5_btn]
	for idx in range(art_btns.size()):
		var btn = art_btns[idx]
		if btn:
			var slot_idx = idx
			btn.pressed.connect(func(): GameManager.unequip_artifact(slot_idx))

func _setup_crosshair_prompt():
	if crosshair:
		prompt_label = Label.new()
		prompt_label.custom_minimum_size = Vector2(300, 30)
		prompt_label.position = Vector2(-135, 24)
		prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		prompt_label.add_theme_font_size_override("font_size", 14)
		prompt_label.add_theme_color_override("font_color", Color("#00f3ff"))
		prompt_label.text = ""
		crosshair.add_child(prompt_label)

func _apply_glassmorphism_styles():
	var glass_style = StyleBoxFlat.new()
	glass_style.bg_color = Color(0.05, 0.09, 0.16, 0.78)
	glass_style.border_color = Color(0.0, 0.95, 1.0, 0.45)
	glass_style.border_width_left = 2; glass_style.border_width_top = 2
	glass_style.border_width_right = 2; glass_style.border_width_bottom = 2
	glass_style.corner_radius_top_left = 8; glass_style.corner_radius_top_right = 8
	glass_style.corner_radius_bottom_left = 8; glass_style.corner_radius_bottom_right = 8

	for p in [vitals_panel, active_item_panel, $Control/HeaderLeftPanel, $Control/HeaderRightPanel, get_node_or_null("Control/PowerStatusPanel"), log_panel]:
		if p: p.add_theme_stylebox_override("panel", glass_style)

	for m in [modal_pause, modal_inventory, modal_crafting, modal_map, modal_npc_quest, modal_npc_merchant]:
		if m: m.add_theme_stylebox_override("panel", glass_style)

func _setup_progress_bars():
	hp_bar = _create_bar(Color("#10b981"))
	suit_bar = _create_bar(Color("#00f3ff"))
	hunger_bar = _create_bar(Color("#f59e0b"))
	thirst_bar = _create_bar(Color("#38bdf8"))

	var hp_box = get_node_or_null("Control/VitalsMarginContainer/VitalsPanel/Margin/VitalsVBox/HPBox")
	var suit_box = get_node_or_null("Control/VitalsMarginContainer/VitalsPanel/Margin/VitalsVBox/SuitBox")
	var hunger_box = get_node_or_null("Control/VitalsMarginContainer/VitalsPanel/Margin/VitalsVBox/HungerBox")
	var thirst_box = get_node_or_null("Control/VitalsMarginContainer/VitalsPanel/Margin/VitalsVBox/ThirstBox")

	if hp_box: hp_box.add_child(hp_bar)
	elif hp_text: hp_text.add_child(hp_bar)

	if suit_box: suit_box.add_child(suit_bar)
	elif suit_text: suit_text.add_child(suit_bar)

	if hunger_box: hunger_box.add_child(hunger_bar)
	elif hunger_text: hunger_text.add_child(hunger_bar)

	if thirst_box: thirst_box.add_child(thirst_bar)
	elif thirst_text: thirst_text.add_child(thirst_bar)

func _create_bar(fill_color: Color) -> ProgressBar:
	var pb = ProgressBar.new()
	pb.custom_minimum_size = Vector2(200, 10)
	pb.show_percentage = false
	
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.02, 0.04, 0.08, 0.8)
	bg.set_corner_radius_all(4)

	var fg = StyleBoxFlat.new()
	fg.bg_color = fill_color
	fg.set_corner_radius_all(4)
	
	pb.add_theme_stylebox_override("background", bg)
	pb.add_theme_stylebox_override("fill", fg)
	return pb

func is_any_modal_open() -> bool:
	return (modal_pause and modal_pause.visible) or (modal_inventory and modal_inventory.visible) or (modal_crafting and modal_crafting.visible) or (modal_map and modal_map.visible) or (modal_portal and modal_portal.visible) or (modal_npc_quest and modal_npc_quest.visible) or (modal_npc_merchant and modal_npc_merchant.visible) or (modal_storage and modal_storage.visible)

func _update_mouse_cursor_state():
	if is_any_modal_open():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _toggle_log_panel():
	if log_panel:
		log_panel.visible = not log_panel.visible
		_update_mouse_cursor_state()

func _update_active_item_widget():
	var active_slot = GameManager.hotbar.get(GameManager.active_hotbar_slot)
	if not active_slot:
		if active_item_icon: active_item_icon.text = "✋"
		if active_item_count: active_item_count.text = "-"
		if active_item_name: active_item_name.text = "Dłonie [" + str(GameManager.active_hotbar_slot) + "]"
		return

	if active_item_icon: active_item_icon.text = active_slot.get("icon", "📦")

	var item_type = active_slot.get("type", "weapon")
	if item_type == "weapon":
		var ammo_type = active_slot.get("ammo_type", "standard")
		var ammo_name = "STD"
		if ammo_type == "ap": ammo_name = "AP"
		elif ammo_type == "incendiary": ammo_name = "FIRE"

		var ammo_left = GameManager.ammo_inventory.get(ammo_type, 0)
		var cond = WeaponManager.get_condition(active_slot) if WeaponManager else 100.0
		var is_jammed = WeaponManager.is_jammed(active_slot) if WeaponManager else false
		var has_supp = WeaponManager.has_attachment(active_slot, "suppressor") if WeaponManager else false
		var has_scope = WeaponManager.has_attachment(active_slot, "scope") if WeaponManager else false

		var status_info = "%s (%d)" % [ammo_name, ammo_left]
		if is_jammed:
			status_info += " ⚠️ ZACIĘTA [R]"
		else:
			status_info += " (%d%%)" % int(cond)

		if has_supp: status_info += " 🔇"
		if has_scope: status_info += " 🔭"

		if active_item_count: active_item_count.text = status_info
		if active_item_name: active_item_name.text = active_slot.get("name", "") + " [" + str(GameManager.active_hotbar_slot) + "]"
	else:
		var count = active_slot.get("count", 1)
		if active_item_count: active_item_count.text = "x" + str(count)
		if active_item_name: active_item_name.text = active_slot.get("name", "") + " [" + str(GameManager.active_hotbar_slot) + "]"

func _process(_delta):
	_update_active_item_widget()
	_update_crosshair_interaction()

func _update_crosshair_interaction():
	if not crosshair:
		return

	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		if prompt_label:
			prompt_label.text = ""
			prompt_label.hide()
		return
	var player = players[0]
	var raycast = player.get_node_or_null("Head/Camera/RayCast")
	
	var is_interactive = false
	var prompt_text = ""
	
	if raycast and raycast.is_colliding():
		var col_point = raycast.get_collision_point()
		var dist = player.global_position.distance_to(col_point)
		if dist <= 4.0:
			var col = raycast.get_collider()
			if col:
				var target_node = col
				if not target_node.has_method("interact") and not target_node.has_method("get_interaction_prompt") and col.get_parent():
					target_node = col.get_parent()
					
				if target_node.is_in_group("interactable") or target_node.is_in_group("interactive") or target_node.has_method("interact") or target_node.has_method("get_interaction_prompt"):
					is_interactive = true
					if target_node.has_method("get_interaction_prompt"):
						prompt_text = target_node.get_interaction_prompt()
					elif target_node.get("prompt_text"):
						prompt_text = "[E] " + str(target_node.get("prompt_text"))
					elif target_node.get("building_type"):
						prompt_text = "[E] Interact: " + str(target_node.get("building_type"))
					elif target_node.get("npc_name"):
						prompt_text = "[E] Talk: " + str(target_node.get("npc_name"))
					else:
						prompt_text = "[E] Interact"

	if is_interactive and not prompt_text.is_empty():
		crosshair.add_theme_color_override("font_color", Color("#00f3ff"))
		crosshair.text = "‹ + ›"
		if prompt_label:
			prompt_label.text = prompt_text
			prompt_label.show()
	else:
		crosshair.add_theme_color_override("font_color", Color("#94a3b8"))
		crosshair.text = "+"
		if prompt_label:
			prompt_label.text = ""
			prompt_label.hide()

func _setup_context_menu():
	context_menu = PopupMenu.new()
	context_menu.add_item("Użyj / Zamontuj", 0)
	context_menu.add_item("Załóż Ekwipunek (Statystyki) 🛡️", 20)
	context_menu.add_item("Załóż jako Wygląd Kosmetyczny 🎨", 21)
	context_menu.add_item("Zamontuj Artefakt [Slot #1] 🔮", 30)
	context_menu.add_item("Zamontuj Artefakt [Slot #2] 🔮", 31)
	context_menu.add_item("Zamontuj Artefakt [Slot #3] 🔮", 32)
	context_menu.add_item("Zamontuj Artefakt [Slot #4] 🔮", 33)
	context_menu.add_item("Zamontuj Artefakt [Slot #5] 🔮", 34)
	context_menu.add_item("Rozłóż Broń na Części ⚙️", 10)
	context_menu.add_item("Hotbar [1]", 1)
	context_menu.add_item("Hotbar [2]", 2)
	context_menu.add_item("Hotbar [3]", 3)
	context_menu.add_item("Hotbar [4]", 4)
	context_menu.add_item("Hotbar [5]", 5)
	context_menu.add_item("Split Stack", 6)
	context_menu.add_item("Drop", 7)
	context_menu.id_pressed.connect(_on_context_menu_item_selected)
	add_child(context_menu)

func _on_context_menu_item_selected(id: int):
	if selected_inventory_idx < 0 or selected_inventory_idx >= GameManager.inventory.size():
		return
	var item = GameManager.inventory[selected_inventory_idx]
	if not item:
		return

	match id:
		0:
			var item_type = item.get("type", "")
			if item_type in ["helmet", "gas_mask", "armor", "boots"]:
				var target_slot = "helmet" if item_type == "helmet" else ("mask" if item_type == "gas_mask" else ("armor" if item_type == "armor" else "boots"))
				GameManager.equip_functional_gear(selected_inventory_idx, target_slot)
			elif item_type == "artifact":
				# Auto-equip artifact to first free slot
				for s in range(5):
					if GameManager.artifact_slots[s] == null:
						GameManager.equip_artifact(selected_inventory_idx, s)
						return
				GameManager.equip_artifact(selected_inventory_idx, 0)
			elif item_type == "backpack":
				GameManager.equip_functional_gear(selected_inventory_idx, "backpack")
			elif item_type == "repair_kit":
				var active_w = GameManager.hotbar.get(GameManager.active_hotbar_slot)
				if active_w and active_w.get("type") in ["weapon", "melee"] and WeaponManager:
					WeaponManager.repair_weapon(active_w, selected_inventory_idx)
				else:
					GameManager.add_log("Modyfikacje", "⚠️ Wybierz w hotbarze broń lub broń białą do naprawy!")
			elif item_type == "bandage":
				if SurvivalManager and SurvivalManager.use_bandage():
					GameManager.inventory.remove_at(selected_inventory_idx)
					GameManager.emit_signal("inventory_changed")
			elif item_type == "charcoal":
				if SurvivalManager and SurvivalManager.use_charcoal():
					GameManager.inventory.remove_at(selected_inventory_idx)
					GameManager.emit_signal("inventory_changed")
			elif item_type == "painkillers":
				if SurvivalManager and SurvivalManager.use_painkillers():
					GameManager.inventory.remove_at(selected_inventory_idx)
					GameManager.emit_signal("inventory_changed")
			elif item_type == "clean_water":
				GameManager.thirst_float = min(100.0, GameManager.thirst_float + 50.0)
				GameManager.player_stats.thirst = int(GameManager.thirst_float)
				GameManager.player_stats.hp = min(GameManager.player_stats.max_hp, GameManager.player_stats.hp + 15)
				GameManager.inventory.remove_at(selected_inventory_idx)
				if SoundManager: SoundManager.play_pick()
				GameManager.add_log("Postać", "Wypito: Czysta Woda (+50 Pragnienie, +15 HP)")
				GameManager.emit_signal("stats_changed")
				GameManager.emit_signal("inventory_changed")
			elif item_type == "food":
				GameManager.player_stats.hunger = min(100, GameManager.player_stats.hunger + item.get("value", 40))
				GameManager.player_stats.hp = min(GameManager.player_stats.max_hp, GameManager.player_stats.hp + 20)
				GameManager.inventory.remove_at(selected_inventory_idx)
				if SoundManager: SoundManager.play_pick()
				GameManager.add_log("Postać", "Zjedzono: " + item.get("name", ""))
				GameManager.emit_signal("inventory_changed")
		20:
			var item_type = item.get("type", "")
			var target_slot = "helmet" if item_type == "helmet" else ("mask" if item_type == "gas_mask" else ("armor" if item_type == "armor" else "boots"))
			GameManager.equip_functional_gear(selected_inventory_idx, target_slot)
		21:
			var item_type = item.get("type", "")
			var target_slot = "helmet" if item_type == "helmet" else ("mask" if item_type == "gas_mask" else ("armor" if item_type == "armor" else "boots"))
			GameManager.equip_cosmetic_gear(selected_inventory_idx, target_slot)
		30: GameManager.equip_artifact(selected_inventory_idx, 0)
		31: GameManager.equip_artifact(selected_inventory_idx, 1)
		32: GameManager.equip_artifact(selected_inventory_idx, 2)
		33: GameManager.equip_artifact(selected_inventory_idx, 3)
		34: GameManager.equip_artifact(selected_inventory_idx, 4)
		10:
			if item.get("type") == "weapon" and WeaponManager:
				WeaponManager.dismantle_weapon(selected_inventory_idx)
		1: GameManager.assign_to_hotbar(selected_inventory_idx, 1)
		2: GameManager.assign_to_hotbar(selected_inventory_idx, 2)
		3: GameManager.assign_to_hotbar(selected_inventory_idx, 3)
		4: GameManager.assign_to_hotbar(selected_inventory_idx, 4)
		5: GameManager.assign_to_hotbar(selected_inventory_idx, 5)
		6: GameManager.split_stack(selected_inventory_idx)
		7:
			var players = get_tree().get_nodes_in_group("player")
			var p_node = players[0] if players.size() > 0 else null
			GameManager.drop_physical_item(item, p_node)
			GameManager.inventory.remove_at(selected_inventory_idx)
			if SoundManager: SoundManager.play_pick()
			GameManager.add_log("Ekwipunek", "📦 Dropped physical item: " + item.get("name", ""))
			GameManager.emit_signal("inventory_changed")

func _update_inventory_ui():
	_update_paperdoll_ui()
	_update_grid_inventory_ui()

func _update_paperdoll_ui():
	# 1. Functional Gear Buttons
	var eq = GameManager.equipment
	if helmet_btn: helmet_btn.text = "🪖 Hełm: " + (eq["helmet"].get("name") if eq["helmet"] else "[Pusty]")
	if mask_btn: mask_btn.text = "😷 Maska: " + (eq["mask"].get("name") if eq["mask"] else "[Pusty]")
	if armor_btn: armor_btn.text = "🛡️ Pancerz: " + (eq["armor"].get("name") if eq["armor"] else "[Pusty]")
	if boots_btn: boots_btn.text = "🥾 Buty: " + (eq["boots"].get("name") if eq["boots"] else "[Pusty]")
	if backpack_btn: backpack_btn.text = "🎒 Plecak: " + (eq["backpack"].get("name") if eq["backpack"] else "[Pusty]")

	# 2. Cosmetic Gear Buttons
	var cosm = GameManager.cosmetic_equipment
	if cosm_helmet_btn: cosm_helmet_btn.text = "🎨 Hełm: " + (cosm["helmet"].get("name") if cosm["helmet"] else "[Brak]")
	if cosm_mask_btn: cosm_mask_btn.text = "🎨 Maska: " + (cosm["mask"].get("name") if cosm["mask"] else "[Brak]")
	if cosm_armor_btn: cosm_armor_btn.text = "🎨 Pancerz: " + (cosm["armor"].get("name") if cosm["armor"] else "[Brak]")
	if cosm_boots_btn: cosm_boots_btn.text = "🎨 Buty: " + (cosm["boots"].get("name") if cosm["boots"] else "[Brak]")

	# 3. 5 Artifact Slots
	var art_btns = [art_slot1_btn, art_slot2_btn, art_slot3_btn, art_slot4_btn, art_slot5_btn]
	for i in range(5):
		var btn = art_btns[i]
		if btn:
			var art = GameManager.artifact_slots[i]
			if art and art is Dictionary:
				btn.text = art.get("icon", "🔮") + " #" + str(i + 1) + "\n" + art.get("name", "").left(8)
				
				# Generate detailed tooltip for procedural buffs & debuffs
				var tt = "🔮 " + art.get("name", "") + "\n"
				var buffs = art.get("buffs", {})
				for k in buffs.keys():
					tt += "  ✅ " + k + ": +" + str(buffs[k]) + "\n"
				var debuffs = art.get("debuffs", {})
				for k in debuffs.keys():
					tt += "  ❌ " + k + ": -" + str(debuffs[k]) + "\n"
				tt += "Kliknij, aby odmontować."
				btn.tooltip_text = tt
			else:
				btn.text = "🔮 #" + str(i + 1) + "\n[Pusty]"
				btn.tooltip_text = "Pusty slot na Artefakt #" + str(i + 1)

func _update_grid_inventory_ui():
	if not inventory_grid: return
	for child in inventory_grid.get_children():
		child.queue_free()

	var items = GameManager.inventory
	var max_slots = GameManager.get_max_inventory_slots()
	if capacity_label:
		capacity_label.text = "Pojemność: " + str(items.size()) + " / " + str(max_slots)

	var slot_style = StyleBoxFlat.new()
	slot_style.bg_color = Color("#1e293b")
	slot_style.border_color = Color("#334155")
	slot_style.border_width_left = 2; slot_style.border_width_top = 2
	slot_style.border_width_right = 2; slot_style.border_width_bottom = 2
	slot_style.corner_radius_top_left = 6; slot_style.corner_radius_top_right = 6
	slot_style.corner_radius_bottom_left = 6; slot_style.corner_radius_bottom_right = 6

	for i in range(max_slots):
		var slot_panel = PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(72, 72)
		slot_panel.add_theme_stylebox_override("panel", slot_style)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 4)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_right", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		slot_panel.add_child(margin)

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(64, 64)
		btn.flat = true
		
		if i < items.size() and items[i] != null:
			var item = items[i]
			var icon_symbol = item.get("icon", "📦")
			var count = item.get("count", 1)
			
			var tooltip = item.get("name", "") + "\nWaga: " + str(GameManager.get_item_unit_weight(item)) + " kg\n"
			if item.get("type") == "artifact":
				var buffs = item.get("buffs", {})
				for k in buffs.keys():
					tooltip += "  ✅ " + k + ": +" + str(buffs[k]) + "\n"
				var debuffs = item.get("debuffs", {})
				for k in debuffs.keys():
					tooltip += "  ❌ " + k + ": -" + str(debuffs[k]) + "\n"
			elif item.get("type") == "weapon" and WeaponManager:
				var cond = WeaponManager.get_condition(item)
				tooltip += "Kondycja: %d%%\n" % int(cond)
				if WeaponManager.is_jammed(item): tooltip += "⚠️ BROŃ ZACIĘTA!\n"
				if WeaponManager.has_attachment(item, "suppressor"): tooltip += "🔇 Zamontowano Tłumik\n"
				if WeaponManager.has_attachment(item, "scope"): tooltip += "🔭 Zamontowano Celownik Optyczny\n"
			tooltip += item.get("desc", "")
			
			btn.tooltip_text = tooltip
			
			var vbox = VBoxContainer.new()
			vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			
			var icon_lbl = Label.new()
			icon_lbl.text = icon_symbol
			icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			icon_lbl.add_theme_font_size_override("font_size", 28)
			vbox.add_child(icon_lbl)
			
			if count > 1:
				var count_lbl = Label.new()
				count_lbl.text = "x" + str(count)
				count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				count_lbl.add_theme_font_size_override("font_size", 12)
				count_lbl.add_theme_color_override("font_color", Color("#00f3ff"))
				vbox.add_child(count_lbl)

			btn.add_child(vbox)
			
			var idx = i
			btn.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
					selected_inventory_idx = idx
					context_menu.position = Vector2i(get_viewport().get_mouse_position())
					context_menu.reset_size()
					context_menu.popup()
			)
		else:
			btn.disabled = true

		margin.add_child(btn)
		inventory_grid.add_child(slot_panel)

func _update_crafting_ui():
	if not crafting_grid: return
	for child in crafting_grid.get_children():
		child.queue_free()

	var row_style = StyleBoxFlat.new()
	row_style.bg_color = Color("#0f172a")
	row_style.border_color = Color("#1e293b")
	row_style.border_width_left = 1; row_style.border_width_top = 1
	row_style.border_width_right = 1; row_style.border_width_bottom = 1
	row_style.corner_radius_top_left = 6; row_style.corner_radius_top_right = 6
	row_style.corner_radius_bottom_left = 6; row_style.corner_radius_bottom_right = 6

	for recipe in GameManager.crafting_recipes:
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, 56)
		panel.add_theme_stylebox_override("panel", row_style)

		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_bottom", 6)
		panel.add_child(margin)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 16)

		var icon_lbl = Label.new()
		icon_lbl.text = recipe.get("icon", "🛠️")
		icon_lbl.custom_minimum_size = Vector2(48, 0)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 26)
		hbox.add_child(icon_lbl)

		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var title_lbl = Label.new()
		title_lbl.text = recipe.get("name", "")
		title_lbl.add_theme_color_override("font_color", Color("#f8fafc"))
		info_vbox.add_child(title_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = recipe.get("desc", "")
		desc_lbl.add_theme_color_override("font_color", Color("#64748b"))
		desc_lbl.add_theme_font_size_override("font_size", 11)
		info_vbox.add_child(desc_lbl)
		hbox.add_child(info_vbox)

		var cost_vbox = VBoxContainer.new()
		cost_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cost_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var mat_names = {
			"scrap": "Scrap", "wood": "Drewno", "cloth": "Szmaty",
			"material_steel": "Steel", "material_polymer": "Polimer", "material_copper": "Copper",
			"clothing": "Ubrania", "part_barrel": "Lufa", "part_receiver": "Zamek",
			"component_bio_engine": "Silnik Bio"
		}

		var cost_str = ""
		var cost_dict = recipe.get("cost", {})
		var can_craft = true
		for mat in cost_dict.keys():
			var req = cost_dict[mat]
			var player_has = 0
			for item in GameManager.inventory:
				if item and item.get("type") == mat:
					player_has += item.get("count", 1)
			if player_has < req:
				can_craft = false
			var mat_title = mat_names.get(mat, mat)
			cost_str += "%s: %d/%d  " % [mat_title, player_has, req]

		var cost_lbl = Label.new()
		cost_lbl.text = cost_str
		cost_lbl.add_theme_font_size_override("font_size", 12)
		if can_craft: cost_lbl.add_theme_color_override("font_color", Color("#10b981"))
		else: cost_lbl.add_theme_color_override("font_color", Color("#ef4444"))
		cost_vbox.add_child(cost_lbl)
		hbox.add_child(cost_vbox)

		var craft_btn = Button.new()
		craft_btn.text = " STWÓRZ "
		craft_btn.custom_minimum_size = Vector2(110, 36)
		craft_btn.disabled = not can_craft
		var r_id = recipe.get("id")
		craft_btn.pressed.connect(func():
			if GameManager.craft_recipe(r_id):
				_update_crafting_ui()
				_update_inventory_ui()
		)
		hbox.add_child(craft_btn)

		margin.add_child(hbox)
		crafting_grid.add_child(panel)

var active_custom_portal_ref = null

func open_portal_tuning_dialog(portal_node):
	if not modal_portal: return
	active_custom_portal_ref = portal_node
	
	modal_pause.hide(); modal_inventory.hide(); modal_crafting.hide(); modal_map.hide()
	modal_npc_quest.hide(); modal_npc_merchant.hide()

	var option_btn = get_node_or_null("Modals/ModalPortal/VBoxContainer/HBoxBiome/BiomeOption")
	var seed_edit = get_node_or_null("Modals/ModalPortal/VBoxContainer/HBoxSeed/SeedEdit")
	var rand_btn = get_node_or_null("Modals/ModalPortal/VBoxContainer/HBoxSeed/RandomSeedBtn")
	var apply_btn = get_node_or_null("Modals/ModalPortal/VBoxContainer/HBoxActions/ApplyBtn")
	var jump_btn = get_node_or_null("Modals/ModalPortal/VBoxContainer/HBoxActions/JumpBtn")

	if option_btn:
		option_btn.clear()
		option_btn.add_item("🪐 Sektor Marsjański (Powierzchnia)", 0)
		option_btn.add_item("🏜️ Kanyon Czerwonej Skały", 1)
		option_btn.add_item("❄️ Lodowa Pustosz Phobos", 2)
		option_btn.add_item("🏙️ Strefa Ocalałych (Miasto)", 3)
		option_btn.add_item("🧬 Portal Misji: Fabryka Klonów", 4)
		option_btn.add_item("🏪 Portal Handlowy: Baser", 5)
		option_btn.add_item("🔮 Własny Seed (Anomalia)", 6)

		match portal_node.target_biome:
			"mars": option_btn.selected = 0
			"canyon": option_btn.selected = 1
			"ice": option_btn.selected = 2
			"town": option_btn.selected = 3
			"clone_factory": option_btn.selected = 4
			"bazar": option_btn.selected = 5
			"custom": option_btn.selected = 6

	if seed_edit:
		seed_edit.text = str(portal_node.custom_seed)

	if rand_btn and not rand_btn.pressed.is_connected(_on_rand_portal_seed_pressed):
		rand_btn.pressed.connect(_on_rand_portal_seed_pressed)

	if apply_btn and not apply_btn.pressed.is_connected(_on_apply_portal_tuning_pressed):
		apply_btn.pressed.connect(_on_apply_portal_tuning_pressed)

	if jump_btn and not jump_btn.pressed.is_connected(_on_jump_portal_pressed):
		jump_btn.pressed.connect(_on_jump_portal_pressed)

	modal_portal.show()
	_update_mouse_cursor_state()

func _on_rand_portal_seed_pressed():
	var seed_edit = get_node_or_null("Modals/ModalPortal/VBoxContainer/HBoxSeed/SeedEdit")
	if seed_edit:
		var new_seed = randi() % 900000 + 100000
		seed_edit.text = str(new_seed)

func _on_apply_portal_tuning_pressed():
	if not active_custom_portal_ref or not is_instance_valid(active_custom_portal_ref): return
	var option_btn = get_node_or_null("Modals/ModalPortal/VBoxContainer/HBoxBiome/BiomeOption")
	var seed_edit = get_node_or_null("Modals/ModalPortal/VBoxContainer/HBoxSeed/SeedEdit")
	
	var biomes = ["mars", "canyon", "ice", "town", "clone_factory", "bazar", "custom"]
	var selected_b = biomes[option_btn.selected] if option_btn and option_btn.selected < biomes.size() else "mars"
	var selected_s = int(seed_edit.text) if seed_edit and seed_edit.text.is_valid_int() else 133742
	
	active_custom_portal_ref.tune_portal(selected_b, selected_s)
	show_notification("✨ Portal kwantowy został pomyślnie dostrojony!")

func _on_jump_portal_pressed():
	_on_apply_portal_tuning_pressed()
	if modal_portal: modal_portal.hide()
	_update_mouse_cursor_state()
	if active_custom_portal_ref and is_instance_valid(active_custom_portal_ref):
		active_custom_portal_ref.execute_jump()

func open_npc_dialog(npc_type: String, npc_name: String):
	modal_pause.hide(); modal_inventory.hide(); modal_crafting.hide(); modal_map.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if npc_type == "quest":
		_populate_quest_dialog(npc_name)
		modal_npc_quest.show()
	else:
		_populate_merchant_dialog(npc_type, npc_name)
		modal_npc_merchant.show()

func _populate_quest_dialog(npc_name: String):
	$Modals/ModalNpcQuest/NpcTitle.text = "📜 " + npc_name + " - ZADANIA POBOCZNE"
	for child in quest_vbox.get_children(): child.queue_free()

	for quest in GameManager.quests:
		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(0, 45)
		
		var title_lbl = Label.new()
		title_lbl.text = quest.get("title", "") + "\n" + quest.get("desc", "")
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(title_lbl)

		var reward_lbl = Label.new()
		reward_lbl.text = "Nagroda: " + str(quest.get("reward_gold")) + " 💰"
		reward_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(reward_lbl)

		var btn = Button.new()
		var q_id = quest.get("id")
		if quest.get("completed", false):
			btn.text = " ✅ UKOŃCZONE "
			btn.disabled = true
		else:
			btn.text = " ODBIERZ NAGRODĘ "
			btn.pressed.connect(func():
				if GameManager.complete_quest(q_id):
					_populate_quest_dialog(npc_name)
			)
		hbox.add_child(btn)
		quest_vbox.add_child(hbox)

func _populate_merchant_dialog(npc_type: String, npc_name: String):
	$Modals/ModalNpcMerchant/MerchantTitle.text = "🛒 " + npc_name
	for child in merchant_vbox.get_children(): child.queue_free()

	var merchant_goods = []
	if npc_type in ["junk", "scrap_dealer", "scrap_merchant"]:
		merchant_goods = [
			{ "id": "buy_scrap", "name": "Scrap Metalowy (x10)", "cost": 60, "item": { "id": "scrap_b", "name": "Scrap Metalowy", "type": "scrap", "count": 10, "weight": 1.0, "icon": "⚙️" } },
			{ "id": "buy_steel", "name": "Steel Płyty Pancerne (x5)", "cost": 120, "item": { "id": "steel_b", "name": "Steel Przemysłowa", "type": "material_steel", "count": 5, "weight": 2.5, "icon": "🪙" } },
			{ "id": "buy_polymer", "name": "Polimer Wojskowy (x5)", "cost": 100, "item": { "id": "poly_b", "name": "Polimer Taktyczny", "type": "material_polymer", "count": 5, "weight": 1.5, "icon": "🧪" } },
			{ "id": "buy_copper", "name": "Miedziane Przewody (x5)", "cost": 90, "item": { "id": "copper_b", "name": "Copper Przewodząca", "type": "material_copper", "count": 5, "weight": 1.0, "icon": "🔌" } },
			{ "id": "buy_rep_kit", "name": "Zestaw Dozbrajający RepKit", "cost": 150, "item": { "id": "rep_b", "name": "Zestaw Dozbrajający", "type": "repair_kit", "count": 1, "weight": 1.0, "icon": "🛠️" } }
		]
	elif npc_type in ["weapons_dealer", "weapon_merchant", "weapon"]:
		merchant_goods = [
			{ "id": "buy_rifle", "name": "Karabin Laserowy Taktyczny", "cost": 350, "item": { "id": "w_laser_adv", "name": "Karabin Laserowy Taktyczny", "type": "weapon", "weaponType": "laser", "count": 1, "damage": 28, "weight": 3.0, "icon": "🔫" } },
			{ "id": "buy_ap_pack", "name": "Paczka Amunicji AP (x50)", "cost": 140, "item": { "id": "ammo_ap_pack_b", "name": "Amunicja AP (x50)", "type": "ammo_ap_pack", "count": 1, "weight": 1.0, "icon": "💥" } },
			{ "id": "buy_suppressor", "name": "Tłumik Taktyczny Dźwięku", "cost": 120, "item": { "id": "suppressor_b", "name": "Tłumik Taktyczny Dźwięku", "type": "attachment_suppressor", "count": 1, "weight": 0.4, "icon": "🔇" } },
			{ "id": "buy_scope", "name": "Celownik Optyczny Snajperski", "cost": 150, "item": { "id": "scope_b", "name": "Celownik Optyczny Snajperski", "type": "attachment_scope", "count": 1, "weight": 0.5, "icon": "🔭" } },
			{ "id": "buy_heavy_helm", "name": "Ciężki Hełm Taktyczny", "cost": 220, "item": { "id": "helm_heavy_b", "name": "Ciężki Hełm Taktyczny", "type": "helmet", "count": 1, "defense_bonus": 25, "weight": 3.5, "icon": "🪖" } }
		]

	# 1. KUPUJ OD HANDLARZA (300% Wartości Bazowej)
	var buy_header = Label.new()
	buy_header.text = "--- 🛒 KUPNO (300% WARTOŚCI BAZOWEJ) ---"
	buy_header.add_theme_color_override("font_color", Color("#00f3ff"))
	merchant_vbox.add_child(buy_header)

	for good in merchant_goods:
		var item_dict = good["item"]
		var buy_cost = GameManager.get_item_buy_price(item_dict) if GameManager.has_method("get_item_buy_price") else good["cost"]
		
		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(0, 40)
		
		var name_lbl = Label.new()
		name_lbl.text = good["name"]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_lbl)

		var cost_lbl = Label.new()
		cost_lbl.text = "Cena: %d 💰 (300%%)" % buy_cost
		cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cost_lbl.add_theme_color_override("font_color", Color("#ef4444"))
		hbox.add_child(cost_lbl)

		var btn = Button.new()
		btn.text = " KUP "
		btn.pressed.connect(func():
			if GameManager.player_stats.gold >= buy_cost:
				GameManager.player_stats.gold -= buy_cost
				GameManager.inventory.append(item_dict.duplicate())
				if SoundManager: SoundManager.play_pick()
				GameManager.add_log("Trade", "Zakupiono: %s za %d💰 (300%% wartości bazowej)" % [good["name"], buy_cost])
				GameManager.emit_signal("stats_changed")
				GameManager.emit_signal("inventory_changed")
				_populate_merchant_dialog(npc_type, npc_name)
			else:
				GameManager.add_log("Trade", "⚠️ Brak wystarczającej ilości Złota (%d 💰)!" % buy_cost)
		)
		hbox.add_child(btn)
		merchant_vbox.add_child(hbox)

	# 2. SPRZEDAJ HANDLARZOWI (15% Wartości Bazowej)
	var sell_header = Label.new()
	sell_header.text = "\n--- 💰 SPRZEDAŻ (15% WARTOŚCI BAZOWEJ) ---"
	sell_header.add_theme_color_override("font_color", Color("#f59e0b"))
	merchant_vbox.add_child(sell_header)

	var inv_items = GameManager.inventory
	if inv_items.size() == 0:
		var empty_lbl = Label.new()
		empty_lbl.text = "(Brak przedmiotów w ekwipunku do sprzedaży)"
		empty_lbl.add_theme_color_override("font_color", Color("#6b7280"))
		merchant_vbox.add_child(empty_lbl)
	else:
		for i in range(inv_items.size()):
			var inv_item = inv_items[i]
			if not inv_item: continue
			
			var sell_val = GameManager.get_item_sell_price(inv_item) if GameManager.has_method("get_item_sell_price") else 5
			var base_val = GameManager.get_item_base_value(inv_item) if GameManager.has_method("get_item_base_value") else 30
			
			var shbox = HBoxContainer.new()
			shbox.custom_minimum_size = Vector2(0, 40)

			var iname_lbl = Label.new()
			iname_lbl.text = (inv_item.get("icon", "📦") + " " + inv_item.get("name", "Przedmiot"))
			iname_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			shbox.add_child(iname_lbl)

			var sval_lbl = Label.new()
			sval_lbl.text = "+%d 💰 (15%% z %d💰)" % [sell_val, base_val]
			sval_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			sval_lbl.add_theme_color_override("font_color", Color("#10b981"))
			shbox.add_child(sval_lbl)

			var sbtn = Button.new()
			sbtn.text = " SPRZEDAJ "
			var idx = i
			sbtn.pressed.connect(func():
				if GameManager.sell_item_to_merchant(idx):
					_populate_merchant_dialog(npc_type, npc_name)
			)
			shbox.add_child(sbtn)
			merchant_vbox.add_child(shbox)

@onready var nick_edit = get_node_or_null("Modals/ModalPause/VBoxContainer/HBoxCustom/NickBox/NickEdit")
@onready var model_option = get_node_or_null("Modals/ModalPause/VBoxContainer/HBoxCustom/ModelBox/ModelOption")
@onready var private_check = get_node_or_null("Modals/ModalPause/VBoxContainer/MultiplayerBox/HBoxMp/PrivateCheck")
@onready var pass_edit = get_node_or_null("Modals/ModalPause/VBoxContainer/MultiplayerBox/HBoxMp/PassEdit")
@onready var save_btn = get_node_or_null("Modals/ModalPause/VBoxContainer/HBoxSaveLoad/SaveBtn")
@onready var load_btn = get_node_or_null("Modals/ModalPause/VBoxContainer/HBoxSaveLoad/LoadBtn")

func _setup_settings_ui():
	if nick_edit:
		nick_edit.text = GameManager.player_name
		nick_edit.text_changed.connect(func(new_text): GameManager.set_player_nickname(new_text))

	if model_option:
		model_option.clear()
		for m in GameManager.model_placeholders:
			model_option.add_item(m)
		model_option.selected = GameManager.selected_model_idx
		model_option.item_selected.connect(func(idx): GameManager.set_player_model(idx))

	if private_check:
		private_check.button_pressed = GameManager.is_private_server
		private_check.toggled.connect(func(toggled): GameManager.is_private_server = toggled)

	if pass_edit:
		pass_edit.text = GameManager.server_password
		pass_edit.text_changed.connect(func(new_pass): GameManager.server_password = new_pass)

	if save_btn:
		save_btn.pressed.connect(func(): GameManager.save_game_state())

	if load_btn:
		load_btn.pressed.connect(func(): GameManager.load_game_state())

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

func _on_main_menu_pressed():
	GameManager.save_and_exit_to_menu()

func _is_chat_typing() -> bool:
	var chat_nodes = get_tree().get_nodes_in_group("chat_box")
	if chat_nodes.size() > 0 and chat_nodes[0].has_method("is_typing_active"):
		return chat_nodes[0].is_typing_active()
	return false

func _unhandled_input(event):
	if _is_chat_typing(): return

	if event.is_action_pressed("toggle_pause"):
		toggle_modal(modal_pause)
	elif event.is_action_pressed("toggle_inventory"):
		_update_inventory_ui()
		toggle_modal(modal_inventory)
	elif event.is_action_pressed("toggle_crafting"):
		_update_crafting_ui()
		toggle_modal(modal_crafting)
	elif event.is_action_pressed("toggle_map"):
		if GameManager.has_item_type("gps"):
			toggle_modal(modal_map)
		else:
			show_notification("⚠️ Wymagany moduł GPS lub Mapa w ekwipunku!")
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_L:
		_toggle_log_panel()

func toggle_modal(modal_node):
	var is_open = modal_node.visible
	modal_pause.hide()
	modal_inventory.hide()
	modal_crafting.hide()
	modal_map.hide()
	modal_npc_quest.hide()
	modal_npc_merchant.hide()

	if not is_open:
		modal_node.show()
	_update_mouse_cursor_state()

func _on_stats_changed():
	var stats = GameManager.player_stats
	var integrity = stats.suit_integrity
	var current_w = GameManager.get_total_inventory_weight()
	var max_w = GameManager.get_max_carry_weight()
	var pct = GameManager.get_weight_percentage()

	var status_text = ""
	if SurvivalManager:
		if SurvivalManager.is_bleeding:
			status_text += "🩸 KRWAWIENIE (-%d HP/s)!\n" % int(SurvivalManager.bleeding_rate)
		if SurvivalManager.has_broken_leg():
			status_text += "🦴 ZŁAMANIE NÓG!\n"
		if SurvivalManager.food_poisoning > 0:
			status_text += "🤢 ZATRUCIE (%d%%)!\n" % int(SurvivalManager.food_poisoning)

	hp_text.text = "HP: %d/%d %s" % [stats.hp, stats.max_hp, status_text]
	if hp_bar:
		hp_bar.max_value = stats.max_hp
		hp_bar.value = stats.hp

	suit_text.text = "Skafander: %d%% 🛡️" % integrity
	if suit_bar:
		suit_bar.max_value = 100
		suit_bar.value = integrity

	if integrity < 20:
		suit_text.add_theme_color_override("font_color", Color("#ef4444"))
	elif integrity < 50:
		suit_text.add_theme_color_override("font_color", Color("#f59e0b"))
	else:
		suit_text.add_theme_color_override("font_color", Color("#00f3ff"))

	weight_text.text = "Udźwig: %.1f / %.1f kg (%d%%) 🎒" % [current_w, max_w, int(pct)]
	if pct >= 100.0:
		weight_text.add_theme_color_override("font_color", Color("#ef4444"))
	elif pct >= 80.0:
		weight_text.add_theme_color_override("font_color", Color("#f59e0b"))
	else:
		weight_text.add_theme_color_override("font_color", Color("#10b981"))

	hunger_text.text = "Głód: %d / 100" % stats.hunger
	if hunger_bar:
		hunger_bar.max_value = 100
		hunger_bar.value = stats.hunger

	thirst_text.text = "Pragnienie: %d / 100" % stats.thirst
	if thirst_bar:
		thirst_bar.max_value = 100
		thirst_bar.value = stats.thirst

	gold_text.text = "Złoto: %d 💰" % stats.gold

func _on_location_changed(new_location):
	var loc_names = {
		"house": "🛡️ Schron Taktyczny Base",
		"expedition": "🚀 Powierzchnia Ekspedycyjna",
		"town": "🏙️ Kolonia Ocalałych / Miasto",
		"dev": "🛠️ Sandbox Deweloperski"
	}
	if new_location == "custom_scene" and GameManager:
		var scene_file = GameManager.custom_destination_scene.get_file()
		if "CloneFactory" in scene_file:
			location_label.text = "🧬 Kompleks Fabryki Klonów (HARDCORE MISJA)"
			return
		elif "MerchantHub" in scene_file:
			location_label.text = "🏪 Międzygwiezdny Baser Handlowy"
			return
	location_label.text = loc_names.get(new_location, "Unknown Location")

func _on_timer_updated(time_left):
	if time_left < 0:
		timer_label.text = "☄️ EMISSION: PAUSED 🛡️"
		timer_label.add_theme_color_override("font_color", Color("#10b981"))
		return

	var m = time_left / 60
	var s = time_left % 60
	timer_label.text = "☄️ EMISSION: %02d:%02d" % [m, s]
	if time_left < 60:
		timer_label.add_theme_color_override("font_color", Color("#ef4444"))
	else:
		timer_label.add_theme_color_override("font_color", Color("#00f3ff"))

func _on_log_added(category: String, message: String):
	if log_box:
		log_box.text += "[" + category + "] " + message + "\n"
		log_box.set_caret_line(log_box.get_line_count())
	show_notification("[" + category + "] " + message)

func show_notification(msg: String):
	if notification_label:
		notification_label.text = msg
		notification_label.show()
		var tween = create_tween()
		tween.tween_property(notification_label, "modulate:a", 1.0, 0.2)
		tween.tween_interval(2.5)
		tween.tween_property(notification_label, "modulate:a", 0.0, 0.5)
		tween.tween_callback(notification_label.hide)

var is_emp_active: bool = false

func trigger_emp_glitch(duration: float = 5.0):
	is_emp_active = true
	show_notification("⚡ WARNING: EMP INTERFERENCE! HUD RESTORED IN %.1f s ⚡" % duration)
	var main_control = get_node_or_null("Control")
	if main_control:
		main_control.modulate = Color(1.5, 0.4, 0.4, 0.85)

	get_tree().create_timer(duration).timeout.connect(func():
		is_emp_active = false
		if main_control:
			main_control.modulate = Color(1.0, 1.0, 1.0, 1.0)
		show_notification("✨ TACTICAL SYSTEM REBOOT: HUD RESTORED")
	)

var modal_storage: PanelContainer = null
var current_open_chest: Node = null
var storage_player_grid: GridContainer = null
var storage_chest_grid: GridContainer = null
var storage_title_lbl: Label = null

func _setup_storage_modal_ui():
	if modal_storage: return

	modal_storage = PanelContainer.new()
	modal_storage.name = "ModalStorage"
	modal_storage.custom_minimum_size = Vector2(850, 520)
	modal_storage.anchors_preset = Control.PRESET_CENTER
	modal_storage.anchor_left = 0.5; modal_storage.anchor_top = 0.5
	modal_storage.anchor_right = 0.5; modal_storage.anchor_bottom = 0.5
	modal_storage.offset_left = -425; modal_storage.offset_top = -260
	modal_storage.offset_right = 425; modal_storage.offset_bottom = 260
	modal_storage.visible = false

	var glass_style = StyleBoxFlat.new()
	glass_style.bg_color = Color(0.05, 0.09, 0.16, 0.94)
	glass_style.border_color = Color(0.0, 0.95, 1.0, 0.8)
	glass_style.border_width_left = 2; glass_style.border_width_top = 2
	glass_style.border_width_right = 2; glass_style.border_width_bottom = 2
	glass_style.set_corner_radius_all(10)
	modal_storage.add_theme_stylebox_override("panel", glass_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	modal_storage.add_child(margin)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	margin.add_child(main_vbox)

	var header_hbox = HBoxContainer.new()
	storage_title_lbl = Label.new()
	storage_title_lbl.text = "📦 CHEST STORAGE"
	storage_title_lbl.add_theme_font_size_override("font_size", 18)
	storage_title_lbl.add_theme_color_override("font_color", Color("#00f3ff"))
	storage_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(storage_title_lbl)

	var close_btn = Button.new()
	close_btn.text = "❌ CLOSE [ESC]"
	close_btn.pressed.connect(func(): close_storage_chest_ui())
	header_hbox.add_child(close_btn)
	main_vbox.add_child(header_hbox)

	var sep = HSeparator.new()
	main_vbox.add_child(sep)

	var cols_hbox = HBoxContainer.new()
	cols_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols_hbox.add_theme_constant_override("separation", 24)
	main_vbox.add_child(cols_hbox)

	var p_col = VBoxContainer.new()
	p_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var p_title = Label.new()
	p_title.text = "🎒 Player Inventory"
	p_title.add_theme_font_size_override("font_size", 15)
	p_title.add_theme_color_override("font_color", Color("#f59e0b"))
	p_col.add_child(p_title)

	var p_scroll = ScrollContainer.new()
	p_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	storage_player_grid = GridContainer.new()
	storage_player_grid.columns = 4
	p_scroll.add_child(storage_player_grid)
	p_col.add_child(p_scroll)

	var p_store_all_btn = Button.new()
	p_store_all_btn.text = "➡️ Store All in Chest"
	p_store_all_btn.pressed.connect(func(): _transfer_all_to_chest())
	p_col.add_child(p_store_all_btn)
	cols_hbox.add_child(p_col)

	var c_col = VBoxContainer.new()
	c_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var c_title = Label.new()
	c_title.text = "📦 Chest Storage Content"
	c_title.add_theme_font_size_override("font_size", 15)
	c_title.add_theme_color_override("font_color", Color("#10b981"))
	c_col.add_child(c_title)

	var c_scroll = ScrollContainer.new()
	c_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	storage_chest_grid = GridContainer.new()
	storage_chest_grid.columns = 4
	c_scroll.add_child(storage_chest_grid)
	c_col.add_child(c_scroll)

	var c_take_all_btn = Button.new()
	c_take_all_btn.text = "⬅️ Take All to Inventory"
	c_take_all_btn.pressed.connect(func(): _transfer_all_to_player())
	c_col.add_child(c_take_all_btn)
	cols_hbox.add_child(c_col)

	var control_root = $Control if has_node("Control") else self
	control_root.add_child(modal_storage)

func open_storage_chest_ui(chest_node: Node):
	current_open_chest = chest_node
	_setup_storage_modal_ui()
	if modal_storage:
		modal_storage.show()
		_update_storage_ui()
		_update_mouse_cursor_state()
		if SoundManager: SoundManager.play_level_up()

func close_storage_chest_ui():
	current_open_chest = null
	if modal_storage:
		modal_storage.hide()
		_update_mouse_cursor_state()
		if SoundManager: SoundManager.play_pick()

func _update_storage_ui():
	if not current_open_chest or not modal_storage or not modal_storage.visible: return

	var chest_items = current_open_chest.get("stored_items")
	if chest_items == null: chest_items = []
	var max_c_slots = current_open_chest.get("max_slots") if current_open_chest.get("max_slots") != null else 16

	if storage_title_lbl:
		storage_title_lbl.text = "📦 CHEST STORAGE [%d/%d Slotów]" % [chest_items.size(), max_c_slots]

	for child in storage_player_grid.get_children():
		child.queue_free()

	for i in range(GameManager.inventory.size()):
		var item = GameManager.inventory[i]
		var btn = _create_storage_item_button(item, true, i)
		storage_player_grid.add_child(btn)

	for child in storage_chest_grid.get_children():
		child.queue_free()

	for i in range(chest_items.size()):
		var item = chest_items[i]
		var btn = _create_storage_item_button(item, false, i)
		storage_chest_grid.add_child(btn)

func _create_storage_item_button(item: Dictionary, is_player_item: bool, index: int) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(72, 72)
	var icon_sym = item.get("icon", "📦")
	var count = item.get("count", 1)
	btn.text = "%s\nx%d" % [icon_sym, count] if count > 1 else icon_sym
	btn.tooltip_text = item.get("name", "") + "\n" + item.get("desc", "")

	if is_player_item:
		btn.pressed.connect(func(): _transfer_item_to_chest(index))
	else:
		btn.pressed.connect(func(): _transfer_item_to_player(index))

	return btn

func _transfer_item_to_chest(inv_idx: int):
	if not current_open_chest: return
	var chest_items = current_open_chest.get("stored_items")
	var max_c_slots = current_open_chest.get("max_slots") if current_open_chest.get("max_slots") != null else 16
	if chest_items == null or inv_idx < 0 or inv_idx >= GameManager.inventory.size(): return

	if chest_items.size() >= max_c_slots:
		if SoundManager: SoundManager.play_hit()
		GameManager.add_log("Skrzynia", "⚠️ Storage chest is full!")
		return

	var item = GameManager.inventory[inv_idx]
	GameManager.inventory.remove_at(inv_idx)
	chest_items.append(item)

	if SoundManager: SoundManager.play_pick()
	GameManager.emit_signal("inventory_changed")
	_update_storage_ui()

func _transfer_item_to_player(chest_idx: int):
	if not current_open_chest: return
	var chest_items = current_open_chest.get("stored_items")
	if chest_items == null or chest_idx < 0 or chest_idx >= chest_items.size(): return

	var item = chest_items[chest_idx]
	var success = GameManager.add_item_to_inventory(item)
	if success:
		chest_items.remove_at(chest_idx)
		if SoundManager: SoundManager.play_pick()
		_update_storage_ui()
	else:
		if SoundManager: SoundManager.play_hit()
		GameManager.add_log("Ekwipunek", "⚠️ Inventory is full!")

func _transfer_all_to_chest():
	if not current_open_chest: return
	var chest_items = current_open_chest.get("stored_items")
	var max_c_slots = current_open_chest.get("max_slots") if current_open_chest.get("max_slots") != null else 16
	if chest_items == null: return

	var moved_any = false
	while GameManager.inventory.size() > 0 and chest_items.size() < max_c_slots:
		var item = GameManager.inventory.pop_back()
		chest_items.append(item)
		moved_any = true

	if moved_any:
		if SoundManager: SoundManager.play_pick()
		GameManager.emit_signal("inventory_changed")
		_update_storage_ui()

func _transfer_all_to_player():
	if not current_open_chest: return
	var chest_items = current_open_chest.get("stored_items")
	if chest_items == null: return

	var moved_any = false
	while chest_items.size() > 0:
		var item = chest_items[chest_items.size() - 1]
		var success = GameManager.add_item_to_inventory(item)
		if success:
			chest_items.pop_back()
			moved_any = true
		else:
			break

	if moved_any:
		if SoundManager: SoundManager.play_pick()
		_update_storage_ui()
