extends Control
## MENU — versão brutalmente minimal. APENAS Buttons default e Labels.
## Zero estilização customizada, zero halo, zero tap counter, zero gradiente.
## Se essa versão der tela preta, o problema é da engine/projeto, não do código.

const GAME_SCENE := "res://scenes/GameScreen.tscn"


func _ready() -> void:
	print("[MENU] _ready iniciado")
	_build()
	print("[MENU] _ready terminado")


func _build() -> void:
	# Fundo escuro
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.09)
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	add_child(bg)

	# Container central — 3 botões + título empilhados
	var box := VBoxContainer.new()
	box.anchor_left = 0.05
	box.anchor_right = 0.95
	box.anchor_top = 0.10
	box.anchor_bottom = 0.95
	box.add_theme_constant_override("separation", 30)
	add_child(box)

	# Título
	var title := Label.new()
	title.text = "PORTO\nSANTIAGO"
	title.add_theme_font_size_override("font_size", 90)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	# Sub
	var tag := Label.new()
	tag.text = "Domine a quebrada"
	tag.add_theme_font_size_override("font_size", 32)
	tag.add_theme_color_override("font_color", Color(1.0, 0.71, 0.0))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tag)

	# Espaçador
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 200)
	box.add_child(sp)

	# Botão 1 — NOVO JOGO (vermelho)
	var b_new := _big_button("NOVO JOGO", Color(0.82, 0.23, 0.17))
	b_new.pressed.connect(_on_new_game)
	box.add_child(b_new)

	# Botão 2 — CONTINUAR (dourado, desabilita se não tem save)
	var b_cont := _big_button("CONTINUAR", Color(0.96, 0.71, 0.0))
	b_cont.disabled = not Game.has_save()
	b_cont.pressed.connect(_on_continue)
	box.add_child(b_cont)

	# Botão 3 — SAIR
	var b_quit := _big_button("SAIR", Color(0.25, 0.27, 0.32))
	b_quit.pressed.connect(_on_quit)
	box.add_child(b_quit)


func _big_button(text: String, bg: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 140)
	b.add_theme_font_size_override("font_size", 40)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	# Stylebox simples
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
	print("[MENU] NOVO JOGO")
	Game.new_game("Você")
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_continue() -> void:
	print("[MENU] CONTINUAR")
	if Game.load_game():
		get_tree().change_scene_to_file(GAME_SCENE)


func _on_quit() -> void:
	print("[MENU] SAIR")
	get_tree().quit()
