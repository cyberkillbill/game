class_name Palette
extends RefCounted
## Paleta única do jogo — Dark Premium.
## Tudo derivado daqui pra manter consistência visual.

const BG_BASE        := Color("0a0a0f")
const BG_SURFACE     := Color("13131a")
const BG_ELEVATED    := Color("1c1c26")
const BG_OVERLAY     := Color(0.039, 0.039, 0.058, 0.85)

const ACCENT_PRIMARY := Color("dc2626")  # vermelho escuro / poder
const ACCENT_GOLD    := Color("fbbf24")  # dourado / dinheiro
const ACCENT_BLUE    := Color("3b82f6")  # informação
const ACCENT_DANGER  := Color("ef4444")  # calor
const ACCENT_SUCCESS := Color("10b981")  # ganho

const TEXT_PRIMARY   := Color("f5f5f7")
const TEXT_SECONDARY := Color("a1a1aa")
const TEXT_MUTED     := Color("71717a")
const BORDER_SUBTLE  := Color(1, 1, 1, 0.08)
const BORDER_STRONG  := Color(1, 1, 1, 0.16)

## Cores oficiais de cada facção ficcional.
const FACTION_COLORS := {
	"CDM": Color("ef4444"),   # Comando da Marina — vermelho coral
	"ADS": Color("10b981"),   # Aliança da Serra — verde esmeralda
	"SV":  Color("f59e0b"),   # Sindicato Vermelho — âmbar
	"NPS": Color("8b5cf6"),   # Núcleo do Porto Sul — roxo
	"IBE": Color("06b6d4"),   # Irmandade do Bairro Esquecido — ciano
	"PLAYER": Color("fbbf24"),
	"NEUTRAL": Color("3f3f46"),
}
