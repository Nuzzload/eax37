# browser_ui.gd
# Constructeur d'interface statique pour le navigateur EAX37.
# Chaque méthode construit une section et retourne un Dictionary de références.
class_name BrowserUI

const C_BG      = Color("#08080f")
const C_SURFACE = Color("#0e0e1a")
const C_BORDER  = Color("#1c1c2e")
const C_TOR     = Color("#7c3aed")
const C_TOR_DIM = Color("#2d1254")
const C_TEXT    = Color("#b0b0cc")
const C_TEXT_DIM = Color("#484866")
const C_LINK    = Color("#a855f7")


# Retourne {container, dot}
# Le tween de la dot est à créer côté appelant (create_tween nécessite un Node dans le tree).
static func build_tor_bar() -> Dictionary:
	var bar := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = C_TOR_DIM
	style.border_color = C_TOR
	style.border_width_bottom = 1
	style.set_content_margin(SIDE_LEFT,   10)
	style.set_content_margin(SIDE_RIGHT,  10)
	style.set_content_margin(SIDE_TOP,     4)
	style.set_content_margin(SIDE_BOTTOM,  4)
	bar.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	bar.add_child(hbox)

	var dot := ColorRect.new()
	dot.color = C_TOR
	dot.custom_minimum_size = Vector2(7, 7)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(dot)

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

	return { "container": bar, "dot": dot }


# Retourne {container, back_btn, fwd_btn, url_bar, home_btn, go_btn}
# Les connexions de signaux sont faites côté browser.gd.
static func build_nav_bar() -> Dictionary:
	var bar := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = C_SURFACE
	style.border_color = C_BORDER
	style.border_width_bottom = 1
	style.set_content_margin_all(6)
	bar.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	bar.add_child(hbox)

	var back_btn := make_nav_btn("◀")
	back_btn.disabled = true
	hbox.add_child(back_btn)

	var fwd_btn := make_nav_btn("▶")
	fwd_btn.disabled = true
	hbox.add_child(fwd_btn)

	var home_btn := make_nav_btn("⌂")
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

	var url_bar := LineEdit.new()
	url_bar.add_theme_color_override("font_color",  C_LINK)
	url_bar.add_theme_color_override("caret_color", C_TOR)
	url_bar.add_theme_font_size_override("font_size", 11)
	url_bar.add_theme_stylebox_override("normal",  StyleBoxEmpty.new())
	url_bar.add_theme_stylebox_override("focused", StyleBoxEmpty.new())
	url_bar.add_theme_stylebox_override("hover",   StyleBoxEmpty.new())
	url_wrap.add_child(url_bar)

	var go_btn := make_nav_btn("→")
	hbox.add_child(go_btn)

	return {
		"container": bar,
		"back_btn":  back_btn,
		"fwd_btn":   fwd_btn,
		"url_bar":   url_bar,
		"home_btn":  home_btn,
		"go_btn":    go_btn,
	}


# Retourne {scroll, content_label}
# Les connexions meta_hover_* et gui_input sont faites côté browser.gd.
static func build_content_area() -> Dictionary:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll_bg := StyleBoxFlat.new()
	scroll_bg.bg_color = C_BG
	scroll.add_theme_stylebox_override("panel", scroll_bg)

	var vsb := scroll.get_v_scroll_bar()
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
	scroll.add_child(margin)

	var label := RichTextLabel.new()
	label.bbcode_enabled  = true
	label.scroll_active   = false
	label.fit_content     = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter    = Control.MOUSE_FILTER_STOP
	label.meta_underlined = true
	label.add_theme_color_override("default_color",       Color("#b0b0cc"))
	label.add_theme_color_override("font_selected_color", Color("#e0e0f0"))
	label.add_theme_font_size_override("normal_font_size", 12)
	label.add_theme_constant_override("line_separation", 5)
	margin.add_child(label)

	return { "scroll": scroll, "content_label": label }


# Retourne {container, label}
static func build_status_bar() -> Dictionary:
	var bar := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = C_SURFACE
	style.border_color = C_BORDER
	style.border_width_top = 1
	style.set_content_margin(SIDE_LEFT,   10)
	style.set_content_margin(SIDE_RIGHT,  10)
	style.set_content_margin(SIDE_TOP,     3)
	style.set_content_margin(SIDE_BOTTOM,  3)
	bar.add_theme_stylebox_override("panel", style)

	var lbl := Label.new()
	lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.text = "Prêt"
	bar.add_child(lbl)

	return { "container": bar, "label": lbl }


static func make_nav_btn(label: String) -> Button:
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
	sh.bg_color    = C_TOR_DIM
	sh.border_color = C_TOR
	btn.add_theme_stylebox_override("normal",   s)
	btn.add_theme_stylebox_override("hover",    sh)
	btn.add_theme_stylebox_override("pressed",  sh)
	btn.add_theme_stylebox_override("disabled", s)
	btn.add_theme_color_override("font_color",          C_TEXT)
	btn.add_theme_color_override("font_disabled_color", C_TEXT_DIM)
	btn.add_theme_font_size_override("font_size", 10)
	return btn
