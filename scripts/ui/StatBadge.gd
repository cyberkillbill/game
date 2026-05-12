class_name StatBadge
extends PanelContainer
## Badge compacto: ícone (caractere) + label + valor.
## Usado no HUD do mapa estratégico (Capital, Influência, Calor, etc.)

enum Tone { NEUTRAL, GOLD, DANGER, SUCCESS, INFO }

var _label: Label
var _value: Label
var _icon: Label
var _tone: Tone = Tone.NEUTRAL


func _init(label_text: String = "", value_text: String = "", icon_char: String = "•", tone: Tone = Tone.NEUTRAL) -> void:
	_tone = tone
	_icon = Label.new()
	_icon.text = icon_char
	_icon.add_theme_font_size_override("font_size", 24)

	_label = Label.new()
	_label.text = label_text
	_label.theme_type_variation = "Muted"

	_value = Label.new()
	_value.text = value_text
	_value.theme_type_variation = "Mono"
	_value.add_theme_font_size_override("font_size", 28)


func _ready() -> void:
	custom_minimum_size = Vector2(0, 76)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.BG_ELEVATED
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.border_color = Palette.BORDER_SUBTLE
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	add_child(hbox)

	var icon_color := _color_for_tone()
	_icon.add_theme_color_override("font_color", icon_color)
	hbox.add_child(_icon)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	vbox.add_child(_label)
	vbox.add_child(_value)

	_value.add_theme_color_override("font_color", icon_color)


func set_value(v: String) -> void:
	if _value:
		_value.text = v


func set_tone(t: Tone) -> void:
	_tone = t
	if is_inside_tree():
		var c := _color_for_tone()
		_icon.add_theme_color_override("font_color", c)
		_value.add_theme_color_override("font_color", c)


func _color_for_tone() -> Color:
	match _tone:
		Tone.GOLD:    return Palette.ACCENT_GOLD
		Tone.DANGER:  return Palette.ACCENT_DANGER
		Tone.SUCCESS: return Palette.ACCENT_SUCCESS
		Tone.INFO:    return Palette.ACCENT_BLUE
		_:            return Palette.TEXT_PRIMARY
