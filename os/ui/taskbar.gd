# taskbar.gd
# Attache à Taskbar.tscn
# Structure :
#   PanelContainer (taskbar.gd)  ← Full Rect horizontal, ancré en bas
#   └── HBoxContainer
#       ├── LogoLabel (Label)          ← "EAX37"
#       ├── Separator (VSeparator)
#       ├── OpenApps (HBoxContainer)   ← boutons apps ouvertes
#       ├── Spacer (Control)           ← flex spacer
#       ├── AlertContainer (HBoxContainer) ← alertes CIPHER etc
#       ├── Separator2 (VSeparator)
#       └── ClockLabel (Label)
extends PanelContainer

signal app_focused(app_id: String)

@onready var open_apps: HBoxContainer = $MarginContainer/HBoxContainer/OpenApps
@onready var clock_label: Label = $MarginContainer/HBoxContainer/ClockLabel
@onready var alert_container: HBoxContainer = $MarginContainer/HBoxContainer/AlertContainer

var app_buttons: Dictionary = {}

const APP_COLORS = {
	"cipher":   Color("#cc2233"),
	"files":    Color("#ccaa22"),
	"browser":  Color("#3366cc"),
	"terminal": Color("#22cc66"),
}


func _ready():
	_apply_style()
	_setup_clock()
	alert_container.visible = false


func _apply_style():
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#0d0d11")
	style.border_color = Color("#1e1e28")
	style.border_width_top = 1
	add_theme_stylebox_override("panel", style)

	var logo = $MarginContainer/HBoxContainer/LogoLabel
	logo.add_theme_font_size_override("font_size", 11)
	logo.add_theme_color_override("font_color", Color("#5a5a6e"))

	clock_label.add_theme_font_size_override("font_size", 11)
	clock_label.add_theme_color_override("font_color", Color("#5a5a6e"))


func _setup_clock():
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_update_clock)
	add_child(timer)
	_update_clock()


func _update_clock():
	var t = Time.get_time_dict_from_system()
	clock_label.text = "%02d:%02d:%02d" % [t["hour"], t["minute"], t["second"]]


func add_app(app_id: String, label: String):
	if app_buttons.has(app_id):
		return

	var color = APP_COLORS.get(app_id, Color("#333344"))
	var btn = Button.new()
	btn.text = label
	btn.add_theme_font_size_override("font_size", 10)

	# Style bouton taskbar
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color.TRANSPARENT
	normal.border_color = color
	normal.border_color.a = 0.3
	normal.set_border_width_all(0)
	normal.border_width_bottom = 2

	var hover = StyleBoxFlat.new()
	hover.bg_color = color
	hover.bg_color.a = 0.1
	hover.border_color = color
	hover.border_color.a = 0.5
	hover.set_border_width_all(0)
	hover.border_width_bottom = 2

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", color)

	btn.pressed.connect(func(): app_focused.emit(app_id))
	# Stocke l'app_id dans le bouton pour pouvoir le retrouver
	btn.set_meta("app_id", app_id)
	open_apps.add_child(btn)
	app_buttons[app_id] = btn


func remove_app(app_id: String):
	if not app_buttons.has(app_id):
		return
	app_buttons[app_id].queue_free()
	app_buttons.erase(app_id)


func set_active(app_id: String):
	for id in app_buttons:
		var btn = app_buttons[id]
		var color = APP_COLORS.get(id, Color("#333344"))
		var style = StyleBoxFlat.new()
		style.bg_color = color if id == app_id else Color.TRANSPARENT
		style.bg_color.a = 0.15 if id == app_id else 0.0
		style.border_color = color
		style.border_color.a = 0.4 if id == app_id else 0.2
		style.set_border_width_all(1)
		style.border_width_bottom = 2
		btn.add_theme_stylebox_override("normal", style)


func show_alert(text: String, app_id: String):
	alert_container.visible = true
	# Vide les alertes précédentes
	for child in alert_container.get_children():
		child.queue_free()

	var lbl = Label.new()
	lbl.text = "⚠ " + text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color("#cc2233"))

	var style = StyleBoxFlat.new()
	style.bg_color = Color("#cc223308")
	style.border_color = Color("#661018")
	style.set_border_width_all(1)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2

	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(lbl)
	panel.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			app_focused.emit(app_id)
	)
	alert_container.add_child(panel)
