using System;
using System.Collections.Generic;
using UnityEngine;

// Game — singleton estático com TODO o estado e regras do jogo.
// Equivalente ao Game.gd da versão Godot, agora em C# com tipagem forte.
// Eventos C# disparam quando estado muda; UI escuta e atualiza.

public static class Game
{
    // ====== Constantes ======
    public const int GRID_W = 4;
    public const int GRID_H = 4;
    public const int N_TILES = GRID_W * GRID_H;
    public const int HEAT_CAP = 100;

    public const int START_CASH = 600;
    public const int START_CLEAN = 0;
    public const int START_SOLDIERS = 4;

    public const float LAUNDER_FEE = 0.18f;
    public const int RECRUIT_COST_EACH = 80;
    public const int VICTORY_CLEAN = 1_000_000;

    public static readonly Color COLOR_BG       = new Color(0.047f, 0.055f, 0.075f);
    public static readonly Color COLOR_SURFACE  = new Color(0.090f, 0.102f, 0.133f);
    public static readonly Color COLOR_ELEVATED = new Color(0.137f, 0.153f, 0.200f);
    public static readonly Color COLOR_BORDER   = new Color(1f, 1f, 1f, 0.08f);
    public static readonly Color COLOR_GOLD     = new Color(0.961f, 0.706f, 0.000f);
    public static readonly Color COLOR_RED      = new Color(0.824f, 0.227f, 0.173f);
    public static readonly Color COLOR_GREEN    = new Color(0.243f, 0.639f, 0.298f);
    public static readonly Color COLOR_BLUE     = new Color(0.180f, 0.490f, 0.843f);
    public static readonly Color COLOR_PURPLE   = new Color(0.608f, 0.349f, 0.839f);
    public static readonly Color COLOR_ORANGE   = new Color(0.878f, 0.478f, 0.149f);
    public static readonly Color COLOR_TEXT     = new Color(0.925f, 0.925f, 0.941f);
    public static readonly Color COLOR_MUTED    = new Color(0.541f, 0.541f, 0.584f);

    public static readonly Dictionary<string, Color> FACTION_COLORS = new()
    {
        { "PLAYER",  new Color(0.961f, 0.706f, 0.000f) },
        { "BV",      new Color(0.914f, 0.306f, 0.235f) },
        { "CE",      new Color(0.243f, 0.639f, 0.298f) },
        { "FB",      new Color(0.608f, 0.349f, 0.839f) },
        { "SV",      new Color(0.180f, 0.490f, 0.843f) },
        { "NEUTRAL", new Color(0.290f, 0.302f, 0.337f) },
    };

    public static readonly Dictionary<string, string> FACTION_NAMES = new()
    {
        { "PLAYER",  "Sua tropa" },
        { "BV",      "Bonde do Vapor" },
        { "CE",      "Comando da Encruzilhada" },
        { "FB",      "Família da Beira" },
        { "SV",      "Sindicato do Vale" },
        { "NEUTRAL", "Sem dono" },
    };

    public static readonly string[] TILE_NAMES = {
        "Beco do Zé",     "Esquina da Vila",   "Travessa Maria",   "Ladeira do Cemitério",
        "Boca do Mato",   "Servidão da Linha", "Becão Velho",      "Curva do Posto",
        "Pé de Manga",    "Subida do Morro",   "Vala da Pedra",    "Ponte de Madeira",
        "Quintal do Tio", "Esquina do Bar",    "Rua do Comércio",  "Largo da Quitanda",
    };

    public static readonly string[] RIVALS = { "BV", "CE", "FB", "SV" };
    public static readonly Dictionary<string, float> RIVAL_AGGRESSION = new()
    {
        { "BV", 0.55f }, { "CE", 0.35f }, { "FB", 0.50f }, { "SV", 0.65f },
    };

    public class ProductInfo
    {
        public string Name;
        public Color Color;
        public float IncomeMult;
        public float HeatMult;
    }

    public static readonly Dictionary<string, ProductInfo> PRODUCT_INFO = new()
    {
        { "PO",   new ProductInfo { Name = "Pó",         Color = new Color(0.91f, 0.91f, 0.91f), IncomeMult = 1.8f, HeatMult = 2.0f } },
        { "ERVA", new ProductInfo { Name = "Erva",       Color = new Color(0.31f, 0.65f, 0.31f), IncomeMult = 1.0f, HeatMult = 0.5f } },
        { "COMP", new ProductInfo { Name = "Comprimido", Color = new Color(0.88f, 0.48f, 0.15f), IncomeMult = 1.3f, HeatMult = 1.0f } },
    };

    public class Territory
    {
        public int Id;
        public string Name;
        public string Owner;
        public int Soldiers;
        public int BaseIncome;
        public int BaseRisk;
        public string Product;
    }

    public class LogEntry
    {
        public int Turn;
        public string Msg;
        public string Tone;
    }

    // ====== Estado ======
    public static string PlayerName = "Você";
    public static int Cash;
    public static int Clean;
    public static int Soldiers;
    public static int Heat;
    public static int Turn = 1;
    public static List<Territory> Territories = new();
    public static List<LogEntry> EventLog = new();
    public static bool Finished;

    // ====== Eventos ======
    public static event Action StateChanged;
    public static event Action<string, string> LogEventEmitted;
    public static event Action<bool, string> GameFinishedEvent;

    static System.Random _rng = new System.Random();

    // ====== Lifecycle ======
    public static void NewGame(string name)
    {
        PlayerName = string.IsNullOrWhiteSpace(name) ? "Você" : name;
        Cash = START_CASH;
        Clean = START_CLEAN;
        Soldiers = START_SOLDIERS;
        Heat = 0;
        Turn = 1;
        Finished = false;
        EventLog.Clear();
        InitTerritories();
        Log($"Bora trampar, {PlayerName}. A quebrada é nossa.", "gold");
        StateChanged?.Invoke();
    }

    static void InitTerritories()
    {
        Territories.Clear();
        var corners = new Dictionary<int, string> { { 0, "BV" }, { 3, "CE" }, { 12, "FB" }, { 15, "SV" } };
        const int playerStart = 5;
        var productKeys = new List<string>(PRODUCT_INFO.Keys);

        for (int i = 0; i < N_TILES; i++)
        {
            string owner = "NEUTRAL";
            int def = 1;
            if (corners.TryGetValue(i, out var f))
            {
                owner = f;
                def = 4 + _rng.Next(2);
            }
            else if (i == playerStart)
            {
                owner = "PLAYER";
                def = 2;
            }
            Territories.Add(new Territory
            {
                Id = i,
                Name = TILE_NAMES[i],
                Owner = owner,
                Soldiers = def,
                BaseIncome = 70 + _rng.Next(60),
                BaseRisk = 4 + _rng.Next(6),
                Product = productKeys[_rng.Next(productKeys.Count)],
            });
        }
    }

    // ====== Helpers ======
    public static int TileIncome(Territory t)
    {
        var p = PRODUCT_INFO.GetValueOrDefault(t.Product, PRODUCT_INFO["ERVA"]);
        return Mathf.RoundToInt(t.BaseIncome * p.IncomeMult);
    }

    public static int TileRisk(Territory t)
    {
        var p = PRODUCT_INFO.GetValueOrDefault(t.Product, PRODUCT_INFO["ERVA"]);
        return Mathf.Max(1, Mathf.RoundToInt(t.BaseRisk * p.HeatMult));
    }

    public static int TileCountOwnedBy(string owner)
    {
        int n = 0;
        foreach (var t in Territories) if (t.Owner == owner) n++;
        return n;
    }

    public static bool IsAdjacentToPlayer(int idx)
    {
        int x = idx % GRID_W, y = idx / GRID_W;
        for (int dx = -1; dx <= 1; dx++)
        for (int dy = -1; dy <= 1; dy++)
        {
            if (dx == 0 && dy == 0) continue;
            int nx = x + dx, ny = y + dy;
            if (nx < 0 || nx >= GRID_W || ny < 0 || ny >= GRID_H) continue;
            int nid = ny * GRID_W + nx;
            if (Territories[nid].Owner == "PLAYER") return true;
        }
        return false;
    }

    // ====== Ações do jogador ======
    public static bool SellAt(int id)
    {
        if (Finished || id < 0 || id >= N_TILES) return false;
        var t = Territories[id];
        if (t.Owner != "PLAYER")
        {
            Log($"Vc não controla {t.Name}.", "danger");
            return false;
        }
        int gain = TileIncome(t), r = TileRisk(t);
        Cash += gain;
        Heat = Mathf.Clamp(Heat + r, 0, HEAT_CAP);
        var pname = PRODUCT_INFO.GetValueOrDefault(t.Product)?.Name ?? "produto";
        Log($"Vendeu {pname} em {t.Name}: +R${gain} · +{r} calor", "gold");
        StateChanged?.Invoke();
        CheckLoss();
        return true;
    }

    public static bool Attack(int id)
    {
        if (Finished || id < 0 || id >= N_TILES) return false;
        var t = Territories[id];
        if (t.Owner == "PLAYER") { Log("Já é seu.", "muted"); return false; }
        if (!IsAdjacentToPlayer(id)) { Log("Boca não é vizinha. Avança passo a passo.", "danger"); return false; }
        if (Soldiers < t.Soldiers + 1) { Log($"Tropa pouca. Precisa {t.Soldiers + 1}, tem {Soldiers}.", "danger"); return false; }

        int losses = t.Soldiers + _rng.Next(2);
        Soldiers = Mathf.Max(0, Soldiers - losses);
        t.Owner = "PLAYER";
        t.Soldiers = Mathf.Max(1, Soldiers / 6);
        Heat = Mathf.Clamp(Heat + 12, 0, HEAT_CAP);
        Log($"Tomou {t.Name}! Perdeu {losses} na tropa · +12 calor", "success");
        StateChanged?.Invoke();
        return true;
    }

    public static bool Recruit(int amount)
    {
        if (Finished || amount <= 0) return false;
        int cost = amount * RECRUIT_COST_EACH;
        if (Cash < cost) { Log($"Caixa fraco. Precisa R${cost}.", "danger"); return false; }
        Cash -= cost;
        Soldiers += amount;
        Heat = Mathf.Clamp(Heat + 2, 0, HEAT_CAP);
        Log($"Recrutou +{amount} · -R${cost} · +2 calor", "info");
        StateChanged?.Invoke();
        return true;
    }

    public static bool Bribe(int amount)
    {
        if (Finished || amount <= 0) return false;
        if (Cash < amount) { Log("Não tem essa nota.", "danger"); return false; }
        int drop = amount / 50;
        if (amount >= 500) drop += 2;
        Cash -= amount;
        Heat = Mathf.Clamp(Heat - drop, 0, HEAT_CAP);
        Log($"Subornou: -R${amount} · -{drop} calor", "info");
        StateChanged?.Invoke();
        return true;
    }

    public static bool Launder(int amount)
    {
        if (Finished || amount <= 0) return false;
        if (Cash < amount) { Log("Sem caixa pra lavar.", "danger"); return false; }
        int outAmt = Mathf.RoundToInt(amount * (1f - LAUNDER_FEE));
        Cash -= amount;
        Clean += outAmt;
        Log($"Lavou R${amount} → R${outAmt} limpo (taxa 18%)", "gold");
        StateChanged?.Invoke();
        CheckVictory();
        return true;
    }

    public static void EndTurn()
    {
        if (Finished) return;
        int passiveIncome = 0, passiveHeat = 0;
        foreach (var t in Territories)
        {
            if (t.Owner != "PLAYER") continue;
            passiveIncome += Mathf.RoundToInt(TileIncome(t) * 0.35f);
            passiveHeat += Mathf.RoundToInt(TileRisk(t) * 0.35f);
        }
        Cash += passiveIncome;
        Heat = Mathf.Clamp(Heat + passiveHeat, 0, HEAT_CAP);
        if (passiveIncome > 0) Log($"Renda passiva: +R${passiveIncome} · +{passiveHeat} calor", "info");

        Heat = Mathf.Clamp(Heat - 3, 0, HEAT_CAP);
        RivalsAI();
        MaybeRandomEvent();
        if (Heat >= 75) PoliceRaid();

        Turn++;
        StateChanged?.Invoke();
        CheckVictory();
        CheckLoss();
    }

    static void RivalsAI()
    {
        foreach (var f in RIVALS)
        {
            float aggr = RIVAL_AGGRESSION.GetValueOrDefault(f, 0.4f);
            if (_rng.NextDouble() > aggr) continue;
            var myTiles = Territories.FindAll(x => x.Owner == f);
            if (myTiles.Count == 0) continue;
            var src = myTiles[_rng.Next(myTiles.Count)];
            int x = src.Id % GRID_W, y = src.Id / GRID_W;
            var targets = new List<Territory>();
            for (int dx = -1; dx <= 1; dx++)
            for (int dy = -1; dy <= 1; dy++)
            {
                if (dx == 0 && dy == 0) continue;
                int nx = x + dx, ny = y + dy;
                if (nx < 0 || nx >= GRID_W || ny < 0 || ny >= GRID_H) continue;
                var n = Territories[ny * GRID_W + nx];
                if (n.Owner != f) targets.Add(n);
            }
            if (targets.Count == 0) continue;
            var target = targets[_rng.Next(targets.Count)];
            int strength = src.Soldiers + _rng.Next(3);
            if (strength > target.Soldiers)
            {
                string prev = target.Owner;
                target.Owner = f;
                target.Soldiers = Mathf.Max(1, strength - target.Soldiers);
                src.Soldiers = Mathf.Max(1, src.Soldiers - 1);
                Log(prev == "PLAYER"
                    ? $"{FACTION_NAMES[f]} invadiu {target.Name} na sua cara!"
                    : $"{FACTION_NAMES[f]} avançou em {target.Name}.",
                    prev == "PLAYER" ? "danger" : "muted");
            }
        }
    }

    static void MaybeRandomEvent()
    {
        if (_rng.NextDouble() > 0.28) return;
        int roll = _rng.Next(8);
        switch (roll)
        {
            case 0: Log("Sumiu um vapor da tropa. -1 soldado.", "danger"); Soldiers = Mathf.Max(0, Soldiers - 1); break;
            case 1: Log("Boato na quebrada: viatura subindo. +6 calor.", "danger"); Heat = Mathf.Clamp(Heat + 6, 0, HEAT_CAP); break;
            case 2: Log("Vereador pede 'colaboração'. -R$200, -4 calor.", "info"); if (Cash >= 200) { Cash -= 200; Heat = Mathf.Clamp(Heat - 4, 0, HEAT_CAP); } break;
            case 3: Log("Mídia denuncia operações. +8 calor.", "danger"); Heat = Mathf.Clamp(Heat + 8, 0, HEAT_CAP); break;
            case 4: Log("Festa na laje rende contatos: +R$150 limpo.", "gold"); Clean += 150; break;
            case 5: Log("Informante quer trocar fita. -R$120, -5 calor.", "info"); if (Cash >= 120) { Cash -= 120; Heat = Mathf.Clamp(Heat - 5, 0, HEAT_CAP); } break;
            case 6: Log("Soldado fiel trouxe um irmão: +1 soldado.", "success"); Soldiers++; break;
            case 7: Log("Produto roubado: -R$80.", "danger"); Cash = Mathf.Max(0, Cash - 80); break;
        }
    }

    static void PoliceRaid()
    {
        int severity = Heat - 70;
        if (Cash >= severity * 80)
        {
            int bribeCost = severity * 80;
            Cash -= bribeCost;
            Heat = Mathf.Clamp(Heat - 25, 0, HEAT_CAP);
            Log($"Operação policial! Você subornou na hora: -R${bribeCost}, -25 calor.", "danger");
            return;
        }
        var myTiles = Territories.FindAll(x => x.Owner == "PLAYER");
        if (myTiles.Count == 0)
        {
            Log("Operação policial e nada pra perder. -10 soldados.", "danger");
            Soldiers = Mathf.Max(0, Soldiers - 10);
            Heat = Mathf.Clamp(Heat - 40, 0, HEAT_CAP);
            return;
        }
        var target = myTiles[_rng.Next(myTiles.Count)];
        target.Owner = "NEUTRAL";
        target.Soldiers = 0;
        Soldiers = Mathf.Max(0, Soldiers - 3);
        Heat = Mathf.Clamp(Heat - 35, 0, HEAT_CAP);
        Log($"BLITZ na {target.Name}! Perdeu a boca, -3 soldados, -35 calor.", "danger");
    }

    static void CheckVictory()
    {
        if (Finished) return;
        if (Clean >= VICTORY_CLEAN && TileCountOwnedBy("PLAYER") >= N_TILES)
        {
            Finished = true;
            Log("DOMÍNIO TOTAL. Vc mandou na quebrada inteira e lavou um milhão. Lenda.", "gold");
            GameFinishedEvent?.Invoke(true, "Domínio total + R$1M lavado.");
        }
    }

    static void CheckLoss()
    {
        if (Finished) return;
        if (TileCountOwnedBy("PLAYER") == 0 && Cash < 80)
        {
            Finished = true;
            Log("Fim de linha. Sem boca, sem grana, sem corre.", "danger");
            GameFinishedEvent?.Invoke(false, "Sem território e sem caixa.");
            return;
        }
        if (Heat >= HEAT_CAP && Cash < 100)
        {
            Finished = true;
            Log("Caiu. O bagulho ficou doido e o calor te pegou.", "danger");
            GameFinishedEvent?.Invoke(false, "Calor máximo sem grana pra subornar.");
        }
    }

    static void Log(string msg, string tone = "muted")
    {
        EventLog.Insert(0, new LogEntry { Turn = Turn, Msg = msg, Tone = tone });
        if (EventLog.Count > 20) EventLog.RemoveRange(20, EventLog.Count - 20);
        LogEventEmitted?.Invoke(msg, tone);
        Debug.Log($"[Game] T{Turn} · {msg}");
    }

    // ====== Save / Load (PlayerPrefs JSON) ======
    const string SAVE_KEY = "porto_santiago_save_v1";

    public static bool HasSave() => PlayerPrefs.HasKey(SAVE_KEY);

    public static bool SaveGame()
    {
        try
        {
            var data = new SaveData
            {
                PlayerName = PlayerName,
                Cash = Cash, Clean = Clean, Soldiers = Soldiers, Heat = Heat, Turn = Turn,
                Finished = Finished,
                Territories = Territories.ToArray(),
            };
            string json = JsonUtility.ToJson(data);
            PlayerPrefs.SetString(SAVE_KEY, json);
            PlayerPrefs.Save();
            return true;
        }
        catch (Exception e) { Debug.LogError($"Save falhou: {e}"); return false; }
    }

    public static bool LoadGame()
    {
        if (!HasSave()) return false;
        try
        {
            var json = PlayerPrefs.GetString(SAVE_KEY);
            var data = JsonUtility.FromJson<SaveData>(json);
            PlayerName = data.PlayerName ?? "Você";
            Cash = data.Cash; Clean = data.Clean; Soldiers = data.Soldiers;
            Heat = data.Heat; Turn = data.Turn; Finished = data.Finished;
            Territories.Clear();
            if (data.Territories != null) Territories.AddRange(data.Territories);
            if (Territories.Count != N_TILES) InitTerritories();
            EventLog.Clear();
            StateChanged?.Invoke();
            return true;
        }
        catch (Exception e) { Debug.LogError($"Load falhou: {e}"); return false; }
    }

    [Serializable]
    class SaveData
    {
        public string PlayerName;
        public int Cash, Clean, Soldiers, Heat, Turn;
        public bool Finished;
        public Territory[] Territories;
    }
}
