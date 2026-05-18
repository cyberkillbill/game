extends Control
## TELA DE JOGO — versão brutalmente minimal.
## HUD em texto + grid 4x4 com botões default + ações em coluna + log em texto.
## Sem cards estilizados, sem accent strips, sem PanelContainers complexos.

const MENU_SCENE := "res://scenes/MainMenu.tscn"

var _selected_id: int = -1
var _tile_buttons: Array = []

var _lbl_hud: Label
var _lbl_detail: Label
var _lbl_log: Label
var _attack_btn: Button
var _sell_btn: Button


func _ready() -> void:
	print("[GAME] _ready iniciado")
	_build()
	Game.state_changed.connect(_refresh)
	Game.log_event.connect(func(_a, _b): _refresh())
	Game.game_finished.connect(_on_game_finished)
	_refresh()
	print("[GAME] _ready terminado")


func _build() -> void:
	# Fundo escuro
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.09)
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	add_child(bg)

	# Tudo dentro de ScrollContainer pra caber em qualquer tela
	var scroll := ScrollContainer.new()
	scroll.anchor_right = 1
	scroll.anchor_bottom = 1
	scroll.offset_left = 20
	scroll.offset_right = -20
	scroll.offset_top = 30
	scroll.offset_bottom = -30
	add_child(scroll)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 20)
	scroll.add_child(col)

	# ===== HUD =====
	_lbl_hud = Label.new()
	_lbl_hud.add_theme_font_size_override("font_size", 28)
	_lbl_hud.add_theme_color_override("font_color", Color.WHITE)
	_lbl_hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_lbl_hud)

	# Separador
	col.add_child(_separator())

	# ===== MAPA 4x4 =====
	var map_title := Label.new()
	map_title.text = "QUEBRADA — toque numa boca"
	map_title.add_theme_font_size_override("font_size", 22)
	map_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	col.add_child(map_title)

	var grid := GridContainer.new()
	grid.columns = Game.GRID_W
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(grid)

	for i in range(Game.N_TILES):
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 170)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 18)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var idx := i
		b.pressed.connect(func(): _on_tile_pressed(idx))
		grid.add_child(b)
		_tile_buttons.append(b)

	# ===== DETALHE BOCA + AÇÕES TILE =====
	col.add_child(_separator())

	_lbl_detail = Label.new()
	_lbl_detail.text = "Selecione uma boca."
	_lbl_detail.add_theme_font_size_override("font_size", 24)
	_lbl_detail.add_theme_color_override("font_color", Color.WHITE)
	_lbl_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_lbl_detail)

	# Linha com VENDER (verde) e INVADIR (vermelho) — mostra ambos sempre,
	# habilita conforme contexto
	var row_tile := HBoxContainer.new()
	row_tile.add_theme_constant_override("separation", 10)
	col.add_child(row_tile)

	_sell_btn = _action_button("VENDER", Color(0.24, 0.64, 0.30))
	_sell_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sell_btn.pressed.connect(func(): if _selected_id >= 0: Game.sell_at(_selected_id))
	row_tile.add_child(_sell_btn)

	_attack_btn = _action_button("INVADIR", Color(0.82, 0.23, 0.17))
	_attack_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attack_btn.pressed.connect(func(): if _selected_id >= 0: Game.attack(_selected_id))
	row_tile.add_child(_attack_btn)

	# ===== AÇÕES GERAIS =====
	col.add_child(_separator())

	var gen_title := Label.new()
	gen_title.text = "AÇÕES GERAIS"
	gen_title.add_theme_font_size_override("font_size", 22)
	gen_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	col.add_child(gen_title)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 10)
	col.add_child(row1)

	var b_rec := _action_button("+3 TROPA\nR$%d" % (3 * Game.RECRUIT_COST_EACH), Color(0.18, 0.49, 0.84))
	b_rec.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_rec.pressed.connect(func(): Game.recruit(3))
	row1.add_child(b_rec)

	var b_bri := _action_button("SUBORNO\nR$300", Color(0.61, 0.35, 0.84))
	b_bri.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_bri.pressed.connect(func(): Game.bribe(300))
	row1.add_child(b_bri)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 10)
	col.add_child(row2)

	var b_l := _action_button("LAVAR\nR$500", Color(0.96, 0.71, 0.0))
	b_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_l.pressed.connect(func(): Game.launder(500))
	row2.add_child(b_l)

	var b_la := _action_button("LAVAR\nTUDO", Color(0.88, 0.48, 0.15))
	b_la.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_la.pressed.connect(func(): Game.launder(Game.cash))
	row2.add_child(b_la)

	# ===== LOG =====
	col.add_child(_separator())

	var log_title := Label.new()
	log_title.text = "DIÁRIO DA QUEBRADA"
	log_title.add_theme_font_size_override("font_size", 22)
	log_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	col.add_child(log_title)

	_lbl_log = Label.new()
	_lbl_log.text = "—"
	_lbl_log.add_theme_font_size_override("font_size", 18)
	_lbl_log.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	_lbl_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_lbl_log)

	# ===== FOOTER =====
	col.add_child(_separator())

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	col.add_child(footer)

	var b_turn := _action_button("PASSAR O DIA", Color(0.82, 0.23, 0.17))
	b_turn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_turn.pressed.connect(func(): Game.end_turn())
	footer.add_child(b_turn)

	var b_save := _action_button("SALVAR", Color(0.96, 0.71, 0.0))
	b_save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_save.pressed.connect(_on_save)
	footer.add_child(b_save)

	var b_menu := _action_button("MENU", Color(0.25, 0.27, 0.32))
	b_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_menu.pressed.connect(_on_menu)
	footer.add_child(b_menu)


# ===========================================================================
func _separator() -> ColorRect:
	var s := ColorRect.new()
	s.color = Color(1, 1, 1, 0.08)
	s.custom_minimum_size = Vector2(0, 2)
	return s


func _action_button(text: String, bg: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 100)
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	b.add_theme_stylebox_override("normal", sb)
	var sb2 := sb.duplicate() as StyleBoxFlat
	sb2.bg_color = bg.lightened(0.08)
	b.add_theme_stylebox_override("hover", sb2)
	var sb3 := sb.duplicate() as StyleBoxFlat
	sb3.bg_color = bg.darkened(0.2)
	b.add_theme_stylebox_override("pressed", sb3)
	var sb4 := sb.duplicate() as StyleBoxFlat
	sb4.bg_color = bg.darkened(0.5)
	b.add_theme_stylebox_override("disabled", sb4)
	return b


# ===========================================================================
# Refresh — atualiza textos a cada mudança de estado
# ===========================================================================
func _refresh() -> void:
	_refresh_hud()
	_refresh_map()
	_refresh_detail()
	_refresh_log()


func _refresh_hud() -> void:
	_lbl_hud.text = "GRANA R$%s   LIMPO R$%s\nTROPA %d   CALOR %d/100   TURNO %d" % [
		_fmt(Game.cash), _fmt(Game.clean),
		Game.soldiers, Game.heat, Game.turn
	]


func _refresh_map() -> void:
	for i in range(Game.N_TILES):
		if i >= _tile_buttons.size():
			continue
		var b: Button = _tile_buttons[i]
		var t = Game.territories[i]
		var owner: String = t.owner
		var product: String = str(t.get("product", "ERVA"))
		var owner_short := "VC" if owner == "PLAYER" else ("—" if owner == "NEUTRAL" else owner)
		var short_name: String = t.name
		if short_name.length() > 13:
			short_name = short_name.substr(0, 11) + "…"
		b.text = "%s\n%s · ⚔%d\n[%s]" % [short_name, owner_short, int(t.soldiers), product]

		# Cor do botão = cor da facção dona
		var bg_color: Color = Color(0.14, 0.16, 0.21)  # neutro
		if owner == "PLAYER":
			bg_color = Color(0.55, 0.4, 0.05)
		elif owner != "NEUTRAL":
			var fc = Game.FACTION_COLORS.get(owner, bg_color)
			bg_color = fc.darkened(0.5)
		# Selecionado: borda dourada (via stylebox)
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg_color
		sb.corner_radius_top_left = 8
		sb.corner_radius_top_right = 8
		sb.corner_radius_bottom_left = 8
		sb.corner_radius_bottom_right = 8
		if i == _selected_id:
			sb.border_color = Color(0.96, 0.71, 0.0)
			sb.border_width_left = 4
			sb.border_width_right = 4
			sb.border_width_top = 4
			sb.border_width_bottom = 4
		b.add_theme_stylebox_override("normal", sb)
		var sb2 := sb.duplicate() as StyleBoxFlat
		sb2.bg_color = bg_color.lightened(0.08)
		b.add_theme_stylebox_override("hover", sb2)
		var sb3 := sb.duplicate() as StyleBoxFlat
		sb3.bg_color = bg_color.darkened(0.2)
		b.add_theme_stylebox_override("pressed", sb3)


func _refresh_detail() -> void:
	if _selected_id < 0 or _selected_id >= Game.N_TILES:
		_lbl_detail.text = "Selecione uma boca no mapa."
		_sell_btn.disabled = true
		_attack_btn.disabled = true
		return
	var t = Game.territories[_selected_id]
	var owner: String = t.owner
	var product: String = str(t.get("product", "ERVA"))
	var pname: String = str(Game.PRODUCT_INFO.get(product, {}).get("name", "?"))
	var income := Game.tile_income(t)
	var risk := Game.tile_risk(t)
	_lbl_detail.text = "%s\nDono: %s · Tropa: %d\nProduto: %s · Venda: +R$%d · Calor: +%d" % [
		t.name,
		Game.FACTION_NAMES.get(owner, owner),
		int(t.soldiers),
		pname, income, risk,
	]
	_sell_btn.disabled = (owner != "PLAYER")
	_attack_btn.disabled = (owner == "PLAYER" or not Game.is_adjacent_to_player(_selected_id))


func _refresh_log() -> void:
	var lines: Array = []
	for entry in Game.event_log:
		lines.append("T%d · %s" % [int(entry.turn), str(entry.msg)])
	_lbl_log.text = "\n".join(lines) if lines.size() > 0 else "—"


# ===========================================================================
func _on_tile_pressed(idx: int) -> void:
	print("[GAME] tile pressionado: ", idx)
	_selected_id = idx
	_refresh()


func _on_save() -> void:
	var ok := Game.save_game()
	var d := AcceptDialog.new()
	d.dialog_text = "Save gravado." if ok else "Falha ao salvar."
	add_child(d)
	d.popup_centered()
	d.confirmed.connect(d.queue_free)


func _on_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)


func _on_game_finished(victory: bool, reason: String) -> void:
	var d := AcceptDialog.new()
	d.title = "DOMÍNIO" if victory else "FIM DE PAPO"
	d.dialog_text = ("Você venceu.\n\n" if victory else "Você foi engolido pela quebrada.\n\n") + reason
	add_child(d)
	d.popup_centered()
	d.confirmed.connect(_on_menu)


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
