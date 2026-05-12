class_name Card
extends PanelContainer
## Painel "card" elevado com sombra e borda sutil.
## Use add_child() pra inserir conteúdo normalmente.

@export var elevated: bool = true

func _ready() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.BG_ELEVATED if elevated else Palette.BG_SURFACE
	sb.corner_radius_top_left = 16
	sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_left = 16
	sb.corner_radius_bottom_right = 16
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.border_color = Palette.BORDER_SUBTLE
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	if elevated:
		sb.shadow_size = 16
		sb.shadow_color = Color(0, 0, 0, 0.4)
	add_theme_stylebox_override("panel", sb)
