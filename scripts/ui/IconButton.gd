class_name IconButton
extends Button
## Botão circular compacto pra ações secundárias (voltar, fechar, etc.)
## O "ícone" é um caractere unicode — substitua por SVG quando dropar assets.

@export var icon_char: String = "←"
@export var size_px: int = 64

func _ready() -> void:
	text = icon_char
	custom_minimum_size = Vector2(size_px, size_px)
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var normal := StyleBoxFlat.new()
	normal.bg_color = Palette.BG_ELEVATED
	normal.corner_radius_top_left = size_px / 2
	normal.corner_radius_top_right = size_px / 2
	normal.corner_radius_bottom_left = size_px / 2
	normal.corner_radius_bottom_right = size_px / 2
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 1
	normal.border_width_bottom = 1
	normal.border_color = Palette.BORDER_SUBTLE
	normal.content_margin_left = 0
	normal.content_margin_right = 0
	normal.content_margin_top = 0
	normal.content_margin_bottom = 0

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Palette.BG_ELEVATED.lightened(0.1)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Palette.BG_BASE

	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed)
	add_theme_color_override("font_color", Palette.TEXT_PRIMARY)
	add_theme_font_size_override("font_size", 32)
