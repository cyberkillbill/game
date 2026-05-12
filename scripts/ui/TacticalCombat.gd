extends Control
## Combate tático em grid 8x8 — XCOM lite simplificado.
##
## Fluxo: jogador seleciona unidade -> tile destacado mostra alcance de movimento (azul)
## e alvos (vermelho). Tap em tile vazio = mover (gasta 1 AP). Tap em inimigo = atacar.
## "Encerrar Turno" passa pra IA inimiga (move e ataca aleatoriamente o mais próximo).

const MAP_PATH := "res://scenes/map/StrategicMap.tscn"

const GRID_SIZE := 8
var TILE_PX := 110

enum Turn { PLAYER, ENEMY, RESOLVED }

var _target_territory: Territory = null
var _defender_id: StringName = &""

var _units: Array[CombatUnit] = []
var _selected: CombatUnit = null
var _turn: Turn = Turn.PLAYER
var _player_turn_count: int = 1

var _grid_root: Control
var _tile_buttons: Array = []   # [row][col] = Button
var _log_label: Label
var _status_label: Label
var _hud: Control
var _end_btn: PrimaryButton


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.BG_BASE
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	add_child(bg)

	# Pega alvo
	var target_id: StringName = GameManager.get_meta("combat_target", &"") if GameManager.has_meta("combat_target") else &""
	if target_id == &"":
		# Sem alvo: volta pro mapa
		_finish_with(true, "Sem alvo de combate. Selecione um território pelo mapa.")
		return
	_target_territory = FactionManager.get_territory(target_id)
	_defender_id = _target_territory.owner_id if _target_territory else &"NEUTRAL"

	# Calcula tile size baseado na viewport
	var vw := get_viewport_rect().size.x
	TILE_PX = int((vw - 80) / GRID_SIZE)

	_build_header()
	_build_grid()
	_build_controls()
	_spawn_units()
	_render_grid()
	_update_status()


func _build_header() -> void:
	_hud = Control.new()
	_hud.anchor_right = 1
	_hud.custom_minimum_size = Vector2(0, 220)
	_hud.offset_bottom = 220
	add_child(_hud)

	var bg := ColorRect.new()
	bg.color = Palette.BG_SURFACE
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	_hud.add_child(bg)

	var stripe := ColorRect.new()
	stripe.color = Palette.ACCENT_PRIMARY
	stripe.anchor_bottom = 1
	stripe.custom_minimum_size = Vector2(6, 0)
	stripe.offset_right = 6
	_hud.add_child(stripe)

	var vb := VBoxContainer.new()
	vb.anchor_left = 0
	vb.anchor_right = 1
	vb.offset_left = 30
	vb.offset_right = -30
	vb.offset_top = 30
	vb.add_theme_constant_override("separation", 8)
	_hud.add_child(vb)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	vb.add_child(hb)

	var back := IconButton.new()
	back.icon_char = "←"
	back.pressed.connect(func(): _finish_with(true, "Combate abortado."))
	hb.add_child(back)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(title_col)
	var t := Label.new()
	t.text = "ASSALTO TÁTICO"
	t.theme_type_variation = "Muted"
	title_col.add_child(t)
	var sub := Label.new()
	sub.text = "%s — defendido por %s" % [_target_territory.name, _faction_short()]
	sub.theme_type_variation = "H3"
	title_col.add_child(sub)

	_status_label = Label.new()
	_status_label.text = "Seu turno"
	_status_label.theme_type_variation = "Mono"
	_status_label.add_theme_color_override("font_color", Palette.ACCENT_GOLD)
	hb.add_child(_status_label)

	_log_label = Label.new()
	_log_label.text = "Selecione uma unidade pra começar."
	_log_label.theme_type_variation = "Body"
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_log_label)


func _build_grid() -> void:
	_grid_root = Control.new()
	_grid_root.position = Vector2(40, 240)
	_grid_root.custom_minimum_size = Vector2(TILE_PX * GRID_SIZE, TILE_PX * GRID_SIZE)
	add_child(_grid_root)

	_tile_buttons.clear()
	for r in GRID_SIZE:
		var row: Array = []
		for c in GRID_SIZE:
			var btn := Button.new()
			btn.flat = true
			btn.focus_mode = Control.FOCUS_NONE
			btn.position = Vector2(c * TILE_PX, r * TILE_PX)
			btn.custom_minimum_size = Vector2(TILE_PX, TILE_PX)
			btn.size = Vector2(TILE_PX, TILE_PX)
			btn.pressed.connect(_on_tile_pressed.bind(Vector2i(c, r)))
			_grid_root.add_child(btn)
			row.append(btn)
		_tile_buttons.append(row)


func _build_controls() -> void:
	var bar := Control.new()
	bar.anchor_left = 0
	bar.anchor_right = 1
	bar.anchor_top = 1
	bar.anchor_bottom = 1
	bar.offset_top = -200
	add_child(bar)

	var bg := ColorRect.new()
	bg.color = Palette.BG_SURFACE
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	bar.add_child(bg)

	var stripe := ColorRect.new()
	stripe.color = Palette.ACCENT_GOLD
	stripe.anchor_right = 1
	stripe.custom_minimum_size = Vector2(0, 3)
	stripe.offset_bottom = 3
	bar.add_child(stripe)

	var vb := VBoxContainer.new()
	vb.anchor_left = 0
	vb.anchor_right = 1
	vb.anchor_top = 0
	vb.anchor_bottom = 1
	vb.offset_left = 30
	vb.offset_right = -30
	vb.offset_top = 24
	vb.offset_bottom = -24
	vb.add_theme_constant_override("separation", 10)
	bar.add_child(vb)

	_end_btn = PrimaryButton.new()
	_end_btn.text = "Encerrar Turno"
	_end_btn.set_variant(PrimaryButton.Variant.PRIMARY)
	_end_btn.pressed.connect(_on_end_player_turn)
	vb.add_child(_end_btn)

	var retreat := PrimaryButton.new()
	retreat.text = "Recuar (penalidade)"
	retreat.set_variant(PrimaryButton.Variant.GHOST)
	retreat.pressed.connect(_on_retreat)
	vb.add_child(retreat)


func _spawn_units() -> void:
	_units.clear()
	# Player: até 3 unidades (1 chefe + tropa). Limita pelos soldados disponíveis.
	var squad := mini(3, maxi(1, GameManager.soldiers))
	# O patrão sempre entra
	_units.append(CombatUnit.make_player(1, GameManager.player.nickname if GameManager.player else "Patrão", Vector2i(0, GRID_SIZE / 2)))
	for i in squad - 1:
		_units.append(CombatUnit.make_player(2 + i, "Soldado %d" % (i + 1), Vector2i(0, GRID_SIZE / 2 - 1 - i)))

	# Inimigos: 2–4 baseados na facção defensora.
	var enemy_count := 3
	if _defender_id == &"NEUTRAL":
		enemy_count = 2
	for i in enemy_count:
		var ey := mini(GRID_SIZE - 1, 1 + i * 2)
		_units.append(CombatUnit.make_enemy(10 + i, "%s %d" % [_faction_short(), i + 1], Vector2i(GRID_SIZE - 1, ey)))


# ---- Rendering ----------------------------------------------------------

func _render_grid() -> void:
	# Pinta tiles base
	for r in GRID_SIZE:
		for c in GRID_SIZE:
			var btn: Button = _tile_buttons[r][c]
			btn.text = ""
			_style_tile(btn, _tile_base_color(r, c), Palette.BORDER_SUBTLE)

	# Highlights de movimento/ataque pra unidade selecionada
	if _selected and _selected.side == CombatUnit.Side.PLAYER and _selected.ap > 0 and _turn == Turn.PLAYER:
		var move_tiles := _tiles_in_range(_selected.pos, _selected.move_range)
		for p in move_tiles:
			if _unit_at(p) == null:
				_style_tile(_tile_buttons[p.y][p.x], Color(Palette.ACCENT_BLUE, 0.25), Palette.ACCENT_BLUE)
		var atk_tiles := _tiles_in_range(_selected.pos, _selected.atk_range)
		for p in atk_tiles:
			var u := _unit_at(p)
			if u != null and u.side == CombatUnit.Side.ENEMY:
				_style_tile(_tile_buttons[p.y][p.x], Color(Palette.ACCENT_DANGER, 0.35), Palette.ACCENT_DANGER)

	# Desenha unidades
	for u in _units:
		if not u.alive:
			continue
		var btn: Button = _tile_buttons[u.pos.y][u.pos.x]
		btn.text = _unit_glyph(u)
		var col := Palette.ACCENT_GOLD if u.side == CombatUnit.Side.PLAYER else Palette.ACCENT_DANGER
		var bg := Palette.BG_ELEVATED if u.side == CombatUnit.Side.PLAYER else Palette.BG_SURFACE
		var border := col
		if _selected == u:
			bg = bg.lightened(0.1)
			border = Palette.ACCENT_GOLD
		_style_tile(btn, bg, border, 3)
		btn.add_theme_color_override("font_color", col)
		btn.add_theme_font_size_override("font_size", 40)

	_update_status()


func _style_tile(btn: Button, bg: Color, border: Color, border_w: int = 1) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.border_color = border
	sb.border_width_left = border_w
	sb.border_width_right = border_w
	sb.border_width_top = border_w
	sb.border_width_bottom = border_w
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)


func _tile_base_color(r: int, c: int) -> Color:
	# Pattern xadrez sutil
	if (r + c) % 2 == 0:
		return Palette.BG_SURFACE
	return Palette.BG_ELEVATED


func _unit_glyph(u: CombatUnit) -> String:
	if u.side == CombatUnit.Side.PLAYER:
		return "♟"
	return "✪"


func _update_status() -> void:
	if _selected and _selected.alive:
		_status_label.text = "%s — HP %d/%d · AP %d" % [_selected.name, _selected.hp, _selected.max_hp, _selected.ap]
	else:
		var player_alive := _count_side(CombatUnit.Side.PLAYER)
		var enemy_alive := _count_side(CombatUnit.Side.ENEMY)
		_status_label.text = "Você %d × %d %s" % [player_alive, enemy_alive, _faction_short()]


# ---- Input --------------------------------------------------------------

func _on_tile_pressed(p: Vector2i) -> void:
	if _turn != Turn.PLAYER:
		return

	var clicked_unit := _unit_at(p)

	# Clique em unidade do jogador -> seleciona
	if clicked_unit and clicked_unit.side == CombatUnit.Side.PLAYER and clicked_unit.alive:
		_selected = clicked_unit
		_log("Selecionado: %s" % clicked_unit.name)
		_render_grid()
		return

	if _selected == null or not _selected.alive:
		_log("Selecione uma unidade sua primeiro.")
		return

	# Clique em inimigo dentro do alcance -> atacar
	if clicked_unit and clicked_unit.side == CombatUnit.Side.ENEMY:
		var dist := _chebyshev(_selected.pos, p)
		if dist <= _selected.atk_range and _selected.ap > 0:
			_attack(_selected, clicked_unit)
			_render_grid()
			_check_victory()
			return
		else:
			_log("Inimigo fora de alcance.")
			return

	# Clique em tile vazio dentro do alcance -> mover
	if clicked_unit == null and _selected.ap > 0:
		var dist := _chebyshev(_selected.pos, p)
		if dist <= _selected.move_range:
			_selected.pos = p
			_selected.ap -= 1
			_log("%s moveu pra (%d,%d)." % [_selected.name, p.x, p.y])
			_render_grid()
			return
		else:
			_log("Tile fora de alcance.")
			return


# ---- Combat helpers -----------------------------------------------------

func _attack(attacker: CombatUnit, defender: CombatUnit) -> void:
	var crit := randf() < 0.15
	var dmg := attacker.damage + (1 if crit else 0)
	defender.hp -= dmg
	attacker.ap -= 1
	var crit_tag := " (crítico!)" if crit else ""
	if defender.hp <= 0:
		defender.alive = false
		_log("%s eliminou %s%s." % [attacker.name, defender.name, crit_tag])
	else:
		_log("%s atacou %s (%d dano%s, HP %d)." % [attacker.name, defender.name, dmg, crit_tag, defender.hp])


func _tiles_in_range(origin: Vector2i, rng: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dy in range(-rng, rng + 1):
		for dx in range(-rng, rng + 1):
			var p := origin + Vector2i(dx, dy)
			if p.x < 0 or p.y < 0 or p.x >= GRID_SIZE or p.y >= GRID_SIZE:
				continue
			if p == origin:
				continue
			if _chebyshev(origin, p) <= rng:
				out.append(p)
	return out


func _chebyshev(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


func _unit_at(p: Vector2i) -> CombatUnit:
	for u in _units:
		if u.alive and u.pos == p:
			return u
	return null


func _count_side(s: CombatUnit.Side) -> int:
	var n := 0
	for u in _units:
		if u.alive and u.side == s:
			n += 1
	return n


# ---- Turn flow ----------------------------------------------------------

func _on_end_player_turn() -> void:
	if _turn != Turn.PLAYER:
		return
	_turn = Turn.ENEMY
	_selected = null
	_log("Turno inimigo.")
	_render_grid()
	# IA inimiga com pequeno delay pra UX
	var timer := get_tree().create_timer(0.5)
	timer.timeout.connect(_run_enemy_ai)


func _run_enemy_ai() -> void:
	for u in _units:
		if u.alive and u.side == CombatUnit.Side.ENEMY:
			u.ap = u.ap_max
	for u in _units:
		if not u.alive or u.side != CombatUnit.Side.ENEMY:
			continue
		while u.ap > 0:
			var target := _closest_player(u)
			if target == null:
				break
			var dist := _chebyshev(u.pos, target.pos)
			if dist <= u.atk_range:
				_attack(u, target)
			else:
				# move um passo em direção ao alvo
				var step := _step_toward(u.pos, target.pos)
				if step == u.pos:
					break
				if _unit_at(step) != null:
					break
				u.pos = step
				u.ap -= 1
	_render_grid()
	if _check_victory():
		return
	# Reset AP dos jogadores e devolve turno
	for u in _units:
		if u.alive and u.side == CombatUnit.Side.PLAYER:
			u.ap = u.ap_max
	_turn = Turn.PLAYER
	_player_turn_count += 1
	_log("Seu turno %d." % _player_turn_count)
	_render_grid()


func _closest_player(u: CombatUnit) -> CombatUnit:
	var best: CombatUnit = null
	var best_d := 999
	for x in _units:
		if x.alive and x.side == CombatUnit.Side.PLAYER:
			var d := _chebyshev(u.pos, x.pos)
			if d < best_d:
				best_d = d
				best = x
	return best


func _step_toward(from: Vector2i, to: Vector2i) -> Vector2i:
	var step := Vector2i(signi(to.x - from.x), signi(to.y - from.y))
	return from + step


# ---- Victory / loss ----------------------------------------------------

func _check_victory() -> bool:
	var player_alive := _count_side(CombatUnit.Side.PLAYER)
	var enemy_alive := _count_side(CombatUnit.Side.ENEMY)
	if enemy_alive == 0:
		_finish_with(false, "Vitória! %s conquistada." % _target_territory.name)
		return true
	if player_alive == 0:
		_finish_with(false, "Derrota. Tropa dizimada.")
		return true
	return false


func _finish_with(aborted: bool, msg: String) -> void:
	_turn = Turn.RESOLVED
	if _log_label:
		_log_label.text = msg
	# Resolução de estado
	if not aborted:
		if msg.begins_with("Vitória"):
			FactionManager.resolve_combat_victory(_target_territory, _defender_id)
		else:
			FactionManager.resolve_combat_defeat(_target_territory)
	# Limpa meta
	if GameManager.has_meta("combat_target"):
		GameManager.remove_meta("combat_target")
	# Pequeno modal e volta pro mapa
	var dlg := AcceptDialog.new()
	dlg.title = "Fim do confronto"
	dlg.dialog_text = msg
	dlg.ok_button_text = "Voltar ao Mapa"
	dlg.min_size = Vector2(800, 400)
	add_child(dlg)
	dlg.popup_centered()
	dlg.confirmed.connect(func(): GameManager.change_scene(MAP_PATH))
	dlg.canceled.connect(func(): GameManager.change_scene(MAP_PATH))


func _on_retreat() -> void:
	GameManager.add_loyalty(-4)
	GameManager.log_event("Recuou de %s. Lealdade abalada." % _target_territory.name, StatBadge.Tone.DANGER)
	_finish_with(true, "Você recuou.")


func _log(msg: String) -> void:
	if _log_label:
		_log_label.text = msg


func _faction_short() -> String:
	var f: Faction = FactionManager.get_faction(_defender_id)
	if f:
		return f.short_name
	return "Neutro"
