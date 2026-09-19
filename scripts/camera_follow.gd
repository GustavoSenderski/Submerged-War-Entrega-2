extends Camera3D

# Configurações
@export var target: Node3D
@export var distance: float = 10.0
@export var height: float = 3.5
@export var look_ahead: float = 4.0
@export var follow_speed: float = 3.0
@export var snap_distance: float = 30.0


func _ready() -> void:
	if target == null:
		target = get_tree().get_first_node_in_group("player") as Node3D

	if target == null:
		push_warning("Camera: submarino não encontrado.")
		return

	# Aguarda o MissionSetup posicionar o jogador.
	call_deferred("snap_to_target")


func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return

	var desired_position: Vector3 = get_desired_position()

	var camera_distance: float = global_position.distance_to(
		desired_position
	)

	# Evita a câmera atravessar o mapa após um teleporte.
	if camera_distance > snap_distance:
		global_position = desired_position
	else:
		global_position = global_position.lerp(
			desired_position,
			min(follow_speed * delta, 1.0)
		)

	update_camera_rotation()


# Posiciona a câmera imediatamente no início.
func snap_to_target() -> void:
	await get_tree().process_frame

	if target == null or not is_instance_valid(target):
		return

	global_position = get_desired_position()
	update_camera_rotation()


# Mantém a câmera olhando à frente do submarino.
func update_camera_rotation() -> void:
	if target == null or not is_instance_valid(target):
		return

	var forward: Vector3 = (
		target.global_transform.basis.x
	)

	forward.y = 0.0

	if forward.length() <= 0.01:
		return

	forward = forward.normalized()

	var look_position: Vector3 = (
		target.global_position
		+ forward * look_ahead
	)

	look_at(
		look_position,
		Vector3.UP
	)


# Calcula a posição atrás e acima do submarino.
func get_desired_position() -> Vector3:
	var forward: Vector3 = (
		target.global_transform.basis.x
	)

	forward.y = 0.0

	if forward.length() <= 0.01:
		forward = Vector3.RIGHT
	else:
		forward = forward.normalized()

	return (
		target.global_position
		- forward * distance
		+ Vector3(0.0, height, 0.0)
	)
