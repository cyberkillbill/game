extends Control
## Tela de jogo: HUD + mapa 4x4 + painel de ações + log.
## Toda a UI é construída em código pra evitar dependência de .tscn quebrada.

const MENU_SCENE := "res://scenes/MainMenu.tscn"

var _hud: HBoxContainer
var _grid_container: GridContainer
var _detail_panel: VBoxContainer
var _log_container: VBoxContainer
var _selected_id: int = -1
var _tile_buttons: Array = []   # Array[Button], len 16

# --- Refs HUD ---
var _lbl_cash: Label
var _lbl_clean: Label
var _lbl_soldiers: Label
var _lbl_heat: Label
var _lbl_turn: Label


func _ready() -> void:
	print("[GameScreen] _ready · player=%s · tiles=%d" % [Game.player_name, Game.territories.size()])
	_build_ui()
	Game.state_changed.connect(_refresh_all)
	Game.log_event.connect(_on_log_event)
	Game.game_finished.connect(_on_game_finished)
	_refresh_all()


# ===========================================================================
# Build
# ===========================================================================
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Game.COLOR_BG
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root := VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 16
	root.offset_right = -16
	root.offset_top = 24
	root.offset_bottom = -24
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	_build_hud(root)
	_build_map(root)
	_build_detail(root)
	_build_log(root)
	_build_footer(root)


func _build_hud(parent: Node) -> void:
	var card := _card(parent)

	_hud = HBoxContainer.new()
	_hud.add_theme_constant_override("separation", 10)
	card.add_child(_hud)

	_lbl_cash = _hud_chip("R$", Game.COLOR_GOLD)
	_lbl_clean = _hud_chip("LIMPO", Game.COLOR_GREEN)
	_lbl_soldiers = _hud_chip("TROPA", Game.COLOR_BLUE)
	_lbl_heat = _hud_chip("CALOR", Game.COLOR_RED)
	_lbl_turn = _hud_chip("TURNO", Game.COLOR_ELEVATED)


func _hud_chip(label_text: String, accent: Color) -> Label:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	_hud.add_child(col)

	var top := Label.new()
	top.text = label_text
	top.add_theme_font_size_override("font_size", 18)
	top.add_theme_color_override("font_color", Game.COLOR_MUTED)
	col.add_child(top)

	var val := Label.new()
	val.text = "-"
	val.add_theme_font_size_override("font_size", 28)
	val.add_theme_color_override("font_color", accent)
	col.add_child(val)
	return val


func _build_map(parent: Node) -> void:
	var wrap := _card(parent)

	var title := Label.new()
	title.text = "MAPA · " + Game.player_name.to_upper()
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Game.COLOR_MUTED)
	wrap.add_child(title)

	_grid_container = GridContainer.new()
	_grid_container.columns = Game.GRID_W
	_grid_container.add_theme_constant_override("h_separation", 6)
	_grid_container.add_theme_constant_override("v_separation", 6)
	_grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_child(_grid_container)

	for i in range(Game.N_TILES):
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 200)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 18)
		b.add_theme_color_override("font_color", Game.COLOR_TEXT)
		b.add_theme_color_override("font_hover_color", Game.COLOR_TEXT)
		b.add_theme_color_override("font_pressed_color", Game.COLOR_TEXT)
		var tile_id := i
		b.pressed.connect(func(): _on_tile_pressed(tile_id))
		_grid_container.add_child(b)
		_tile_buttons.append(b)


func _build_detail(parent: Node) -> void:
	var card := _card(parent)

	var title := Label.new()
	title.text = "AÇÕES"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Game.COLOR_MUTED)
	card.add_child(title)

	_detail_panel = VBoxContainer.new()
	_detail_panel.add_theme_constant_override("separation", 8)
	card.add_child(_detail_panel)


func _build_log(parent: Node) -> void:
	var card := _card(parent)

	var title := Label.new()
	title.text = "DIÁRIO"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Game.COLOR_MUTED)
	card.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 320)
	card.add_child(scroll)

	_log_container = VBoxContainer.new()
	_log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_container.add_theme_constant_override("separation", 4)
	scroll.add_child(_log_container)


func _build_footer(parent: Node) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var btn_turn := _wide_button("PASSAR O DIA", Game.COLOR_RED, Game.COLOR_TEXT)
	btn_turn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_turn.pressed.connect(_on_end_turn)
	row.add_child(btn_turn)

	var btn_save := _wide_button("SALVAR", Game.COLOR_GOLD, Game.COLOR_BG)
	btn_save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_save.pressed.connect(_on_save)
	row.add_child(btn_save)

	var btn_menu := _wide_button("MENU", Game.COLOR_ELEVATED, Game.COLOR_TEXT)
	btn_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_menu.pressed.connect(_on_menu)
	row.add_child(btn_menu)


# ===========================================================================
# UI helpers
# ===========================================================================
func _card(parent: Node) -> VBoxContainer:
	# Cria um PanelContainer estilizado (a "caixinha") como filho de `parent`,
	# e retorna um VBoxContainer interno onde o chamador adiciona o conteúdo.
	# PanelContainer só aceita 1 filho, então o VBox centraliza a lista.
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Game.COLOR_SURFACE
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = 14
	sb.corner_radius_bottom_right = 14
	sb.border_color = Game.COLOR_BORDER
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	return v


func _wide_button(text: String, bg: Color, fg: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 100)
	b.add_theme_font_size_override("font_size", 30)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", _btn_style(bg))
	b.add_theme_stylebox_override("hover", _btn_style(bg.lightened(0.08)))
	b.add_theme_stylebox_override("pressed", _btn_style(bg.darkened(0.15)))
	b.add_theme_stylebox_override("disabled", _btn_style(Game.COLOR_ELEVATED.darkened(0.3)))
	return b


func _btn_style(c: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.corner_radius_top_left = 10
	s.corner_radius_top_right = 10
	s.corner_radius_bottom_left = 10
	s.corner_radius_bottom_right = 10
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 14
	s.content_margin_bottom = 14
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
	_lbl_cash.text = "R$ " + _fmt(Game.cash)
	_lbl_clean.text = "R$ " + _fmt(Game.clean)
	_lbl_soldiers.text = str(Game.soldiers)
	_lbl_heat.text = str(Game.heat) + "/100"
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
		var owner_color: Color = Game.FACTION_COLORS.get(owner, Game.COLOR_MUTED)
		# Texto: nome curto + soldados
		var short_name: String = t.name
		if short_name.length() > 16:
			short_name = short_name.substr(0, 14) + "…"
		b.text = "%s\n[%d]" % [short_name, int(t.soldiers)]
		# Estilo baseado no dono
		var bg_color: Color = owner_color.darkened(0.45)
		if owner == "PLAYER":
			bg_color = Game.COLOR_GOLD.darkened(0.55)
		elif owner == "NEUTRAL":
			bg_color = Game.COLOR_ELEVATED
		var border := Game.COLOR_BORDER
		if i == _selected_id:
			border = Game.COLOR_GOLD
		b.add_theme_stylebox_override("normal", _tile_style(bg_color, border, 1))
		b.add_theme_stylebox_override("hover", _tile_style(bg_color.lightened(0.08), border, 2))
		b.add_theme_stylebox_override("pressed", _tile_style(bg_color.darkened(0.15), border, 2))


func _tile_style(bg: Color, border: Color, border_w: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	s.border_color = border
	s.border_width_left = border_w
	s.border_width_right = border_w
	s.border_width_top = border_w
	s.border_width_bottom = border_w
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


func _refresh_detail() -> void:
	# Limpa
	for c in _detail_panel.get_children():
		c.queue_free()

	if _selected_id < 0 or _selected_id >= Game.N_TILES:
		var prompt := Label.new()
		prompt.text = "Selecione uma boca no mapa pra ver opções."
		prompt.add_theme_font_size_override("font_size", 22)
		prompt.add_theme_color_override("font_color", Game.COLOR_MUTED)
		prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail_panel.add_child(prompt)
		_detail_panel.add_child(_global_actions_row())
		return

	var t = Game.territories[_selected_id]
	var owner: String = t.owner
	var head := Label.new()
	head.text = t.name
	head.add_theme_font_size_override("font_size", 30)
	head.add_theme_color_override("font_color", Game.COLOR_TEXT)
	_detail_panel.add_child(head)

	var info := Label.new()
	info.text = "Dono: %s · Tropa: %d · Lucro/venda: R$%d · Calor/venda: %d" % [
		Game.FACTION_NAMES.get(owner, owner), int(t.soldiers), int(t.income), int(t.risk)
	]
	info.add_theme_font_size_override("font_size", 20)
	info.add_theme_color_override("font_color", Game.COLOR_MUTED)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_panel.add_child(info)

	# Ações específicas do tile
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_detail_panel.add_child(row)

	if owner == "PLAYER":
		var b_sell := _wide_button("VENDER (+R$%d)" % int(t.income), Game.COLOR_GREEN, Game.COLOR_TEXT)
		b_sell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b_sell.pressed.connect(func(): Game.sell_at(_selected_id))
		row.add_child(b_sell)
	else:
		var label_atk := "TOMAR BOCA"
		if Game.is_adjacent_to_player(_selected_id):
			label_atk = "INVADIR (tropa %d)" % int(t.soldiers)
		else:
			label_atk = "FORA DE ALCANCE"
		var b_atk := _wide_button(label_atk, Game.COLOR_RED, Game.COLOR_TEXT)
		b_atk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b_atk.disabled = not Game.is_adjacent_to_player(_selected_id)
		b_atk.pressed.connect(func(): Game.attack(_selected_id))
		row.add_child(b_atk)

	_detail_panel.add_child(_global_actions_row())


func _global_actions_row() -> Control:
	# Linha de ações globais (recrutar, subornar, lavar)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var sep := ColorRect.new()
	sep.color = Game.COLOR_BORDER
	sep.custom_minimum_size = Vector2(0, 1)
	box.add_child(sep)

	var lbl := Label.new()
	lbl.text = "Geral"
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Game.COLOR_MUTED)
	box.add_child(lbl)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	box.add_child(row1)

	var b_rec := _wide_button("+3 TROPA (R$%d)" % (3 * Game.RECRUIT_COST_EACH), Game.COLOR_BLUE, Game.COLOR_TEXT)
	b_rec.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_rec.pressed.connect(func(): Game.recruit(3))
	row1.add_child(b_rec)

	var b_bri := _wide_button("SUBORNO (R$300)", Game.COLOR_PURPLE, Game.COLOR_TEXT)
	b_bri.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_bri.pressed.connect(func(): Game.bribe(300))
	row1.add_child(b_bri)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	box.add_child(row2)

	var b_l500 := _wide_button("LAVAR R$500", Game.COLOR_GOLD, Game.COLOR_BG)
	b_l500.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_l500.pressed.connect(func(): Game.launder(500))
	row2.add_child(b_l500)

	var b_l_all := _wide_button("LAVAR TUDO", Game.COLOR_ORANGE, Game.COLOR_TEXT)
	b_l_all.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_l_all.pressed.connect(func(): Game.launder(Game.cash))
	row2.add_child(b_l_all)

	return box


func _refresh_log() -> void:
	for c in _log_container.get_children():
		c.queue_free()
	for entry in Game.event_log:
		var ln := Label.new()
		ln.text = "T%d · %s" % [int(entry.turn), str(entry.msg)]
		ln.add_theme_font_size_override("font_size", 20)
		ln.add_theme_color_override("font_color", _tone_color(str(entry.get("tone", "muted"))))
		ln.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_log_container.add_child(ln)


func _tone_color(tone: String) -> Color:
	match tone:
		"gold": return Game.COLOR_GOLD
		"success": return Game.COLOR_GREEN
		"danger": return Game.COLOR_RED
		"info": return Game.COLOR_BLUE
		_: return Game.COLOR_MUTED


func _on_log_event(_msg: String, _tone: String) -> void:
	_refresh_log()


# ===========================================================================
# Eventos
# ===========================================================================
func _on_tile_pressed(idx: int) -> void:
	_selected_id = idx
	_refresh_map()
	_refresh_detail()


func _on_end_turn() -> void:
	Game.end_turn()


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
	d.title = "FIM DE PAPO" if not victory else "DOMÍNIO"
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
	# 1234567 -> "1.234.567"
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
