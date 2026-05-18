extends Node
## Game — autoload único com TODO o estado e regras do jogo.
## Mantemos numa autoload só (em vez de 6) pra simplificar boot e evitar
## ordem de carregamento entre dependências.

signal state_changed
signal log_event(text: String, tone: String)  # tone: gold|info|success|danger|muted
signal turn_ended(turn: int)
signal game_finished(victory: bool, reason: String)

# ----- Constantes -----------------------------------------------------------
const GRID_W := 4
const GRID_H := 4
const N_TILES := 16
const HEAT_CAP := 100

const START_CASH := 600
const START_CLEAN := 0
const START_SOLDIERS := 4

const LAUNDER_FEE := 0.18
const RECRUIT_COST_EACH := 80
const VICTORY_CLEAN := 1_000_000

const COLOR_BG := Color("0c0e13")
const COLOR_SURFACE := Color("171a22")
const COLOR_ELEVATED := Color("232733")
const COLOR_BORDER := Color(1, 1, 1, 0.08)
const COLOR_GOLD := Color("f5b400")
const COLOR_RED := Color("d23a2c")
const COLOR_GREEN := Color("3ea34c")
const COLOR_BLUE := Color("2e7dd7")
const COLOR_PURPLE := Color("9b59d6")
const COLOR_ORANGE := Color("e07a26")
const COLOR_TEXT := Color("ececf0")
const COLOR_MUTED := Color("8a8a95")

const FACTION_COLORS := {
	"PLAYER":  Color("f5b400"),
	"BV":      Color("e94e3c"),
	"CE":      Color("3ea34c"),
	"FB":      Color("9b59d6"),
	"SV":      Color("2e7dd7"),
	"NEUTRAL": Color("4a4d56"),
}

const FACTION_NAMES := {
	"PLAYER":  "Sua tropa",
	"BV":      "Bonde do Vapor",
	"CE":      "Comando da Encruzilhada",
	"FB":      "Família da Beira",
	"SV":      "Sindicato do Vale",
	"NEUTRAL": "Sem dono",
}

const TILE_NAMES := [
	"Beco do Zé",      "Esquina da Vila",  "Travessa Maria",   "Ladeira do Cemitério",
	"Boca do Mato",    "Servidão da Linha","Becão Velho",      "Curva do Posto",
	"Pé de Manga",     "Subida do Morro",  "Vala da Pedra",    "Ponte de Madeira",
	"Quintal do Tio",  "Esquina do Bar",   "Rua do Comércio",  "Largo da Quitanda",
]

const RIVALS := ["BV", "CE", "FB", "SV"]
const RIVAL_AGGRESSION := {"BV": 0.55, "CE": 0.35, "FB": 0.5, "SV": 0.65}

# Tipos de produto: cada boca tem 1 afinidade. Margens e calor diferentes.
# PO   = pó branco          → margem +80%, calor x2
# ERVA = verde              → margem padrão, calor /2
# COMP = comprimido sintético → margem +30%, calor x1
const PRODUCT_INFO := {
	"PO":   {"name": "Pó",         "color": Color("e7e7e7"), "income_mult": 1.8, "heat_mult": 2.0},
	"ERVA": {"name": "Erva",       "color": Color("4ea64e"), "income_mult": 1.0, "heat_mult": 0.5},
	"COMP": {"name": "Comprimido", "color": Color("e07a26"), "income_mult": 1.3, "heat_mult": 1.0},
}

# Recrutas com nomes ficcionais e bônus passivos (sem caricatura)
const RECRUIT_POOL := [
	{"nome": "Tigrão",   "bonus": "+2 ataque",       "key": "ATK"},
	{"nome": "Doutor",   "bonus": "-1 calor/turno",  "key": "COOL"},
	{"nome": "Cobrinha", "bonus": "+R$30/turno",     "key": "EARN"},
	{"nome": "Magrão",   "bonus": "+1 tropa/turno",  "key": "TROOP"},
	{"nome": "Velhinho", "bonus": "+5% lavagem",     "key": "WASH"},
	{"nome": "Mosca",    "bonus": "-1 perda no atq", "key": "DEF"},
]

# ----- Estado --------------------------------------------------------------
var player_name: String = "Você"
var cash: int = 0
var clean: int = 0
var soldiers: int = 0
var heat: int = 0
var turn: int = 1
var territories: Array = []   # Array[Dictionary]
var event_log: Array = []     # últimos 20 eventos
var finished: bool = false

# ----- Lifecycle -----------------------------------------------------------
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[Game] autoload ready")
	new_game("Você")


func new_game(p_name: String) -> void:
	player_name = (p_name if p_name.strip_edges() != "" else "Você")
	cash = START_CASH
	clean = START_CLEAN
	soldiers = START_SOLDIERS
	heat = 0
	turn = 1
	finished = false
	event_log.clear()
	_init_territories()
	_log("Bora trampar, " + player_name + ". A quebrada é nossa.", "gold")
	state_changed.emit()


func _init_territories() -> void:
	territories.clear()
	# Cada facção rival ocupa 1 canto, neutro no resto, player numa boca específica.
	var corner_factions := {0: "BV", 3: "CE", 12: "FB", 15: "SV"}
	var player_start := 5  # x=1, y=1 (canto superior esq sem facção)
	for i in range(N_TILES):
		var owner := "NEUTRAL"
		var def := 1
		if corner_factions.has(i):
			owner = corner_factions[i]
			def = 4 + randi() % 2
		elif i == player_start:
			owner = "PLAYER"
			def = 2
		var product_keys := PRODUCT_INFO.keys()
		var product: String = product_keys[randi() % product_keys.size()]
		var t := {
			"id": i,
			"name": TILE_NAMES[i],
			"owner": owner,
			"soldiers": def,
			"base_income": 70 + randi() % 60,   # base R$ por venda
			"base_risk": 4 + randi() % 6,       # base calor por venda
			"product": product,
		}
		territories.append(t)


# ----- Helpers de leitura --------------------------------------------------
func player_tiles() -> Array:
	return territories.filter(func(t): return t.owner == "PLAYER")


func tile_count_owned_by(owner: String) -> int:
	var n := 0
	for t in territories:
		if t.owner == owner:
			n += 1
	return n


func is_adjacent_to_player(idx: int) -> bool:
	var x := idx % GRID_W
	var y := idx / GRID_W
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var nx := x + dx
			var ny := y + dy
			if nx < 0 or nx >= GRID_W or ny < 0 or ny >= GRID_H:
				continue
			var nid := ny * GRID_W + nx
			if territories[nid].owner == "PLAYER":
				return true
	return false


# ----- Ações do jogador ----------------------------------------------------
func tile_income(t: Dictionary) -> int:
	var info: Dictionary = PRODUCT_INFO.get(str(t.get("product", "ERVA")), PRODUCT_INFO["ERVA"])
	return int(int(t.get("base_income", 80)) * float(info.income_mult))


func tile_risk(t: Dictionary) -> int:
	var info: Dictionary = PRODUCT_INFO.get(str(t.get("product", "ERVA")), PRODUCT_INFO["ERVA"])
	var r := int(int(t.get("base_risk", 6)) * float(info.heat_mult))
	return max(1, r)


func sell_at(territory_id: int) -> bool:
	if finished: return false
	if territory_id < 0 or territory_id >= N_TILES: return false
	var t = territories[territory_id]
	if t.owner != "PLAYER":
		_log("Vc não controla " + t.name + ".", "danger")
		return false
	var gain := tile_income(t)
	var r := tile_risk(t)
	cash += gain
	heat = clampi(heat + r, 0, HEAT_CAP)
	var pname: String = str(PRODUCT_INFO.get(str(t.product), {}).get("name", "produto"))
	_log("Vendeu " + pname + " em " + t.name + ": +R$" + str(gain) + " · +" + str(r) + " calor", "gold")
	state_changed.emit()
	_check_loss()
	return true


func attack(territory_id: int) -> bool:
	if finished: return false
	if territory_id < 0 or territory_id >= N_TILES: return false
	var t = territories[territory_id]
	if t.owner == "PLAYER":
		_log("Já é seu.", "muted")
		return false
	if not is_adjacent_to_player(territory_id):
		_log("Boca não é vizinha. Tem que avançar passo a passo.", "danger")
		return false
	if soldiers < t.soldiers + 1:
		_log("Tropa pouca. Precisa " + str(t.soldiers + 1) + ", tem " + str(soldiers) + ".", "danger")
		return false
	# Combate simples: perde X = defensor + variação
	var losses: int = t.soldiers + (randi() % 2)
	soldiers = max(0, soldiers - losses)
	t.owner = "PLAYER"
	t.soldiers = max(1, soldiers / 6)
	heat = clampi(heat + 12, 0, HEAT_CAP)
	_log("Tomou " + t.name + "! Perdeu " + str(losses) + " na tropa · +12 calor", "success")
	state_changed.emit()
	return true


func recruit(amount: int) -> bool:
	if finished: return false
	var cost := amount * RECRUIT_COST_EACH
	if amount <= 0: return false
	if cash < cost:
		_log("Caixa fraco. Precisa R$" + str(cost) + ".", "danger")
		return false
	cash -= cost
	soldiers += amount
	heat = clampi(heat + 2, 0, HEAT_CAP)
	_log("Recrutou +" + str(amount) + " · -R$" + str(cost) + " · +2 calor", "info")
	state_changed.emit()
	return true


func bribe(amount: int) -> bool:
	if finished: return false
	if amount <= 0: return false
	if cash < amount:
		_log("Não tem essa nota.", "danger")
		return false
	# R$50 = -1 calor. Soborno alto rende negociação melhor (escala).
	var drop: int = int(amount / 50.0)
	if amount >= 500:
		drop += 2  # bônus de "presente bom"
	cash -= amount
	heat = clampi(heat - drop, 0, HEAT_CAP)
	_log("Subornou: -R$" + str(amount) + " · -" + str(drop) + " calor", "info")
	state_changed.emit()
	return true


func launder(amount: int) -> bool:
	if finished: return false
	if amount <= 0: return false
	if cash < amount:
		_log("Sem caixa pra lavar.", "danger")
		return false
	var out: int = int(amount * (1.0 - LAUNDER_FEE))
	cash -= amount
	clean += out
	_log("Lavou R$" + str(amount) + " → R$" + str(out) + " limpo (taxa 18%)", "gold")
	state_changed.emit()
	_check_victory()
	return true


func end_turn() -> void:
	if finished: return
	# 1. Renda passiva: cada boca rende metade do "income" sem ato manual,
	#    mas também gera metade do calor.
	var passive_income := 0
	var passive_heat := 0
	for t in territories:
		if t.owner == "PLAYER":
			passive_income += int(tile_income(t) * 0.35)
			passive_heat += int(tile_risk(t) * 0.35)
	cash += passive_income
	heat = clampi(heat + passive_heat, 0, HEAT_CAP)
	if passive_income > 0:
		_log("Renda passiva da quebrada: +R$" + str(passive_income) + " · +" + str(passive_heat) + " calor", "info")

	# 2. Decaimento natural do calor (a cidade esquece um pouco)
	heat = clampi(heat - 3, 0, HEAT_CAP)

	# 3. IA dos rivais
	_rivals_ai()

	# 4. Evento aleatório
	_maybe_random_event()

	# 5. Risco de blitz se calor >= 75
	if heat >= 75:
		_police_raid()

	turn += 1
	turn_ended.emit(turn)
	state_changed.emit()
	_check_victory()
	_check_loss()


func _rivals_ai() -> void:
	for f in RIVALS:
		var aggression: float = RIVAL_AGGRESSION.get(f, 0.4)
		if randf() > aggression:
			continue
		# Lista todos os tiles dessa facção
		var my_tiles: Array = territories.filter(func(t): return t.owner == f)
		if my_tiles.is_empty():
			continue
		var src = my_tiles.pick_random()
		# Encontra vizinho do PLAYER ou NEUTRAL
		var x: int = int(src.id) % GRID_W
		var y: int = int(src.id) / GRID_W
		var targets := []
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx == 0 and dy == 0: continue
				var nx := x + dx
				var ny := y + dy
				if nx < 0 or nx >= GRID_W or ny < 0 or ny >= GRID_H: continue
				var nid := ny * GRID_W + nx
				var n = territories[nid]
				if n.owner != f:
					targets.append(n)
		if targets.is_empty():
			continue
		var target = targets.pick_random()
		var attacker_strength: int = int(src.soldiers) + randi() % 3
		if attacker_strength > target.soldiers:
			var prev_owner: String = target.owner
			target.owner = f
			target.soldiers = max(1, attacker_strength - target.soldiers)
			src.soldiers = max(1, src.soldiers - 1)
			if prev_owner == "PLAYER":
				_log(FACTION_NAMES[f] + " invadiu " + target.name + " na sua cara!", "danger")
			else:
				_log(FACTION_NAMES[f] + " avançou em " + target.name + ".", "muted")


func _maybe_random_event() -> void:
	if randf() > 0.28:
		return
	var roll := randi() % 8
	match roll:
		0:
			_log("Sumiu um vapor da tropa. -1 soldado.", "danger")
			soldiers = max(0, soldiers - 1)
		1:
			_log("Boato na quebrada: viatura subindo. +6 calor.", "danger")
			heat = clampi(heat + 6, 0, HEAT_CAP)
		2:
			_log("Vereador pede 'colaboração' pra próxima campanha. -R$200, -4 calor.", "info")
			if cash >= 200:
				cash -= 200
				heat = clampi(heat - 4, 0, HEAT_CAP)
		3:
			_log("Mídia local denuncia operações na sua área. +8 calor.", "danger")
			heat = clampi(heat + 8, 0, HEAT_CAP)
		4:
			_log("Festa na laje rende contatos: +R$150 limpo.", "gold")
			clean += 150
		5:
			_log("Um informante apareceu querendo trocar fita por grana. -R$120, -5 calor.", "info")
			if cash >= 120:
				cash -= 120
				heat = clampi(heat - 5, 0, HEAT_CAP)
		6:
			_log("Soldado fiel trouxe um irmão: +1 soldado de graça.", "success")
			soldiers += 1
		7:
			_log("Encrenca em outra boca: perda de R$80 em produto roubado.", "danger")
			cash = max(0, cash - 80)


func _police_raid() -> void:
	# Quanto maior o calor, pior a operação.
	var severity := heat - 70  # 5..30
	if cash >= severity * 80:
		# Suborno emergencial: paga mas continua.
		var bribe_cost: int = severity * 80
		cash -= bribe_cost
		heat = clampi(heat - 25, 0, HEAT_CAP)
		_log("Operação policial! Você subornou na hora: -R$" + str(bribe_cost) + ", -25 calor.", "danger")
		return

	# Sem grana suficiente: perde a boca mais vulnerável + soldados
	var my_tiles: Array = player_tiles()
	if my_tiles.is_empty():
		_log("Operação policial e nada pra perder além de você mesmo. -10 soldados.", "danger")
		soldiers = max(0, soldiers - 10)
		heat = clampi(heat - 40, 0, HEAT_CAP)
		return
	var target = my_tiles.pick_random()
	target.owner = "NEUTRAL"
	target.soldiers = 0
	soldiers = max(0, soldiers - 3)
	heat = clampi(heat - 35, 0, HEAT_CAP)
	_log("BLITZ na " + target.name + "! Perdeu a boca, -3 soldados, -35 calor.", "danger")


# ----- Vitória / derrota ---------------------------------------------------
func _check_victory() -> void:
	if finished: return
	if clean >= VICTORY_CLEAN and tile_count_owned_by("PLAYER") >= N_TILES:
		finished = true
		_log("DOMÍNIO TOTAL. Vc mandou na quebrada inteira e lavou um milhão. Lenda.", "gold")
		game_finished.emit(true, "Domínio total + R$1M lavado.")


func _check_loss() -> void:
	if finished: return
	if tile_count_owned_by("PLAYER") == 0 and cash < 80:
		finished = true
		_log("Fim de linha. Sem boca, sem grana, sem corre.", "danger")
		game_finished.emit(false, "Sem território e sem caixa.")
		return
	if heat >= HEAT_CAP and cash < 100:
		finished = true
		_log("Caiu. O bagulho ficou doido e o calor te pegou.", "danger")
		game_finished.emit(false, "Calor máximo sem grana pra subornar.")


# ----- Log ----------------------------------------------------------------
func _log(msg: String, tone: String = "muted") -> void:
	event_log.push_front({"turn": turn, "msg": msg, "tone": tone})
	if event_log.size() > 20:
		event_log.resize(20)
	log_event.emit(msg, tone)


# ----- Save (opcional, encriptado simples) ---------------------------------
const SAVE_PATH := "user://save.dat"
const SAVE_KEY := "porto-santiago-quebrada-v1"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var data := {
		"v": 1,
		"player_name": player_name,
		"cash": cash, "clean": clean, "soldiers": soldiers,
		"heat": heat, "turn": turn,
		"territories": territories,
		"event_log": event_log,
		"finished": finished,
	}
	var json := JSON.stringify(data)
	var f := FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.WRITE, SAVE_KEY)
	if f == null:
		f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("save: não abriu o arquivo")
		return false
	f.store_string(json)
	f.close()
	return true


func load_game() -> bool:
	if not has_save(): return false
	var f := FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.READ, SAVE_KEY)
	if f == null:
		f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null: return false
	var raw := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary): return false
	var d: Dictionary = parsed
	player_name = d.get("player_name", "Você")
	cash = int(d.get("cash", START_CASH))
	clean = int(d.get("clean", 0))
	soldiers = int(d.get("soldiers", START_SOLDIERS))
	heat = int(d.get("heat", 0))
	turn = int(d.get("turn", 1))
	finished = bool(d.get("finished", false))
	var loaded_t: Array = d.get("territories", [])
	if loaded_t.size() == N_TILES:
		territories = loaded_t
	else:
		_init_territories()
	event_log = d.get("event_log", [])
	state_changed.emit()
	return true
