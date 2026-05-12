class_name Territory
extends Resource
## Zona/distrito da metrópole fictícia Porto Santiago.

enum Profile { COMMERCIAL, TOURIST, INDUSTRIAL, RESIDENTIAL_LOW, RESIDENTIAL_HIGH, PORT, NIGHTLIFE, INSTITUTIONAL }

@export var id: StringName = &""
@export var name: String = ""
@export var profile: Profile = Profile.COMMERCIAL
@export var base_income: int = 0
@export var base_heat: int = 0
@export var map_position: Vector2 = Vector2.ZERO
@export var map_size: Vector2 = Vector2(220, 180)

# Estado mutável:
var owner_id: StringName = &"NEUTRAL"
var operations: int = 0          # nº de pontos de operação instalados (max 3)
var defenders: int = 0           # soldados alocados defendendo
var raid_cooldown: int = 0


static func make(p_id: StringName, p_name: String, p_profile: Profile, p_income: int, p_heat: int, p_pos: Vector2, p_owner: StringName) -> Territory:
	var t := Territory.new()
	t.id = p_id
	t.name = p_name
	t.profile = p_profile
	t.base_income = p_income
	t.base_heat = p_heat
	t.map_position = p_pos
	t.owner_id = p_owner
	return t


func profile_label() -> String:
	match profile:
		Profile.COMMERCIAL:         return "Comercial"
		Profile.TOURIST:            return "Turístico"
		Profile.INDUSTRIAL:         return "Industrial"
		Profile.RESIDENTIAL_LOW:    return "Residencial Popular"
		Profile.RESIDENTIAL_HIGH:   return "Residencial Nobre"
		Profile.PORT:               return "Portuário"
		Profile.NIGHTLIFE:          return "Vida Noturna"
		Profile.INSTITUTIONAL:      return "Institucional"
		_:                          return "—"


func current_income() -> int:
	return base_income + operations * int(base_income * 0.4)


func current_heat() -> int:
	return base_heat + operations * 2
