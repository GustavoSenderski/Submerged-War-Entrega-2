extends CanvasLayer

# Elementos do HUD
@onready var message_label: Label = $MessageLabel
@onready var health_label: Label = $HealthLabel
@onready var boost_label: Label = $BoostLabel

var message_timer: float = 0.0
var player: Node = null
var damage_flash: ColorRect = null


func _ready() -> void:
	add_to_group("hud")

	setup_message_label()
	setup_health_label()
	setup_boost_label()
	create_damage_flash()

	player = get_tree().get_first_node_in_group("player")

	if player == null:
		health_label.text = "VIDA: --"
	else:
		update_health()


# Configura a mensagem de alerta.
func setup_message_label() -> void:
	message_label.text = ""
	message_label.visible = false
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	message_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.1, 0.1)
	)

	message_label.add_theme_font_size_override(
		"font_size",
		28
	)


# Configura o indicador de vida.
func setup_health_label() -> void:
	health_label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	health_label.add_theme_font_size_override(
		"font_size",
		24
	)


# Configura o indicador de boost.
func setup_boost_label() -> void:
	boost_label.text = "BOOST"
	boost_label.visible = false

	boost_label.add_theme_color_override(
		"font_color",
		Color(0.0, 0.9, 1.0)
	)

	boost_label.add_theme_font_size_override(
		"font_size",
		24
	)


func _process(delta: float) -> void:
	update_message_timer(delta)

	boost_label.visible = Input.is_action_pressed(
		"boost"
	)


# Controla o tempo das mensagens.
func update_message_timer(delta: float) -> void:
	if message_timer <= 0.0:
		return

	message_timer -= delta

	if message_timer <= 0.0:
		message_label.visible = false


# Cria o efeito vermelho de dano.
func create_damage_flash() -> void:
	damage_flash = ColorRect.new()
	damage_flash.name = "DamageFlash"

	add_child(damage_flash)

	damage_flash.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_flash.color = Color(0.8, 0.0, 0.0, 0.0)
	damage_flash.z_index = -1


func show_damage_flash() -> void:
	if damage_flash == null:
		return

	damage_flash.color.a = 0.28

	var tween := create_tween()

	tween.tween_property(
		damage_flash,
		"color:a",
		0.0,
		0.35
	)


# Exibe uma mensagem temporária.
func show_message(text: String) -> void:
	if message_label == null:
		return

	message_label.text = text
	message_label.visible = true
	message_timer = 2.0


# Atualiza a vida mostrada no HUD.
func update_health(
	current_value: int = -1,
	max_value: int = -1
) -> void:
	if health_label == null:
		return

	if current_value >= 0 and max_value >= 0:
		health_label.text = (
			"VIDA: "
			+ str(current_value)
			+ "/"
			+ str(max_value)
		)
		return

	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group(
			"player"
		)

	if player == null:
		health_label.text = "VIDA: --"
		return

	health_label.text = (
		"VIDA: "
		+ str(player.current_health)
		+ "/"
		+ str(player.max_health)
	)
