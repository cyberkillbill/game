class_name Faction
extends Resource
## Facção rival fictícia.

enum Personality { AGGRESSIVE, OPPORTUNIST, MERCHANT, ISOLATIONIST, LOYAL }

@export var id: StringName = &""
@export var name: String = ""
@export var short_name: String = ""
@export var color: Color = Color.WHITE
@export var specialty: String = ""
@export var personality: Personality = Personality.OPPORTUNIST
@export var description: String = ""

# Estado mutável durante a partida:
var relation: int = 0           # -100 (guerra) ... +100 (aliança)
var capital: int = 0
var soldiers: int = 0
var territories: Array[StringName] = []


static func make(p_id: StringName, p_name: String, p_short: String, p_color: Color, p_specialty: String, p_personality: Personality, p_desc: String) -> Faction:
	var f := Faction.new()
	f.id = p_id
	f.name = p_name
	f.short_name = p_short
	f.color = p_color
	f.specialty = p_specialty
	f.personality = p_personality
	f.description = p_desc
	return f


func relation_label() -> String:
	if relation >= 75: return "Aliada"
	if relation >= 30: return "Amistosa"
	if relation >= -10: return "Neutra"
	if relation >= -50: return "Hostil"
	return "Em guerra"
