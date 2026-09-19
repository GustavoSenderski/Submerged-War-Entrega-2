extends Node3D

# Cena e quantidade
@export var enemy_submarine_scene: PackedScene
@export var patrol_submarine_count: int = 10

# Limites do mapa
@export var spawn_limit_x: float = 320.0
@export var spawn_limit_z: float = 320.0

# Profundidade
@export var minimum_depth: float = -7.0
@export var maximum_depth: float = -3.0

# Distâncias de segurança
@export var minimum_distance_from_player: float = 70.0
@export var minimum_distance_from_objective: float = 50.0
@export var minimum_distance_between_submarines: float = 25.0
@export var guard_distance_from_objective: float = 35.0
@export var coast_spawn_margin: float = 10.0

# Layer 2 = continente
@export_flags_3d_physics var terrain_collision_mask: int = 2
@export var terrain_check_height: float = 50.0
@export var terrain_check_depth: float = -50.0

var player: Node3D = null
var objective: Node3D = null
var occupied_positions: Array[Vector3] = []

const INVALID_SPAWN := Vector3(
	999999.0,
	999999.0,
	999999.0
)


func _ready() -> void:
	# Aguarda o MissionSetup posicionar os objetos.
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	player = get_tree().get_first_node_in_group("player") as Node3D
	objective = get_tree().get_first_node_in_group(
		"mission_objective"
	) as Node3D

	if enemy_submarine_scene == null:
		push_warning(
			"EnemySubmarineSpawner: cena não configurada."
		)
		return

	if player == null:
		push_warning(
			"EnemySubmarineSpawner: player não encontrado."
		)
		return

	occupied_positions.clear()

	spawn_patrol_submarines()
	spawn_guard_submarine()


# Cria os submarinos que patrulham o mapa.
func spawn_patrol_submarines() -> void:
	var created: int = 0

	for _i in range(patrol_submarine_count):
		var spawn_position: Vector3 = find_patrol_position()

		if spawn_position == INVALID_SPAWN:
			push_warning(
				"EnemySubmarineSpawner: patrulheiro não pôde ser criado."
			)
			continue

		var enemy := create_submarine(spawn_position)

		if enemy == null:
			continue

		enemy.set("behavior", 0)
		enemy.set("test_spawn_near_player", false)

		occupied_positions.append(spawn_position)
		created += 1

	print(
		"Submarinos patrulheiros criados: ",
		created
	)


# Cria um submarino próximo do objetivo.
func spawn_guard_submarine() -> void:
	if objective == null:
		push_warning(
			"EnemySubmarineSpawner: objetivo não encontrado."
		)
		return

	var spawn_position: Vector3 = find_guard_position()

	if spawn_position == INVALID_SPAWN:
		push_warning(
			"EnemySubmarineSpawner: guardião não pôde ser criado."
		)
		return

	var enemy := create_submarine(spawn_position)

	if enemy == null:
		return

	enemy.set("behavior", 1)
	enemy.set("test_spawn_near_player", false)

	occupied_positions.append(spawn_position)

	print(
		"SUBMARINO GUARDIÃO CRIADO: ",
		spawn_position
	)


func create_submarine(
	spawn_position: Vector3
) -> Node3D:
	var enemy := enemy_submarine_scene.instantiate() as Node3D

	if enemy == null:
		return null

	get_tree().current_scene.add_child(enemy)
	enemy.global_position = spawn_position

	return enemy


# Procura uma posição segura para um patrulheiro.
func find_patrol_position() -> Vector3:
	var max_attempts: int = 500

	for _attempt in range(max_attempts):
		var spawn_position := Vector3(
			randf_range(-spawn_limit_x, spawn_limit_x),
			randf_range(minimum_depth, maximum_depth),
			randf_range(-spawn_limit_z, spawn_limit_z)
		)

		if is_position_near_land(spawn_position):
			continue

		if not is_far_enough_from_player(spawn_position):
			continue

		if not is_far_enough_from_objective(spawn_position):
			continue

		if not is_far_enough_from_submarines(spawn_position):
			continue

		return spawn_position

	return INVALID_SPAWN


# Procura uma posição segura próxima do objetivo.
func find_guard_position() -> Vector3:
	if objective == null:
		return INVALID_SPAWN

	var max_attempts: int = 100

	for _attempt in range(max_attempts):
		var angle: float = randf_range(0.0, TAU)

		var guard_distance: float = randf_range(
			guard_distance_from_objective,
			guard_distance_from_objective + 20.0
		)

		var offset := Vector3(
			cos(angle) * guard_distance,
			0.0,
			sin(angle) * guard_distance
		)

		var spawn_position: Vector3 = (
			objective.global_position
			+ offset
		)

		spawn_position.y = randf_range(
			minimum_depth,
			maximum_depth
		)

		if is_position_near_land(spawn_position):
			continue

		if not is_far_enough_from_player(spawn_position):
			continue

		if not is_far_enough_from_submarines(spawn_position):
			continue

		return spawn_position

	return INVALID_SPAWN


# Verifica o ponto e uma margem ao redor da costa.
func is_position_near_land(
	world_position: Vector3
) -> bool:
	if is_position_on_land(world_position):
		return true

	var directions: Array[Vector3] = [
		Vector3(1.0, 0.0, 0.0),
		Vector3(-1.0, 0.0, 0.0),
		Vector3(0.0, 0.0, 1.0),
		Vector3(0.0, 0.0, -1.0),
		Vector3(1.0, 0.0, 1.0).normalized(),
		Vector3(-1.0, 0.0, 1.0).normalized(),
		Vector3(1.0, 0.0, -1.0).normalized(),
		Vector3(-1.0, 0.0, -1.0).normalized()
	]

	for direction in directions:
		var check_position: Vector3 = (
			world_position
			+ direction * coast_spawn_margin
		)

		if is_position_on_land(check_position):
			return true

	return false


# Usa um raycast vertical para verificar o continente.
func is_position_on_land(
	world_position: Vector3
) -> bool:
	var space_state: PhysicsDirectSpaceState3D = (
		get_world_3d().direct_space_state
	)

	var ray_start := Vector3(
		world_position.x,
		terrain_check_height,
		world_position.z
	)

	var ray_end := Vector3(
		world_position.x,
		terrain_check_depth,
		world_position.z
	)

	var query := PhysicsRayQueryParameters3D.create(
		ray_start,
		ray_end
	)

	query.collision_mask = terrain_collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result: Dictionary = space_state.intersect_ray(query)

	return not result.is_empty()


func is_far_enough_from_player(
	spawn_position: Vector3
) -> bool:
	if player == null:
		return true

	var distance_to_player: float = horizontal_distance(
		spawn_position,
		player.global_position
	)

	return distance_to_player >= minimum_distance_from_player


func is_far_enough_from_objective(
	spawn_position: Vector3
) -> bool:
	if objective == null:
		return true

	var distance_to_objective: float = horizontal_distance(
		spawn_position,
		objective.global_position
	)

	return distance_to_objective >= minimum_distance_from_objective


func is_far_enough_from_submarines(
	spawn_position: Vector3
) -> bool:
	for existing_position in occupied_positions:
		var distance_to_submarine: float = horizontal_distance(
			spawn_position,
			existing_position
		)

		if distance_to_submarine < minimum_distance_between_submarines:
			return false

	return true


# Calcula a distância sem considerar a profundidade.
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
