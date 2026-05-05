# main_menu.gd
# Menu principal d'EAX37.
# Gère la navigation entre le panneau principal et le panneau de paramètres,
# ainsi que les transitions (fade) et la séquence de boot.
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
const C_AMBER      = Color("#ccaa22")

const GAME_SCENE := "res://room.tscn"

# ── BOOT ──────────────────────────────────────────
const BOOT_LINES = [
	{ "text": "EAX-37 BIOS v2.3.1  —  Copyright (C) EAX Systems", "color": "amber", "delay": 0.0 },
	{ "text": "CPU: EAX-X86 @ 3.2GHz  |  RAM: 16384MB  |  STORAGE: 512GB SSD", "color": "dim", "delay": 0.3 },
	{ "text": "", "delay": 0.1 },
	{ "text": "Running POST...", "color": "dim", "delay": 0.2 },
	{ "text": "  Memory check.................... [OK]", "color": "green", "delay": 0.4 },
	{ "text": "  Storage check................... [OK]", "color": "green", "delay": 0.3 },
	{ "text": "  Network interface............... [OK]", "color": "green", "delay": 0.3 },
	{ "text": "  Security module................. [OK]", "color": "green", "delay": 0.4 },
	{ "text": "", "delay": 0.1 },
	{ "text": "Booting EAX-37 OS...", "color": "dim", "delay": 0.3 },
	{ "text": "  Loading kernel.................. [OK]", "color": "green", "delay": 0.5 },
	{ "text": "  Mounting filesystem............. [OK]", "color": "green", "delay": 0.3 },
	{ "text": "  Starting services...............", "color": "dim", "delay": 0.4 },
	{ "text": "    cipher.service................ [ACTIVE]", "color": "red", "delay": 0.3 },
	{ "text": "    monitor.service............... [ACTIVE]", "color": "red", "delay": 0.2 },
	{ "text": "    keylog.service................ [ACTIVE]", "color": "red", "delay": 0.3 },
	{ "text": "", "delay": 0.2 },
	{ "text": "WARNING: Unauthorized access detected on /home/user", "color": "red", "delay": 0.4 },
	{ "text": "WARNING: Remote connection established — 194.███.██.██", "color": "red", "delay": 0.2 },
	{ "text": "", "delay": 0.3 },
	{ "text": "Starting desktop environment...", "color": "dim", "delay": 0.6 },
]

# ── NŒUDS ─────────────────────────────────────────
var _main_panel:     Control
var _settings_panel: SettingsPanel
var _continue_btn:   Button
var _boot_panel:     Control
var _boot_text:      RichTextLabel
var _skip_label:     Label
var _boot_finished   := false
var _skip_requested  := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_boot_panel()
	_build_main_panel()
	_build_settings_panel()
	_start_boot_sequence()


# ═══════════════════════════════════════════════════
# BOOT
# ═══════════════════════════════════════════════════
func _build_boot_panel() -> void:
	_boot_panel = Control.new()
	_boot_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_boot_panel)

	# Texte de boot dans un margin container
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	_boot_panel.add_child(margin)

	_boot_text = RichTextLabel.new()
	_boot_text.bbcode_enabled = true
	_boot_text.scroll_active = true
	_boot_text.scroll_following = true
	_boot_text.add_theme_font_size_override("normal_font_size", 13)
	_boot_text.add_theme_color_override("default_color", C_TEXT)
	margin.add_child(_boot_text)

	# Label "Entrée pour passer"
	_skip_label = Label.new()
	_skip_label.text = "[ ENTRÉE pour passer ]"
	_skip_label.add_theme_font_size_override("font_size", 11)
	_skip_label.add_theme_color_override("font_color", C_TEXT_DIM)
	_skip_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_label.position = Vector2(-150, -40)
	_boot_panel.add_child(_skip_label)


func _start_boot_sequence() -> void:
	_skip_label.visible = true
	for line_data in BOOT_LINES:
		if _skip_requested:
			break
		await get_tree().create_timer(line_data["delay"]).timeout
		if _skip_requested:
			break
		_append_boot_line(line_data)
	_finish_boot()


func _append_boot_line(data: Dictionary) -> void:
	var text: String = data.get("text", "")
	var color: String = data.get("color", "text")
	var hex: String
	match color:
		"green": hex = "#22c55e"
		"red":   hex = "#ef4444"
		"amber": hex = "#ccaa22"
		"dim":   hex = "#484866"
		_:       hex = "#b0b0cc"
	if text == "":
		_boot_text.append_text("\n")
	else:
		_boot_text.append_text("[color=%s]%s[/color]\n" % [hex, text])


func _finish_boot() -> void:
	_boot_finished = true
	_skip_label.visible = false
	var tw := create_tween()
	tw.tween_property(_boot_text, "modulate:a", 0.0, 0.6)
	await tw.finished
	_boot_panel.visible = false
	_fade_in(_main_panel)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		if not _boot_finished:
			_skip_requested = true


# ═══════════════════════════════════════════════════
# CONSTRUCTION — FOND
# ═══════════════════════════════════════════════════
func _build_background() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	for i in range(0, 40):
		var line := ColorRect.new()
		line.set_anchors_preset(Control.PRESET_TOP_WIDE)
		line.custom_minimum_size = Vector2(0, 1)
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.color = Color(1, 1, 1, 0.015)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.position.y = i * 30.0
		bg.add_child(line)

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
	_main_panel.modulate.a = 0.0
	_main_panel.visible = false
	add_child(_main_panel)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_main_panel.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	vbox.custom_minimum_size.x = 320
	center.add_child(vbox)

	vbox.add_child(_make_title_block())
	vbox.add_child(_make_spacer(24))
	vbox.add_child(_make_button_card())
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

	var tagline := Label.new()
	tagline.text = "Obéir semble être la clé de votre liberté."
	tagline.add_theme_font_size_override("font_size", 10)
	tagline.add_theme_color_override("font_color", C_TEXT_DIM)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	block.add_child(tagline)

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

	_continue_btn = _make_menu_btn("CONTINUER", C_TEXT_DIM, C_BORDER)
	_continue_btn.disabled = true
	vbox.add_child(_continue_btn)

	vbox.add_child(_make_thin_sep())

	var new_btn := _make_menu_btn("NOUVELLE PARTIE", C_GREEN, Color("#14532d"))
	new_btn.pressed.connect(_on_new_game_pressed)
	vbox.add_child(new_btn)

	var settings_btn := _make_menu_btn("PARAMÈTRES", C_ACCENT, C_ACCENT_DIM)
	settings_btn.pressed.connect(_on_settings_pressed)
	vbox.add_child(settings_btn)

	vbox.add_child(_make_thin_sep())

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
