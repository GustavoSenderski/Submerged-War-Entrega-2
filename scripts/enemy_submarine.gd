extends CharacterBody3D

# Vida
@export var max_health: int = 6
var current_health: int = 6

# Comportamento
enum Behavior {
	PATROL,
	GUARD
}

@export var behavior: Behavior = Behavior.PATROL

# Opções para teste manual
@export var test_spawn_near_player: bool = false
@export var test_spawn_distance: float = 25.0

# Combate
@export var combat_distance: float = 22.0
@export var minimum_player_distance: float = 14.0
@export var detection_range: float = 120.0
@export var attack_range: float = 45.0

# Movimento
@export var patrol_speed: float = 3.0
@export var chase_speed: float = 5.0
@export var turn_speed: float = 1.5
@export var patrol_radius: float = 50.0
@export var minimum_depth: float = -7.0
@export var maximum_depth: float = -3.0

# Segurança da costa
@export var coast_safety_distance: float = 7.0
@export var coast_side_angle: float = 35.0
@export var coast_avoid_time: float = 2.0
var coast_avoid_timer: float = 0.0

# Guarda do objetivo
@export var guard_radius: float = 60.0
var guard_center: Vector3 = Vector3.ZERO

# Torpedo
@export var torpedo_scene: PackedScene
@export var fire_cooldown: float = 3.0
@onready var torpedo_spawn: Marker3D = $TorpedoSpawn
var fire_timer: float = 0.0

# Referências
var player: Node3D = null
var objective: Node3D = null
var patrol_target: Vector3 = Vector3.ZERO


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("enemy_submarine")
	add_to_group("objective_blocker")

	current_health = max_health

	# Colide somente com o continente.
	collision_layer = 0
	collision_mask = 2

	# Aguarda o MissionSetup definir as posições.
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	player = get_tree().get_first_node_in_group("player") as Node3D
	objective = get_tree().get_first_node_in_group(
		"mission_objective"
	) as Node3D

	if player == null:
		push_warning("EnemySubmarine: player não encontrado.")
		return

	if test_spawn_near_player:
		spawn_near_player()

	if behavior == Behavior.GUARD:
		if objective != null:
			guard_center = objective.global_position
		else:
			guard_center = global_position
	else:
		guard_center = global_position

	choose_patrol_target()


func _physics_process(delta: float) -> void:
	if player == null:
		return

	update_timers(delta)

	var distance_to_player: float = horizontal_distance(
		global_position,
		player.global_position
	)

	# Durante o desvio da costa continua patrulhando.
	if coast_avoid_timer > 0.0:
		patrol(delta)
		return

	if distance_to_player <= detection_range:
		chase_player(delta)
	else:
		patrol(delta)


func update_timers(delta: float) -> void:
	if fire_timer > 0.0:
		fire_timer = max(fire_timer - delta, 0.0)

	if coast_avoid_timer > 0.0:
		coast_avoid_timer = max(
			coast_avoid_timer - delta,
			0.0
		)


# Posiciona o inimigo perto do jogador para testes.
func spawn_near_player() -> void:
	var player_forward: Vector3 = player.global_transform.basis.x
	player_forward.y = 0.0

	if player_forward.length() > 0.01:
		player_forward = player_forward.normalized()

	global_position = (
		player.global_position
		+ player_forward * test_spawn_distance
	)

	global_position.y = clamp(
		player.global_position.y,
		minimum_depth,
		maximum_depth
	)

	look_at_player()


func patrol(delta: float) -> void:
	var distance_to_target: float = horizontal_distance(
		global_position,
		patrol_target
	)

	if distance_to_target < 8.0:
		choose_patrol_target()

	var direction: Vector3 = patrol_target - global_position
	direction.y = 0.0

	if direction.length() <= 0.01:
		choose_patrol_target()
		return

	direction = direction.normalized()

	# Evita se aproximar da costa.
	if coast_ahead(direction):
		velocity = Vector3.ZERO
		coast_avoid_timer = coast_avoid_time
		choose_patrol_target()
		return

	move_towards_position(
		patrol_target,
		patrol_speed,
		delta
	)


# Escolhe um ponto seguro de patrulha.
func choose_patrol_target() -> void:
	var radius: float = patrol_radius

	if behavior == Behavior.GUARD:
		radius = guard_radius

	var attempts: int = 0

	while attempts < 20:
		attempts += 1

		var new_target := Vector3(
			guard_center.x + randf_range(-radius, radius),
			randf_range(minimum_depth, maximum_depth),
			guard_center.z + randf_range(-radius, radius)
		)

		if position_is_over_land(new_target):
			continue

		var direction: Vector3 = new_target - global_position
		direction.y = 0.0

		if direction.length() <= 0.01:
			continue

		direction = direction.normalized()

		if coast_ahead(direction):
			continue

		patrol_target = new_target
		return

	# Se não encontrar ponto seguro, permanece no local.
	patrol_target = global_position


func chase_player(delta: float) -> void:
	if player == null:
		return

	var distance_to_player: float = horizontal_distance(
		global_position,
		player.global_position
	)

	# O guardião permanece próximo do objetivo.
	if (
		behavior == Behavior.GUARD
		and horizontal_distance(
			global_position,
			guard_center
		) > guard_radius * 1.5
	):
		return_to_guard(delta)
		return

	# Afasta quando está muito próximo do jogador.
	if distance_to_player < minimum_player_distance:
		retreat_from_player(delta)

	# Aproxima quando está longe da distância de combate.
	elif distance_to_player > combat_distance:
		approach_player(delta)

	# Mantém posição quando está na distância ideal.
	else:
		velocity = Vector3.ZERO
		look_at_player()

	if distance_to_player <= attack_range and fire_timer <= 0.0:
		fire_torpedo()
		fire_timer = fire_cooldown


# Faz o guardião retornar para perto do objetivo.
func return_to_guard(delta: float) -> void:
	var guard_direction: Vector3 = guard_center - global_position
	guard_direction.y = 0.0

	if guard_direction.length() > 0.01:
		guard_direction = guard_direction.normalized()

		if coast_ahead(guard_direction):
			velocity = Vector3.ZERO
			choose_patrol_target()
			return

	move_towards_position(
		guard_center,
		patrol_speed,
		delta
	)


# Afasta o submarino quando o jogador chega muito perto.
func retreat_from_player(delta: float) -> void:
	var away_direction: Vector3 = (
		global_position
		- player.global_position
	)

	away_direction.y = 0.0

	if away_direction.length() <= 0.01:
		return

	away_direction = away_direction.normalized()

	var retreat_position: Vector3 = (
		global_position
		+ away_direction * 10.0
	)

	retreat_position.y = global_position.y

	if (
		coast_ahead(away_direction)
		or position_is_over_land(retreat_position)
	):
		velocity = Vector3.ZERO
		choose_patrol_target()
		coast_avoid_timer = coast_avoid_time
		return

	move_towards_position(
		retreat_position,
		chase_speed,
		delta
	)


# Aproxima o inimigo do jogador.
func approach_player(delta: float) -> void:
	var chase_direction: Vector3 = (
		player.global_position
		- global_position
	)

	chase_direction.y = 0.0

	if chase_direction.length() <= 0.01:
		return

	chase_direction = chase_direction.normalized()

	if coast_ahead(chase_direction):
		velocity = Vector3.ZERO
		choose_patrol_target()
		coast_avoid_timer = coast_avoid_time
		return

	move_towards_position(
		player.global_position,
		chase_speed,
		delta
	)


# Move o inimigo em direção a uma posição.
func move_towards_position(
	target_position: Vector3,
	speed: float,
	delta: float
) -> void:
	var direction: Vector3 = target_position - global_position
	direction.y = 0.0

	if direction.length() <= 0.01:
		return

	direction = direction.normalized()

	var target_yaw: float = atan2(
		-direction.z,
		direction.x
	)

	rotation.y = lerp_angle(
		rotation.y,
		target_yaw,
		turn_speed * delta
	)

	var forward: Vector3 = global_transform.basis.x
	forward.y = 0.0

	if forward.length() > 0.01:
		forward = forward.normalized()

	velocity.x = forward.x * speed
	velocity.z = forward.z * speed

	var vertical_difference: float = (
		target_position.y
		- global_position.y
	)

	velocity.y = move_toward(
		velocity.y,
		vertical_difference,
		1.0 * delta
	)

	move_and_slide()

	global_position.y = clamp(
		global_position.y,
		minimum_depth,
		maximum_depth
	)


# Verifica a costa à frente e nas laterais.
func coast_ahead(direction: Vector3) -> bool:
	if direction.length() <= 0.01:
		return false

	var forward: Vector3 = direction.normalized()

	var left_direction: Vector3 = forward.rotated(
		Vector3.UP,
		deg_to_rad(-coast_side_angle)
	)

	var right_direction: Vector3 = forward.rotated(
		Vector3.UP,
		deg_to_rad(coast_side_angle)
	)

	if coast_ray_hit(forward):
		return true

	if coast_ray_hit(left_direction):
		return true

	if coast_ray_hit(right_direction):
		return true

	return false


func coast_ray_hit(direction: Vector3) -> bool:
	var space_state := get_world_3d().direct_space_state
	var ray_start: Vector3 = global_position

	var ray_end: Vector3 = (
		ray_start
		+ direction.normalized() * coast_safety_distance
	)

	var query := PhysicsRayQueryParameters3D.create(
		ray_start,
		ray_end
	)

	query.collision_mask = 2
	query.exclude = [get_rid()]

	var result: Dictionary = space_state.intersect_ray(query)

	return not result.is_empty()


# Verifica se uma posição está sobre o continente.
func position_is_over_land(world_position: Vector3) -> bool:
	var space_state := get_world_3d().direct_space_state

	var ray_start := Vector3(
		world_position.x,
		20.0,
		world_position.z
	)

	var ray_end := Vector3(
		world_position.x,
		-15.0,
		world_position.z
	)

	var query := PhysicsRayQueryParameters3D.create(
		ray_start,
		ray_end
	)

	query.collision_mask = 2
	query.exclude = [get_rid()]

	var result: Dictionary = space_state.intersect_ray(query)

	return not result.is_empty()


func look_at_player() -> void:
	if player == null:
		return

	var direction: Vector3 = (
		player.global_position
		- global_position
	)

	direction.y = 0.0

	if direction.length() <= 0.01:
		return

	var target_yaw: float = atan2(
		-direction.z,
		direction.x
	)

	rotation.y = target_yaw


func fire_torpedo() -> void:
	if torpedo_scene == null:
		print("EnemySubmarine: Torpedo Scene não configurada.")
		return

	var torpedo: Node3D = torpedo_scene.instantiate() as Node3D

	if torpedo == null:
		return

	get_tree().current_scene.add_child(torpedo)
	torpedo.global_transform = torpedo_spawn.global_transform

	var fire_direction: Vector3 = (
		torpedo_spawn.global_transform.basis.x.normalized()
	)

	if torpedo.has_method("initialize"):
		torpedo.call(
			"initialize",
			fire_direction,
			player
		)

	print("SUBMARINO INIMIGO DISPAROU!")


# Calcula a distância horizontal entre dois pontos.
func horizontal_distance(
	position_a: Vector3,
	position_b: Vector3
) -> float:
	var point_a := Vector2(
		position_a.x,
		position_a.z
	)

	var point_b := Vector2(
		position_b.x,
		position_b.z
	)

	return point_a.distance_to(point_b)


func take_damage(damage: int) -> void:
	if current_health <= 0:
		return

	current_health -= damage
	current_health = max(current_health, 0)

	print(
		"SUBMARINO INIMIGO RECEBEU DANO! Vida: ",
		current_health,
		"/",
		max_health
	)

	if current_health <= 0:
		destroy_enemy()


func destroy_enemy() -> void:
	print("SUBMARINO INIMIGO DESTRUÍDO!")
	queue_free()
