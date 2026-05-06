# files_explorer.gd
extends Control

@onready var path_label: Label = $VBoxContainer/Toolbar/PathLabel
@onready var back_btn: Button = $VBoxContainer/Toolbar/BackBtn
@onready var grid_container: GridContainer = $VBoxContainer/ScrollContainer/GridContainer

const C_BG       = Color("#050508")
const C_SURFACE  = Color("#111116")
const C_BORDER   = Color("#1e1e28")
const C_TEXT     = Color("#c8c8d4")
const C_TEXT_DIM = Color("#5a5a6e")
const C_YELLOW   = Color("#ccaa22")
const C_BLUE     = Color("#3366cc")
const C_GREEN    = Color("#22cc66")
const C_ACCENT   = Color("#cc2233")

var current_node
var path_stack: Array = []
var root_node

# Fenêtre de preview de fichier
var preview_window = null


func _ready():
	_apply_styles()
	back_btn.pressed.connect(_on_back_pressed)
	# Le filesystem est construit dans terminal._ready() via _build_filesystem()
	# On attend un frame pour être sûr qu'il soit prêt
	call_deferred("_deferred_init")


func _deferred_init():
	_find_filesystem()
	_update_view()


func _apply_styles():
	# Fond global
	var bg = StyleBoxFlat.new()
	bg.bg_color = C_BG
	add_theme_stylebox_override("panel", bg)

	# Toolbar
	var toolbar = $VBoxContainer/Toolbar
	var tb_style = StyleBoxFlat.new()
	tb_style.bg_color = Color("#0d0d11")
	tb_style.border_color = C_BORDER
	tb_style.border_width_bottom = 1
	tb_style.set_content_margin_all(6)
	toolbar.add_theme_stylebox_override("panel", tb_style)

	# Path label
	path_label.add_theme_color_override("font_color", C_TEXT_DIM)
	path_label.add_theme_font_size_override("font_size", 11)

	# Back button
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color.TRANSPARENT
	btn_style.border_color = C_BORDER
	btn_style.set_border_width_all(1)
	btn_style.set_content_margin_all(4)
	btn_style.corner_radius_top_left = 2
	btn_style.corner_radius_top_right = 2
	btn_style.corner_radius_bottom_left = 2
	btn_style.corner_radius_bottom_right = 2
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = C_SURFACE
	back_btn.add_theme_stylebox_override("normal", btn_style)
	back_btn.add_theme_stylebox_override("hover", btn_hover)
	back_btn.add_theme_stylebox_override("disabled", btn_style)
	back_btn.add_theme_color_override("font_color", C_TEXT_DIM)
	back_btn.add_theme_font_size_override("font_size", 11)

	# Grid
	grid_container.add_theme_constant_override("h_separation", 8)
	grid_container.add_theme_constant_override("v_separation", 8)
	grid_container.columns = 5


func _find_filesystem():
	# Utilise directement l'autoload FileSystem
	root_node = GameFS.get_root()
	current_node = GameFS.get_home()
	path_stack.clear()


func _update_view():
	for child in grid_container.get_children():
		child.queue_free()

	if not current_node:
		path_label.text = "~/  (filesystem introuvable)"
		return

	path_label.text = "  " + _get_path_string()
	back_btn.disabled = path_stack.is_empty()

	for node in current_node.get_visible_children():
		_create_icon(node)


func _get_path_string() -> String:
	if current_node == root_node:
		return "~/"
	var p = "~"
	for n in path_stack:
		if n != root_node:
			p += "/" + n.node_name
	p += "/" + current_node.node_name
	return p


func _create_icon(node):
	var is_folder: bool = node.is_folder
	var filename: String = node.node_name

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(80, 85)
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS

	# ── Icône dessinée en code ──
	var icon_container = Control.new()
	icon_container.custom_minimum_size = Vector2(48, 48)
	icon_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon_container)

	if is_folder:
		_draw_folder_icon(icon_container)
	else:
		_draw_file_icon(icon_container, filename)

	# ── Label ──
	var label = Label.new()
	label.text = filename
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", C_TEXT)
	vbox.add_child(label)

	grid_container.add_child(vbox)

	# ── Hover ──
	vbox.mouse_entered.connect(func():
		_set_icon_hover(icon_container, true, is_folder)
		label.add_theme_color_override("font_color", C_YELLOW if is_folder else Color.WHITE)
	)
	vbox.mouse_exited.connect(func():
		_set_icon_hover(icon_container, false, is_folder)
		label.add_theme_color_override("font_color", C_TEXT)
	)

	# ── Clic ──
	vbox.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_folder:
				path_stack.append(current_node)
				current_node = node
				_update_view()
			else:
				_open_file(node)
	)


func _draw_folder_icon(parent):
	# Tab du dossier
	var tab = ColorRect.new()
	tab.color = C_YELLOW
	tab.color.a = 0.8
	tab.size = Vector2(18, 6)
	tab.position = Vector2(4, 10)
	parent.add_child(tab)
	# Corps du dossier
	var body = ColorRect.new()
	body.color = C_YELLOW
	body.color.a = 0.7
	body.size = Vector2(40, 28)
	body.position = Vector2(4, 16)
	parent.add_child(body)
	# Reflet
	var shine = ColorRect.new()
	shine.color = Color(1, 1, 1, 0.08)
	shine.size = Vector2(40, 8)
	shine.position = Vector2(4, 16)
	parent.add_child(shine)
	parent.set_meta("type", "folder")


func _draw_file_icon(parent, filename: String):
	var ext = filename.get_extension().to_lower()
	var color: Color
	match ext:
		"txt", "sh": color = C_GREEN
		"pdf":       color = C_ACCENT
		"jpg", "png", "jpeg", "webp": color = C_BLUE
		"zip", "tar", "gz": color = Color("#cc6600")
		_:           color = C_TEXT_DIM

	# Corps du fichier
	var body = ColorRect.new()
	body.color = color
	body.color.a = 0.6
	body.size = Vector2(32, 40)
	body.position = Vector2(8, 4)
	parent.add_child(body)
	# Coin plié
	var corner = ColorRect.new()
	corner.color = color
	corner.color.a = 0.3
	corner.size = Vector2(10, 10)
	corner.position = Vector2(30, 4)
	parent.add_child(corner)
	# Lignes de texte simulées
	for i in range(3):
		var line = ColorRect.new()
		line.color = Color(1, 1, 1, 0.15)
		line.size = Vector2(20 - i * 4, 2)
		line.position = Vector2(12, 18 + i * 6)
		parent.add_child(line)
	parent.set_meta("type", "file")


func _set_icon_hover(parent, hovered: bool, is_folder: bool):
	# Légère surbrillance sur hover
	for child in parent.get_children():
		if child is ColorRect:
			child.color.a = child.color.a * (1.3 if hovered else 1.0 / 1.3)


func _on_back_pressed():
	if not path_stack.is_empty():
		current_node = path_stack.pop_back()
		_update_view()


func _open_file(node):
	if not node.has_method("get_content"):
		return

	var filename: String = node.get("filename") if node.get("filename") != null else node.node_name
	var content: String = node.get_content()

	# Ouvre une petite fenêtre de preview
	_show_preview(filename, content)


func _show_preview(filename: String, content: String):
	# Ferme l'ancienne preview si elle existe
	if preview_window and is_instance_valid(preview_window):
		preview_window.queue_free()

	var win = PanelContainer.new()
	win.size = Vector2(340, 260)
	win.position = Vector2(100, 80)
	win.z_index = 10

	var win_style = StyleBoxFlat.new()
	win_style.bg_color = C_SURFACE
	win_style.border_color = C_YELLOW
	win_style.border_color.a = 0.5
	win_style.set_border_width_all(1)
	win_style.shadow_color = Color(0, 0, 0, 0.5)
	win_style.shadow_size = 8
	win.add_theme_stylebox_override("panel", win_style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	win.add_child(vbox)

	# Titlebar
	var titlebar = HBoxContainer.new()
	var tb_style = StyleBoxFlat.new()
	tb_style.bg_color = Color("#0d0d11")
	tb_style.border_color = C_YELLOW
	tb_style.border_color.a = 0.3
	tb_style.border_width_bottom = 1
	tb_style.set_content_margin(SIDE_LEFT, 10)
	tb_style.set_content_margin(SIDE_RIGHT, 6)
	tb_style.set_content_margin(SIDE_TOP, 4)
	tb_style.set_content_margin(SIDE_BOTTOM, 4)
	titlebar.add_theme_stylebox_override("panel", tb_style)

	var title_lbl = Label.new()
	title_lbl.text = filename
	title_lbl.add_theme_font_size_override("font_size", 10)
	title_lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titlebar.add_child(title_lbl)

	# Bouton Copier
	var copy_btn = Button.new()
	copy_btn.text = "COPIER"
	copy_btn.add_theme_font_size_override("font_size", 9)
	copy_btn.add_theme_color_override("font_color", C_YELLOW)
	var copy_style = StyleBoxFlat.new()
	copy_style.bg_color = Color(C_YELLOW.r, C_YELLOW.g, C_YELLOW.b, 0.1)
	copy_style.border_color = C_YELLOW
	copy_style.border_color.a = 0.3
	copy_style.set_border_width_all(1)
	copy_style.set_content_margin(SIDE_LEFT, 6)
	copy_style.set_content_margin(SIDE_RIGHT, 6)
	copy_style.set_content_margin(SIDE_TOP, 2)
	copy_style.set_content_margin(SIDE_BOTTOM, 2)
	copy_style.corner_radius_top_left = 2
	copy_style.corner_radius_top_right = 2
	copy_style.corner_radius_bottom_left = 2
	copy_style.corner_radius_bottom_right = 2
	var copy_hover = copy_style.duplicate()
	copy_hover.bg_color = Color(C_YELLOW.r, C_YELLOW.g, C_YELLOW.b, 0.25)
	copy_btn.add_theme_stylebox_override("normal", copy_style)
	copy_btn.add_theme_stylebox_override("hover", copy_hover)
	copy_btn.pressed.connect(func():
		DisplayServer.clipboard_set(content)
		copy_btn.text = "COPIÉ ✓"
		copy_btn.add_theme_color_override("font_color", C_GREEN)
		await get_tree().create_timer(1.5).timeout
		if is_instance_valid(copy_btn):
			copy_btn.text = "COPIER"
			copy_btn.add_theme_color_override("font_color", C_YELLOW)
	)
	titlebar.add_child(copy_btn)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.add_theme_font_size_override("font_size", 10)
	close_btn.add_theme_color_override("font_color", C_ACCENT)
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color.TRANSPARENT
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_stylebox_override("hover", close_style)
	close_btn.pressed.connect(func(): win.queue_free())
	titlebar.add_child(close_btn)
	vbox.add_child(titlebar)

	# Contenu
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	var content_lbl = Label.new()
	content_lbl.text = content if content != "" else "[Fichier vide]"
	content_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_lbl.custom_minimum_size = Vector2(280, 0)
	content_lbl.add_theme_font_size_override("font_size", 11)
	var is_sensitive = "⚠" in content or "NE PAS PARTAGER" in content or "password" in filename.to_lower()
	content_lbl.add_theme_color_override("font_color", C_ACCENT if is_sensitive else C_TEXT)
	margin.add_child(content_lbl)
	scroll.add_child(margin)
	vbox.add_child(scroll)

	# Drag simple sur la titlebar
	var dragging := false
	var drag_offset := Vector2.ZERO
	titlebar.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			drag_offset = get_global_mouse_position() - win.global_position
		if event is InputEventMouseMotion and dragging:
			win.position = get_global_mouse_position() - drag_offset
	)

	get_parent().add_child(win)
	preview_window = win
