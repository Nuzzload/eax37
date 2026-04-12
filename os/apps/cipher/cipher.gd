# cipher.gd
# Attache à cipher.tscn
extends PanelContainer

@onready var header: PanelContainer = $VBoxContainer/Header
@onready var messages_scroll: ScrollContainer = $VBoxContainer/MessagesScroll
@onready var messages_list: VBoxContainer = $VBoxContainer/MessagesScroll/MessagesList
@onready var input_bar: PanelContainer = $VBoxContainer/InputBar
@onready var message_input: LineEdit = $VBoxContainer/InputBar/HBoxContainer/MessageInput
@onready var send_button: Button = $VBoxContainer/InputBar/HBoxContainer/SendButton

# Couleurs
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

# Messages initiaux du hacker
const INITIAL_MESSAGES = [
	{ "from": "UNKNOWN_▓▓▓", "time": "02:14", "text": "Je sais ce que tu as fait.", "unread": false },
	{ "from": "UNKNOWN_▓▓▓", "time": "02:31", "text": "Ne contacte personne. Ne dis rien à personne.", "unread": false },
	{ "from": "UNKNOWN_▓▓▓", "time": "08:03", "text": "Première mission. Simple.\nRécupère le fichier /documents/password.txt et envoie-le moi ici.", "unread": false },
	{ "from": "UNKNOWN_▓▓▓", "time": "08:04", "text": "Tu as 3 heures.", "unread": true },
	{ "from": "UNKNOWN_▓▓▓", "time": "08:05", "text": "Et ne joue pas au plus malin. Je regarde.", "unread": true },
]

# Réponses automatiques du hacker
const AUTO_REPLIES = [
	"Je t'entends. Continue.",
	"Ne me fais pas attendre.",
	"...",
	"Tu sais ce qui se passe si tu échoues.",
	"Bien. Ne t'arrête pas.",
]

var reply_index := 0
var is_typing := false

# ── MESSAGES SCRIPTÉS ────────────────────────────────────
# Format : { "delay": secondes, "text": "..." }
# Ajoute tes messages narratifs ici !
const SCRIPTED_MESSAGES = [
	{ "delay": 10.0,  "text": "Tu es là ?" },
	{ "delay": 30.0,  "text": "Je t'ai dit de ne pas traîner." },
	{ "delay": 120.0, "text": "Le fichier. Maintenant." },
	{ "delay": 300.0, "text": "Dernière chance." },
]


func _ready():
	_apply_styles()
	_setup_header()
	_load_initial_messages()
	message_input.gui_input.connect(_on_input_event)
	send_button.pressed.connect(_send_message)
	await get_tree().process_frame
	_scroll_to_bottom()
	_start_scripted_messages()


# ── STYLES ────────────────────────────────────────────────
func _apply_styles():
	# Fond racine
	var bg = StyleBoxFlat.new()
	bg.bg_color = C_BG
	add_theme_stylebox_override("panel", bg)

	# Header
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = C_BG
	header_style.border_color = C_ACCENT_DIM
	header_style.border_width_bottom = 1
	header.add_theme_stylebox_override("panel", header_style)

	# ScrollContainer fond (pas de panel stylebox sur ScrollContainer)
	messages_scroll.add_theme_constant_override("separation", 0)

	# Scrollbar discrète
	var sb = messages_scroll.get_v_scroll_bar()
	var sb_style = StyleBoxFlat.new()
	sb_style.bg_color = C_BORDER
	sb.add_theme_stylebox_override("scroll", sb_style)
	var grabber = StyleBoxFlat.new()
	grabber.bg_color = C_ACCENT_DIM
	sb.add_theme_stylebox_override("grabber", grabber)
	sb.custom_minimum_size.x = 3

	# MessagesList pleine largeur
	messages_list.add_theme_constant_override("separation", 10)
	messages_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	messages_scroll.follow_focus = true

	# InputBar
	var input_style = StyleBoxFlat.new()
	input_style.bg_color = C_BG
	input_style.border_color = C_ACCENT_DIM
	input_style.border_width_top = 1
	input_style.set_content_margin(SIDE_LEFT, 10)
	input_style.set_content_margin(SIDE_RIGHT, 10)
	input_style.set_content_margin(SIDE_TOP, 8)
	input_style.set_content_margin(SIDE_BOTTOM, 8)
	input_bar.add_theme_stylebox_override("panel", input_style)

	# MessageInput style
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

	# SendButton
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

	# Point rouge clignotant
	var dot = ColorRect.new()
	dot.color = C_ACCENT
	dot.custom_minimum_size = Vector2(8, 8)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(dot)

	# Nom contact
	var name_lbl = Label.new()
	name_lbl.text = "UNKNOWN_▓▓▓"
	name_lbl.add_theme_color_override("font_color", C_ACCENT)
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_lbl)

	# Statut chiffrement
	var status_lbl = Label.new()
	status_lbl.text = "CHIFFREMENT E2E · ACTIF"
	status_lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	status_lbl.add_theme_font_size_override("font_size", 9)
	hbox.add_child(status_lbl)

	# Margin autour
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 0)
	margin.add_theme_constant_override("margin_bottom", 0)
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(hbox)
	header.add_child(margin)

	# Animation pulse sur le dot
	var tween = create_tween().set_loops()
	tween.tween_property(dot, "color:a", 0.2, 1.0)
	tween.tween_property(dot, "color:a", 1.0, 1.0)


# ── MESSAGES ─────────────────────────────────────────────
func _load_initial_messages():
	for msg in INITIAL_MESSAGES:
		_add_message(msg["from"], msg["time"], msg["text"], msg["unread"])


func _add_message(from: String, time: String, text: String, unread: bool):
	var is_me = (from == "VOUS")

	var outer = HBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.alignment = BoxContainer.ALIGNMENT_END if is_me else BoxContainer.ALIGNMENT_BEGIN

	# Spacer gauche pour pousser à droite si c'est nous
	if is_me:
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		outer.add_child(spacer)

	# Bulle message
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

	# Ligne auteur + heure
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

	# Texte du message
	var msg_lbl = Label.new()
	msg_lbl.text = text
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_lbl.custom_minimum_size.x = 200
	msg_lbl.add_theme_font_size_override("font_size", 12)
	msg_lbl.add_theme_color_override("font_color", Color("#ffcccc") if unread else C_TEXT)
	vbox.add_child(msg_lbl)

	bubble.add_child(vbox)
	outer.add_child(bubble)

	# Spacer droite pour les messages du hacker
	if not is_me:
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		outer.add_child(spacer)

	messages_list.add_child(outer)


# ── INPUT ─────────────────────────────────────────────────
func _on_input_event(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		get_viewport().set_input_as_handled()
		_send_message()


func _send_message():
	var text = message_input.text.strip_edges()
	if text.is_empty() or is_typing:
		return

	var time = Time.get_time_dict_from_system()
	var time_str = "%02d:%02d" % [time["hour"], time["minute"]]

	_add_message("VOUS", time_str, text, false)
	message_input.text = ""
	message_input.grab_focus()
	_scroll_to_bottom()

	# Réponse automatique après délai
	is_typing = true
	await get_tree().create_timer(0.8).timeout
	_add_typing_indicator()
	await get_tree().create_timer(1.5).timeout
	_remove_typing_indicator()
	_add_hacker_reply(time_str)
	is_typing = false
	_scroll_to_bottom()


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


func _add_hacker_reply(time_str: String):
	var reply = AUTO_REPLIES[reply_index % AUTO_REPLIES.size()]
	reply_index += 1
	_add_message("UNKNOWN_▓▓▓", time_str, reply, false)


func _start_scripted_messages():
	for msg in SCRIPTED_MESSAGES:
		await get_tree().create_timer(msg["delay"]).timeout
		var t = Time.get_time_dict_from_system()
		var time_str = "%02d:%02d" % [t["hour"], t["minute"]]
		_add_message("UNKNOWN_▓▓▓", time_str, msg["text"], true)
		_scroll_to_bottom()


func _scroll_to_bottom():
	await get_tree().process_frame
	messages_scroll.scroll_vertical = messages_scroll.get_v_scroll_bar().max_value
