class_name CombatUnit
extends RefCounted
## Unidade de combate tático. Dados puros — o rendering é com botões na grade.

enum Side { PLAYER, ENEMY }

var id: int = 0
var side: Side = Side.PLAYER
var name: String = ""
var hp: int = 5
var max_hp: int = 5
var ap_max: int = 2
var ap: int = 2
var move_range: int = 4
var atk_range: int = 3
var damage: int = 2
var pos: Vector2i = Vector2i.ZERO
var alive: bool = true


static func make_player(p_id: int, p_name: String, p_pos: Vector2i) -> CombatUnit:
	var u := CombatUnit.new()
	u.id = p_id
	u.side = Side.PLAYER
	u.name = p_name
	u.hp = 6
	u.max_hp = 6
	u.damage = 2
	u.pos = p_pos
	return u


static func make_enemy(p_id: int, p_name: String, p_pos: Vector2i) -> CombatUnit:
	var u := CombatUnit.new()
	u.id = p_id
	u.side = Side.ENEMY
	u.name = p_name
	u.hp = 5
	u.max_hp = 5
	u.damage = 2
	u.atk_range = 2
	u.move_range = 3
	u.pos = p_pos
	return u
