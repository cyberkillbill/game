extends Control
## Editor de Personagem — apelido, tom de pele, cabelo, barba, camisa de time fictício.

const MAP_PATH := "res://scenes/map/StrategicMap.tscn"
const MENU_PATH := "res://scenes/main_menu/MainMenu.tscn"

var _pc: PlayerCharacter
var _name_edit: LineEdit
var _avatar_panel: Control
var _jersey_preview: Control
var _is_new_game: bool


func _ready() -> void:
	_is_new_game = GameManager.player == null
	_pc = GameManager.player if GameManager.player else PlayerCharacter.default_char()

	var bg := ColorRect.new()
	bg.color = Palette.BG_BASE
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	add_child(bg)

	var sc := ScrollContainer.new()
	sc.anchor_right = 1
	sc.anchor_bottom = 1
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 60)
	sc.add_child(margin)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 24)
	margin.add_child(content)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	content.add_child(header)
	var back := IconButton.new()
	back.icon_char = "←"
	back.pressed.connect(_on_back)
	header.add_child(back)
	var title := Label.new()
	title.text = "Quem é você?" if _is_new_game else "Seu Perfil"
	title.theme_type_variation = "H2"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 16)
	content.add_child(top_spacer)

	# Avatar preview
	_avatar_panel = _build_avatar_panel()
	content.add_child(_avatar_panel)

	# Nickname
	var nick_card := Card.new()
	content.add_child(nick_card)
	var nick_vb := VBoxContainer.new()
	nick_vb.add_theme_constant_override("separation", 8)
	nick_card.add_child(nick_vb)
	var nick_label := Label.new()
	nick_label.text = "APELIDO"
	nick_label.theme_type_variation = "Muted"
	nick_vb.add_child(nick_label)
	_name_edit = LineEdit.new()
	_name_edit.text = _pc.nickname
	_name_edit.placeholder_text = "Como vão te chamar nas ruas?"
	_name_edit.text_changed.connect(func(t: String): _pc.nickname = t)
	nick_vb.add_child(_name_edit)

	# Atributos visuais — usar OptionButtons
	content.add_child(_make_picker("TOM DE PELE", [
		"Claro", "Médio claro", "Médio", "Médio escuro", "Escuro"
	], int(_pc.skin), func(idx: int):
		_pc.skin = idx as PlayerCharacter.SkinTone
		_refresh_avatar()))

	content.add_child(_make_picker("CABELO", [
		"Curto", "Degradê", "Cacheado", "Longo", "Raspado", "Tranças"
	], int(_pc.hair), func(idx: int):
		_pc.hair = idx as PlayerCharacter.HairStyle
		_refresh_avatar()))

	content.add_child(_make_picker("BARBA", [
		"Nenhuma", "Bigode", "Cavanhaque", "Cheia", "Por fazer"
	], int(_pc.facial), func(idx: int):
		_pc.facial = idx as PlayerCharacter.FacialHair
		_refresh_avatar()))

	content.add_child(_make_picker("CAMISA DE TIME (fictícios)", [
		"Atlético Litoral", "Real Serrano", "União Portuária", "Grêmio Palmares",
		"Esporte Central", "Juventude Atlântica", "Nacional do Vale", "Independente FC"
	], int(_pc.jersey), func(idx: int):
		_pc.jersey = idx as PlayerCharacter.JerseyTeam
		_refresh_avatar()))

	var tat_card := Card.new()
	content.add_child(tat_card)
	var tat_row := HBoxContainer.new()
	tat_card.add_child(tat_row)
	var tat_label := Label.new()
	tat_label.text = "TATUAGENS NO PESCOÇO"
	tat_label.theme_type_variation = "Muted"
	tat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tat_row.add_child(tat_label)
	var tat_btn := CheckButton.new()
	tat_btn.button_pressed = _pc.has_tattoo
	tat_btn.toggled.connect(func(p: bool):
		_pc.has_tattoo = p
		_refresh_avatar())
	tat_row.add_child(tat_btn)

	# CTA
	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 16)
	content.add_child(spacer2)

	var cta := PrimaryButton.new()
	cta.text = "Começar Império →" if _is_new_game else "Salvar Mudanças"
	cta.set_variant(PrimaryButton.Variant.PRIMARY)
	cta.pressed.connect(_on_confirm)
	content.add_child(cta)

	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 60)
	content.add_child(bottom_spacer)


func _build_avatar_panel() -> Control:
	var card := Card.new()
	card.custom_minimum_size = Vector2(0, 600)
	var center := CenterContainer.new()
	center.anchor_right = 1
	center.anchor_bottom = 1
	card.add_child(center)
	_jersey_preview = Control.new()
	_jersey_preview.custom_minimum_size = Vector2(600, 560)
	center.add_child(_jersey_preview)
	_jersey_preview.draw.connect(_draw_avatar)
	return card


func _refresh_avatar() -> void:
	if _jersey_preview:
		_jersey_preview.queue_redraw()


func _draw_avatar() -> void:
	var c := _jersey_preview
	var sz := c.size
	if sz.x <= 0 or sz.y <= 0:
		sz = Vector2(600, 560)

	# Base centro
	var cx := sz.x / 2
	var top := 40.0

	# Camisa = retângulo arredondado com cor primária do time
	var team_colors := PlayerCharacter.team_colors(_pc.jersey)
	var primary: Color = team_colors[0]
	var secondary: Color = team_colors[1]

	# Corpo (camisa)
	var shirt_rect := Rect2(cx - 200, top + 200, 400, 280)
	_draw_rounded_rect(c, shirt_rect, primary, 24)
	# Faixa horizontal estilizada
	_draw_rounded_rect(c, Rect2(cx - 200, top + 200 + 80, 400, 36), secondary, 6)
	# Gola
	_draw_rounded_rect(c, Rect2(cx - 50, top + 200, 100, 30), secondary, 8)
	# Brasão estilizado (escudo)
	var crest_pos := Vector2(cx - 165, top + 240)
	_draw_rounded_rect(c, Rect2(crest_pos, Vector2(48, 56)), secondary, 6)
	c.draw_string(c.get_theme_default_font(), crest_pos + Vector2(8, 36),
		"%d" % (int(_pc.jersey) + 1), HORIZONTAL_ALIGNMENT_LEFT, 32, 22, primary)

	# Pescoço
	var skin_col := _pc.skin_color()
	_draw_rounded_rect(c, Rect2(cx - 38, top + 160, 76, 60), skin_col, 8)
	# Tatuagem
	if _pc.has_tattoo:
		_draw_rounded_rect(c, Rect2(cx - 28, top + 200, 56, 14), Color(0.06, 0.06, 0.1), 4)

	# Cabeça
	var head_radius := 90.0
	c.draw_circle(Vector2(cx, top + 90), head_radius, skin_col)

	# Cabelo
	_draw_hair(c, Vector2(cx, top + 90), head_radius)

	# Barba
	_draw_facial(c, Vector2(cx, top + 90), head_radius)

	# Olhos
	c.draw_circle(Vector2(cx - 28, top + 86), 5, Color(0.05, 0.05, 0.08))
	c.draw_circle(Vector2(cx + 28, top + 86), 5, Color(0.05, 0.05, 0.08))

	# Nome do time
	var team_label := PlayerCharacter.team_name(_pc.jersey)
	c.draw_string(c.get_theme_default_font(), Vector2(cx - 200, top + 510),
		team_label, HORIZONTAL_ALIGNMENT_CENTER, 400, 22, Palette.TEXT_MUTED)


func _draw_hair(c: Control, head_center: Vector2, head_r: float) -> void:
	var hair_color := Color(0.06, 0.05, 0.05)
	match _pc.hair:
		PlayerCharacter.HairStyle.SHORT:
			_draw_rounded_rect(c, Rect2(head_center.x - head_r, head_center.y - head_r - 4, head_r * 2, head_r * 0.7), hair_color, 60)
		PlayerCharacter.HairStyle.FADE:
			_draw_rounded_rect(c, Rect2(head_center.x - head_r * 0.8, head_center.y - head_r, head_r * 1.6, head_r * 0.55), hair_color, 40)
		PlayerCharacter.HairStyle.CURLY:
			for i in 9:
				var ang := PI + i * (PI / 8)
				var px := head_center.x + cos(ang) * head_r * 0.95
				var py := head_center.y + sin(ang) * head_r * 0.95
				c.draw_circle(Vector2(px, py), 18, hair_color)
		PlayerCharacter.HairStyle.LONG:
			_draw_rounded_rect(c, Rect2(head_center.x - head_r, head_center.y - head_r, head_r * 2, head_r * 2.1), hair_color, 50)
			# corte oval na frente pra mostrar rosto
			c.draw_circle(head_center + Vector2(0, 10), head_r * 0.92, _pc.skin_color())
		PlayerCharacter.HairStyle.BALD:
			pass
		PlayerCharacter.HairStyle.BRAIDS:
			for i in 6:
				var px := head_center.x - head_r * 0.6 + i * (head_r * 0.25)
				_draw_rounded_rect(c, Rect2(px, head_center.y - head_r, 14, head_r * 1.6), hair_color, 6)


func _draw_facial(c: Control, head_center: Vector2, head_r: float) -> void:
	var col := Color(0.06, 0.05, 0.05)
	match _pc.facial:
		PlayerCharacter.FacialHair.MUSTACHE:
			_draw_rounded_rect(c, Rect2(head_center.x - 35, head_center.y + 32, 70, 10), col, 4)
		PlayerCharacter.FacialHair.GOATEE:
			_draw_rounded_rect(c, Rect2(head_center.x - 18, head_center.y + 50, 36, 22), col, 8)
		PlayerCharacter.FacialHair.FULL_BEARD:
			_draw_rounded_rect(c, Rect2(head_center.x - 70, head_center.y + 20, 140, 60), col, 30)
		PlayerCharacter.FacialHair.STUBBLE:
			for i in 25:
				var rng := RandomNumberGenerator.new()
				rng.seed = i * 13 + int(_pc.skin)
				var px := head_center.x + rng.randf_range(-60, 60)
				var py := head_center.y + rng.randf_range(20, 70)
				c.draw_circle(Vector2(px, py), 1.5, Color(col, 0.6))
		_:
			pass


func _draw_rounded_rect(c: Control, rect: Rect2, color: Color, _radius: float) -> void:
	# Aproximação: draw_rect; Godot 4 não tem rounded_rect nativo no Control.draw.
	c.draw_rect(rect, color, true)


func _make_picker(label_text: String, options: Array, current: int, on_change: Callable) -> Card:
	var card := Card.new()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	card.add_child(vb)
	var l := Label.new()
	l.text = label_text
	l.theme_type_variation = "Muted"
	vb.add_child(l)
	var opt := OptionButton.new()
	for s in options:
		opt.add_item(s)
	opt.selected = current
	opt.item_selected.connect(on_change)
	opt.custom_minimum_size = Vector2(0, 72)
	vb.add_child(opt)
	return card


func _on_confirm() -> void:
	if _name_edit.text.strip_edges().is_empty():
		_pc.nickname = "Patrão"
	else:
		_pc.nickname = _name_edit.text.strip_edges()

	if _is_new_game:
		GameManager.start_new_game(_pc)
		GameManager.change_scene(MAP_PATH)
	else:
		GameManager.player = _pc
		GameManager.change_scene(MAP_PATH)


func _on_back() -> void:
	if _is_new_game:
		GameManager.change_scene(MENU_PATH)
	else:
		GameManager.change_scene(MAP_PATH)
