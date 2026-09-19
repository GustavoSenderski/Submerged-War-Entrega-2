extends Node3D

# Cenas dos inimigos
@export var enemy_ship_scene: PackedScene
@export var enemy_mine_scene: PackedScene

# Quantidades
@export var ship_count: int = 12
@export var mine_count: int = 8

# Limites do mapa
@export var spawn_limit_x: float = 320.0
@export var spawn_limit_z: float = 320.0

# Alturas
@export var ship_height: float = 4.2
@export var mine_min_height: float = -7.5
@export var mine_max_height: float = -2.5

# Distâncias de segurança
@export var minimum_distance_from_player: float = 70.0
@export var minimum_distance_between_enemies: float = 25.0
@export var minimum_distance_from_objective: float = 40.0
@export var coast_spawn_margin: float = 12.0

# Layer 2 = continente
@export_flags_3d_physics var terrain_collision_mask: int = 2
@export var terrain_check_height: float = 50.0
@export var terrain_check_depth: float = -50.0

@export var player: Node3D

var objective: Node3D = null
var occupied_positions: Array[Vector3] = []
var already_spawned: bool = false

const INVALID_SPAWN := Vector3(
	999999.0,
	999999.0,
	999999.0
)


func _ready() -> void:
	call_deferred("start_spawning")


func start_spawning() -> void:
	if already_spawned:
		return

	# Aguarda o posicionamento do jogador e objetivo.
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node3D

	if player == null:
		push_warning("EnemySpawner: Player não encontrado.")
		return

	objective = get_tree().get_first_node_in_group(
		"mission_objective"
	) as Node3D

	occupied_positions.clear()

	spawn_ships()
	spawn_mines()

	already_spawned = true

	print("==============================")
	print("SPAWN FINALIZADO")
	print("==============================")


# Cria os navios em posições seguras.
func spawn_ships() -> void:
	if enemy_ship_scene == null:
		push_warning("EnemySpawner: EnemyShip não configurado.")
		return

	var created: int = 0

	for _i in range(ship_count):
		var spawn_pos: Vector3 = get_valid_spawn_position(
			ship_height,
			ship_height
		)

		if spawn_pos == INVALID_SPAWN:
			push_warning(
				"EnemySpawner: navio não pôde ser criado."
			)
			continue

		var enemy: Node3D = enemy_ship_scene.instantiate() as Node3D

		if enemy == null:
			continue

		enemy.position = spawn_pos
		enemy.rotation.y = randf_range(0.0, TAU)

		add_child(enemy)

		if not enemy.is_in_group("objective_blocker"):
			enemy.add_to_group("objective_blocker")

		occupied_positions.append(spawn_pos)
		created += 1

	print("Navios criados: ", created)


# Cria as minas em posições seguras.
func spawn_mines() -> void:
	if enemy_mine_scene == null:
		push_warning("EnemySpawner: EnemyMine não configurada.")
		return

	var created: int = 0

	for _i in range(mine_count):
		var spawn_pos: Vector3 = get_valid_spawn_position(
			mine_min_height,
			mine_max_height
		)

		if spawn_pos == INVALID_SPAWN:
			push_warning(
				"EnemySpawner: mina não pôde ser criada."
			)
			continue

		var enemy: Node3D = enemy_mine_scene.instantiate() as Node3D

		if enemy == null:
			continue

		enemy.position = spawn_pos
		enemy.rotation.y = randf_range(0.0, TAU)

		add_child(enemy)

		if not enemy.is_in_group("objective_blocker"):
			enemy.add_to_group("objective_blocker")

		occupied_positions.append(spawn_pos)
		created += 1

	print("Minas criadas: ", created)


# Procura uma posição válida para o inimigo.
func get_valid_spawn_position(
	min_height: float,
	max_height: float
) -> Vector3:
	var max_attempts: int = 500

	for _attempt in range(max_attempts):
		var spawn_pos := Vector3(
			randf_range(-spawn_limit_x, spawn_limit_x),
			randf_range(min_height, max_height),
			randf_range(-spawn_limit_z, spawn_limit_z)
		)

		if is_position_near_land(spawn_pos):
			continue

		if not is_far_enough_from_player(spawn_pos):
			continue

		if not is_far_enough_from_objective(spawn_pos):
			continue

		if not is_far_enough_from_enemies(spawn_pos):
			continue

		return spawn_pos

	push_warning(
		"EnemySpawner: nenhuma posição segura encontrada."
	)

	return INVALID_SPAWN


# Verifica o ponto e uma margem ao redor da costa.
func is_position_near_land(world_position: Vector3) -> bool:
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
func is_position_on_land(world_position: Vector3) -> bool:
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
	spawn_pos: Vector3
) -> bool:
	if player == null:
		return true

	var distance_to_player: float = horizontal_distance(
		spawn_pos,
		player.global_position
	)

	return distance_to_player >= minimum_distance_from_player


func is_far_enough_from_objective(
	spawn_pos: Vector3
) -> bool:
	if objective == null:
		return true

	var distance_to_objective: float = horizontal_distance(
		spawn_pos,
		objective.global_position
	)

	return distance_to_objective >= minimum_distance_from_objective


func is_far_enough_from_enemies(
	spawn_pos: Vector3
) -> bool:
	for existing_position in occupied_positions:
		var distance_to_enemy: float = horizontal_distance(
			spawn_pos,
			existing_position
		)

		if distance_to_enemy < minimum_distance_between_enemies:
			return false

	return true


# Calcula a distância sem considerar a altura.
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
