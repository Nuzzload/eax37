# settings_panel.gd
# Panneau de paramètres — s'affiche par-dessus le menu principal.
# Émet back_pressed quand l'utilisateur veut revenir.
class_name SettingsPanel
extends Control

signal back_pressed

# ── COULEURS ──────────────────────────────────────
const C_BG         = Color("#0a0a14")
const C_PANEL      = Color("#0e0e1a")
const C_BORDER     = Color("#1c1c2e")
const C_ACCENT     = Color("#7c3aed")
const C_ACCENT_DIM = Color("#2d1254")
const C_TEXT       = Color("#b0b0cc")
const C_TEXT_DIM   = Color("#484866")
const C_BRIGHT     = Color("#e0e0f0")

# ── NŒUDS ─────────────────────────────────────────
var _music_slider: HSlider
var _sfx_slider:   HSlider
var _display_opt:  OptionButton
var _lang_opt:     OptionButton


func _ready() -> void:
	_build()


# ═══════════════════════════════════════════════════
# CONSTRUCTION
# ═══════════════════════════════════════════════════
func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := _make_card()
	center.add_child(card)


func _make_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(480, 0)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = C_PANEL
	card_style.border_color = C_ACCENT
	card_style.set_border_width_all(1)
	card_style.set_content_margin_all(32)
	card_style.corner_radius_top_left     = 4
	card_style.corner_radius_top_right    = 4
	card_style.corner_radius_bottom_left  = 4
	card_style.corner_radius_bottom_right = 4
	card_style.shadow_color = Color(0, 0, 0, 0.5)
	card_style.shadow_size  = 16
	card_style.shadow_offset = Vector2(0, 6)
	card.add_theme_stylebox_override("panel", card_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)

	# ── Titre ──
	var title := Label.new()
	title.text = "PARAMÈTRES"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", C_BRIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(_make_separator())

	# ── AUDIO ──
	vbox.add_child(_make_section_header("AUDIO"))
	vbox.add_child(_make_slider_row("MUSIQUE",   0, 100, 80,  func(v): _on_music_changed(v)))
	vbox.add_child(_make_slider_row("EFFETS",    0, 100, 100, func(v): _on_sfx_changed(v)))

	vbox.add_child(_make_separator())

	# ── AFFICHAGE ──
	vbox.add_child(_make_section_header("AFFICHAGE"))
	vbox.add_child(_make_display_row())

	vbox.add_child(_make_separator())

	# ── SYSTÈME ──
	vbox.add_child(_make_section_header("SYSTÈME"))
	vbox.add_child(_make_lang_row())

	vbox.add_child(_make_separator())

	var back_btn := _make_button("← RETOUR")
	back_btn.pressed.connect(_on_back_pressed)
	vbox.add_child(back_btn)

	return card


func _make_section_header(text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var accent := ColorRect.new()
	accent.color = C_ACCENT
	accent.custom_minimum_size = Vector2(3, 14)
	accent.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(accent)

	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", C_ACCENT)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)

	return row


func _make_separator() -> HSeparator:
	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = C_BORDER
	sep_style.content_margin_top    = 0.0
	sep_style.content_margin_bottom = 0.0
	sep.add_theme_stylebox_override("separator", sep_style)
	return sep


func _make_slider_row(label_text: String, min_v: float, max_v: float, default_v: float, on_change: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 80
	lbl.add_theme_color_override("font_color", C_TEXT)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.value     = default_v
	slider.step      = 1.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_slider_style(slider)
	slider.value_changed.connect(on_change)
	row.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.text = str(int(default_v))
	val_lbl.custom_minimum_size.x = 32
	val_lbl.add_theme_color_override("font_color", C_ACCENT)
	val_lbl.add_theme_font_size_override("font_size", 11)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	row.add_child(val_lbl)

	slider.value_changed.connect(func(v: float) -> void: val_lbl.text = str(int(v)))

	if label_text == "MUSIQUE":
		_music_slider = slider
	else:
		_sfx_slider = slider

	return row


func _make_display_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var lbl := Label.new()
	lbl.text = "MODE"
	lbl.custom_minimum_size.x = 80
	lbl.add_theme_color_override("font_color", C_TEXT)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)

	_display_opt = OptionButton.new()
	_display_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_display_opt.add_item("Fenêtré")
	_display_opt.add_item("Plein écran")
	_display_opt.add_item("Fenêtré sans bordure")
	_apply_option_style(_display_opt)
	_display_opt.item_selected.connect(_on_display_changed)
	row.add_child(_display_opt)

	return row


func _make_lang_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var lbl := Label.new()
	lbl.text = "LANGUE"
	lbl.custom_minimum_size.x = 80
	lbl.add_theme_color_override("font_color", C_TEXT)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)

	_lang_opt = OptionButton.new()
	_lang_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lang_opt.add_item("Français")
	_lang_opt.add_item("English")
	_lang_opt.add_item("Español")
	_lang_opt.add_item("Deutsch")
	_apply_option_style(_lang_opt)
	_lang_opt.item_selected.connect(_on_lang_changed)
	row.add_child(_lang_opt)

	return row


func _make_button(label_text: String) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(0, 38)
	btn.add_theme_font_size_override("font_size", 11)

	var s_normal := StyleBoxFlat.new()
	s_normal.bg_color = C_ACCENT_DIM
	s_normal.border_color = C_ACCENT
	s_normal.border_width_left   = 3
	s_normal.border_width_top    = 0
	s_normal.border_width_right  = 0
	s_normal.border_width_bottom = 0
	s_normal.set_content_margin_all(8)
	s_normal.corner_radius_top_left     = 2
	s_normal.corner_radius_top_right    = 2
	s_normal.corner_radius_bottom_left  = 2
	s_normal.corner_radius_bottom_right = 2

	var s_hover := s_normal.duplicate() as StyleBoxFlat
	s_hover.bg_color = C_ACCENT

	btn.add_theme_stylebox_override("normal",  s_normal)
	btn.add_theme_stylebox_override("hover",   s_hover)
	btn.add_theme_stylebox_override("pressed", s_hover)
	btn.add_theme_color_override("font_color",         C_BRIGHT)
	btn.add_theme_color_override("font_hover_color",   C_BRIGHT)
	btn.add_theme_color_override("font_pressed_color", C_BRIGHT)
	return btn


# ── STYLES WIDGETS ────────────────────────────────

func _apply_slider_style(slider: HSlider) -> void:
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = C_ACCENT
	grabber.set_border_width_all(0)
	grabber.corner_radius_top_left     = 10
	grabber.corner_radius_top_right    = 10
	grabber.corner_radius_bottom_left  = 10
	grabber.corner_radius_bottom_right = 10
	grabber.set_content_margin_all(6)

	var grabber_hl := grabber.duplicate() as StyleBoxFlat
	grabber_hl.bg_color = Color("#9d5ff8")

	var slider_bg := StyleBoxFlat.new()
	slider_bg.bg_color = C_BORDER
	slider_bg.set_content_margin(SIDE_TOP,    3)
	slider_bg.set_content_margin(SIDE_BOTTOM, 3)
	slider_bg.corner_radius_top_left     = 3
	slider_bg.corner_radius_top_right    = 3
	slider_bg.corner_radius_bottom_left  = 3
	slider_bg.corner_radius_bottom_right = 3

	var fill := slider_bg.duplicate() as StyleBoxFlat
	fill.bg_color = C_ACCENT_DIM

	slider.add_theme_stylebox_override("grabber_area",           fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	slider.add_theme_stylebox_override("slider",                 slider_bg)
	slider.add_theme_stylebox_override("grabber",                grabber)
	slider.add_theme_stylebox_override("grabber_highlight",      grabber_hl)
	slider.custom_minimum_size.y = 20


func _apply_option_style(opt: OptionButton) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#0e0e1a")
	s.border_color = C_BORDER
	s.set_border_width_all(1)
	s.set_content_margin(SIDE_LEFT,   10)
	s.set_content_margin(SIDE_RIGHT,  10)
	s.set_content_margin(SIDE_TOP,     6)
	s.set_content_margin(SIDE_BOTTOM,  6)
	s.corner_radius_top_left     = 2
	s.corner_radius_top_right    = 2
	s.corner_radius_bottom_left  = 2
	s.corner_radius_bottom_right = 2

	var sh := s.duplicate() as StyleBoxFlat
	sh.border_color = C_ACCENT

	opt.add_theme_stylebox_override("normal", s)
	opt.add_theme_stylebox_override("hover",  sh)
	opt.add_theme_stylebox_override("focus",  sh)
	opt.add_theme_color_override("font_color",       C_TEXT)
	opt.add_theme_color_override("font_hover_color", C_BRIGHT)
	opt.add_theme_font_size_override("font_size", 11)


# ═══════════════════════════════════════════════════
# HANDLERS
# ═══════════════════════════════════════════════════
func _on_music_changed(value: float) -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_volume_linear(idx, value / 100.0)


func _on_sfx_changed(value: float) -> void:
	var idx := AudioServer.get_bus_index("Master")
	if idx >= 0:
		AudioServer.set_bus_volume_linear(idx, value / 100.0)


func _on_display_changed(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)


func _on_lang_changed(index: int) -> void:
	var locales := ["fr", "en", "es", "de"]
	if index < locales.size():
		TranslationServer.set_locale(locales[index])


func _on_back_pressed() -> void:
	back_pressed.emit()
