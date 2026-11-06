extends CharacterBody3D

signal died

const MOVE_SPEED := 3.0
const ATTACK_RANGE := 19.0
const ATTACK_INTERVAL := 1.25
const ATTACK_DAMAGE := 8

var target: Node3D
var health := 100
var attack_timer := 0.8
var is_dead := false
var body_mesh: MeshInstance3D
var health_tag: Label3D

func _ready() -> void:
	_make_body()
	add_to_group("enemies")

func _make_body() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.9
	collision.shape = capsule
	collision.position.y = 0.95
	add_child(collision)

	body_mesh = MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.4
	mesh.height = 1.85
	body_mesh.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.34, 0.12, 0.09)
	material.roughness = 0.78
	body_mesh.material_override = material
	body_mesh.position.y = 0.95
	add_child(body_mesh)

	var chest := MeshInstance3D.new()
	var chest_mesh := BoxMesh.new()
	chest_mesh.size = Vector3(0.68, 0.48, 0.30)
	chest.mesh = chest_mesh
	var chest_material := StandardMaterial3D.new()
	chest_material.albedo_color = Color(0.12, 0.14, 0.16)
	chest.material_override = chest_material
	chest.position = Vector3(0, 1.15, -0.02)
	add_child(chest)

	health_tag = Label3D.new()
	health_tag.text = "100"
	health_tag.position.y = 2.2
	health_tag.font_size = 32
	health_tag.modulate = Color(1.0, 0.76, 0.42)
	add_child(health_tag)

func _physics_process(delta: float) -> void:
	if is_dead or not is_instance_valid(target):
		return
	attack_timer = maxf(0.0, attack_timer - delta)
	var flat_target := Vector3(target.global_position.x, global_position.y, target.global_position.z)
	var distance := global_position.distance_to(flat_target)
	if distance > 6.5:
		var direction := global_position.direction_to(flat_target)
		velocity.x = direction.x * MOVE_SPEED
		velocity.z = direction.z * MOVE_SPEED
		if direction.length() > 0.05:
			look_at(flat_target, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, MOVE_SPEED * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, MOVE_SPEED * 5.0 * delta)
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if distance <= ATTACK_RANGE and attack_timer <= 0.0:
		_attack()
		attack_timer = ATTACK_INTERVAL

func _attack() -> void:
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return
	var origin := global_position + Vector3(0, 1.45, 0)
	var destination := target.global_position + Vector3(0, 1.3, 0)
	var query := PhysicsRayQueryParameters3D.create(origin, destination)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider == target:
		target.take_damage(ATTACK_DAMAGE)

func take_damage(amount: int) -> void:
	if is_dead:
		return
	health = maxi(0, health - amount)
	if is_instance_valid(health_tag):
		health_tag.text = str(health)
	if health <= 0:
		is_dead = true
		died.emit()
		queue_free()
