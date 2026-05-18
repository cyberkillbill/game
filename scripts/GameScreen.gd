extends Control
## Tela de jogo · HUD + mapa 4x4 + ações + log.
## Reformulada: alto contraste, click confiável, produto por boca,
## brasão de facção, log estilo notificação.

const MENU_SCENE := "res://scenes/MainMenu.tscn"

var _selected_id: int = -1
var _tile_buttons: Array = []   # Array[Button]

# HUD refs
var _lbl_cash: Label
var _lbl_clean: Label
var _lbl_soldiers: Label
var _lbl_heat: Label
var _lbl_turn: Label

var _detail_panel: VBoxContainer
var _log_container: VBoxContainer


func _ready() -> void:
	print("[GameScreen] _ready · player=%s · tiles=%d" % [Game.player_name, Game.territories.size()])
	_build_ui()
	Game.state_changed.connect(_refresh_all)
	Game.log_event.connect(_on_log_event)
	Game.game_finished.connect(_on_game_finished)
	_refresh_all()


# ===========================================================================
# Build UI (procedural, sem focus_mode em botões)
# ===========================================================================
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Game.COLOR_BG
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Scroll global pra caber em qualquer altura de tela
	var scroll := ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 16
	scroll.offset_right = -16
	scroll.offset_top = 20
	scroll.offset_bottom = -20
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 14)
	scroll.add_child(root)

	_build_hud(root)
	_build_map(root)
	_build_detail(root)
	_build_log(root)
	_build_footer(root)


func _build_hud(parent: Node) -> void:
	var card := _card(parent, Game.COLOR_RED)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	_lbl_cash     = _stat_chip(row, "GRANA",  Game.COLOR_GOLD)
	_lbl_clean    = _stat_chip(row, "LIMPO",  Game.COLOR_GREEN)
	_lbl_soldiers = _stat_chip(row, "TROPA",  Game.COLOR_BLUE)
	_lbl_heat     = _stat_chip(row, "CALOR",  Game.COLOR_RED)
	_lbl_turn     = _stat_chip(row, "TURNO",  Game.COLOR_MUTED)


func _stat_chip(parent: Node, label: String, accent: Color) -> Label:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	parent.add_child(col)

	var top := Label.new()
	top.text = label
	top.add_theme_font_size_override("font_size", 16)
	top.add_theme_color_override("font_color", Game.COLOR_MUTED)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)

	var val := Label.new()
	val.text = "-"
	val.add_theme_font_size_override("font_size", 30)
	val.add_theme_color_override("font_color", accent)
	val.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(val)
	return val


func _build_map(parent: Node) -> void:
	var card := _card(parent, Game.COLOR_BLUE)

	var header := HBoxContainer.new()
	card.add_child(header)

	var title := Label.new()
	title.text = "QUEBRADA"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Game.COLOR_TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var legend := Label.new()
	legend.text = "● Pó  ● Erva  ● Comp."
	legend.add_theme_font_size_override("font_size", 16)
	legend.add_theme_color_override("font_color", Game.COLOR_MUTED)
	header.add_child(legend)

	var grid := GridContainer.new()
	grid.columns = Game.GRID_W
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(grid)

	for i in range(Game.N_TILES):
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 200)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = false
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 16)
		var tile_id := i
		b.pressed.connect(func(): _on_tile_pressed(tile_id))
		grid.add_child(b)
		_tile_buttons.append(b)


func _build_detail(parent: Node) -> void:
	var card := _card(parent, Game.COLOR_GOLD)

	var title := Label.new()
	title.text = "AÇÕES"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Game.COLOR_TEXT)
	card.add_child(title)

	_detail_panel = VBoxContainer.new()
	_detail_panel.add_theme_constant_override("separation", 10)
	_detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(_detail_panel)


func _build_log(parent: Node) -> void:
	var card := _card(parent, Game.COLOR_PURPLE)

	var title := Label.new()
	title.text = "DIÁRIO DA QUEBRADA"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Game.COLOR_TEXT)
	card.add_child(title)

	_log_container = VBoxContainer.new()
	_log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_container.add_theme_constant_override("separation", 6)
	card.add_child(_log_container)


func _build_footer(parent: Node) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var btn_turn := _wide_button("PASSAR O DIA", Game.COLOR_RED, Game.COLOR_TEXT, Color("ff6b5e"))
	btn_turn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_turn.pressed.connect(func(): Game.end_turn())
	row.add_child(btn_turn)

	var btn_save := _wide_button("SALVAR", Game.COLOR_GOLD, Game.COLOR_BG, Color("fcd34d"))
	btn_save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_save.pressed.connect(_on_save)
	row.add_child(btn_save)

	var btn_menu := _wide_button("MENU", Color("2a2f3a"), Game.COLOR_TEXT, Color("6e7282"))
	btn_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_menu.pressed.connect(_on_menu)
	row.add_child(btn_menu)


# ===========================================================================
# Card com accent colorido na borda esquerda
# ===========================================================================
func _card(parent: Node, accent: Color) -> VBoxContainer:
	# Wrap horizontal: barra de accent à esquerda + panel à direita
	var wrap := HBoxContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_theme_constant_override("separation", 0)
	parent.add_child(wrap)

	var accent_strip := ColorRect.new()
	accent_strip.color = accent
	accent_strip.custom_minimum_size = Vector2(6, 0)
	accent_strip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	accent_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(accent_strip)

	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Game.COLOR_SURFACE
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_right = 12
	sb.border_color = Game.COLOR_BORDER
	sb.border_width_left = 0
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	p.add_theme_stylebox_override("panel", sb)
	wrap.add_child(p)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	return v


func _wide_button(text: String, bg: Color, fg: Color, accent: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 100)
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_disabled_color", Color(fg, 0.4))
	b.add_theme_stylebox_override("normal", _btn_style(bg, accent, 3))
	b.add_theme_stylebox_override("hover",  _btn_style(bg.lightened(0.06), accent, 3))
	b.add_theme_stylebox_override("pressed",_btn_style(bg.darkened(0.18), accent, 3))
	b.add_theme_stylebox_override("disabled",_btn_style(bg.darkened(0.35), accent.darkened(0.3), 2))
	return b


func _btn_style(c: Color, border: Color, w: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.corner_radius_top_left = 12
	s.corner_radius_top_right = 12
	s.corner_radius_bottom_left = 12
	s.corner_radius_bottom_right = 12
	s.border_color = border
	s.border_width_left = w
	s.border_width_right = w
	s.border_width_top = w
	s.border_width_bottom = w
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s


# ===========================================================================
# Refresh
# ===========================================================================
func _refresh_all() -> void:
	_refresh_hud()
	_refresh_map()
	_refresh_detail()
	_refresh_log()


func _refresh_hud() -> void:
	_lbl_cash.text = "R$" + _fmt(Game.cash)
	_lbl_clean.text = "R$" + _fmt(Game.clean)
	_lbl_soldiers.text = str(Game.soldiers)
	_lbl_heat.text = str(Game.heat)
	_lbl_turn.text = str(Game.turn)
	# Cor do calor escala
	var heat_color: Color = Game.COLOR_GREEN
	if Game.heat >= 75:
		heat_color = Game.COLOR_RED
	elif Game.heat >= 50:
		heat_color = Game.COLOR_GOLD
	_lbl_heat.add_theme_color_override("font_color", heat_color)


func _refresh_map() -> void:
	for i in range(Game.N_TILES):
		if i >= _tile_buttons.size():
			continue
		var b: Button = _tile_buttons[i]
		var t = Game.territories[i]
		var owner: String = t.owner
		var product: String = str(t.get("product", "ERVA"))
		var product_color: Color = Game.PRODUCT_INFO.get(product, {}).get("color", Game.COLOR_MUTED)

		var short: String = t.name
		if short.length() > 14:
			short = short.substr(0, 12) + "…"
		var owner_short := _owner_short(owner)
		b.text = "%s\n%s · ⚔%d" % [short, owner_short, int(t.soldiers)]

		# Cor de fundo derivada do dono
		var owner_color: Color = Game.FACTION_COLORS.get(owner, Game.COLOR_ELEVATED)
		var bg_color: Color = owner_color.darkened(0.55)
		if owner == "NEUTRAL":
			bg_color = Game.COLOR_ELEVATED
		# Selecionado: ouro brilhante, senão: cor do produto
		var border: Color = product_color
		var w := 2
		if i == _selected_id:
			border = Game.COLOR_GOLD
			w = 4
		b.add_theme_color_override("font_color", Game.COLOR_TEXT)
		b.add_theme_color_override("font_hover_color", Game.COLOR_TEXT)
		b.add_theme_color_override("font_pressed_color", Game.COLOR_TEXT)
		b.add_theme_stylebox_override("normal",  _tile_style(bg_color, border, w))
		b.add_theme_stylebox_override("hover",   _tile_style(bg_color.lightened(0.06), border, w))
		b.add_theme_stylebox_override("pressed", _tile_style(bg_color.darkened(0.18), border, w))


func _owner_short(owner: String) -> String:
	match owner:
		"PLAYER":  return "VC"
		"NEUTRAL": return "—"
		_: return owner


func _tile_style(bg: Color, border: Color, w: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = 10
	s.corner_radius_top_right = 10
	s.corner_radius_bottom_left = 10
	s.corner_radius_bottom_right = 10
	s.border_color = border
	s.border_width_left = w
	s.border_width_right = w
	s.border_width_top = w
	s.border_width_bottom = w
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s


# ===========================================================================
# Detail panel
# ===========================================================================
func _refresh_detail() -> void:
	for c in _detail_panel.get_children():
		c.queue_free()

	if _selected_id < 0 or _selected_id >= Game.N_TILES:
		var prompt := Label.new()
		prompt.text = "Toque numa boca no mapa pra ver opções."
		prompt.add_theme_font_size_override("font_size", 22)
		prompt.add_theme_color_override("font_color", Game.COLOR_MUTED)
		prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail_panel.add_child(prompt)
		_detail_panel.add_child(_global_actions())
		return

	var t = Game.territories[_selected_id]
	var owner: String = t.owner
	var product: String = str(t.get("product", "ERVA"))
	var pinfo: Dictionary = Game.PRODUCT_INFO.get(product, {})

	var head := Label.new()
	head.text = t.name
	head.add_theme_font_size_override("font_size", 30)
	head.add_theme_color_override("font_color", Game.COLOR_TEXT)
	_detail_panel.add_child(head)

	var info1 := Label.new()
	info1.text = "Dono: %s · Tropa: %d" % [Game.FACTION_NAMES.get(owner, owner), int(t.soldiers)]
	info1.add_theme_font_size_override("font_size", 20)
	info1.add_theme_color_override("font_color", Game.COLOR_MUTED)
	_detail_panel.add_child(info1)

	var info2 := Label.new()
	info2.text = "Produto: %s · Venda: +R$%d · Calor: +%d" % [
		str(pinfo.get("name", "?")),
		Game.tile_income(t),
		Game.tile_risk(t),
	]
	info2.add_theme_font_size_override("font_size", 20)
	info2.add_theme_color_override("font_color", Game.PRODUCT_INFO.get(product, {}).get("color", Game.COLOR_TEXT))
	_detail_panel.add_child(info2)

	# Ação específica do tile
	if owner == "PLAYER":
		var b_sell := _wide_button("VENDER (+R$%d)" % Game.tile_income(t), Game.COLOR_GREEN, Game.COLOR_TEXT, Color("6fd07a"))
		b_sell.pressed.connect(func(): Game.sell_at(_selected_id))
		_detail_panel.add_child(b_sell)
	else:
		var adj := Game.is_adjacent_to_player(_selected_id)
		var label := "INVADIR (precisa %d tropa)" % (int(t.soldiers) + 1) if adj else "FORA DE ALCANCE"
		var color := Game.COLOR_RED if adj else Color("2a2f3a")
		var b_atk := _wide_button(label, color, Game.COLOR_TEXT, Color("ff6b5e") if adj else Color("6e7282"))
		b_atk.disabled = not adj
		b_atk.pressed.connect(func(): Game.attack(_selected_id))
		_detail_panel.add_child(b_atk)

	_detail_panel.add_child(_global_actions())


func _global_actions() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var sep := ColorRect.new()
	sep.color = Game.COLOR_BORDER
	sep.custom_minimum_size = Vector2(0, 1)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(sep)

	var lbl := Label.new()
	lbl.text = "GERAL"
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Game.COLOR_MUTED)
	box.add_child(lbl)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	box.add_child(row1)

	var b_rec := _wide_button("+3 TROPA\nR$%d" % (3 * Game.RECRUIT_COST_EACH), Game.COLOR_BLUE, Game.COLOR_TEXT, Color("5da3f0"))
	b_rec.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_rec.pressed.connect(func(): Game.recruit(3))
	row1.add_child(b_rec)

	var b_bri := _wide_button("SUBORNO\nR$300", Game.COLOR_PURPLE, Game.COLOR_TEXT, Color("c08be3"))
	b_bri.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_bri.pressed.connect(func(): Game.bribe(300))
	row1.add_child(b_bri)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	box.add_child(row2)

	var b_l500 := _wide_button("LAVAR\nR$500", Game.COLOR_GOLD, Game.COLOR_BG, Color("fcd34d"))
	b_l500.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_l500.pressed.connect(func(): Game.launder(500))
	row2.add_child(b_l500)

	var b_l_all := _wide_button("LAVAR\nTUDO", Game.COLOR_ORANGE, Game.COLOR_TEXT, Color("f59e63"))
	b_l_all.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_l_all.pressed.connect(func(): Game.launder(Game.cash))
	row2.add_child(b_l_all)

	return box


# ===========================================================================
# Log estilo notificação (bolinha colorida + texto)
# ===========================================================================
func _refresh_log() -> void:
	for c in _log_container.get_children():
		c.queue_free()
	for entry in Game.event_log:
		_log_container.add_child(_make_log_row(entry))


func _make_log_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Bolinha colorida
	var dot := ColorRect.new()
	dot.color = _tone_color(str(entry.get("tone", "muted")))
	dot.custom_minimum_size = Vector2(10, 10)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Faz a bolinha redonda visualmente (canto arredondado num ColorRect não dá,
	# então uso PanelContainer com StyleBoxFlat circular)
	var dot_wrap := PanelContainer.new()
	var dot_sb := StyleBoxFlat.new()
	dot_sb.bg_color = _tone_color(str(entry.get("tone", "muted")))
	dot_sb.corner_radius_top_left = 8
	dot_sb.corner_radius_top_right = 8
	dot_sb.corner_radius_bottom_left = 8
	dot_sb.corner_radius_bottom_right = 8
	dot_wrap.add_theme_stylebox_override("panel", dot_sb)
	dot_wrap.custom_minimum_size = Vector2(14, 14)
	dot_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(dot_wrap)

	# Coluna texto
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)

	var msg := Label.new()
	msg.text = str(entry.msg)
	msg.add_theme_font_size_override("font_size", 20)
	msg.add_theme_color_override("font_color", Game.COLOR_TEXT)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(msg)

	var meta := Label.new()
	meta.text = "Turno %d" % int(entry.turn)
	meta.add_theme_font_size_override("font_size", 14)
	meta.add_theme_color_override("font_color", Game.COLOR_MUTED)
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(meta)

	return row


func _tone_color(tone: String) -> Color:
	match tone:
		"gold":    return Game.COLOR_GOLD
		"success": return Game.COLOR_GREEN
		"danger":  return Game.COLOR_RED
		"info":    return Game.COLOR_BLUE
		_:         return Game.COLOR_MUTED


func _on_log_event(_msg: String, _tone: String) -> void:
	_refresh_log()


# ===========================================================================
# Eventos UI
# ===========================================================================
func _on_tile_pressed(idx: int) -> void:
	print("[GameScreen] tile pressed: ", idx)
	_selected_id = idx
	_refresh_map()
	_refresh_detail()


func _on_save() -> void:
	var ok := Game.save_game()
	var d := AcceptDialog.new()
	d.dialog_text = "Save gravado." if ok else "Falha ao salvar."
	d.ok_button_text = "Fechar"
	add_child(d)
	d.popup_centered()
	d.confirmed.connect(d.queue_free)


func _on_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)


func _on_game_finished(victory: bool, reason: String) -> void:
	var d := AcceptDialog.new()
	d.title = "DOMÍNIO" if victory else "FIM DE PAPO"
	d.dialog_text = ("Você venceu.\n\n" if victory else "Você foi engolido pela quebrada.\n\n") + reason
	d.ok_button_text = "Voltar ao Menu"
	d.min_size = Vector2(800, 400)
	add_child(d)
	d.popup_centered()
	d.confirmed.connect(_on_menu)


# ===========================================================================
# Util
# ===========================================================================
func _fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "." + out
	if n < 0:
		out = "-" + out
	return out
