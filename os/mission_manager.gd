# mission_manager.gd
# Autoload "MissionManager"
extends Node

signal mission_completed(mission_id: String)
signal mission_updated(mission_id: String, step: int)
signal setting_changed(key: String, value: Variant)
signal hacker_message(text: String)
signal open_cipher()
signal tech_note(id: String, title: String, body: String)
signal tech_note_acknowledged
signal sentinel_message(text: String)
signal chapter_end()
signal demo_end()

var _tech_note_pending := false
var current_mission: String = "m001"
var current_step: int = 0
var completed_missions: Array = []
var cipher_history: Array = []
var vpn_connected: bool = false
var shown_tech_notes: Array = []
var settings: Dictionary = {
	"crt_filter": true,
	"volume": 1.0,
}

const MISSIONS = {
	"m001": {
		"title": "Connexion VPN",
		"steps": [
			{
				"type": "terminal_command",
				"value": "vpn connect nexcorp_vpn Nx@2024!secure",
				"hint": "Trouve les credentials et\nconnecte-toi au VPN NexCorp.",
			}
		],
		"reward_messages": [
			"Je te vois sur le réseau interne.",
			"Bien. Tu commences à comprendre.",
			"Maintenant scanne la cible.",
		],
		"next_mission": "m002"
	},
	"m002": {
		"title": "Reconnaissance réseau",
		"steps": [
			{
				"type": "terminal_command",
				"value": "nmap 10.13.37.1",
				"hint": "Scanne le réseau interne.",
			}
		],
		"reward_messages": [
			"Port 22 ouvert. SSH actif.",
			"Il te faut les credentials SSH.",
			"J'ai déposé quelque chose sur ta machine.",
		],
		"next_mission": "m003"
	},
	"m003": {
		"title": "Brute Force SSH",
		"steps": [
			{
				"type": "terminal_command",
				"value": "hydra -l admin -P rockyou.txt",
				"hint": "Cible : ssh://10.13.37.1\nLogin : admin",
			}
		],
		"reward_messages": [
			"Bien. Tu as le mot de passe.",
			"Connecte-toi maintenant.",
		],
		"next_mission": "m004"
	},
	"m004": {
		"title": "Accès SSH",
		"steps": [
			{
				"type": "terminal_command",
				"value": "ssh admin@10.13.37.1",
				"hint": "Connecte-toi en SSH au serveur.",
			}
		],
		"reward_messages": [
			"Tu es dedans.",
			"Lis ce que l'admin a laissé sur sa machine.",
			"/data/confidentiel/ — c'est là que tu trouveras ce que je cherche.",
		],
		"next_mission": "m005"
	},
	"m005": {
		"title": "Récupération",
		"steps": [
			{
				"type": "terminal_command",
				"value": "nexus_registry.dat",
				"hint": "Explore /data/confidentiel/",
			}
		],
		"reward_messages": [],
		"next_mission": ""
	}
}

func reset() -> void:
	current_mission    = "m001"
	current_step       = 0
	completed_missions = []
	cipher_history     = []
	vpn_connected      = false
	shown_tech_notes   = []
	_tech_note_pending = false


# ── API PUBLIQUE ──────────────────────────────────

func check_file_read(filename: String) -> bool:
	return _check_action("file_read", filename)

func check_terminal_command(command: String) -> bool:
	return _check_action("terminal_command", command)

func check_cipher_message(text: String) -> bool:
	return _check_action("cipher_contains", text)

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

func show_tech_note(id: String, title: String, body: String) -> void:
	if id in shown_tech_notes:
		return
	shown_tech_notes.append(id)
	_tech_note_pending = true
	tech_note.emit(id, title, body)

func on_tech_note_dismissed() -> void:
	_tech_note_pending = false
	tech_note_acknowledged.emit()

# ── INTERNE ───────────────────────────────────────

func _check_action(action_type: String, value: String) -> bool:
	if current_mission == "" or not MISSIONS.has(current_mission):
		return false
	var mission = MISSIONS[current_mission]
	if current_step >= mission["steps"].size():
		return false
	var step = mission["steps"][current_step]
	if step["type"] != action_type:
		return false
	if step["value"].to_lower() in value.to_lower():
		_complete_step()
		return true
	return false


func _complete_step():
	var mission = MISSIONS[current_mission]
	current_step += 1
	if current_step >= mission["steps"].size():
		_complete_mission()
	else:
		mission_updated.emit(current_mission, current_step)


func _complete_mission():
	var mission_id = current_mission
	var mission = MISSIONS[mission_id]
	completed_missions.append(mission_id)

	if mission_id == "m001":
		vpn_connected = true

	mission_completed.emit(mission_id)

	var next = mission.get("next_mission", "")
	current_mission = next
	current_step = 0

	SaveManager.save()

	if mission_id == "m005":
		_trigger_cliffhanger()
	else:
		_send_reward_messages(mission_id, mission.get("reward_messages", []))


func _send_reward_messages(mission_id: String, messages: Array) -> void:
	if messages.is_empty():
		return
	if _tech_note_pending:
		await tech_note_acknowledged
	await get_tree().create_timer(1.5).timeout
	open_cipher.emit()
	for i in range(messages.size()):
		await get_tree().create_timer(1.8 + i * 0.3).timeout
		hacker_message.emit(messages[i])
		if i < messages.size() - 1:
			await get_tree().create_timer(2.0).timeout
	if mission_id == "m002":
		# CIPHER vient de dire avoir déposé rockyou.txt : le dossier
		# wordlists devient visible dans le filesystem à partir d'ici.
		GameFS.refresh_locked_content()
	SaveManager.save()


func _trigger_cliffhanger() -> void:
	if _tech_note_pending:
		await tech_note_acknowledged
	await get_tree().create_timer(1.5).timeout
	open_cipher.emit()
	await get_tree().create_timer(2.5).timeout
	hacker_message.emit("Tu as vu ce qu'il fallait voir.")
	await get_tree().create_timer(3.5).timeout
	hacker_message.emit("Maintenant tu sais où tu en es.")
	await get_tree().create_timer(3.5).timeout
	hacker_message.emit("La phase 2 commence bientôt.\nAttends.")
	await get_tree().create_timer(4.0).timeout
	hacker_message.emit("— CONNEXION FERMÉE —")
	# Pause dramatique, puis glitch, puis SENTINELLE
	await get_tree().create_timer(3.5).timeout
	chapter_end.emit()
	await get_tree().create_timer(1.5).timeout
	sentinel_message.emit("Ce fichier est surveillé.\nJe t'ai vu lire.")
	await get_tree().create_timer(4.0).timeout
	sentinel_message.emit("Ce que tu viens de découvrir va tout changer.\nPas seulement pour toi.")
	await get_tree().create_timer(4.0).timeout
	sentinel_message.emit("Ne fais pas confiance à INCONNU.\nJe peux t'expliquer. Mais pas ici.")
	await get_tree().create_timer(3.5).timeout
	sentinel_message.emit("▓▓▓  FIN DU CHAPITRE 1  ▓▓▓")
	SaveManager.save()
	# Laisse le joueur lire le dernier message avant le rideau final
	await get_tree().create_timer(4.5).timeout
	demo_end.emit()
