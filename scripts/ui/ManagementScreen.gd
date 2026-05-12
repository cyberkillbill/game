extends Control
## Tela de Gestão — overview do império, lavagem, suborno, recrutamento, inventário.

const MAP_PATH := "res://scenes/map/StrategicMap.tscn"

var _root: VBoxContainer
var _launder_input: SpinBox
var _bribe_input: SpinBox


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BG_BASE
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	add_child(bg)

	add_child(_build_header())

	var sc := ScrollContainer.new()
	sc.anchor_right = 1
	sc.offset_top = 200
	sc.anchor_bottom = 1
	sc.offset_bottom = -40
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 60)
	sc.add_child(margin)

	_root = VBoxContainer.new()
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.add_theme_constant_override("separation", 18)
	margin.add_child(_root)

	_render()
	GameManager.game_state_changed.connect(_render)


func _build_header() -> Control:
	var c := Control.new()
	c.anchor_right = 1
	c.custom_minimum_size = Vector2(0, 180)
	c.offset_bottom = 180

	var bg := ColorRect.new()
	bg.color = Palette.BG_SURFACE
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	c.add_child(bg)

	var stripe := ColorRect.new()
	stripe.color = Palette.ACCENT_GOLD
	stripe.anchor_bottom = 1
	stripe.custom_minimum_size = Vector2(6, 0)
	stripe.offset_right = 6
	c.add_child(stripe)

	var hb := HBoxContainer.new()
	hb.anchor_left = 0
	hb.anchor_right = 1
	hb.offset_left = 30
	hb.offset_right = -30
	hb.offset_top = 60
	hb.add_theme_constant_override("separation", 16)
	c.add_child(hb)
	var back := IconButton.new()
	back.icon_char = "←"
	back.pressed.connect(_on_back)
	hb.add_child(back)
	var title := Label.new()
	title.text = "Gestão"
	title.theme_type_variation = "H2"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(title)
	var auth := Label.new()
	auth.text = HeatManager.authority_label()
	auth.theme_type_variation = "Mono"
	auth.add_theme_color_override("font_color", Palette.ACCENT_DANGER if HeatManager.heat > 40 else Palette.TEXT_SECONDARY)
	hb.add_child(auth)
	return c


func _render() -> void:
	if _root == null:
		return
	for c in _root.get_children():
		c.queue_free()

	# Resumo
	var summary := Card.new()
	_root.add_child(summary)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 8)
	summary.add_child(grid)
	_kv(grid, "Capital sujo", "%s$" % EconomyManager._fmt(GameManager.capital), Palette.ACCENT_GOLD)
	_kv(grid, "Capital limpo", "%s$" % EconomyManager._fmt(GameManager.clean_capital), Palette.ACCENT_SUCCESS)
	_kv(grid, "Soldados", str(GameManager.soldiers), Palette.TEXT_PRIMARY)
	_kv(grid, "Operações ativas", str(_total_ops()), Palette.TEXT_PRIMARY)
	_kv(grid, "Influência", str(GameManager.influence), Palette.ACCENT_BLUE)
	_kv(grid, "Calor / Lealdade", "%d / %d" % [HeatManager.heat, GameManager.loyalty], Palette.ACCENT_DANGER)

	# --- Lavagem ---
	var launder_card := Card.new()
	_root.add_child(launder_card)
	var lvb := VBoxContainer.new()
	lvb.add_theme_constant_override("separation", 10)
	launder_card.add_child(lvb)
	var l_title := Label.new()
	l_title.text = "LAVAGEM DE CAPITAL"
	l_title.theme_type_variation = "Muted"
	lvb.add_child(l_title)
	var l_desc := Label.new()
	l_desc.text = "Taxa de %d%%. Limite de $%s por semana. Lavar gera calor." % [int(EconomyManager.LAUNDER_FEE_PCT * 100), EconomyManager._fmt(EconomyManager.LAUNDER_CAP_PER_TURN)]
	l_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l_desc.theme_type_variation = "Body"
	lvb.add_child(l_desc)
	_launder_input = SpinBox.new()
	_launder_input.min_value = 0
	_launder_input.max_value = mini(GameManager.capital, EconomyManager.LAUNDER_CAP_PER_TURN)
	_launder_input.step = 500
	_launder_input.value = mini(2000, _launder_input.max_value)
	_launder_input.custom_minimum_size = Vector2(0, 72)
	lvb.add_child(_launder_input)
	var l_btn := PrimaryButton.new()
	l_btn.text = "Lavar Capital"
	l_btn.set_variant(PrimaryButton.Variant.GOLD)
	l_btn.disabled = GameManager.capital <= 0
	l_btn.pressed.connect(_on_launder)
	lvb.add_child(l_btn)

	# --- Suborno ---
	var bribe_card := Card.new()
	_root.add_child(bribe_card)
	var bvb := VBoxContainer.new()
	bvb.add_theme_constant_override("separation", 10)
	bribe_card.add_child(bvb)
	var b_title := Label.new()
	b_title.text = "SUBORNAR AUTORIDADES"
	b_title.theme_type_variation = "Muted"
	bvb.add_child(b_title)
	var b_desc := Label.new()
	b_desc.text = "Cada $250 reduz 1 ponto de calor (mín. 1, máx. 20)."
	b_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b_desc.theme_type_variation = "Body"
	bvb.add_child(b_desc)
	_bribe_input = SpinBox.new()
	_bribe_input.min_value = 0
	_bribe_input.max_value = GameManager.capital
	_bribe_input.step = 250
	_bribe_input.value = mini(1500, GameManager.capital)
	_bribe_input.custom_minimum_size = Vector2(0, 72)
	bvb.add_child(_bribe_input)
	var b_btn := PrimaryButton.new()
	b_btn.text = "Pagar Propina"
	b_btn.set_variant(PrimaryButton.Variant.PRIMARY)
	b_btn.disabled = GameManager.capital <= 0 or HeatManager.heat <= 0
	b_btn.pressed.connect(_on_bribe)
	bvb.add_child(b_btn)

	# --- Recrutamento ---
	var rec_card := Card.new()
	_root.add_child(rec_card)
	var rvb := VBoxContainer.new()
	rvb.add_theme_constant_override("separation", 10)
	rec_card.add_child(rvb)
	var r_title := Label.new()
	r_title.text = "RECRUTAMENTO"
	r_title.theme_type_variation = "Muted"
	rvb.add_child(r_title)
	var r_desc := Label.new()
	r_desc.text = "Cada soldado custa $600 inicial e $80 de manutenção semanal."
	r_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r_desc.theme_type_variation = "Body"
	rvb.add_child(r_desc)
	var r_btn := PrimaryButton.new()
	r_btn.text = "Contratar Soldado ($600)"
	r_btn.set_variant(PrimaryButton.Variant.GOLD)
	r_btn.disabled = GameManager.capital < 600
	r_btn.pressed.connect(func(): EconomyManager.recruit_soldier())
	rvb.add_child(r_btn)

	# --- Territórios próprios ---
	var ts := FactionManager.player_territories()
	var t_card := Card.new()
	_root.add_child(t_card)
	var tvb := VBoxContainer.new()
	tvb.add_theme_constant_override("separation", 10)
	t_card.add_child(tvb)
	var t_title := Label.new()
	t_title.text = "SEUS TERRITÓRIOS (%d)" % ts.size()
	t_title.theme_type_variation = "Muted"
	tvb.add_child(t_title)
	if ts.is_empty():
		var empty := Label.new()
		empty.text = "Você ainda não controla nenhum distrito. Conquiste um pelo mapa."
		empty.theme_type_variation = "Body"
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tvb.add_child(empty)
	else:
		for t in ts:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			tvb.add_child(row)
			var n := Label.new()
			n.text = t.name
			n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(n)
			var inc := Label.new()
			inc.text = "+%s$" % EconomyManager._fmt(t.current_income())
			inc.add_theme_color_override("font_color", Palette.ACCENT_GOLD)
			inc.theme_type_variation = "Mono"
			row.add_child(inc)
			var ops := Label.new()
			ops.text = "%d/3 op" % t.operations
			ops.theme_type_variation = "Muted"
			row.add_child(ops)

	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 80)
	_root.add_child(bottom_spacer)


func _kv(grid: GridContainer, k: String, v: String, color: Color) -> void:
	var key := Label.new()
	key.text = k
	key.theme_type_variation = "Muted"
	grid.add_child(key)
	var val := Label.new()
	val.text = v
	val.theme_type_variation = "Mono"
	val.add_theme_color_override("font_color", color)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(val)


func _total_ops() -> int:
	var n := 0
	for t in FactionManager.player_territories():
		n += t.operations
	return n


func _on_launder() -> void:
	var amt := int(_launder_input.value)
	if amt > 0:
		EconomyManager.launder(amt)


func _on_bribe() -> void:
	var amt := int(_bribe_input.value)
	if amt > 0:
		EconomyManager.bribe(amt)


func _on_back() -> void:
	GameManager.change_scene(MAP_PATH)
