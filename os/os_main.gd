# os_main.gd
# Attache à la scène racine OS.tscn
extends Control

@onready var wallpaper: TextureRect = $Wallpaper
@onready var window_manager: Control = $WindowManager
@onready var taskbar: Control = $Taskbar
@onready var desktop_icons: Control = $DesktopIcons

# Liste des ressources d'applications
@export var apps_list: Array[AppResource] = []

var apps_dict: Dictionary = {}

func _ready():
	# Initialise le dictionnaire pour un accès rapide
	for app in apps_list:
		apps_dict[app.id] = app

	# Signal depuis les icônes du bureau
	desktop_icons.app_opened.connect(_on_app_opened)
	# Signal depuis la taskbar
	taskbar.app_focused.connect(_on_taskbar_app_focused)
	taskbar.app_closed.connect(_on_app_closed)
	# Signal depuis le window manager
	window_manager.window_opened.connect(_on_window_opened)
	window_manager.window_closed.connect(_on_window_closed)
	window_manager.window_focused.connect(_on_window_focused)


func _on_app_opened(app_id: String):
	if apps_dict.has(app_id):
		window_manager.open_app_resource(apps_dict[app_id])


func _on_taskbar_app_focused(app_id: String):
	window_manager.focus_app(app_id)


func _on_app_closed(app_id: String):
	window_manager.close_app(app_id)


func _on_window_opened(app_id: String):
	if apps_dict.has(app_id):
		taskbar.add_app(app_id, apps_dict[app_id].label)


func _on_window_closed(app_id: String):
	taskbar.remove_app(app_id)


func _on_window_focused(app_id: String):
	taskbar.set_active(app_id)


func set_wallpaper(path: String):
	var tex = load(path)
	if tex:
		wallpaper.texture = tex


func corrupted_transition(new_path: String):
	var tween = create_tween()
	tween.tween_property(wallpaper, "modulate", Color(3, 3, 3), 0.05)
	tween.tween_callback(func(): set_wallpaper(new_path))
	tween.tween_property(wallpaper, "modulate", Color.WHITE, 0.4)


# Appelé depuis room_scene.gd avec la position du curseur simulé
func on_cursor_press(cursor_pos: Vector2, pressed: bool):
	window_manager.on_cursor_press(cursor_pos, pressed)


func on_cursor_move(cursor_pos: Vector2):
	window_manager.on_cursor_move(cursor_pos)
