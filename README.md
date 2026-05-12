# Porto Santiago — *Money, Power, Respect* (BR)

Drama criminal estratégico turn-based para Android, ambientado em uma metrópole brasileira **fictícia** chamada **Porto Santiago**. Inspirado em *Scarface: Money, Power, Respect* (PSP, 2006) com vibe *GTA / Mafia / Civilization*.

> ⚠️ **Tudo é ficção.** Nenhuma pessoa, organização, instituição, marca, time ou arma real é referenciada. Estética brasileira tratada com respeito — sem caricaturar comunidades reais.

---

## Como baixar o APK no celular (sem PC)

1. Abra este repositório no celular pelo navegador.
2. Toque na aba **Actions**.
3. Toque no workflow run mais recente que aparece com ✅ verde (título *"Build Android APK"*).
4. Role pra baixo até **Artifacts** → toque em `porto-santiago-android-debug`.
5. O GitHub vai baixar um `.zip` — extraia (qualquer file manager faz isso).
6. Toque no `.apk` extraído.
7. Permita "Instalar de fontes desconhecidas" pro app que abriu o APK.
8. Instale e jogue.

**Dica:** o primeiro build pode demorar ~15 min porque o cache do Godot está vazio. Builds seguintes são rápidos (~5 min) porque o Godot fica em cache.

Se o build falhar, o log fica visível na mesma página — me mande o erro que ajusto.

---

## O jogo

Você é um patrão recém-chegado em Porto Santiago, controlando o **Bairro do Porto** (vida noturna). Sua missão: expandir o império conquistando os outros 11 distritos das mãos de 5 facções rivais fictícias, sem que o Calor te derrube.

### Loop de uma semana (turno)

Toda vez que você toca em **"Encerrar Semana →"**, 5 fases rodam em sequência:

1. **Econômica** — coleta de renda dos seus territórios
2. **Recrutamento** — lealdade alta atrai recruta, lealdade baixa causa deserção
3. **Diplomática** — facções rivais oscilam relação
4. **Tática** — facções hostis podem atacar seus territórios
5. **Manutenção** — paga folha de soldados e operações; Calor decai um pouco

### Recursos

| Recurso        | O que é                                                       |
|----------------|---------------------------------------------------------------|
| **Capital**    | Dinheiro sujo da economia paralela. Gasta em quase tudo.      |
| **Limpo**      | Capital lavado, usável publicamente. Não rola Calor extra.    |
| **Influência** | Reputação na rua. Sobe com vitórias, alianças, ameaças.       |
| **Calor**      | Atenção das autoridades fictícias (GM → ETE → FFI).           |
| **Lealdade**   | Moral da tropa. Baixa = deserções.                            |
| **Tropa**      | Soldados disponíveis pra combate e defesa.                    |

### Telas

- **Menu Principal** — Novo Jogo, Continuar, Sobre.
- **Editor de Personagem** — apelido, tom de pele, cabelo, barba, **camisa de time fictício** (8 times inventados com brasão estilizado), tatuagem.
- **Mapa Estratégico** — 12 distritos coloridos pela facção dominante. Toque pra abrir painel com renda, calor, ações. HUD top com 6 stats. Diário de eventos.
- **Diplomacia** — 5 facções com relação, barra de afinidade, ações: Trégua / Presente / Aliança / Ameaça.
- **Gestão** — overview do império, lavagem de capital (taxa 18%), suborno (reduz Calor), recrutamento, lista de territórios.
- **Combate Tático** — grid 8×8 estilo XCOM lite. Mova suas unidades (♟), ataque inimigos (✪) dentro do alcance. Vitória = território conquistado.

---

## Stack técnica

- **Engine:** Godot 4.3 (GDScript)
- **Target:** Android API 26+ (portrait obrigatório, 1080×2400 base)
- **Idioma:** pt-BR (CSV de i18n em `translations/pt_br.csv`)
- **Persistência:** local em `user://save.json` (encriptado quando suportado), com stub pra cloud sync
- **Estilo visual:** procedural stylized (cards arredondados, paleta dark premium, sem dependência de assets externos)

### Paleta

```
bg-base       #0a0a0f      accent-primary  #dc2626 (poder)
bg-surface    #13131a      accent-gold     #fbbf24 (dinheiro)
bg-elevated   #1c1c26      accent-blue     #3b82f6 (info)
text-primary  #f5f5f7      accent-danger   #ef4444 (calor)
text-muted    #71717a      accent-success  #10b981 (ganho)
```

---

## Estrutura

```
porto_santiago/
├── project.godot              # config principal (mobile portrait, 6 autoloads)
├── export_presets.cfg         # Android Debug + Release
├── icon.svg                   # ícone do app
├── .github/workflows/
│   └── build-android.yml      # CI: builda APK a cada push, gratuito
├── scenes/                    # .tscn de cada tela (esqueleto mínimo)
│   ├── main_menu/MainMenu.tscn
│   ├── map/StrategicMap.tscn
│   ├── combat/TacticalCombat.tscn
│   ├── diplomacy/DiplomacyScreen.tscn
│   ├── management/ManagementScreen.tscn
│   └── character/CharacterEditor.tscn
├── scripts/
│   ├── autoload/              # 6 singletons (estado global)
│   ├── ui/                    # scripts de tela + componentes (PrimaryButton, Card, StatBadge, IconButton, ThemeBuilder)
│   ├── entities/              # CombatUnit
│   └── data/                  # Palette, Faction, Territory, Item, PlayerCharacter
├── assets/                    # fonts/, ui/, audio/, characters/ (vazias por enquanto)
├── translations/pt_br.csv
└── android/                   # build template gerado pelo Godot (gitignored)
```

---

## Autoloads (singletons)

| Autoload         | Função                                                        |
|------------------|---------------------------------------------------------------|
| `GameManager`    | Estado global, controle de turnos e fases, navegação          |
| `SaveManager`    | Save/load local encriptado + stub cloud                       |
| `EconomyManager` | Capital, renda, manutenção, lavagem, suborno, recrutamento    |
| `HeatManager`    | Nível de calor; raids da GM/ETE/FFI                           |
| `FactionManager` | 5 facções fictícias + 12 territórios + diplomacia + combate   |
| `AudioManager`   | Stub (sem assets de áudio ainda)                              |

---

## Facções fictícias

| Sigla | Nome                            | Especialidade           | Personalidade   |
|-------|---------------------------------|-------------------------|-----------------|
| CDM   | Comando da Marina               | Contrabando portuário   | Agressiva       |
| ADS   | Aliança da Serra                | Transporte e rotas      | Oportunista     |
| SV    | Sindicato Vermelho              | Mercado paralelo        | Mercantil       |
| NPS   | Núcleo do Porto Sul             | Indústria pesada        | Leal            |
| IBE   | Irmandade do Bairro Esquecido   | Cultura de rua          | Isolacionista   |

Autoridades também fictícias: **Guarda Metropolitana** → **ETE** → **FFI** conforme o calor sobe.

---

## Rodar localmente (opcional, no PC)

1. Baixe **Godot 4.3 stable** em https://godotengine.org/download
2. Abra o `project.godot`
3. F5 (Play). Pra exportar APK localmente: `Project > Install Android Build Template` → `Project > Export > Android Debug`.

Pra dropar fontes premium depois:
1. Coloque `GeneralSans-Variable.ttf`, `Satoshi-Variable.ttf`, `JetBrainsMono-Regular.ttf` em `assets/fonts/`
2. Edite `scripts/ui/ThemeBuilder.gd` constantes `FONT_UI_PATH`, `FONT_DISPLAY_PATH`, `FONT_MONO_PATH`
3. Rebuild

---

## Roadmap pós-v0.1

- [ ] Som e música (assets a definir)
- [ ] Cloud sync real via Firebase Firestore (stub já existe)
- [ ] Eventos roteirizados (quests da história)
- [ ] Sistema de inventário e loadout pré-combate
- [ ] Multiplayer assíncrono via Nakama (v2)
- [ ] Versão iOS (depois)

---

## Licença

A definir.
