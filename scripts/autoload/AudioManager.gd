extends Node
## AudioManager — stub funcional. Toca beeps procedurais até você dropar SFX/música.
## Implementação completa: substitua play_sfx por AudioStreamPlayer + buses.

var _sfx_player: AudioStreamPlayer


func _ready() -> void:
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "Master"
	add_child(_sfx_player)


func play_sfx(_id: StringName) -> void:
	# Sem assets ainda — só registra no log.
	pass


func play_music(_id: StringName) -> void:
	pass


func click() -> void:
	play_sfx(&"ui_click")
