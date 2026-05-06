# mission_manager.gd
# Autoload "MissionManager"
extends Node

signal mission_completed(mission_id: String)
signal mission_updated(mission_id: String, step: int)
signal setting_changed(key: String, value: Variant)

# ── ÉTAT ──────────────────────────────────────────
var current_mission: String = "m001"
var current_step: int = 0
var completed_missions: Array = []
var cipher_unread_count: int = 2  # notifications CIPHER au démarrage
var settings: Dictionary = {
	"crt_filter": true,
	"volume": 1.0,
}


# ── DÉFINITION DES MISSIONS ───────────────────────
# Chaque mission a des étapes avec des conditions à remplir
const MISSIONS = {
	"m001": {
		"title": "Première livraison",
		"steps": [
			{
				"type": "cipher_contains",   # le message CIPHER doit contenir...
				"value": "Nx@2024!secure",    # mot de passe exact requis
				"hint": "Envoie le contenu de documents/password.txt dans CIPHER."
			}
		],
		"reward_message": "Bien. C'est exactement ce que je voulais.\nProchaine instruction à venir.",
		"next_mission": "m002"
	},
	"m002": {
		"title": "Reconnaissance",
		"steps": [
			{
				"type": "cipher_contains",
				"value": "22/tcp",
				"hint": "Lance un nmap sur 10.13.37.1 et envoie le résultat dans CIPHER."
			}
		],
		"reward_message": "Parfait. Je vois que le port 22 est ouvert.\nTu seras utile.",
		"next_mission": ""
	}
}


# ── API PUBLIQUE ──────────────────────────────────

# Appelé par cipher.gd à chaque message envoyé par le joueur
func check_cipher_message(text: String) -> bool:
	if current_mission == "" or not MISSIONS.has(current_mission):
		return false

	var mission = MISSIONS[current_mission]
	if current_step >= mission["steps"].size():
		return false

	var step = mission["steps"][current_step]

	match step["type"]:
		"cipher_contains":
			if step["value"].to_lower() in text.to_lower():
				_complete_step()
				return true

	return false


func get_current_hint() -> String:
	if current_mission == "" or not MISSIONS.has(current_mission):
		return ""
	var mission = MISSIONS[current_mission]
	if current_step >= mission["steps"].size():
		return ""
	return mission["steps"][current_step].get("hint", "")


func is_mission_completed(mission_id: String) -> bool:
	return mission_id in completed_missions


func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	if has_signal("setting_changed"):
		emit_signal("setting_changed", key, value)


# ── INTERNE ───────────────────────────────────────

func _complete_step():
	var mission = MISSIONS[current_mission]
	current_step += 1

	if current_step >= mission["steps"].size():
		_complete_mission()
	else:
		mission_updated.emit(current_mission, current_step)


func _complete_mission():
	var mission_id = current_mission
	completed_missions.append(mission_id)
	mission_completed.emit(mission_id)

	# Passe à la mission suivante
	var next = MISSIONS[mission_id].get("next_mission", "")
	current_mission = next
	current_step = 0
