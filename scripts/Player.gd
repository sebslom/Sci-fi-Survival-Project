extends CharacterBody3D

@export var mouse_sensitivity = 0.002
@export var base_speed = 8.5
@export var sprint_speed = 14.0
@export var jump_force = 8.0
@export var gravity = 20.0

@onready var head = $Head
@onready var camera = $Head/Camera
@onready var raycast = $Head/Camera/RayCast
@onready var fps_weapon = $Head/Camera/FPSWeapon
@onready var muzzle_light = $Head/Camera/FPSWeapon/MuzzleLight
@onready var flashlight_light = get_node_or_null("Head/Camera/Flashlight")

var camera_yaw = 0.0
var camera_pitch = 0.0
var step_timer = 0.0
var recoil_offset = 0.0
var is_sprinting = false
var last_y_velocity = 0.0
var is_aiming_scope = false
var placement_cooldown_timer: float = 0.0

# Building Ghost Preview
var ghost_mesh_instance: MeshInstance3D = null
var ghost_mat_valid: StandardMaterial3D
var ghost_mat_invalid: StandardMaterial3D
var is_ghost_valid: bool = false
var ghost_target_pos: Vector3 = Vector3.ZERO

# 3D Player Legs & Body Model Placeholder for First-Person View (FPV)
var player_legs_mesh: MeshInstance3D = null
var player_body_mesh: MeshInstance3D = null

func _ready():
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if raycast:
		raycast.add_exception(self)
		raycast.collide_with_areas = true
		raycast.collide_with_bodies = true
	_setup_ghost_preview()
	_setup_3d_player_model()
	if GameManager:
		GameManager.player_model_changed.connect(_on_player_model_changed)

	# FPP Camera & Local Authority Mesh Visibility Layers Setup
	if is_multiplayer_authority():
		_configure_local_fpp_visibility()

func _configure_local_fpp_visibility():
	# Assign local torso/body mesh to Visual Layer 2
	if player_body_mesh:
		player_body_mesh.layers = 2 # Layer 2: Local Body Mesh

	# Disable Layer 2 in local camera's Cull Mask (1048575 - 2 = 1048573)
	if camera:
		camera.cull_mask = 1048573 # Cull Layer 2 from local FPP camera view

	# Player legs remain on Layer 1 so player can see boots/legs when looking down
	if player_legs_mesh:
		player_legs_mesh.layers = 1

func _setup_3d_player_model():
	# Legs mesh placed below camera so player can see legs when looking down
	player_legs_mesh = MeshInstance3D.new()
	var leg_box = BoxMesh.new()
	leg_box.size = Vector3(0.5, 0.7, 0.4)
	player_legs_mesh.mesh = leg_box
	player_legs_mesh.position = Vector3(0, 0.35, -0.05)
	add_child(player_legs_mesh)

	# Torso/body mesh placed at player center for multiplayer 3D representation
	player_body_mesh = MeshInstance3D.new()
	var body_box = BoxMesh.new()
	body_box.size = Vector3(0.6, 1.0, 0.4)
	player_body_mesh.mesh = body_box
	player_body_mesh.position = Vector3(0, 1.0, 0.0)
	add_child(player_body_mesh)

	if GameManager:
		_update_player_model_appearance(GameManager.selected_model_idx)

func _on_player_model_changed(model_idx: int):
	_update_player_model_appearance(model_idx)

func _update_player_model_appearance(idx: int):
	if not player_legs_mesh or not player_body_mesh: return
	var mat = StandardMaterial3D.new()
	match idx:
		0: # Alpha Scout
			mat.albedo_color = Color("#06b6d4")
			mat.emission_enabled = true
			mat.emission = Color("#00f3ff")
			mat.emission_energy_multiplier = 0.5
		1: # Heavy Commando
			mat.albedo_color = Color("#f59e0b")
			mat.roughness = 0.3
			mat.metallic = 0.8
		2: # Bio-Hazard Suit
			mat.albedo_color = Color("#10b981")
			mat.roughness = 0.9
		3: # Tech Engineer
			mat.albedo_color = Color("#a855f7")
			mat.emission_enabled = true
			mat.emission = Color("#a855f7")
			mat.emission_energy_multiplier = 0.6

	player_legs_mesh.material_override = mat
	player_body_mesh.material_override = mat

var ghost_area: Area3D = null
var ghost_col_shape: CollisionShape3D = null

func _setup_ghost_preview():
	ghost_mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.4, 1.4, 1.4)
	ghost_mesh_instance.mesh = box

	ghost_area = Area3D.new()
	ghost_area.name = "GhostArea"
	ghost_area.collision_layer = 0
	ghost_area.collision_mask = 1
	ghost_col_shape = CollisionShape3D.new()
	var bshape = BoxShape3D.new()
	bshape.size = Vector3(1.2, 1.2, 1.2)
	ghost_col_shape.shape = bshape
	ghost_area.add_child(ghost_col_shape)
	ghost_mesh_instance.add_child(ghost_area)

	ghost_mat_valid = StandardMaterial3D.new()
	ghost_mat_valid.albedo_color = Color(0.1, 1.0, 0.2, 0.45)
	ghost_mat_valid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	ghost_mat_invalid = StandardMaterial3D.new()
	ghost_mat_invalid.albedo_color = Color(1.0, 0.1, 0.1, 0.45)
	ghost_mat_invalid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	ghost_mesh_instance.material_override = ghost_mat_invalid
	ghost_mesh_instance.visible = false
	add_child(ghost_mesh_instance)

	if raycast:
		raycast.add_exception(ghost_mesh_instance)
		raycast.add_exception(ghost_area)

func _is_typing() -> bool:
	var chat_nodes = get_tree().get_nodes_in_group("chat_box")
	if chat_nodes.size() > 0 and chat_nodes[0].has_method("is_typing_active"):
		if chat_nodes[0].is_typing_active():
			return true
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner and (focus_owner is LineEdit or focus_owner is TextEdit):
		return true
	return false

func _input(event):
	if _is_typing(): return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var sens = mouse_sensitivity * (0.4 if is_aiming_scope else 1.0)
		rotate_y(-event.relative.x * sens)

		camera_pitch -= event.relative.y * sens
		camera_pitch = clamp(camera_pitch, deg_to_rad(-85.0), deg_to_rad(85.0))
		head.rotation.x = camera_pitch

	if event is InputEventMouseButton and event.pressed:
		var hud = get_tree().get_nodes_in_group("hud")
		var is_modal_open = false
		if hud.size() > 0 and hud[0].has_method("is_any_modal_open"):
			is_modal_open = hud[0].is_any_modal_open()

		if not is_modal_open and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if _is_typing(): return

	if event.is_action_pressed("shoot") and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		use_active_hotbar_item()

	if event.is_action_pressed("interact"):
		handle_interaction()

	if event.is_action_pressed("reload"):
		var active_slot = GameManager.hotbar.get(GameManager.active_hotbar_slot)
		if active_slot and active_slot.get("type") in ["weapon", "melee"]:
			if WeaponManager and WeaponManager.is_jammed(active_slot):
				WeaponManager.unjam_weapon(active_slot)
			elif active_slot.get("type") == "weapon":
				GameManager.cycle_ammo_type(GameManager.active_hotbar_slot)

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		toggle_flashlight()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var active_slot = GameManager.hotbar.get(GameManager.active_hotbar_slot)
		if active_slot and active_slot.get("type") == "flashlight":
			toggle_flashlight()

	if event.is_action_pressed("hotbar_1"): select_hotbar_slot(1)
	if event.is_action_pressed("hotbar_2"): select_hotbar_slot(2)
	if event.is_action_pressed("hotbar_3"): select_hotbar_slot(3)
	if event.is_action_pressed("hotbar_4"): select_hotbar_slot(4)
	if event.is_action_pressed("hotbar_5"): select_hotbar_slot(5)

func toggle_flashlight():
	var has_flashlight = GameManager and GameManager.has_item_type("flashlight")
	if not has_flashlight:
		if SoundManager: SoundManager.play_hit()
		if GameManager: GameManager.add_log("Ekwipunek", "⚠️ BRAK LATARKI! Wytwórz Latarkę Taktyczną w Craftingu [C] lub znajdź ją w skrzyni z łupem!")
		return

	if not flashlight_light:
		flashlight_light = get_node_or_null("Head/Camera/Flashlight")

	if flashlight_light:
		flashlight_light.visible = not flashlight_light.visible
		if SoundManager: SoundManager.play_pick()
		if GameManager: GameManager.add_log("Latarka", "🔦 " + ("WŁĄCZONO" if flashlight_light.visible else "WYŁĄCZONO") + " latarkę taktyczną [F].")

func select_hotbar_slot(num: int):
	GameManager.active_hotbar_slot = num
	if SoundManager:
		SoundManager.play_pick()
	var slot = GameManager.hotbar.get(num)
	if slot:
		GameManager.add_log("Hotbar", "Wybrano slot [" + str(num) + "]: " + slot.get("name", ""))
	else:
		GameManager.add_log("Hotbar", "Slot [" + str(num) + "] jest pusty.")

func _physics_process(delta):
	_process_movement(delta)
	_update_ghost_building_preview()
	_update_crosshair_target_inspection()

func _update_crosshair_target_inspection():
	var hud_nodes = get_tree().get_nodes_in_group("hud")
	if hud_nodes.size() == 0: return

	var hud = hud_nodes[0]

	if raycast and raycast.is_colliding():
		var col_point = raycast.get_collision_point()
		var dist = global_position.distance_to(col_point)
		if dist <= 4.0:
			var col = raycast.get_collider()
			if col:
				var target_node = col
				if not target_node.has_method("interact") and not target_node.has_method("get_interaction_prompt") and col.get_parent():
					target_node = col.get_parent()
				
				if target_node.has_method("get_interaction_prompt"):
					var ptext = target_node.get_interaction_prompt()
					if hud.has_method("update_target_inspection"):
						hud.update_target_inspection(ptext)
					return
				elif target_node.get("enemy_name"):
					var ename = target_node.get("enemy_name")
					var chp = target_node.get("hp") if target_node.get("hp") != null else 0
					var mhp = target_node.get("max_hp") if target_node.get("max_hp") != null else 0
					if hud.has_method("update_target_inspection"):
						hud.update_target_inspection("👾 %s [HP: %d/%d]" % [ename, chp, mhp])
					return
				elif target_node.has_method("interact"):
					if hud.has_method("update_target_inspection"):
						hud.update_target_inspection("[E] Interact")
					return

	if hud.has_method("update_target_inspection"):
		hud.update_target_inspection("")

func _process_movement(delta):
	placement_cooldown_timer = max(0.0, placement_cooldown_timer - delta)
	if _is_typing():
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= 15.0 * delta
		move_and_slide()
		return

	var weight_pct = GameManager.get_weight_percentage()
	if is_nan(weight_pct): weight_pct = 0.0
	
	var has_broken_legs = false
	if SurvivalManager:
		has_broken_legs = SurvivalManager.has_broken_leg()
	
	var can_sprint = (weight_pct < 95.0) and not has_broken_legs
	var can_jump = (weight_pct < 100.0) and not has_broken_legs

	# Artifact & Equipment Stat Bonuses
	var art_effects = GameManager.get_total_artifact_effects()
	var net_speed_bonus = art_effects["speed_boost"] - art_effects["speed_penalty"]
	if GameManager.equipment["boots"]:
		net_speed_bonus += GameManager.equipment["boots"].get("speed_bonus", 0.8)

	is_sprinting = can_sprint and Input.is_action_pressed("sprint")
	var current_speed = (sprint_speed if is_sprinting else base_speed) + net_speed_bonus
	if weight_pct >= 100.0:
		current_speed *= 0.85
	if has_broken_legs:
		current_speed *= 0.6

	var active_slot = GameManager.hotbar.get(GameManager.active_hotbar_slot)
	var has_scope = (active_slot and active_slot.get("type") == "weapon" and WeaponManager and WeaponManager.has_attachment(active_slot, "scope"))
	is_aiming_scope = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and has_scope
	if is_aiming_scope:
		current_speed *= 0.5

	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"): input_dir.y -= 1
	if Input.is_action_pressed("move_backward"): input_dir.y += 1
	if Input.is_action_pressed("move_left"): input_dir.x -= 1
	if Input.is_action_pressed("move_right"): input_dir.x += 1

	if input_dir.length() > 0:
		input_dir = input_dir.normalized()

	var forward = -head.global_transform.basis.z
	forward.y = 0.0
	if forward.length() > 0.001:
		forward = forward.normalized()
	else:
		forward = Vector3(0, 0, -1)

	var right = head.global_transform.basis.x
	right.y = 0.0
	if right.length() > 0.001:
		right = right.normalized()
	else:
		right = Vector3(1, 0, 0)

	var direction = (forward * (-input_dir.y) + right * input_dir.x)
	if direction.length() > 0:
		direction = direction.normalized()

	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	if not is_on_floor():
		velocity.y -= gravity * delta
		last_y_velocity = velocity.y
	else:
		if last_y_velocity < -12.0:
			var fall_impact = abs(last_y_velocity) - 10.0
			var fall_dmg = int(fall_impact * 4.0)
			take_damage(fall_dmg)
			if SurvivalManager:
				SurvivalManager.inflict_damage(fall_dmg, true)
		last_y_velocity = 0.0

		if Input.is_action_just_pressed("jump") and can_jump:
			velocity.y = jump_force + art_effects.get("jump_boost", 0.0)
			if SoundManager:
				SoundManager.play_jump()

	if GameManager and GameManager.player_stats.hp <= 0 and not GameManager.is_player_dying:
		die()
		return

	move_and_slide()

	var target_fov = 35.0 if is_aiming_scope else (86.0 if is_sprinting else 75.0)
	camera.fov = lerp(camera.fov, target_fov, delta * 12.0)

	var bob_multiplier = 2.2 if has_broken_legs else (1.8 if weight_pct >= 85.0 else 1.0)
	if direction.length() > 0 and is_on_floor():
		step_timer += delta * (12.0 if is_sprinting else (5.0 if has_broken_legs else 8.0))
		camera.position.y = sin(step_timer * 2.0) * 0.06 * bob_multiplier
	else:
		camera.position.y = lerp(camera.position.y, 0.0, delta * 10.0)

func take_damage(amount: int):
	if GameManager.player_stats.hp <= 0: return
	GameManager.player_stats.hp = max(0, GameManager.player_stats.hp - amount)
	if SoundManager: SoundManager.play_hit()
	GameManager.emit_signal("stats_changed")
	
	if GameManager.player_stats.hp <= 0:
		die()

func die():
	if GameManager:
		GameManager.handle_player_death(self)

func _update_ghost_building_preview():
	if not ghost_mesh_instance: return
	
	var active_slot = GameManager.hotbar.get(GameManager.active_hotbar_slot)
	if not active_slot or active_slot.get("type") != "furniture" or active_slot.get("count", 1) <= 0:
		ghost_mesh_instance.visible = false
		return

	if raycast:
		raycast.add_exception(ghost_mesh_instance)
		if ghost_area: raycast.add_exception(ghost_area)

	if raycast and raycast.is_colliding():
		var col_point = raycast.get_collision_point()
		var col_normal = raycast.get_collision_normal()
		var col_node = raycast.get_collider()

		if col_node == ghost_mesh_instance or col_node == ghost_area:
			return

		var f_type = active_slot.get("furnitureType", "")
		var is_wall_mounted = f_type in ["painting", "wall_cabinet", "wall_shelf", "light_bulb", "wall_window", "wall_doorway", "window_glass", "door"]
		var is_ceiling_mounted = f_type in ["light_bulb"]

		# Assign preview mesh size matching object dimensions
		var mesh_box_size = Vector3(1.2, 1.2, 1.2)
		if f_type in ["floor", "roof"]: mesh_box_size = Vector3(2.0, 0.2, 2.0)
		elif f_type == "stairs": mesh_box_size = Vector3(2.0, 3.0, 2.0)
		elif f_type in ["door", "wall_doorway", "wall_window"]: mesh_box_size = Vector3(2.0, 3.0, 0.2)
		elif f_type == "window_glass": mesh_box_size = Vector3(1.5, 1.5, 0.1)
		elif f_type in ["decon_chamber", "isotope"]: mesh_box_size = Vector3(2.0, 3.0, 2.0)
		elif f_type == "bed": mesh_box_size = Vector3(1.2, 0.8, 2.2)
		elif f_type == "chair": mesh_box_size = Vector3(0.8, 1.0, 0.8)
		elif f_type == "distiller": mesh_box_size = Vector3(1.5, 2.0, 1.5)
		elif f_type == "hydro_shelf": mesh_box_size = Vector3(1.6, 2.4, 1.0)
		elif f_type == "table": mesh_box_size = Vector3(2.2, 1.0, 1.4)
		elif f_type == "wardrobe": mesh_box_size = Vector3(1.6, 2.8, 1.0)
		elif f_type == "chest": mesh_box_size = Vector3(1.4, 1.2, 1.4)
		elif f_type == "planter": mesh_box_size = Vector3(1.6, 0.8, 1.2)
		elif f_type == "radio": mesh_box_size = Vector3(0.8, 0.6, 0.5)
		elif f_type == "light_bulb": mesh_box_size = Vector3(0.4, 0.5, 0.4)
		elif f_type == "boar_hide": mesh_box_size = Vector3(2.4, 0.05, 1.8)

		if not ghost_mesh_instance.mesh or not (ghost_mesh_instance.mesh is BoxMesh) or ghost_mesh_instance.mesh.get("size") != mesh_box_size:
			var new_box = BoxMesh.new()
			new_box.size = mesh_box_size
			ghost_mesh_instance.mesh = new_box

		# Flexible Placement: Smart Target Snapping OR Free Ground/Wall Placement
		var target_btype = str(col_node.get("building_type")) if col_node else ""
		if f_type == "window_glass" and (target_btype == "wall_window" or (col_node and col_node.is_in_group("placed_structure"))):
			ghost_target_pos = col_node.global_position
		elif f_type == "door" and (target_btype == "wall_doorway" or (col_node and col_node.is_in_group("placed_structure"))):
			ghost_target_pos = col_node.global_position
		else:
			var half_h = mesh_box_size.y * 0.5
			if col_normal.y > 0.5:
				# Raise object origin by half height + 0.01 above ground surface so collider sits flush on top of floor/terrain
				var target_y = col_point.y + half_h + 0.01
				var grid_step = Vector3(1.0, 0.1, 1.0) if f_type in ["floor", "roof", "stairs", "wall_window", "wall_doorway"] else Vector3(0.5, 0.1, 0.5)
				var snapped_xz = col_point.snapped(grid_step)
				ghost_target_pos = Vector3(snapped_xz.x, target_y, snapped_xz.z)
			elif col_normal.y < -0.5:
				# Ceiling Placement: shift downward by half height
				var target_y = col_point.y - half_h - 0.01
				ghost_target_pos = Vector3(col_point.x, target_y, col_point.z)
			else:
				# Vertical Wall Placement: offset along normal by half depth
				var half_d = mesh_box_size.z * 0.5 if mesh_box_size.z < mesh_box_size.x else mesh_box_size.x * 0.5
				ghost_target_pos = col_point + col_normal * (half_d + 0.02)

		ghost_mesh_instance.global_position = ghost_target_pos
		ghost_mesh_instance.visible = true

		# Update ghost collision shape dimensions for overlap check
		var ghost_box_size = mesh_box_size * 0.85
		if ghost_col_shape and ghost_col_shape.shape is BoxShape3D:
			ghost_col_shape.shape.size = ghost_box_size

		# Overlapping 3D Physical Collision Check (Model Clipping)
		var is_intersecting = false
		if ghost_area:
			var overlapping_bodies = ghost_area.get_overlapping_bodies()
			for body in overlapping_bodies:
				if body == self or body == ghost_mesh_instance: continue
				# Ignore supporting surface being placed on
				if body == col_node and col_normal.y > 0.5: continue
				# Ignore ground terrain surface
				var bname = body.name.to_lower()
				if bname.contains("ground") or bname.contains("terrain") or body.is_in_group("terrain") or (body is StaticBody3D and (bname.contains("floor") or bname.contains("sand") or bname.contains("map"))):
					continue
				# Allow hosting frame for door & window
				if (f_type == "door" and body == col_node) or (f_type == "window_glass" and body == col_node):
					continue
				
				is_intersecting = true
				break

		if is_wall_mounted:
			is_ghost_valid = (abs(col_normal.y) < 0.5 or (is_ceiling_mounted and col_normal.y < -0.5) or (col_node and col_node.is_in_group("placed_structure"))) and not is_intersecting
		else:
			is_ghost_valid = (col_normal.y > 0.5 or (col_node and col_node.is_in_group("placed_structure"))) and not is_intersecting

		ghost_mesh_instance.material_override = ghost_mat_valid if is_ghost_valid else ghost_mat_invalid
	else:
		ghost_mesh_instance.visible = false

func use_active_hotbar_item():
	var active_slot = GameManager.hotbar.get(GameManager.active_hotbar_slot)
	if not active_slot:
		use_unarmed_attack()
		return

	var item_type = active_slot.get("type", "")
	if item_type in ["weapon", "melee"]:
		var cond = WeaponManager.get_condition(active_slot) if WeaponManager else 500.0
		if cond <= 0.0:
			use_broken_weapon_club(active_slot)
			return

	if item_type == "weapon":
		shoot_weapon(active_slot)
	elif item_type == "melee":
		use_melee_weapon(active_slot)
	elif item_type == "flashlight":
		use_flashlight_melee_attack(active_slot)
	elif item_type == "furniture" and ghost_mesh_instance and ghost_mesh_instance.visible and is_ghost_valid:
		if placement_cooldown_timer > 0.0:
			return
		placement_cooldown_timer = 0.3
		place_furniture_structure(active_slot, ghost_target_pos)
	else:
		use_unarmed_attack()

func use_flashlight_melee_attack(item_dict: Dictionary):
	# Heavy Tactical Flashlight Melee Attack (Bare fists 5 + 2 = 7 DMG)
	camera.rotation.z += 0.04
	get_tree().create_timer(0.09).timeout.connect(func(): camera.rotation.z -= 0.04)

	if raycast and raycast.is_colliding():
		var col = raycast.get_collider()
		if col and col != self and not col.is_in_group("player"):
			var target_node = col
			if not target_node.has_method("take_damage") and col.get_parent() and col.get_parent().has_method("take_damage"):
				target_node = col.get_parent()
				
			if target_node and target_node != self and not target_node.is_in_group("player") and target_node.has_method("take_damage"):
				var dmg = 7 # Unarmed (5) + 2 = 7 DMG
				target_node.take_damage(dmg)
				if GameManager: GameManager.add_log("Combat", "🔦 TACTICAL FLASHLIGHT ATTACK: -%d HP (Atak bez broni +2)!" % dmg)

	if SoundManager: SoundManager.play_hit()

func use_unarmed_attack():
	# Unarmed Bare Fists Attack (5 DMG)
	camera.rotation.z += 0.03
	get_tree().create_timer(0.08).timeout.connect(func(): camera.rotation.z -= 0.03)

	if raycast and raycast.is_colliding():
		var col = raycast.get_collider()
		if col and col != self and not col.is_in_group("player"):
			var target_node = col
			if not target_node.has_method("take_damage") and col.get_parent() and col.get_parent().has_method("take_damage"):
				target_node = col.get_parent()
				
			if target_node and target_node != self and not target_node.is_in_group("player") and target_node.has_method("take_damage"):
				var dmg = 5
				target_node.take_damage(dmg)
				if GameManager: GameManager.add_log("Combat", "👊 ATAK PIĘŚCIĄ (Walka Wręcz): -%d HP!" % dmg)

	if SoundManager: SoundManager.play_hit()

func use_broken_weapon_club(item_dict: Dictionary):
	# Broken Weapon Attack (Unarmed 5 + 1 = 6 DMG)
	camera.rotation.z += 0.04
	get_tree().create_timer(0.09).timeout.connect(func(): camera.rotation.z -= 0.04)

	if raycast and raycast.is_colliding():
		var col = raycast.get_collider()
		if col and col != self and not col.is_in_group("player"):
			var target_node = col
			if not target_node.has_method("take_damage") and col.get_parent() and col.get_parent().has_method("take_damage"):
				target_node = col.get_parent()
				
			if target_node and target_node != self and not target_node.is_in_group("player") and target_node.has_method("take_damage"):
				var dmg = 6
				var w_name = item_dict.get("name", "Zepsuta Broń")
				target_node.take_damage(dmg)
				if GameManager: GameManager.add_log("Combat", "🔨 ATAK ZEPSUTĄ BRONIĄ (%s): -%d HP (Atak bez broni +1)!" % [w_name, dmg])

	if SoundManager: SoundManager.play_hit()

func shoot_weapon(item_dict: Dictionary):
	var ammo_type = item_dict.get("ammo_type", "standard")
	var ammo_left = GameManager.ammo_inventory.get(ammo_type, 0)
	if ammo_left <= 0:
		if SoundManager: SoundManager.play_hit()
		GameManager.add_log("Amunicja", "⚠️ BRAK AMUNICJI (%s)! Wytwórz w Rzemiośle [C] lub znajdź skrzynię z łupem!" % ammo_type.to_upper())
		return

	if WeaponManager and WeaponManager.is_jammed(item_dict):
		if SoundManager: SoundManager.play_hit()
		GameManager.add_log("Broń", "⚠️ BROŃ ZACIĘTA! Wciśnij [R], aby usunąć zacięcie!")
		return

	GameManager.ammo_inventory[ammo_type] -= 1
	GameManager.emit_signal("inventory_changed")

	if WeaponManager:
		WeaponManager.degrade_weapon(item_dict, 0.08)

	if muzzle_light:
		muzzle_light.visible = true
		get_tree().create_timer(0.05).timeout.connect(func(): muzzle_light.visible = false)

	recoil_offset += 0.05
	camera.rotation.x += 0.03
	get_tree().create_timer(0.08).timeout.connect(func(): camera.rotation.x -= 0.03)

	if raycast and raycast.is_colliding():
		var col = raycast.get_collider()
		if col and col != self and not col.is_in_group("player"):
			var target_node = col
			if not target_node.has_method("take_damage") and col.get_parent() and col.get_parent().has_method("take_damage"):
				target_node = col.get_parent()
				
			if target_node and target_node != self and not target_node.is_in_group("player") and target_node.has_method("take_damage"):
				var dmg = item_dict.get("damage", 20)
				target_node.take_damage(dmg)

	if SoundManager: SoundManager.play_shoot()

func use_melee_weapon(item_dict: Dictionary):
	if WeaponManager:
		WeaponManager.degrade_weapon(item_dict, 0.3)

	camera.rotation.z += 0.05
	get_tree().create_timer(0.1).timeout.connect(func(): camera.rotation.z -= 0.05)

	if raycast and raycast.is_colliding():
		var col = raycast.get_collider()
		if col and col != self and not col.is_in_group("player"):
			var target_node = col
			if not target_node.has_method("take_damage") and col.get_parent() and col.get_parent().has_method("take_damage"):
				target_node = col.get_parent()
				
			if target_node and target_node != self and not target_node.is_in_group("player") and target_node.has_method("take_damage"):
				var dmg = item_dict.get("damage", 35)
				target_node.take_damage(dmg)
				GameManager.add_log("Combat", "💥 Melee weapon slash: -" + str(dmg) + " HP!")

	if SoundManager: SoundManager.play_pick()

func get_structure_parent_container() -> Node:
	var main_scene = get_parent()
	if main_scene and main_scene.get("current_location_instance") and is_instance_valid(main_scene.get("current_location_instance")):
		return main_scene.get("current_location_instance")
	return get_parent()

func _on_structure_placed(msg: String):
	if SoundManager: SoundManager.play_craft()
	if GameManager:
		GameManager.add_log("Budowanie", msg)
		GameManager.consume_hotbar_item(GameManager.active_hotbar_slot)
	_update_ghost_building_preview()

func place_furniture_structure(item_dict: Dictionary, pos: Vector3):
	var target_parent = get_structure_parent_container()
	var f_type = item_dict.get("furnitureType", "floor")
	var struct_node = StaticBody3D.new()
	struct_node.add_to_group("placed_structure")
	struct_node.set("building_type", f_type)

	var mesh_inst = MeshInstance3D.new()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("#475569")
	mat.roughness = 0.4
	mat.metallic = 0.8

	if f_type == "floor":
		var box = BoxMesh.new(); box.size = Vector3(2.0, 0.2, 2.0)
		mesh_inst.mesh = box
	elif f_type == "roof":
		var box = BoxMesh.new(); box.size = Vector3(2.0, 0.2, 2.0)
		mesh_inst.mesh = box
		pos.y += 3.0
	elif f_type == "stairs":
		var prism = PrismMesh.new(); prism.size = Vector3(2.0, 3.0, 2.0)
		mesh_inst.mesh = prism
	elif f_type == "bed":
		struct_node.set_script(load("res://scripts/BaseBed.gd"))
		var box = BoxMesh.new(); box.size = Vector3(1.2, 0.8, 2.2)
		mesh_inst.mesh = box
		mat.albedo_color = Color("#1e293b")
	elif f_type == "chair":
		struct_node.set_script(load("res://scripts/BaseChair.gd"))
		var box = BoxMesh.new(); box.size = Vector3(0.8, 1.0, 0.8)
		mesh_inst.mesh = box
		mat.albedo_color = Color("#0f172a")
	elif f_type == "decon_chamber":
		struct_node.set_script(load("res://scripts/DeconChamber.gd"))
		var box = BoxMesh.new(); box.size = Vector3(2.0, 3.0, 2.0)
		mesh_inst.mesh = box
		mat.albedo_color = Color("#00f3ff")
		mat.emission_enabled = true; mat.emission = Color("#00f3ff"); mat.emission_energy_multiplier = 0.5
	elif f_type == "distiller":
		struct_node.set_script(load("res://scripts/WaterDistiller.gd"))
		var box = BoxMesh.new(); box.size = Vector3(1.5, 2.0, 1.5)
		mesh_inst.mesh = box
		mat.albedo_color = Color("#38bdf8")
	elif f_type == "isotope":
		struct_node.set_script(load("res://scripts/IsotopeGenerator.gd"))
		var box = BoxMesh.new(); box.size = Vector3(2.2, 2.5, 2.2)
		mesh_inst.mesh = box
		mat.albedo_color = Color("#f59e0b")
		mat.emission_enabled = true; mat.emission = Color("#f59e0b"); mat.emission_energy_multiplier = 1.0
	elif f_type == "hydro_shelf":
		struct_node.set_script(load("res://scripts/HydroponicShelf.gd"))
		var box = BoxMesh.new(); box.size = Vector3(1.6, 2.4, 1.0)
		mesh_inst.mesh = box
		mat.albedo_color = Color("#10b981")
	elif f_type == "mirror":
		var mirror_scene = load("res://scenes/prefabs/Mirror.tscn")
		if mirror_scene:
			var mirror_inst = mirror_scene.instantiate()
			mirror_inst.global_position = pos
			target_parent.add_child(mirror_inst)
			_on_structure_placed("🪞 Mounted Craftsman Mirror (3D Paperdoll Preview)")
			return
	elif f_type == "painting":
		var scene = load("res://scenes/prefabs/Painting.tscn")
		if scene:
			var inst = scene.instantiate()
			inst.global_position = pos
			target_parent.add_child(inst)
			_on_structure_placed("🖼️ Hung Wall Painting (Toggle Art on [E])")
			return
	elif f_type == "wall_cabinet":
		var scene = load("res://scenes/prefabs/WallCabinet.tscn")
		if scene:
			var inst = scene.instantiate()
			inst.global_position = pos
			target_parent.add_child(inst)
			_on_structure_placed("🗄️ Mounted Hanging Wall Cabinet")
			return
	elif f_type == "military_crate":
		var scene = load("res://scenes/prefabs/MilitaryCrate.tscn")
		if scene:
			var inst = scene.instantiate()
			inst.global_position = pos
			target_parent.add_child(inst)
			_on_structure_placed("📦 Placed Military Storage Crate")
			return
	elif f_type == "wall_shelf":
		var scene = load("res://scenes/prefabs/WallShelf.tscn")
		if scene:
			var inst = scene.instantiate()
			inst.global_position = pos
			target_parent.add_child(inst)
			_on_structure_placed("📐 Mounted Hanging Wall Shelf")
			return
	elif f_type == "umbrella":
		var scene = load("res://scenes/prefabs/Umbrella.tscn")
		if scene:
			var inst = scene.instantiate()
			inst.global_position = pos
			target_parent.add_child(inst)
			_on_structure_placed("☂️ Placed Protective Canopy (Toggle on [E])")
			return
	elif f_type == "door":
		var scene = load("res://scenes/prefabs/Door.tscn")
		if scene:
			var inst = scene.instantiate()
			inst.global_position = pos
			target_parent.add_child(inst)
			_on_structure_placed("🚪 Mounted Steel Base Door (Open/Close [E])")
			return
	elif f_type == "window_glass":
		var scene = load("res://scenes/prefabs/WindowGlass.tscn")
		if scene:
			var inst = scene.instantiate()
			inst.global_position = pos
			target_parent.add_child(inst)
			_on_structure_placed("🪟 Installed Glass Window Pane")
			return
	elif f_type == "wall_doorway":
		var box = BoxMesh.new(); box.size = Vector3(2.0, 3.0, 0.2)
		mesh_inst.mesh = box
		mat.albedo_color = Color("#334155")
	elif f_type == "light_bulb":
		var scene = load("res://scenes/prefabs/LightBulb.tscn")
		if scene:
			var inst = scene.instantiate()
			inst.global_position = pos
			target_parent.add_child(inst)
			_on_structure_placed("💡 Mounted Base Lightbulb")
			return
	elif f_type == "chest":
		struct_node.set_script(load("res://scripts/BaseStorageChest.gd"))
		var box = BoxMesh.new(); box.size = Vector3(1.4, 1.2, 1.4)
		mesh_inst.mesh = box
		mat.albedo_color = Color("#d97706")
	elif f_type == "planter":
		struct_node.set_script(load("res://scripts/BasePlanter.gd"))
		var box = BoxMesh.new(); box.size = Vector3(1.6, 0.8, 1.2)
		mesh_inst.mesh = box
		mat.albedo_color = Color("#78350f")
	elif f_type == "radio":
		struct_node.set_script(load("res://scripts/BaseRadio.gd"))
		var box = BoxMesh.new(); box.size = Vector3(0.8, 0.6, 0.5)
		mesh_inst.mesh = box
		mat.albedo_color = Color("#475569")
	elif f_type == "table":
		var box = BoxMesh.new(); box.size = Vector3(2.2, 1.0, 1.4)
		mesh_inst.mesh = box
		mat.albedo_color = Color("#92400e")
	elif f_type == "wardrobe":
		var box = BoxMesh.new(); box.size = Vector3(1.6, 2.8, 1.0)
		mesh_inst.mesh = box
		mat.albedo_color = Color("#1e293b")
	elif f_type == "tv":
		var box = BoxMesh.new(); box.size = Vector3(1.4, 1.0, 0.6)
		mesh_inst.mesh = box
		mat.albedo_color = Color("#0284c7")
		mat.emission_enabled = true; mat.emission = Color("#0284c7"); mat.emission_energy_multiplier = 1.0
	elif f_type == "boar_hide":
		var box = BoxMesh.new(); box.size = Vector3(2.4, 0.05, 1.8)
		mesh_inst.mesh = box
		mat.albedo_color = Color("#713f12")
	elif f_type == "wall_window":
		var box = BoxMesh.new(); box.size = Vector3(2.0, 3.0, 0.2)
		mesh_inst.mesh = box
		mat.albedo_color = Color("#38bdf8")
		mat.roughness = 0.1
	elif f_type in ["portal_station", "portal_mobile", "portal_clone_factory", "portal_bazar"]:
		var portal_scene = load("res://scenes/prefabs/CustomPortal.tscn")
		if portal_scene:
			var p_inst = portal_scene.instantiate()
			p_inst.global_position = pos
			p_inst.is_mobile = (f_type == "portal_mobile")
			if f_type == "portal_clone_factory":
				p_inst.target_biome = "clone_factory"
				p_inst.portal_name = "Portal Misji: Fabryka Klonów"
			elif f_type == "portal_bazar":
				p_inst.target_biome = "bazar"
				p_inst.portal_name = "Portal Handlowy: Baser"
			target_parent.add_child(p_inst)
			_on_structure_placed("🌀 Mounted Advanced Portal: " + p_inst.portal_name)
			return

	mesh_inst.material_override = mat
	struct_node.add_child(mesh_inst)

	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = mesh_inst.mesh.get("size") if mesh_inst.mesh.get("size") else Vector3(1.5, 1.5, 1.5)
	col.shape = box_shape
	struct_node.add_child(col)

	struct_node.global_position = pos
	target_parent.add_child(struct_node)

	_on_structure_placed("🏗️ Placed structure: " + item_dict.get("name", ""))

func handle_interaction():
	if not raycast or not raycast.is_colliding(): return
	var col = raycast.get_collider()
	if col:
		var target_node = col
		if not target_node.has_method("interact") and col.get_parent() and col.get_parent().has_method("interact"):
			target_node = col.get_parent()
			
		if target_node.has_method("interact"):
			target_node.interact()
