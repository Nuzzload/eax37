# main_menu.gd
# Menu principal d'EAX37.
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

# ── GLITCH ────────────────────────────────────────
const GLITCH_CHARS    := "!@#$%^&*<>?|▓░▒█▄▀±×÷∞Ω"
const TITLE_TEXT      := "EAX37"
const SUBTITLE_TEXT   := "SYSTÈME EN LIGNE"
const CORRUPT_STRINGS := [
	"0xDEADBEEF", "NULL_PTR", "STACK_OVERFLOW",
	"ERR::0x4F2A", "KERN PANIC", "SIGSEGV",
	"///ACCESS DENIED///", "BUFFER OVERFLOW",
	"SIGNAL_11", "HEAP_CORRUPT", "0xFF3C8A1D",
	"BAD_POOL_HEADER", "FATAL:0x0000007E",
]

# ── UPTIME FICTIF ─────────────────────────────────
# Durée de base en secondes : 42h 17m 08s
const FAKE_UPTIME_BASE := 152228

# ── BOOT ──────────────────────────────────────────
const BOOT_LINES = [
	{ "text": "EAX-37 BIOS v2.3.1  —  Copyright (C) EAX Systems", "color": "amber", "delay": 0.0 },
	{ "text": "CPU: EAX-X86 @ 3.2GHz  |  RAM: 16384MB  |  STORAGE: 512GB SSD", "color": "dim", "delay": 0.3 },
	{ "text": "", "delay": 0.1 },
	{ "text": "Running POST...", "color": "dim", "delay": 0.2 },
	{ "text": "  Memory check.................... [ OK ]", "color": "green", "delay": 0.4 },
	{ "text": "  Storage check................... [ OK ]", "color": "green", "delay": 0.3 },
	{ "text": "  Network interface............... [ OK ]", "color": "green", "delay": 0.3 },
	{ "text": "  Security module................. [ OK ]", "color": "green", "delay": 0.4 },
	{ "text": "", "delay": 0.1 },
	{ "text": "Booting EAX-37 OS...", "color": "dim", "delay": 0.3 },
	{ "text": "  Loading kernel.................. [ OK ]", "color": "green", "delay": 0.5 },
	{ "text": "  Mounting filesystem............. [ OK ]", "color": "green", "delay": 0.3 },
	{ "text": "  Starting services...............", "color": "dim", "delay": 0.4 },
	{ "text": "    cipher.service................ [ ACTIF ]", "color": "red", "delay": 0.3 },
	{ "text": "    monitor.service............... [ ACTIF ]", "color": "red", "delay": 0.2 },
	{ "text": "    keylog.service................ [ ACTIF ]", "color": "red", "delay": 0.3 },
	{ "text": "", "delay": 0.2 },
	{ "text": "AVERTISSEMENT : Accès non autorisé sur /home/user", "color": "red", "delay": 0.4 },
	{ "text": "AVERTISSEMENT : Connexion distante établie — 194.███.██.██", "color": "red", "delay": 0.2 },
	{ "text": "", "delay": 0.3 },
	{ "text": "Démarrage de l'environnement de bureau...", "color": "dim", "delay": 0.6 },
]

# ── NŒUDS ─────────────────────────────────────────
var _main_panel:     Control
var _settings_panel: SettingsPanel
var _continue_btn:   Button
var _boot_panel:     Control
var _boot_text:      RichTextLabel
var _skip_label:     Label
var _title_label:    Label
var _sub_label:      Label
var _uptime_label:   Label
var _boot_finished   := false
var _skip_requested  := false
var _boot_start_ms:  int = 0
var _menu_start_ms:  int = 0
var _glitch_layer:   Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_boot_panel()
	_build_main_panel()
	_build_settings_panel()
	_build_glitch_layer()
	_start_boot_sequence()


# ═══════════════════════════════════════════════════
# BOOT
# ═══════════════════════════════════════════════════
func _build_boot_panel() -> void:
	_boot_panel = Control.new()
	_boot_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_boot_panel)

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

	_skip_label = Label.new()
	_skip_label.text = "[ ENTRÉE pour passer ]"
	_skip_label.add_theme_font_size_override("font_size", 11)
	_skip_label.add_theme_color_override("font_color", C_TEXT_DIM)
	_skip_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_label.position = Vector2(-150, -40)
	_boot_panel.add_child(_skip_label)


func _start_boot_sequence() -> void:
	_boot_start_ms = Time.get_ticks_msec()
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
		var elapsed_ms := Time.get_ticks_msec() - _boot_start_ms
		var secs := elapsed_ms / 1000
		var ms   := (elapsed_ms % 1000) / 10
		var ts   := "[color=#1c3a1c][%02d:%02d][/color] " % [secs, ms]
		_boot_text.append_text("%s[color=%s]%s[/color]\n" % [ts, hex, text])


func _finish_boot() -> void:
	_boot_finished = true
	_skip_label.visible = false
	var tw := create_tween()
	tw.tween_property(_boot_text, "modulate:a", 0.0, 0.6)
	await tw.finished
	_boot_panel.visible = false
	_menu_start_ms = Time.get_ticks_msec()
	_fade_in(_main_panel)
	# Effets post-boot (coroutines en arrière-plan)
	_typewrite_subtitle()
	_show_toast("ACCÈS SYSTÈME ACCORDÉ", C_GREEN)


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

	# Scanlines statiques
	for i in range(0, 40):
		var line := ColorRect.new()
		line.set_anchors_preset(Control.PRESET_TOP_WIDE)
		line.custom_minimum_size = Vector2(0, 1)
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.color = Color(1, 1, 1, 0.015)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.position.y = i * 30.0
		bg.add_child(line)

	# Lueur accent
	var glow := ColorRect.new()
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.color = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.04)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	_build_scan_line()
	_build_corner_brackets()
	_run_static_flashes()


# ── LIGNE DE SCAN ─────────────────────────────────
func _build_scan_line() -> void:
	var scan := ColorRect.new()
	scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scan.color = Color(1.0, 1.0, 1.0, 0.032)
	add_child(scan)
	_run_scan_loop(scan)


func _run_scan_loop(scan: ColorRect) -> void:
	while is_inside_tree():
		await get_tree().process_frame
		var vp := get_viewport().get_visible_rect().size
		scan.size     = Vector2(vp.x, 3)
		scan.position = Vector2(0, -3.0)
		var tw := create_tween()
		tw.tween_property(scan, "position:y", vp.y + 6.0, 5.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tw.finished
		await get_tree().create_timer(randf_range(8.0, 18.0)).timeout


# ── FLASH STATIQUE ────────────────────────────────
func _run_static_flashes() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(12.0, 40.0)).timeout
		if not is_inside_tree(): return
		var flash := ColorRect.new()
		flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		flash.color = Color(1, 1, 1, 0.0)
		flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(flash)
		var tw := create_tween()
		tw.tween_property(flash, "color:a", 0.05, 0.03)
		tw.tween_property(flash, "color:a", 0.0,  0.07)
		await tw.finished
		flash.queue_free()


# ═══════════════════════════════════════════════════
# GLITCH AVANCÉ
# ═══════════════════════════════════════════════════
func _build_glitch_layer() -> void:
	_glitch_layer = Control.new()
	_glitch_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_glitch_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_glitch_layer)
	_run_heavy_glitch()
	_run_corruption_floaters()


# ── ÉVÉNEMENT GLITCH LOURD ────────────────────────
func _run_heavy_glitch() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(8.0, 20.0)).timeout
		if not is_inside_tree(): return

		# Barres horizontales
		var bar_count := randi_range(3, 8)
		_spawn_glitch_bars(bar_count)

		# Shake du panneau principal si visible
		if _main_panel != null and _main_panel.visible:
			_shake_panel(_main_panel)

		# Double flash rapide
		for _f in 2:
			if not is_inside_tree(): return
			var flash := ColorRect.new()
			flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			flash.color = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.0)
			flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_glitch_layer.add_child(flash)
			var tw := create_tween()
			tw.tween_property(flash, "color:a", randf_range(0.04, 0.09), 0.03)
			tw.tween_property(flash, "color:a", 0.0, 0.06)
			await tw.finished
			flash.queue_free()
			await get_tree().create_timer(randf_range(0.04, 0.12)).timeout


# ── BARRES DE GLITCH ──────────────────────────────
func _spawn_glitch_bars(count: int) -> void:
	var vp := get_viewport().get_visible_rect().size
	# Couleurs de bruit possibles
	var bar_colors := [
		Color(1.0, 1.0, 1.0, 0.08),
		Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.18),
		Color(0.0, 1.0, 0.8, 0.10),
		Color(1.0, 0.2, 0.2, 0.08),
	]
	for _i in count:
		var bar := ColorRect.new()
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var h := randf_range(1.0, 6.0)
		var w := randf_range(vp.x * 0.1, vp.x * 0.85)
		bar.size = Vector2(w, h)
		bar.position = Vector2(
			randf_range(0.0, vp.x - w),
			randf_range(0.0, vp.y)
		)
		bar.color = bar_colors[randi() % bar_colors.size()]
		_glitch_layer.add_child(bar)

		var dur := randf_range(0.04, 0.12)
		var tw := create_tween()
		tw.tween_property(bar, "color:a", 0.0, dur)
		await tw.finished
		bar.queue_free()


# ── SHAKE ─────────────────────────────────────────
func _shake_panel(target: Control, intensity: float = 7.0) -> void:
	var tw := create_tween()
	for _i in 7:
		tw.tween_property(target, "position",
			Vector2(randf_range(-intensity, intensity), randf_range(-intensity * 0.4, intensity * 0.4)),
			0.03
		)
	tw.tween_property(target, "position", Vector2.ZERO, 0.04)


# ── FLOATERS DE CORRUPTION ────────────────────────
func _run_corruption_floaters() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(3.0, 9.0)).timeout
		if not is_inside_tree(): return

		var vp := get_viewport().get_visible_rect().size
		var lbl := Label.new()
		lbl.text = CORRUPT_STRINGS[randi() % CORRUPT_STRINGS.size()]
		lbl.add_theme_font_size_override("font_size", randi_range(8, 11))
		lbl.add_theme_color_override("font_color", Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.0))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.position = Vector2(
			randf_range(30.0, vp.x * 0.75),
			randf_range(50.0, vp.y - 50.0)
		)
		_glitch_layer.add_child(lbl)

		var stay := randf_range(0.25, 0.7)
		var alpha := randf_range(0.35, 0.7)
		var tw := create_tween()
		tw.tween_property(lbl, "modulate:a", alpha, 0.08)
		tw.tween_property(lbl, "modulate:a", alpha, stay)
		tw.tween_property(lbl, "modulate:a", 0.0, 0.2)
		await tw.finished
		lbl.queue_free()


# ── GLITCH SUR BOUTON HOVER ───────────────────────
func _glitch_btn_text(btn: Button, original: String) -> void:
	for _i in randi_range(2, 4):
		if not is_inside_tree() or not is_instance_valid(btn): return
		var glitched := ""
		for ci in original.length():
			glitched += GLITCH_CHARS[randi() % GLITCH_CHARS.length()] if randf() < 0.55 else original[ci]
		btn.text = glitched
		await get_tree().create_timer(0.045).timeout
	if is_instance_valid(btn):
		btn.text = original


# ── BRACKETS HUD ──────────────────────────────────
func _build_corner_brackets() -> void:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)

	var m := 24.0
	var a := 32.0
	var t := 2.0
	var col := Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.4)

	_bracket_rect(c, col, 0, 0, 0, 0,  m,       m + a,  m,       m + t)
	_bracket_rect(c, col, 0, 0, 0, 0,  m,       m + t,  m,       m + a)
	_bracket_rect(c, col, 1, 1, 0, 0,  -(m+a),  -m,     m,       m + t)
	_bracket_rect(c, col, 1, 1, 0, 0,  -(m+t),  -m,     m,       m + a)
	_bracket_rect(c, col, 0, 0, 1, 1,  m,       m + a,  -(m+t),  -m)
	_bracket_rect(c, col, 0, 0, 1, 1,  m,       m + t,  -(m+a),  -m)
	_bracket_rect(c, col, 1, 1, 1, 1,  -(m+a),  -m,     -(m+t),  -m)
	_bracket_rect(c, col, 1, 1, 1, 1,  -(m+t),  -m,     -(m+a),  -m)

	# Pulse des brackets
	var tw := create_tween().set_loops()
	tw.tween_property(c, "modulate:a", 0.5, 2.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(c, "modulate:a", 1.0, 2.5).set_trans(Tween.TRANS_SINE)


func _bracket_rect(parent: Control, col: Color,
		al: float, ar: float, at_: float, ab: float,
		ol: float, or_: float, ot: float, ob: float) -> void:
	var r := ColorRect.new()
	r.color = col
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.anchor_left   = al;  r.anchor_right  = ar
	r.anchor_top    = at_; r.anchor_bottom = ab
	r.offset_left   = ol;  r.offset_right  = or_
	r.offset_top    = ot;  r.offset_bottom = ob
	parent.add_child(r)


# ═══════════════════════════════════════════════════
# CONSTRUCTION — PANNEAU PRINCIPAL
# ═══════════════════════════════════════════════════
func _build_main_panel() -> void:
	_main_panel = Control.new()
	_main_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_main_panel.modulate.a = 0.0
	_main_panel.visible = false
	add_child(_main_panel)

	# Particules derrière le contenu
	_build_particles(_main_panel)

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

	_build_top_bar(_main_panel)
	_build_bottom_bar(_main_panel)


# ── PARTICULES ────────────────────────────────────
func _build_particles(parent: Control) -> void:
	var container := Control.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(container)

	for _i in range(14):
		_create_particle_loop(container)


func _create_particle_loop(parent: Control) -> void:
	# Démarrage décalé pour éviter que tout arrive en même temps
	await get_tree().create_timer(randf_range(0.0, 5.0)).timeout

	while is_inside_tree():
		var vp := get_viewport().get_visible_rect().size

		var dot := ColorRect.new()
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sz := randf_range(1.5, 3.5)
		dot.custom_minimum_size = Vector2(sz, sz)
		dot.color = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, randf_range(0.1, 0.32))
		dot.position = Vector2(randf_range(0.0, vp.x), randf_range(vp.y * 0.4, vp.y + 20.0))
		parent.add_child(dot)

		var target := Vector2(
			dot.position.x + randf_range(-70.0, 70.0),
			randf_range(-40.0, vp.y * 0.2)
		)
		var dur := randf_range(7.0, 16.0)

		var tw := create_tween().set_parallel(true)
		tw.tween_property(dot, "position", target, dur).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_property(dot, "color:a", 0.0, dur * 0.65).set_delay(dur * 0.35)
		await tw.finished
		dot.queue_free()

		await get_tree().create_timer(randf_range(0.1, 2.5)).timeout


# ── BARRES ────────────────────────────────────────
func _build_top_bar(parent: Control) -> void:
	var bar := PanelContainer.new()
	bar.anchor_left   = 0.0; bar.anchor_right  = 1.0
	bar.anchor_top    = 0.0; bar.anchor_bottom = 0.0
	bar.offset_bottom = 26

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.45)
	style.border_color = C_BORDER
	style.border_width_bottom = 1
	style.set_content_margin(SIDE_LEFT,   20)
	style.set_content_margin(SIDE_RIGHT,  20)
	style.set_content_margin(SIDE_TOP,     4)
	style.set_content_margin(SIDE_BOTTOM,  4)
	bar.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	bar.add_child(hbox)

	var left := Label.new()
	left.text = "SESSION-ID: 0xA7F3C219  ·  NODE: NL-AMS-7  ·  PID: 3741"
	left.add_theme_font_size_override("font_size", 9)
	left.add_theme_color_override("font_color", C_TEXT_DIM)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(left)

	var right := Label.new()
	right.text = "EAX-OS v2.3.1  ·  KERNEL 5.15.0-eax"
	right.add_theme_font_size_override("font_size", 9)
	right.add_theme_color_override("font_color", C_TEXT_DIM)
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(right)

	parent.add_child(bar)


func _build_bottom_bar(parent: Control) -> void:
	var bar := PanelContainer.new()
	bar.anchor_left   = 0.0; bar.anchor_right  = 1.0
	bar.anchor_top    = 1.0; bar.anchor_bottom = 1.0
	bar.offset_top    = -26

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.45)
	style.border_color = C_BORDER
	style.border_width_top = 1
	style.set_content_margin(SIDE_LEFT,   20)
	style.set_content_margin(SIDE_RIGHT,  20)
	style.set_content_margin(SIDE_TOP,     4)
	style.set_content_margin(SIDE_BOTTOM,  4)
	bar.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	bar.add_child(hbox)

	# Dot TOR clignotant
	var dot := ColorRect.new()
	dot.color = C_GREEN
	dot.custom_minimum_size = Vector2(6, 6)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(dot)
	var dot_tw := create_tween().set_loops()
	dot_tw.tween_property(dot, "color:a", 0.1, 0.9)
	dot_tw.tween_property(dot, "color:a", 1.0, 0.9)

	var conn := Label.new()
	conn.text = "TOR ACTIF  ·  AES-256  ·  ANONYMAT: ÉLEVÉ"
	conn.add_theme_font_size_override("font_size", 9)
	conn.add_theme_color_override("font_color", C_TEXT_DIM)
	conn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(conn)

	# Uptime en temps réel
	_uptime_label = Label.new()
	_uptime_label.add_theme_font_size_override("font_size", 9)
	_uptime_label.add_theme_color_override("font_color", C_TEXT_DIM)
	_uptime_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(_uptime_label)

	# Séparateur
	var sep_lbl := Label.new()
	sep_lbl.text = "  ·  "
	sep_lbl.add_theme_font_size_override("font_size", 9)
	sep_lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	hbox.add_child(sep_lbl)

	var threat := Label.new()
	threat.text = "MENACE: ██████░░░░ 60%"
	threat.add_theme_font_size_override("font_size", 9)
	threat.add_theme_color_override("font_color", C_AMBER)
	threat.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(threat)

	parent.add_child(bar)

	# Timer uptime
	_update_uptime()
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_update_uptime)
	add_child(timer)


func _update_uptime() -> void:
	if _uptime_label == null: return
	var total := int(Time.get_ticks_msec() / 1000) + FAKE_UPTIME_BASE
	var h := total / 3600
	var m := (total % 3600) / 60
	var s := total % 60
	_uptime_label.text = "UPTIME %02d:%02d:%02d" % [h, m, s]


# ═══════════════════════════════════════════════════
# TITRE
# ═══════════════════════════════════════════════════
func _make_title_block() -> VBoxContainer:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 4)

	_title_label = Label.new()
	_title_label.text = TITLE_TEXT
	_title_label.add_theme_font_size_override("font_size", 52)
	_title_label.add_theme_color_override("font_color", C_BRIGHT)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	block.add_child(_title_label)
	_start_title_glitch()
	_start_title_pulse()

	_sub_label = Label.new()
	_sub_label.text = ""  # rempli par typewriter après le boot
	_sub_label.add_theme_font_size_override("font_size", 10)
	_sub_label.add_theme_color_override("font_color", C_ACCENT)
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	block.add_child(_sub_label)

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


# ── PULSE TITRE ───────────────────────────────────
func _start_title_pulse() -> void:
	var tw := create_tween().set_loops()
	tw.tween_property(_title_label, "modulate", Color(0.82, 0.68, 1.0, 1.0), 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_title_label, "modulate", Color.WHITE, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ── GLITCH TITRE ──────────────────────────────────
func _start_title_glitch() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(3.5, 8.0)).timeout
		if not is_inside_tree() or _title_label == null: return
		for _i in range(randi_range(3, 6)):
			var glitched := ""
			for ci in TITLE_TEXT.length():
				glitched += GLITCH_CHARS[randi() % GLITCH_CHARS.length()] if randf() < 0.45 else TITLE_TEXT[ci]
			_title_label.text = glitched
			await get_tree().create_timer(0.055).timeout
			if not is_inside_tree(): return
		_title_label.text = TITLE_TEXT


# ── TYPEWRITER SOUS-TITRE ─────────────────────────
func _typewrite_subtitle() -> void:
	if _sub_label == null: return
	_sub_label.text = ""
	# Attend que le menu soit bien visible
	await get_tree().create_timer(0.3).timeout
	for i in SUBTITLE_TEXT.length():
		if not is_inside_tree() or _sub_label == null: return
		_sub_label.text = SUBTITLE_TEXT.substr(0, i + 1)
		await get_tree().create_timer(0.045).timeout
	# Curseur clignotant bref après la fin
	for _i in range(3):
		await get_tree().create_timer(0.35).timeout
		if not is_inside_tree() or _sub_label == null: return
		_sub_label.text = SUBTITLE_TEXT + "█"
		await get_tree().create_timer(0.35).timeout
		_sub_label.text = SUBTITLE_TEXT


# ═══════════════════════════════════════════════════
# TOAST NOTIFICATION
# ═══════════════════════════════════════════════════
func _show_toast(message: String, col: Color) -> void:
	# Attend que le menu soit affiché et le typewriter terminé
	await get_tree().create_timer(1.6).timeout
	if not is_inside_tree(): return

	var toast := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color    = Color(col.r, col.g, col.b, 0.10)
	style.border_color = col
	style.border_width_left   = 3
	style.border_width_top    = 1
	style.border_width_right  = 1
	style.border_width_bottom = 1
	style.set_content_margin(SIDE_LEFT,   12)
	style.set_content_margin(SIDE_RIGHT,  16)
	style.set_content_margin(SIDE_TOP,     8)
	style.set_content_margin(SIDE_BOTTOM,  8)
	style.corner_radius_top_left     = 2
	style.corner_radius_top_right    = 2
	style.corner_radius_bottom_left  = 2
	style.corner_radius_bottom_right = 2
	toast.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	toast.add_child(hbox)

	var dot := ColorRect.new()
	dot.color = col
	dot.custom_minimum_size = Vector2(5, 5)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(dot)

	var lbl := Label.new()
	lbl.text = message
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", col)
	hbox.add_child(lbl)

	add_child(toast)
	await get_tree().process_frame

	var vp_w := get_viewport().get_visible_rect().size.x
	var toast_w := toast.get_combined_minimum_size().x
	toast.position = Vector2(vp_w + 10.0, 36.0)

	# Slide in
	var tw_in := create_tween()
	tw_in.tween_property(toast, "position:x", vp_w - toast_w - 30.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw_in.finished

	await get_tree().create_timer(3.0).timeout

	# Slide out + fade
	var tw_out := create_tween().set_parallel(true)
	tw_out.tween_property(toast, "position:x", vp_w + 10.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw_out.tween_property(toast, "modulate:a", 0.0, 0.4)
	await tw_out.finished
	toast.queue_free()


# ═══════════════════════════════════════════════════
# BOUTONS
# ═══════════════════════════════════════════════════
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
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	style.shadow_color  = Color(0, 0, 0, 0.5)
	style.shadow_size   = 20
	style.shadow_offset = Vector2(0, 8)
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
	new_btn.mouse_entered.connect(_glitch_btn_text.bind(new_btn, "NOUVELLE PARTIE"))
	vbox.add_child(new_btn)

	var settings_btn := _make_menu_btn("PARAMÈTRES", C_ACCENT, C_ACCENT_DIM)
	settings_btn.pressed.connect(_on_settings_pressed)
	settings_btn.mouse_entered.connect(_glitch_btn_text.bind(settings_btn, "PARAMÈTRES"))
	vbox.add_child(settings_btn)

	vbox.add_child(_make_thin_sep())

	var quit_btn := _make_menu_btn("QUITTER", C_WARN, Color("#4c0519"))
	quit_btn.pressed.connect(_on_quit_pressed)
	quit_btn.mouse_entered.connect(_glitch_btn_text.bind(quit_btn, "QUITTER"))
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
	s.border_color = Color(fg.r, fg.g, fg.b, 0.4)
	s.border_width_left   = 3
	s.border_width_top    = 0
	s.border_width_right  = 0
	s.border_width_bottom = 0
	s.set_content_margin_all(10)
	s.corner_radius_top_left     = 2
	s.corner_radius_top_right    = 2
	s.corner_radius_bottom_left  = 2
	s.corner_radius_bottom_right = 2

	var sh := s.duplicate() as StyleBoxFlat
	sh.bg_color     = Color(bg_accent.r, bg_accent.g, bg_accent.b, 0.6)
	sh.border_color = fg
	sh.border_width_left = 3

	var sp := sh.duplicate() as StyleBoxFlat
	sp.bg_color = bg_accent

	var sd := s.duplicate() as StyleBoxFlat
	sd.bg_color     = Color(0.05, 0.05, 0.08, 0.3)
	sd.border_color = Color(fg.r, fg.g, fg.b, 0.1)
	sd.border_width_left = 2

	btn.add_theme_stylebox_override("normal",   s)
	btn.add_theme_stylebox_override("hover",    sh)
	btn.add_theme_stylebox_override("pressed",  sp)
	btn.add_theme_stylebox_override("disabled", sd)
	btn.add_theme_color_override("font_color",          fg)
	btn.add_theme_color_override("font_hover_color",    C_BRIGHT)
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
