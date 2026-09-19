extends Node3D

# Movimento
@export var speed: float = 12.0
@export var turn_speed: float = 2.5
@export var lifetime: float = 8.0

# Dano
@export var damage: int = 2
@export var hit_distance: float = 2.0

var direction: Vector3 = Vector3.RIGHT
var target: Node3D = null
var life_timer: float = 0.0


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("enemy_torpedo")

	life_timer = lifetime


# Permite que o torpedo seja destruído pelo jogador.
func take_damage(_damage: int) -> void:
	print("TORPEDO INIMIGO DESTRUÍDO!")
	queue_free()


# Recebe a direção inicial e o jogador como alvo.
func initialize(
	initial_direction: Vector3,
	target_node: Node3D
) -> void:
	direction = initial_direction.normalized()
	target = target_node

	update_rotation()


func _physics_process(delta: float) -> void:
	life_timer -= delta

	if life_timer <= 0.0:
		queue_free()
		return

	if target != null and is_instance_valid(target):
		update_direction_to_target(delta)
	elif target != null:
		target = null

	global_position += direction * speed * delta

	update_rotation()
	check_hit()


# Ajusta gradualmente a direção para seguir o jogador.
func update_direction_to_target(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return

	var target_direction: Vector3 = (
		target.global_position
		- global_position
	)

	if target_direction.length() <= 0.01:
		return

	target_direction = target_direction.normalized()

	direction = direction.slerp(
		target_direction,
		min(turn_speed * delta, 1.0)
	)

	if direction.length() > 0.01:
		direction = direction.normalized()


# Mantém o modelo apontado para a direção do movimento.
func update_rotation() -> void:
	if direction.length() <= 0.01:
		return

	# O modelo aponta para +X.
	var target_yaw: float = atan2(
		-direction.z,
		direction.x
	)

	rotation.y = target_yaw


# Verifica se o torpedo atingiu o jogador.
func check_hit() -> void:
	if target == null or not is_instance_valid(target):
		return

	var distance_to_target: float = global_position.distance_to(
		target.global_position
	)

	if distance_to_target > hit_distance:
		return

	if target.has_method("take_damage"):
		target.call("take_damage", damage)

	print("TORPEDO DO SUBMARINO INIMIGO ACERTOU!")

	queue_free()
