# window.gd
extends PanelContainer

signal close_requested
signal focus_requested

@onready var title_bar: PanelContainer = $VBoxContainer/TitleBar
@onready var title_label: Label = $VBoxContainer/TitleBar/HBoxContainer/TitleLabel
@onready var dot_accent: ColorRect = $VBoxContainer/TitleBar/HBoxContainer/DotAccent
@onready var close_btn: Button = $VBoxContainer/TitleBar/HBoxContainer/Buttons/CloseBtn
@onready var minimize_btn: Button = $VBoxContainer/TitleBar/HBoxContainer/Buttons/MinimizeBtn
@onready var content_container: MarginContainer = $VBoxContainer/ContentContainer

var app_id: String = ""
var accent_color: Color = Color("#333344")
var is_dragging: bool = false
var drag_start_mouse: Vector2 = Vector2.ZERO
var drag_start_pos: Vector2 = Vector2.ZERO
var is_minimized: bool = false
const TITLEBAR_HEIGHT = 32


func _ready():
	# Pivot au centre pour les animations de scale
	pivot_offset = size / 2
	scale = Vector2.ONE * 0.95
	modulate.a = 0.0
	
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.3)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.2)


func setup(p_app_id: String, p_title: String, p_color: Color, app_scene: PackedScene):
	app_id = p_app_id
	accent_color = p_color
	title_label.text = p_title
	dot_accent.color = p_color
	_apply_style()
	if app_scene:
		var app_instance = app_scene.instantiate()
		content_container.add_child.call_deferred(app_instance)
	close_btn.pressed.connect(func(): close_window())
	minimize_btn.pressed.connect(_toggle_minimize)


func close_window():
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	tween.parallel().tween_property(self, "scale", Vector2.ONE * 0.9, 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func(): close_requested.emit())


func _toggle_minimize():
	is_minimized = !is_minimized
	if is_minimized:
		var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
		tween.parallel().tween_property(self, "scale", Vector2.ONE * 0.8, 0.2)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): visible = false)
	else:
		visible = true
		scale = Vector2.ONE * 0.8
		modulate.a = 0.0
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.25)
		tween.parallel().tween_property(self, "modulate:a", 1.0, 0.2)


func restore():
	if is_minimized:
		_toggle_minimize()


# Drag géré manuellement depuis room_scene via ces fonctions
func handle_cursor_press(cursor_pos: Vector2, pressed: bool):
	var local = cursor_pos - position
	if pressed:
		focus_requested.emit()
		
		# Vérifie si on a cliqué sur un bouton de la barre de titre
		# On utilise des marges basées sur la taille actuelle pour être plus flexible
		if local.y >= 0 and local.y <= TITLEBAR_HEIGHT:
			if local.x >= size.x - 30: # Bouton Close (approximatif)
				close_requested.emit()
				return
			if local.x >= size.x - 55: # Bouton Minimize (approximatif)
				_toggle_minimize()
				return
			
			on_drag_start(cursor_pos)
	else:
		on_drag_end()


func on_drag_start(cursor_pos: Vector2):
	is_dragging = true
	drag_start_mouse = cursor_pos
	drag_start_pos = position


func handle_cursor_move(cursor_pos: Vector2):
	on_drag_move(cursor_pos)

func on_drag_move(cursor_pos: Vector2):
	if not is_dragging:
		return
	var delta = cursor_pos - drag_start_mouse
	var new_pos = drag_start_pos + delta
	var parent_size = get_parent().size
	new_pos.x = clamp(new_pos.x, 0, parent_size.x - size.x)
	new_pos.y = clamp(new_pos.y, 0, parent_size.y - size.y)
	position = new_pos


func on_drag_end():
	is_dragging = false


func is_cursor_on_titlebar(cursor_pos: Vector2) -> bool:
	var local = cursor_pos - position
	return Rect2(Vector2.ZERO, Vector2(size.x, TITLEBAR_HEIGHT)).has_point(local)


func is_cursor_on_window(cursor_pos: Vector2) -> bool:
	return Rect2(position, size).has_point(cursor_pos)


func _apply_style():
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#111116")
	style.border_color = accent_color
	style.border_color.a = 0.25
	style.set_border_width_all(1)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 8
	add_theme_stylebox_override("panel", style)

	var tb_style = StyleBoxFlat.new()
	tb_style.bg_color = Color("#0d0d11")
	tb_style.border_color = accent_color
	tb_style.border_color.a = 0.2
	tb_style.set_border_width_all(0)
	tb_style.border_width_bottom = 1
	title_bar.add_theme_stylebox_override("panel", tb_style)

	_style_btn(close_btn, Color("#cc2233"))
	_style_btn(minimize_btn, Color("#ccaa22"))
	title_label.add_theme_color_override("font_color", Color("#5a5a6e"))
	title_label.add_theme_font_size_override("font_size", 11)


func _style_btn(btn: Button, color: Color):
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color.TRANSPARENT
	normal.set_border_width_all(1)
	normal.border_color = color
	normal.border_color.a = 0.3
	normal.corner_radius_top_left = 1
	normal.corner_radius_top_right = 1
	normal.corner_radius_bottom_left = 1
	normal.corner_radius_bottom_right = 1

	var hover = StyleBoxFlat.new()
	hover.bg_color = color
	hover.bg_color.a = 0.15
	hover.set_border_width_all(1)
	hover.border_color = color
	hover.border_color.a = 0.6
	hover.corner_radius_top_left = 1
	hover.corner_radius_top_right = 1
	hover.corner_radius_bottom_left = 1
	hover.corner_radius_bottom_right = 1

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_color", Color("#5a5a6e"))
	btn.add_theme_color_override("font_hover_color", color)
	btn.add_theme_font_size_override("font_size", 10)
