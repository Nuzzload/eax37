# desktop_icon.gd
# Attache à desktop_icon.tscn
# Structure :
#   PanelContainer (desktop_icon.gd)
#   └── HBoxContainer
#       ├── IconLabel (Label)       ← emoji icône
#       ├── VBoxContainer
#       │   ├── NameLabel (Label)
#       │   └── DescLabel (Label)
#       └── NotifDot (ColorRect)    ← point rouge notif
extends PanelContainer

signal double_clicked

@onready var icon_label: Label = $MarginContainer/HBoxContainer/IconLabel
@onready var name_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/NameLabel
@onready var desc_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/DescLabel
@onready var notif_dot: ColorRect = $MarginContainer/HBoxContainer/NotifDot

var app_id: String = ""
var accent_color: Color
var _click_time: float = 0.0
const DOUBLE_CLICK_DELAY = 0.4


func setup(data: Dictionary):
	app_id = data["id"]
	accent_color = Color(data["color"])
	icon_label.text = data["icon"]
	name_label.text = data["label"]
	desc_label.text = data["desc"]

	name_label.add_theme_color_override("font_color", Color("#e8e8f0"))
	name_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color("#5a5a6e"))
	desc_label.add_theme_font_size_override("font_size", 9)

	notif_dot.visible = false
	notif_dot.color = Color("#cc2233")
	notif_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	_apply_style(false)


func _apply_style(hovered: bool):
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#00000000") if not hovered else accent_color
	style.bg_color.a = 0.0 if not hovered else 0.07
	style.border_color = accent_color
	style.border_color.a = 0.0 if not hovered else 0.2
	style.set_border_width_all(1)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	add_theme_stylebox_override("panel", style)

	if hovered:
		name_label.add_theme_color_override("font_color", accent_color)
	else:
		name_label.add_theme_color_override("font_color", Color("#e8e8f0"))


func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		double_clicked.emit()
		get_viewport().set_input_as_handled()


func _on_mouse_entered():
	_apply_style(true)


func _on_mouse_exited():
	_apply_style(false)


func set_notification(count: int):
	notif_dot.visible = count > 0
