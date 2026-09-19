extends Node3D

# Limites do mapa
@export var min_x: float = -380.0
@export var max_x: float = 380.0
@export var min_z: float = -380.0
@export var max_z: float = 380.0

# Layer 2 = continente
@export_flags_3d_physics var terrain_collision_mask: int = 2
@export var terrain_check_height: float = 50.0
@export var terrain_check_depth: float = -50.0

# Configurações do jogador
@export var player_spawn_y: float = -4.0
@export var player_blocker_distance: float = 100.0

# Configurações do objetivo
@export var objective_min_y: float = -7.0
@export var objective_max_y: float = -2.0
@export var objective_player_distance: float = 300.0
@export var objective_blocker_distance: float = 60.0

@export var max_attempts: int = 300

var player: Node3D = null
var objective: Node3D = null


func _ready() -> void:
	call_deferred("setup_mission")


# Localiza os objetos e configura a missão.
func setup_mission() -> void:
	player = get_tree().get_first_node_in_group("player") as Node3D

	objective = get_tree().get_first_node_in_group(
		"mission_objective"
	) as Node3D

	if player == null:
		push_warning(
			"MissionSetup: submarino não encontrado."
		)
		return

	if objective == null:
		push_warning(
			"MissionSetup: objetivo não encontrado."
		)
		return

	randomize_player_position()
	randomize_objective_position()

	print("================================")
	print("MISSÃO CONFIGURADA")
	print("SUBMARINO: ", player.global_position)
	print("OBJETIVO: ", objective.global_position)
	print(
		"DISTÂNCIA: ",
		get_horizontal_distance(
			player.global_position,
			objective.global_position
		)
	)
	print("================================")


# Procura uma posição segura para o jogador.
func randomize_player_position() -> void:
	for attempt in range(max_attempts):
		var candidate: Vector3 = Vector3(
			randf_range(min_x, max_x),
			player_spawn_y,
			randf_range(min_z, max_z)
		)

		if is_position_on_land(candidate):
			continue

		if not is_position_far_from_blockers(
			candidate,
			player_blocker_distance
		):
			continue

		player.global_position = candidate
		player.rotation.y = randf_range(-PI, PI)

		print(
			"SUBMARINO POSICIONADO APÓS ",
			attempt + 1,
			" TENTATIVA(S)."
		)
		return

	push_warning(
		"MissionSetup: não encontrou posição ideal para o submarino."
	)


# Procura uma posição segura para o objetivo.
func randomize_objective_position() -> void:
	for attempt in range(max_attempts):
		var candidate: Vector3 = Vector3(
			randf_range(min_x, max_x),
			randf_range(
				objective_min_y,
				objective_max_y
			),
			randf_range(min_z, max_z)
		)

		if is_position_on_land(candidate):
			continue

		var distance_from_player: float = get_horizontal_distance(
			candidate,
			player.global_position
		)

		if distance_from_player < objective_player_distance:
			continue

		if not is_position_far_from_blockers(
			candidate,
			objective_blocker_distance
		):
			continue

		objective.global_position = candidate

		print(
			"OBJETIVO POSICIONADO APÓS ",
			attempt + 1,
			" TENTATIVA(S)."
		)
		return

	push_warning(
		"MissionSetup: não encontrou posição ideal para o objetivo."
	)


# Verifica se uma posição está sobre o continente.
func is_position_on_land(
	test_position: Vector3
) -> bool:
	var space_state: PhysicsDirectSpaceState3D = (
		get_world_3d().direct_space_state
	)

	var ray_start: Vector3 = Vector3(
		test_position.x,
		terrain_check_height,
		test_position.z
	)

	var ray_end: Vector3 = Vector3(
		test_position.x,
		terrain_check_depth,
		test_position.z
	)

	var query := PhysicsRayQueryParameters3D.create(
		ray_start,
		ray_end
	)

	query.collision_mask = terrain_collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var result: Dictionary = space_state.intersect_ray(query)

	return not result.is_empty()


# Evita posições próximas de inimigos e bloqueadores.
func is_position_far_from_blockers(
	test_position: Vector3,
	minimum_distance: float
) -> bool:
	var blockers: Array[Node] = get_tree().get_nodes_in_group(
		"objective_blocker"
	)

	for blocker in blockers:
		if not blocker is Node3D:
			continue

		var blocker_3d: Node3D = blocker as Node3D

		if blocker_3d == player:
			continue

		if blocker_3d == objective:
			continue

		var distance_to_blocker: float = get_horizontal_distance(
			test_position,
			blocker_3d.global_position
		)

		if distance_to_blocker < minimum_distance:
			return false

	return true


# Calcula a distância sem considerar a profundidade.
func get_horizontal_distance(
	position_a: Vector3,
	position_b: Vector3
) -> float:
	var point_a: Vector2 = Vector2(
		position_a.x,
		position_a.z
	)

	var point_b: Vector2 = Vector2(
		position_b.x,
		position_b.z
	)

	return point_a.distance_to(point_b)
