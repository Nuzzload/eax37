# credits.gd
# Attache à cutscenes/credits.tscn
# Écran de fin de démo — générique de fin façon "EAX-OS" qui se déconnecte.
#
# ─── CONTENU À PERSONNALISER ─────────────────────────────────────────────────
# Remplace les valeurs entre [ crochets ] ci-dessous et dans CREDITS_BLOCKS.
extends Control

const NEXT_SCENE := "res://ui/main_menu/MainMenu.tscn"

# ── COULEURS (identiques au reste de la DA — cf. main_menu.gd) ───────────────
const C_BG        = Color("#0a0a14")
const C_ACCENT    = Color("#7c3aed")
const C_TEXT      = Color("#b0b0cc")
const C_TEXT_DIM  = Color("#484866")
const C_BRIGHT    = Color("#e0e0f0")
const C_GREEN     = Color("#22c55e")

const GLITCH_CHARS := "!@#$%^&*<>?|▓░▒█▄▀±×÷∞Ω"

# ── TEXTES — PLACEHOLDERS À REMPLIR ───────────────────────────────────────────
const GAME_TITLE    := "EAX37"
const END_HEADLINE  := "FIN DE LA DÉMO — CHAPITRE 1"
const HEADLINE_SUB  := "[ Merci d'avoir joué jusqu'ici. — texte à ajuster ]"

const FINAL_LINE  := "MERCI D'AVOIR JOUÉ"
const TEASER_LINE := "[ Teaser / accroche pour le Chapitre 2 — à compléter ]"

# Générique défilant. Types disponibles :
#   "section" — petit intitulé en majuscules, couleur accent
#   "name"    — ligne de crédit (nom, outil, remerciement...)
#   "spacer"  — espace vertical, "h" = hauteur en px
const CREDITS_BLOCKS := [
	{"type": "spacer",  "h": 40},
	{"type": "section", "text": "UN JEU DE"},
	{"type": "name",    "text": "[ Prénom Nom ]", "big": true},
	{"type": "spacer",  "h": 70},

	{"type": "section", "text": "DÉVELOPPEMENT & GAME DESIGN"},
	{"type": "name",    "text": "[ Prénom Nom ]"},
	{"type": "spacer",  "h": 50},

	{"type": "section", "text": "ENCADREMENT"},
	{"type": "name",    "text": "[ Nom de l'encadrant·e ]"},
	{"type": "spacer",  "h": 50},

	{"type": "section", "text": "REMERCIEMENTS"},
	{"type": "name",    "text": "[ À compléter ]"},
	{"type": "name",    "text": "[ À compléter ]"},
	{"type": "spacer",  "h": 50},

	{"type": "section", "text": "RÉALISÉ AVEC"},
	{"type": "name",    "text": "Godot Engine 4.6"},
	{"type": "spacer",  "h": 110},
]

const SCROLL_SPEED := 42.0  # pixels / seconde

var _skipped := false
var _fade: ColorRect
var _skip_label: Label
var _headline_box: VBoxContainer
var _crawl: Control
var _crawl_list: VBoxContainer
var _final_box: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_background()
	_build_fade()
	_build_skip_label()

	await _run_sequence()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_skipped = true


# ── SÉQUENCE ──────────────────────────────────────────────────────────────────
func _run_sequence() -> void:
	await _fade_to(0.0, 1.2)
	_show_skip_label()

	await _show_headline()
	await _run_crawl()
	await _show_final_card()

	await _fade_to(1.0, 1.4)
	get_tree().change_scene_to_file(NEXT_SCENE)


func _wait_or_skip(duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		if _skipped:
			return
		await get_tree().process_frame
		elapsed += get_process_delta_time()


# ── HEADLINE ──────────────────────────────────────────────────────────────────
func _show_headline() -> void:
	_headline_box = VBoxContainer.new()
	_headline_box.add_theme_constant_override("separation", 10)
	_headline_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_headline_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_headline_box.modulate.a = 0.0
	add_child(_headline_box)

	var title := Label.new()
	title.text = GAME_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", C_BRIGHT)
	_headline_box.add_child(title)

	var headline := Label.new()
	headline.text = END_HEADLINE
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	headline.add_theme_font_size_override("font_size", 15)
	headline.add_theme_color_override("font_color", C_ACCENT)
	_headline_box.add_child(headline)

	var sub := Label.new()
	sub.text = HEADLINE_SUB
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", C_TEXT_DIM)
	_headline_box.add_child(sub)

	var tw := create_tween()
	tw.tween_property(_headline_box, "modulate:a", 1.0, 1.0)
	await tw.finished

	_glitch_label(title, GAME_TITLE)
	await _wait_or_skip(3.2)

	var out := create_tween()
	out.tween_property(_headline_box, "modulate:a", 0.0, 0.7)
	await out.finished
	_headline_box.queue_free()
	_headline_box = null


func _glitch_label(lbl: Label, original: String) -> void:
	if not is_instance_valid(lbl):
		return
	for _i in range(4):
		if _skipped or not is_instance_valid(lbl):
			return
		var glitched := ""
		for ci in original.length():
			glitched += GLITCH_CHARS[randi() % GLITCH_CHARS.length()] if randf() < 0.4 else original[ci]
		lbl.text = glitched
		await get_tree().create_timer(0.05).timeout
	if is_instance_valid(lbl):
		lbl.text = original


# ── CRAWL (générique défilant) ────────────────────────────────────────────────
func _run_crawl() -> void:
	_crawl = Control.new()
	_crawl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crawl.anchor_left = 0.0; _crawl.anchor_right = 1.0
	add_child(_crawl)

	_crawl_list = VBoxContainer.new()
	_crawl_list.add_theme_constant_override("separation", 6)
	_crawl_list.anchor_left = 0.0; _crawl_list.anchor_right = 1.0
	_crawl_list.offset_left = 0; _crawl_list.offset_right = 0
	_crawl.add_child(_crawl_list)

	for block in CREDITS_BLOCKS:
		_crawl_list.add_child(_make_credit_line(block))

	await get_tree().process_frame
	await get_tree().process_frame
	# Force le conteneur (fils d'un Control nu, pas géré par un parent Container)
	# à adopter sa taille minimale réelle, sinon les enfants du VBoxContainer
	# se replient tous sur une hauteur nulle.
	_crawl_list.size = _crawl_list.get_combined_minimum_size()

	var vp_h := get_viewport_rect().size.y
	var content_h: float = _crawl_list.size.y

	_crawl.position.y = vp_h + 60.0
	var target_y := -content_h - 60.0
	var total_dist: float = _crawl.position.y - target_y
	var duration: float = total_dist / SCROLL_SPEED
	var start_y: float = _crawl.position.y

	var t := 0.0
	while t < duration:
		if _skipped:
			break
		await get_tree().process_frame
		t += get_process_delta_time()
		_crawl.position.y = lerp(start_y, target_y, clamp(t / duration, 0.0, 1.0))

	_crawl.queue_free()
	_crawl = null
	_crawl_list = null


func _make_credit_line(block: Dictionary) -> Control:
	var type: String = block.get("type", "name")
	match type:
		"spacer":
			var s := Control.new()
			s.custom_minimum_size = Vector2(0, block.get("h", 30))
			return s
		"section":
			var lbl := Label.new()
			lbl.text = String(block.get("text", "")).to_upper()
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 11)
			lbl.add_theme_color_override("font_color", C_ACCENT)
			return lbl
		_:
			var lbl2 := Label.new()
			lbl2.text = block.get("text", "")
			lbl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl2.add_theme_font_size_override("font_size", 22 if block.get("big", false) else 14)
			lbl2.add_theme_color_override("font_color", C_BRIGHT if block.get("big", false) else C_TEXT)
			return lbl2


# ── CARTE FINALE ──────────────────────────────────────────────────────────────
func _show_final_card() -> void:
	_final_box = VBoxContainer.new()
	_final_box.add_theme_constant_override("separation", 14)
	_final_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_final_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_final_box.modulate.a = 0.0
	add_child(_final_box)

	var dot := ColorRect.new()
	dot.color = C_GREEN
	dot.custom_minimum_size = Vector2(6, 6)
	dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_final_box.add_child(dot)
	var dot_tw := create_tween().set_loops()
	dot_tw.tween_property(dot, "color:a", 0.2, 1.0)
	dot_tw.tween_property(dot, "color:a", 1.0, 1.0)

	var final_lbl := Label.new()
	final_lbl.text = FINAL_LINE
	final_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	final_lbl.add_theme_font_size_override("font_size", 24)
	final_lbl.add_theme_color_override("font_color", C_BRIGHT)
	_final_box.add_child(final_lbl)

	var teaser := Label.new()
	teaser.text = TEASER_LINE
	teaser.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	teaser.add_theme_font_size_override("font_size", 12)
	teaser.add_theme_color_override("font_color", C_TEXT_DIM)
	_final_box.add_child(teaser)

	var tw := create_tween()
	tw.tween_property(_final_box, "modulate:a", 1.0, 1.0)
	await tw.finished

	await _wait_or_skip(3.5)


# ── FOND ──────────────────────────────────────────────────────────────────────
func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	glow.color = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.035)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(glow)


func _build_fade() -> void:
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)


func _build_skip_label() -> void:
	_skip_label = Label.new()
	_skip_label.text = "ÉCHAP / ENTRÉE — passer"
	_skip_label.add_theme_font_size_override("font_size", 11)
	_skip_label.add_theme_color_override("font_color", Color("#484866"))
	_skip_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_label.position = Vector2(-160, -30)
	_skip_label.modulate.a = 0.0
	add_child(_skip_label)


func _show_skip_label() -> void:
	var tw := create_tween()
	tw.tween_property(_skip_label, "modulate:a", 1.0, 0.4)


func _fade_to(alpha: float, duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, duration)
	await tw.finished
