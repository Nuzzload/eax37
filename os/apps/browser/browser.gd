# browser.gd
# Navigateur darknet simulé — EAX37
# UI, navigation et gestion des événements.
# Le contenu des pages est dans browser_pages.gd (BrowserPages).
extends PanelContainer

# ── COULEURS UI ───────────────────────────────────
const C_BG       = Color("#08080f")
const C_SURFACE  = Color("#0e0e1a")
const C_BORDER   = Color("#1c1c2e")
const C_TOR      = Color("#7c3aed")
const C_TOR_DIM  = Color("#2d1254")
const C_TEXT     = Color("#b0b0cc")
const C_TEXT_DIM = Color("#484866")
const C_LINK     = Color("#a855f7")

# ── ÉTAT ──────────────────────────────────────────
var nav_history: Array[String] = []
var nav_index: int = -1
var _hovered_url: String = ""

# ── NŒUDS UI ──────────────────────────────────────
var url_bar: LineEdit
var content_label: RichTextLabel
var status_lbl: Label
var back_btn: Button
var fwd_btn: Button
var scroll_container: ScrollContainer


func _ready() -> void:
	_apply_styles()
	_build_ui()
	_go(BrowserPages.HOME)


# ═══════════════════════════════════════════════════
# CONSTRUCTION UI
# ═══════════════════════════════════════════════════
func _build_ui() -> void:
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)

	root_vbox.add_child(_build_tor_bar())
	root_vbox.add_child(_build_nav_bar())
	root_vbox.add_child(_build_content_area())
	root_vbox.add_child(_build_status_bar())


func _build_tor_bar() -> PanelContainer:
	var tor_bar := PanelContainer.new()
	var tor_style := StyleBoxFlat.new()
	tor_style.bg_color = C_TOR_DIM
	tor_style.border_color = C_TOR
	tor_style.border_width_bottom = 1
	tor_style.set_content_margin(SIDE_LEFT,   10)
	tor_style.set_content_margin(SIDE_RIGHT,  10)
	tor_style.set_content_margin(SIDE_TOP,     4)
	tor_style.set_content_margin(SIDE_BOTTOM,  4)
	tor_bar.add_theme_stylebox_override("panel", tor_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	tor_bar.add_child(hbox)

	var dot := ColorRect.new()
	dot.color = C_TOR
	dot.custom_minimum_size = Vector2(7, 7)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(dot)
	var tween := create_tween().set_loops()
	tween.tween_property(dot, "color:a", 0.2, 1.2)
	tween.tween_property(dot, "color:a", 1.0, 1.2)

	var tor_lbl := Label.new()
	tor_lbl.text = "TOR"
	tor_lbl.add_theme_color_override("font_color", C_TOR)
	tor_lbl.add_theme_font_size_override("font_size", 9)
	hbox.add_child(tor_lbl)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(6, 0)
	hbox.add_child(spacer)

	var enc_lbl := Label.new()
	enc_lbl.text = "CHIFFRÉ · ANONYME · RÉSEAU OIGNON"
	enc_lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	enc_lbl.add_theme_font_size_override("font_size", 9)
	enc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(enc_lbl)

	var node_lbl := Label.new()
	node_lbl.text = "Nœud : NL-AMS-7"
	node_lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	node_lbl.add_theme_font_size_override("font_size", 9)
	hbox.add_child(node_lbl)

	return tor_bar


func _build_nav_bar() -> PanelContainer:
	var nav_bar := PanelContainer.new()
	var nav_style := StyleBoxFlat.new()
	nav_style.bg_color = C_SURFACE
	nav_style.border_color = C_BORDER
	nav_style.border_width_bottom = 1
	nav_style.set_content_margin_all(6)
	nav_bar.add_theme_stylebox_override("panel", nav_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	nav_bar.add_child(hbox)

	back_btn = _make_nav_btn("◀")
	back_btn.pressed.connect(_go_back)
	back_btn.disabled = true
	hbox.add_child(back_btn)

	fwd_btn = _make_nav_btn("▶")
	fwd_btn.pressed.connect(_go_forward)
	fwd_btn.disabled = true
	hbox.add_child(fwd_btn)

	var home_btn := _make_nav_btn("⌂")
	home_btn.pressed.connect(func() -> void: _go(BrowserPages.HOME))
	hbox.add_child(home_btn)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(2, 0)
	hbox.add_child(sep)

	var url_wrap := PanelContainer.new()
	url_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var url_style := StyleBoxFlat.new()
	url_style.bg_color = Color("#060610")
	url_style.border_color = C_TOR
	url_style.border_color.a = 0.5
	url_style.set_border_width_all(1)
	url_style.set_content_margin(SIDE_LEFT,   8)
	url_style.set_content_margin(SIDE_RIGHT,  8)
	url_style.set_content_margin(SIDE_TOP,    5)
	url_style.set_content_margin(SIDE_BOTTOM, 5)
	url_style.corner_radius_top_left     = 3
	url_style.corner_radius_top_right    = 3
	url_style.corner_radius_bottom_left  = 3
	url_style.corner_radius_bottom_right = 3
	url_wrap.add_theme_stylebox_override("panel", url_style)
	hbox.add_child(url_wrap)

	url_bar = LineEdit.new()
	url_bar.add_theme_color_override("font_color", C_LINK)
	url_bar.add_theme_color_override("caret_color", C_TOR)
	url_bar.add_theme_font_size_override("font_size", 11)
	url_bar.add_theme_stylebox_override("normal",  StyleBoxEmpty.new())
	url_bar.add_theme_stylebox_override("focused", StyleBoxEmpty.new())
	url_bar.add_theme_stylebox_override("hover",   StyleBoxEmpty.new())
	url_bar.text_submitted.connect(_on_url_submitted)
	url_wrap.add_child(url_bar)

	var go_btn := _make_nav_btn("→")
	go_btn.pressed.connect(func() -> void: _on_url_submitted(url_bar.text))
	hbox.add_child(go_btn)

	return nav_bar


func _build_content_area() -> ScrollContainer:
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll_bg := StyleBoxFlat.new()
	scroll_bg.bg_color = C_BG
	scroll_container.add_theme_stylebox_override("panel", scroll_bg)

	var vsb := scroll_container.get_v_scroll_bar()
	var vsb_style := StyleBoxFlat.new()
	vsb_style.bg_color = C_BORDER
	vsb.add_theme_stylebox_override("scroll", vsb_style)
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = C_TOR_DIM
	vsb.add_theme_stylebox_override("grabber", grabber)
	vsb.custom_minimum_size.x = 4

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left",   16)
	margin.add_theme_constant_override("margin_right",  16)
	margin.add_theme_constant_override("margin_top",    12)
	margin.add_theme_constant_override("margin_bottom", 12)
	scroll_container.add_child(margin)

	content_label = RichTextLabel.new()
	content_label.bbcode_enabled  = true
	content_label.scroll_active   = false
	content_label.fit_content     = true
	content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_label.mouse_filter    = Control.MOUSE_FILTER_STOP
	content_label.meta_underlined = true
	content_label.add_theme_color_override("default_color",      Color("#b0b0cc"))
	content_label.add_theme_color_override("font_selected_color", Color("#e0e0f0"))
	content_label.add_theme_font_size_override("normal_font_size", 12)
	content_label.add_theme_constant_override("line_separation", 5)

	# Hover : mémorise l'URL survolée (fonctionne avec un seul event motion)
	content_label.meta_hover_started.connect(func(m: Variant) -> void:
		_hovered_url = str(m)
		status_lbl.text = _hovered_url
	)
	content_label.meta_hover_ended.connect(func(_m: Variant) -> void:
		_hovered_url = ""
		status_lbl.text = url_bar.text
	)

	# Clic : utilise _hovered_url au lieu de meta_clicked (plus fiable avec curseur virtuel)
	content_label.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				if not _hovered_url.is_empty():
					_on_link_clicked(_hovered_url)
					content_label.accept_event()
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				scroll_container.scroll_vertical -= 60
				content_label.accept_event()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				scroll_container.scroll_vertical += 60
				content_label.accept_event()
	)

	margin.add_child(content_label)
	return scroll_container


func _build_status_bar() -> PanelContainer:
	var status_bar := PanelContainer.new()
	var status_style := StyleBoxFlat.new()
	status_style.bg_color = C_SURFACE
	status_style.border_color = C_BORDER
	status_style.border_width_top = 1
	status_style.set_content_margin(SIDE_LEFT,   10)
	status_style.set_content_margin(SIDE_RIGHT,  10)
	status_style.set_content_margin(SIDE_TOP,     3)
	status_style.set_content_margin(SIDE_BOTTOM,  3)
	status_bar.add_theme_stylebox_override("panel", status_style)

	status_lbl = Label.new()
	status_lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	status_lbl.add_theme_font_size_override("font_size", 9)
	status_lbl.text = "Prêt"
	status_bar.add_child(status_lbl)

	return status_bar


func _make_nav_btn(label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(28, 28)
	var s := StyleBoxFlat.new()
	s.bg_color = C_SURFACE
	s.border_color = C_BORDER
	s.set_border_width_all(1)
	s.corner_radius_top_left     = 3
	s.corner_radius_top_right    = 3
	s.corner_radius_bottom_left  = 3
	s.corner_radius_bottom_right = 3
	var sh := s.duplicate() as StyleBoxFlat
	sh.bg_color = C_TOR_DIM
	sh.border_color = C_TOR
	btn.add_theme_stylebox_override("normal",   s)
	btn.add_theme_stylebox_override("hover",    sh)
	btn.add_theme_stylebox_override("pressed",  sh)
	btn.add_theme_stylebox_override("disabled", s)
	btn.add_theme_color_override("font_color",          C_TEXT)
	btn.add_theme_color_override("font_disabled_color", C_TEXT_DIM)
	btn.add_theme_font_size_override("font_size", 10)
	return btn


# ═══════════════════════════════════════════════════
# SCROLL MOLETTE (zone hors label)
# ═══════════════════════════════════════════════════
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_container.scroll_vertical -= 60
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_container.scroll_vertical += 60
			get_viewport().set_input_as_handled()


# ═══════════════════════════════════════════════════
# NAVIGATION
# ═══════════════════════════════════════════════════
func _go(url: String) -> void:
	var u := url.strip_edges()
	if u.begins_with("http://"):
		u = u.substr(7)
	elif u.begins_with("https://"):
		u = u.substr(8)

	if nav_index < nav_history.size() - 1:
		nav_history = nav_history.slice(0, nav_index + 1)
	nav_history.append(u)
	nav_index = nav_history.size() - 1
	_render(u)


func _go_back() -> void:
	if nav_index > 0:
		nav_index -= 1
		_render(nav_history[nav_index])


func _go_forward() -> void:
	if nav_index < nav_history.size() - 1:
		nav_index += 1
		_render(nav_history[nav_index])


func _on_url_submitted(url: String) -> void:
	if not url.is_empty():
		_go(url)


func _on_link_clicked(meta: Variant) -> void:
	var url := str(meta)
	if url.begins_with("/"):
		_go(BrowserPages.HOME + url)
	else:
		_go(url)


func _render(url: String) -> void:
	url_bar.text = url
	status_lbl.text = "Connexion à %s..." % url
	back_btn.disabled = nav_index <= 0
	fwd_btn.disabled  = nav_index >= nav_history.size() - 1
	content_label.clear()
	content_label.append_text(BrowserPages.get_page(url))
	scroll_container.scroll_vertical = 0
	status_lbl.text = url


# ═══════════════════════════════════════════════════
# STYLES
# ═══════════════════════════════════════════════════
func _apply_styles() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = C_BG
	add_theme_stylebox_override("panel", bg)
	mouse_filter = Control.MOUSE_FILTER_STOP
