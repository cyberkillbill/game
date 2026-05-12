extends Control
## Tela de Diplomacia — listagem das 5 facções rivais com ações.

const MAP_PATH := "res://scenes/map/StrategicMap.tscn"

var _scroll_root: VBoxContainer


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BG_BASE
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	add_child(bg)

	var header := _build_header()
	add_child(header)

	var sc := ScrollContainer.new()
	sc.anchor_left = 0
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

	_scroll_root = VBoxContainer.new()
	_scroll_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_root.add_theme_constant_override("separation", 18)
	margin.add_child(_scroll_root)

	_render_factions()
	GameManager.game_state_changed.connect(_render_factions)


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
	stripe.color = Palette.ACCENT_BLUE
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
	title.text = "Diplomacia"
	title.theme_type_variation = "H2"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(title)
	var sub := Label.new()
	sub.text = "Semana %02d" % GameManager.current_turn
	sub.theme_type_variation = "Mono"
	sub.add_theme_color_override("font_color", Palette.ACCENT_GOLD)
	hb.add_child(sub)
	return c


func _render_factions() -> void:
	if _scroll_root == null:
		return
	for c in _scroll_root.get_children():
		c.queue_free()

	for f in FactionManager.rival_factions():
		_scroll_root.add_child(_make_faction_card(f))


func _make_faction_card(f: Faction) -> Card:
	var card := Card.new()

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	card.add_child(vb)

	# Header da facção
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	vb.add_child(hb)
	var dot := ColorRect.new()
	dot.color = f.color
	dot.custom_minimum_size = Vector2(12, 56)
	hb.add_child(dot)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	hb.add_child(col)
	var name_lbl := Label.new()
	name_lbl.text = f.name
	name_lbl.theme_type_variation = "H3"
	col.add_child(name_lbl)
	var sub := Label.new()
	sub.text = "%s · %s" % [f.short_name, f.specialty]
	sub.theme_type_variation = "Muted"
	col.add_child(sub)

	# Relação como barra
	var rel_label := Label.new()
	rel_label.text = "%s (%d)" % [f.relation_label(), f.relation]
	rel_label.theme_type_variation = "Mono"
	var rel_color := _relation_color(f.relation)
	rel_label.add_theme_color_override("font_color", rel_color)
	hb.add_child(rel_label)

	var bar_bg := ColorRect.new()
	bar_bg.color = Palette.BG_BASE
	bar_bg.custom_minimum_size = Vector2(0, 10)
	vb.add_child(bar_bg)
	var bar_fg := ColorRect.new()
	bar_fg.color = rel_color
	bar_fg.custom_minimum_size = Vector2((f.relation + 100) * 10, 10)
	bar_fg.anchor_left = 0
	bar_bg.add_child(bar_fg)

	var desc := Label.new()
	desc.text = f.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.theme_type_variation = "Body"
	vb.add_child(desc)

	# Territórios da facção
	var ts := FactionManager.territories_of(f.id)
	var ts_label := Label.new()
	var ts_names := []
	for t in ts:
		ts_names.append(t.name)
	ts_label.text = "Controla: %s" % (", ".join(ts_names) if ts_names.size() > 0 else "—")
	ts_label.theme_type_variation = "Muted"
	ts_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(ts_label)

	# Ações
	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 10)
	vb.add_child(row1)

	var truce := PrimaryButton.new()
	truce.text = "Trégua ($1.500)"
	truce.set_variant(PrimaryButton.Variant.GHOST)
	truce.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	truce.disabled = GameManager.capital < 1500
	truce.pressed.connect(func(): FactionManager.offer_truce(f))
	row1.add_child(truce)

	var bribe := PrimaryButton.new()
	bribe.text = "Presente ($2.000)"
	bribe.set_variant(PrimaryButton.Variant.GOLD)
	bribe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bribe.disabled = GameManager.capital < 2000
	bribe.pressed.connect(func(): FactionManager.bribe_faction(f, 2000))
	row1.add_child(bribe)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 10)
	vb.add_child(row2)

	var ally := PrimaryButton.new()
	ally.text = "Aliança ($6.000)"
	ally.set_variant(PrimaryButton.Variant.GOLD)
	ally.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ally.disabled = GameManager.capital < 6000 or f.relation < 40
	ally.pressed.connect(func(): FactionManager.offer_alliance(f))
	row2.add_child(ally)

	var threat := PrimaryButton.new()
	threat.text = "Ameaça"
	threat.set_variant(PrimaryButton.Variant.DANGER)
	threat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	threat.disabled = GameManager.soldiers < 3
	threat.pressed.connect(func(): FactionManager.threaten(f))
	row2.add_child(threat)

	return card


func _relation_color(rel: int) -> Color:
	if rel >= 75: return Palette.ACCENT_GOLD
	if rel >= 30: return Palette.ACCENT_SUCCESS
	if rel >= -10: return Palette.TEXT_SECONDARY
	if rel >= -50: return Color("f59e0b")
	return Palette.ACCENT_DANGER


func _on_back() -> void:
	GameManager.change_scene(MAP_PATH)
