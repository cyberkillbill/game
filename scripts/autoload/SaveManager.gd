extends Node
## SaveManager — persistência local em JSON encriptado em user://.
## Stub de cloud (Firebase) também aqui, sem conexão real ainda.

const SAVE_PATH := "user://save.json"
const CLOUD_PATH := "user://cloud_pending.json"
const ENCRYPTION_KEY := "porto-santiago-v1-local-key"

signal save_completed(success: bool)
signal load_completed(success: bool)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var data := GameManager.to_dict()
	var json := JSON.stringify(data, "\t", false)
	var f := FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.WRITE, ENCRYPTION_KEY)
	if f == null:
		# Fallback sem encriptação se a plataforma reclamar.
		f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if f == null:
			push_error("Não foi possível abrir save para escrita.")
			save_completed.emit(false)
			return false
	f.store_string(json)
	f.close()
	save_completed.emit(true)
	return true


func load_game() -> bool:
	if not has_save():
		load_completed.emit(false)
		return false
	var f := FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.READ, ENCRYPTION_KEY)
	if f == null:
		f = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f == null:
			load_completed.emit(false)
			return false
	var raw := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if parsed == null or not (parsed is Dictionary):
		load_completed.emit(false)
		return false
	GameManager.from_dict(parsed)
	load_completed.emit(true)
	return true


# Cloud sync stub — quando integrar Firebase, este método empurra o save
# atual pra Firestore. Por enquanto só registra a intenção.
func push_to_cloud() -> void:
	var data := GameManager.to_dict()
	var f := FileAccess.open(CLOUD_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()
	print("[SaveManager] Cloud push pendente (Firebase não conectado).")


func pull_from_cloud() -> bool:
	if not FileAccess.file_exists(CLOUD_PATH):
		return false
	var f := FileAccess.open(CLOUD_PATH, FileAccess.READ)
	if f == null:
		return false
	var raw := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if parsed == null or not (parsed is Dictionary):
		return false
	GameManager.from_dict(parsed)
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
