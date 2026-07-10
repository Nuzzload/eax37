# save_manager.gd
# Autoload "SaveManager"
extends Node

const SAVE_PATH := "user://save.dat"
const VERSION   := 1


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save() -> void:
	var data := {
		"version": VERSION,
		"mission": {
			"current_mission":    MissionManager.current_mission,
			"current_step":       MissionManager.current_step,
			"completed_missions": MissionManager.completed_missions,
			"vpn_connected":      MissionManager.vpn_connected,
			"shown_tech_notes":   MissionManager.shown_tech_notes,
			"cipher_history":     MissionManager.cipher_history,
			"settings":           MissionManager.settings,
		},
		"hacker_brain": {
			"message_count": HackerBrain.message_count,
			"current_mood":  int(HackerBrain.current_mood),
			"last_topic":    HackerBrain.last_topic,
		},
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func load_save() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var text   := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary:
		return false

	var m: Dictionary = parsed.get("mission", {})
	MissionManager.current_mission    = m.get("current_mission",    "m001")
	MissionManager.current_step       = m.get("current_step",       0)
	MissionManager.completed_missions = m.get("completed_missions", [])
	MissionManager.vpn_connected      = m.get("vpn_connected",      false)
	MissionManager.shown_tech_notes   = m.get("shown_tech_notes",   [])
	MissionManager.cipher_history     = m.get("cipher_history",     [])
	var saved_settings: Dictionary    = m.get("settings",           {})
	for key in saved_settings:
		MissionManager.settings[key] = saved_settings[key]

	var hb: Dictionary     = parsed.get("hacker_brain", {})
	HackerBrain.message_count  = hb.get("message_count", 0)
	HackerBrain.current_mood   = hb.get("current_mood",  0)
	HackerBrain.last_topic     = hb.get("last_topic",    "")

	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
