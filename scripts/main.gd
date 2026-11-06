extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")

func _ready() -> void:
	_build_world()
	var player := CharacterBody3D.new()
	player.set_script(PLAYER_SCRIPT)
	player.name = "Player"
	player.position = Vector3(0.0, 0.05, 5.0)
	add_child(player)

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.48, 0.52, 0.58)
	environment.ambient_light_energy = 0.7
	world_env.environment = environment
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	sun.light_energy = 1.15
	add_child(sun)

	_add_box("Ground", Vector3(0, -0.25, 0), Vector3(32, 0.5, 32), Color(0.24, 0.27, 0.29))
	_add_box("NorthWall", Vector3(0, 2, -16), Vector3(32, 4, 0.5), Color(0.34, 0.32, 0.28))
	_add_box("SouthWall", Vector3(0, 2, 16), Vector3(32, 4, 0.5), Color(0.34, 0.32, 0.28))
	_add_box("WestWall", Vector3(-16, 2, 0), Vector3(0.5, 4, 32), Color(0.31, 0.33, 0.34))
	_add_box("EastWall", Vector3(16, 2, 0), Vector3(0.5, 4, 32), Color(0.31, 0.33, 0.34))
	_add_box("CoverA", Vector3(-4, 0.8, -3), Vector3(3, 1.6, 1.2), Color(0.42, 0.32, 0.22))
	_add_box("CoverB", Vector3(4, 0.65, 2), Vector3(2.2, 1.3, 2.2), Color(0.38, 0.39, 0.36))
	_add_box("CenterCrate", Vector3(0, 0.6, -7), Vector3(2, 1.2, 2), Color(0.42, 0.34, 0.24))

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
	material.roughness = 0.92
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
