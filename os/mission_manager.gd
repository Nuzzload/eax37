# mission_manager.gd
# Autoload "MissionManager"
extends Node

signal mission_completed(mission_id: String)
signal mission_updated(mission_id: String, step: int)
signal setting_changed(key: String, value: Variant)
signal game_ending(ending_type: String)  # "bad" ou "good"

# ── ÉTAT ──────────────────────────────────────────
var current_mission: String = "m001"
var current_step: int = 0
var completed_missions: Array = []
var cipher_unread_count: int = 2  # notifications CIPHER au démarrage
var last_ending: String = ""
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
				"type": "cipher_contains",
				"value": "Nx@2024!secure",
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
		"reward_message": "Parfait. Je vois que le port 22 est ouvert.\nTu seras utile.\n\nProchaine étape : j'ai besoin d'un accès plus profond à ta machine.\nEnvoie-moi le contenu de ~/.ssh/authorized_keys.",
		"next_mission": "m003"
	},
	"m003": {
		"title": "Accès SSH",
		"steps": [
			{
				"type": "cipher_contains",
				"value": "UNKNOWN_OPERATOR",
				"hint": "Envoie le contenu de ~/.ssh/authorized_keys dans CIPHER."
			}
		],
		"reward_message": "Bien reçu. Clé confirmée.\n\nMaintenant : quelqu'un d'autre observe ta machine.\nConsulte ~/logs/connection.log et dis-moi ce que tu trouves.",
		"next_mission": "m004"
	},
	"m004": {
		"title": "Analyse des traces",
		"steps": [
			{
				"type": "cipher_contains",
				"value": "10.13.37.254",
				"hint": "Analyse ~/logs/connection.log et envoie l'IP suspecte dans CIPHER."
			}
		],
		"reward_message": "...\n\nTu es plus malin que tu en as l'air.\nC'est moi. C'était toujours moi.\n\nDernière mission. Lance l'attaque sur 10.13.37.1.\nConfirme avec l'IP cible.",
		"next_mission": "m005"
	},
	"m005": {
		"title": "Fin de partie",
		"steps": [
			{
				"type": "cipher_choice",
				"value_bad": "10.13.37.1",    # obéir → bad ending
				"value_good": "10.13.37.254",  # retourner l'attaque → good ending
				"hint": "Envoie l'IP cible dans CIPHER : obéis, ou retourne l'attaque."
			}
		],
		"reward_message": "",  # géré par cipher.gd selon le choix
		"next_mission": ""
	},
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

		"cipher_choice":
			var txt = text.to_lower().strip_edges()
			if step["value_bad"].to_lower() in txt:
				last_ending = "bad"
				_complete_step()
				return true
			elif step["value_good"].to_lower() in txt:
				last_ending = "good"
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
	setting_changed.emit(key, value)


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

	# Déclenche la fin si c'était la dernière mission
	if mission_id == "m005":
		game_ending.emit(last_ending)
