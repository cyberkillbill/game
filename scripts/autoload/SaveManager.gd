extends Node
## SaveManager — persistência local (JSON encriptado em user://) e stub cloud.
## Implementação completa virá no Passo 4.

const SAVE_PATH := "user://save.dat"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
