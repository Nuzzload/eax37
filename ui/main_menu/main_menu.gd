# main_menu.gd
# Menu principal d'EAX37.
# Gère la navigation entre le panneau principal et le panneau de paramètres,
# ainsi que les transitions (fade).
extends Control

# ── COULEURS ──────────────────────────────────────
const C_BG         = Color("#0a0a14")
const C_PANEL      = Color("#0e0e1a")
const C_BORDER     = Color("#1c1c2e")
const C_ACCENT     = Color("#7c3aed")
const C_ACCENT_DIM = Color("#2d1254")
const C_TEXT       = Color("#b0b0cc")
const C_TEXT_DIM   = Color("#484866")
const C_BRIGHT     = Color("#e0e0f0")
const C_GREEN      = Color("#22c55e")
const C_WARN       = Color("#ef4444")

# Chemin de la scène de jeu à charger (à adapter)
const GAME_SCENE := "res://room.tscn"

# ── NŒUDS ─────────────────────────────────────────
var _main_panel:    Control
var _settings_panel: SettingsPanel
var _continue_btn:  Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_main_panel()
	_build_settings_panel()
	_fade_in(_main_panel)


# ═══════════════════════════════════════════════════
# CONSTRUCTION — FOND
# ═══════════════════════════════════════════════════
func _build_background() -> void:
	# Fond uni
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Grille subtile (lignes horizontales)
	for i in range(0, 40):
		var line := ColorRect.new()
		line.set_anchors_preset(Control.PRESET_TOP_WIDE)
		line.custom_minimum_size = Vector2(0, 1)
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.color = Color(1, 1, 1, 0.015)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.position.y = i * 30.0
		bg.add_child(line)

	# Lueur centrale violette
	var glow := ColorRect.new()
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.color = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.04)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)


# ═══════════════════════════════════════════════════
# CONSTRUCTION — PANNEAU PRINCIPAL
# ═══════════════════════════════════════════════════
func _build_main_panel() -> void:
	_main_panel = Control.new()
	_main_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_main_panel.modulate.a = 0.0  # caché au départ, fade-in dans _ready
	add_child(_main_panel)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_main_panel.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	vbox.custom_minimum_size.x = 320
	center.add_child(vbox)

	# ── En-tête ──
	vbox.add_child(_make_title_block())
	vbox.add_child(_make_spacer(24))

	# ── Carte des boutons ──
	var card := _make_button_card()
	vbox.add_child(card)

	# ── Pied de page ──
	vbox.add_child(_make_spacer(16))
	vbox.add_child(_make_footer())


func _make_title_block() -> VBoxContainer:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 4)

	var title := Label.new()
	title.text = "EAX37"
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", C_BRIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	block.add_child(title)

	var sub := Label.new()
	sub.text = "SYSTÈME EN LIGNE"
	sub.add_theme_font_size_override("font_size", 10)
	sub.add_theme_color_override("font_color", C_ACCENT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	block.add_child(sub)

	# Indicateur de statut
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 6)
	status_row.alignment = BoxContainer.ALIGNMENT_CENTER
	block.add_child(status_row)

	var dot := ColorRect.new()
	dot.color = C_GREEN
	dot.custom_minimum_size = Vector2(6, 6)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	status_row.add_child(dot)
	var tween := create_tween().set_loops()
	tween.tween_property(dot, "color:a", 0.2, 1.0)
	tween.tween_property(dot, "color:a", 1.0, 1.0)

	var status_lbl := Label.new()
	status_lbl.text = "TOR ACTIF · NL-AMS-7"
	status_lbl.add_theme_font_size_override("font_size", 9)
	status_lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	status_row.add_child(status_lbl)

	return block


func _make_button_card() -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = C_PANEL
	style.border_color = C_BORDER
	style.set_border_width_all(1)
	style.set_content_margin(SIDE_LEFT,   28)
	style.set_content_margin(SIDE_RIGHT,  28)
	style.set_content_margin(SIDE_TOP,    24)
	style.set_content_margin(SIDE_BOTTOM, 24)
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color  = Color(0, 0, 0, 0.4)
	style.shadow_size   = 16
	style.shadow_offset = Vector2(0, 6)
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	# Bouton Continuer (désactivé)
	_continue_btn = _make_menu_btn("CONTINUER", C_TEXT_DIM, C_BORDER)
	_continue_btn.disabled = true
	vbox.add_child(_continue_btn)

	vbox.add_child(_make_thin_sep())

	# Bouton Nouvelle partie
	var new_btn := _make_menu_btn("NOUVELLE PARTIE", C_GREEN, Color("#14532d"))
	new_btn.pressed.connect(_on_new_game_pressed)
	vbox.add_child(new_btn)

	# Bouton Paramètres
	var settings_btn := _make_menu_btn("PARAMÈTRES", C_ACCENT, C_ACCENT_DIM)
	settings_btn.pressed.connect(_on_settings_pressed)
	vbox.add_child(settings_btn)

	vbox.add_child(_make_thin_sep())

	# Bouton Quitter
	var quit_btn := _make_menu_btn("QUITTER", C_WARN, Color("#4c0519"))
	quit_btn.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_btn)

	return card


func _make_footer() -> Label:
	var lbl := Label.new()
	lbl.text = "v0.1.0 · 2026"
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl


# ═══════════════════════════════════════════════════
# CONSTRUCTION — PANNEAU PARAMÈTRES
# ═══════════════════════════════════════════════════
func _build_settings_panel() -> void:
	_settings_panel = SettingsPanel.new()
	_settings_panel.modulate.a = 0.0
	_settings_panel.visible    = false
	_settings_panel.back_pressed.connect(_on_settings_back)
	add_child(_settings_panel)


# ═══════════════════════════════════════════════════
# HELPERS UI
# ═══════════════════════════════════════════════════
func _make_menu_btn(label_text: String, fg: Color, bg_accent: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(0, 44)
	btn.add_theme_font_size_override("font_size", 12)
	btn.focus_mode = Control.FOCUS_NONE

	var s := StyleBoxFlat.new()
	s.bg_color = Color(bg_accent.r, bg_accent.g, bg_accent.b, 0.25)
	s.border_color = Color(fg.r, fg.g, fg.b, 0.3)
	s.set_border_width_all(1)
	s.set_content_margin_all(10)
	s.corner_radius_top_left     = 4
	s.corner_radius_top_right    = 4
	s.corner_radius_bottom_left  = 4
	s.corner_radius_bottom_right = 4

	var sh := s.duplicate() as StyleBoxFlat
	sh.bg_color    = Color(bg_accent.r, bg_accent.g, bg_accent.b, 0.7)
	sh.border_color = fg

	var sp := sh.duplicate() as StyleBoxFlat
	sp.bg_color = bg_accent

	var sd := s.duplicate() as StyleBoxFlat
	sd.bg_color    = Color(0.05, 0.05, 0.08, 0.3)
	sd.border_color = Color(fg.r, fg.g, fg.b, 0.1)

	btn.add_theme_stylebox_override("normal",   s)
	btn.add_theme_stylebox_override("hover",    sh)
	btn.add_theme_stylebox_override("pressed",  sp)
	btn.add_theme_stylebox_override("disabled", sd)
	btn.add_theme_color_override("font_color",          fg)
	btn.add_theme_color_override("font_hover_color",    fg)
	btn.add_theme_color_override("font_pressed_color",  C_BRIGHT)
	btn.add_theme_color_override("font_disabled_color", C_TEXT_DIM)
	return btn


func _make_thin_sep() -> Control:
	var sep := HSeparator.new()
	var style := StyleBoxFlat.new()
	style.bg_color = C_BORDER
	style.content_margin_top    = 0.0
	style.content_margin_bottom = 0.0
	sep.add_theme_stylebox_override("separator", style)
	sep.add_theme_constant_override("separation", 0)
	return sep


func _make_spacer(height: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, height)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


# ═══════════════════════════════════════════════════
# TRANSITIONS
# ═══════════════════════════════════════════════════
func _fade_in(target: Control, duration: float = 0.35) -> void:
	target.visible = true
	var tw := create_tween()
	tw.tween_property(target, "modulate:a", 1.0, duration).set_ease(Tween.EASE_OUT)


func _fade_out(target: Control, duration: float = 0.25, on_done: Callable = Callable()) -> void:
	var tw := create_tween()
	tw.tween_property(target, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
	if on_done.is_valid():
		tw.tween_callback(func() -> void:
			target.visible = false
			on_done.call()
		)
	else:
		tw.tween_callback(func() -> void: target.visible = false)


func _switch_to_settings() -> void:
	_fade_out(_main_panel, 0.2, func() -> void:
		_fade_in(_settings_panel)
	)


func _switch_to_main() -> void:
	_fade_out(_settings_panel, 0.2, func() -> void:
		_fade_in(_main_panel)
	)


# ═══════════════════════════════════════════════════
# HANDLERS
# ═══════════════════════════════════════════════════
func _on_new_game_pressed() -> void:
	_fade_out(_main_panel, 0.4, func() -> void:
		get_tree().change_scene_to_file(GAME_SCENE)
	)


func _on_settings_pressed() -> void:
	_switch_to_settings()


func _on_settings_back() -> void:
	_switch_to_main()


func _on_quit_pressed() -> void:
	_fade_out(_main_panel, 0.3, func() -> void:
		get_tree().quit()
	)
