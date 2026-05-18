extends Control
## Menu principal — alto contraste, click-feedback explícito, sem focus_mode.

const GAME_SCENE := "res://scenes/GameScreen.tscn"

var _continue_btn: Button
var _tap_counter: Label
var _taps: int = 0


func _ready() -> void:
	print("[MainMenu] _ready · saved=", Game.has_save())
	_build_background()
	_build_content()
	# Diagnóstico: qualquer toque na tela incrementa um contador,
	# pra confirmar visualmente que input está chegando ao app.
	set_process_unhandled_input(true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_bump_tap()
	elif event is InputEventMouseButton and event.pressed:
		_bump_tap()


func _bump_tap() -> void:
	_taps += 1
	if _tap_counter:
		_tap_counter.text = "toques: %d" % _taps


# ===========================================================================
# Background
# ===========================================================================
func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Game.COLOR_BG
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Faixa vermelha topo
	var top := ColorRect.new()
	top.color = Game.COLOR_RED
	top.anchor_right = 1.0
	top.offset_bottom = 10
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)

	# Faixa dourada fim
	var bot := ColorRect.new()
	bot.color = Game.COLOR_GOLD
	bot.anchor_right = 1.0
	bot.anchor_top = 1.0
	bot.anchor_bottom = 1.0
	bot.offset_top = -8
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bot)

	# Halo vermelho atrás do título (gradiente radial procedural)
	var halo := _radial(Game.COLOR_RED, 0.15, 900)
	halo.position = Vector2(80, 250)
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(halo)


func _radial(color: Color, alpha: float, sz: int) -> TextureRect:
	var grad := Gradient.new()
	grad.add_point(0.0, Color(color, alpha))
	grad.add_point(1.0, Color(color, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = sz
	tex.height = sz
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	var tr := TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = Vector2(sz, sz)
	tr.size = Vector2(sz, sz)
	return tr


# ===========================================================================
# Conteúdo
# ===========================================================================
func _build_content() -> void:
	var center := VBoxContainer.new()
	center.anchor_left = 0
	center.anchor_right = 1
	center.anchor_top = 0
	center.anchor_bottom = 1
	center.offset_left = 60
	center.offset_right = -60
	center.offset_top = 240
	center.offset_bottom = -200
	center.add_theme_constant_override("separation", 24)
	add_child(center)

	var title := Label.new()
	title.text = "PORTO\nSANTIAGO"
	title.add_theme_font_size_override("font_size", 110)
	title.add_theme_color_override("font_color", Game.COLOR_TEXT)
	title.add_theme_constant_override("line_spacing", -8)
	center.add_child(title)

	var rule := ColorRect.new()
	rule.color = Game.COLOR_RED
	rule.custom_minimum_size = Vector2(160, 8)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(rule)

	var tag := Label.new()
	tag.text = "Domine a quebrada."
	tag.add_theme_font_size_override("font_size", 40)
	tag.add_theme_color_override("font_color", Game.COLOR_GOLD)
	center.add_child(tag)

	var sub := Label.new()
	sub.text = "Drama criminal · 100% ficcional · BR"
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", Game.COLOR_MUTED)
	center.add_child(sub)

	# Espaçador
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 60)
	center.add_child(sp)

	# Botões — todos VISIBLE com cor distinta + borda. Sem focus_mode.
	var btn_new := _action_button(
		"▶  NOVO CORRE",
		Game.COLOR_RED,             # fundo
		Color("ffffff"),            # texto
		Color("ff6b5e"),             # borda accent (mais clara)
	)
	btn_new.pressed.connect(_on_new_game)
	center.add_child(btn_new)

	_continue_btn = _action_button(
		"⤴  CONTINUAR",
		Game.COLOR_GOLD,
		Game.COLOR_BG,
		Color("fcd34d"),
	)
	_continue_btn.disabled = not Game.has_save()
	_continue_btn.pressed.connect(_on_continue)
	center.add_child(_continue_btn)

	var btn_about := _action_button(
		"ⓘ  SOBRE O JOGO",
		Color("2a2f3a"),             # cinza médio, claramente visível
		Color("ececf0"),
		Color("6e7282"),             # borda mais clara
	)
	btn_about.pressed.connect(_on_about)
	center.add_child(btn_about)

	# Tap counter pra confirmar input chegando
	_tap_counter = Label.new()
	_tap_counter.text = "toques: 0"
	_tap_counter.add_theme_font_size_override("font_size", 18)
	_tap_counter.add_theme_color_override("font_color", Game.COLOR_MUTED)
	_tap_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tap_counter.anchor_top = 1
	_tap_counter.anchor_bottom = 1
	_tap_counter.anchor_left = 0
	_tap_counter.anchor_right = 1
	_tap_counter.offset_top = -100
	_tap_counter.offset_bottom = -60
	_tap_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tap_counter)

	var footer := Label.new()
	footer.text = "v0.3 · build %s" % Time.get_datetime_string_from_system()
	footer.add_theme_font_size_override("font_size", 16)
	footer.add_theme_color_override("font_color", Game.COLOR_MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.anchor_top = 1
	footer.anchor_bottom = 1
	footer.anchor_left = 0
	footer.anchor_right = 1
	footer.offset_top = -55
	footer.offset_bottom = -25
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(footer)


# ===========================================================================
# Botão com alta visibilidade
# ===========================================================================
func _action_button(text: String, bg: Color, fg: Color, accent: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 120)
	b.add_theme_font_size_override("font_size", 38)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_disabled_color", Color(fg, 0.4))
	# Estilos
	b.add_theme_stylebox_override("normal",  _btn_style(bg, accent, 3))
	b.add_theme_stylebox_override("hover",   _btn_style(bg.lightened(0.08), accent, 3))
	b.add_theme_stylebox_override("pressed", _btn_style(bg.darkened(0.18), accent, 3))
	b.add_theme_stylebox_override("disabled", _btn_style(bg.darkened(0.35), accent.darkened(0.4), 2))
	b.add_theme_stylebox_override("focus",   _btn_style(Color.TRANSPARENT, accent, 3))
	return b


func _btn_style(c: Color, border: Color, border_w: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.corner_radius_top_left = 14
	s.corner_radius_top_right = 14
	s.corner_radius_bottom_left = 14
	s.corner_radius_bottom_right = 14
	s.border_color = border
	s.border_width_left = border_w
	s.border_width_right = border_w
	s.border_width_top = border_w
	s.border_width_bottom = border_w
	s.content_margin_left = 24
	s.content_margin_right = 24
	s.content_margin_top = 18
	s.content_margin_bottom = 18
	s.shadow_color = Color(c, 0.4)
	s.shadow_size = 8
	return s


# ===========================================================================
# Ações
# ===========================================================================
func _on_new_game() -> void:
	print("[MainMenu] NOVO CORRE pressed")
	Game.new_game("Você")
	_go_to_game()


func _on_continue() -> void:
	print("[MainMenu] CONTINUAR pressed")
	if Game.load_game():
		_go_to_game()


func _go_to_game() -> void:
	var err := get_tree().change_scene_to_file(GAME_SCENE)
	if err != OK:
		push_error("change_scene falhou: %d" % err)


func _on_about() -> void:
	print("[MainMenu] SOBRE pressed")
	var d := AcceptDialog.new()
	d.title = "Sobre"
	d.dialog_text = "Porto Santiago é um drama criminal estratégico ficcional ambientado num bairro brasileiro inventado.\n\nNenhuma comunidade, organização, marca ou pessoa real é referenciada. Tudo aqui é invenção.\n\nGênero inspirado em jogos de império criminal. Sem afiliação com nenhuma franquia.\n\nFeito com Godot 4."
	d.ok_button_text = "Fechar"
	d.min_size = Vector2(900, 600)
	add_child(d)
	d.popup_centered()
	d.confirmed.connect(d.queue_free)
	d.canceled.connect(d.queue_free)
