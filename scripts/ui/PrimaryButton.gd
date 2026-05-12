class_name PrimaryButton
extends Button
## Botão primário com variantes de estilo: PRIMARY (vermelho), GOLD, GHOST, DANGER.
## Use via código: var b := PrimaryButton.new(); b.set_variant(PrimaryButton.Variant.GOLD)

enum Variant { PRIMARY, GOLD, GHOST, DANGER }

@export var variant: Variant = Variant.PRIMARY

func _ready() -> void:
	custom_minimum_size = Vector2(0, 88)
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_variant()


func set_variant(v: Variant) -> void:
	variant = v
	if is_inside_tree():
		_apply_variant()


func _apply_variant() -> void:
	var bg: Color
	match variant:
		Variant.PRIMARY: bg = Palette.ACCENT_PRIMARY
		Variant.GOLD:    bg = Palette.ACCENT_GOLD
		Variant.GHOST:   bg = Palette.BG_ELEVATED
		Variant.DANGER:  bg = Palette.ACCENT_DANGER

	var normal := _make_style(bg)
	var hover := _make_style(bg.lightened(0.08))
	hover.shadow_size = 18
	var pressed := _make_style(bg.darkened(0.15))

	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed)

	var text_color := Palette.TEXT_PRIMARY
	if variant == Variant.GOLD:
		text_color = Palette.BG_BASE
	if variant == Variant.GHOST:
		text_color = Palette.TEXT_PRIMARY
	add_theme_color_override("font_color", text_color)
	add_theme_color_override("font_hover_color", text_color)
	add_theme_color_override("font_pressed_color", text_color)
	add_theme_font_size_override("font_size", 30)


func _make_style(c: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = 14
	sb.corner_radius_bottom_right = 14
	sb.content_margin_left = 32
	sb.content_margin_right = 32
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	sb.shadow_size = 12
	sb.shadow_color = Color(c, 0.35)
	if variant == Variant.GHOST:
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_width_top = 1
		sb.border_width_bottom = 1
		sb.border_color = Palette.BORDER_SUBTLE
		sb.shadow_size = 0
	return sb
