using UnityEngine;
using UnityEngine.EventSystems;

// GameBootstrap — entry point chamado automaticamente pelo Unity
// ANTES de qualquer cena carregar. Cria o GameObject raiz com Camera,
// EventSystem e UIController, todos via código. Isso elimina dependência
// de cenas hand-authored e meta files corretas.

public static class GameBootstrap
{
    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
    static void Init()
    {
        Debug.Log("[Bootstrap] Init chamado antes da cena.");
    }

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
    static void PostSceneInit()
    {
        Debug.Log("[Bootstrap] Cena carregada, criando GameRoot.");

        // Camera 2D ortográfica (fundo escuro)
        var camGO = new GameObject("MainCamera");
        Object.DontDestroyOnLoad(camGO);
        var cam = camGO.AddComponent<Camera>();
        cam.clearFlags = CameraClearFlags.SolidColor;
        cam.backgroundColor = Game.COLOR_BG;
        cam.orthographic = true;
        cam.tag = "MainCamera";

        // EventSystem para input de UI
        var esGO = new GameObject("EventSystem");
        Object.DontDestroyOnLoad(esGO);
        esGO.AddComponent<EventSystem>();
        esGO.AddComponent<StandaloneInputModule>();

        // Game root + UIController
        var rootGO = new GameObject("GameRoot");
        Object.DontDestroyOnLoad(rootGO);
        rootGO.AddComponent<UIController>();

        // Estado inicial do jogo
        Game.NewGame("Você");
    }
}
