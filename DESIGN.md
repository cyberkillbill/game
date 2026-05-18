# PORTO SANTIAGO — Design Document

> Drama criminal estratégico turn-based · mobile portrait · 100% ficcional · ambientação brasileira
> Versão atual: **v0.4 (em desenvolvimento)** · Estado: prototype

---

## 1. CONCEITO

Porto Santiago é uma metrópole portuária **fictícia** brasileira. Você sobe de uma quebrada da Zona Norte, atravessa o Centro e tenta dominar a Zona Sul — geograficamente, economicamente, politicamente.

O jogo é **turn-based, single-player, sem timer**. Toda decisão é deliberada. Não tem tiro em primeira pessoa, não tem direção de carro, não tem combate em tempo real. É xadrez de império criminal.

### Pilares de design

1. **Decisão antes de reflexo.** Cada turno o jogador pondera: vender e ganhar grana mas subir o calor? Atacar uma boca vizinha e arriscar a tropa? Lavar tudo e ficar sem caixa pra suborno?
2. **Risco visível.** Calor sobe na frente do jogador. Rivais que vão atacar têm sinais antes (boato no diário). Nada é unfair.
3. **Curva de morte natural.** Quanto mais você cresce, mais polícia, mais inveja, mais rivais juntando. Vencer exige ritmo, não acumulação cega.
4. **Estética brasileira sem caricatura.** Gírias, locais, ritmo da rua — sem reduzir comunidades a estereótipos. Sem nomear drogas reais ("produto"). Sem facções/polícias reais (tudo inventado).

---

## 2. AMBIENTAÇÃO — A CIDADE

Porto Santiago tem **três zonas** com dinâmicas distintas:

### Zona Norte — **"A casa"**
- Onde o jogador começa. Comunidades, becos, lajes, vias estreitas.
- Bocas tradicionais, vendem **Erva** principalmente.
- Polícia menos ostensiva. Calor sobe devagar.
- Renda baixa-média. Tropa custa pouco pra recrutar (rapazes da quebrada).
- Bocas tem nomes tipo: *Beco do Zé, Travessa Maria, Ladeira do Cemitério, Pé de Manga, Subida do Morro, Quintal do Tio*.

### Centro — **"A rua"**
- Corredor comercial, prédios velhos, terminais de ônibus, calçadões.
- Bocas que vendem **Comprimido** (clientela jovem balada/trampo).
- Blitz constante. Calor sobe rápido, mas dinheiro também.
- Renda média-alta. Tropa custa mais.
- Bocas tipo: *Rua do Comércio, Largo da Quitanda, Esquina do Bar, Ponte de Madeira, Servidão da Linha*.

### Zona Sul — **"A orla"**
- Praia, condomínios, restaurantes finos, clientela elite/turista.
- Bocas vendem **Pó** (margem altíssima, calor altíssimo).
- Polícia + segurança privada + paparazzi.
- Pra operar aqui precisa de **suborno alto e influência**, não força bruta.
- Bocas tipo: *Boca do Mato (referência ao mato da orla), Curva do Posto, Becão Velho (uma rua antiga turística), Vala da Pedra*.

> **v0.3 atual:** 16 bocas num grid 4x4 sem distinção de zona. Nomes já estão BR.
> **v0.4 alvo:** dividir o grid em 3 colunas/seções (4 bocas Norte + 4 Centro + 4 Sul + 4 mistas), cor de fundo distinta por zona.

---

## 3. CICLO DE JOGO

### Turno do jogador
1. Olha o HUD: **Grana, Limpo, Tropa, Calor, Turno**
2. Seleciona uma boca no mapa → vê detalhes (dono, tropa, produto)
3. Toma N ações livremente:
   - **Vender** numa boca sua (+grana, +calor variável por produto)
   - **Invadir** uma boca vizinha de área sua (gasta tropa, ganha território)
   - **Recrutar** soldados (R$80 cada, +calor leve)
   - **Subornar** polícia (R$X, -calor proporcional)
   - **Lavar** grana suja → grana limpa (taxa 18%)
4. Aperta **"Passar o dia"** → fim do turno

### Fim de turno (automático)
1. **Renda passiva** — cada boca sua rende ~35% do income normal sem ato manual + parte do calor
2. **Decay** — calor cai 3 naturalmente (a cidade esquece)
3. **Rivais agem** — facções inimigas movem (atacam suas bocas, expandem em neutras)
4. **Evento aleatório** — 28% de chance: vereador pede bola, festa rende contatos, mídia denuncia, etc.
5. **Operação policial** — se calor ≥ 75: paga suborno emergencial OU perde uma boca + tropa

### Vitória / derrota
- **Vitória:** dominar TODAS as bocas E ter R$1.000.000 lavado
- **Derrota:**
  - Perder todas as bocas E ficar com menos de R$80, OU
  - Calor = 100 E menos de R$100 pra subornar

---

## 4. SISTEMA DE PRODUTOS

| Produto | Cor | Margem | Calor | Onde |
|---|---|---|---|---|
| **Erva** | 🟢 verde | 1.0x | 0.5x | Zona Norte |
| **Comprimido** | 🟠 laranja | 1.3x | 1.0x | Centro |
| **Pó** | ⚪ branco | 1.8x | 2.0x | Zona Sul |

Cada boca tem **afinidade** com um produto. Vender em boca que combina com a região = bônus implícito de margem (já refletido nos base_income de cada zona).

**v0.4 alvo:** tipo de produto da boca passa a depender da zona (não mais 100% aleatório).

---

## 5. FACÇÕES (todas ficcionais)

| Sigla | Nome | Cor | Personalidade |
|---|---|---|---|
| **BV** | Bonde do Vapor | 🔴 vermelho-coral | agressivo, ataca cedo (0.55) |
| **CE** | Comando da Encruzilhada | 🟢 verde | defensivo, expande lento (0.35) |
| **FB** | Família da Beira | 🟣 roxo | equilibrado, foca em renda (0.5) |
| **SV** | Sindicato do Vale | 🔵 azul | muito agressivo, alta tropa (0.65) |
| **PLAYER** | Sua tropa | 🟡 dourado | é você |
| **NEUTRAL** | Sem dono | ⚫ cinza | bocas livres pra tomar |

> **v0.5 alvo:** cada facção tem um "estilo de jogo" mais distinto:
> - BV: foca em destruir suas bocas, ignora neutros
> - CE: nunca ataca primeiro, mas defende com tudo
> - FB: tenta lavar tanto quanto você (você compete por mercado)
> - SV: cria alianças temporárias contra quem tá liderando

---

## 6. RECRUTAS (planejado v0.4)

Em vez de só "+1 soldado genérico", recrutamento traz NPCs com bônus passivos:

| Nome | Bônus | Custo |
|---|---|---|
| **Tigrão** | +2 dano em ataques | R$500 |
| **Doutor** | -1 calor por turno (consultor) | R$700 |
| **Cobrinha** | +R$30 por turno (negociador) | R$600 |
| **Magrão** | +1 tropa por turno (recrutador) | R$800 |
| **Velhinho** | +5% margem na lavagem | R$1000 |
| **Mosca** | -1 perda em ataques (esquiva) | R$450 |

Limite: máximo 3 recrutas ativos por vez. Pra trocar, dispensa um (ele "sai do corre").

---

## 7. EVENTOS ALEATÓRIOS

### Atuais (v0.3)
- Sumiu um vapor da tropa (-1 soldado)
- Boato na quebrada: viatura subindo (+6 calor)
- Vereador pede 'colaboração' (-R$200, -4 calor)
- Mídia local denuncia (+8 calor)
- Festa na laje rende contatos (+R$150 limpo)
- Informante quer trocar fita por grana (-R$120, -5 calor)
- Soldado fiel trouxe irmão (+1 soldado)
- Produto roubado (-R$80)

### Planejados (v0.4+)
- **Fitas / missões especiais** — eventos com escolha binária:
  - "Bonde rival quer aliança contra X. Aceitar? (sim: -calor 10, ganha turno de imunidade contra X · não: nada)"
  - "Cliente VIP quer entrega grande. Risco alto. Topar? (+R$1500 OU -3 tropa em falha)"
  - "Delegado novo no distrito. Untar? (-R$800 ganha 5 turnos sem blitz)"
- **Decisão de dilema moral** — sem julgamento, mas com consequência:
  - "Bagulho deu errado, um garoto se machucou. Pagar família? (-R$300 +reputação · ignorar: -reputação)"

---

## 8. REPUTAÇÃO POR ZONA (planejado v0.5)

Métrica de -100 a +100 por zona:
- **Norte:** lealdade da quebrada. Negativa = bocas suas vendem menos, recrutas pedem mais grana.
- **Centro:** medo na rua. Negativa = atacar boca custa mais. Positiva = facções menores podem se entregar.
- **Sul:** influência elite. Negativa = polícia ataca em dobro. Positiva = imprensa ignora você.

Reputação muda com escolhas em eventos + dominação visível.

---

## 9. UI / VISUAL

### Estado atual (v0.3)
- Tudo procedural em código (sem assets externos além do ícone .svg)
- Paleta: fundo escuro (#0c0e13), accent vermelho (#d23a2c), dourado (#f5b400)
- Botões com cantos arredondados, cores de chip
- HUD em texto simples (essa versão)

### Direção visual (v0.4-v0.5)
- **Brasões procedurais por facção** — círculo com sigla + padrão geométrico de fundo (linhas diagonais pra BV, círculos pra CE, etc.)
- **Tiles do mapa estilo "carta"** — cor de fundo da zona + accent de borda do produto + badge de tropa
- **Log estilo notificação WhatsApp** — bolinha colorida + texto + timestamp do turno
- **Transição entre zonas** — fade rápido com nome da zona em letras grandes ("ENTRANDO NA ZONA SUL · Cuidado, calor altíssimo")
- **Animação de turno** — pulse no HUD ao avançar
- **Som ambiente sutil** — zumbido baixo de rua + clique de botão

### Direção visual (v1.0)
- Texturas procedurais simulando concreto/pichação no fundo
- Pequenas ilustrações vetoriais procedurais (silhueta de prédio, palmeira da orla, antena de favela)
- Funk procedural opcional (BPM 130, bumbo + 808 + texto sintetizado em "TR" + "DUM DUM")

---

## 10. TECH STACK

### Engine
- **Godot 4.3 stable** (binário standard, não Mono)
- **GDScript** (sem class_name, autoload único)
- Renderer: **gl_compatibility** (máxima compatibilidade Android)

### Build / CI
- **GitHub Actions** roda em ubuntu-22.04
- Baixa Godot + export templates, instala Android SDK + JDK 17
- Gera keystore debug, configura editor_settings
- Importa o projeto (2 passes), exporta APK debug
- Template Android: **prebuilt** (use_gradle_build=false), sem NDK
- Output: APK arm64-v8a + x86_64, ~25MB

### Arquivos
```
project.godot              ← config engine
scripts/
  Game.gd                  ← autoload único: estado + regras (~470 linhas)
  MainMenu.gd              ← menu (~100 linhas, brutalmente simples)
  GameScreen.gd            ← tela de jogo (~300 linhas)
scenes/
  MainMenu.tscn            ← Control root + script
  GameScreen.tscn          ← Control root + script
.github/workflows/
  build-android.yml        ← CI Android
```

---

## 11. ESTADO DO CÓDIGO (v0.3 → v0.4)

### Funcionando ✅
- Build CI gera APK consistentemente
- Game.gd: estado + regras completas (vender/atacar/recrutar/subornar/lavar/turno/IA rival/eventos/blitz/vitória/derrota)
- Sistema de save criptografado em user://
- 4 facções rivais com personalidades distintas no AI

### Problemas conhecidos ⚠️
- UI procedural complexa quebra silenciosamente em alguns devices (tela preta)
- Layout não testado em devices reais com diferentes aspect ratios

### Versão atual minimalista
A iteração v0.3 final foi reescrita pra ser **brutalmente simples**: textos labels em vez de cards estilizados, só Buttons default + ColorRect bg. Sacrifica visual, mas garante renderização. Visual volta em v0.4 sobre essa base.

---

## 12. ROADMAP

### v0.4 — "A Cidade Inteira" (próxima)
- [ ] 3 zonas no mapa (Norte/Centro/Sul) com cor de fundo distinta
- [ ] Nomes de bocas distribuídos por zona
- [ ] Produto por boca depende da zona (não 100% random)
- [ ] Recrutamento por NPC (Tigrão, Doutor, etc.) com bônus passivos
- [ ] Fitas/missões: 3-5 eventos com escolha binária
- [ ] Visual: brasões procedurais nos tiles do mapa

### v0.5 — "Reforma Visual"
- [ ] Telas de transição entre zonas
- [ ] Animação de turno (pulse HUD, fade no log)
- [ ] Som ambiente procedural (baixo zumbido + cliques)
- [ ] Log estilo notificação com bolinha colorida
- [ ] Personalidade visual diferenciada por facção (padrão de fundo do tile)

### v0.6 — "Carisma"
- [ ] Sistema de reputação por zona (-100..+100)
- [ ] Aliados/inimigos políticos: vereador, delegado, juiz
- [ ] Vitórias alternativas: dominação total, vitória econômica (R$5M sem disputar tudo), vitória política (apoio dos 3 vereadores)

### v0.7 — "Polimento"
- [ ] Tutorial interativo (primeiro turno guiado)
- [ ] Tela de configurações (volume, idioma futuro)
- [ ] Múltiplos saves (3 slots)
- [ ] Conquistas locais (sem cloud)

### v1.0 — "Lançamento"
- [ ] Funk procedural opcional
- [ ] Cloud save (Firebase) opcional
- [ ] Tela "Sobre" detalhada com créditos
- [ ] APK release assinado pra Play Store

---

## 13. DECISÕES TÉCNICAS

### GDScript vs C# (Godot Mono)
**Decisão atual: GDScript.**
Razão: C# em Godot exige binário Mono diferente, .NET 8 SDK no CI, refazer workflow. Custo de migração: 1-2 dias só pra CI + risco de novos bugs. Vantagem: type safety, IDE melhor. Vale a pena revisitar depois da v0.5 quando o projeto tiver mais código.

### Unity como alternativa
**Descartado por enquanto.**
Razão: pipeline 5x mais complexa (license activation, secrets, game-ci/unity-builder), build time 10x maior, e não resolve nenhum problema atual.

### 2D vs 3D
**2D portrait, sem planos pra 3D.**
Razão: jogo é tático, leitura visual rápida importa mais que imersão. Menos peso no APK, menos bugs, mais focado.

### Procedural vs Asset Pack
**Procedural sempre que possível.**
Razão: zero risco de IP, fácil iterar (mudar uma cor afeta tudo), pequeno no APK. Quando precisar de algo específico (logo do jogo, talvez ícone Android customizado), aí adiciona asset.

---

## 14. DIRETRIZES DE CONTEÚDO

### Hard rules
- 🚫 **Nenhum nome real** de comunidade, organização, facção, polícia, banda, marca
- 🚫 **Nenhuma droga nomeada por nome técnico** ("produto", "fita", "corre")
- 🚫 **Sem caricatura** — personagens são pessoas, não tipos
- 🚫 **Sem violência gráfica** — combate é "perdeu 2 soldados", não descrição

### Soft rules
- ✅ **Gírias autenticamente brasileiras** sem exotificar ("mano", "corre", "vapor", "bagulho", "quebrada", "boca", "trampo", "fita")
- ✅ **Geografia genérica** — "ladeira", "morro", "vala", "servidão", "becão" — termos que existem em várias cidades, sem mapear pra lugar real
- ✅ **Polícia genérica** — "polícia", "blitz", "operação", "delegado" — não BOPE/CORE/ROTA
- ✅ **Política genérica** — "vereador", "delegado", "juiz" — sem partido/sigla

---

## 15. INSPIRAÇÕES (não cópias)

O gênero "império criminal" é compartilhado por dezenas de jogos. Sem copiar:
- Mecânica de **calor/wanted** é genre staple desde os anos 90
- Mecânica de **dominação por territórios** vem dos jogos 4X e foi adaptada pra crime
- Mecânica de **lavagem de dinheiro como gameplay** existe em vários sims criminais
- Mecânica de **gangs com personalidades distintas** é padrão do gênero

Nada aqui copia design específico, UI, narrativa ou identidade visual de outros jogos. Tudo é montado do zero pra contexto BR.

---

## 16. PRÓXIMOS PASSOS IMEDIATOS

Quando a v0.3 final abrir e jogar:
1. ✅ Confirmar que o loop básico funciona
2. ✅ Coletar feedback de quais ações são mais usadas (vender? atacar? lavar?)
3. ➡️ Implementar v0.4 começando pelo mais visível: **3 zonas com cor de fundo**
4. ➡️ Depois recrutas
5. ➡️ Depois fitas

Tempo estimado v0.4 completa: ~2-3 sessões de trabalho focadas.

---

*Documento vivo. Atualizar a cada versão. — Porto Santiago Team (você + Claude)*
