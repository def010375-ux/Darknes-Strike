extends CharacterBody3D

const WALK_SPEED := 5.2
const SPRINT_SPEED := 7.2
const JUMP_VELOCITY := 4.5
const LOOK_SENSITIVITY := 0.0025

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var look_pitch := 0.0
var move_touch_id := -1
var look_touch_id := -1
var move_origin := Vector2.ZERO
var move_vector := Vector2.ZERO
var jump_requested := false
var sprint_requested := false
var hud_layer: CanvasLayer
var status_label: Label
var camera: Camera3D

func _ready() -> void:
	_make_collision()
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.58, 0)
	camera.current = true
	camera.fov = 82.0
	add_child(camera)
	_create_hud()
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

func _physics_process(delta: float) -> void:
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
		velocity.x = move_toward(velocity.x, 0.0, speed * 7.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 7.0 * delta)
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_view(event.relative)
	elif event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < get_viewport().get_visible_rect().size.x * 0.48 and move_touch_id == -1:
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
			move_vector = (event.position - move_origin) / 72.0
			move_vector = move_vector.limit_length(1.0)
		elif event.index == look_touch_id:
			_rotate_view(event.relative)

func _rotate_view(relative: Vector2) -> void:
	rotate_y(-relative.x * LOOK_SENSITIVITY)
	look_pitch = clampf(look_pitch - relative.y * LOOK_SENSITIVITY, deg_to_rad(-82), deg_to_rad(82))
	camera.rotation.x = look_pitch

func _create_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(root)

	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 30)
	crosshair.add_theme_color_override("font_color", Color(1.0, 0.82, 0.48))
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-8, -20)
	root.add_child(crosshair)

	status_label = Label.new()
	status_label.text = "DARKNES STRIKE  |  TRAINING"
	status_label.position = Vector2(18, 16)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color(1.0, 0.58, 0.2))
	root.add_child(status_label)

	var hint := Label.new()
	hint.text = "WASD + мышь  |  Телефон: слева движение, справа обзор"
	hint.position = Vector2(18, 44)
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.88, 0.9, 0.92))
	root.add_child(hint)

	var jump_button := _make_button(root, "JUMP", Vector2(-112, -178), Vector2(92, 64))
	jump_button.button_down.connect(func(): jump_requested = true)
	var fire_button := _make_button(root, "FIRE", Vector2(-112, -98), Vector2(92, 64))
	fire_button.pressed.connect(_shoot)
	var sprint_button := _make_button(root, "RUN", Vector2(-220, -98), Vector2(92, 54))
	sprint_button.button_down.connect(func(): sprint_requested = true)
	sprint_button.button_up.connect(func(): sprint_requested = false)

func _make_button(parent: Control, caption: String, offset: Vector2, button_size: Vector2) -> Button:
	var button := Button.new()
	button.text = caption
	button.size = button_size
	button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button.position = offset
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.12, 0.14, 0.17, 0.82)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.95, 0.39, 0.08, 0.95)))
	parent.add_child(button)
	return button

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(1.0, 0.58, 0.2, 0.9)
	return style

func _shoot() -> void:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_transform.basis.z * 100.0)
	query.exclude = [self]
	var hit := space.intersect_ray(query)
	if not hit.is_empty():
		status_label.text = "HIT: " + str(hit.collider.name)
	else:
		status_label.text = "DARKNES STRIKE  |  SHOT FIRED"
