extends Control

# Configurações do mapa
@export var map_offset_x: float = 0.0
@export var map_offset_z: float = 0.0
@export var map_reference: MeshInstance3D
@export var flip_x: bool = false
@export var flip_z: bool = false
@export var marker_margin: float = 8.0
@export var detection_radius: float = 180.0

@onready var map: TextureRect = $Map
@onready var player_marker: Control = $PlayerMarker
@onready var objective_marker: Control = $ObjectiveMarker

var player: Node3D = null
var objective: Node3D = null

var player_arrow: Polygon2D = null
var objective_circle: Polygon2D = null

var ship_markers: Dictionary = {}
var mine_markers: Dictionary = {}
var submarine_markers: Dictionary = {}


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Node3D

	objective = get_tree().get_first_node_in_group(
		"mission_objective"
	) as Node3D

	if player == null:
		push_warning(
			"Sonar: submarino do jogador não encontrado."
		)

	if objective == null:
		push_warning(
			"Sonar: objetivo não encontrado."
		)

	if map_reference == null:
		push_warning(
			"Sonar: Map Reference não configurado."
		)

	player_marker.z_index = 20
	objective_marker.z_index = 21

	create_player_arrow()
	create_objective_circle()


func _process(_delta: float) -> void:
	if map_reference == null:
		return

	update_player()
	update_objective()
	update_enemy_ships()
	update_enemy_mines()
	update_enemy_submarines()


# Atualiza a posição e direção do jogador.
func update_player() -> void:
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node3D

	if player == null:
		return

	player_marker.position = world_to_sonar(
		player.global_position,
		player_marker.size
	)

	update_player_direction()


# Atualiza a posição do objetivo.
func update_objective() -> void:
	if objective == null or not is_instance_valid(objective):
		objective = get_tree().get_first_node_in_group(
			"mission_objective"
		) as Node3D

	if objective == null:
		objective_marker.visible = false
		return

	objective_marker.visible = true

	objective_marker.position = world_to_sonar(
		objective.global_position,
		objective_marker.size
	)


# Atualiza os navios detectados.
func update_enemy_ships() -> void:
	if player == null or not is_instance_valid(player):
		return

	var ships := get_tree().get_nodes_in_group("enemy_ship")

	for ship in ships:
		if not is_instance_valid(ship):
			continue

		var distance_to_player: float = (
			player.global_position.distance_to(
				ship.global_position
			)
		)

		if distance_to_player > detection_radius:
			remove_enemy_marker(ship_markers, ship)
			continue

		if not ship_markers.has(ship):
			ship_markers[ship] = create_ship_marker()

		var marker: Control = ship_markers[ship]

		marker.position = world_to_sonar(
			ship.global_position,
			marker.size
		)

	cleanup_markers(ship_markers)


# Atualiza as minas detectadas.
func update_enemy_mines() -> void:
	if player == null or not is_instance_valid(player):
		return

	var mines := get_tree().get_nodes_in_group("enemy_mine")

	for mine in mines:
		if not is_instance_valid(mine):
			continue

		var distance_to_player: float = (
			player.global_position.distance_to(
				mine.global_position
			)
		)

		if distance_to_player > detection_radius:
			remove_enemy_marker(mine_markers, mine)
			continue

		if not mine_markers.has(mine):
			mine_markers[mine] = create_mine_marker()

		var marker: Control = mine_markers[mine]

		marker.position = world_to_sonar(
			mine.global_position,
			marker.size
		)

	cleanup_markers(mine_markers)


# Atualiza os submarinos inimigos detectados.
func update_enemy_submarines() -> void:
	if player == null or not is_instance_valid(player):
		return

	var submarines := get_tree().get_nodes_in_group(
		"enemy_submarine"
	)

	for submarine in submarines:
		if not is_instance_valid(submarine):
			continue

		var distance_to_player: float = (
			player.global_position.distance_to(
				submarine.global_position
			)
		)

		if distance_to_player > detection_radius:
			remove_enemy_marker(
				submarine_markers,
				submarine
			)
			continue

		if not submarine_markers.has(submarine):
			submarine_markers[submarine] = (
				create_submarine_marker()
			)

		var marker: Control = submarine_markers[submarine]

		marker.position = world_to_sonar(
			submarine.global_position,
			marker.size
		)

	cleanup_markers(submarine_markers)


# Remove um marcador que saiu do alcance.
func remove_enemy_marker(
	markers: Dictionary,
	enemy: Node
) -> void:
	if not markers.has(enemy):
		return

	var marker = markers[enemy]

	if is_instance_valid(marker):
		marker.queue_free()

	markers.erase(enemy)


# Converte uma posição 3D para o sonar.
func world_to_sonar(
	world_position: Vector3,
	marker_size: Vector2
) -> Vector2:
	var local_position: Vector3 = map_reference.to_local(
		world_position
	)

	local_position.x += map_offset_x
	local_position.z += map_offset_z

	var map_aabb: AABB = map_reference.get_aabb()

	var normalized_x: float = inverse_lerp(
		map_aabb.position.x,
		map_aabb.position.x + map_aabb.size.x,
		local_position.x
	)

	var normalized_z: float = inverse_lerp(
		map_aabb.position.z,
		map_aabb.position.z + map_aabb.size.z,
		local_position.z
	)

	if flip_x:
		normalized_x = 1.0 - normalized_x

	if flip_z:
		normalized_z = 1.0 - normalized_z

	normalized_x = clamp(normalized_x, 0.0, 1.0)
	normalized_z = clamp(normalized_z, 0.0, 1.0)

	var usable_width: float = (
		map.size.x
		- marker_margin * 2.0
	)

	var usable_height: float = (
		map.size.y
		- marker_margin * 2.0
	)

	var sonar_position := Vector2(
		map.position.x
		+ marker_margin
		+ normalized_x * usable_width,

		map.position.y
		+ marker_margin
		+ normalized_z * usable_height
	)

	sonar_position = clamp_to_circle(sonar_position)

	return sonar_position - marker_size / 2.0


# Mantém os marcadores dentro do sonar circular.
func clamp_to_circle(point: Vector2) -> Vector2:
	var center: Vector2 = (
		map.position
		+ map.size / 2.0
	)

	var radius: float = (
		min(map.size.x, map.size.y) / 2.0
		- marker_margin
	)

	var direction: Vector2 = point - center

	if direction.length() > radius:
		direction = direction.normalized() * radius

	return center + direction


# Cria a seta verde do jogador.
func create_player_arrow() -> void:
	if player_marker is ColorRect:
		var marker := player_marker as ColorRect
		marker.color.a = 0.0

	player_arrow = Polygon2D.new()
	player_arrow.name = "Arrow"

	player_arrow.polygon = PackedVector2Array([
		Vector2(6.0, 0.0),
		Vector2(-4.0, -4.0),
		Vector2(-4.0, 4.0)
	])

	player_arrow.color = Color(
		0.2,
		1.0,
		0.35,
		1.0
	)

	player_arrow.position = player_marker.size / 2.0
	player_marker.add_child(player_arrow)


# Atualiza a direção da seta do jogador.
func update_player_direction() -> void:
	if player == null or not is_instance_valid(player):
		return

	if player_arrow == null:
		return

	var forward: Vector3 = (
		player.global_transform.basis.x
	)

	var direction_2d := Vector2(
		forward.x,
		forward.z
	)

	if flip_x:
		direction_2d.x *= -1.0

	if flip_z:
		direction_2d.y *= -1.0

	if direction_2d.length() <= 0.01:
		return

	player_arrow.rotation = direction_2d.angle()


# Cria o marcador amarelo do objetivo.
func create_objective_circle() -> void:
	if objective_marker is ColorRect:
		var marker := objective_marker as ColorRect
		marker.color.a = 0.0

	objective_circle = Polygon2D.new()

	var points := PackedVector2Array()
	var radius: float = 3.0

	for i in range(16):
		var angle: float = (
			TAU
			* float(i)
			/ 16.0
		)

		points.append(
			Vector2(
				cos(angle),
				sin(angle)
			) * radius
		)

	objective_circle.polygon = points

	objective_circle.color = Color(
		1.0,
		0.9,
		0.1,
		1.0
	)

	objective_circle.position = (
		objective_marker.size / 2.0
	)

	objective_marker.add_child(
		objective_circle
	)


# Cria o marcador vermelho dos navios.
func create_ship_marker() -> Control:
	var marker := Control.new()

	marker.size = Vector2(5.0, 5.0)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.z_index = 15

	var square := ColorRect.new()

	square.size = Vector2(5.0, 5.0)

	square.color = Color(
		1.0,
		0.15,
		0.15,
		1.0
	)

	marker.add_child(square)
	add_child(marker)

	return marker


# Cria o marcador laranja das minas.
func create_mine_marker() -> Control:
	var marker := Control.new()

	marker.size = Vector2(4.0, 4.0)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.z_index = 16

	var circle := Polygon2D.new()
	var points := PackedVector2Array()

	for i in range(12):
		var angle: float = (
			TAU
			* float(i)
			/ 12.0
		)

		points.append(
			Vector2(
				cos(angle),
				sin(angle)
			) * 2.0
		)

	circle.polygon = points

	circle.color = Color(
		1.0,
		0.55,
		0.1,
		1.0
	)

	circle.position = Vector2(2.0, 2.0)

	marker.add_child(circle)
	add_child(marker)

	return marker


# Cria o marcador rosa dos submarinos inimigos.
func create_submarine_marker() -> Control:
	var marker := Control.new()

	marker.size = Vector2(7.0, 7.0)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.z_index = 17

	var diamond := Polygon2D.new()

	diamond.polygon = PackedVector2Array([
		Vector2(3.5, 0.0),
		Vector2(7.0, 3.5),
		Vector2(3.5, 7.0),
		Vector2(0.0, 3.5)
	])

	diamond.color = Color(
		1.0,
		0.15,
		0.65,
		1.0
	)

	marker.add_child(diamond)
	add_child(marker)

	return marker


# Remove marcadores de inimigos destruídos.
func cleanup_markers(markers: Dictionary) -> void:
	var to_remove: Array = []

	for enemy in markers.keys():
		if not is_instance_valid(enemy):
			var marker = markers[enemy]

			if is_instance_valid(marker):
				marker.queue_free()

			to_remove.append(enemy)

	for enemy in to_remove:
		markers.erase(enemy)
