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

const WINDOW_SIZES = {
	"cipher":   Vector2(520, 520),
	"files":    Vector2(680, 480),
	"browser":  Vector2(740, 520),
	"terminal": Vector2(620, 440),
}

const WINDOW_COLORS = {
	"cipher":   Color("#cc2233"),
	"files":    Color("#ccaa22"),
	"browser":  Color("#3366cc"),
	"terminal": Color("#22cc66"),
}


func open_app(app_id: String, app_data: Dictionary):
	if open_windows.has(app_id):
		focus_app(app_id)
		return

	var win = WINDOW_SCENE.instantiate()
	add_child(win)

	top_z += 1
	win.z_index = top_z
	win.position = START_POSITIONS.get(app_id, Vector2(100, 80))
	win.custom_minimum_size = WINDOW_SIZES.get(app_id, Vector2(600, 400))
	win.size = WINDOW_SIZES.get(app_id, Vector2(600, 400))

	win.setup(
		app_id,
		app_data["label"],
		WINDOW_COLORS.get(app_id, Color("#333344")),
		load(app_data["scene"])
	)

	win.close_requested.connect(func(): close_app(app_id))
	win.focus_requested.connect(func(): focus_app(app_id))

	open_windows[app_id] = win
	window_opened.emit(app_id)


func close_app(app_id: String):
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
	# Si minimisée → restaure toujours
	if not win.visible:
		win.visible = true
		win.is_minimized = false
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
