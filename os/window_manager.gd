# window_manager.gd
extends Control

signal window_opened(app_id: String)
signal window_closed(app_id: String)
signal window_focused(app_id: String)

var open_windows: Dictionary = {}
var top_z: int = 10

const WINDOW_SCENE = preload("res://os/ui/window.tscn")

const START_POSITIONS = {
	"cipher":   Vector2(80,  60),
	"files":    Vector2(160, 80),
	"browser":  Vector2(200, 40),
	"terminal": Vector2(120, 100),
}


func open_app_resource(app: AppResource):
	if open_windows.has(app.id):
		focus_app(app.id)
		return

	var win = WINDOW_SCENE.instantiate()
	add_child(win)

	top_z += 1
	win.z_index = top_z
	win.position = START_POSITIONS.get(app.id, Vector2(100, 80))
	win.custom_minimum_size = app.default_size
	win.size = app.default_size
	win.pivot_offset = app.default_size / 2

	win.setup(
		app.id,
		app.label,
		app.accent_color,
		app.scene
	)

	win.close_requested.connect(func(): _actually_close_app(app.id))
	win.focus_requested.connect(func(): focus_app(app.id))

	open_windows[app.id] = win
	window_opened.emit(app.id)


func open_app(app_id: String, app_data: Dictionary):
	# Gardé pour compatibilité temporaire si nécessaire
	var app = AppResource.new()
	app.id = app_id
	app.label = app_data.get("label", "App")
	app.scene = load(app_data["scene"])
	open_app_resource(app)


func close_app(app_id: String):
	if not open_windows.has(app_id):
		return
	var win = open_windows[app_id]
	if win.has_method("close_window"):
		win.close_window()
	else:
		_actually_close_app(app_id)


func _actually_close_app(app_id: String):
	if not open_windows.has(app_id):
		return
	var win = open_windows[app_id]
	open_windows.erase(app_id)
	win.queue_free()
	window_closed.emit(app_id)


func focus_app(app_id: String):
	if not open_windows.has(app_id):
		return
	var win = open_windows[app_id]
	# Si minimisée → restaure avec animation
	if win.is_minimized:
		win.restore()
	top_z += 1
	win.z_index = top_z
	window_focused.emit(app_id)


# Appelé depuis os_main avec la position du curseur simulé
func on_cursor_press(cursor_pos: Vector2, pressed: bool):
	# Trouve la fenêtre sous le curseur (la plus haute en z)
	var best_win = null
	var best_z = -1
	for win in open_windows.values():
		var win_rect = Rect2(win.position, win.size)
		if win_rect.has_point(cursor_pos):
			if win.z_index > best_z:
				best_z = win.z_index
				best_win = win

	if best_win:
		best_win.handle_cursor_press(cursor_pos, pressed)


func on_cursor_move(cursor_pos: Vector2):
	# Propage le mouvement à la fenêtre en cours de drag
	for win in open_windows.values():
		if win.is_dragging:
			win.handle_cursor_move(cursor_pos)
			return
