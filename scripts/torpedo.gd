extends Area3D

# Configurações do torpedo
@export var speed: float = 18.0
@export var lifetime: float = 5.0
@export var hit_distance: float = 2.0

var direction: Vector3 = Vector3.ZERO
var life_timer: float = 0.0
var already_hit: bool = false


func _ready() -> void:
	life_timer = lifetime

	monitoring = true
	monitorable = true
	collision_layer = 2
	collision_mask = 1

	body_entered.connect(_on_body_entered)


# Define a direção recebida pelo submarino.
func initialize(new_direction: Vector3) -> void:
	direction = new_direction.normalized()


func _physics_process(delta: float) -> void:
	if already_hit:
		return

	if direction == Vector3.ZERO:
		return

	global_position += direction * speed * delta

	# Complementa a detecção da Area3D.
	check_enemy_collision()

	life_timer -= delta

	if life_timer <= 0.0:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if already_hit or body == null:
		return

	if body.is_in_group("player"):
		return

	if body.is_in_group("enemy"):
		destroy_enemy(body)


# Verifica inimigos próximos ao torpedo.
func check_enemy_collision() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance: float = global_position.distance_to(
			enemy.global_position
		)

		if distance <= hit_distance:
			destroy_enemy(enemy)
			return


func destroy_enemy(enemy: Node) -> void:
	if already_hit or not is_instance_valid(enemy):
		return

	already_hit = true

	if enemy.is_in_group("enemy_ship"):
		print("TORPEDO DESTRUIU NAVIO!")
		show_message("NAVIO INIMIGO DESTRUÍDO!")

	elif enemy.is_in_group("enemy_submarine"):
		print("TORPEDO DESTRUIU SUBMARINO INIMIGO!")
		show_message("SUBMARINO INIMIGO DESTRUÍDO!")

	elif enemy.is_in_group("enemy_torpedo"):
		print("TORPEDO INIMIGO DESTRUÍDO!")
		show_message("TORPEDO INIMIGO DESTRUÍDO!")

	elif enemy.is_in_group("enemy_mine"):
		print("TORPEDO DESTRUIU MINA!")
		show_message("MINA DESTRUÍDA!")

	else:
		print("TORPEDO DESTRUIU INIMIGO!")
		show_message("INIMIGO DESTRUÍDO!")

	enemy.queue_free()
	queue_free()


func show_message(text: String) -> void:
	var hud: Node = get_tree().get_first_node_in_group("hud")

	if hud == null:
		return

	if hud.has_method("show_message"):
		hud.call("show_message", text)
