using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

// UIController — constrói UI inteira proceduralmente em runtime.
// Sem dependência de prefabs, scenes hand-authored ou TMP.
// Tem 2 modos: Menu e Playing. Troca limpa entre eles sem mudar de cena
// (eliminando o ponto de falha "scene change silently fails" que tivemos
// na versão GDScript).

public class UIController : MonoBehaviour
{
    enum Mode { Menu, Playing }
    Mode _mode = Mode.Menu;

    Canvas _canvas;
    GameObject _modeRoot;          // pai de toda UI atual (menu OU game)
    Text _statusLabel;             // feedback "Carregando..." no menu

    // Refs do jogo (recriadas a cada mudança de modo)
    Text _hudText;
    Text _detailText;
    Text _logText;
    Button _sellBtn;
    Button _attackBtn;
    List<Button> _tileBtns = new();
    int _selectedId = -1;

    void Start()
    {
        Debug.Log("[UIController] Start");
        BuildCanvas();
        ShowMenu();

        Game.StateChanged += OnStateChanged;
        Game.LogEventEmitted += OnLogEmitted;
        Game.GameFinishedEvent += OnGameFinished;
    }

    void OnDestroy()
    {
        Game.StateChanged -= OnStateChanged;
        Game.LogEventEmitted -= OnLogEmitted;
        Game.GameFinishedEvent -= OnGameFinished;
    }

    // =====================================================================
    // Canvas raiz + CanvasScaler para portrait mobile
    // =====================================================================
    void BuildCanvas()
    {
        var canvasGO = new GameObject("MainCanvas");
        canvasGO.transform.SetParent(transform);
        _canvas = canvasGO.AddComponent<Canvas>();
        _canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        var scaler = canvasGO.AddComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = new Vector2(1080, 2400);
        scaler.matchWidthOrHeight = 0.5f;
        canvasGO.AddComponent<GraphicRaycaster>();

        // Fundo escuro
        var bg = NewPanel("Background", _canvas.transform, Game.COLOR_BG);
        var rt = bg.GetComponent<RectTransform>();
        rt.anchorMin = Vector2.zero;
        rt.anchorMax = Vector2.one;
        rt.offsetMin = Vector2.zero;
        rt.offsetMax = Vector2.zero;
    }

    // =====================================================================
    // Mode switching
    // =====================================================================
    void ClearMode()
    {
        if (_modeRoot != null) Destroy(_modeRoot);
        _tileBtns.Clear();
        _hudText = _detailText = _logText = _statusLabel = null;
        _sellBtn = _attackBtn = null;
    }

    void ShowMenu()
    {
        ClearMode();
        _mode = Mode.Menu;
        _modeRoot = NewPanel("MenuRoot", _canvas.transform, new Color(0, 0, 0, 0));
        var rt = _modeRoot.GetComponent<RectTransform>();
        rt.anchorMin = Vector2.zero;
        rt.anchorMax = Vector2.one;
        rt.offsetMin = new Vector2(50, 50);
        rt.offsetMax = new Vector2(-50, -50);

        var layout = _modeRoot.AddComponent<VerticalLayoutGroup>();
        layout.childAlignment = TextAnchor.MiddleCenter;
        layout.spacing = 30;
        layout.childForceExpandWidth = true;
        layout.childForceExpandHeight = false;

        NewText(_modeRoot.transform, "PORTO SANTIAGO", 80, Color.white, TextAnchor.MiddleCenter);
        NewText(_modeRoot.transform, "Domine a quebrada", 40, Game.COLOR_GOLD, TextAnchor.MiddleCenter);
        NewText(_modeRoot.transform, "Drama criminal ficcional · 100% BR", 24, Game.COLOR_MUTED, TextAnchor.MiddleCenter);

        Spacer(_modeRoot.transform, 80);

        _statusLabel = NewText(_modeRoot.transform, "", 26, Game.COLOR_GREEN, TextAnchor.MiddleCenter);

        var btnNew = NewBigButton(_modeRoot.transform, "NOVO JOGO", Game.COLOR_RED);
        btnNew.onClick.AddListener(OnNewGame);

        var btnCont = NewBigButton(_modeRoot.transform, "CONTINUAR", Game.COLOR_GOLD, true);
        btnCont.interactable = Game.HasSave();
        btnCont.onClick.AddListener(OnContinue);

        var btnQuit = NewBigButton(_modeRoot.transform, "SAIR", new Color(0.25f, 0.27f, 0.32f));
        btnQuit.onClick.AddListener(OnQuit);
    }

    void ShowGame()
    {
        ClearMode();
        _mode = Mode.Playing;
        _modeRoot = NewPanel("GameRoot", _canvas.transform, new Color(0, 0, 0, 0));
        var rt = _modeRoot.GetComponent<RectTransform>();
        rt.anchorMin = Vector2.zero;
        rt.anchorMax = Vector2.one;
        rt.offsetMin = new Vector2(20, 20);
        rt.offsetMax = new Vector2(-20, -20);

        // Scroll pra caber em qualquer tela
        var scrollGO = new GameObject("Scroll", typeof(RectTransform), typeof(ScrollRect), typeof(Image));
        scrollGO.transform.SetParent(_modeRoot.transform, false);
        var srt = scrollGO.GetComponent<RectTransform>();
        srt.anchorMin = Vector2.zero;
        srt.anchorMax = Vector2.one;
        srt.offsetMin = Vector2.zero;
        srt.offsetMax = Vector2.zero;
        var scroll = scrollGO.GetComponent<ScrollRect>();
        scroll.horizontal = false;
        var scrollImg = scrollGO.GetComponent<Image>();
        scrollImg.color = new Color(0, 0, 0, 0);

        var contentGO = new GameObject("Content", typeof(RectTransform), typeof(VerticalLayoutGroup), typeof(ContentSizeFitter));
        contentGO.transform.SetParent(scrollGO.transform, false);
        var crt = contentGO.GetComponent<RectTransform>();
        crt.anchorMin = new Vector2(0, 1);
        crt.anchorMax = new Vector2(1, 1);
        crt.pivot = new Vector2(0.5f, 1);
        var clayout = contentGO.GetComponent<VerticalLayoutGroup>();
        clayout.spacing = 20;
        clayout.childForceExpandWidth = true;
        clayout.childForceExpandHeight = false;
        clayout.padding = new RectOffset(10, 10, 10, 10);
        var fitter = contentGO.GetComponent<ContentSizeFitter>();
        fitter.verticalFit = ContentSizeFitter.FitMode.PreferredSize;
        scroll.content = crt;

        var content = contentGO.transform;

        // HUD
        _hudText = NewText(content, "...", 30, Color.white, TextAnchor.UpperLeft);
        _hudText.alignment = TextAnchor.MiddleLeft;
        var hudLE = _hudText.gameObject.AddComponent<LayoutElement>();
        hudLE.preferredHeight = 110;

        Separator(content);

        // Map title
        NewText(content, "QUEBRADA — toque numa boca", 24, Game.COLOR_MUTED, TextAnchor.MiddleLeft);

        // Grid 4x4
        var gridGO = new GameObject("Grid", typeof(RectTransform), typeof(GridLayoutGroup));
        gridGO.transform.SetParent(content, false);
        var grid = gridGO.GetComponent<GridLayoutGroup>();
        grid.cellSize = new Vector2(230, 180);
        grid.spacing = new Vector2(8, 8);
        grid.constraint = GridLayoutGroup.Constraint.FixedColumnCount;
        grid.constraintCount = Game.GRID_W;
        var gridLE = gridGO.AddComponent<LayoutElement>();
        gridLE.preferredHeight = (180 * 4) + (8 * 3);

        for (int i = 0; i < Game.N_TILES; i++)
        {
            int idx = i;
            var b = NewTileButton(gridGO.transform);
            b.onClick.AddListener(() => OnTilePressed(idx));
            _tileBtns.Add(b);
        }

        Separator(content);

        // Detail
        _detailText = NewText(content, "Selecione uma boca.", 22, Color.white, TextAnchor.UpperLeft);
        var detLE = _detailText.gameObject.AddComponent<LayoutElement>();
        detLE.preferredHeight = 130;

        var tileActionRow = NewHRow(content);
        _sellBtn = NewBigButton(tileActionRow.transform, "VENDER", Game.COLOR_GREEN);
        _sellBtn.onClick.AddListener(() => { if (_selectedId >= 0) Game.SellAt(_selectedId); });
        _attackBtn = NewBigButton(tileActionRow.transform, "INVADIR", Game.COLOR_RED);
        _attackBtn.onClick.AddListener(() => { if (_selectedId >= 0) Game.Attack(_selectedId); });

        Separator(content);

        NewText(content, "AÇÕES GERAIS", 22, Game.COLOR_MUTED, TextAnchor.MiddleLeft);
        var row1 = NewHRow(content);
        NewBigButton(row1.transform, $"+3 TROPA R${3 * Game.RECRUIT_COST_EACH}", Game.COLOR_BLUE)
            .onClick.AddListener(() => Game.Recruit(3));
        NewBigButton(row1.transform, "SUBORNO R$300", Game.COLOR_PURPLE)
            .onClick.AddListener(() => Game.Bribe(300));

        var row2 = NewHRow(content);
        NewBigButton(row2.transform, "LAVAR R$500", Game.COLOR_GOLD)
            .onClick.AddListener(() => Game.Launder(500));
        NewBigButton(row2.transform, "LAVAR TUDO", Game.COLOR_ORANGE)
            .onClick.AddListener(() => Game.Launder(Game.Cash));

        Separator(content);

        NewText(content, "DIÁRIO", 22, Game.COLOR_MUTED, TextAnchor.MiddleLeft);
        _logText = NewText(content, "—", 20, new Color(0.85f, 0.85f, 0.9f), TextAnchor.UpperLeft);
        var logLE = _logText.gameObject.AddComponent<LayoutElement>();
        logLE.preferredHeight = 280;

        Separator(content);

        var footer = NewHRow(content);
        NewBigButton(footer.transform, "PASSAR O DIA", Game.COLOR_RED)
            .onClick.AddListener(Game.EndTurn);
        NewBigButton(footer.transform, "SALVAR", Game.COLOR_GOLD)
            .onClick.AddListener(OnSave);
        NewBigButton(footer.transform, "MENU", new Color(0.25f, 0.27f, 0.32f))
            .onClick.AddListener(ShowMenu);

        Refresh();
    }

    // =====================================================================
    // Refresh — atualiza texts/cores quando estado muda
    // =====================================================================
    void OnStateChanged() { if (_mode == Mode.Playing) Refresh(); }
    void OnLogEmitted(string m, string t) { if (_mode == Mode.Playing) RefreshLog(); }

    void Refresh()
    {
        if (_hudText != null)
            _hudText.text = $"GRANA R${Fmt(Game.Cash)}   LIMPO R${Fmt(Game.Clean)}\nTROPA {Game.Soldiers}   CALOR {Game.Heat}/100   TURNO {Game.Turn}";
        RefreshMap();
        RefreshDetail();
        RefreshLog();
    }

    void RefreshMap()
    {
        for (int i = 0; i < Game.N_TILES && i < _tileBtns.Count; i++)
        {
            var b = _tileBtns[i];
            var t = Game.Territories[i];
            string ownerShort = t.Owner == "PLAYER" ? "VC" : (t.Owner == "NEUTRAL" ? "—" : t.Owner);
            string shortName = t.Name.Length > 13 ? t.Name.Substring(0, 11) + "…" : t.Name;
            var txt = b.GetComponentInChildren<Text>();
            if (txt != null) txt.text = $"{shortName}\n{ownerShort} · ⚔{t.Soldiers}\n[{t.Product}]";

            Color bg = new Color(0.14f, 0.16f, 0.21f);
            if (t.Owner == "PLAYER") bg = new Color(0.55f, 0.4f, 0.05f);
            else if (t.Owner != "NEUTRAL" && Game.FACTION_COLORS.TryGetValue(t.Owner, out var fc)) bg = fc * 0.5f;
            var img = b.GetComponent<Image>();
            if (img != null) img.color = bg;

            var outline = b.GetComponent<Outline>();
            if (outline != null)
            {
                outline.effectColor = i == _selectedId ? Game.COLOR_GOLD : new Color(0, 0, 0, 0);
                outline.effectDistance = i == _selectedId ? new Vector2(3, -3) : new Vector2(0, 0);
            }
        }
    }

    void RefreshDetail()
    {
        if (_detailText == null) return;
        if (_selectedId < 0 || _selectedId >= Game.N_TILES)
        {
            _detailText.text = "Selecione uma boca no mapa.";
            if (_sellBtn != null) _sellBtn.interactable = false;
            if (_attackBtn != null) _attackBtn.interactable = false;
            return;
        }
        var t = Game.Territories[_selectedId];
        var p = Game.PRODUCT_INFO.GetValueOrDefault(t.Product);
        _detailText.text = $"{t.Name}\nDono: {Game.FACTION_NAMES.GetValueOrDefault(t.Owner, t.Owner)} · Tropa: {t.Soldiers}\n"
                         + $"Produto: {p?.Name ?? "?"} · Venda: +R${Game.TileIncome(t)} · Calor: +{Game.TileRisk(t)}";
        if (_sellBtn != null) _sellBtn.interactable = (t.Owner == "PLAYER");
        if (_attackBtn != null) _attackBtn.interactable = (t.Owner != "PLAYER" && Game.IsAdjacentToPlayer(_selectedId));
    }

    void RefreshLog()
    {
        if (_logText == null) return;
        if (Game.EventLog.Count == 0) { _logText.text = "—"; return; }
        var lines = new List<string>();
        foreach (var e in Game.EventLog) lines.Add($"T{e.Turn} · {e.Msg}");
        _logText.text = string.Join("\n", lines);
    }

    // =====================================================================
    // Eventos UI
    // =====================================================================
    void OnTilePressed(int idx)
    {
        Debug.Log($"[UI] tile {idx} pressionado");
        _selectedId = idx;
        Refresh();
    }

    void OnNewGame()
    {
        Debug.Log("[UI] NOVO JOGO");
        if (_statusLabel != null) _statusLabel.text = "Carregando...";
        Game.NewGame("Você");
        ShowGame();
    }

    void OnContinue()
    {
        Debug.Log("[UI] CONTINUAR");
        if (_statusLabel != null) _statusLabel.text = "Carregando save...";
        if (Game.LoadGame()) ShowGame();
        else if (_statusLabel != null) { _statusLabel.text = "Falha ao carregar save."; _statusLabel.color = Game.COLOR_RED; }
    }

    void OnQuit() => Application.Quit();

    void OnSave() => Game.SaveGame();

    void OnGameFinished(bool victory, string reason)
    {
        Debug.Log($"[UI] Game finished. victory={victory} reason={reason}");
        // TODO: dialog. Por ora, log no console.
        Game.EventLog.Insert(0, new Game.LogEntry {
            Turn = Game.Turn,
            Msg = (victory ? "VITÓRIA: " : "DERROTA: ") + reason,
            Tone = victory ? "gold" : "danger"
        });
        RefreshLog();
    }

    // =====================================================================
    // UI helpers
    // =====================================================================
    GameObject NewPanel(string name, Transform parent, Color color)
    {
        var go = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
        go.transform.SetParent(parent, false);
        go.GetComponent<Image>().color = color;
        return go;
    }

    Text NewText(Transform parent, string content, int size, Color color, TextAnchor anchor)
    {
        var go = new GameObject("Text", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
        go.transform.SetParent(parent, false);
        var t = go.GetComponent<Text>();
        t.text = content;
        t.fontSize = size;
        t.color = color;
        t.alignment = anchor;
        t.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
        t.horizontalOverflow = HorizontalWrapMode.Wrap;
        t.verticalOverflow = VerticalWrapMode.Overflow;
        var le = go.AddComponent<LayoutElement>();
        le.preferredHeight = Mathf.Max(size + 10, 40);
        return t;
    }

    void Spacer(Transform parent, float height)
    {
        var go = new GameObject("Spacer", typeof(RectTransform), typeof(LayoutElement));
        go.transform.SetParent(parent, false);
        go.GetComponent<LayoutElement>().preferredHeight = height;
    }

    void Separator(Transform parent)
    {
        var go = NewPanel("Sep", parent, new Color(1, 1, 1, 0.08f));
        var le = go.AddComponent<LayoutElement>();
        le.preferredHeight = 2;
    }

    GameObject NewHRow(Transform parent)
    {
        var go = new GameObject("Row", typeof(RectTransform), typeof(HorizontalLayoutGroup), typeof(LayoutElement));
        go.transform.SetParent(parent, false);
        var h = go.GetComponent<HorizontalLayoutGroup>();
        h.spacing = 10;
        h.childForceExpandWidth = true;
        h.childForceExpandHeight = false;
        var le = go.GetComponent<LayoutElement>();
        le.preferredHeight = 100;
        return go;
    }

    Button NewBigButton(Transform parent, string label, Color bg, bool darkText = false)
    {
        var go = new GameObject("Button", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(Button), typeof(LayoutElement));
        go.transform.SetParent(parent, false);
        var img = go.GetComponent<Image>();
        img.color = bg;
        var btn = go.GetComponent<Button>();
        var colors = btn.colors;
        colors.normalColor = Color.white;
        colors.highlightedColor = new Color(1.1f, 1.1f, 1.1f, 1f);
        colors.pressedColor = new Color(0.85f, 0.85f, 0.85f);
        colors.disabledColor = new Color(0.5f, 0.5f, 0.5f);
        btn.colors = colors;
        var le = go.GetComponent<LayoutElement>();
        le.preferredHeight = 100;
        le.flexibleWidth = 1;

        // Texto interno
        var textGO = new GameObject("Label", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
        textGO.transform.SetParent(go.transform, false);
        var t = textGO.GetComponent<Text>();
        t.text = label;
        t.fontSize = 28;
        t.color = darkText ? Game.COLOR_BG : Color.white;
        t.alignment = TextAnchor.MiddleCenter;
        t.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
        var trt = textGO.GetComponent<RectTransform>();
        trt.anchorMin = Vector2.zero;
        trt.anchorMax = Vector2.one;
        trt.offsetMin = new Vector2(8, 4);
        trt.offsetMax = new Vector2(-8, -4);
        return btn;
    }

    Button NewTileButton(Transform parent)
    {
        var go = new GameObject("Tile", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(Button), typeof(Outline));
        go.transform.SetParent(parent, false);
        go.GetComponent<Image>().color = new Color(0.14f, 0.16f, 0.21f);

        var textGO = new GameObject("Label", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
        textGO.transform.SetParent(go.transform, false);
        var t = textGO.GetComponent<Text>();
        t.text = "?";
        t.fontSize = 18;
        t.color = Color.white;
        t.alignment = TextAnchor.MiddleCenter;
        t.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
        t.horizontalOverflow = HorizontalWrapMode.Wrap;
        t.verticalOverflow = VerticalWrapMode.Overflow;
        var trt = textGO.GetComponent<RectTransform>();
        trt.anchorMin = Vector2.zero;
        trt.anchorMax = Vector2.one;
        trt.offsetMin = new Vector2(6, 6);
        trt.offsetMax = new Vector2(-6, -6);

        return go.GetComponent<Button>();
    }

    static string Fmt(int n)
    {
        return n.ToString("N0", System.Globalization.CultureInfo.GetCultureInfo("pt-BR"));
    }
}
