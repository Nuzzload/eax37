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
const CAM_POSTIT_POS   = Vector3(-0.6, 0.95, 0.35)
const CAM_POSTIT_ROT   = Vector3(-55,  0,    0)
const CAM_SCREEN_POS   = Vector3(0.0,  1.35, 0.65)
const CAM_SCREEN_ROT   = Vector3(0,    0,    0)
const CAM_RECOIL_POS   = Vector3(0.0,  1.5,  1.8)
const CAM_RECOIL_ROT   = Vector3(-8,   0,    0)

# Messages cinématique
const CIPHER_MESSAGES = [
	"Je sais ce que tu as fait.",
	"Ne contacte personne. Ne dis rien à personne.",
	"Tu vas faire exactement ce que je te dis.",
	"Sinon... tout le monde saura.",
	"Première mission. Maintenant.",
]

var _skipped := false
var _cipher_app = null
var _sub_viewport = null


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

	_run_cutscene()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if not _skipped:
			_skipped = true
			await _end_cutscene()


# ── SÉQUENCE ──────────────────────────────────────

func _run_cutscene() -> void:
	await _fade_to(0.0, 1.0)
	_show_skip_label()
	await _wait(0.5)

	# Approche du bureau
	await _move_cam(CAM_DESK_POS, CAM_DESK_ROT, 2.5, Tween.TRANS_SINE)
	await _wait(0.3)

	# Zoom sur le post-it ALT+E
	await _move_cam(CAM_POSTIT_POS, CAM_POSTIT_ROT, 1.2, Tween.TRANS_CUBIC)
	await _wait(1.5)

	# Recule vers le bureau
	await _move_cam(CAM_DESK_POS, CAM_DESK_ROT, 0.8, Tween.TRANS_SINE)
	await _wait(0.2)

	# Écran s'allume
	await _wake_screen()
	await _wait(0.3)

	# Face à l'écran
	await _move_cam(CAM_SCREEN_POS, CAM_SCREEN_ROT, 1.8, Tween.TRANS_CUBIC)

	# Messages CIPHER
	await _play_cipher_messages()

	if _skipped:
		return

	# Recul brusque
	await _recoil()
	await _wait(0.8)
	await _end_cutscene()


# ── ÉCRAN ─────────────────────────────────────────

func _wake_screen() -> void:
	if _sub_viewport:
		_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		_sub_viewport.gui_disable_input = true

	# Flash blanc
	var tw = create_tween()
	tw.tween_property(fade, "color", Color(1, 1, 1, 0.8), 0.06)
	tw.tween_property(fade, "color", Color(0, 0, 0, 0.0), 0.3)
	await tw.finished

	await get_tree().process_frame
	var os_node = _sub_viewport.get_node_or_null("OS") if _sub_viewport else null
	if os_node and os_node.has_method("_on_app_opened"):
		os_node._on_app_opened("cipher")
		await get_tree().process_frame
		await get_tree().process_frame
		_cipher_app = _find_cipher_app(os_node)


func _find_cipher_app(os_node: Node):
	var wm = os_node.get_node_or_null("WindowManager")
	if wm and wm.open_windows.has("cipher"):
		var win = wm.open_windows["cipher"]
		var app = win.get_node_or_null("VBoxContainer/ContentContainer/Cipher")
		if app:
			# Vide les messages existants
			var msg_list = app.get_node_or_null("VBoxContainer/MessagesScroll/MessagesList")
			if msg_list:
				for child in msg_list.get_children():
					child.queue_free()
			# Annule les timers scriptés
			app.set("_scripted_cancelled", true)
		return app
	return null


# ── MESSAGES ──────────────────────────────────────

func _play_cipher_messages() -> void:
	for i in range(CIPHER_MESSAGES.size()):
		if _skipped:
			return
		await _wait(1.8 if i > 0 else 0.8)
		if _skipped:
			return
		_push_cipher_message(CIPHER_MESSAGES[i])
	# Pause après le dernier message
	await _wait(3.0)


func _push_cipher_message(text: String) -> void:
	if not _cipher_app:
		return
	var t = Time.get_time_dict_from_system()
	var time_str = "%02d:%02d" % [t["hour"], t["minute"]]
	if _cipher_app.has_method("_add_message_ui"):
		_cipher_app._add_message_ui("UNKNOWN_▓▓▓", time_str, text, true)
	elif _cipher_app.has_method("_add_message"):
		_cipher_app._add_message("UNKNOWN_▓▓▓", time_str, text, true)
	if _cipher_app.has_method("_scroll_to_bottom"):
		_cipher_app._scroll_to_bottom()


# ── RECUL ─────────────────────────────────────────

func _recoil() -> void:
	# Sursaut brusque
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(cine_cam, "position", Vector3(0.05, 1.6, 2.0), 0.2)
	tw.parallel().tween_property(cine_cam, "rotation_degrees", Vector3(-10, 2, 0), 0.2)
	await tw.finished
	# Stabilise sur la position de départ du joueur
	await _move_cam(CAM_RECOIL_POS, CAM_RECOIL_ROT, 0.5, Tween.TRANS_SINE)


# ── FIN ───────────────────────────────────────────

func _end_cutscene() -> void:
	if _sub_viewport and _sub_viewport.has_meta("in_cutscene"):
		_sub_viewport.remove_meta("in_cutscene")
	await _fade_to(1.0, 0.4)
	get_tree().change_scene_to_file(GAME_SCENE)


# ── HELPERS ───────────────────────────────────────

func _move_cam(target_pos: Vector3, target_rot: Vector3, duration: float, trans = Tween.TRANS_SINE) -> void:
	var tw = create_tween()
	tw.set_trans(trans)
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.set_parallel(true)
	tw.tween_property(cine_cam, "position", target_pos, duration)
	tw.tween_property(cine_cam, "rotation_degrees", target_rot, duration)
	await tw.finished


func _fade_to(alpha: float, duration: float) -> void:
	var tw = create_tween()
	tw.tween_property(fade, "color:a", alpha, duration)
	await tw.finished


func _show_skip_label() -> void:
	var tw = create_tween()
	tw.tween_property(skip_label, "modulate:a", 1.0, 0.4)


func _wait(duration: float) -> void:
	await get_tree().create_timer(duration).timeout
