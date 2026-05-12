extends Node
## GameManager — singleton de estado global do jogo.
## Implementação completa virá no Passo 4.

signal turn_advanced(new_turn: int)

var current_turn: int = 1
var player_name: String = ""

func _ready() -> void:
	pass
