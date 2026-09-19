extends Node3D

# Configurações
@export var speed: float = 16.0
@export var damage: int = 2
@export var hit_distance: float = 1.5
@export var max_lifetime: float = 8.0

var direction: Vector3 = Vector3.ZERO
var target: Node3D = null
var lifetime: float = 0.0
var initialized: bool = false


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("enemy_torpedo")

	lifetime = max_lifetime


# Recebe a direção do disparo e o jogador como alvo.
func initialize(
	fire_direction: Vector3,
	target_player: Node3D
) -> void:
	direction = fire_direction.normalized()
	target = target_player
	initialized = true

	print("TORPEDO INIMIGO INICIALIZADO!")


func _process(delta: float) -> void:
	if not initialized:
		return

	lifetime -= delta

	if lifetime <= 0.0:
		queue_free()
		return

	global_position += direction * speed * delta

	if target == null:
		return

	if not is_instance_valid(target):
		target = null
		return

	var distance_to_target: float = global_position.distance_to(
		target.global_position
	)

	if distance_to_target <= hit_distance:
		hit_target()


# Aplica dano ao jogador e destrói o torpedo.
func hit_target() -> void:
	if target != null and is_instance_valid(target):
		if target.has_method("take_damage"):
			target.call("take_damage", damage)

	print("TORPEDO INIMIGO ATINGIU O SUBMARINO!")
	show_message("TORPEDO ATINGIU O SUBMARINO!")

	queue_free()


func show_message(text: String) -> void:
	var hud: Node = get_tree().get_first_node_in_group("hud")

	if hud == null:
		return

	if hud.has_method("show_message"):
		hud.call("show_message", text)
