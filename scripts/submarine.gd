extends CharacterBody3D

# Vida
@export var max_health: int = 10
var current_health: int

# Movimento
@export var move_speed: float = 6.0
@export var reverse_speed: float = 3.5
@export var acceleration: float = 5.0
@export var deceleration: float = 4.0
@export var vertical_speed: float = 4.0
@export var vertical_acceleration: float = 5.0
@export var rotation_speed: float = 1.8
@export var boost_speed: float = 12.0

# Leme
@export var max_rudder_angle: float = 22.0
@export var rudder_speed: float = 5.0
@onready var tail: MeshInstance3D = $Tail
var tail_original_rotation_y: float = 0.0

# Torpedo
@export var torpedo_scene: PackedScene
@export var fire_cooldown: float = 0.8
@onready var torpedo_spawn: Marker3D = $TorpedoSpawn
var fire_timer: float = 0.0

# Limites do mapa
@export var max_height: float = 3.6
@export var max_depth: float = -8.5
@export var horizontal_limit_x: float = 425.0
@export var horizontal_limit_z: float = 425.0


func _ready() -> void:
	current_health = max_health
	tail_original_rotation_y = tail.rotation.y

	collision_layer = 1
	collision_mask = 2

	print("Vida do submarino: ", current_health, "/", max_health)


func _physics_process(delta: float) -> void:
	var forward_input: float = Input.get_axis("move_backward", "move_forward")
	var turn_input: float = Input.get_axis("turn_right", "turn_left")
	var vertical_input: float = Input.get_axis("move_down", "move_up")
	var boost_active: bool = Input.is_action_pressed("boost")

	# Aplica zona morta aos controles.
	if abs(forward_input) < 0.15:
		forward_input = 0.0

	if abs(turn_input) < 0.15:
		turn_input = 0.0

	if abs(vertical_input) < 0.15:
		vertical_input = 0.0

	update_rotation(turn_input, delta)
	update_movement(forward_input, vertical_input, boost_active, delta)

	move_and_slide()
	apply_movement_limits()
	update_torpedo(delta)


# Atualiza a rotação do submarino e do leme.
func update_rotation(turn_input: float, delta: float) -> void:
	rotate_y(turn_input * rotation_speed * delta)

	var target_rudder_rotation: float = (
		tail_original_rotation_y
		+ deg_to_rad(-max_rudder_angle * turn_input)
	)

	tail.rotation.y = lerp_angle(
		tail.rotation.y,
		target_rudder_rotation,
		min(rudder_speed * delta, 1.0)
	)


# Calcula a velocidade horizontal e vertical.
func update_movement(
	forward_input: float,
	vertical_input: float,
	boost_active: bool,
	delta: float
) -> void:
	var forward_direction: Vector3 = global_transform.basis.x
	forward_direction.y = 0.0

	if forward_direction.length() > 0.01:
		forward_direction = forward_direction.normalized()

	var target_velocity_x: float = 0.0
	var target_velocity_z: float = 0.0

	if forward_input > 0.0:
		var current_speed: float = move_speed

		if boost_active:
			current_speed = boost_speed

		target_velocity_x = forward_direction.x * current_speed * forward_input
		target_velocity_z = forward_direction.z * current_speed * forward_input

	elif forward_input < 0.0:
		target_velocity_x = forward_direction.x * reverse_speed * forward_input
		target_velocity_z = forward_direction.z * reverse_speed * forward_input

	if forward_input != 0.0:
		velocity.x = move_toward(
			velocity.x,
			target_velocity_x,
			acceleration * delta
		)
		velocity.z = move_toward(
			velocity.z,
			target_velocity_z,
			acceleration * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			deceleration * delta
		)
		velocity.z = move_toward(
			velocity.z,
			0.0,
			deceleration * delta
		)

	var target_vertical_speed: float = vertical_input * vertical_speed

	velocity.y = move_toward(
		velocity.y,
		target_vertical_speed,
		vertical_acceleration * delta
	)


# Mantém o submarino dentro da área jogável.
func apply_movement_limits() -> void:
	global_position.y = clamp(global_position.y, max_depth, max_height)
	global_position.x = clamp(
		global_position.x,
		-horizontal_limit_x,
		horizontal_limit_x
	)
	global_position.z = clamp(
		global_position.z,
		-horizontal_limit_z,
		horizontal_limit_z
	)

	if global_position.y >= max_height and velocity.y > 0.0:
		velocity.y = 0.0

	if global_position.y <= max_depth and velocity.y < 0.0:
		velocity.y = 0.0


# Controla o intervalo entre os disparos.
func update_torpedo(delta: float) -> void:
	if fire_timer > 0.0:
		fire_timer -= delta

	if Input.is_action_just_pressed("fire") and fire_timer <= 0.0:
		fire_torpedo()
		fire_timer = fire_cooldown


func fire_torpedo() -> void:
	if torpedo_scene == null:
		print("Torpedo Scene não configurada.")
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
		torpedo.call("initialize", fire_direction)

	print("TORPEDO DISPARADO!")


# Reduz a vida e verifica a destruição.
func take_damage(damage: int) -> void:
	if current_health <= 0:
		return

	current_health -= damage
	current_health = max(current_health, 0)

	print(
		"SUBMARINO RECEBEU DANO! Vida: ",
		current_health,
		"/",
		max_health
	)

	update_health_hud()
	show_damage_feedback()

	if current_health <= 0:
		submarine_destroyed()


func show_damage_feedback() -> void:
	var hud: Node = get_tree().get_first_node_in_group("hud")

	if hud == null:
		return

	if hud.has_method("show_damage_flash"):
		hud.call("show_damage_flash")


func update_health_hud() -> void:
	var hud: Node = get_tree().get_first_node_in_group("hud")

	if hud == null:
		return

	if hud.has_method("update_health"):
		hud.call("update_health", current_health, max_health)


func submarine_destroyed() -> void:
	print("SUBMARINO DESTRUÍDO!")

	velocity = Vector3.ZERO
	set_physics_process(false)

	show_failure_screen()


func show_failure_screen() -> void:
	var failure_ui: Node = get_tree().get_first_node_in_group(
		"mission_failed_ui"
	)

	if failure_ui == null:
		print("ERRO: MissionFailedUI NÃO ENCONTRADO")
		return

	if failure_ui.has_method("show_failure"):
		failure_ui.call("show_failure")
