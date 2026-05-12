# Porto Santiago — *Money, Power, Respect* (BR)

Drama criminal estratégico turn-based para Android, ambientado em uma metrópole brasileira **fictícia** chamada **Porto Santiago**. Inspirado em *Scarface: Money, Power, Respect* (PSP, 2006) com vibe *GTA / Mafia / Civilization*.

> ⚠️ **Tudo é ficção.** Nenhuma pessoa, organização, instituição, marca, time ou arma real é referenciada. Estética brasileira tratada com respeito — sem caricaturar comunidades reais.

---

## Stack

- **Engine:** Godot 4.3 (GDScript)
- **Target:** Android, API 26+ (portrait obrigatório)
- **Resolução base:** 1080×2400, layout responsivo
- **Idioma:** pt-BR (CSV de i18n em `translations/pt_br.csv`)
- **Persistência:** local (JSON encriptado em `user://`), cloud save opcional via Firebase

## Como rodar

1. Abra o projeto no **Godot 4.3** (`File > Open > project.godot`).
2. Conecte um aparelho Android com depuração USB ativada.
3. Use a preset **"Android Debug"** em `Project > Export` (configure o Android SDK em `Editor Settings > Export > Android` antes).
4. Para release, configure um keystore em `android/keystore.cfg` (gitignored) e use a preset **"Android Release"** para gerar AAB.

## Estrutura

```
porto_santiago/
├── project.godot              # config principal (mobile, portrait, autoloads)
├── export_presets.cfg         # Android Debug + Release
├── icon.svg                   # ícone do app
├── scenes/                    # .tscn por tela
│   ├── main_menu/
│   ├── map/                   # mapa estratégico das 12 zonas
│   ├── combat/                # combate tático 8×8
│   ├── diplomacy/
│   ├── management/
│   ├── character/             # editor de personagem
│   └── ui/                    # componentes reutilizáveis
├── scripts/
│   ├── autoload/              # singletons (GameManager, SaveManager, ...)
│   ├── entities/
│   ├── ui/
│   └── data/
├── resources/                 # .tres tipados
│   ├── factions/
│   ├── territories/
│   ├── items/
│   └── characters/
├── assets/
│   ├── fonts/                 # General Sans, Satoshi, JetBrains Mono
│   ├── ui/                    # tema, ícones, frames
│   ├── characters/
│   ├── audio/
│   └── shaders/
├── translations/
│   └── pt_br.csv
└── android/                   # build template + keystore config (gitignored)
```

## Autoloads (singletons)

Configurados em `project.godot`. Stubs criados no Passo 1, lógica vem nos passos seguintes:

| Autoload         | Função                                                 |
|------------------|--------------------------------------------------------|
| `GameManager`    | Estado global do jogo, controle de turnos              |
| `SaveManager`    | Save/load local + stub cloud (Firebase)                |
| `EconomyManager` | Capital, renda, manutenção, lavagem                    |
| `HeatManager`    | Nível de calor (autoridades fictícias: GM / ETE / FFI) |
| `FactionManager` | Facções rivais, território, diplomacia                 |
| `AudioManager`   | Música e SFX                                            |

## Roadmap (versão 1)

- [x] **Passo 1** — Setup inicial (Godot project, Android export, estrutura, .gitignore)
- [ ] **Passo 2** — Design System (fontes, theme.tres, componentes UI)
- [ ] **Passo 3** — Tela de Menu Principal
- [ ] **Passo 4** — GameManager + SaveManager (lógica completa)
- [ ] **Passo 5** — Mapa Estratégico + 12 zonas + 5 facções
- [ ] **Passo 6** — Sistema de turnos (5 fases) + eventos
- [ ] **Passo 7** — Stubs das demais telas

## Regras de conteúdo

- Tudo ficcional: cidade, facções, autoridades, times, armas, veículos, marcas.
- "Mercadoria" abstrata em tiers (estilo *Tropico*) — sem detalhes de substâncias reais.
- Classificação alvo: **16+/18+** (drama criminal estilizado).
- Sem caricaturas ofensivas; estética BR com respeito.

## Licença

A definir.
