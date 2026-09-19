extends Node3D

# Detecção e dano
@export var detection_range: float = 5.0
@export var collision_distance: float = 1.5
@export var explosion_damage: int = 2
@export var explosion_delay: float = 0.8

# Movimento da mina
@export var sway_amount: float = 0.18
@export var sway_speed: float = 1.3
@export var vertical_sway_amount: float = 0.08

var player: Node3D = null
var detected: bool = false
var exploded: bool = false
var explosion_timer: float = 0.0

var original_position: Vector3
var original_rotation: Vector3
var sway_time: float = 0.0


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("enemy_mine")
	add_to_group("objective_blocker")

	player = get_tree().get_first_node_in_group("player") as Node3D

	original_position = position
	original_rotation = rotation

	if player == null:
		push_warning("EnemyMine: submarino não encontrado.")
	else:
		print("EnemyMine encontrou o jogador: ", player.name)


func _process(delta: float) -> void:
	if exploded:
		return

	update_sway(delta)

	if player == null or not is_instance_valid(player):
		return

	var distance_to_player: float = global_position.distance_to(
		player.global_position
	)

	# Contato direto causa explosão imediata.
	if distance_to_player <= collision_distance:
		explode(true)
		return

	# Detecta o submarino dentro do raio da mina.
	if not detected and distance_to_player <= detection_range:
		detected = true
		explosion_timer = explosion_delay

		print("MINA DETECTOU O SUBMARINO!")
		show_message("MINA DETECTOU O SUBMARINO!")

	# Após detectar, inicia a contagem para explosão.
	if detected:
		explosion_timer -= delta

		if explosion_timer <= 0.0:
			explode(false)


# Simula o movimento da mina pela correnteza.
func update_sway(delta: float) -> void:
	sway_time += delta * sway_speed

	rotation.x = (
		original_rotation.x
		+ sin(sway_time) * sway_amount
	)

	rotation.z = (
		original_rotation.z
		+ cos(sway_time * 0.8) * sway_amount
	)

	position.y = (
		original_position.y
		+ sin(sway_time * 0.7) * vertical_sway_amount
	)


# Explode a mina e aplica dano quando necessário.
func explode(direct_collision: bool = false) -> void:
	if exploded:
		return

	exploded = true

	print("MINA EXPLODIU!")
	show_message("MINA EXPLODIU!")

	if player != null and is_instance_valid(player):
		var distance_to_player: float = global_position.distance_to(
			player.global_position
		)

		if direct_collision or distance_to_player <= detection_range:
			if player.has_method("take_damage"):
				player.call(
					"take_damage",
					explosion_damage
				)

			print("SUBMARINO ATINGIDO PELA MINA!")
			show_message("SUBMARINO ATINGIDO!")

	queue_free()


func show_message(text: String) -> void:
	var hud: Node = get_tree().get_first_node_in_group("hud")

	if hud == null:
		return

	if hud.has_method("show_message"):
		hud.call("show_message", text)
