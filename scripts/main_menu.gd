extends Control

@onready var play_button: Button = $MenuContainer/PlayButton
@onready var exit_button: Button = $MenuContainer/ExitButton

var selected_button: int = 0


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	update_selection()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_down"):
		selected_button = 1
		update_selection()

	elif event.is_action_pressed("menu_up"):
		selected_button = 0
		update_selection()

	elif event.is_action_pressed("menu_confirm"):
		activate_selected_button()


# Atualiza o botão selecionado.
func update_selection() -> void:
	if selected_button == 0:
		play_button.grab_focus()
	else:
		exit_button.grab_focus()


# Executa o botão selecionado.
func activate_selected_button() -> void:
	if selected_button == 0:
		_on_play_pressed()
	else:
		_on_exit_pressed()


# Inicia o jogo.
func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(
		"res://Scenes/TestSubmarineMovement.tscn"
	)


# Fecha o jogo.
func _on_exit_pressed() -> void:
	get_tree().quit()
