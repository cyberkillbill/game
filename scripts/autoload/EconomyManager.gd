extends Node
## EconomyManager — renda, manutenção, lavagem de capital.
## Constantes ajustadas pra que o early game seja apertado, mas justo.

const MAINT_PER_SOLDIER := 80
const MAINT_PER_OPERATION := 350
const LAUNDER_FEE_PCT := 0.18
const LAUNDER_CAP_PER_TURN := 8000

func reset() -> void:
	pass


func collect_income() -> void:
	var total_dirty := 0
	for t in FactionManager.player_territories():
		var inc := t.current_income()
		total_dirty += inc
	if total_dirty > 0:
		GameManager.capital += total_dirty
		GameManager.log_event("Coleta semanal: +%s$ em capital sujo." % _fmt(total_dirty), StatBadge.Tone.GOLD)


func process_recruit_phase() -> void:
	# Lealdade alta gera bônus de moral; baixa pode causar deserção.
	if GameManager.loyalty < 25 and GameManager.soldiers > 0:
		var lost := mini(GameManager.soldiers, 1 + randi_range(0, 1))
		GameManager.soldiers -= lost
		GameManager.log_event("Lealdade baixa: %d soldado(s) abandonaram a tropa." % lost, StatBadge.Tone.DANGER)
	elif GameManager.loyalty > 80 and randf() < 0.3:
		GameManager.soldiers += 1
		GameManager.log_event("Reputação na rua trouxe um recruta voluntário.", StatBadge.Tone.SUCCESS)


func pay_maintenance() -> void:
	var op_count := 0
	for t in FactionManager.player_territories():
		op_count += t.operations
	var cost := GameManager.soldiers * MAINT_PER_SOLDIER + op_count * MAINT_PER_OPERATION
	if cost <= 0:
		return
	if GameManager.capital >= cost:
		GameManager.capital -= cost
		GameManager.log_event("Manutenção paga: -%s$." % _fmt(cost), StatBadge.Tone.NEUTRAL)
	else:
		var debt := cost - GameManager.capital
		GameManager.capital = 0
		GameManager.loyalty = clampi(GameManager.loyalty - 12, 0, 100)
		GameManager.log_event("Folha atrasada! Devendo %s$. Lealdade caiu." % _fmt(debt), StatBadge.Tone.DANGER)


func launder(amount: int) -> int:
	## Lava `amount` de capital sujo. Retorna capital limpo obtido.
	amount = clampi(amount, 0, LAUNDER_CAP_PER_TURN)
	amount = mini(amount, GameManager.capital)
	if amount <= 0:
		return 0
	var fee := int(amount * LAUNDER_FEE_PCT)
	var clean := amount - fee
	GameManager.capital -= amount
	GameManager.clean_capital += clean
	GameManager.add_heat(int(amount / 2000.0))
	GameManager.log_event("Lavagem: -%s$ sujo / +%s$ limpo (taxa %d%%)." % [_fmt(amount), _fmt(clean), int(LAUNDER_FEE_PCT * 100)], StatBadge.Tone.INFO)
	GameManager.game_state_changed.emit()
	return clean


func bribe(amount: int) -> bool:
	if GameManager.capital < amount:
		return false
	GameManager.capital -= amount
	var reduce := clampi(amount / 250, 1, 20)
	HeatManager.heat = clampi(HeatManager.heat - reduce, 0, GameManager.MAX_HEAT)
	GameManager.log_event("Suborno: -%s$, -%d Calor." % [_fmt(amount), reduce], StatBadge.Tone.GOLD)
	GameManager.game_state_changed.emit()
	return true


func recruit_soldier() -> bool:
	const COST := 600
	if GameManager.capital < COST:
		return false
	GameManager.capital -= COST
	GameManager.soldiers += 1
	GameManager.log_event("Novo soldado contratado. -%s$." % _fmt(COST), StatBadge.Tone.SUCCESS)
	GameManager.game_state_changed.emit()
	return true


func install_operation(territory: Territory) -> bool:
	const COST := 2500
	if territory.operations >= 3:
		return false
	if GameManager.capital < COST:
		return false
	GameManager.capital -= COST
	territory.operations += 1
	GameManager.log_event("Nova operação instalada em %s." % territory.name, StatBadge.Tone.GOLD)
	GameManager.game_state_changed.emit()
	return true


func _fmt(n: int) -> String:
	# Formato BR com pontos: 12345 -> 12.345
	var s := str(absi(n))
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "." + out
	if n < 0:
		out = "-" + out
	return out
