class_name PlayerCharacter
extends Resource
## Personagem do protagonista. Customizável no editor.

enum SkinTone { LIGHT, MEDIUM_LIGHT, MEDIUM, MEDIUM_DARK, DARK }
enum HairStyle { SHORT, FADE, CURLY, LONG, BALD, BRAIDS }
enum FacialHair { NONE, MUSTACHE, GOATEE, FULL_BEARD, STUBBLE }
enum JerseyTeam {
	# 8 times fictícios — vibe BR mas sem reproduzir nenhum real.
	ATLETICO_LITORAL,
	REAL_SERRANO,
	UNIAO_PORTUARIA,
	GREMIO_PALMARES,
	ESPORTE_CENTRAL,
	JUVENTUDE_ATLANTICA,
	NACIONAL_DO_VALE,
	INDEPENDENTE_FC
}

@export var nickname: String = "Apelido"
@export var skin: SkinTone = SkinTone.MEDIUM
@export var hair: HairStyle = HairStyle.SHORT
@export var facial: FacialHair = FacialHair.NONE
@export var jersey: JerseyTeam = JerseyTeam.ATLETICO_LITORAL
@export var has_tattoo: bool = false


static func default_char() -> PlayerCharacter:
	var c := PlayerCharacter.new()
	c.nickname = "Patrão"
	return c


static func team_name(team: JerseyTeam) -> String:
	match team:
		JerseyTeam.ATLETICO_LITORAL:    return "Atlético Litoral"
		JerseyTeam.REAL_SERRANO:        return "Real Serrano"
		JerseyTeam.UNIAO_PORTUARIA:     return "União Portuária"
		JerseyTeam.GREMIO_PALMARES:     return "Grêmio Palmares"
		JerseyTeam.ESPORTE_CENTRAL:     return "Esporte Central"
		JerseyTeam.JUVENTUDE_ATLANTICA: return "Juventude Atlântica"
		JerseyTeam.NACIONAL_DO_VALE:    return "Nacional do Vale"
		JerseyTeam.INDEPENDENTE_FC:     return "Independente FC"
		_:                              return "—"


static func team_colors(team: JerseyTeam) -> Array[Color]:
	# Pares de cores fictícias para o brasão/camisa.
	match team:
		JerseyTeam.ATLETICO_LITORAL:    return [Color("0ea5e9"), Color("f8fafc")]
		JerseyTeam.REAL_SERRANO:        return [Color("16a34a"), Color("eab308")]
		JerseyTeam.UNIAO_PORTUARIA:     return [Color("ef4444"), Color("1e293b")]
		JerseyTeam.GREMIO_PALMARES:     return [Color("7c3aed"), Color("f1f5f9")]
		JerseyTeam.ESPORTE_CENTRAL:     return [Color("f97316"), Color("0f172a")]
		JerseyTeam.JUVENTUDE_ATLANTICA: return [Color("0891b2"), Color("fef3c7")]
		JerseyTeam.NACIONAL_DO_VALE:    return [Color("e11d48"), Color("fafafa")]
		JerseyTeam.INDEPENDENTE_FC:     return [Color("1e293b"), Color("fbbf24")]
		_:                              return [Color.WHITE, Color.BLACK]


func skin_color() -> Color:
	match skin:
		SkinTone.LIGHT:        return Color("f3d5b5")
		SkinTone.MEDIUM_LIGHT: return Color("d4a574")
		SkinTone.MEDIUM:       return Color("b08660")
		SkinTone.MEDIUM_DARK:  return Color("8b5a3c")
		SkinTone.DARK:         return Color("5d3a23")
		_:                     return Color("b08660")


func to_dict() -> Dictionary:
	return {
		"nickname": nickname,
		"skin": int(skin),
		"hair": int(hair),
		"facial": int(facial),
		"jersey": int(jersey),
		"has_tattoo": has_tattoo,
	}


static func from_dict(d: Dictionary) -> PlayerCharacter:
	var c := PlayerCharacter.new()
	c.nickname = d.get("nickname", "Patrão")
	c.skin = d.get("skin", SkinTone.MEDIUM)
	c.hair = d.get("hair", HairStyle.SHORT)
	c.facial = d.get("facial", FacialHair.NONE)
	c.jersey = d.get("jersey", JerseyTeam.ATLETICO_LITORAL)
	c.has_tattoo = d.get("has_tattoo", false)
	return c
