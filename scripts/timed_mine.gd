extends Node3D

# Configurações da mina
@export var explosion_time: float = 4.0
@export var sink_speed: float = 1.5
@export var minimum_y: float = -8.0
@export var explosion_radius: float = 5.0
@export var explosion_damage: int = 2

var player: CharacterBody3D = null
var timer: float = 0.0
var exploded: bool = false


func _ready() -> void:
	add_to_group("timed_mine")

	timer = explosion_time


# Recebe o jogador e arma a mina.
func arm_as_timed_mine(
	target_player: CharacterBody3D
) -> void:
	player = target_player

	print(
		"MINA ARMADA! Explosão em ",
		explosion_time,
		" segundos."
	)

	show_message("MINA ARMADA!")


func _process(delta: float) -> void:
	if exploded:
		return

	update_sink(delta)

	timer -= delta

	if timer <= 0.0:
		explode()


# Faz a mina afundar até a profundidade máxima.
func update_sink(delta: float) -> void:
	if global_position.y <= minimum_y:
		return

	global_position.y -= sink_speed * delta

	if global_position.y < minimum_y:
		global_position.y = minimum_y


# Explode e causa dano se o jogador estiver no raio.
func explode() -> void:
	if exploded:
		return

	exploded = true

	print("MINA EXPLODIU!")
	show_message("MINA EXPLODIU!")

	if player != null and is_instance_valid(player):
		check_explosion_damage()

	queue_free()


func check_explosion_damage() -> void:
	var distance_to_player: float = global_position.distance_to(
		player.global_position
	)

	print(
		"Distância da explosão ao submarino: ",
		distance_to_player
	)

	if distance_to_player > explosion_radius:
		print("SUBMARINO FORA DO RAIO DA EXPLOSÃO.")
		return

	if player.has_method("take_damage"):
		player.call(
			"take_damage",
			explosion_damage
		)

	print("SUBMARINO ATINGIDO PELA MINA!")
	show_message("SUBMARINO ATINGIDO PELA MINA!")


func show_message(text: String) -> void:
	var hud: Node = get_tree().get_first_node_in_group("hud")

	if hud == null:
		return

	if hud.has_method("show_message"):
		hud.call("show_message", text)
