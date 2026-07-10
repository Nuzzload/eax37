# cipher.gd
extends PanelContainer

@onready var header: PanelContainer = $VBoxContainer/Header
@onready var messages_scroll: ScrollContainer = $VBoxContainer/MessagesScroll
@onready var messages_list: VBoxContainer = $VBoxContainer/MessagesScroll/MessagesList
@onready var input_bar: PanelContainer = $VBoxContainer/InputBar
@onready var message_input: LineEdit = $VBoxContainer/InputBar/HBoxContainer/MessageInput
@onready var send_button: Button = $VBoxContainer/InputBar/HBoxContainer/SendButton

const C_BG        = Color("#050508")
const C_SURFACE   = Color("#111116")
const C_BORDER    = Color("#1e1e28")
const C_ACCENT    = Color("#cc2233")
const C_ACCENT_DIM = Color("#661018")
const C_TEXT      = Color("#c8c8d4")
const C_TEXT_DIM  = Color("#5a5a6e")
const C_TEXT_BRIGHT = Color("#e8e8f0")
const C_BLUE      = Color("#3366cc")
const C_BLUE_DIM  = Color("#0d1a33")

# Messages initiaux — contexte narratif, pas d'instructions de mission
const INITIAL_MESSAGES = [
	{ "from": "UNKNOWN_▓▓▓", "time": "02:14", "text": "Tu te souviens du 14 octobre.", "unread": false },
	{ "from": "UNKNOWN_▓▓▓", "time": "02:14", "text": "Ce que tu as caché — je sais.", "unread": false },
	{ "from": "UNKNOWN_▓▓▓", "time": "02:15", "text": "Tu vas travailler pour moi.\nSinon tout le monde saura.", "unread": false },
	{ "from": "UNKNOWN_▓▓▓", "time": "02:31", "text": "Ne contacte personne.\nNe dis rien à personne.", "unread": false },
	{ "from": "UNKNOWN_▓▓▓", "time": "08:03", "text": "Première mission.\nAccède au réseau interne NexCorp.", "unread": false },
	{ "from": "UNKNOWN_▓▓▓", "time": "08:04", "text": "Les credentials sont sur cette machine.", "unread": true },
	{ "from": "UNKNOWN_▓▓▓", "time": "08:05", "text": "Je regarde.", "unread": true },
]

var is_typing := false
var cinematic_mode := false
var _scripted_cancelled := false
var _initialized := false
var _chapter_ended := false

const SCRIPTED_MESSAGES = [
	{ "delay": 999.0,  "text": "Tu es là ?" },
	{ "delay": 1200.0, "text": "Je t'ai dit de ne pas traîner." },
	{ "delay": 1500.0, "text": "Dépêche-toi." },
	{ "delay": 1800.0, "text": "Dernière chance." },
]


func _ready():
	_apply_styles()
	_setup_header()
	_load_initial_messages()
	message_input.gui_input.connect(_on_input_event)
	send_button.pressed.connect(_send_message)
	await get_tree().process_frame
	_scroll_to_bottom()
	if not cinematic_mode:
		_start_scripted_messages()
	MissionManager.hacker_message.connect(_on_hacker_message)
	MissionManager.sentinel_message.connect(_on_sentinel_message)
	MissionManager.chapter_end.connect(_on_chapter_end)
	if MissionManager.current_mission == "":
		_apply_chapter_ended_state()


func _on_hacker_message(text: String) -> void:
	_add_typing_indicator()
	await get_tree().create_timer(1.2 + randf() * 0.8).timeout
	_remove_typing_indicator()
	var t = Time.get_time_dict_from_system()
	var time_str = "%02d:%02d" % [t["hour"], t["minute"]]
	_add_message("UNKNOWN_▓▓▓", time_str, text, true)
	_scroll_to_bottom()


func _on_sentinel_message(text: String) -> void:
	GlitchManager.trigger(0.3, 0.25, "sentinel")
	_add_sentinel_typing_indicator()
	await get_tree().create_timer(1.5 + randf() * 0.5).timeout
	_remove_typing_indicator()
	var t = Time.get_time_dict_from_system()
	var time_str = "%02d:%02d" % [t["hour"], t["minute"]]
	_add_sentinel_message(time_str, text)
	_scroll_to_bottom()


func _add_sentinel_typing_indicator():
	var lbl = Label.new()
	lbl.name = "TypingIndicator"
	lbl.text = "SENTINELLE_▓▓▓ est en train d'écrire..."
	lbl.add_theme_color_override("font_color", Color("#22aa55"))
	lbl.add_theme_font_size_override("font_size", 10)
	messages_list.add_child(lbl)
	_scroll_to_bottom()


func _add_sentinel_message(time_str: String, text: String, save: bool = true):
	if save:
		MissionManager.cipher_history.append({"from": "SENTINELLE_▓▓▓", "time": time_str, "text": text, "unread": true, "sentinel": true})
	var outer = HBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.alignment = BoxContainer.ALIGNMENT_BEGIN
	var bubble = PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var bubble_style = StyleBoxFlat.new()
	bubble_style.bg_color = Color("#081a0d")
	bubble_style.border_color = Color("#22cc66")
	bubble_style.border_color.a = 0.7
	bubble_style.set_border_width_all(1)
	bubble_style.corner_radius_top_left = 2
	bubble_style.corner_radius_top_right = 2
	bubble_style.corner_radius_bottom_left = 2
	bubble_style.corner_radius_bottom_right = 2
	bubble_style.set_content_margin_all(10)
	bubble.add_theme_stylebox_override("panel", bubble_style)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	var meta_hbox = HBoxContainer.new()
	var from_lbl = Label.new()
	from_lbl.text = "SENTINELLE_▓▓▓"
	from_lbl.add_theme_font_size_override("font_size", 9)
	from_lbl.add_theme_color_override("font_color", Color("#22cc66"))
	meta_hbox.add_child(from_lbl)
	var spacer2 = Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_hbox.add_child(spacer2)
	var time_lbl = Label.new()
	time_lbl.text = time_str
	time_lbl.add_theme_font_size_override("font_size", 9)
	time_lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	meta_hbox.add_child(time_lbl)
	vbox.add_child(meta_hbox)
	var msg_lbl = Label.new()
	msg_lbl.text = text
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_lbl.custom_minimum_size.x = 200
	msg_lbl.add_theme_font_size_override("font_size", 12)
	msg_lbl.add_theme_color_override("font_color", Color("#aaffcc"))
	vbox.add_child(msg_lbl)
	bubble.add_child(vbox)
	outer.add_child(bubble)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(spacer)
	messages_list.add_child(outer)


func _add_sentinel_message_ui(time_str: String, text: String) -> void:
	_add_sentinel_message(time_str, text, false)


# ── STYLES ────────────────────────────────────────────────
func _apply_styles():
	var bg = StyleBoxFlat.new()
	bg.bg_color = C_BG
	add_theme_stylebox_override("panel", bg)
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = C_BG
	header_style.border_color = C_ACCENT_DIM
	header_style.border_width_bottom = 1
	header.add_theme_stylebox_override("panel", header_style)
	messages_scroll.add_theme_constant_override("separation", 0)
	var sb = messages_scroll.get_v_scroll_bar()
	var sb_style = StyleBoxFlat.new()
	sb_style.bg_color = C_BORDER
	sb.add_theme_stylebox_override("scroll", sb_style)
	var grabber = StyleBoxFlat.new()
	grabber.bg_color = C_ACCENT_DIM
	sb.add_theme_stylebox_override("grabber", grabber)
	sb.custom_minimum_size.x = 3
	messages_list.add_theme_constant_override("separation", 10)
	messages_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	messages_scroll.follow_focus = true
	var input_style = StyleBoxFlat.new()
	input_style.bg_color = C_BG
	input_style.border_color = C_ACCENT_DIM
	input_style.border_width_top = 1
	input_style.set_content_margin(SIDE_LEFT, 10)
	input_style.set_content_margin(SIDE_RIGHT, 10)
	input_style.set_content_margin(SIDE_TOP, 8)
	input_style.set_content_margin(SIDE_BOTTOM, 8)
	input_bar.add_theme_stylebox_override("panel", input_style)
	var input_normal = StyleBoxFlat.new()
	input_normal.bg_color = Color("#17171e")
	input_normal.border_color = C_BORDER
	input_normal.set_border_width_all(1)
	input_normal.set_content_margin_all(8)
	input_normal.corner_radius_top_left = 2
	input_normal.corner_radius_top_right = 2
	input_normal.corner_radius_bottom_left = 2
	input_normal.corner_radius_bottom_right = 2
	message_input.add_theme_stylebox_override("normal", input_normal)
	message_input.add_theme_stylebox_override("focused", input_normal)
	message_input.add_theme_stylebox_override("hover", input_normal)
	message_input.add_theme_color_override("font_color", C_TEXT)
	message_input.add_theme_color_override("caret_color", C_ACCENT)
	message_input.add_theme_color_override("selection_color", Color(C_ACCENT, 0.3))
	message_input.add_theme_font_size_override("font_size", 12)
	message_input.placeholder_text = "Message chiffré..."
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = C_ACCENT_DIM
	btn_normal.border_color = C_ACCENT
	btn_normal.border_color.a = 0.4
	btn_normal.set_border_width_all(1)
	btn_normal.set_content_margin(SIDE_LEFT, 12)
	btn_normal.set_content_margin(SIDE_RIGHT, 12)
	btn_normal.set_content_margin(SIDE_TOP, 8)
	btn_normal.set_content_margin(SIDE_BOTTOM, 8)
	btn_normal.corner_radius_top_left = 2
	btn_normal.corner_radius_top_right = 2
	btn_normal.corner_radius_bottom_left = 2
	btn_normal.corner_radius_bottom_right = 2
	var btn_hover = btn_normal.duplicate()
	btn_hover.bg_color = Color("#881020")
	send_button.add_theme_stylebox_override("normal", btn_normal)
	send_button.add_theme_stylebox_override("hover", btn_hover)
	send_button.add_theme_stylebox_override("pressed", btn_hover)
	send_button.add_theme_color_override("font_color", C_ACCENT)
	send_button.add_theme_font_size_override("font_size", 10)


# ── HEADER ────────────────────────────────────────────────
func _setup_header():
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	var dot = ColorRect.new()
	dot.color = C_ACCENT
	dot.custom_minimum_size = Vector2(8, 8)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(dot)
	var name_lbl = Label.new()
	name_lbl.text = "UNKNOWN_▓▓▓"
	name_lbl.add_theme_color_override("font_color", C_ACCENT)
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_lbl)
	var status_lbl = Label.new()
	status_lbl.text = "CHIFFREMENT E2E · ACTIF"
	status_lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	status_lbl.add_theme_font_size_override("font_size", 9)
	hbox.add_child(status_lbl)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 0)
	margin.add_theme_constant_override("margin_bottom", 0)
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(hbox)
	header.add_child(margin)
	var tween = create_tween().set_loops()
	tween.tween_property(dot, "color:a", 0.2, 1.0)
	tween.tween_property(dot, "color:a", 1.0, 1.0)


# ── MESSAGES ─────────────────────────────────────────────
func _load_initial_messages():
	if cinematic_mode:
		return
	if not MissionManager.cipher_history.is_empty():
		_cancel_scripted_messages()
		for msg in MissionManager.cipher_history:
			if msg.get("sentinel", false):
				_add_sentinel_message(msg["time"], msg["text"], false)
			else:
				_add_message(msg["from"], msg["time"], msg["text"], msg["unread"], false)
		return
	for msg in INITIAL_MESSAGES:
		_add_message(msg["from"], msg["time"], msg["text"], msg["unread"])


func _add_message(from: String, time: String, text: String, unread: bool, save: bool = true):
	if save:
		MissionManager.cipher_history.append({"from": from, "time": time, "text": text, "unread": unread})
	var is_me = (from == "VOUS")
	var outer = HBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.alignment = BoxContainer.ALIGNMENT_END if is_me else BoxContainer.ALIGNMENT_BEGIN
	if is_me:
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		outer.add_child(spacer)
	var bubble = PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var bubble_style = StyleBoxFlat.new()
	if is_me:
		bubble_style.bg_color = C_BLUE_DIM
		bubble_style.border_color = C_BLUE
		bubble_style.border_color.a = 0.3
	elif unread:
		bubble_style.bg_color = Color("#220810")
		bubble_style.border_color = C_ACCENT
		bubble_style.border_color.a = 0.5
	else:
		bubble_style.bg_color = Color("#17171e")
		bubble_style.border_color = C_BORDER
	bubble_style.set_border_width_all(1)
	bubble_style.corner_radius_top_left = 2
	bubble_style.corner_radius_top_right = 2
	bubble_style.corner_radius_bottom_left = 2
	bubble_style.corner_radius_bottom_right = 2
	bubble_style.set_content_margin_all(10)
	bubble.add_theme_stylebox_override("panel", bubble_style)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	var meta_hbox = HBoxContainer.new()
	var from_lbl = Label.new()
	from_lbl.text = from
	from_lbl.add_theme_font_size_override("font_size", 9)
	from_lbl.add_theme_color_override("font_color", C_ACCENT if unread else C_TEXT_DIM)
	meta_hbox.add_child(from_lbl)
	var spacer2 = Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_hbox.add_child(spacer2)
	var time_lbl = Label.new()
	time_lbl.text = time
	time_lbl.add_theme_font_size_override("font_size", 9)
	time_lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	meta_hbox.add_child(time_lbl)
	vbox.add_child(meta_hbox)
	var msg_lbl = Label.new()
	msg_lbl.text = text
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_lbl.custom_minimum_size.x = 200
	msg_lbl.add_theme_font_size_override("font_size", 12)
	msg_lbl.add_theme_color_override("font_color", Color("#ffcccc") if unread else C_TEXT)
	vbox.add_child(msg_lbl)
	bubble.add_child(vbox)
	outer.add_child(bubble)
	if not is_me:
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		outer.add_child(spacer)
	messages_list.add_child(outer)


func _add_message_ui(from: String, time: String, text: String, unread: bool) -> void:
	_add_message(from, time, text, unread, false)


# ── INPUT ─────────────────────────────────────────────────
func _on_input_event(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		get_viewport().set_input_as_handled()
		_send_message()


func _send_message():
	var text = message_input.text.strip_edges()
	if text.is_empty() or is_typing or _chapter_ended:
		return
	var t = Time.get_time_dict_from_system()
	var time_str = "%02d:%02d" % [t["hour"], t["minute"]]
	_add_message("VOUS", time_str, text, false)
	message_input.text = ""
	message_input.grab_focus()
	_scroll_to_bottom()

	# Réponse contextuelle via HackerBrain
	is_typing = true
	await get_tree().create_timer(0.6 + randf() * 0.8).timeout
	var reply = HackerBrain.get_response(text, [])
	var new_topic = HackerBrain.last_topic

	# Glitch sur défi/insulte
	if new_topic in ["insulte", "defi", "menace_joueur"]:
		GlitchManager.trigger(0.8 if new_topic == "defi" else 0.5, 0.5)
		await get_tree().create_timer(0.5 + 3.2 + 0.5).timeout

	_add_typing_indicator()
	await get_tree().create_timer(0.5 + randf() * 0.5).timeout
	_remove_typing_indicator()
	var t2 = Time.get_time_dict_from_system()
	var time_str2 = "%02d:%02d" % [t2["hour"], t2["minute"]]
	_add_message("UNKNOWN_▓▓▓", time_str2, reply, false)
	is_typing = false
	_scroll_to_bottom()
	SaveManager.save()


func _add_typing_indicator():
	var lbl = Label.new()
	lbl.name = "TypingIndicator"
	lbl.text = "UNKNOWN_▓▓▓ est en train d'écrire..."
	lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	lbl.add_theme_font_size_override("font_size", 10)
	messages_list.add_child(lbl)
	_scroll_to_bottom()


func _remove_typing_indicator():
	var indicator = messages_list.get_node_or_null("TypingIndicator")
	if indicator:
		indicator.queue_free()


func _cancel_scripted_messages() -> void:
	_scripted_cancelled = true


func _on_chapter_end() -> void:
	_chapter_ended = true
	_apply_chapter_ended_state()


func _apply_chapter_ended_state() -> void:
	_chapter_ended = true
	message_input.editable = false
	message_input.placeholder_text = "— CONNEXION INACTIVE —"
	send_button.disabled = true


func _start_scripted_messages():
	_scripted_cancelled = false
	var elapsed := 0.0
	for msg in SCRIPTED_MESSAGES:
		var wait_time: float = msg["delay"] - elapsed
		var waited := 0.0
		while waited < wait_time:
			await get_tree().create_timer(0.5).timeout
			waited += 0.5
			if _scripted_cancelled:
				return
		elapsed = msg["delay"]
		if _scripted_cancelled:
			return
		var t = Time.get_time_dict_from_system()
		var time_str = "%02d:%02d" % [t["hour"], t["minute"]]
		_add_message("UNKNOWN_▓▓▓", time_str, msg["text"], true)
		_scroll_to_bottom()


func _scroll_to_bottom():
	await get_tree().process_frame
	messages_scroll.scroll_vertical = messages_scroll.get_v_scroll_bar().max_value


func _input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				messages_scroll.scroll_vertical -= 80
				get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_DOWN:
				messages_scroll.scroll_vertical += 80
				get_viewport().set_input_as_handled()
