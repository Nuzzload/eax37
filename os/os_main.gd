# os_main.gd
# Attache à la scène racine OS.tscn
extends Control
@onready var wallpaper: TextureRect = $Wallpaper
@onready var window_manager: Control = $WindowManager
@onready var taskbar: Control = $Taskbar
@onready var desktop_icons: Control = $DesktopIcons
@onready var post_process: ColorRect = $PostProcess
# Liste des ressources d'applications
@export var apps_list: Array[AppResource] = []
var apps_dict: Dictionary = {}
# Reminder mission
var _r_bg: ColorRect = null
var _r_bar: ColorRect = null
var _r_header: Label = null
var _r_title: Label = null
var _r_hint: Label = null
func _ready():
	for app in apps_list:
		apps_dict[app.id] = app
	desktop_icons.app_opened.connect(_on_app_opened)
	taskbar.app_focused.connect(_on_taskbar_app_focused)
	window_manager.window_opened.connect(_on_window_opened)
	window_manager.window_closed.connect(_on_window_closed)
	window_manager.window_focused.connect(_on_window_focused)
	MissionManager.mission_completed.connect(_on_mission_completed)
	MissionManager.mission_updated.connect(_on_mission_updated)
	if MissionManager.has_signal("setting_changed"):
		MissionManager.setting_changed.connect(_on_setting_changed)
	_apply_all_settings()
	call_deferred("_build_reminder")
func _on_setting_changed(id: String, value: Variant):
	if id == "crt_filter":
		post_process.visible = value
func _apply_all_settings():
	if post_process:
		post_process.visible = MissionManager.settings.get("crt_filter", true)
func _on_mission_completed(_id: String):
	_refresh_reminder()
	corrupted_transition("")
func _on_mission_updated(_id: String, _step: int):
	_refresh_reminder()
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
func on_cursor_press(cursor_pos: Vector2, pressed: bool):
	window_manager.on_cursor_press(cursor_pos, pressed)
func on_cursor_move(cursor_pos: Vector2):
	window_manager.on_cursor_move(cursor_pos)
# ── REMINDER ──────────────────────────────────────
func _build_reminder() -> void:
	_r_bg = ColorRect.new()
	_r_bg.color = Color(0.0, 0.0, 0.0, 0.65)
	_r_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_r_bg.anchor_left = 1.0; _r_bg.anchor_right = 1.0
	_r_bg.anchor_top = 0.0;  _r_bg.anchor_bottom = 0.0
	_r_bg.offset_left = -206; _r_bg.offset_right = -8
	_r_bg.offset_top = 8;    _r_bg.offset_bottom = 76
	add_child(_r_bg)
	_r_bar = ColorRect.new()
	_r_bar.color = Color("#ccaa22")
	_r_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_r_bar.anchor_left = 1.0; _r_bar.anchor_right = 1.0
	_r_bar.anchor_top = 0.0;  _r_bar.anchor_bottom = 0.0
	_r_bar.offset_left = -206; _r_bar.offset_right = -204
	_r_bar.offset_top = 8;    _r_bar.offset_bottom = 76
	add_child(_r_bar)
	_r_header = _rlbl("▸ MISSION EN COURS", 8, Color("#ccaa22"))
	_r_header.anchor_left = 1.0; _r_header.anchor_right = 1.0
	_r_header.anchor_top = 0.0;  _r_header.anchor_bottom = 0.0
	_r_header.offset_left = -200; _r_header.offset_right = -10
	_r_header.offset_top = 12;   _r_header.offset_bottom = 26
	add_child(_r_header)
	_r_title = _rlbl("", 11, Color("#e8e8f0"))
	_r_title.anchor_left = 1.0; _r_title.anchor_right = 1.0
	_r_title.anchor_top = 0.0;  _r_title.anchor_bottom = 0.0
	_r_title.offset_left = -200; _r_title.offset_right = -10
	_r_title.offset_top = 28;   _r_title.offset_bottom = 46
	add_child(_r_title)
	_r_hint = _rlbl("", 9, Color("#5a5a6e"))
	_r_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_r_hint.anchor_left = 1.0; _r_hint.anchor_right = 1.0
	_r_hint.anchor_top = 0.0;  _r_hint.anchor_bottom = 0.0
	_r_hint.offset_left = -200; _r_hint.offset_right = -10
	_r_hint.offset_top = 46;   _r_hint.offset_bottom = 74
	add_child(_r_hint)
	_refresh_reminder()
func _rlbl(text: String, size: int, color: Color) -> Label:
	var l = Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return l
func _refresh_reminder() -> void:
	if not _r_title:
		return
	var hint = MissionManager.get_current_hint()
	var show = hint != ""
	_r_bg.visible = show; _r_bar.visible = show
	_r_header.visible = show; _r_title.visible = show; _r_hint.visible = show
	if show:
		var m = MissionManager.MISSIONS.get(MissionManager.current_mission, {})
		_r_title.text = m.get("title", "")
		_r_hint.text = hint
