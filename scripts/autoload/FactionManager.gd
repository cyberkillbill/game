extends Node
## FactionManager — cria e mantém facções, territórios, relações diplomáticas.

const PLAYER_ID := &"PLAYER"

var factions: Dictionary = {}        # StringName -> Faction
var territories: Dictionary = {}     # StringName -> Territory


func _ready() -> void:
	if factions.is_empty():
		reset()


func reset() -> void:
	factions.clear()
	territories.clear()
	_seed_factions()
	_seed_territories()


# ---- Seed -----------------------------------------------------------------

func _seed_factions() -> void:
	var pf := Faction.make(PLAYER_ID, "Sua Organização", "VOCÊ", Palette.FACTION_COLORS["PLAYER"], "—", Faction.Personality.OPPORTUNIST, "Você manda aqui.")
	factions[PLAYER_ID] = pf

	var defs: Array = [
		{
			"id": &"CDM", "name": "Comando da Marina", "short": "CDM",
			"specialty": "Contrabando portuário", "p": Faction.Personality.AGGRESSIVE,
			"desc": "Domina o cais e a frente turística. Caixa cheio, pavio curto."
		},
		{
			"id": &"ADS", "name": "Aliança da Serra", "short": "ADS",
			"specialty": "Transporte e rotas", "p": Faction.Personality.OPPORTUNIST,
			"desc": "Controla os morros do norte. Boa em logística, vende lealdade."
		},
		{
			"id": &"SV", "name": "Sindicato Vermelho", "short": "SV",
			"specialty": "Mercado paralelo", "p": Faction.Personality.MERCHANT,
			"desc": "Donos do Centro Velho. Negociam tudo, traem por troco."
		},
		{
			"id": &"NPS", "name": "Núcleo do Porto Sul", "short": "NPS",
			"specialty": "Indústria pesada", "p": Faction.Personality.LOYAL,
			"desc": "Disciplinados, hereditários. Não se enganam fácil."
		},
		{
			"id": &"IBE", "name": "Irmandade do Bairro Esquecido", "short": "IBE",
			"specialty": "Cultura de rua", "p": Faction.Personality.ISOLATIONIST,
			"desc": "Pequena, fechada, perigosa quando provocada."
		},
	]
	for d in defs:
		var f := Faction.make(d["id"], d["name"], d["short"], Palette.FACTION_COLORS[String(d["id"])], d["specialty"], d["p"], d["desc"])
		f.capital = randi_range(8000, 22000)
		f.soldiers = randi_range(3, 8)
		f.relation = 0
		factions[d["id"]] = f


func _seed_territories() -> void:
	# Layout 3 colunas x 4 linhas. Coordenadas relativas à viewport do mapa.
	# x: ~80..820, y: ~80..1100. map_size padrão 220x180.
	var col_x := [60.0, 320.0, 580.0]
	var row_y := [60.0, 260.0, 460.0, 660.0]

	var defs: Array = [
		{"id": &"centro_velho",   "name": "Centro Velho",        "p": Territory.Profile.COMMERCIAL,        "inc": 900,  "heat": 1, "owner": &"SV"},
		{"id": &"marina_alta",    "name": "Marina Alta",         "p": Territory.Profile.TOURIST,           "inc": 1900, "heat": 5, "owner": &"CDM"},
		{"id": &"morro_cruzeiro", "name": "Morro do Cruzeiro",   "p": Territory.Profile.RESIDENTIAL_LOW,   "inc": 500,  "heat": 2, "owner": &"ADS"},
		{"id": &"distrito_ind",   "name": "Distrito Industrial", "p": Territory.Profile.INDUSTRIAL,        "inc": 1500, "heat": 3, "owner": &"NPS"},
		{"id": &"porto_sul",      "name": "Porto Sul",           "p": Territory.Profile.PORT,              "inc": 1700, "heat": 4, "owner": &"NPS"},
		{"id": &"vila_aurora",    "name": "Vila Aurora",         "p": Territory.Profile.RESIDENTIAL_HIGH,  "inc": 1200, "heat": 4, "owner": &"NEUTRAL"},
		{"id": &"bairro_porto",   "name": "Bairro do Porto",     "p": Territory.Profile.NIGHTLIFE,         "inc": 1100, "heat": 5, "owner": &"PLAYER"},
		{"id": &"praca_real",     "name": "Praça Real",          "p": Territory.Profile.INSTITUTIONAL,     "inc": 700,  "heat": 6, "owner": &"NEUTRAL"},
		{"id": &"morro_alegre",   "name": "Morro Alegre",        "p": Territory.Profile.RESIDENTIAL_LOW,   "inc": 550,  "heat": 2, "owner": &"ADS"},
		{"id": &"jardim_sereia",  "name": "Jardim Sereia",       "p": Territory.Profile.RESIDENTIAL_HIGH,  "inc": 1300, "heat": 4, "owner": &"NEUTRAL"},
		{"id": &"bairro_esq",     "name": "Bairro Esquecido",    "p": Territory.Profile.RESIDENTIAL_LOW,   "inc": 600,  "heat": 2, "owner": &"IBE"},
		{"id": &"cais_velho",     "name": "Cais Velho",          "p": Territory.Profile.PORT,              "inc": 1400, "heat": 4, "owner": &"CDM"},
	]
	for i in defs.size():
		var d: Dictionary = defs[i]
		var c := i % 3
		var r := i / 3
		var pos := Vector2(col_x[c], row_y[r])
		var t := Territory.make(d["id"], d["name"], d["p"], d["inc"], d["heat"], pos, d["owner"])
		t.operations = 1 if d["owner"] == PLAYER_ID else 0
		territories[d["id"]] = t


# ---- Queries --------------------------------------------------------------

func player_faction() -> Faction:
	return factions.get(PLAYER_ID)


func rival_factions() -> Array[Faction]:
	var out: Array[Faction] = []
	for id in factions:
		if id != PLAYER_ID:
			out.append(factions[id])
	return out


func player_territories() -> Array[Territory]:
	var out: Array[Territory] = []
	for t in territories.values():
		if t.owner_id == PLAYER_ID:
			out.append(t)
	return out


func territories_of(owner: StringName) -> Array[Territory]:
	var out: Array[Territory] = []
	for t in territories.values():
		if t.owner_id == owner:
			out.append(t)
	return out


func get_faction(id: StringName) -> Faction:
	return factions.get(id)


func get_territory(id: StringName) -> Territory:
	return territories.get(id)


func faction_color(owner_id: StringName) -> Color:
	if owner_id == &"NEUTRAL":
		return Palette.FACTION_COLORS["NEUTRAL"]
	var f: Faction = factions.get(owner_id)
	if f:
		return f.color
	return Palette.FACTION_COLORS["NEUTRAL"]


# ---- Tick por turno -------------------------------------------------------

func tick_relations() -> void:
	# Pequena oscilação natural baseada em personalidade.
	for f in rival_factions():
		var drift := 0
		match f.personality:
			Faction.Personality.AGGRESSIVE:    drift = randi_range(-3, 1)
			Faction.Personality.OPPORTUNIST:   drift = randi_range(-2, 2)
			Faction.Personality.MERCHANT:      drift = randi_range(-1, 2)
			Faction.Personality.ISOLATIONIST:  drift = randi_range(-2, 1)
			Faction.Personality.LOYAL:         drift = randi_range(-1, 1)
		f.relation = clampi(f.relation + drift, -100, 100)


func maybe_trigger_raid() -> void:
	# Facções inimigas atacam um território do jogador se hostis e a chance fechar.
	var pt := player_territories()
	if pt.is_empty():
		return
	for f in rival_factions():
		if f.relation > -40:
			continue
		if randf() > 0.18:
			continue
		var target: Territory = pt.pick_random()
		target.operations = maxi(0, target.operations - 1)
		GameManager.capital = maxi(0, GameManager.capital - 1200)
		GameManager.add_loyalty(-5)
		GameManager.log_event("%s atacou %s. Operação destruída." % [f.short_name, target.name], StatBadge.Tone.DANGER)
		break


# ---- Ações diplomáticas ---------------------------------------------------

func offer_truce(f: Faction) -> bool:
	const COST := 1500
	if GameManager.capital < COST:
		return false
	GameManager.capital -= COST
	f.relation = clampi(f.relation + 25, -100, 100)
	GameManager.log_event("Trégua oferecida a %s. (+25 relação)" % f.short_name, StatBadge.Tone.SUCCESS)
	GameManager.game_state_changed.emit()
	return true


func offer_alliance(f: Faction) -> bool:
	const COST := 6000
	if GameManager.capital < COST:
		return false
	if f.relation < 40:
		GameManager.log_event("%s ainda não confia em você." % f.short_name, StatBadge.Tone.DANGER)
		return false
	GameManager.capital -= COST
	f.relation = clampi(f.relation + 35, -100, 100)
	GameManager.add_influence(8)
	GameManager.log_event("Aliança selada com %s." % f.short_name, StatBadge.Tone.GOLD)
	GameManager.game_state_changed.emit()
	return true


func threaten(f: Faction) -> bool:
	if GameManager.soldiers < 3:
		GameManager.log_event("Tropa insuficiente pra ameaçar.", StatBadge.Tone.DANGER)
		return false
	f.relation = clampi(f.relation - 20, -100, 100)
	if randf() < 0.4:
		GameManager.add_influence(4)
		GameManager.log_event("Ameaça surtiu efeito sobre %s. +4 Influência." % f.short_name, StatBadge.Tone.SUCCESS)
	else:
		GameManager.add_heat(6)
		GameManager.log_event("%s ignorou a ameaça. +6 Calor." % f.short_name, StatBadge.Tone.DANGER)
	GameManager.game_state_changed.emit()
	return true


func bribe_faction(f: Faction, amount: int) -> bool:
	if GameManager.capital < amount or amount <= 0:
		return false
	GameManager.capital -= amount
	var bonus := clampi(amount / 400, 2, 25)
	f.relation = clampi(f.relation + bonus, -100, 100)
	GameManager.log_event("Presente a %s: +%d relação." % [f.short_name, bonus], StatBadge.Tone.GOLD)
	GameManager.game_state_changed.emit()
	return true


# ---- Combate territorial --------------------------------------------------

func resolve_combat_victory(territory: Territory, defending_faction: StringName) -> void:
	var prev_owner: StringName = territory.owner_id
	territory.owner_id = PLAYER_ID
	territory.operations = 1
	territory.defenders = 0
	GameManager.add_influence(12)
	var f: Faction = factions.get(prev_owner)
	if f:
		f.relation = clampi(f.relation - 30, -100, 100)
		f.territories.erase(territory.id)
	GameManager.log_event("Você conquistou %s." % territory.name, StatBadge.Tone.SUCCESS)
	GameManager.game_state_changed.emit()


func resolve_combat_defeat(territory: Territory) -> void:
	GameManager.soldiers = maxi(0, GameManager.soldiers - 2)
	GameManager.add_loyalty(-8)
	GameManager.add_heat(5)
	GameManager.log_event("Derrota em %s. Tropa abalada." % territory.name, StatBadge.Tone.DANGER)
	GameManager.game_state_changed.emit()


# ---- Serialização --------------------------------------------------------

func serialize() -> Array:
	var out: Array = []
	for f in factions.values():
		out.append({
			"id": String(f.id),
			"name": f.name,
			"short_name": f.short_name,
			"color": f.color.to_html(),
			"specialty": f.specialty,
			"personality": int(f.personality),
			"description": f.description,
			"relation": f.relation,
			"capital": f.capital,
			"soldiers": f.soldiers,
		})
	return out


func serialize_territories() -> Array:
	var out: Array = []
	for t in territories.values():
		out.append({
			"id": String(t.id),
			"owner_id": String(t.owner_id),
			"operations": t.operations,
			"defenders": t.defenders,
		})
	return out


func deserialize(arr: Array) -> void:
	for d in arr:
		var id := StringName(d.get("id", ""))
		var f: Faction = factions.get(id)
		if f:
			f.relation = d.get("relation", 0)
			f.capital = d.get("capital", 0)
			f.soldiers = d.get("soldiers", 0)


func deserialize_territories(arr: Array) -> void:
	for d in arr:
		var id := StringName(d.get("id", ""))
		var t: Territory = territories.get(id)
		if t:
			t.owner_id = StringName(d.get("owner_id", "NEUTRAL"))
			t.operations = d.get("operations", 0)
			t.defenders = d.get("defenders", 0)
