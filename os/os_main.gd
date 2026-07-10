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
# Tech note layer — toujours au-dessus de toutes les fenêtres
var _tech_note_layer: CanvasLayer = null
func _ready():
	for app in apps_list:
		apps_dict[app.id] = app
	_tech_note_layer = CanvasLayer.new()
	_tech_note_layer.layer = 200
	add_child(_tech_note_layer)
	desktop_icons.app_opened.connect(_on_app_opened)
	taskbar.app_focused.connect(_on_taskbar_app_focused)
	window_manager.window_opened.connect(_on_window_opened)
	window_manager.window_closed.connect(_on_window_closed)
	window_manager.window_focused.connect(_on_window_focused)
	MissionManager.mission_completed.connect(_on_mission_completed)
	MissionManager.mission_updated.connect(_on_mission_updated)
	MissionManager.open_cipher.connect(_on_open_cipher)
	MissionManager.tech_note.connect(_on_tech_note)
	MissionManager.chapter_end.connect(_on_chapter_end)
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
	GlitchManager.trigger(0.3, 0.25)
func _on_mission_updated(_id: String, _step: int):
	_refresh_reminder()

func _on_open_cipher() -> void:
	if not window_manager.open_windows.has("cipher"):
		_on_app_opened("cipher")
	call_deferred("_focus_cipher")

func _focus_cipher() -> void:
	window_manager.focus_app("cipher")
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
func _on_chapter_end() -> void:
	GlitchManager.trigger(1.0, 0.8, "sentinel")


func _on_tech_note(_id: String, title: String, body: String) -> void:
	# Conteneur racine dans le CanvasLayer 200 — toujours au-dessus de tout
	var overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_tech_note_layer.add_child(overlay)

	# Fond assombri
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)

	# Centrage du panneau
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 0)
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color("#040a06")
	ps.border_color = Color("#22cc66")
	ps.set_border_width_all(1)
	ps.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", ps)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	# Header
	var header_bg = ColorRect.new()
	header_bg.color = Color("#0d1f10")
	header_bg.custom_minimum_size.y = 34
	vbox.add_child(header_bg)
	var hm = MarginContainer.new()
	hm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hm.add_theme_constant_override("margin_left", 14)
	hm.add_theme_constant_override("margin_right", 14)
	hm.add_theme_constant_override("margin_top", 8)
	hm.add_theme_constant_override("margin_bottom", 8)
	var hl = HBoxContainer.new()
	var dot = ColorRect.new()
	dot.color = Color("#22cc66")
	dot.custom_minimum_size = Vector2(7, 7)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hl.add_child(dot)
	hl.add_theme_constant_override("separation", 8)
	var ht = Label.new()
	ht.text = "▸ TECH NOTE — " + title.to_upper()
	ht.add_theme_color_override("font_color", Color("#22cc66"))
	ht.add_theme_font_size_override("font_size", 11)
	hl.add_child(ht)
	hm.add_child(hl)
	header_bg.add_child(hm)

	var sep = ColorRect.new()
	sep.color = Color(0.133, 0.8, 0.4, 0.3)
	sep.custom_minimum_size.y = 1
	vbox.add_child(sep)

	# Body
	var bm = MarginContainer.new()
	bm.add_theme_constant_override("margin_left", 16)
	bm.add_theme_constant_override("margin_right", 16)
	bm.add_theme_constant_override("margin_top", 14)
	bm.add_theme_constant_override("margin_bottom", 10)
	var bv = VBoxContainer.new()
	bv.add_theme_constant_override("separation", 5)
	bm.add_child(bv)
	vbox.add_child(bm)
	for line in body.split("\n"):
		var ll = Label.new()
		ll.text = line
		ll.add_theme_font_size_override("font_size", 11)
		ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if line.begins_with("Défense") or line.begins_with("Vecteur") or line.begins_with("Risque") or line.begins_with("Ici :") or line.begins_with("Phase"):
			ll.add_theme_color_override("font_color", Color("#cc8844"))
		else:
			ll.add_theme_color_override("font_color", Color("#c8c8d4"))
		bv.add_child(ll)

	# Bouton fermeture
	var btnm = MarginContainer.new()
	btnm.add_theme_constant_override("margin_left", 16)
	btnm.add_theme_constant_override("margin_right", 16)
	btnm.add_theme_constant_override("margin_top", 4)
	btnm.add_theme_constant_override("margin_bottom", 14)
	var btn = Button.new()
	btn.text = "[ COMPRIS ]"
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color("#0d1f10")
	bs.border_color = Color("#22cc66")
	bs.border_color.a = 0.5
	bs.set_border_width_all(1)
	bs.set_content_margin(SIDE_LEFT, 20)
	bs.set_content_margin(SIDE_RIGHT, 20)
	bs.set_content_margin(SIDE_TOP, 7)
	bs.set_content_margin(SIDE_BOTTOM, 7)
	var bsh = bs.duplicate()
	bsh.bg_color = Color("#1a3d20")
	btn.add_theme_stylebox_override("normal", bs)
	btn.add_theme_stylebox_override("hover", bsh)
	btn.add_theme_stylebox_override("pressed", bsh)
	btn.add_theme_color_override("font_color", Color("#22cc66"))
	btn.add_theme_font_size_override("font_size", 11)
	btnm.add_child(btn)
	vbox.add_child(btnm)

	btn.pressed.connect(func():
		MissionManager.on_tech_note_dismissed()
		var t2 = create_tween()
		t2.tween_property(overlay, "modulate:a", 0.0, 0.2)
		t2.tween_callback(overlay.queue_free)
	)


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
	_r_bg.offset_top = 8;    _r_bg.offset_bottom = 88
	add_child(_r_bg)
	_r_bar = ColorRect.new()
	_r_bar.color = Color("#ccaa22")
	_r_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_r_bar.anchor_left = 1.0; _r_bar.anchor_right = 1.0
	_r_bar.anchor_top = 0.0;  _r_bar.anchor_bottom = 0.0
	_r_bar.offset_left = -206; _r_bar.offset_right = -204
	_r_bar.offset_top = 8;    _r_bar.offset_bottom = 88
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
	_r_hint.offset_top = 46;   _r_hint.offset_bottom = 86
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
