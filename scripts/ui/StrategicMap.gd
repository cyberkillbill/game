extends Control
## Mapa Estratégico — HUD + 12 zonas tapáveis + painel lateral + barra inferior.

const DIPLO_PATH := "res://scenes/diplomacy/DiplomacyScreen.tscn"
const MGMT_PATH := "res://scenes/management/ManagementScreen.tscn"
const COMBAT_PATH := "res://scenes/combat/TacticalCombat.tscn"
const CHAR_PATH := "res://scenes/character/CharacterEditor.tscn"
const MENU_PATH := "res://scenes/main_menu/MainMenu.tscn"

const TILE_W := 300
const TILE_H := 220
const TILE_GAP := 30
const MAP_TOP_OFFSET := 420   # após o HUD

var _map_root: Control
var _hud: Control
var _stat_capital: StatBadge
var _stat_clean: StatBadge
var _stat_influence: StatBadge
var _stat_heat: StatBadge
var _stat_loyalty: StatBadge
var _stat_soldiers: StatBadge
var _turn_label: Label
var _phase_label: Label
var _bottom_bar: Control
var _detail_panel: Panel
var _detail_root: Control
var _selected: Territory = null
var _territory_buttons: Dictionary = {}    # id -> Button
var _log_panel: Panel
var _log_visible: bool = false


func _ready() -> void:
	if GameManager.player == null:
		# Veio direto sem passar pelo editor (debug) — cria padrão.
		GameManager.start_new_game(PlayerCharacter.default_char())

	_build_background()
	_build_hud()
	_build_map()
	_build_bottom_bar()
	_build_detail_panel()
	_build_log_panel()

	GameManager.game_state_changed.connect(_refresh)
	GameManager.turn_advanced.connect(_on_turn_advanced)
	GameManager.event_logged.connect(_on_event_logged)
	_refresh()


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BG_BASE
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	add_child(bg)


# ---- HUD -----------------------------------------------------------------

func _build_hud() -> void:
	_hud = Control.new()
	_hud.anchor_right = 1
	_hud.custom_minimum_size = Vector2(0, MAP_TOP_OFFSET - 20)
	_hud.offset_bottom = MAP_TOP_OFFSET - 20
	add_child(_hud)

	var hud_bg := ColorRect.new()
	hud_bg.color = Palette.BG_SURFACE
	hud_bg.anchor_right = 1
	hud_bg.anchor_bottom = 1
	_hud.add_child(hud_bg)

	var stripe := ColorRect.new()
	stripe.color = Palette.ACCENT_PRIMARY
	stripe.anchor_bottom = 1
	stripe.custom_minimum_size = Vector2(6, 0)
	stripe.offset_right = 6
	_hud.add_child(stripe)

	var vbox := VBoxContainer.new()
	vbox.anchor_left = 0
	vbox.anchor_right = 1
	vbox.anchor_top = 0
	vbox.anchor_bottom = 1
	vbox.offset_left = 30
	vbox.offset_right = -30
	vbox.offset_top = 22
	vbox.offset_bottom = -16
	vbox.add_theme_constant_override("separation", 12)
	_hud.add_child(vbox)

	# Linha 1: turno + fase + menu
	var line1 := HBoxContainer.new()
	line1.add_theme_constant_override("separation", 16)
	vbox.add_child(line1)

	var turn_box := VBoxContainer.new()
	turn_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	turn_box.add_theme_constant_override("separation", 2)
	line1.add_child(turn_box)
	var label := Label.new()
	label.text = "SEMANA"
	label.theme_type_variation = "Muted"
	turn_box.add_child(label)
	_turn_label = Label.new()
	_turn_label.text = "01"
	_turn_label.theme_type_variation = "H2"
	_turn_label.add_theme_color_override("font_color", Palette.ACCENT_GOLD)
	turn_box.add_child(_turn_label)

	var phase_box := VBoxContainer.new()
	phase_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phase_box.add_theme_constant_override("separation", 2)
	line1.add_child(phase_box)
	var plabel := Label.new()
	plabel.text = "FASE"
	plabel.theme_type_variation = "Muted"
	phase_box.add_child(plabel)
	_phase_label = Label.new()
	_phase_label.text = "Aguardando"
	_phase_label.theme_type_variation = "H3"
	phase_box.add_child(_phase_label)

	var save_btn := IconButton.new()
	save_btn.icon_char = "💾"
	save_btn.pressed.connect(_on_save)
	line1.add_child(save_btn)

	var log_btn := IconButton.new()
	log_btn.icon_char = "≡"
	log_btn.pressed.connect(_toggle_log)
	line1.add_child(log_btn)

	var home_btn := IconButton.new()
	home_btn.icon_char = "⌂"
	home_btn.pressed.connect(_on_home)
	line1.add_child(home_btn)

	# Linha 2: 3 badges
	var line2 := HBoxContainer.new()
	line2.add_theme_constant_override("separation", 10)
	vbox.add_child(line2)
	_stat_capital = StatBadge.new("CAPITAL", "0$", "$", StatBadge.Tone.GOLD)
	_stat_capital.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line2.add_child(_stat_capital)
	_stat_clean = StatBadge.new("LIMPO", "0$", "✓", StatBadge.Tone.SUCCESS)
	_stat_clean.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line2.add_child(_stat_clean)
	_stat_influence = StatBadge.new("INFLUÊNCIA", "0", "★", StatBadge.Tone.INFO)
	_stat_influence.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line2.add_child(_stat_influence)

	# Linha 3: 3 badges
	var line3 := HBoxContainer.new()
	line3.add_theme_constant_override("separation", 10)
	vbox.add_child(line3)
	_stat_heat = StatBadge.new("CALOR", "0", "⚠", StatBadge.Tone.DANGER)
	_stat_heat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line3.add_child(_stat_heat)
	_stat_loyalty = StatBadge.new("LEALDADE", "0", "♥", StatBadge.Tone.NEUTRAL)
	_stat_loyalty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line3.add_child(_stat_loyalty)
	_stat_soldiers = StatBadge.new("TROPA", "0", "▲", StatBadge.Tone.INFO)
	_stat_soldiers.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line3.add_child(_stat_soldiers)


# ---- Map ----------------------------------------------------------------

func _build_map() -> void:
	_map_root = Control.new()
	_map_root.anchor_right = 1
	_map_root.offset_top = MAP_TOP_OFFSET
	_map_root.offset_bottom = -260
	_map_root.anchor_bottom = 1
	add_child(_map_root)

	var title := Label.new()
	title.text = "PORTO SANTIAGO"
	title.theme_type_variation = "Muted"
	title.add_theme_font_size_override("font_size", 22)
	title.position = Vector2(40, 8)
	_map_root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "12 distritos · 5 facções rivais"
	subtitle.theme_type_variation = "Muted"
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.position = Vector2(40, 36)
	_map_root.add_child(subtitle)

	# Posiciona os 12 territórios em grid 3x4
	var col_x := [40, 40 + TILE_W + TILE_GAP, 40 + (TILE_W + TILE_GAP) * 2]
	var row_y := [90, 90 + TILE_H + TILE_GAP, 90 + (TILE_H + TILE_GAP) * 2, 90 + (TILE_H + TILE_GAP) * 3]

	var territories := FactionManager.territories.values()
	for i in territories.size():
		var t: Territory = territories[i]
		var col := i % 3
		var row := i / 3
		var btn := _make_territory_card(t)
		btn.position = Vector2(col_x[col], row_y[row])
		btn.custom_minimum_size = Vector2(TILE_W, TILE_H)
		btn.size = Vector2(TILE_W, TILE_H)
		_map_root.add_child(btn)
		_territory_buttons[t.id] = btn


func _make_territory_card(t: Territory) -> Button:
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(_on_territory_pressed.bind(t))
	_style_territory_button(btn, t, false)

	# Conteúdo do card
	var vb := VBoxContainer.new()
	vb.anchor_left = 0
	vb.anchor_top = 0
	vb.anchor_right = 1
	vb.anchor_bottom = 1
	vb.offset_left = 18
	vb.offset_right = -18
	vb.offset_top = 16
	vb.offset_bottom = -16
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 4)
	btn.add_child(vb)

	var owner_dot := ColorRect.new()
	owner_dot.color = FactionManager.faction_color(t.owner_id)
	owner_dot.custom_minimum_size = Vector2(40, 6)
	vb.add_child(owner_dot)

	var name_lbl := Label.new()
	name_lbl.text = t.name
	name_lbl.add_theme_font_size_override("font_size", 28)
	name_lbl.add_theme_color_override("font_color", Palette.TEXT_PRIMARY)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(name_lbl)

	var profile_lbl := Label.new()
	profile_lbl.text = t.profile_label()
	profile_lbl.theme_type_variation = "Muted"
	profile_lbl.add_theme_font_size_override("font_size", 18)
	vb.add_child(profile_lbl)

	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sp)

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 12)
	vb.add_child(stats_row)
	var inc := Label.new()
	inc.text = "$ " + str(t.current_income())
	inc.add_theme_font_size_override("font_size", 20)
	inc.add_theme_color_override("font_color", Palette.ACCENT_GOLD)
	stats_row.add_child(inc)
	var heat := Label.new()
	heat.text = "⚠ " + str(t.current_heat())
	heat.add_theme_font_size_override("font_size", 20)
	heat.add_theme_color_override("font_color", Palette.ACCENT_DANGER)
	stats_row.add_child(heat)

	var ops_box := HBoxContainer.new()
	ops_box.add_theme_constant_override("separation", 4)
	ops_box.alignment = BoxContainer.ALIGNMENT_END
	stats_row.add_child(ops_box)
	ops_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in 3:
		var dot := ColorRect.new()
		dot.color = Palette.ACCENT_GOLD if i < t.operations else Palette.BG_BASE
		dot.custom_minimum_size = Vector2(10, 10)
		ops_box.add_child(dot)

	return btn


func _style_territory_button(btn: Button, t: Territory, selected: bool) -> void:
	var owner_color := FactionManager.faction_color(t.owner_id)
	var bg := Palette.BG_SURFACE
	if t.owner_id == FactionManager.PLAYER_ID:
		bg = Palette.BG_ELEVATED

	var make_sb := func(b: Color, border: Color, border_w: int) -> StyleBoxFlat:
		var sb := StyleBoxFlat.new()
		sb.bg_color = b
		sb.corner_radius_top_left = 14
		sb.corner_radius_top_right = 14
		sb.corner_radius_bottom_left = 14
		sb.corner_radius_bottom_right = 14
		sb.border_color = border
		sb.border_width_left = border_w
		sb.border_width_right = border_w
		sb.border_width_top = border_w
		sb.border_width_bottom = border_w
		sb.content_margin_left = 0
		sb.content_margin_right = 0
		sb.content_margin_top = 0
		sb.content_margin_bottom = 0
		if selected:
			sb.shadow_size = 14
			sb.shadow_color = Color(border, 0.6)
		return sb

	var border_w := 3 if selected else 1
	var border_color := owner_color if selected else Palette.BORDER_SUBTLE
	btn.add_theme_stylebox_override("normal", make_sb.call(bg, border_color, border_w))
	btn.add_theme_stylebox_override("hover", make_sb.call(bg.lightened(0.05), owner_color, border_w))
	btn.add_theme_stylebox_override("pressed", make_sb.call(bg.darkened(0.1), owner_color, border_w))


# ---- Bottom bar ---------------------------------------------------------

func _build_bottom_bar() -> void:
	_bottom_bar = Control.new()
	_bottom_bar.anchor_left = 0
	_bottom_bar.anchor_right = 1
	_bottom_bar.anchor_top = 1
	_bottom_bar.anchor_bottom = 1
	_bottom_bar.offset_top = -240
	add_child(_bottom_bar)

	var bg := ColorRect.new()
	bg.color = Palette.BG_SURFACE
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	_bottom_bar.add_child(bg)

	var stripe := ColorRect.new()
	stripe.color = Palette.ACCENT_GOLD
	stripe.anchor_right = 1
	stripe.custom_minimum_size = Vector2(0, 3)
	stripe.offset_bottom = 3
	_bottom_bar.add_child(stripe)

	var vb := VBoxContainer.new()
	vb.anchor_left = 0
	vb.anchor_right = 1
	vb.offset_top = 24
	vb.offset_left = 30
	vb.offset_right = -30
	vb.anchor_bottom = 1
	vb.offset_bottom = -24
	vb.add_theme_constant_override("separation", 16)
	_bottom_bar.add_child(vb)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vb.add_child(row)

	var b_diplo := PrimaryButton.new()
	b_diplo.text = "Diplomacia"
	b_diplo.set_variant(PrimaryButton.Variant.GHOST)
	b_diplo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_diplo.pressed.connect(func(): GameManager.change_scene(DIPLO_PATH))
	row.add_child(b_diplo)

	var b_mgmt := PrimaryButton.new()
	b_mgmt.text = "Gestão"
	b_mgmt.set_variant(PrimaryButton.Variant.GHOST)
	b_mgmt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_mgmt.pressed.connect(func(): GameManager.change_scene(MGMT_PATH))
	row.add_child(b_mgmt)

	var b_char := PrimaryButton.new()
	b_char.text = "Perfil"
	b_char.set_variant(PrimaryButton.Variant.GHOST)
	b_char.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_char.pressed.connect(func(): GameManager.change_scene(CHAR_PATH))
	row.add_child(b_char)

	var b_end := PrimaryButton.new()
	b_end.text = "Encerrar Semana →"
	b_end.set_variant(PrimaryButton.Variant.PRIMARY)
	b_end.pressed.connect(_on_end_turn)
	vb.add_child(b_end)


# ---- Detail side panel --------------------------------------------------

func _build_detail_panel() -> void:
	_detail_panel = Panel.new()
	_detail_panel.anchor_left = 0
	_detail_panel.anchor_right = 1
	_detail_panel.anchor_top = 1
	_detail_panel.offset_top = 0   # começa escondido (abaixo da tela)
	_detail_panel.offset_bottom = 0
	_detail_panel.visible = false

	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.BG_ELEVATED
	sb.corner_radius_top_left = 20
	sb.corner_radius_top_right = 20
	sb.shadow_size = 24
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.border_width_top = 2
	sb.border_color = Palette.ACCENT_GOLD
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	_detail_panel.add_theme_stylebox_override("panel", sb)

	add_child(_detail_panel)


func _show_detail(t: Territory) -> void:
	_selected = t
	for id in _territory_buttons:
		var b: Button = _territory_buttons[id]
		_style_territory_button(b, FactionManager.get_territory(id), id == t.id)

	for c in _detail_panel.get_children():
		c.queue_free()

	_detail_panel.visible = true
	_detail_panel.size = Vector2(get_viewport_rect().size.x, 880)
	_detail_panel.position = Vector2(0, get_viewport_rect().size.y - 880)

	var vb := VBoxContainer.new()
	vb.anchor_right = 1
	vb.anchor_bottom = 1
	vb.add_theme_constant_override("separation", 14)
	_detail_panel.add_child(vb)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vb.add_child(header)

	var dot := ColorRect.new()
	dot.color = FactionManager.faction_color(t.owner_id)
	dot.custom_minimum_size = Vector2(16, 56)
	header.add_child(dot)

	var hcol := VBoxContainer.new()
	hcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hcol.add_theme_constant_override("separation", 2)
	header.add_child(hcol)
	var name := Label.new()
	name.text = t.name
	name.theme_type_variation = "H2"
	hcol.add_child(name)
	var sub := Label.new()
	var owner_label := "Você" if t.owner_id == FactionManager.PLAYER_ID else (FactionManager.get_faction(t.owner_id).short_name if FactionManager.get_faction(t.owner_id) else "Neutra")
	sub.text = "%s · %s" % [t.profile_label(), owner_label]
	sub.theme_type_variation = "Muted"
	hcol.add_child(sub)

	var close := IconButton.new()
	close.icon_char = "×"
	close.pressed.connect(_hide_detail)
	header.add_child(close)

	# Stats grid
	var stats := GridContainer.new()
	stats.columns = 3
	stats.add_theme_constant_override("h_separation", 12)
	stats.add_theme_constant_override("v_separation", 12)
	vb.add_child(stats)
	stats.add_child(_mini_stat("Renda", "%s$" % EconomyManager._fmt(t.current_income()), Palette.ACCENT_GOLD))
	stats.add_child(_mini_stat("Calor base", str(t.current_heat()), Palette.ACCENT_DANGER))
	stats.add_child(_mini_stat("Operações", "%d / 3" % t.operations, Palette.TEXT_PRIMARY))

	# Ações disponíveis
	var actions_label := Label.new()
	actions_label.text = "AÇÕES"
	actions_label.theme_type_variation = "Muted"
	actions_label.add_theme_font_size_override("font_size", 20)
	vb.add_child(actions_label)

	if t.owner_id == FactionManager.PLAYER_ID:
		var inst := PrimaryButton.new()
		inst.text = "Instalar Operação ($2.500)"
		inst.set_variant(PrimaryButton.Variant.GOLD)
		inst.disabled = t.operations >= 3 or GameManager.capital < 2500
		inst.pressed.connect(func(): if EconomyManager.install_operation(t): _show_detail(t))
		vb.add_child(inst)

		var fortify := PrimaryButton.new()
		fortify.text = "Reforçar Defesa (+1 defensor)"
		fortify.set_variant(PrimaryButton.Variant.GHOST)
		fortify.disabled = GameManager.soldiers <= 0
		fortify.pressed.connect(func():
			if GameManager.soldiers > 0:
				GameManager.soldiers -= 1
				t.defenders += 1
				GameManager.log_event("%s reforçada (+1 defensor)." % t.name, StatBadge.Tone.SUCCESS)
				GameManager.game_state_changed.emit()
				_show_detail(t))
		vb.add_child(fortify)
	else:
		var attack := PrimaryButton.new()
		attack.text = "Atacar %s" % t.name
		attack.set_variant(PrimaryButton.Variant.PRIMARY)
		attack.disabled = GameManager.soldiers < 2
		attack.pressed.connect(_on_attack.bind(t))
		vb.add_child(attack)

		var diplo := PrimaryButton.new()
		diplo.text = "Ir para Diplomacia"
		diplo.set_variant(PrimaryButton.Variant.GHOST)
		diplo.pressed.connect(func(): GameManager.change_scene(DIPLO_PATH))
		vb.add_child(diplo)


func _hide_detail() -> void:
	_detail_panel.visible = false
	if _selected:
		var prev_id := _selected.id
		_selected = null
		var b: Button = _territory_buttons.get(prev_id)
		if b:
			_style_territory_button(b, FactionManager.get_territory(prev_id), false)


func _mini_stat(label: String, value: String, value_color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.BG_SURFACE
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.border_color = Palette.BORDER_SUBTLE
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(220, 80)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	p.add_child(vb)
	var l := Label.new()
	l.text = label
	l.theme_type_variation = "Muted"
	l.add_theme_font_size_override("font_size", 18)
	vb.add_child(l)
	var v := Label.new()
	v.text = value
	v.add_theme_font_size_override("font_size", 26)
	v.add_theme_color_override("font_color", value_color)
	vb.add_child(v)
	return p


# ---- Event log ----------------------------------------------------------

func _build_log_panel() -> void:
	_log_panel = Panel.new()
	_log_panel.anchor_left = 0
	_log_panel.anchor_right = 1
	_log_panel.anchor_top = 0
	_log_panel.anchor_bottom = 1
	_log_panel.visible = false

	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.BG_OVERLAY
	_log_panel.add_theme_stylebox_override("panel", sb)
	add_child(_log_panel)


func _toggle_log() -> void:
	_log_visible = not _log_visible
	_log_panel.visible = _log_visible
	if _log_visible:
		_render_log()


func _render_log() -> void:
	for c in _log_panel.get_children():
		c.queue_free()

	var vb := VBoxContainer.new()
	vb.anchor_left = 0
	vb.anchor_right = 1
	vb.offset_left = 40
	vb.offset_right = -40
	vb.offset_top = 120
	vb.offset_bottom = -120
	vb.anchor_bottom = 1
	vb.add_theme_constant_override("separation", 14)
	_log_panel.add_child(vb)

	var header := HBoxContainer.new()
	vb.add_child(header)
	var title := Label.new()
	title.text = "Diário"
	title.theme_type_variation = "H2"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := IconButton.new()
	close.icon_char = "×"
	close.pressed.connect(_toggle_log)
	header.add_child(close)

	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sc)
	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 10)
	sc.add_child(inner)

	if GameManager.event_log.is_empty():
		var empty := Label.new()
		empty.text = "Sem eventos ainda. Encerre a primeira semana."
		empty.theme_type_variation = "Muted"
		inner.add_child(empty)
		return

	for ev in GameManager.event_log:
		var card := Card.new()
		inner.add_child(card)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 14)
		card.add_child(hb)
		var dot := ColorRect.new()
		dot.color = _tone_color(ev.get("tone", 0))
		dot.custom_minimum_size = Vector2(8, 8)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(dot)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(col)
		var t := Label.new()
		t.text = "Semana %02d" % ev.get("turn", 0)
		t.theme_type_variation = "Muted"
		col.add_child(t)
		var m := Label.new()
		m.text = ev.get("msg", "")
		m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(m)


func _tone_color(tone: int) -> Color:
	match tone:
		StatBadge.Tone.GOLD:    return Palette.ACCENT_GOLD
		StatBadge.Tone.DANGER:  return Palette.ACCENT_DANGER
		StatBadge.Tone.SUCCESS: return Palette.ACCENT_SUCCESS
		StatBadge.Tone.INFO:    return Palette.ACCENT_BLUE
		_:                      return Palette.TEXT_SECONDARY


# ---- Refresh / events ---------------------------------------------------

func _refresh() -> void:
	_turn_label.text = "%02d" % GameManager.current_turn
	_phase_label.text = _phase_label_text()
	_stat_capital.set_value("%s$" % EconomyManager._fmt(GameManager.capital))
	_stat_clean.set_value("%s$" % EconomyManager._fmt(GameManager.clean_capital))
	_stat_influence.set_value(str(GameManager.influence))
	_stat_heat.set_value(str(HeatManager.heat))
	_stat_heat.set_tone(StatBadge.Tone.DANGER if HeatManager.heat >= 50 else StatBadge.Tone.NEUTRAL)
	_stat_loyalty.set_value(str(GameManager.loyalty))
	_stat_soldiers.set_value(str(GameManager.soldiers))

	# Atualiza visuais dos cartões de território (cores podem ter mudado).
	for id in _territory_buttons:
		var t: Territory = FactionManager.get_territory(id)
		var btn: Button = _territory_buttons[id]
		var is_sel := _selected != null and _selected.id == id
		_style_territory_button(btn, t, is_sel)


func _phase_label_text() -> String:
	match GameManager.current_phase:
		GameManager.Phase.ECONOMY:     return "Econômica"
		GameManager.Phase.RECRUIT:     return "Recrutamento"
		GameManager.Phase.DIPLOMACY:   return "Diplomática"
		GameManager.Phase.TACTICAL:    return "Tática"
		GameManager.Phase.MAINTENANCE: return "Manutenção"
		_:                             return "—"


func _on_event_logged(_msg: String, _tone: int) -> void:
	if _log_visible:
		_render_log()


func _on_turn_advanced(_t: int) -> void:
	# Toast leve no topo do mapa
	var toast := Label.new()
	toast.text = "Semana %02d" % GameManager.current_turn
	toast.theme_type_variation = "H3"
	toast.add_theme_color_override("font_color", Palette.ACCENT_GOLD)
	toast.position = Vector2(get_viewport_rect().size.x / 2 - 100, MAP_TOP_OFFSET + 10)
	add_child(toast)
	var tw := create_tween()
	tw.tween_property(toast, "modulate:a", 0.0, 1.6).set_delay(0.6)
	tw.tween_callback(toast.queue_free)


# ---- Actions ------------------------------------------------------------

func _on_territory_pressed(t: Territory) -> void:
	_show_detail(t)


func _on_attack(t: Territory) -> void:
	# Vai pro combate tático com payload do alvo.
	GameManager.set_meta("combat_target", t.id)
	GameManager.change_scene(COMBAT_PATH)


func _on_end_turn() -> void:
	_hide_detail()
	GameManager.end_turn()


func _on_save() -> void:
	if SaveManager.save_game():
		var t := Label.new()
		t.text = "✓ Jogo salvo"
		t.add_theme_color_override("font_color", Palette.ACCENT_SUCCESS)
		t.theme_type_variation = "H3"
		t.position = Vector2(get_viewport_rect().size.x / 2 - 120, 30)
		add_child(t)
		var tw := create_tween()
		tw.tween_property(t, "modulate:a", 0.0, 1.5).set_delay(0.5)
		tw.tween_callback(t.queue_free)


func _on_home() -> void:
	GameManager.change_scene(MENU_PATH)
