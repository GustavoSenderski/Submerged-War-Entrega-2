extends CanvasLayer

# Elementos da tela
@onready var overlay: ColorRect = $Overlay
@onready var panel: Panel = $Overlay/CenterContainer/panel
@onready var title: Label = $Overlay/CenterContainer/panel/VBoxContainer/Title
@onready var subtitle: Label = $Overlay/CenterContainer/panel/VBoxContainer/Subtitle
@onready var status: Label = $Overlay/CenterContainer/panel/VBoxContainer/Status
@onready var restart_button: Button = $Overlay/CenterContainer/panel/VBoxContainer/Buttons/RestartButton
@onready var exit_button: Button = $Overlay/CenterContainer/panel/VBoxContainer/Buttons/ExitButton


func _ready() -> void:
	add_to_group("mission_complete_ui")

	# Permite que os botões funcionem com o jogo pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS

	overlay.visible = false

	restart_button.pressed.connect(
		_on_restart_pressed
	)

	exit_button.pressed.connect(
		_on_exit_pressed
	)


# Exibe a tela de missão concluída.
func show_completion(objective_name: String) -> void:
	if overlay.visible:
		return

	overlay.visible = true

	title.text = "MISSÃO CONCLUÍDA"
	subtitle.text = objective_name + " ALCANÇADO"
	status.text = "OPERAÇÃO FINALIZADA COM SUCESSO"

	overlay.modulate.a = 0.0
	panel.scale = Vector2(0.90, 0.90)

	await get_tree().process_frame

	panel.pivot_offset = panel.size / 2.0

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		overlay,
		"modulate:a",
		1.0,
		0.5
	)

	tween.tween_property(
		panel,
		"scale",
		Vector2.ONE,
		0.5
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	await tween.finished

	get_tree().paused = true
	restart_button.grab_focus()


# Reinicia a missão.
func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


# Fecha o jogo.
func _on_exit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
