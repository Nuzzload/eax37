# terminal.gd
extends Control

@onready var display: RichTextLabel = $VBoxContainer/TerminalDisplay
@onready var input: LineEdit = $VBoxContainer/HBoxContainer/TerminalInput
@onready var prompt_label: Label = $VBoxContainer/HBoxContainer/TerminalPromptLabel

# FSNode depuis l'autoload FileSystem
var current_dir

var user := "hacker"
var host := "eax37"

var history: Array[String] = []
var history_index := -1
var is_typing := false
var interrupted := false

var capture_mode := false
var capture_buffer: Array[String] = []

const COMMANDS := [
	"cat", "cd", "chmod", "clear", "cp", "date", "echo", "exit",
	"find", "grep", "head", "help", "history", "hostname", "kill",
	"ls", "man", "mkdir", "mv", "nmap", "ps", "pwd", "rm",
	"ssh", "sudo", "tail", "touch", "tree", "uname", "wc", "whoami"
]


func _ready():
	current_dir = GameFS.get_home()

	display.bbcode_enabled = true
	display.scroll_active = true
	display.scroll_following = true
	display.clear()

	var root_style := StyleBoxFlat.new()
	root_style.bg_color = Color("#050808")
	add_theme_stylebox_override("panel", root_style)

	var display_style := StyleBoxFlat.new()
	display_style.bg_color = Color("#050808")
	display_style.set_content_margin_all(10)
	display.add_theme_stylebox_override("normal", display_style)
	display.add_theme_color_override("default_color", Color("#c8c8d4"))
	display.add_theme_font_size_override("normal_font_size", 12)

	var scrollbar_style := StyleBoxFlat.new()
	scrollbar_style.bg_color = Color("#1e1e28")
	display.get_v_scroll_bar().add_theme_stylebox_override("scroll", scrollbar_style)
	var grabber_style := StyleBoxFlat.new()
	grabber_style.bg_color = Color("#2a2a38")
	display.get_v_scroll_bar().add_theme_stylebox_override("grabber", grabber_style)
	display.get_v_scroll_bar().custom_minimum_size.x = 3

	var hbox = $VBoxContainer/HBoxContainer
	var hbox_style := StyleBoxFlat.new()
	hbox_style.bg_color = Color("#050808")
	hbox_style.border_color = Color("#1e1e28")
	hbox_style.border_width_top = 1
	hbox.add_theme_stylebox_override("panel", hbox_style)

	prompt_label.add_theme_color_override("font_color", Color("#22cc66"))
	prompt_label.add_theme_font_size_override("font_size", 12)

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
	_print_welcome_async()


func _print_welcome_async():
	await print_welcome()


# ─────────────────────────────────────────────────
# PROMPT / PATH
# ─────────────────────────────────────────────────
func get_terminal_path() -> String:
	var home = GameFS.get_home()
	var root = GameFS.get_root()
	if current_dir == root:
		return "/"
	if current_dir == home:
		return "~"

	# Reconstruit le chemin complet
	var parts: Array = []
	var node = current_dir
	while node != null and node != root:
		parts.insert(0, node.node_name)
		node = node.parent

	var full_path = "/" + "/".join(parts)
	var home_path = "/home/hacker"
	if full_path.begins_with(home_path):
		return "~" + full_path.substr(home_path.length())
	return full_path


func update_prompt_label():
	prompt_label.text = "%s@%s:%s$ " % [user, host, get_terminal_path()]


func print_welcome():
	await type_text("╔══════════════════════════════════╗", "#22cc66", 0.005)
	await type_text("║  EAX-37 OS  Terminal v2.3.1      ║", "#e8e8f0", 0.005)
	await type_text("╚══════════════════════════════════╝", "#22cc66", 0.005)
	await type_text("Type help for available commands.", "#5a5a6e", 0.005)
	display.append_text("\n")


# ─────────────────────────────────────────────────
# INPUT HANDLING
# ─────────────────────────────────────────────────
func _input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		input.grab_focus()


func _on_input_event(event: InputEvent):
	if not (event is InputEventKey and event.pressed):
		return

	if event.ctrl_pressed:
		match event.keycode:
			KEY_C:
				get_viewport().set_input_as_handled()
				if is_typing:
					interrupted = true
					is_typing = false
					display.append_text("[color=white]^C[/color]\n")
					update_prompt_label()
					scroll_bottom()
				else:
					display.append_text(
						"[color=lime]%s@%s[/color][color=white]:[/color][color=deepskyblue]%s[/color][color=white]$ %s^C[/color]\n"
						% [user, host, get_terminal_path(), input.text]
					)
					input.text = ""
					scroll_bottom()
				return
			KEY_L:
				get_viewport().set_input_as_handled()
				display.clear()
				return
			KEY_U:
				get_viewport().set_input_as_handled()
				input.text = ""
				return
			KEY_A:
				get_viewport().set_input_as_handled()
				input.caret_column = 0
				return
			KEY_E:
				get_viewport().set_input_as_handled()
				input.caret_column = input.text.length()
				return

	if is_typing:
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
	if is_typing:
		return
	var command_text := cmd.strip_edges()

	display.append_text(
		"[color=lime]%s@%s[/color][color=white]:[/color][color=deepskyblue]%s[/color][color=white]$ %s[/color]\n"
		% [user, host, get_terminal_path(), command_text]
	)

	if command_text != "":
		history.append(command_text)
		history_index = history.size()

	if ";" in command_text:
		for sub in command_text.split(";"):
			var s := sub.strip_edges()
			if s != "":
				run_pipeline(s)
	else:
		run_pipeline(command_text)

	input.text = ""
	update_prompt_label()
	input.grab_focus()


# ─────────────────────────────────────────────────
# PIPELINE
# ─────────────────────────────────────────────────
func run_pipeline(cmd: String):
	if "|" not in cmd:
		run_command(cmd)
		return

	var segments := cmd.split("|")
	var piped_lines: Array[String] = []

	for i in range(segments.size()):
		var seg := segments[i].strip_edges()
		if i < segments.size() - 1:
			capture_mode = true
			capture_buffer = []
			run_command(seg)
			capture_mode = false
			piped_lines = capture_buffer.duplicate()
		else:
			var parts: PackedStringArray = seg.split(" ", false)
			var fcmd: String = parts[0] if parts.size() > 0 else ""
			var fargs: Array[String] = []
			for j in range(1, parts.size()):
				fargs.append(parts[j])
			match fcmd:
				"grep": _piped_grep(fargs, piped_lines)
				"wc":   _piped_wc(piped_lines)
				"head":
					var n: int = int(fargs[0]) if fargs.size() > 0 and fargs[0].is_valid_int() else 10
					for j in range(min(n, piped_lines.size())):
						print_line(piped_lines[j])
				"tail":
					var n: int = int(fargs[0]) if fargs.size() > 0 and fargs[0].is_valid_int() else 10
					var start: int = max(0, piped_lines.size() - n)
					for j in range(start, piped_lines.size()):
						print_line(piped_lines[j])
				_: run_command(seg)


func _piped_grep(args: Array[String], lines: Array[String]):
	if args.is_empty():
		print_line("grep: missing pattern", "red")
		return
	var keyword := args[0]
	var found := false
	for line in lines:
		if keyword.to_lower() in line.to_lower():
			display.append_text("[color=white]%s[/color]\n" % line.replace(keyword, "[color=red]%s[/color]" % keyword))
			scroll_bottom()
			found = true
	if not found:
		print_line("grep: no match for '%s'" % keyword, "gray")


func _piped_wc(lines: Array[String]):
	var words := 0
	var chars := 0
	for line in lines:
		chars += line.length() + 1
		words += line.split(" ", false).size()
	print_line("%6d %6d %6d" % [lines.size(), words, chars])


# ─────────────────────────────────────────────────
# AUTOCOMPLETE
# ─────────────────────────────────────────────────
func autocomplete():
	var text := input.text
	if text.is_empty():
		display.append_text(
			"[color=lime]%s@%s[/color][color=white]:[/color][color=deepskyblue]%s[/color][color=white]$ [/color]\n"
			% [user, host, get_terminal_path()]
		)
		print_line("  ".join(COMMANDS), "gray")
		update_prompt_label()
		return

	var parts: PackedStringArray = text.split(" ")
	var target: String = parts[-1]
	var is_first_word := parts.size() == 1
	var matches: Array[String] = []

	if is_first_word:
		for cmd in COMMANDS:
			if cmd.begins_with(target):
				matches.append(cmd)
	else:
		# Gère les chemins avec des séparateurs (ex: ~/.ssh/auth)
		var slash_idx := target.rfind("/")
		var dir_part  := ""
		var name_part := target
		if slash_idx >= 0:
			dir_part  = target.substr(0, slash_idx + 1)
			name_part = target.substr(slash_idx + 1)

		var search_dir = current_dir
		if dir_part != "":
			var resolved = GameFS.resolve_path(dir_part.rstrip("/"), current_dir)
			if resolved != null and resolved.is_folder:
				search_dir = resolved
			else:
				search_dir = null

		if search_dir != null:
			for child in search_dir.get_visible_children(true):
				var suffix := "/" if child.is_folder else ""
				if child.node_name.begins_with(name_part):
					matches.append(dir_part + child.node_name + suffix)

	if matches.size() == 1:
		parts[-1] = matches[0]
		input.text = " ".join(parts)
		input.caret_column = input.text.length()
	elif matches.size() > 1:
		display.append_text(
			"[color=lime]%s@%s[/color][color=white]:[/color][color=deepskyblue]%s[/color][color=white]$ %s[/color]\n"
			% [user, host, get_terminal_path(), input.text]
		)
		print_line("  ".join(matches), "white")
		update_prompt_label()


# ─────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────
func strip_bbcode(text: String) -> String:
	var result := ""
	var in_tag := false
	for c in text:
		if c == "[": in_tag = true
		elif c == "]": in_tag = false
		elif not in_tag: result += c
	return result


# ─────────────────────────────────────────────────
# COMMANDES
# ─────────────────────────────────────────────────
func run_command(cmd: String):
	if cmd.is_empty():
		return
	var parts: PackedStringArray = cmd.split(" ", false)
	var command: String = parts[0]
	var args: Array[String] = []
	for i in range(1, parts.size()):
		args.append(parts[i])

	match command:
		"help":     cmd_help()
		"ls":       cmd_ls(args)
		"cd":       cmd_cd(args)
		"pwd":      cmd_pwd()
		"cat":      cmd_cat(args)
		"tree":     cmd_tree(current_dir, "")
		"grep":     cmd_grep(args)
		"nmap":     cmd_nmap(args)
		"ssh":      cmd_ssh(args)
		"clear":    display.clear()
		"echo":     print_line(" ".join(args))
		"whoami":   print_line(user)
		"hostname": print_line(host)
		"exit":     _close_app()
		"mkdir":    cmd_mkdir(args)
		"touch":    cmd_touch(args)
		"rm":       cmd_rm(args)
		"mv":       cmd_mv(args)
		"cp":       cmd_cp(args)
		"history":  cmd_history()
		"date":     cmd_date()
		"uname":    cmd_uname(args)
		"man":      cmd_man(args)
		"wc":       cmd_wc(args)
		"head":     cmd_head(args)
		"tail":     cmd_tail(args)
		"find":     cmd_find(args)
		"ps":       cmd_ps()
		"kill":     cmd_kill(args)
		"sudo":
			print_line("%s is not in the sudoers file." % user, "red")
		"chmod":
			if args.size() >= 2:
				print_line("chmod: changed permissions of '%s'" % args[1], "gray")
			else:
				print_line("Usage: chmod <mode> <file>", "red")
		"python3", "python":
			if args.is_empty():
				print_line("Python 3.11.4 (main, Jul 5 2023, 09:00:00)", "gray")
				print_line("Type \"exit()\" to quit.", "gray")
				await get_tree().create_timer(0.5).timeout
				print_line(">>> ", "lightgreen")
				print_line("KeyboardInterrupt", "red")
			else:
				var script_path := args[0]
				var script_node = GameFS.resolve_path(script_path, current_dir)
				if script_node == null or script_node.is_folder:
					print_line("python3: can't open file '%s': No such file or directory" % script_path, "red")
				else:
					print_line("[*] Exécution de %s..." % script_path, "gray")
					await get_tree().create_timer(0.5).timeout
					print_line("Traceback (most recent call last):", "red")
					print_line("  File \"%s\", line 1" % script_path, "red")
					print_line("ModuleNotFoundError: No module named 'pynput'", "red")
		_:
			if command.begins_with("./"):
				var script_name := command.substr(2)
				var script_node = GameFS.resolve_path(script_name, current_dir)
				if script_node == null:
					print_line("bash: %s: No such file or directory" % command, "red")
				elif script_node.is_folder:
					print_line("bash: %s: Is a directory" % command, "red")
				elif script_name == "scan.sh":
					await _run_scan_sh(args)
				else:
					print_line("bash: %s: Permission denied" % command, "red")
					print_line("Hint: chmod +x %s" % script_name, "gray")
			else:
				print_line("bash: %s: command not found" % command, "red")


func _close_app():
	var p = get_parent()
	while p and not p.has_method("close_window"):
		p = p.get_parent()
	if p:
		p.close_window()


func cmd_help():
	print_line("Available commands:", "yellow")
	var cmds := [
		["ls [-la]",         "List directory contents"],
		["cd [dir]",         "Change directory (supports /abs, .., ~)"],
		["pwd",              "Print working directory"],
		["cat <file>",       "Display file content"],
		["head/tail <file>", "Show first / last N lines"],
		["wc <file>",        "Word, line, byte count"],
		["tree",             "Show directory tree"],
		["find <name>",      "Search for files recursively"],
		["grep <kw> [file]", "Search for keyword"],
		["mkdir <dir>",      "Create directory"],
		["touch <file>",     "Create empty file"],
		["rm [-r] <name>",   "Remove file or directory"],
		["mv <src> <dst>",   "Move / rename"],
		["cp <src> <dst>",   "Copy file"],
		["nmap <ip>",        "Scan network target"],
		["ssh <host>",       "Connect to remote host"],
		["echo <text>",      "Print text"],
		["history",          "Show command history"],
		["date",             "Show current date/time"],
		["uname [-a]",       "System information"],
		["man <cmd>",        "Show manual"],
		["ps",               "List running processes"],
		["whoami / hostname","User and host info"],
		["clear",            "Clear terminal"],
		["exit",             "Close terminal"],
	]
	for item in cmds:
		print_line("  %-22s %s" % [item[0], item[1]], "gray")
	print_line("", "")
	print_line("Shortcuts:  Ctrl+C  Ctrl+L  Ctrl+U  Ctrl+A/E", "#5a5a6e")
	print_line("Pipes:      ls | grep foo   |   cat file | wc", "#5a5a6e")
	print_line("Chain:      pwd; ls; whoami", "#5a5a6e")


func cmd_ls(args: Array[String]):
	var show_long   := false
	var show_hidden := false
	var path_arg    := ""

	for arg in args:
		if arg.begins_with("-"):
			if "l" in arg: show_long = true
			if "a" in arg: show_hidden = true
		else:
			path_arg = arg

	var target_dir = current_dir
	if path_arg != "":
		var node = GameFS.resolve_path(path_arg, current_dir)
		if node == null or not node.is_folder:
			print_line("ls: cannot access '%s': No such file or directory" % path_arg, "red")
			return
		target_dir = node

	var entries = target_dir.get_visible_children(show_hidden)
	if entries.is_empty():
		if not capture_mode:
			print_line("(empty directory)", "gray")
		return

	if show_long or capture_mode:
		if show_long:
			print_line("total %d" % entries.size(), "gray")
		for child in entries:
			if child.is_folder:
				var n: String = child.node_name + "/"
				if capture_mode: capture_buffer.append(n)
				else: print_line("drwxr-xr-x  2 %s %s  4096 May  1 22:10 [color=deepskyblue]%s[/color]" % [user, user, n], "white")
			else:
				var n: String = child.node_name
				if capture_mode: capture_buffer.append(n)
				else: print_line("-rw-r--r--  1 %s %s  %4d May  1 22:10 [color=lightgreen]%s[/color]" % [user, user, child.get_content().length(), n], "white")
	else:
		var parts_out: Array[String] = []
		for child in entries:
			if child.is_folder:
				parts_out.append("[color=deepskyblue]%s/[/color]" % child.node_name)
			else:
				parts_out.append("[color=lightgreen]%s[/color]" % child.node_name)
		if not parts_out.is_empty():
			display.append_text("  ".join(parts_out) + "\n")
			scroll_bottom()


func cmd_cd(args: Array[String]):
	if args.is_empty():
		current_dir = GameFS.get_home()
		return

	var dir := args[0]

	if dir == "/":
		current_dir = GameFS.get_root()
		return

	if dir == "~":
		current_dir = GameFS.get_home()
		return

	var node = GameFS.resolve_path(dir, current_dir)
	if node == null:
		print_line("cd: no such directory: %s" % dir, "red")
		return
	if not node.is_folder:
		print_line("cd: not a directory: %s" % dir, "red")
		return

	current_dir = node


func cmd_pwd():
	var p := get_terminal_path()
	print_line(p)
	if capture_mode and not capture_buffer.has(p):
		capture_buffer.append(p)


func cmd_cat(args: Array[String]):
	if args.is_empty():
		print_line("Usage: cat <file>", "red")
		return
	for fname in args:
		var node = GameFS.resolve_path(fname, current_dir)
		if node == null or node.is_folder:
			print_line("cat: %s: No such file or directory" % fname, "red")
			continue
		if node.node_name == "shadow" and user != "root":
			print_line("cat: %s: Permission denied" % fname, "red")
			continue
		for line in node.get_content().split("\n"):
			print_line(line)


func cmd_tree(node, prefix: String):
	var children = node.get_visible_children()
	for i in range(children.size()):
		var child = children[i]
		var is_last: bool = i == children.size() - 1
		var branch: String = "└── " if is_last else "├── "
		var next: String   = "    " if is_last else "│   "
		if child.is_folder:
			print_line(prefix + branch + child.node_name + "/", "deepskyblue")
			cmd_tree(child, prefix + next)
		else:
			print_line(prefix + branch + child.node_name, "lightgreen")


func cmd_grep(args: Array[String]):
	if args.is_empty():
		print_line("Usage: grep [-r] <pattern> [path]", "red")
		return

	var recursive := false
	var filtered: Array[String] = []
	for a in args:
		if a == "-r" or a == "-R" or a == "-ri" or a == "-ir":
			recursive = true
		else:
			filtered.append(a)

	var keyword  := filtered[0] if filtered.size() >= 1 else ""
	var path_arg := filtered[1] if filtered.size() >= 2 else ""

	if keyword.is_empty():
		print_line("Usage: grep [-r] <pattern> [path]", "red")
		return

	if path_arg != "":
		var node = GameFS.resolve_path(path_arg, current_dir)
		if node == null:
			print_line("grep: %s: No such file or directory" % path_arg, "red")
			return
		if node.is_folder:
			if recursive:
				var found := false
				_grep_recursive(node, keyword, path_arg, found)
				return
			else:
				print_line("grep: %s: Is a directory (use -r)" % path_arg, "red")
				return
		# Fichier simple
		var hit := false
		for line in node.get_content().split("\n"):
			if keyword in line:
				print_line(line.replace(keyword, "[color=red]%s[/color]" % keyword))
				hit = true
		if not hit:
			print_line("(no match)", "gray")
		return

	# Pas de path : recherche dans le répertoire courant
	if recursive:
		_grep_recursive(current_dir, keyword, ".", false)
		return

	var found := false
	for child in current_dir.get_visible_children(true):
		if not child.is_folder:
			var content: String = child.get_content()
			if keyword in content:
				for line in content.split("\n"):
					if keyword in line:
						print_line("[color=yellow]%s[/color]: %s" % [child.node_name, line.replace(keyword, "[color=red]%s[/color]" % keyword)])
						found = true
	if not found:
		print_line("grep: no match for '%s'" % keyword, "gray")


func _grep_recursive(node, keyword: String, display_path: String, _found: bool) -> void:
	for child in node.get_visible_children(true):
		var child_path: String = display_path.rstrip("/") + "/" + child.node_name
		if child.is_folder:
			_grep_recursive(child, keyword, child_path, _found)
		else:
			var content: String = child.get_content()
			if keyword in content:
				for line in content.split("\n"):
					if keyword in line:
						print_line("[color=yellow]%s[/color]: %s" % [child_path, line.replace(keyword, "[color=red]%s[/color]" % keyword)])


func cmd_nmap(args: Array[String]):
	if args.is_empty():
		print_line("Usage: nmap <target_ip>", "red")
		return
	interrupted = false
	is_typing   = true
	var target := args[0]
	print_line("Starting Nmap 7.80 at 2026-05-01 22:14", "gray")
	await get_tree().create_timer(0.5).timeout
	if interrupted: return
	print_line("Scanning %s..." % target, "gray")
	for _i in range(10):
		await get_tree().create_timer(0.15).timeout
		if interrupted: return
		display.append_text("[color=gray]#[/color]")
		scroll_bottom()
	display.append_text("\n")
	await get_tree().create_timer(0.3).timeout
	if interrupted: return

	if target == "10.13.37.254":
		print_line("Nmap scan report for %s" % target, "white")
		print_line("Host is up (0.0004s latency).", "gray")
		print_line("PORT     STATE   SERVICE    VERSION", "yellow")
		print_line("22/tcp   open    ssh        OpenSSH 9.3", "lightgreen")
		print_line("443/tcp  open    https      nginx 1.24", "lightgreen")
		print_line("4444/tcp open    krb5-sec   unknown", "orange")
		print_line("8080/tcp filtered http      no-response", "gray")
		print_line("OS: Linux 6.6 (Arch Linux)", "gray")
		print_line("MAC: ▓▓:▓▓:▓▓:▓▓:▓▓:▓▓  (Unknown)", "gray")
		print_line("WARNING: Host appears to be running countermeasures.", "#ef4444")
		print_line("Nmap done: 1 IP address scanned in 4.11 seconds", "gray")
		if capture_mode:
			capture_buffer.append("22/tcp   open    ssh")
			capture_buffer.append("10.13.37.254")
	else:
		print_line("Nmap scan report for %s" % target, "white")
		print_line("Host is up (0.0021s latency).", "gray")
		print_line("PORT     STATE  SERVICE", "yellow")
		print_line("22/tcp   open   ssh", "lightgreen")
		print_line("80/tcp   open   http", "lightgreen")
		print_line("443/tcp  open   https", "lightgreen")
		print_line("Nmap done: 1 IP address scanned in 2.54 seconds", "gray")
		if capture_mode:
			capture_buffer.append("22/tcp   open   ssh")

	is_typing = false


func cmd_ssh(args: Array[String]):
	if args.is_empty():
		print_line("Usage: ssh [user@]host", "red")
		return
	var target: String = args[0]
	interrupted = false
	is_typing   = true
	print_line("Connecting to %s..." % target, "gray")
	await get_tree().create_timer(1.0).timeout
	if interrupted: return

	if "10.13.37.254" in target:
		print_line("Connection established.", "lightgreen")
		await get_tree().create_timer(0.6).timeout
		if interrupted: return
		print_line("Authenticating...", "gray")
		await get_tree().create_timer(0.8).timeout
		if interrupted: return
		print_line("", "")
		print_line("Je vois ce que tu fais.", "#ef4444")
		await get_tree().create_timer(0.5).timeout
		if interrupted: return
		print_line("Ferme cette session.", "#ef4444")
		await get_tree().create_timer(0.4).timeout
		if interrupted: return
		print_line("", "")
		print_line("Connection closed by remote host.", "gray")
	else:
		await get_tree().create_timer(0.5).timeout
		if interrupted: return
		print_line("ssh: connect to host %s port 22: Connection refused" % target, "red")

	is_typing = false


func cmd_mkdir(args: Array[String]):
	if args.is_empty():
		print_line("Usage: mkdir <directory>", "red")
		return
	for dir_name in args:
		if current_dir.get_child(dir_name):
			print_line("mkdir: cannot create directory '%s': File exists" % dir_name, "red")
			continue
		GameFS.create_dir(current_dir, dir_name)


func cmd_touch(args: Array[String]):
	if args.is_empty():
		print_line("Usage: touch <file>", "red")
		return
	for fname in args:
		if not current_dir.get_child(fname):
			GameFS.create_file(current_dir, fname, "")


func cmd_rm(args: Array[String]):
	if args.is_empty():
		print_line("Usage: rm [-r] <name>", "red")
		return
	var recursive := false
	var targets: Array[String] = []
	for arg in args:
		if arg.begins_with("-"):
			if "r" in arg: recursive = true
		else:
			targets.append(arg)
	for target in targets:
		var node = current_dir.get_child(target)
		if node == null:
			print_line("rm: cannot remove '%s': No such file or directory" % target, "red")
			continue
		if node.is_folder and not recursive:
			print_line("rm: cannot remove '%s': Is a directory (use rm -r)" % target, "red")
			continue
		GameFS.delete_node(current_dir, target)


func cmd_mv(args: Array[String]):
	if args.size() < 2:
		print_line("Usage: mv <source> <destination>", "red")
		return
	var node = current_dir.get_child(args[0])
	if node == null:
		print_line("mv: cannot stat '%s': No such file or directory" % args[0], "red")
		return
	node.node_name = args[1]


func cmd_cp(args: Array[String]):
	if args.size() < 2:
		print_line("Usage: cp <source> <destination>", "red")
		return
	var node = current_dir.get_child(args[0])
	if node == null or node.is_folder:
		print_line("cp: cannot stat '%s': No such file or directory" % args[0], "red")
		return
	GameFS.create_file(current_dir, args[1], node.get_content())


func cmd_history():
	if history.is_empty():
		print_line("(no history)", "gray")
		return
	for i in range(history.size()):
		print_line("  %4d  %s" % [i + 1, history[i]], "gray")


func cmd_date():
	var dt := Time.get_datetime_dict_from_system()
	var months := ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
	print_line("%s %2d %02d:%02d:%02d UTC %d" % [months[dt.month-1], dt.day, dt.hour, dt.minute, dt.second, dt.year])


func cmd_uname(args: Array[String]):
	if "-a" in args:
		print_line("EAX_CORE %s 2.3.1-eax #1 SMP 2026-05-01 x86_64 GNU/Linux" % host)
	elif "-r" in args:
		print_line("2.3.1-eax")
	else:
		print_line("EAX_CORE")


func cmd_man(args: Array[String]):
	if args.is_empty():
		print_line("Usage: man <command>", "red")
		return
	var manuals := {
		"ls":    "ls [OPTION] [FILE]\n  List directory contents.\n  -l long format  -a show hidden",
		"cd":    "cd [DIR]\n  Change directory.\n  cd ~  home  |  cd ..  up",
		"cat":   "cat [FILE]\n  Print file contents.",
		"grep":  "grep PATTERN [FILE]\n  Search for PATTERN.",
		"rm":    "rm [-r] NAME\n  Remove files or directories.",
		"mkdir": "mkdir DIR\n  Create directory.",
		"touch": "touch FILE\n  Create empty file.",
		"find":  "find [path] [-name PATTERN]\n  Search files recursively.\n  Supports wildcards: *.txt",
		"nmap":  "nmap TARGET\n  Network scanner. Ctrl+C to stop.",
		"ssh":   "ssh [user@]HOST\n  Remote login.",
	}
	var cmd_name := args[0]
	if cmd_name in manuals:
		print_line("", "")
		print_line("MAN(%s)" % cmd_name.to_upper(), "yellow")
		print_line("─────────────────────────────────", "gray")
		for line in manuals[cmd_name].split("\n"):
			print_line(line, "white")
		print_line("─────────────────────────────────", "gray")
		print_line("", "")
	else:
		print_line("man: no manual entry for '%s'" % cmd_name, "red")


func cmd_wc(args: Array[String]):
	if args.is_empty():
		print_line("Usage: wc <file>", "red")
		return
	var node = GameFS.resolve_path(args[0], current_dir)
	if node == null or node.is_folder:
		print_line("wc: %s: No such file" % args[0], "red")
		return
	var content: String = node.get_content()
	print_line("%6d %6d %6d %s" % [content.split("\n").size(), content.split(" ", false).size(), content.length(), args[0]])


func cmd_head(args: Array[String]):
	var n := 10
	var fname := ""
	for arg in args:
		if arg.begins_with("-") and arg.substr(1).is_valid_int(): n = int(arg.substr(1))
		else: fname = arg
	if fname.is_empty(): print_line("Usage: head [-N] <file>", "red"); return
	var node = GameFS.resolve_path(fname, current_dir)
	if node == null or node.is_folder: print_line("head: %s: No such file" % fname, "red"); return
	var lines: PackedStringArray = node.get_content().split("\n")
	for i in range(min(n, lines.size())): print_line(lines[i])


func cmd_tail(args: Array[String]):
	var n := 10
	var fname := ""
	for arg in args:
		if arg.begins_with("-") and arg.substr(1).is_valid_int(): n = int(arg.substr(1))
		else: fname = arg
	if fname.is_empty(): print_line("Usage: tail [-N] <file>", "red"); return
	var node = GameFS.resolve_path(fname, current_dir)
	if node == null or node.is_folder: print_line("tail: %s: No such file" % fname, "red"); return
	var lines: PackedStringArray = node.get_content().split("\n")
	var start: int = max(0, lines.size() - n)
	for i in range(start, lines.size()): print_line(lines[i])


func cmd_find(args: Array[String]):
	# Syntaxe : find [path] [-name pattern] [pattern_positional]
	var search_root = GameFS.get_root()
	var root_display := ""
	var pattern := ""

	var i := 0
	while i < args.size():
		var a := args[i]
		if a == "-name" and i + 1 < args.size():
			i += 1
			pattern = args[i]
		elif not a.begins_with("-"):
			# Premier arg non-flag = chemin de départ OU pattern
			var maybe_path = GameFS.resolve_path(a, current_dir)
			if maybe_path != null and maybe_path.is_folder:
				search_root = maybe_path
				root_display = a.rstrip("/")
			else:
				pattern = a
		i += 1

	_find_recursive(search_root, pattern, root_display)


func _find_recursive(node, pattern: String, path: String):
	for child in node.get_visible_children(true):
		var cpath: String = (path + "/" if path != "" else "/") + child.node_name
		var matches: bool = pattern.is_empty() or (pattern in child.node_name)
		# Support wildcards simples : *.ext
		if not matches and pattern.begins_with("*"):
			var suffix := pattern.substr(1)
			matches = child.node_name.ends_with(suffix)
		if matches:
			print_line(cpath, "lightgreen")
		if child.is_folder:
			_find_recursive(child, pattern, cpath)


func cmd_ps():
	print_line("  PID TTY          TIME CMD", "yellow")
	print_line("    1 pts/0    00:00:00 bash", "white")
	print_line("   42 pts/0    00:00:00 ps", "white")


func cmd_kill(args: Array[String]):
	if args.is_empty(): print_line("Usage: kill <pid>", "red"); return
	print_line("kill: (%s) - No such process" % args[0], "red")


# ─────────────────────────────────────────────────
# PRINT + SCROLL
# ─────────────────────────────────────────────────
func type_text(text: String, color: String = "white", speed: float = 0.02):
	is_typing = true
	display.append_text("[color=%s]" % color)
	for c in text:
		display.append_text(c)
		scroll_bottom()
		if c != " ":
			await get_tree().create_timer(speed).timeout
	display.append_text("[/color]\n")
	is_typing = false


func print_line(msg: String, color: String = "white"):
	if capture_mode:
		capture_buffer.append(strip_bbcode(msg))
	else:
		display.append_text("[color=%s]%s[/color]\n" % [color, msg])
		scroll_bottom()


func scroll_bottom():
	display.scroll_to_line(display.get_line_count() - 1)


func _run_scan_sh(extra_args: Array[String]) -> void:
	interrupted = false
	is_typing   = true
	var target_range := extra_args[0] if extra_args.size() > 0 else "10.13.37.0/24"
	print_line("[*] Scan de %s" % target_range, "gray")
	print_line("[*] Résultats -> scan_%s.txt" % Time.get_date_string_from_system().replace("-", ""), "gray")
	await get_tree().create_timer(0.4).timeout
	if interrupted: return

	print_line("Starting Nmap 7.80...", "gray")
	for _i in range(8):
		await get_tree().create_timer(0.18).timeout
		if interrupted: return
		display.append_text("[color=gray].[/color]")
		scroll_bottom()
	display.append_text("\n")

	await get_tree().create_timer(0.3).timeout
	if interrupted: return

	var hosts := [
		["10.13.37.1",   "up", [["22/tcp", "open", "ssh"], ["80/tcp", "open", "http"], ["443/tcp", "open", "https"]], ""],
		["10.13.37.10",  "up", [["22/tcp", "open", "ssh"]], ""],
		["10.13.37.42",  "up", [["80/tcp", "open", "http"], ["8080/tcp", "open", "http-proxy"]], ""],
		["10.13.37.100", "up", [["22/tcp", "open", "ssh"]], ""],
		["10.13.37.254", "up", [["22/tcp", "open", "ssh"], ["443/tcp", "open", "https"], ["4444/tcp", "open", "unknown"]], "⚠ COUNTERMEASURES DETECTED"],
	]

	for host_data in hosts:
		if interrupted: return
		print_line("", "")
		print_line("Nmap scan report for %s" % host_data[0], "white")
		print_line("Host is up.", "gray")
		for port_info in host_data[2]:
			var color := "lightgreen" if port_info[1] == "open" else "gray"
			print_line("  %-10s %-8s %s" % [port_info[0], port_info[1], port_info[2]], color)
		if host_data[3] != "":
			print_line("  %s" % host_data[3], "#ef4444")
		await get_tree().create_timer(0.2).timeout

	print_line("", "")
	print_line("[+] Terminé. 5 hôtes actifs sur %s" % target_range, "lightgreen")
	is_typing = false
