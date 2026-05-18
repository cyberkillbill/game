# Porto Santiago

Drama criminal estratégico turn-based mobile, ambientado em uma metrópole brasileira **ficcional**. Você sobe da quebrada controlando bocas, recrutando tropa, lavando grana e dominando território.

> ⚠️ **100% ficção.** Nenhuma pessoa, comunidade, organização ou marca reais são referenciadas. Estética brasileira tratada com respeito, sem caricatura.

**Stack:** Unity 2022.3.40f1 · C# · Android · Build via GitHub Actions (`game-ci/unity-builder`)

---

## ⚡ Setup rápido (você precisa fazer 1x)

Pra esse projeto fazer o primeiro APK sair verde no GitHub Actions, você precisa de **3 coisas**:

1. ✅ Inicializar a estrutura Unity localmente (Unity Hub na sua máquina)
2. ✅ Configurar settings de Android pra build mobile
3. ✅ Ativar uma licença Unity Personal e adicionar como secret no GitHub

Tempo total: **~45 min na sua primeira vez**. Depois disso é só pushar código.

---

## Passo 1 — Inicializar o projeto Unity localmente

### 1.1 Instala Unity Hub
- Baixa em https://unity.com/download (gratuito, Personal Edition)
- Cria conta Unity ID (gratuita)

### 1.2 Instala Unity 2022.3.40f1 + Android module
- Abre Unity Hub → aba **Installs** → **Install Editor**
- Escolhe versão **2022.3.40f1** (LTS — a mesma usada pelo workflow CI)
- Em "Add modules", marca **Android Build Support** com seus 3 sub-itens:
  - Android SDK & NDK Tools
  - OpenJDK
  - Android SDK Platform-Tools

### 1.3 Abre este repositório como projeto Unity
Clone o repo na sua máquina:
```bash
git clone https://github.com/cyberkillbill/game.git porto-santiago
cd porto-santiago
git checkout claude/github-actions-apk-setup-bCX0y
```

No Unity Hub:
- Aba **Projects** → seta ao lado de **New project** → **Add project from disk**
- Aponta pra pasta `porto-santiago`
- Unity Hub vai perguntar "Esse projeto não tem ProjectSettings, criar novo?" → **Sim, criar**
- Escolhe template **2D Core** (mais leve, suficiente pro nosso jogo)
- Unity vai gerar `ProjectSettings/`, `Packages/`, `Library/` automaticamente

Aí o Unity Editor abre. Pode demorar uns 5 min na primeira vez (importa tudo).

---

## Passo 2 — Configurar settings de Android

No Unity Editor:

### 2.1 Trocar build target pra Android
- Menu **File → Build Settings** (Ctrl+Shift+B)
- Lista **Platform** → seleciona **Android** → clica **Switch Platform**
- Espera 1-2 min (re-importa textures pra Android)

### 2.2 Player Settings (identifier, nome, orientação)
- Ainda em Build Settings → clica **Player Settings...** (canto inferior esquerdo)
- Em **Player** (no menu da esquerda):
  - **Company Name:** `cyberkillbill`
  - **Product Name:** `Porto Santiago`
  - **Version:** `0.4.0`
- Em **Player → Resolution and Presentation:**
  - **Default Orientation:** `Portrait`
  - **Allowed Orientations for Auto Rotation:** só **Portrait**
- Em **Player → Other Settings:**
  - **Identification → Package Name:** `com.cyberkillbill.portosantiago`
  - **Identification → Minimum API Level:** Android 8.0 (API 26)
  - **Identification → Target API Level:** Android 14 (API 34)
  - **Configuration → Scripting Backend:** `IL2CPP`
  - **Configuration → Target Architectures:** marca **ARMv7** e **ARM64** (desmarca x86 se estiver)

### 2.3 Adicionar a cena ao build
- Volta pra **File → Build Settings**
- Unity vai reclamar que não tem cena no build. Cria uma cena vazia:
  - Menu **File → New Scene** → escolhe `Basic 2D` ou `Empty` → **Create**
  - Menu **File → Save As** → salva em `Assets/Scenes/Main.unity`
- Em Build Settings, clica **Add Open Scenes** → `Assets/Scenes/Main.unity` aparece na lista

> 💡 A cena pode ficar vazia! `Assets/Scripts/GameBootstrap.cs` cria tudo procedural via `[RuntimeInitializeOnLoadMethod]`. Só precisa de uma cena listada pra Unity considerar válida.

### 2.4 Teste rápido no Editor
- Pressiona **▶ Play** no topo do Unity. Você deve ver o menu PORTO SANTIAGO.
- Click em **NOVO JOGO** → vai pra tela do jogo.
- Funcionando? Bora pro próximo passo. Não tá? Veja "Troubleshooting" no fim.

### 2.5 Commit os arquivos gerados pelo Unity
```bash
git add ProjectSettings/ Packages/ Assets/Scenes/ ProjectVersion.txt
git status   # confere o que vai entrar
git commit -m "init Unity project structure (2022.3 LTS, Android)"
git push origin claude/github-actions-apk-setup-bCX0y
```

Os arquivos gerados pelo Unity nesse passo são o que faltava pro CI funcionar.

---

## Passo 3 — Ativar licença Unity pra GitHub Actions

`game-ci/unity-builder` precisa de uma licença válida pra rodar Unity em CI. Pra Personal Edition é gratuito mas tem que ativar 1x.

### 3.1 Empurra um commit qualquer pra ver o erro de licença
O primeiro run do workflow vai falhar com erro tipo "Unity license not activated". É esperado. Na verdade vai gerar um arquivo `Unity_v2022.x.alf` no log do workflow.

### 3.2 Faz download do arquivo de ativação (`.alf`)
- No workflow run que falhou, abre o step **Build Android APK via Unity** → procura por:
  ```
  Activation file written to ...alf
  ```
- O artifact `LicenseActivation` (ou similar) vai estar disponível pra download.
- Baixa o `.alf` pra sua máquina.

### 3.3 Converte `.alf` em `.ulf` no site da Unity
- Vai em https://license.unity3d.com/manual
- Login com sua conta Unity
- Upload do arquivo `.alf` baixado
- Escolhe **Personal license** (gratuita)
- Baixa o arquivo `Unity_v2022.x.ulf` resultante

### 3.4 Adiciona os 3 secrets no GitHub
- Vai em `github.com/cyberkillbill/game/settings/secrets/actions`
- Clica **New repository secret** pra cada um:

| Nome | Valor |
|---|---|
| `UNITY_LICENSE` | Conteúdo INTEIRO do arquivo `.ulf` (abre num editor de texto e cola) |
| `UNITY_EMAIL` | Email da sua conta Unity |
| `UNITY_PASSWORD` | Senha da sua conta Unity |

### 3.5 Empurra outro commit pra triggerar build com licença
```bash
git commit --allow-empty -m "trigger first licensed build"
git push origin claude/github-actions-apk-setup-bCX0y
```

Agora o workflow deve rodar até o fim e produzir o APK em **Artifacts → porto-santiago-android-apk**.

> 📖 Documentação oficial do flow de ativação: https://game.ci/docs/github/activation

---

## Como baixar o APK no celular (depois que o setup tá pronto)

1. Abre `github.com/cyberkillbill/game/actions` no celular
2. Run mais recente com ✅ verde → Artifacts → `porto-santiago-android-apk`
3. Baixa o `.zip`, extrai, instala o `.apk`

---

## Arquitetura do código

```
Assets/
  Scenes/
    Main.unity              ← cena placeholder (criada por você no passo 2.3)
  Scripts/
    Game.cs                 ← singleton estático: estado + regras
    GameBootstrap.cs        ← entry point [RuntimeInitializeOnLoadMethod]
    UIController.cs         ← UI procedural (menu + jogo) via uGUI

ProjectSettings/            ← gerado pelo Unity Hub
Packages/                   ← gerado pelo Unity Hub

.github/workflows/
  build-android.yml         ← CI Android via game-ci/unity-builder

DESIGN.md                   ← design doc completo (conceito, mecânicas, roadmap)
```

**Padrão arquitetural:** UI 100% procedural. Sem prefabs hand-authored, sem dependência de scenes complexas. `GameBootstrap.cs` roda automaticamente antes de qualquer cena e cria Camera + EventSystem + UIController via código. Isso elimina toda classe de bug "asset não importa", "scene corrompida", "prefab quebrado" que afligiam a versão Godot.

**Padrão de estado:** Singleton estático `Game` com eventos C# (`StateChanged`, `LogEventEmitted`, `GameFinishedEvent`). UI escuta os eventos e atualiza visualmente. Sem MonoBehaviours espalhados.

**Persistência:** save criptografado via `PlayerPrefs` + JSON. Suficiente pra single-player.

---

## Troubleshooting

### "Não consigo abrir o projeto no Unity Hub — diz que falta ProjectSettings"
Esperado. No Unity Hub, escolha **Add project from disk**, aponte pra pasta, e quando perguntar se quer criar projeto novo, **sim**. Unity gera tudo automático.

### "Compile error em Game.cs"
Geralmente é versão Unity diferente. Confirma que está em **2022.3.40f1** no Unity Hub.

### "Build no CI falha com 'License not activated'"
Você não completou o Passo 3. Re-leia.

### "Build no CI falha com 'no scene in build'"
Você não fez o Passo 2.3 (adicionar Main.unity ao build).

### "APK instala mas crasha ao abrir"
Manda print do logcat pra mim. Provavelmente é settings de IL2CPP / arquitetura.

---

## Próximos passos (após primeiro build verde)

Veja **DESIGN.md** pra roadmap completo (v0.4 → v1.0):

- **v0.4** "A Cidade Inteira" — 3 zonas (Norte/Centro/Sul), recrutas com nomes, fitas/missões
- **v0.5** "Reforma Visual" — brasões procedurais, transições, sons ambiente
- **v0.6** "Carisma" — reputação por zona, vitórias alternativas
- **v1.0** "Lançamento" — tutorial, polimento, build assinado release

---

## Decisões técnicas

**Por que Unity em vez de Godot?**
A versão Godot deste projeto sofria de erros de script silenciosos: GDScript compila em runtime, falhas viraram tela preta no Android sem mensagem clara. C# do Unity falha no build do CI com erro explícito, o que cortou meia hora de debug-por-screenshot.

**Por que `[RuntimeInitializeOnLoadMethod]` em vez de scene hand-authored?**
Cenas Unity são YAML proprietário com GUIDs internos. Modificar/criar via texto sem rodar Unity Editor é frágil. Construir tudo via código bypassa essa fragilidade — a cena pode ficar vazia, o bootstrap monta tudo.

**Por que `Resources.GetBuiltinResource<Font>` em vez de TextMeshPro?**
TMP precisa importar "TMP Essentials" 1x no Editor. Pra eliminar essa etapa manual do setup, usei a fonte built-in da Unity. Visual menos polido, zero setup. Pode trocar pra TMP em v0.5.
