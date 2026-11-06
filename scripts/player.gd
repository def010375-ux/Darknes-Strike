extends CharacterBody3D

signal died

const WALK_SPEED := 5.4
const SPRINT_SPEED := 7.6
const JUMP_VELOCITY := 4.6
const LOOK_SENSITIVITY := 0.0022
const MAGAZINE_SIZE := 30

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var look_pitch := 0.0
var move_touch_id := -1
var look_touch_id := -1
var move_origin := Vector2.ZERO
var move_vector := Vector2.ZERO
var jump_requested := false
var sprint_requested := false
var health := 100
var ammo := MAGAZINE_SIZE
var reserve_ammo := 120
var fire_cooldown := 0.0
var is_reloading := false
var is_dead := false
var hud_layer: CanvasLayer
var status_label: Label
var health_label: Label
var ammo_label: Label
var camera: Camera3D

func _ready() -> void:
	_make_collision()
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.62, 0)
	camera.current = true
	camera.fov = 82.0
	add_child(camera)
	_create_hud()
	_update_hud()
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _make_collision() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)

func _process(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif jump_requested:
		velocity.y = JUMP_VELOCITY
	jump_requested = false

	var keyboard := Vector2.ZERO
	keyboard.x = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	keyboard.y = float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	var input_vector := move_vector if move_vector.length() > 0.08 else keyboard
	input_vector = input_vector.limit_length(1.0)
	var direction := (global_transform.basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()
	var speed := SPRINT_SPEED if sprint_requested or Input.is_key_pressed(KEY_SHIFT) else WALK_SPEED
	if direction.length() > 0.01:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 8.0 * delta)
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_view(event.relative)
	elif event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < get_viewport().get_visible_rect().size.x * 0.45 and move_touch_id == -1:
				move_touch_id = event.index
				move_origin = event.position
				move_vector = Vector2.ZERO
			elif look_touch_id == -1:
				look_touch_id = event.index
		else:
			if event.index == move_touch_id:
				move_touch_id = -1
				move_vector = Vector2.ZERO
			if event.index == look_touch_id:
				look_touch_id = -1
	elif event is InputEventScreenDrag:
		if event.index == move_touch_id:
			move_vector = ((event.position - move_origin) / 82.0).limit_length(1.0)
		elif event.index == look_touch_id:
			_rotate_view(event.relative)

func _rotate_view(relative: Vector2) -> void:
	rotate_y(-relative.x * LOOK_SENSITIVITY)
	look_pitch = clampf(look_pitch - relative.y * LOOK_SENSITIVITY, deg_to_rad(-80), deg_to_rad(80))
	camera.rotation.x = look_pitch

func _create_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(root)

	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(18, 16)
	top_panel.custom_minimum_size = Vector2(260, 74)
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.015, 0.02, 0.03, 0.72)
	top_style.border_color = Color(0.78, 0.52, 0.16, 0.8)
	top_style.set_border_width_all(1)
	top_style.set_corner_radius_all(8)
	top_panel.add_theme_stylebox_override("panel", top_style)
	root.add_child(top_panel)

	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 3)
	top_panel.add_child(stats)
	health_label = Label.new()
	health_label.add_theme_font_size_override("font_size", 18)
	health_label.add_theme_color_override("font_color", Color(0.96, 0.88, 0.72))
	stats.add_child(health_label)
	ammo_label = Label.new()
	ammo_label.add_theme_font_size_override("font_size", 16)
	ammo_label.add_theme_color_override("font_color", Color(0.91, 0.66, 0.28))
	stats.add_child(ammo_label)

	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 32)
	crosshair.add_theme_color_override("font_color", Color(1.0, 0.82, 0.48))
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-8, -22)
	root.add_child(crosshair)

	status_label = Label.new()
	status_label.text = "DSm  |  ELIMINATE ALL TARGETS"
	status_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	status_label.position = Vector2(0, 18)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color(0.94, 0.67, 0.25))
	root.add_child(status_label)

	var hint := Label.new()
	hint.text = "СЛЕВА — ДВИЖЕНИЕ  •  СПРАВА — ОБЗОР"
	hint.position = Vector2(18, 100)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.75, 0.77, 0.80))
	root.add_child(hint)

	var jump_button := _make_button(root, "JUMP", Vector2(-112, -178), Vector2(92, 64))
	jump_button.button_down.connect(func(): jump_requested = true)
	var fire_button := _make_button(root, "FIRE", Vector2(-112, -98), Vector2(92, 64))
	fire_button.button_down.connect(_shoot)
	var sprint_button := _make_button(root, "RUN", Vector2(-220, -98), Vector2(92, 54))
	sprint_button.button_down.connect(func(): sprint_requested = true)
	sprint_button.button_up.connect(func(): sprint_requested = false)
	var reload_button := _make_button(root, "RELOAD", Vector2(-220, -166), Vector2(92, 54))
	reload_button.pressed.connect(_reload)

func _make_button(parent: Control, caption: String, offset: Vector2, button_size: Vector2) -> Button:
	var button := Button.new()
	button.text = caption
	button.size = button_size
	button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button.position = offset
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.075, 0.085, 0.10, 0.88)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.55, 0.34, 0.10, 0.96)))
	parent.add_child(button)
	return button

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.set_border_width_all(1)
	style.border_color = Color(0.92, 0.61, 0.20, 0.9)
	return style

func _shoot() -> void:
	if is_dead or is_reloading or fire_cooldown > 0.0:
		return
	if ammo <= 0:
		status_label.text = "НЕТ ПАТРОНОВ — ПЕРЕЗАРЯДИ"
		return
	ammo -= 1
	fire_cooldown = 0.16
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_transform.basis.z * 100.0)
	query.exclude = [self]
	var hit := space.intersect_ray(query)
	if not hit.is_empty():
		var target = hit.collider
		if target.has_method("take_damage"):
			target.take_damage(34)
			status_label.text = "ПОПАДАНИЕ"
		else:
			status_label.text = "ПОПАДАНИЕ В УКРЫТИЕ"
	else:
		status_label.text = "ВЫСТРЕЛ"
	_update_hud()

func _reload() -> void:
	if is_reloading or ammo == MAGAZINE_SIZE or reserve_ammo <= 0 or is_dead:
		return
	is_reloading = true
	status_label.text = "ПЕРЕЗАРЯДКА..."
	await get_tree().create_timer(1.35).timeout
	if is_dead:
		return
	var needed := MAGAZINE_SIZE - ammo
	var loaded := mini(needed, reserve_ammo)
	ammo += loaded
	reserve_ammo -= loaded
	is_reloading = false
	status_label.text = "ГОТОВО"
	_update_hud()

func take_damage(amount: int) -> void:
	if is_dead:
		return
	health = maxi(0, health - amount)
	_update_hud()
	if health <= 0:
		is_dead = true
		status_label.text = "ТЫ УСТРАНЁН"
		died.emit()

func _update_hud() -> void:
	if is_instance_valid(health_label):
		health_label.text = "ЗДОРОВЬЕ  %d" % health
	if is_instance_valid(ammo_label):
		ammo_label.text = "ПАТРОНЫ  %02d / %03d" % [ammo, reserve_ammo]
