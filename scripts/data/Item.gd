class_name Item
extends Resource
## Equipamento ou mercadoria (tudo fictício e estilizado).

enum Category { LIGHT_WEAPON, MEDIUM_WEAPON, HEAVY_WEAPON, SPECIAL, VEHICLE, GOODS, GEAR }

@export var id: StringName = &""
@export var name: String = ""
@export var category: Category = Category.LIGHT_WEAPON
@export var cost: int = 0
@export var damage: int = 0          # 0 para itens não-letais
@export var range_tiles: int = 1
@export var description: String = ""


static func make(p_id: StringName, p_name: String, p_cat: Category, p_cost: int, p_dmg: int, p_range: int, p_desc: String) -> Item:
	var it := Item.new()
	it.id = p_id
	it.name = p_name
	it.category = p_cat
	it.cost = p_cost
	it.damage = p_dmg
	it.range_tiles = p_range
	it.description = p_desc
	return it


func category_label() -> String:
	match category:
		Category.LIGHT_WEAPON:  return "Arma Leve"
		Category.MEDIUM_WEAPON: return "Arma Média"
		Category.HEAVY_WEAPON:  return "Arma Pesada"
		Category.SPECIAL:       return "Especial"
		Category.VEHICLE:       return "Veículo"
		Category.GOODS:         return "Mercadoria"
		Category.GEAR:          return "Equipamento"
		_:                      return "—"
