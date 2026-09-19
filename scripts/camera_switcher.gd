extends Node3D

# Câmeras
@onready var player_camera: Camera3D = $Camera3D
@onready var top_camera: Camera3D = $TopCamera

# HUD
@onready var sonar: Control = $HUD/Sonar
@onready var strategic_overlay: Control = $HUD/StrategicOverlay
@onready var marker_layer: Control = $HUD/StrategicOverlay/MarkerLayer
@onready var scan_line: ColorRect = $HUD/StrategicOverlay/ScanLine

# Configurações
@export var scan_speed: float = 180.0
@export var mine_display_distance: float = 120.0

var top_view_active: bool = false

var player_marker: Polygon2D = null
var objective_marker: Polygon2D = null
var enemy_markers: Array[ColorRect] = []


func _ready() -> void:
	player_camera.current = true
	top_camera.current = false

	sonar.visible = true
	strategic_overlay.visible = false

	create_strategic_markers()


func _process(delta: float) -> void:
	if not top_view_active:
		return

	update_scan_line(delta)
	update_strategic_markers()


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("strategic_view"):
		toggle_camera()


# Alterna entre a câmera normal e estratégica.
func toggle_camera() -> void:
	top_view_active = not top_view_active

	if top_view_active:
		activate_strategic_view()
	else:
		activate_player_view()


func activate_strategic_view() -> void:
	player_camera.current = false
	top_camera.current = true

	sonar.visible = false
	strategic_overlay.visible = true

	refresh_enemy_markers()
	reset_scan_line()

	print("VISÃO ESTRATÉGICA ATIVADA")


func activate_player_view() -> void:
	top_camera.current = false
	player_camera.current = true

	sonar.visible = true
	strategic_overlay.visible = false

	print("VISÃO DO SUBMARINO ATIVADA")


# Cria os marcadores principais.
func create_strategic_markers() -> void:
	if marker_layer == null:
		return

	player_marker = create_player_marker()
	objective_marker = create_objective_marker()

	refresh_enemy_markers()


func create_player_marker() -> Polygon2D:
	var marker := Polygon2D.new()

	marker.polygon = PackedVector2Array([
		Vector2(0, -11),
		Vector2(7, 8),
		Vector2(0, 5),
		Vector2(-7, 8)
	])

	marker.color = Color(0.1, 1.0, 0.2)

	marker_layer.add_child(marker)

	return marker


func create_objective_marker() -> Polygon2D:
	var marker := Polygon2D.new()
	var points := PackedVector2Array()

	for i in range(24):
		var angle: float = TAU * float(i) / 24.0

		points.append(
			Vector2(
				cos(angle),
				sin(angle)
			) * 8.0
		)

	marker.polygon = points
	marker.color = Color(1.0, 0.9, 0.0)

	marker_layer.add_child(marker)

	return marker


# Recria os marcadores dos inimigos existentes.
func refresh_enemy_markers() -> void:
	for marker in enemy_markers:
		if is_instance_valid(marker):
			marker.queue_free()

	enemy_markers.clear()

	var enemies := get_tree().get_nodes_in_group("enemy")

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var color := Color.RED
		var size := Vector2(7, 7)

		if enemy.is_in_group("enemy_submarine"):
			color = Color(1.0, 0.0, 1.0)
			size = Vector2(9, 9)

		elif enemy.is_in_group("enemy_mine"):
			color = Color(1.0, 0.5, 0.0)
			size = Vector2(5, 5)

		var marker := ColorRect.new()

		marker.color = color
		marker.size = size
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE

		marker.set_meta("target", enemy)

		marker_layer.add_child(marker)
		enemy_markers.append(marker)


func update_strategic_markers() -> void:
	update_player_marker()
	update_objective_marker()
	update_enemy_markers()


# Atualiza o jogador na visão estratégica.
func update_player_marker() -> void:
	if player_marker == null:
		return

	var player := get_tree().get_first_node_in_group(
		"player"
	) as Node3D

	if player == null:
		player_marker.visible = false
		return

	player_marker.visible = true

	var screen_position: Vector2 = top_camera.unproject_position(
		player.global_position
	)

	player_marker.position = screen_position

	var forward: Vector3 = (
		player.global_transform.basis.x.normalized()
	)

	var front_position: Vector2 = top_camera.unproject_position(
		player.global_position + forward * 10.0
	)

	var screen_direction: Vector2 = (
		front_position - screen_position
	)

	if screen_direction.length() > 0.1:
		player_marker.rotation = (
			screen_direction.angle()
			+ PI / 2.0
		)


# Atualiza o objetivo na visão estratégica.
func update_objective_marker() -> void:
	if objective_marker == null:
		return

	var objective := get_tree().get_first_node_in_group(
		"mission_objective"
	) as Node3D

	if objective == null:
		objective_marker.visible = false
		return

	objective_marker.visible = true

	objective_marker.position = top_camera.unproject_position(
		objective.global_position
	)


# Atualiza os inimigos na visão estratégica.
func update_enemy_markers() -> void:
	var player := get_tree().get_first_node_in_group(
		"player"
	) as Node3D

	for marker in enemy_markers:
		if not is_instance_valid(marker):
			continue

		var target = marker.get_meta(
			"target",
			null
		)

		if target == null or not is_instance_valid(target):
			marker.visible = false
			continue

		# Minas aparecem somente próximas do jogador.
		if target.is_in_group("enemy_mine"):
			if player == null:
				marker.visible = false
				continue

			var mine_distance: float = (
				player.global_position.distance_to(
					target.global_position
				)
			)

			if mine_distance > mine_display_distance:
				marker.visible = false
				continue

		marker.visible = true

		set_enemy_marker_position(
			marker,
			target.global_position
		)


func set_enemy_marker_position(
	marker: Control,
	world_position: Vector3
) -> void:
	var screen_position: Vector2 = top_camera.unproject_position(
		world_position
	)

	marker.position = (
		screen_position
		- marker.size / 2.0
	)


# Move a linha de varredura da visão estratégica.
func update_scan_line(delta: float) -> void:
	if scan_line == null:
		return

	scan_line.position.y += scan_speed * delta

	var screen_height: float = (
		get_viewport()
		.get_visible_rect()
		.size.y
	)

	if scan_line.position.y > screen_height:
		scan_line.position.y = 0.0


func reset_scan_line() -> void:
	if scan_line != null:
		scan_line.position.y = 0.0
