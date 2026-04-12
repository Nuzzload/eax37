# desktop_icons.gd
# Attache à un Control "DesktopIcons"
# Layout : Anchor top-left, Mouse Filter : Pass
# Enfants : VBoxContainer avec les DesktopIcon instanciés
extends Control

signal app_opened(app_id: String)

const ICON_SCENE = preload("res://os/ui/desktop_icon.tscn")

const ICONS = [
	{ "id": "cipher",   "label": "CIPHER",    "desc": "Messagerie chiffrée", "color": "#cc2233", "icon": "🔴" },
	{ "id": "files",    "label": "FILES",      "desc": "Explorateur",         "color": "#ccaa22", "icon": "📁" },
	{ "id": "browser",  "label": "NAVIGATOR",  "desc": "Navigateur",          "color": "#3366cc", "icon": "🌐" },
	{ "id": "terminal", "label": "TERMINAL",   "desc": "Terminal",            "color": "#22cc66", "icon": "⬛" },
]

# app_id -> nombre de notifications
var notifications: Dictionary = {}


func _ready():
	# Le VBoxContainer est déjà dans la scène, on le récupère
	var vbox = get_child(0)
	vbox.add_theme_constant_override("separation", 4)
	# Important : le vbox ne doit pas s'étirer
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	vbox.mouse_filter = Control.MOUSE_FILTER_STOP

	for icon_data in ICONS:
		var icon = ICON_SCENE.instantiate()
		vbox.add_child(icon)
		icon.setup(icon_data)
		# Capture la valeur dans une variable locale pour la lambda
		var id = icon_data["id"]
		icon.double_clicked.connect(func(): app_opened.emit(id))

	# Notification CIPHER au démarrage
	set_notification("cipher", 2)


func set_notification(app_id: String, count: int):
	notifications[app_id] = count
	# Trouve l'icône et met à jour
	var vbox = get_child(0)
	for icon in vbox.get_children():
		if icon.app_id == app_id:
			icon.set_notification(count)
			break
