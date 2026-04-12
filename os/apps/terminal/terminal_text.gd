# terminal.gd
extends Control

@onready var display: RichTextLabel = $VBoxContainer/TerminalDisplay
@onready var input: LineEdit = $VBoxContainer/HBoxContainer/TerminalInput
@onready var prompt_label: Label = $VBoxContainer/HBoxContainer/TerminalPromptLabel
@onready var filesystem_root = $filesystem_root

var current_dir: Node
var path_stack: Array[Node] = []

var user := "hacker"
var host := "eax37"

var history: Array[String] = []
var history_index := -1


func _ready():
	current_dir = filesystem_root
	display.bbcode_enabled = true
	display.scroll_active = true
	display.scroll_following = true
	display.clear()

	# ── Style global du terminal ──────────────────────────
	# Fond noir sur le Control racine
	var root_style := StyleBoxFlat.new()
	root_style.bg_color = Color("#050808")
	add_theme_stylebox_override("panel", root_style)

	# Fond noir sur le RichTextLabel
	var display_style := StyleBoxFlat.new()
	display_style.bg_color = Color("#050808")
	display_style.set_content_margin_all(10)
	display.add_theme_stylebox_override("normal", display_style)
	display.add_theme_color_override("default_color", Color("#c8c8d4"))
	display.add_theme_font_size_override("normal_font_size", 12)

	# Scrollbar invisible
	var scrollbar_style := StyleBoxFlat.new()
	scrollbar_style.bg_color = Color("#1e1e28")
	display.get_v_scroll_bar().add_theme_stylebox_override("scroll", scrollbar_style)
	var grabber_style := StyleBoxFlat.new()
	grabber_style.bg_color = Color("#2a2a38")
	display.get_v_scroll_bar().add_theme_stylebox_override("grabber", grabber_style)
	display.get_v_scroll_bar().custom_minimum_size.x = 3

	# Fond noir sur le HBoxContainer (barre de saisie)
	var hbox = $VBoxContainer/HBoxContainer
	var hbox_style := StyleBoxFlat.new()
	hbox_style.bg_color = Color("#050808")
	hbox_style.border_color = Color("#1e1e28")
	hbox_style.border_width_top = 1
	hbox.add_theme_stylebox_override("panel", hbox_style)

	# Prompt label
	prompt_label.add_theme_color_override("font_color", Color("#22cc66"))
	prompt_label.add_theme_font_size_override("font_size", 12)

	# Style du LineEdit : fond transparent, texte vert
	var stylebox := StyleBoxEmpty.new()
	input.add_theme_stylebox_override("normal", stylebox)
	input.add_theme_stylebox_override("focused", stylebox)
	input.add_theme_stylebox_override("read_only", stylebox)
	input.add_theme_stylebox_override("hover", stylebox)
	input.add_theme_stylebox_override("focus", stylebox)
	input.add_theme_color_override("font_color", Color("#22cc66"))
	input.add_theme_color_override("caret_color", Color("#22cc66"))
	input.add_theme_color_override("selection_color", Color(0.13, 0.8, 0.4, 0.3))
	input.add_theme_font_size_override("font_size", 12)

	input.text = ""
	input.focus_mode = Control.FOCUS_ALL
	input.gui_input.connect(_on_input_event)
	input.grab_focus()

	update_prompt_label()
	print_welcome()


# -----------------------------
# PROMPT / PATH
# -----------------------------
func get_terminal_path() -> String:
	if path_stack.is_empty():
		return "~"
	var p := "~"
	for i in range(1, path_stack.size()):
		p += "/" + path_stack[i].name
	p += "/" + current_dir.name
	return p


func update_prompt_label():
	prompt_label.text = "%s@%s:%s$ " % [user, host, get_terminal_path()]


func print_welcome():
	display.append_text("[color=#22cc66]╔══════════════════════════════════╗[/color]
")
	display.append_text("[color=#22cc66]║[/color]  [color=#e8e8f0]EAX-37 OS[/color]  [color=#5a5a6e]Terminal v2.3.1[/color]      [color=#22cc66]║[/color]
")
	display.append_text("[color=#22cc66]╚══════════════════════════════════╝[/color]
")
	display.append_text("[color=#5a5a6e]Type [/color][color=#ccaa22]help[/color][color=#5a5a6e] for available commands.[/color]

")
	scroll_bottom()


# -----------------------------
# INPUT HANDLING
# -----------------------------
func _input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		input.grab_focus()


func _on_input_event(event: InputEvent):
	if not (event is InputEventKey and event.pressed):
		return

	match event.keycode:
		KEY_UP:
			if not history.is_empty():
				history_index = max(0, history_index - 1)
				input.text = history[history_index]
				input.caret_column = input.text.length()

		KEY_DOWN:
			if not history.is_empty():
				history_index = min(history.size(), history_index + 1)
				input.text = "" if history_index == history.size() else history[history_index]
				input.caret_column = input.text.length()

		KEY_ENTER, KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
			_on_command(input.text)
		KEY_TAB:
			get_viewport().set_input_as_handled()
			autocomplete()


func _on_command(cmd: String):
	var command_text := cmd.strip_edges()

	display.append_text("[color=lime]%s@%s[/color][color=white]:[/color][color=deepskyblue]%s[/color][color=white]$ %s[/color]\n" % [user, host, get_terminal_path(), command_text])

	if command_text != "":
		history.append(command_text)
		history_index = history.size()

	run_command(command_text)
	input.text = ""
	update_prompt_label()
	input.grab_focus()


# -----------------------------
# AUTOCOMPLETE
# -----------------------------
func autocomplete():
	var text := input.text
	if text.is_empty():
		return

	var parts: PackedStringArray = text.split(" ")
	var target: String = parts[-1]

	for child in current_dir.get_children():
		var entry_name: String = get_entry_name(child)
		if entry_name != "" and entry_name.begins_with(target):
			parts[-1] = entry_name
			input.text = " ".join(parts)
			input.caret_column = input.text.length()
			return


# -----------------------------
# HELPERS FILESYSTEM
# -----------------------------
func is_folder(node: Node) -> bool:
	return node.get("is_folder") == true


func get_entry_name(node: Node) -> String:
	if not is_folder(node):
		return node.get("filename") if node.get("filename") != null else node.name
	return node.name


# -----------------------------
# COMMANDES
# -----------------------------
func run_command(cmd: String):
	if cmd.is_empty():
		return

	var parts: PackedStringArray = cmd.split(" ", false)
	var command: String = parts[0]
	var args: Array[String] = []
	for i in range(1, parts.size()):
		args.append(parts[i])

	match command:
		"help":
			cmd_help()
		"ls":
			cmd_ls(args)
		"cd":
			cmd_cd(args)
		"pwd":
			cmd_pwd()
		"cat":
			cmd_cat(args)
		"tree":
			cmd_tree(current_dir, "")
		"grep":
			cmd_grep(args)
		"ssh":
			cmd_ssh(args)
		"clear":
			display.clear()
		"echo":
			print_line(" ".join(args))
		"whoami":
			print_line(user)
		"hostname":
			print_line(host)
		_:
			print_line("bash: %s: command not found" % command, "red")


func cmd_help():
	print_line("Available commands:", "yellow")
	print_line("  ls              List directory contents", "gray")
	print_line("  cd [dir]        Change directory", "gray")
	print_line("  pwd             Print working directory", "gray")
	print_line("  cat [file]      Display file content", "gray")
	print_line("  tree            Show directory tree", "gray")
	print_line("  grep [kw]       Search files for keyword", "gray")
	print_line("  ssh [host]      Connect to remote host", "gray")
	print_line("  clear           Clear terminal", "gray")
	print_line("  whoami          Print username", "gray")
	print_line("  echo [text]     Print text", "gray")


func cmd_ls(_args: Array[String]):
	var entries := current_dir.get_children()
	if entries.is_empty():
		print_line("(empty directory)", "gray")
		return
	for child in entries:
		if is_folder(child):
			print_line(child.name + "/", "deepskyblue")
		elif child.has_method("get_content"):
			print_line(get_entry_name(child), "lightgreen")


func cmd_cd(args: Array[String]):
	if args.is_empty():
		current_dir = filesystem_root
		path_stack.clear()
		return

	var dir: String = args[0]

	if dir == "..":
		if not path_stack.is_empty():
			current_dir = path_stack.pop_back()
		return

	if dir == "~" or dir == "/":
		current_dir = filesystem_root
		path_stack.clear()
		return

	for child in current_dir.get_children():
		if is_folder(child) and child.name == dir:
			path_stack.append(current_dir)
			current_dir = child
			return

	print_line("cd: no such directory: %s" % dir, "red")


func cmd_pwd():
	print_line(get_terminal_path())


func cmd_cat(args: Array[String]):
	if args.is_empty():
		print_line("cat: missing file operand", "red")
		return

	var filename: String = args[0]

	for child in current_dir.get_children():
		if child.has_method("get_content") and get_entry_name(child) == filename:
			var content: String = child.get_content()
			display.append_text("[color=white]" + content + "[/color]\n")
			scroll_bottom()
			return

	print_line("cat: %s: No such file" % filename, "red")


func cmd_grep(args: Array[String]):
	if args.is_empty():
		print_line("grep: missing pattern", "red")
		return

	var keyword: String = args[0]
	var found := false

	for child in current_dir.get_children():
		if child.has_method("get_content"):
			var content: String = child.get_content()
			if keyword in content:
				var fname: String = get_entry_name(child)
				var highlighted: String = content.replace(keyword, "[color=red]%s[/color]" % keyword)
				print_line("[color=yellow]%s[/color]: %s" % [fname, highlighted], "white")
				found = true

	if not found:
		print_line("grep: no match for '%s'" % keyword, "gray")


func cmd_ssh(args: Array[String]):
	if args.is_empty():
		print_line("ssh: missing destination", "red")
		return
	var target: String = args[0]
	print_line("Connecting to %s..." % target, "gray")
	print_line("ssh: connect to host %s: Connection refused" % target, "red")


# -----------------------------
# TREE RECURSION
# -----------------------------
func cmd_tree(node: Node, prefix: String):
	for child in node.get_children():
		if is_folder(child):
			print_line(prefix + "├── " + child.name + "/", "deepskyblue")
			cmd_tree(child, prefix + "│   ")
		elif child.has_method("get_content"):
			print_line(prefix + "├── " + get_entry_name(child), "lightgreen")


# -----------------------------
# PRINT + SCROLL
# -----------------------------
func print_line(msg: String, color: String = "white"):
	display.append_text("[color=%s]%s[/color]\n" % [color, msg])
	scroll_bottom()


func scroll_bottom():
	display.scroll_to_line(display.get_line_count() - 1)
