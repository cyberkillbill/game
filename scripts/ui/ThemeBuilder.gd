class_name ThemeBuilder
extends RefCounted
## Constrói o tema global do jogo em código.
## Chamado por GameManager._ready() e aplicado em get_tree().root.theme.
##
## Usa fontes default do Godot. Quando você dropar General Sans / Satoshi /
## JetBrains Mono em assets/fonts/, troque os FONT_* paths abaixo.

const FONT_UI_PATH      := ""  # ex: "res://assets/fonts/GeneralSans-Variable.ttf"
const FONT_DISPLAY_PATH := ""  # ex: "res://assets/fonts/Satoshi-Variable.ttf"
const FONT_MONO_PATH    := ""  # ex: "res://assets/fonts/JetBrainsMono-Regular.ttf"


static func build() -> Theme:
	var theme := Theme.new()
	var ui_font := _load_font(FONT_UI_PATH)
	var display_font := _load_font(FONT_DISPLAY_PATH)
	var mono_font := _load_font(FONT_MONO_PATH)

	if ui_font:
		theme.default_font = ui_font
	theme.default_font_size = 28

	_apply_button(theme)
	_apply_panel(theme)
	_apply_label(theme, display_font, mono_font)
	_apply_line_edit(theme)
	_apply_progress_bar(theme)
	_apply_scroll(theme)
	return theme


static func _load_font(path: String) -> Font:
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Font


static func _apply_button(theme: Theme) -> void:
	var normal := _flat(Palette.ACCENT_PRIMARY, 14)
	normal.border_width_left = 0
	normal.shadow_size = 12
	normal.shadow_color = Color(Palette.ACCENT_PRIMARY, 0.35)

	var hover := _flat(Palette.ACCENT_PRIMARY.lightened(0.08), 14)
	hover.shadow_size = 16
	hover.shadow_color = Color(Palette.ACCENT_PRIMARY, 0.5)

	var pressed := _flat(Palette.ACCENT_PRIMARY.darkened(0.15), 14)
	var disabled := _flat(Palette.BG_ELEVATED, 14)

	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("disabled", "Button", disabled)
	theme.set_stylebox("focus", "Button", _flat(Color.TRANSPARENT, 14, Palette.BORDER_STRONG))
	theme.set_color("font_color", "Button", Palette.TEXT_PRIMARY)
	theme.set_color("font_hover_color", "Button", Palette.TEXT_PRIMARY)
	theme.set_color("font_pressed_color", "Button", Palette.TEXT_PRIMARY)
	theme.set_color("font_disabled_color", "Button", Palette.TEXT_MUTED)
	theme.set_constant("h_separation", "Button", 12)
	theme.set_constant("outline_size", "Button", 0)


static func _apply_panel(theme: Theme) -> void:
	var panel := _flat(Palette.BG_SURFACE, 16, Palette.BORDER_SUBTLE)
	theme.set_stylebox("panel", "Panel", panel)
	theme.set_stylebox("panel", "PanelContainer", panel)

	# A Card será um PanelContainer com type variation "Card"
	var card := _flat(Palette.BG_ELEVATED, 16, Palette.BORDER_SUBTLE)
	card.content_margin_left = 20
	card.content_margin_right = 20
	card.content_margin_top = 18
	card.content_margin_bottom = 18
	card.shadow_size = 18
	card.shadow_color = Color(0, 0, 0, 0.4)
	theme.set_stylebox("panel", "Card", card)
	theme.set_type_variation("Card", "PanelContainer")


static func _apply_label(theme: Theme, display_font: Font, mono_font: Font) -> void:
	theme.set_color("font_color", "Label", Palette.TEXT_PRIMARY)

	# Variações tipográficas — usadas via Label.theme_type_variation = "H1" etc.
	theme.set_type_variation("H1", "Label")
	theme.set_color("font_color", "H1", Palette.TEXT_PRIMARY)
	theme.set_font_size("font_size", "H1", 56)
	if display_font:
		theme.set_font("font", "H1", display_font)

	theme.set_type_variation("H2", "Label")
	theme.set_color("font_color", "H2", Palette.TEXT_PRIMARY)
	theme.set_font_size("font_size", "H2", 40)
	if display_font:
		theme.set_font("font", "H2", display_font)

	theme.set_type_variation("H3", "Label")
	theme.set_color("font_color", "H3", Palette.TEXT_PRIMARY)
	theme.set_font_size("font_size", "H3", 30)

	theme.set_type_variation("Body", "Label")
	theme.set_color("font_color", "Body", Palette.TEXT_SECONDARY)
	theme.set_font_size("font_size", "Body", 26)

	theme.set_type_variation("Muted", "Label")
	theme.set_color("font_color", "Muted", Palette.TEXT_MUTED)
	theme.set_font_size("font_size", "Muted", 22)

	theme.set_type_variation("Mono", "Label")
	theme.set_color("font_color", "Mono", Palette.TEXT_PRIMARY)
	theme.set_font_size("font_size", "Mono", 28)
	if mono_font:
		theme.set_font("font", "Mono", mono_font)


static func _apply_line_edit(theme: Theme) -> void:
	var normal := _flat(Palette.BG_ELEVATED, 12, Palette.BORDER_SUBTLE)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 14
	normal.content_margin_bottom = 14
	var focus := _flat(Palette.BG_ELEVATED, 12, Palette.ACCENT_GOLD)
	focus.border_width_top = 2
	focus.border_width_bottom = 2
	focus.border_width_left = 2
	focus.border_width_right = 2
	theme.set_stylebox("normal", "LineEdit", normal)
	theme.set_stylebox("focus", "LineEdit", focus)
	theme.set_color("font_color", "LineEdit", Palette.TEXT_PRIMARY)
	theme.set_color("caret_color", "LineEdit", Palette.ACCENT_GOLD)


static func _apply_progress_bar(theme: Theme) -> void:
	var bg := _flat(Palette.BG_ELEVATED, 8)
	var fg := _flat(Palette.ACCENT_GOLD, 8)
	theme.set_stylebox("background", "ProgressBar", bg)
	theme.set_stylebox("fill", "ProgressBar", fg)


static func _apply_scroll(theme: Theme) -> void:
	var grabber := _flat(Color(1, 1, 1, 0.2), 4)
	var grabber_hl := _flat(Color(1, 1, 1, 0.35), 4)
	var sb := _flat(Color.TRANSPARENT, 0)
	theme.set_stylebox("scroll", "VScrollBar", sb)
	theme.set_stylebox("scroll", "HScrollBar", sb)
	theme.set_stylebox("grabber", "VScrollBar", grabber)
	theme.set_stylebox("grabber_highlight", "VScrollBar", grabber_hl)
	theme.set_stylebox("grabber_pressed", "VScrollBar", grabber_hl)
	theme.set_stylebox("grabber", "HScrollBar", grabber)
	theme.set_stylebox("grabber_highlight", "HScrollBar", grabber_hl)
	theme.set_stylebox("grabber_pressed", "HScrollBar", grabber_hl)


static func _flat(color: Color, radius: int, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	if border.a > 0:
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_width_top = 1
		sb.border_width_bottom = 1
		sb.border_color = border
	return sb
