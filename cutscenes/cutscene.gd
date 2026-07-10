# cutscene.gd
# Attache à cutscene.tscn
# Structure :
#   Node3D (cutscene.gd)
#   ├── [instance room.tscn] nommé "RoomScene"
#   ├── Camera3D "CineCam"
#   └── CanvasLayer "Overlay"
#       ├── ColorRect "Fade"
#       └── Label "SkipLabel"
extends Node3D

@onready var room_scene = $RoomScene
@onready var cine_cam: Camera3D = $CineCam
@onready var fade: ColorRect = $Overlay/Fade
@onready var skip_label: Label = $Overlay/SkipLabel

const GAME_SCENE = "res://room.tscn"

# Points caméra
const CAM_START_POS    = Vector3(0.0,  1.9,  2.8)
const CAM_START_ROT    = Vector3(-12,  0,    0)
const CAM_DESK_POS     = Vector3(0.0,  1.5,  1.6)
const CAM_DESK_ROT     = Vector3(-8,   0,    0)
const CAM_SCREEN_POS   = Vector3(0.0,  1.35, 0.65)
const CAM_SCREEN_ROT   = Vector3(0,    0,    0)
const CAM_RECOIL_POS   = Vector3(0.0,  1.5,  1.8)
const CAM_RECOIL_ROT   = Vector3(-8,   0,    0)

# Phase 2 — trois plans "souvenir", chacun lié à un objet chargé de sens.
# Volontairement proches de l'axe déjà établi (desk → écran) : un grand virage
# de caméra (ex. vers le miroir, à 80° sur le côté) a été testé et cassait la
# continuité spatiale — trop désorientant pour une coupe de 0,1s sur du noir.
const CAM_THOUGHT_WINDOW_POS = Vector3(0.0,  1.85, 1.9)   # la fenêtre — ce qu'il aurait pu regarder ailleurs
const CAM_THOUGHT_WINDOW_ROT = Vector3(-3,   0,    0)
const CAM_THOUGHT_DESK_POS   = Vector3(-0.35, 1.30, 1.05) # le bazar du bureau — la tasse, le cendrier, le livre
const CAM_THOUGHT_DESK_ROT   = Vector3(-28,  9,    0)
# Le 3e plan réutilise CAM_SCREEN_POS/ROT — le silence, les yeux sur l'écran éteint,
# qui prépare directement l'allumage de la phase 3.

const COLOR_BLACK  := Color(0.0, 0.0, 0.0, 1.0)
const COLOR_MEMORY := Color(0.03, 0.06, 0.10, 0.34)  # voile froid — la pièce doit rester lisible, déjà sombre de nuit

# Messages CIPHER — arrivés cette nuit-là
const CIPHER_MESSAGES = [
	"Tu te souviens du 14 octobre.",
	"Ce que tu as caché — je sais.",
	"Tu vas travailler pour moi.",
	"Sinon tout le monde saura.",
	"Première mission. Maintenant.",
]

var _skipped := false
var _cipher_app = null
var _sub_viewport = null
var _bar_top: ColorRect
var _bar_bottom: ColorRect


func _ready() -> void:
	room_scene.set_process_unhandled_input(false)
	cine_cam.make_current()
	cine_cam.position = CAM_START_POS
	cine_cam.rotation_degrees = CAM_START_ROT
	cine_cam.fov = 60

	fade.color = Color(0, 0, 0, 1.0)
	skip_label.text = "ÉCHAP — passer"
	skip_label.add_theme_font_size_override("font_size", 11)
	skip_label.add_theme_color_override("font_color", Color("#484866"))
	skip_label.modulate.a = 0.0

	_sub_viewport = room_scene.get_node_or_null("SubViewport")
	if _sub_viewport:
		_sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		_sub_viewport.set_meta("in_cutscene", true)

	if room_scene.has_method("hide_gameplay_hint"):
		room_scene.hide_gameplay_hint()

	_build_letterbox()
	_run_cutscene()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if not _skipped:
			_skipped = true
			await _end_cutscene()


# ── SÉQUENCE ──────────────────────────────────────

func _run_cutscene() -> void:
	# Phase 1 — La pièce, la nuit
	_show_timestamp("14 octobre  ·  02:14")       # en parallèle, pas d'await
	await _fade_to(0.0, 1.8)
	_show_skip_label()

	# Micro-respiration : la caméra ne reste jamais vraiment immobile
	_breath_cam()
	await _wait(2.5)
	if _skipped: return

	# Glissement lent et inexorable vers le bureau
	await _move_cam(CAM_DESK_POS, CAM_DESK_ROT, 5.5, Tween.TRANS_SINE)
	await _wait(0.8)
	if _skipped: return

	# Phase 2 — Les pensées. Trois plans-souvenirs dans la pièce même,
	# pas un fond noir plat : la fenêtre, le bureau, puis l'écran éteint.
	await _fade_to(1.0, 0.7)
	if _skipped: return
	_show_letterbox()

	await _memory_beat(CAM_THOUGHT_WINDOW_POS, CAM_THOUGHT_WINDOW_ROT,
		"Ce n'était pas prévu comme ça.", 2.3, 15, Color("#a8b4c0"))
	if _skipped: return

	await _memory_beat(CAM_THOUGHT_DESK_POS, CAM_THOUGHT_DESK_ROT,
		"Tu aurais pu faire autrement.", 2.1, 15, Color("#a8b4c0"))
	if _skipped: return

	# Pause pure avant la dernière ligne — le silence fait tout.
	# On reste sur le plan large du bureau (celui de la phase 1, déjà cadré) —
	# le rapprochement vers l'écran n'arrive qu'à son réveil, plus bas.
	cine_cam.position = CAM_DESK_POS
	cine_cam.rotation_degrees = CAM_DESK_ROT
	await _wait(1.5)
	if _skipped: return
	await _fade_to_state(COLOR_MEMORY, 0.8)
	if _skipped: return
	await _show_interstitial("Tu n'as rien dit.", 3.0, 21, Color("#d8d4d0"))
	if _skipped: return

	await _wait(0.7)

	# Phase 3 — Retour dans la pièce. L'intrusion.
	# Le voile se lève lentement — on laisse la pièce, vide et sombre, s'installer
	# avant que l'écran ne s'anime : la coupure doit se sentir venir.
	await _fade_to_state(Color(0.0, 0.0, 0.0, 0.0), 1.6)
	await _wait(1.0)
	if _skipped: return

	# L'écran s'allume — avec un pré-clignotement CRT
	await _wake_screen()
	await _wait(0.4)
	if _skipped: return

	# On se rapproche de l'écran — le mouvement d'approche qui manquait
	await _move_cam(CAM_SCREEN_POS, CAM_SCREEN_ROT, 1.8, Tween.TRANS_CUBIC)

	# Les messages arrivent
	await _play_cipher_messages()

	if _skipped: return

	# Sursaut, puis noir
	await _recoil()
	await _wait(0.7)
	await _hide_letterbox()
	await _end_cutscene()


# ── TEXTES D'INTERSTITIEL ─────────────────────────

func _breath_cam() -> void:
	# Très légère dérive — la caméra ne s'immobilise jamais vraiment
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE)
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(cine_cam, "position",
		CAM_START_POS + Vector3(0.04, 0.03, 0.0), 2.8)
	# Pas d'await — la dérive se fond dans le mouvement suivant


func _show_timestamp(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color("#3a3a4a"))
	lbl.modulate.a = 0.0
	lbl.anchor_left   = 0.0; lbl.anchor_right  = 0.0
	lbl.anchor_top    = 1.0; lbl.anchor_bottom = 1.0
	lbl.offset_left   = 28;  lbl.offset_right  = 260
	lbl.offset_top    = -44; lbl.offset_bottom  = -22
	$Overlay.add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 2.0)
	tw.tween_interval(5.0)
	tw.tween_property(lbl, "modulate:a", 0.0, 1.5)
	tw.tween_callback(lbl.queue_free)


func _show_interstitial(text: String, duration: float,
		font_size: int = 16, color: Color = Color("#c8c8d4"),
		v_offset: float = 0.0) -> void:
	if _skipped:
		return
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if v_offset != 0.0:
		lbl.offset_top = v_offset * 2.0
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.modulate.a = 0.0
	$Overlay.add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 0.8)
	tw.tween_interval(duration)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.6)
	await tw.finished
	lbl.queue_free()


# ── PLANS-SOUVENIRS (phase 2) ──────────────────────

func _memory_beat(cam_pos: Vector3, cam_rot: Vector3, text: String,
		duration: float, font_size: int, color: Color) -> void:
	# Coupe pendant le noir plein (la caméra "saute" sans que ça se voie),
	# tenue un instant, puis on dévoile la pièce à travers un voile froid —
	# ni noir plat, ni pièce normale. Le fondu est volontairement lent pour
	# ne pas lire comme un bug de rendu.
	cine_cam.position = cam_pos
	cine_cam.rotation_degrees = cam_rot
	await _wait(0.25)
	if _skipped:
		return
	await _fade_to_state(COLOR_MEMORY, 1.1)
	if _skipped:
		return
	await _show_interstitial(text, duration, font_size, color)
	if _skipped:
		return
	await _fade_to_state(COLOR_BLACK, 0.7)


# ── ÉCRAN ─────────────────────────────────────────

func _wake_screen() -> void:
	if _sub_viewport:
		_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		_sub_viewport.gui_disable_input = true

	# Pré-clignotement CRT — l'écran essaie de s'allumer
	for flicker_alpha in [0.18, 0.0, 0.35, 0.0, 0.6, 0.0]:
		var fl := create_tween()
		fl.tween_property(fade, "color:a", flicker_alpha, 0.04)
		await fl.finished
		await _wait(0.06 if flicker_alpha == 0.0 else 0.03)

	# Flash d'allumage final
	var tw := create_tween()
	tw.tween_property(fade, "color", Color(1, 1, 1, 0.75), 0.07)
	tw.tween_property(fade, "color", Color(0, 0, 0, 0.0), 0.35)
	await tw.finished

	await get_tree().process_frame
	var os_node = _sub_viewport.get_node_or_null("OS") if _sub_viewport else null
	if os_node and os_node.has_method("_on_app_opened"):
		os_node._on_app_opened("cipher")
		await get_tree().process_frame
		await get_tree().process_frame
		_cipher_app = _find_cipher_app(os_node)


func _find_cipher_app(os_node: Node):
	var wm := os_node.get_node_or_null("WindowManager")
	if wm and wm.open_windows.has("cipher"):
		var win = wm.open_windows["cipher"]
		var app = win.get_node_or_null("VBoxContainer/ContentContainer/Cipher")
		if app:
			var msg_list = app.get_node_or_null("VBoxContainer/MessagesScroll/MessagesList")
			if msg_list:
				for child in msg_list.get_children():
					child.queue_free()
			app.set("_scripted_cancelled", true)
		return app
	return null


# ── MESSAGES CIPHER ───────────────────────────────

func _play_cipher_messages() -> void:
	for i in range(CIPHER_MESSAGES.size()):
		if _skipped:
			return
		var delay := 2.3 - clampf(float(i) * 0.15, 0.0, 0.8)
		if i == 0:
			delay = 1.0
		elif i == CIPHER_MESSAGES.size() - 1:
			await _glitch_flash()
			delay = 1.2
		await _wait(delay)
		if _skipped:
			return
		_push_cipher_message(CIPHER_MESSAGES[i])
		if i == 0:
			# Micro-sursaut involontaire au premier message
			var nudge := create_tween()
			nudge.set_trans(Tween.TRANS_SINE)
			nudge.tween_property(cine_cam, "rotation_degrees",
				CAM_SCREEN_ROT + Vector3(-1.8, 0.6, 0.0), 0.12)
			nudge.tween_property(cine_cam, "rotation_degrees",
				CAM_SCREEN_ROT, 0.5)
	await _wait(2.8)


func _push_cipher_message(text: String) -> void:
	if not _cipher_app:
		return
	var t := Time.get_time_dict_from_system()
	var time_str := "%02d:%02d" % [t["hour"], t["minute"]]
	if _cipher_app.has_method("_add_message_ui"):
		_cipher_app._add_message_ui("UNKNOWN_▓▓▓", time_str, text, true)
	elif _cipher_app.has_method("_add_message"):
		_cipher_app._add_message("UNKNOWN_▓▓▓", time_str, text, true)
	if _cipher_app.has_method("_scroll_to_bottom"):
		_cipher_app._scroll_to_bottom()


func _glitch_flash() -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color", Color(0.18, 0.0, 0.0, 0.65), 0.04)
	tw.tween_property(fade, "color", Color(0, 0, 0, 0.0), 0.28)
	await tw.finished


# ── RECUL ─────────────────────────────────────────

func _recoil() -> void:
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(cine_cam, "position", Vector3(0.05, 1.6, 2.0), 0.2)
	tw.parallel().tween_property(cine_cam, "rotation_degrees", Vector3(-10, 2, 0), 0.2)
	await tw.finished
	await _move_cam(CAM_RECOIL_POS, CAM_RECOIL_ROT, 0.5, Tween.TRANS_SINE)


# ── FIN ───────────────────────────────────────────

func _end_cutscene() -> void:
	if _sub_viewport and _sub_viewport.has_meta("in_cutscene"):
		_sub_viewport.remove_meta("in_cutscene")
	await _fade_to(1.0, 0.5)
	get_tree().change_scene_to_file(GAME_SCENE)


# ── HELPERS ───────────────────────────────────────

func _move_cam(target_pos: Vector3, target_rot: Vector3,
		duration: float, trans := Tween.TRANS_SINE) -> void:
	var tw := create_tween()
	tw.set_trans(trans)
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.set_parallel(true)
	tw.tween_property(cine_cam, "position", target_pos, duration)
	tw.tween_property(cine_cam, "rotation_degrees", target_rot, duration)
	await tw.finished


func _fade_to(alpha: float, duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", alpha, duration)
	await tw.finished


func _fade_to_state(target_color: Color, duration: float) -> void:
	# Anime alpha ET teinte en une fois — utilisé pour le voile froid de phase 2.
	var tw := create_tween()
	tw.tween_property(fade, "color", target_color, duration)
	await tw.finished


func _show_skip_label() -> void:
	var tw := create_tween()
	tw.tween_property(skip_label, "modulate:a", 1.0, 0.4)


func _wait(duration: float) -> void:
	await get_tree().create_timer(duration).timeout


# ── LETTERBOX (cadre cinéma, phase 2 → phase 3) ────

func _build_letterbox() -> void:
	_bar_top = ColorRect.new()
	_bar_top.color = Color(0, 0, 0, 1)
	_bar_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_bar_top.offset_bottom = 0
	$Overlay.add_child(_bar_top)

	_bar_bottom = ColorRect.new()
	_bar_bottom.color = Color(0, 0, 0, 1)
	_bar_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bar_bottom.offset_top = 0
	$Overlay.add_child(_bar_bottom)

	# Le skip label vit dans la bande couverte par la barre du bas —
	# le repasser au-dessus pour qu'il reste lisible.
	$Overlay.move_child(skip_label, $Overlay.get_child_count() - 1)


func _show_letterbox() -> void:
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.set_ease(Tween.EASE_OUT)
	tw.set_parallel(true)
	tw.tween_property(_bar_top, "offset_bottom", 38.0, 0.6)
	tw.tween_property(_bar_bottom, "offset_top", -38.0, 0.6)


func _hide_letterbox() -> void:
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.set_ease(Tween.EASE_IN)
	tw.set_parallel(true)
	tw.tween_property(_bar_top, "offset_bottom", 0.0, 0.5)
	tw.tween_property(_bar_bottom, "offset_top", 0.0, 0.5)
	await tw.finished
