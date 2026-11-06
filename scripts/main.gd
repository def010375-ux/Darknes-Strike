extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const BOT_SCRIPT = preload("res://scripts/bot.gd")

var menu_layer: CanvasLayer
var player: CharacterBody3D
var alive_bots := 0
var selected_quality := "BALANCED"

func _ready() -> void:
	_apply_quality()
	_build_world()
	_show_main_menu()

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.018, 0.024, 0.038)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.59, 0.68)
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = environment
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

	_add_box("ArenaFloor", Vector3(0, -0.3, 0), Vector3(64, 0.6, 64), Color(0.105, 0.12, 0.14))
	_add_box("NorthWall", Vector3(0, 2.2, -32), Vector3(64, 4.4, 0.6), Color(0.19, 0.20, 0.22))
	_add_box("SouthWall", Vector3(0, 2.2, 32), Vector3(64, 4.4, 0.6), Color(0.19, 0.20, 0.22))
	_add_box("WestWall", Vector3(-32, 2.2, 0), Vector3(0.6, 4.4, 64), Color(0.17, 0.19, 0.21))
	_add_box("EastWall", Vector3(32, 2.2, 0), Vector3(0.6, 4.4, 64), Color(0.17, 0.19, 0.21))

	var cover_data := [
		[Vector3(-9, 0.8, -8), Vector3(5, 1.6, 2.0)],
		[Vector3(8, 0.7, -10), Vector3(3.2, 1.4, 3.2)],
		[Vector3(-12, 1.0, 5), Vector3(2.2, 2.0, 5.0)],
		[Vector3(10, 0.9, 7), Vector3(5.0, 1.8, 2.0)],
		[Vector3(0, 0.65, -17), Vector3(3.0, 1.3, 3.0)],
		[Vector3(-2, 1.1, 15), Vector3(7.0, 2.2, 2.0)],
		[Vector3(19, 0.8, -1), Vector3(2.0, 1.6, 7.0)],
		[Vector3(-20, 0.8, -14), Vector3(6.0, 1.6, 2.0)],
		[Vector3(19, 0.8, 18), Vector3(5.0, 1.6, 2.0)],
		[Vector3(-19, 0.8, 20), Vector3(2.0, 1.6, 6.0)]
	]
	for i in range(cover_data.size()):
		var item: Array = cover_data[i]
		var tint := Color(0.28, 0.25, 0.20) if i % 2 == 0 else Color(0.22, 0.25, 0.27)
		_add_box("Cover_%02d" % i, item[0], item[1], tint)

func _add_box(node_name: String, at: Vector3, dimensions: Vector3, tint: Color) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = at
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.88
	material.metallic = 0.08
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _show_main_menu() -> void:
	_create_menu("DARKNES STRIKE", "MOBILE TACTICAL FPS", [
		{"text": "НАЧАТЬ МАТЧ", "action": _start_match},
		{"text": "НАСТРОЙКИ ГРАФИКИ", "action": _show_settings},
		{"text": "ВЫХОД", "action": _exit_game}
	])

func _show_settings() -> void:
	_create_menu("НАСТРОЙКИ", "КАЧЕСТВО И ПРОИЗВОДИТЕЛЬНОСТЬ", [
		{"text": "ЭКОНОМИЧНЫЙ РЕЖИМ", "action": func(): _set_quality("LOW")},
		{"text": "СБАЛАНСИРОВАННЫЙ", "action": func(): _set_quality("BALANCED")},
		{"text": "ВЫСОКОЕ КАЧЕСТВО", "action": func(): _set_quality("HIGH")},
		{"text": "НАЗАД", "action": _show_main_menu}
	])

func _create_menu(title_text: String, subtitle_text: String, entries: Array) -> void:
	if is_instance_valid(menu_layer):
		menu_layer.queue_free()
	menu_layer = CanvasLayer.new()
	add_child(menu_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(root)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.012, 0.016, 0.025, 0.97)
	root.add_child(backdrop)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-260, -285)
	panel.size = Vector2(520, 570)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.041, 0.052, 0.98)
	panel_style.border_color = Color(0.82, 0.59, 0.20, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(18)
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 28
	panel_style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", panel_style)
	root.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 15)
	panel.add_child(column)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.94, 0.68, 0.25))
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = subtitle_text
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.72, 0.73, 0.76))
	column.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 12
	column.add_child(spacer)

	for entry in entries:
		var button := Button.new()
		button.text = entry.text
		button.custom_minimum_size = Vector2(0, 64)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_color_override("font_color", Color(0.97, 0.95, 0.91))
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.10, 0.11, 0.13)
		normal.border_color = Color(0.62, 0.43, 0.16)
		normal.set_border_width_all(1)
		normal.set_corner_radius_all(10)
		var pressed := normal.duplicate()
		pressed.bg_color = Color(0.48, 0.31, 0.10)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", pressed)
		button.add_theme_stylebox_override("pressed", pressed)
		button.pressed.connect(entry.action)
		column.add_child(button)

	var footer := Label.new()
	footer.text = "DSm  •  ANDROID OPTIMIZED"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color(0.58, 0.53, 0.43))
	column.add_child(footer)

func _set_quality(level: String) -> void:
	selected_quality = level
	_apply_quality()
	_show_settings()

func _apply_quality() -> void:
	match selected_quality:
		"LOW":
			get_viewport().scaling_3d_scale = 0.72
			get_viewport().msaa_3d = Viewport.MSAA_DISABLED
		"HIGH":
			get_viewport().scaling_3d_scale = 1.0
			get_viewport().msaa_3d = Viewport.MSAA_2X
		_:
			get_viewport().scaling_3d_scale = 0.85
			get_viewport().msaa_3d = Viewport.MSAA_DISABLED

func _start_match() -> void:
	if is_instance_valid(menu_layer):
		menu_layer.queue_free()
	player = CharacterBody3D.new()
	player.set_script(PLAYER_SCRIPT)
	player.name = "Player"
	player.position = Vector3(0, 0.1, 23)
	add_child(player)
	player.died.connect(_on_player_died)

	var spawn_points := [
		Vector3(-20, 0.1, -20), Vector3(0, 0.1, -24),
		Vector3(20, 0.1, -18), Vector3(-21, 0.1, 5),
		Vector3(20, 0.1, 12), Vector3(0, 0.1, -4)
	]
	alive_bots = spawn_points.size()
	for i in range(spawn_points.size()):
		var bot := CharacterBody3D.new()
		bot.set_script(BOT_SCRIPT)
		bot.name = "StrikeBot_%02d" % (i + 1)
		bot.position = spawn_points[i]
		bot.target = player
		bot.died.connect(_on_bot_died)
		add_child(bot)

func _on_bot_died() -> void:
	alive_bots = maxi(0, alive_bots - 1)
	if alive_bots == 0:
		_show_result(true)

func _on_player_died() -> void:
	_show_result(false)

func _show_result(won: bool) -> void:
	if is_instance_valid(player):
		player.set_physics_process(false)
		player.set_process(false)
	var heading := "ПОБЕДА" if won else "ПОРАЖЕНИЕ"
	var detail := "ВСЕ ПРОТИВНИКИ УСТРАНЕНЫ" if won else "ТЫ БЫЛ УСТРАНЁН"
	_create_menu(heading, detail, [
		{"text": "В ГЛАВНОЕ МЕНЮ", "action": _return_to_menu}
	])

func _return_to_menu() -> void:
	get_tree().reload_current_scene()

func _exit_game() -> void:
	get_tree().quit()
