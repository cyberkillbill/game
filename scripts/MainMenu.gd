extends Control
## MENU — versão minimal com feedback visual de clique.

const GAME_SCENE := "res://scenes/GameScreen.tscn"

var _status_label: Label   # mostra "carregando..." quando botão é apertado


func _ready() -> void:
	print("[MENU] _ready iniciado")
	_build()
	print("[MENU] _ready terminado")


func _build() -> void:
	# Fundo escuro (mouse_filter IGNORE pra não bloquear cliques)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.09)
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Container central com tudo. Anchors em PORCENTAGEM pra escalar bem.
	var box := VBoxContainer.new()
	box.anchor_left = 0.05
	box.anchor_right = 0.95
	box.anchor_top = 0.05
	box.anchor_bottom = 0.95
	box.add_theme_constant_override("separation", 20)
	add_child(box)

	# Título (menor pra caber tudo)
	var title := Label.new()
	title.text = "PORTO SANTIAGO"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)

	# Tagline
	var tag := Label.new()
	tag.text = "Domine a quebrada"
	tag.add_theme_font_size_override("font_size", 28)
	tag.add_theme_color_override("font_color", Color(1.0, 0.71, 0.0))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(tag)

	# Espaçador menor
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 60)
	box.add_child(sp)

	# Label de status (vazio por padrão, vira "Carregando..." ao clicar)
	_status_label = Label.new()
	_status_label.text = ""
	_status_label.add_theme_font_size_override("font_size", 22)
	_status_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_status_label)

	# Botões — menores pra TODOS caberem na tela
	var b_new := _big_button("NOVO JOGO", Color(0.82, 0.23, 0.17))
	b_new.pressed.connect(_on_new_game)
	# Também conecto button_down/button_up como backup pra debug de input
	b_new.button_down.connect(func(): print("[MENU] NOVO JOGO button_down"))
	box.add_child(b_new)

	var b_cont := _big_button("CONTINUAR", Color(0.96, 0.71, 0.0))
	b_cont.disabled = not Game.has_save()
	b_cont.pressed.connect(_on_continue)
	box.add_child(b_cont)

	var b_quit := _big_button("SAIR", Color(0.25, 0.27, 0.32))
	b_quit.pressed.connect(_on_quit)
	box.add_child(b_quit)


func _big_button(text: String, bg: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 110)
	b.add_theme_font_size_override("font_size", 34)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.4))
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	b.add_theme_stylebox_override("normal", sb)
	var sb2 := sb.duplicate() as StyleBoxFlat
	sb2.bg_color = bg.lightened(0.1)
	b.add_theme_stylebox_override("hover", sb2)
	var sb3 := sb.duplicate() as StyleBoxFlat
	sb3.bg_color = bg.darkened(0.2)
	b.add_theme_stylebox_override("pressed", sb3)
	var sb4 := sb.duplicate() as StyleBoxFlat
	sb4.bg_color = bg.darkened(0.5)
	b.add_theme_stylebox_override("disabled", sb4)
	return b


func _on_new_game() -> void:
	print("[MENU] NOVO JOGO pressed")
	_status_label.text = "Carregando..."
	await get_tree().process_frame
	Game.new_game("Você")
	_load_game_scene()


func _on_continue() -> void:
	print("[MENU] CONTINUAR pressed")
	_status_label.text = "Carregando save..."
	await get_tree().process_frame
	if not Game.load_game():
		_show_error("Falha ao carregar save.")
		return
	_load_game_scene()


func _load_game_scene() -> void:
	# Carga explícita em vez de change_scene_to_file: se a cena tiver erro
	# de script/import, load() retorna null e mostramos a falha na tela
	# em vez de trocar pra cena vazia (que ficaria preta ou travada).
	var res: Resource = load(GAME_SCENE)
	if res == null:
		_show_error("Falha ao carregar GameScreen.tscn (load null).")
		return
	var packed: PackedScene = res as PackedScene
	if packed == null:
		_show_error("Recurso carregado não é uma cena.")
		return
	var err := get_tree().change_scene_to_packed(packed)
	if err != OK:
		_show_error("change_scene_to_packed falhou (cod %d)." % err)


func _show_error(msg: String) -> void:
	_status_label.text = "ERRO: " + msg
	_status_label.add_theme_color_override("font_color", Color(1, 0.35, 0.35))
	push_error(msg)


func _on_quit() -> void:
	print("[MENU] SAIR pressed")
	get_tree().quit()
