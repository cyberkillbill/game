extends Node
## HeatManager — nível de atenção das autoridades fictícias.
## 0–40: Guarda Metropolitana (rotina).
## 41–75: ETE (Esquadrão Tático Especial).
## 76–100: FFI (Força Federal de Intervenção).

signal raid_triggered(level: int)

const HEAT_DECAY_PER_TURN := 4

var heat: int = 0


func reset() -> void:
	heat = 0


func tick() -> void:
	# Calor naturalmente decai um pouco a cada semana.
	heat = clampi(heat - HEAT_DECAY_PER_TURN, 0, GameManager.MAX_HEAT)
	if heat >= 75 and randf() < 0.5:
		_trigger_raid(2)
	elif heat >= 40 and randf() < 0.3:
		_trigger_raid(1)


func _trigger_raid(level: int) -> void:
	var loss := 1500 * level
	var sold_loss := level
	GameManager.capital = maxi(0, GameManager.capital - loss)
	GameManager.soldiers = maxi(0, GameManager.soldiers - sold_loss)
	heat = clampi(heat - 15 * level, 0, GameManager.MAX_HEAT)
	var unit := "ETE" if level == 1 else "FFI"
	GameManager.log_event("Operação da %s! -%d soldado(s), -%s$ apreendido(s)." % [unit, sold_loss, _fmt(loss)], StatBadge.Tone.DANGER)
	raid_triggered.emit(level)


func authority_label() -> String:
	if heat >= 76: return "FFI alerta"
	if heat >= 41: return "ETE de olho"
	if heat >= 10: return "Guarda Metropolitana"
	return "Calmaria"


func _fmt(n: int) -> String:
	return EconomyManager._fmt(n)
