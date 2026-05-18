extends Control
## Menu principal — minimal, procedural, sem dependências.

const GAME_SCENE := "res://scenes/GameScreen.tscn"

var _bg: ColorRect
var _continue_btn: Button


func _ready() -> void:
	print("[MainMenu] _ready")
	_build_background()
	_build_content()
	# Pinta uma frame imediatamente — se algo der ruim depois disto,
	# pelo menos o usuário vê uma tela colorida (não preta).


func _build_background() -> void:
	_bg = ColorRect.new()
	_bg.color = Game.COLOR_BG
	_bg.anchor_right = 1.0
	_bg.anchor_bottom = 1.0
	_bg.offset_right = 0
	_bg.offset_bottom = 0
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	# Faixa vermelha decorativa no topo
	var top_strip := ColorRect.new()
	top_strip.color = Game.COLOR_RED
	top_strip.anchor_right = 1.0
	top_strip.offset_top = 0
	top_strip.offset_bottom = 8
	top_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_strip)

	# Faixa dourada no fim
	var bot_strip := ColorRect.new()
	bot_strip.color = Game.COLOR_GOLD
	bot_strip.anchor_right = 1.0
	bot_strip.anchor_top = 1.0
	bot_strip.anchor_bottom = 1.0
	bot_strip.offset_top = -6
	bot_strip.offset_bottom = 0
	bot_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bot_strip)


func _build_content() -> void:
	var center := VBoxContainer.new()
	center.anchor_left = 0
	center.anchor_right = 1
	center.anchor_top = 0
	center.anchor_bottom = 1
	center.offset_left = 80
	center.offset_right = -80
	center.offset_top = 280
	center.offset_bottom = -160
	center.alignment = BoxContainer.ALIGNMENT_BEGIN
	center.add_theme_constant_override("separation", 28)
	add_child(center)

	var title := Label.new()
	title.text = "PORTO\nSANTIAGO"
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Game.COLOR_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	center.add_child(title)

	var rule := ColorRect.new()
	rule.color = Game.COLOR_RED
	rule.custom_minimum_size = Vector2(140, 6)
	center.add_child(rule)

	var tag := Label.new()
	tag.text = "Domine a quebrada."
	tag.add_theme_font_size_override("font_size", 36)
	tag.add_theme_color_override("font_color", Game.COLOR_GOLD)
	center.add_child(tag)

	var sub := Label.new()
	sub.text = "Drama criminal ficcional · 100% brasileiro"
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", Game.COLOR_MUTED)
	center.add_child(sub)

	# Espaço
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 80)
	center.add_child(sp)

	# Botões
	var btn_new := _make_button("NOVO CORRE", Game.COLOR_RED, Game.COLOR_TEXT)
	btn_new.pressed.connect(_on_new_game)
	center.add_child(btn_new)

	_continue_btn = _make_button("CONTINUAR", Game.COLOR_GOLD, Game.COLOR_BG)
	_continue_btn.disabled = not Game.has_save()
	_continue_btn.pressed.connect(_on_continue)
	center.add_child(_continue_btn)

	var btn_about := _make_button("SOBRE O JOGO", Game.COLOR_ELEVATED, Game.COLOR_TEXT)
	btn_about.pressed.connect(_on_about)
	center.add_child(btn_about)

	# Footer
	var footer := Label.new()
	footer.text = "v0.2 · build interno · debug"
	footer.add_theme_font_size_override("font_size", 20)
	footer.add_theme_color_override("font_color", Game.COLOR_MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.anchor_top = 1
	footer.anchor_bottom = 1
	footer.anchor_left = 0
	footer.anchor_right = 1
	footer.offset_top = -80
	footer.offset_bottom = -20
	footer.offset_left = 0
	footer.offset_right = 0
	add_child(footer)


func _make_button(text: String, bg: Color, fg: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 110)
	b.add_theme_font_size_override("font_size", 36)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_disabled_color", Game.COLOR_MUTED)
	b.focus_mode = Control.FOCUS_NONE
	var n := _stylebox(bg)
	var h := _stylebox(bg.lightened(0.08))
	var p := _stylebox(bg.darkened(0.15))
	var d := _stylebox(Game.COLOR_ELEVATED.darkened(0.2))
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_stylebox_override("disabled", d)
	return b


func _stylebox(c: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.corner_radius_top_left = 12
	s.corner_radius_top_right = 12
	s.corner_radius_bottom_left = 12
	s.corner_radius_bottom_right = 12
	s.content_margin_left = 24
	s.content_margin_right = 24
	s.content_margin_top = 18
	s.content_margin_bottom = 18
	return s


# --- Ações ---
func _on_new_game() -> void:
	print("[MainMenu] new game")
	Game.new_game("Você")
	_change_to_game()


func _on_continue() -> void:
	print("[MainMenu] continue")
	if Game.load_game():
		_change_to_game()


func _change_to_game() -> void:
	var err := get_tree().change_scene_to_file(GAME_SCENE)
	if err != OK:
		push_error("change_scene falhou: %d" % err)


func _on_about() -> void:
	var d := AcceptDialog.new()
	d.title = "Sobre"
	d.dialog_text = "Porto Santiago é um drama criminal estratégico ficcional ambientado num bairro brasileiro inventado.\n\nNenhuma comunidade, organização criminal, marca ou pessoa reais são referenciadas. Tudo aqui é invenção.\n\nGênero inspirado em jogos de império criminal. Sem afiliação com nenhuma franquia.\n\nFeito com Godot 4."
	d.ok_button_text = "Fechar"
	d.min_size = Vector2(880, 600)
	d.add_theme_color_override("title_color", Game.COLOR_TEXT)
	add_child(d)
	d.popup_centered()
	d.confirmed.connect(d.queue_free)
	d.canceled.connect(d.queue_free)
