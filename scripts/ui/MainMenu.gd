extends Control
## Menu principal — logo, botões, background animado.

const MAP_PATH := "res://scenes/map/StrategicMap.tscn"
const CHARACTER_PATH := "res://scenes/character/CharacterEditor.tscn"

var _grain_offset: float = 0.0
var _bg: ColorRect


func _ready() -> void:
	_build_background()
	_build_content()


func _process(delta: float) -> void:
	_grain_offset += delta * 12.0
	queue_redraw()


func _draw() -> void:
	# Sutil ruído pra dar textura premium.
	var rng := RandomNumberGenerator.new()
	rng.seed = 9001
	var sz := size
	for i in 80:
		var px := rng.randf() * sz.x
		var py := rng.randf() * sz.y
		var a := 0.018 + 0.012 * sin(_grain_offset * 0.1 + i)
		draw_rect(Rect2(px, py, 2, 2), Color(1, 1, 1, a))


func _build_background() -> void:
	_bg = ColorRect.new()
	_bg.color = Palette.BG_BASE
	_bg.anchor_right = 1
	_bg.anchor_bottom = 1
	add_child(_bg)

	# Halo vermelho radial no topo
	var halo := _make_radial(Palette.ACCENT_PRIMARY, 0.18, 700)
	halo.position = Vector2(540 - 350, 200)
	add_child(halo)

	# Halo dourado mais embaixo
	var halo2 := _make_radial(Palette.ACCENT_GOLD, 0.10, 600)
	halo2.position = Vector2(540 - 300, 1500)
	add_child(halo2)


func _make_radial(color: Color, alpha: float, radius: int) -> TextureRect:
	# Cria um gradient radial procedural via Gradient + GradientTexture2D.
	var grad := Gradient.new()
	grad.add_point(0.0, Color(color, alpha))
	grad.add_point(1.0, Color(color, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = radius
	tex.height = radius
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1, 0.5)
	var tr := TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = Vector2(radius, radius)
	tr.size = Vector2(radius, radius)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _build_content() -> void:
	var center := VBoxContainer.new()
	center.anchor_left = 0
	center.anchor_right = 1
	center.anchor_top = 0
	center.anchor_bottom = 1
	center.offset_left = 60
	center.offset_right = -60
	center.offset_top = 200
	center.offset_bottom = -120
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 32)
	add_child(center)

	# --- Logo block ---
	var logo_box := VBoxContainer.new()
	logo_box.alignment = BoxContainer.ALIGNMENT_CENTER
	logo_box.add_theme_constant_override("separation", 8)
	center.add_child(logo_box)

	var title := Label.new()
	title.text = "PORTO SANTIAGO"
	title.theme_type_variation = "H1"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Palette.TEXT_PRIMARY)
	logo_box.add_child(title)

	var rule := ColorRect.new()
	rule.color = Palette.ACCENT_PRIMARY
	rule.custom_minimum_size = Vector2(140, 4)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logo_box.add_child(rule)

	var tagline := Label.new()
	tagline.text = "DINHEIRO · PODER · RESPEITO"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 24)
	tagline.add_theme_color_override("font_color", Palette.ACCENT_GOLD)
	logo_box.add_child(tagline)

	var spacer1 := Control.new()
	spacer1.custom_minimum_size = Vector2(0, 120)
	center.add_child(spacer1)

	# --- Buttons ---
	var btn_new := PrimaryButton.new()
	btn_new.text = "Novo Jogo"
	btn_new.set_variant(PrimaryButton.Variant.PRIMARY)
	btn_new.pressed.connect(_on_new_game)
	center.add_child(btn_new)

	var btn_continue := PrimaryButton.new()
	btn_continue.text = "Continuar"
	btn_continue.set_variant(PrimaryButton.Variant.GOLD)
	btn_continue.disabled = not SaveManager.has_save()
	btn_continue.pressed.connect(_on_continue)
	center.add_child(btn_continue)

	var btn_settings := PrimaryButton.new()
	btn_settings.text = "Configurações"
	btn_settings.set_variant(PrimaryButton.Variant.GHOST)
	btn_settings.pressed.connect(_on_settings)
	center.add_child(btn_settings)

	var btn_about := PrimaryButton.new()
	btn_about.text = "Sobre"
	btn_about.set_variant(PrimaryButton.Variant.GHOST)
	btn_about.pressed.connect(_on_about)
	center.add_child(btn_about)

	# --- Footer ---
	var footer := Label.new()
	footer.text = "v0.1.0 — ficção. Tudo aqui é inventado."
	footer.theme_type_variation = "Muted"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.anchor_top = 1
	footer.anchor_bottom = 1
	footer.anchor_left = 0
	footer.anchor_right = 1
	footer.offset_top = -60
	footer.offset_bottom = -20
	add_child(footer)


func _on_new_game() -> void:
	GameManager.change_scene(CHARACTER_PATH)


func _on_continue() -> void:
	if SaveManager.load_game():
		GameManager.change_scene(MAP_PATH)


func _on_settings() -> void:
	_show_modal("Configurações", "Volume, idioma e cloud sync virão em breve.\n\nPor ora: idioma fixo em pt-BR, áudio mudo.")


func _on_about() -> void:
	var text := "Porto Santiago é um drama criminal estratégico ficcional.\n\nNenhuma pessoa, organização, instituição, marca, time ou arma reais são referenciadas. A estética brasileira é tratada com respeito, sem caricaturar comunidades específicas.\n\nInspirado em Scarface: Money, Power, Respect (2006)."
	_show_modal("Sobre", text)


func _show_modal(title_text: String, body_text: String) -> void:
	var dlg := AcceptDialog.new()
	dlg.title = title_text
	dlg.dialog_text = body_text
	dlg.ok_button_text = "Fechar"
	dlg.min_size = Vector2(900, 600)
	add_child(dlg)
	dlg.popup_centered()
	dlg.confirmed.connect(dlg.queue_free)
	dlg.canceled.connect(dlg.queue_free)
