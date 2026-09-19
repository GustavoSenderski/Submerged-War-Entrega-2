extends CharacterBody3D

# Detecção e movimento
@export var detection_range: float = 40.0
@export var approach_speed: float = 7.0
@export var approach_acceleration: float = 8.0
@export var patrol_speed: float = 2.5
@export var patrol_acceleration: float = 4.0
@export var patrol_radius: float = 30.0
@export var patrol_tolerance: float = 2.0
@export var turn_speed: float = 4.0

# Superfície e costa
@export var surface_height: float = 4.2
@export var coast_safety_distance: float = 8.0
@export var coast_side_angle: float = 30.0
@export var coast_avoid_time: float = 2.0

# Ataque
@export var mine_attack_distance: float = 6.0
@export var torpedo_attack_distance: float = 12.0
@export var attack_lock_time: float = 5.0
@export var torpedo_cooldown: float = 5.0
@export var surface_threshold: float = 2.8

# Cenas
@export var enemy_mine_scene: PackedScene
@export var enemy_torpedo_scene: PackedScene

# Referências
@onready var mesh: MeshInstance3D = $Visual/Hull
@onready var mine_spawn: Marker3D = get_node_or_null("MineSpawn") as Marker3D
@onready var torpedo_spawn: Marker3D = get_node_or_null("TorpedoSpawn") as Marker3D

var player: CharacterBody3D = null

enum State {
	PATROL,
	APPROACH,
	ATTACK
}

var current_state: State = State.PATROL
var patrol_origin: Vector3
var patrol_target: Vector3

var active_mine: Node3D = null
var attack_lock_timer: float = 0.0
var torpedo_cooldown_timer: float = 0.0
var torpedo_spawn_pending: bool = false

var normal_material: StandardMaterial3D
var detected_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("enemy_ship")

	# Colide somente com o continente.
	collision_layer = 0
	collision_mask = 2

	player = get_tree().get_first_node_in_group("player") as CharacterBody3D

	if player == null:
		push_warning("EnemyShip: submarino não encontrado.")
		return

	global_position.y = surface_height
	patrol_origin = global_position
	choose_new_patrol_target()

	normal_material = StandardMaterial3D.new()
	normal_material.albedo_color = Color(0.15, 0.15, 0.20)

	detected_material = StandardMaterial3D.new()
	detected_material.albedo_color = Color(1.0, 0.08, 0.08)

	if mesh != null:
		mesh.material_override = normal_material


func _physics_process(delta: float) -> void:
	if player == null:
		return

	update_timers(delta)

	if active_mine != null and not is_instance_valid(active_mine):
		active_mine = null

	# Mantém o navio na superfície.
	global_position.y = surface_height
	velocity.y = 0.0

	# Após atacar, retorna temporariamente à patrulha.
	if attack_lock_timer > 0.0:
		if current_state != State.PATROL:
			current_state = State.PATROL
			set_detected_visual(false)
			velocity = Vector3.ZERO
			choose_new_patrol_target()

		patrol(delta)
		global_position.y = surface_height
		velocity.y = 0.0
		return

	update_detection()

	match current_state:
		State.PATROL:
			patrol(delta)

		State.APPROACH:
			approach_player(delta)

		State.ATTACK:
			attack_player(delta)

	global_position.y = surface_height
	velocity.y = 0.0


# Verifica se o submarino entrou ou saiu da área de detecção.
func update_detection() -> void:
	var distance_to_player: float = global_position.distance_to(
		player.global_position
	)

	if distance_to_player <= detection_range:
		if current_state == State.PATROL:
			current_state = State.APPROACH
			set_detected_visual(true)

			print("SUBMARINO DETECTADO!")
			show_message("SUBMARINO DETECTADO!")
	else:
		if current_state != State.PATROL:
			current_state = State.PATROL
			set_detected_visual(false)
			velocity = Vector3.ZERO
			choose_new_patrol_target()


func update_timers(delta: float) -> void:
	if attack_lock_timer > 0.0:
		attack_lock_timer = max(
			attack_lock_timer - delta,
			0.0
		)

	if torpedo_cooldown_timer > 0.0:
		torpedo_cooldown_timer = max(
			torpedo_cooldown_timer - delta,
			0.0
		)


# Movimento normal de patrulha.
func patrol(delta: float) -> void:
	var distance_to_target: float = global_position.distance_to(
		patrol_target
	)

	if distance_to_target <= patrol_tolerance:
		choose_new_patrol_target()

	var direction: Vector3 = patrol_target - global_position
	direction.y = 0.0

	if direction.length() <= 0.01:
		return

	direction = direction.normalized()

	if coast_ahead(direction):
		velocity = Vector3.ZERO
		choose_new_patrol_target()
		return

	face_direction(direction, delta)

	var target_velocity: Vector3 = direction * patrol_speed

	velocity.x = move_toward(
		velocity.x,
		target_velocity.x,
		patrol_acceleration * delta
	)

	velocity.z = move_toward(
		velocity.z,
		target_velocity.z,
		patrol_acceleration * delta
	)

	velocity.y = 0.0

	move_and_slide()
	global_position.y = surface_height


# Escolhe um ponto de patrulha que não esteja sobre terra.
func choose_new_patrol_target() -> void:
	var attempts: int = 0

	while attempts < 20:
		attempts += 1

		var random_x: float = randf_range(
			-patrol_radius,
			patrol_radius
		)

		var random_z: float = randf_range(
			-patrol_radius,
			patrol_radius
		)

		var new_target: Vector3 = patrol_origin + Vector3(
			random_x,
			0.0,
			random_z
		)

		new_target.y = surface_height

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

	# Se não encontrar uma rota segura, permanece parado.
	patrol_target = global_position
	patrol_target.y = surface_height


func approach_player(delta: float) -> void:
	var horizontal_target := Vector3(
		player.global_position.x,
		surface_height,
		player.global_position.z
	)

	var direction: Vector3 = horizontal_target - global_position
	direction.y = 0.0

	var horizontal_distance: float = direction.length()
	var desired_distance: float

	if is_submarine_on_surface():
		desired_distance = torpedo_attack_distance
	else:
		desired_distance = mine_attack_distance

	if horizontal_distance <= desired_distance:
		current_state = State.ATTACK
		velocity = Vector3.ZERO
		return

	if direction.length() <= 0.01:
		return

	direction = direction.normalized()

	# Evita perseguir o jogador através do continente.
	if coast_ahead(direction):
		current_state = State.PATROL
		set_detected_visual(false)

		velocity = Vector3.ZERO
		choose_new_patrol_target()
		attack_lock_timer = coast_avoid_time
		return

	face_direction(direction, delta)

	var target_velocity: Vector3 = direction * approach_speed

	velocity.x = move_toward(
		velocity.x,
		target_velocity.x,
		approach_acceleration * delta
	)

	velocity.z = move_toward(
		velocity.z,
		target_velocity.z,
		approach_acceleration * delta
	)

	velocity.y = 0.0

	move_and_slide()
	global_position.y = surface_height


# Escolhe o ataque de acordo com a profundidade do jogador.
func attack_player(delta: float) -> void:
	velocity = Vector3.ZERO

	var horizontal_target := Vector3(
		player.global_position.x,
		surface_height,
		player.global_position.z
	)

	var direction: Vector3 = horizontal_target - global_position
	direction.y = 0.0

	var horizontal_distance: float = direction.length()
	var submarine_on_surface: bool = is_submarine_on_surface()
	var desired_distance: float

	if submarine_on_surface:
		desired_distance = torpedo_attack_distance
	else:
		desired_distance = mine_attack_distance

	if horizontal_distance > desired_distance + 3.0:
		current_state = State.APPROACH
		return

	if direction.length() > 0.01:
		face_direction(direction.normalized(), delta)

	# Próximo da superfície, o navio usa torpedo.
	if submarine_on_surface:
		if enemy_torpedo_scene != null and torpedo_cooldown_timer <= 0.0:
			fire_enemy_torpedo()

		return

	# Submerso, o navio utiliza mina.
	if active_mine != null:
		if is_instance_valid(active_mine):
			current_state = State.PATROL
			set_detected_visual(false)

			velocity = Vector3.ZERO
			choose_new_patrol_target()
			attack_lock_timer = attack_lock_time
			return

		active_mine = null

	drop_mine()


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

	var ray_start: Vector3 = global_position + Vector3(
		0.0,
		0.2,
		0.0
	)

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


func is_submarine_on_surface() -> bool:
	return player.global_position.y >= surface_threshold


func drop_mine() -> void:
	if enemy_mine_scene == null:
		push_warning("EnemyShip: TimedMine não configurada.")
		return

	# Mantém somente uma mina ativa por navio.
	if active_mine != null:
		if is_instance_valid(active_mine):
			return

		active_mine = null

	_spawn_mine()


func _spawn_mine() -> void:
	if enemy_mine_scene == null:
		return

	var mine: Node3D = enemy_mine_scene.instantiate() as Node3D

	if mine == null:
		push_warning("EnemyShip: erro ao criar mina.")
		return

	get_tree().current_scene.add_child(mine)

	if mine_spawn != null:
		mine.global_position = mine_spawn.global_position
	else:
		mine.global_position = global_position + Vector3(
			0.0,
			-1.0,
			0.0
		)

	active_mine = mine

	if mine.has_method("arm_as_timed_mine"):
		mine.call("arm_as_timed_mine", player)

	print("NAVIO LANÇOU UMA MINA!")
	show_message("MINA LANÇADA!")

	current_state = State.PATROL
	set_detected_visual(false)

	velocity = Vector3.ZERO
	choose_new_patrol_target()
	attack_lock_timer = attack_lock_time


func fire_enemy_torpedo() -> void:
	if enemy_torpedo_scene == null:
		return

	if torpedo_spawn_pending:
		return

	torpedo_spawn_pending = true
	call_deferred("_spawn_enemy_torpedo")


func _spawn_enemy_torpedo() -> void:
	torpedo_spawn_pending = false

	if enemy_torpedo_scene == null:
		return

	var torpedo: Node3D = enemy_torpedo_scene.instantiate() as Node3D

	if torpedo == null:
		return

	get_tree().current_scene.add_child(torpedo)

	if torpedo_spawn != null:
		torpedo.global_transform = torpedo_spawn.global_transform
	else:
		torpedo.global_position = global_position

	var direction: Vector3 = (
		player.global_position
		- torpedo.global_position
	).normalized()

	if torpedo.has_method("initialize"):
		torpedo.call("initialize", direction, player)

	torpedo_cooldown_timer = torpedo_cooldown

	print("NAVIO DISPAROU TORPEDO!")
	show_message("TORPEDO INIMIGO DISPARADO!")

	current_state = State.PATROL
	set_detected_visual(false)

	velocity = Vector3.ZERO
	choose_new_patrol_target()
	attack_lock_timer = attack_lock_time


# Faz o navio apontar para a direção de movimento.
func face_direction(direction: Vector3, delta: float) -> void:
	var flat_direction: Vector3 = direction
	flat_direction.y = 0.0

	if flat_direction.length() <= 0.01:
		return

	flat_direction = flat_direction.normalized()

	# A frente do modelo aponta para +X.
	var target_yaw: float = atan2(
		-flat_direction.z,
		flat_direction.x
	)

	rotation.y = lerp_angle(
		rotation.y,
		target_yaw,
		turn_speed * delta
	)


func set_detected_visual(detected: bool) -> void:
	if mesh == null:
		return

	if detected:
		mesh.material_override = detected_material
	else:
		mesh.material_override = normal_material


func show_message(text: String) -> void:
	var hud: Node = get_tree().get_first_node_in_group("hud")

	if hud == null:
		return

	if hud.has_method("show_message"):
		hud.call("show_message", text)
