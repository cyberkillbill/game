extends Node
## GameManager — estado global, controle de turnos e fases, navegação entre cenas.

signal turn_advanced(new_turn: int)
signal phase_changed(phase: int)
signal game_state_changed
signal event_logged(message: String, tone: int)  # tone = StatBadge.Tone

enum Phase { ECONOMY, RECRUIT, DIPLOMACY, TACTICAL, MAINTENANCE }

const MAX_HEAT := 100
const MAX_LOYALTY := 100
const START_CAPITAL := 25000
const START_CLEAN := 0
const START_INFLUENCE := 10
const START_LOYALTY := 60
const START_SOLDIERS := 4

var player: PlayerCharacter = null
var current_turn: int = 1
var current_phase: Phase = Phase.ECONOMY

var capital: int = 0
var clean_capital: int = 0
var influence: int = 0
var loyalty: int = 0
var soldiers: int = 0
var goods_units: int = 0    # "mercadoria" abstrata, tier 1

var event_log: Array[Dictionary] = []   # [{turn, msg, tone}]

var _theme_applied: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_global_theme()


func _apply_global_theme() -> void:
	if _theme_applied:
		return
	var root := get_tree().root
	if root:
		root.theme = ThemeBuilder.build()
		_theme_applied = true


func start_new_game(p: PlayerCharacter) -> void:
	player = p
	current_turn = 1
	current_phase = Phase.ECONOMY
	capital = START_CAPITAL
	clean_capital = START_CLEAN
	influence = START_INFLUENCE
	loyalty = START_LOYALTY
	soldiers = START_SOLDIERS
	goods_units = 0
	event_log.clear()
	FactionManager.reset()
	EconomyManager.reset()
	HeatManager.reset()
	log_event("Nova semana em Porto Santiago. Bora pro jogo.", StatBadge.Tone.GOLD)
	game_state_changed.emit()


func log_event(msg: String, tone: int = StatBadge.Tone.NEUTRAL) -> void:
	event_log.push_front({"turn": current_turn, "msg": msg, "tone": tone})
	if event_log.size() > 30:
		event_log.resize(30)
	event_logged.emit(msg, tone)


func end_turn() -> void:
	# Executa as 5 fases em sequência.
	_run_phase(Phase.ECONOMY)
	_run_phase(Phase.RECRUIT)
	_run_phase(Phase.DIPLOMACY)
	_run_phase(Phase.TACTICAL)
	_run_phase(Phase.MAINTENANCE)
	current_turn += 1
	current_phase = Phase.ECONOMY
	turn_advanced.emit(current_turn)
	game_state_changed.emit()


func _run_phase(p: Phase) -> void:
	current_phase = p
	phase_changed.emit(int(p))
	match p:
		Phase.ECONOMY:     EconomyManager.collect_income()
		Phase.RECRUIT:     EconomyManager.process_recruit_phase()
		Phase.DIPLOMACY:   FactionManager.tick_relations()
		Phase.TACTICAL:    FactionManager.maybe_trigger_raid()
		Phase.MAINTENANCE: EconomyManager.pay_maintenance(); HeatManager.tick()
	_maybe_random_event()


func _maybe_random_event() -> void:
	# Eventos aleatórios bem leves — placeholder pra expansão.
	if randf() > 0.18:
		return
	var rolls := [
		{"msg": "Boato na rua: investidor estrangeiro chega à Marina Alta.", "tone": StatBadge.Tone.INFO},
		{"msg": "Um informante quer trocar fofoca por capital.", "tone": StatBadge.Tone.NEUTRAL},
		{"msg": "A imprensa local fala de operações no Distrito Industrial.", "tone": StatBadge.Tone.DANGER},
		{"msg": "Um soldado fiel pede mais responsabilidade.", "tone": StatBadge.Tone.SUCCESS},
		{"msg": "Festa privada na Marina rende contatos. +2 Influência.", "tone": StatBadge.Tone.GOLD},
	]
	var pick: Dictionary = rolls.pick_random()
	log_event(pick["msg"], pick["tone"])
	if pick["msg"].begins_with("Festa"):
		influence += 2


func add_capital(amount: int) -> void:
	capital += amount
	game_state_changed.emit()


func add_influence(amount: int) -> void:
	influence = clampi(influence + amount, 0, 999)
	game_state_changed.emit()


func add_heat(amount: int) -> void:
	HeatManager.heat = clampi(HeatManager.heat + amount, 0, MAX_HEAT)
	game_state_changed.emit()


func add_loyalty(amount: int) -> void:
	loyalty = clampi(loyalty + amount, 0, MAX_LOYALTY)
	game_state_changed.emit()


func change_scene(path: String) -> void:
	# Helper único pra navegação, evita esquecer await/erro silencioso.
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Falha ao trocar de cena: %s (erro %d)" % [path, err])


# Serialização ---------------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"version": 1,
		"player": player.to_dict() if player else {},
		"current_turn": current_turn,
		"current_phase": int(current_phase),
		"capital": capital,
		"clean_capital": clean_capital,
		"influence": influence,
		"loyalty": loyalty,
		"soldiers": soldiers,
		"goods_units": goods_units,
		"heat": HeatManager.heat,
		"factions": FactionManager.serialize(),
		"territories": FactionManager.serialize_territories(),
		"event_log": event_log,
	}


func from_dict(d: Dictionary) -> void:
	player = PlayerCharacter.from_dict(d.get("player", {}))
	current_turn = d.get("current_turn", 1)
	current_phase = d.get("current_phase", Phase.ECONOMY)
	capital = d.get("capital", START_CAPITAL)
	clean_capital = d.get("clean_capital", 0)
	influence = d.get("influence", START_INFLUENCE)
	loyalty = d.get("loyalty", START_LOYALTY)
	soldiers = d.get("soldiers", START_SOLDIERS)
	goods_units = d.get("goods_units", 0)
	HeatManager.heat = d.get("heat", 0)
	FactionManager.reset()
	FactionManager.deserialize(d.get("factions", []))
	FactionManager.deserialize_territories(d.get("territories", []))
	event_log.clear()
	for ev in d.get("event_log", []):
		event_log.append(ev)
	game_state_changed.emit()
