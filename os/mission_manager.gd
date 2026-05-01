# mission_manager.gd
extends Node

signal mission_started(mission_id: String)
signal mission_updated(mission_id: String, step: int)
signal mission_completed(mission_id: String)
signal cipher_message_added(msg: Dictionary)
signal cipher_notifications_changed(count: int)
signal setting_changed(setting_id: String, value: Variant)

var current_mission := "m001"
var current_step := 0

# Paramètres de l'OS
var settings := {
	"crt_filter": true
}


func set_setting(id: String, value: Variant):
	settings[id] = value
	setting_changed.emit(id, value)

# Persistance des messages Cipher
var cipher_history: Array[Dictionary] = [
	{ "from": "UNKNOWN_▓▓▓", "time": "02:14", "text": "Je sais ce que tu as fait.", "unread": false },
	{ "from": "UNKNOWN_▓▓▓", "time": "02:31", "text": "Ne contacte personne. Ne dis rien à personne.", "unread": false },
	{ "from": "UNKNOWN_▓▓▓", "time": "08:03", "text": "Première mission. Simple.\nRécupère le fichier /documents/password.txt et envoie-le moi ici.", "unread": false },
	{ "from": "UNKNOWN_▓▓▓", "time": "08:04", "text": "Tu as 3 heures.", "unread": true },
	{ "from": "UNKNOWN_▓▓▓", "time": "08:05", "text": "Et ne joue pas au plus malin. Je regarde.", "unread": true },
]
var cipher_unread_count := 2

func _ready():
	# Délai avant le premier message pour laisser le temps au joueur de s'installer
	await get_tree().create_timer(5.0).timeout
	start_mission("m001")


func start_mission(id: String):
	current_mission = id
	current_step = 0
	mission_started.emit(id)
	print("Mission started: ", id)


func complete_step(id: String, step: int):
	if id == current_mission and step == current_step:
		current_step += 1
		mission_updated.emit(id, current_step)
		
		if current_step >= MISSIONS[id]["steps"].size():
			complete_mission(id)


func complete_mission(id: String):
	mission_completed.emit(id)
	# Déclenche une petite récompense visuelle ou narrative
	_trigger_glitch_event()


func _trigger_glitch_event():
	# On peut envoyer un signal pour que room_scene ou os_main fasse quelque chose
	pass


func add_cipher_message(from: String, text: String, unread: bool = false):
	var t = Time.get_time_dict_from_system()
	var time_str = "%02d:%02d" % [t["hour"], t["minute"]]
	var msg = { "from": from, "time": time_str, "text": text, "unread": unread }
	cipher_history.append(msg)
	if unread:
		cipher_unread_count += 1
		cipher_notifications_changed.emit(cipher_unread_count)
	cipher_message_added.emit(msg)


func mark_cipher_as_read():
	cipher_unread_count = 0
	for msg in cipher_history:
		msg["unread"] = false
	cipher_notifications_changed.emit(0)


# Appelée par Cipher quand l'utilisateur envoie un message
func check_cipher_message(text: String):
	if current_mission == "m001" and current_step == 1:
		if text.to_lower() == MISSIONS["m001"]["target_password"]:
			complete_mission("m001")
			return true
	return false


# Données des missions
const MISSIONS = {
	"m001": {
		"title": "First Contact",
		"steps": [
			"Trouver le mot de passe dans /documents/password.txt",
			"Envoyer le mot de passe au hacker via Cipher"
		],
		"target_password": "mysuperpassword"
	}
}
