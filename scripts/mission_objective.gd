extends Area3D

# Configurações do objetivo
@export var objective_name: String = "PONTO DE EXTRAÇÃO"
@export var proximity_distance: float = 60.0
@export var start_message: String = "MISSÃO ATIVA: LOCALIZE O PONTO DE EXTRAÇÃO"
@export var near_message: String = "OBJETIVO PRÓXIMO!"

signal mission_completed

var player: Node3D = null
var completed: bool = false
var proximity_warning_sent: bool = false


func _ready() -> void:
	add_to_group("mission_objective")
	body_entered.connect(_on_body_entered)

	await get_tree().process_frame
	await get_tree().process_frame

	player = get_tree().get_first_node_in_group("player") as Node3D

	print("OBJETIVO ATIVO: ", objective_name)
	show_message(start_message)


func _process(_delta: float) -> void:
	if completed:
		return

	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node3D

	if player == null:
		return

	check_player_distance()


# Mostra um aviso quando o jogador se aproxima.
func check_player_distance() -> void:
	if proximity_warning_sent:
		return

	var distance_to_player: float = horizontal_distance(
		global_position,
		player.global_position
	)

	if distance_to_player <= proximity_distance:
		proximity_warning_sent = true
		show_message(near_message)


func _on_body_entered(body: Node3D) -> void:
	if completed:
		return

	if not body.is_in_group("player"):
		return

	print("PLAYER ENTROU NO OBJETIVO")
	complete_objective()


# Finaliza a missão e desativa o objetivo.
func complete_objective() -> void:
	if completed:
		return

	completed = true

	# Precisa ser deferred durante o sinal body_entered.
	set_deferred("monitoring", false)

	print("MISSÃO CONCLUÍDA: ", objective_name)

	remove_from_group("mission_objective")
	hide()

	show_completion_screen()
	mission_completed.emit()


# Exibe a tela de missão concluída.
func show_completion_screen() -> void:
	var completion_ui: Node = get_tree().get_first_node_in_group(
		"mission_complete_ui"
	)

	if completion_ui == null:
		print("ERRO: MissionCompleteUI NÃO ENCONTRADO")
		return

	if completion_ui.has_method("show_completion"):
		completion_ui.call(
			"show_completion",
			objective_name
		)


# Calcula a distância sem considerar a profundidade.
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


func show_message(text: String) -> void:
	var hud: Node = get_tree().get_first_node_in_group("hud")

	if hud == null:
		return

	if hud.has_method("show_message"):
		hud.call(
			"show_message",
			text
		)
