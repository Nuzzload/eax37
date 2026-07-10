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

var ssh_connected := false
var ssh_host := ""
var ssh_user := ""
var remote_path := "/home/admin"
var _ssh_password_mode := false
var _ssh_password_host := ""
var _ssh_password_user := ""
var _ssh_password_attempts := 0
var _tar_extracted: Dictionary = {}  # fichiers extraits à la volée
var _tar_dirs: Dictionary = {}       # répertoires extraits à la volée

const COMMANDS := [
	"cat", "cd", "chmod", "clear", "cp", "date", "echo", "exit",
	"find", "grep", "hashcat", "head", "help", "history", "hostname", "hydra", "kill",
	"ls", "man", "md5sum", "mkdir", "mv", "nmap", "ps", "pwd", "rm",
	"ssh", "sudo", "tail", "touch", "tree", "uname", "vpn", "wc", "whoami"
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
		parts.insert(0, node.name)
		node = node.parent

	var full_path = "/" + "/".join(parts)
	var home_path = "/home/hacker"
	if full_path.begins_with(home_path):
		return "~" + full_path.substr(home_path.length())
	return full_path


func update_prompt_label():
	if ssh_connected:
		var dp := "~" if remote_path == "/home/admin" else remote_path
		prompt_label.text = "%s@nexcorp-srv-01:%s$ " % [ssh_user, dp]
		prompt_label.add_theme_color_override("font_color", Color("#44aaff"))
	else:
		prompt_label.text = "%s@%s:%s$ " % [user, host, get_terminal_path()]
		prompt_label.add_theme_color_override("font_color", Color("#22cc66"))


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
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				display.get_v_scroll_bar().value -= 80
				get_viewport().set_input_as_handled()
				return
			MOUSE_BUTTON_WHEEL_DOWN:
				display.get_v_scroll_bar().value += 80
				get_viewport().set_input_as_handled()
				return
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
			get_viewport().set_input_as_handled()
			if not history.is_empty():
				history_index = max(0, history_index - 1)
				input.text = history[history_index]
				input.caret_column = input.text.length()
		KEY_DOWN:
			get_viewport().set_input_as_handled()
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
	if _ssh_password_mode:
		_ssh_password_mode = false
		input.secret = false
		display.append_text("\n")
		scroll_bottom()
		input.text = ""
		input.grab_focus()
		_handle_ssh_password(cmd.strip_edges())
		return
	var command_text := cmd.strip_edges()

	if ssh_connected:
		var dp := "~" if remote_path == "/home/admin" else remote_path
		display.append_text(
			"[color=#44aaff]%s@nexcorp-srv-01[/color][color=white]:[/color][color=deepskyblue]%s[/color][color=white]$ %s[/color]\n"
			% [ssh_user, dp, command_text]
		)
	else:
		display.append_text(
			"[color=lime]%s@%s[/color][color=white]:[/color][color=deepskyblue]%s[/color][color=white]$ %s[/color]\n"
			% [user, host, get_terminal_path(), command_text]
		)

	if command_text != "":
		history.append(command_text)
		history_index = history.size()
		if not command_text.begins_with("ssh "):
			MissionManager.check_terminal_command(command_text)

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
		if ssh_connected:
			var base: String = "" if remote_path == "/" else remote_path
			var entries: Array = REMOTE_FS.get(remote_path, _tar_dirs.get(remote_path, []))
			for e in entries:
				var full: String = base + "/" + e
				var is_dir := REMOTE_FS.has(full) or _tar_dirs.has(full)
				if e.begins_with(target):
					matches.append(e + ("/" if is_dir else ""))
		else:
			for child in current_dir.get_visible_children(true):
				var suffix = "/" if child.is_folder else ""
				if child.node_name.begins_with(target):
					matches.append(child.node_name + suffix)

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
func is_folder(node) -> bool:
	return node.is_folder


func get_entry_name(node) -> String:
	return node.node_name


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

	if ssh_connected:
		run_remote_command(command, args)
		return

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
		"md5sum":   cmd_md5sum(args)
		"hydra":    cmd_hydra(args)
		"hashcat":  cmd_hashcat(args)
		"vpn":
			cmd_vpn(args)
		"sudo":
			print_line("%s is not in the sudoers file." % user, "red")
		"chmod":
			if args.size() >= 2:
				print_line("chmod: changed permissions of '%s'" % args[1], "gray")
			else:
				print_line("Usage: chmod <mode> <file>", "red")
		_:
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
		["hydra -l <user>",  "Brute force SSH credentials (online)"],
		["hashcat <hash>",   "Crack password hash (offline dictionary)"],
		["ssh <host>",       "Connect to remote host"],
		["vpn connect <profile> <pass>", "Connect to VPN"],
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
		if fname == "shadow" and user != "root":
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
		print_line("Usage: grep <pattern> [file]", "red")
		return
	var keyword  := args[0]
	var filename := args[1] if args.size() >= 2 else ""

	if filename != "":
		var node = GameFS.resolve_path(filename, current_dir)
		if node == null or node.is_folder:
			print_line("grep: %s: No such file" % filename, "red")
			return
		var hit := false
		for line in node.get_content().split("\n"):
			if keyword in line:
				print_line(line.replace(keyword, "[color=red]%s[/color]" % keyword))
				hit = true
		if not hit:
			print_line("(no match)", "gray")
		return

	var found := false
	for child in current_dir.get_visible_children():
		if not child.is_folder:
			var content: String = child.get_content()
			if keyword in content:
				for line in content.split("\n"):
					if keyword in line:
						print_line("[color=yellow]%s[/color]: %s" % [child.node_name, line.replace(keyword, "[color=red]%s[/color]" % keyword)])
						found = true
	if not found:
		print_line("grep: no match for '%s'" % keyword, "gray")


func cmd_nmap(args: Array[String]):
	if args.is_empty():
		print_line("Usage: nmap <target_ip>", "red")
		return
	# Bloquer les IP internes NexCorp sans VPN
	var target = args[0]
	if target.begins_with("10.13.37") and not MissionManager.vpn_connected:
		interrupted = false
		is_typing = true
		print_line("Starting Nmap 7.80 at 2026-05-01 22:14", "gray")
		await get_tree().create_timer(0.8).timeout
		print_line("Scanning %s..." % target, "gray")
		await get_tree().create_timer(1.5).timeout
		print_line("Note: Host seems down. If it is really up, but blocking our ping probes, try -Pn", "red")
		print_line("Nmap done: 1 IP address (0 hosts up)", "gray")
		is_typing = false
		return
	interrupted = false
	is_typing   = true
	print_line("Starting Nmap 7.80 at 2026-05-01 22:14", "gray")
	await get_tree().create_timer(0.5).timeout
	if interrupted: return
	print_line("Scanning %s..." % args[0], "gray")
	for _i in range(10):
		await get_tree().create_timer(0.15).timeout
		if interrupted: return
		display.append_text("[color=gray]#[/color]")
		scroll_bottom()
	display.append_text("\n")
	await get_tree().create_timer(0.3).timeout
	if interrupted: return
	print_line("Nmap scan report for %s" % args[0], "white")
	print_line("Host is up (0.0021s latency).", "gray")
	print_line("PORT     STATE  SERVICE", "yellow")
	print_line("22/tcp   open   ssh", "lightgreen")
	print_line("80/tcp   open   http", "lightgreen")
	print_line("443/tcp  open   https", "lightgreen")
	print_line("Nmap done: 1 IP address scanned in 2.54 seconds", "gray")
	is_typing = false
	MissionManager.show_tech_note("nmap", "NMAP — Network Mapper",
		"Outil open-source de reconnaissance réseau.\n" +
		"Identifie hôtes actifs, ports ouverts et services exposés.\n" +
		"Port 22 ouvert → SSH actif : vecteur d'entrée potentiel.\n\n" +
		"Phase de reconnaissance : cartographier avant d'attaquer.")


func cmd_ssh(args: Array[String]):
	if args.is_empty():
		print_line("Usage: ssh [user@]host", "red")
		return
	var target := args[0]
	var r_user := "admin"
	var r_host := target
	if "@" in target:
		var sp := target.split("@", true, 1)
		r_user = sp[0]
		r_host = sp[1]
	# IP internes bloquées sans VPN
	if r_host.begins_with("10.13.37") and not MissionManager.vpn_connected:
		interrupted = false
		is_typing = true
		print_line("Connecting to %s..." % r_host, "gray")
		await get_tree().create_timer(1.5).timeout
		if interrupted: is_typing = false; return
		print_line("ssh: connect to host %s port 22: Connection refused" % r_host, "red")
		is_typing = false
		return
	# Serveur NexCorp — connexion réussie
	if r_host == "10.13.37.1":
		interrupted = false
		is_typing = true
		print_line("Connecting to %s..." % r_host, "gray")
		await get_tree().create_timer(0.7).timeout
		if interrupted: is_typing = false; return
		print_line("Warning: Permanently added '10.13.37.1' (ED25519) to known hosts.", "yellow")
		await get_tree().create_timer(0.5).timeout
		if interrupted: is_typing = false; return
		is_typing = false
		_ssh_password_host = r_host
		_ssh_password_user = r_user
		_ssh_password_attempts = 0
		_ssh_password_mode = true
		input.secret = true
		display.append_text("%s@%s's password: " % [r_user, r_host])
		scroll_bottom()
		input.grab_focus()
		return
	# Tout autre hôte — refusé
	interrupted = false
	is_typing = true
	print_line("Connecting to %s..." % r_host, "gray")
	await get_tree().create_timer(1.5).timeout
	if interrupted: is_typing = false; return
	print_line("ssh: connect to host %s port 22: Connection refused" % r_host, "red")
	is_typing = false


func _handle_ssh_password(password: String):
	if password == "adm1n_p@ss":
		_ssh_password_attempts = 0
		is_typing = true
		await get_tree().create_timer(0.4).timeout
		display.append_text("[color=#44aaff]Connected to nexcorp-srv-01 as %s[/color]\n" % _ssh_password_user)
		print_line("", "")
		print_line("  NexCorp Internal Server — Authorized Access Only", "yellow")
		print_line("  Unauthorized access is monitored and prosecuted.", "#cc4444")
		print_line("", "")
		print_line("Last login: Sun Jun 28 23:58:03 2026 from 192.168.1.42", "gray")
		print_line("", "")
		is_typing = false
		ssh_connected = true
		ssh_host = _ssh_password_host
		ssh_user = _ssh_password_user
		remote_path = "/home/admin"
		update_prompt_label()
		MissionManager.check_terminal_command("ssh %s@%s" % [_ssh_password_user, _ssh_password_host])
		MissionManager.show_tech_note("ssh", "SSH — Secure Shell",
			"Protocole de connexion distante chiffrée (port 22).\n" +
			"Authentification : mot de passe ou clé cryptographique.\n" +
			"Ici : credentials compromis → accès complet au serveur.\n\n" +
			"Risque réel : 1 credential volé = intrusion totale.")
	else:
		_ssh_password_attempts += 1
		if _ssh_password_attempts >= 3:
			_ssh_password_attempts = 0
			print_line("%s@%s: Permission denied (publickey,password)." % [_ssh_password_user, _ssh_password_host], "red")
			input.grab_focus()
		else:
			print_line("Permission denied, please try again.", "red")
			await get_tree().process_frame
			display.append_text("%s@%s's password: " % [_ssh_password_user, _ssh_password_host])
			scroll_bottom()
			input.secret = true
			_ssh_password_mode = true
			input.grab_focus()


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
		"find":  "find NAME\n  Search files recursively.",
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
	var search_root = current_dir
	var pattern := ""
	var i := 0
	if i < args.size() and not args[i].begins_with("-"):
		var node = GameFS.resolve_path(args[i], current_dir)
		if node != null and node.is_folder:
			search_root = node
		else:
			pattern = args[i]
		i += 1
	while i < args.size():
		if args[i] == "-name" and i + 1 < args.size():
			pattern = args[i + 1].strip_edges().trim_prefix("'").trim_suffix("'").trim_prefix('"').trim_suffix('"')
			i += 2
		else:
			i += 1
	_find_recursive(search_root, pattern, _node_to_path(search_root))


func _node_to_path(node) -> String:
	var root = GameFS.get_root()
	if node == root:
		return ""
	var parts: Array = []
	var n = node
	while n != null and n != root:
		parts.insert(0, n.name)
		n = n.parent
	return "/" + "/".join(parts)


func _find_recursive(node, pattern: String, path: String):
	for child in node.get_visible_children(true):
		var cpath: String = path + "/" + child.node_name
		if pattern.is_empty() or pattern in child.node_name:
			print_line(cpath, "lightgreen")
		if child.is_folder:
			_find_recursive(child, pattern, cpath)


func cmd_vpn(args: Array[String]):
	if args.is_empty() or args[0] != "connect":
		print_line("Usage: vpn connect <profile> <password>", "red")
		return
	if args.size() < 3:
		print_line("vpn: missing credentials", "red")
		return
	is_typing = true
	interrupted = false
	print_line("Initializing VPN connection...", "gray")
	await get_tree().create_timer(0.6).timeout
	if interrupted: is_typing = false; return
	print_line("Authenticating as %s..." % args[1], "gray")
	await get_tree().create_timer(0.8).timeout
	if interrupted: is_typing = false; return
	print_line("Establishing encrypted tunnel...", "gray")
	await get_tree().create_timer(1.0).timeout
	if interrupted: is_typing = false; return
	print_line("[color=#22cc66]VPN connected — NexCorp Internal Network[/color]")
	print_line("IP assigned: 10.13.37.42", "gray")
	print_line("Gateway:     10.13.37.1", "gray")
	is_typing = false
	MissionManager.show_tech_note("vpn", "VPN — Virtual Private Network",
		"Crée un tunnel chiffré vers le réseau cible (NexCorp).\n" +
		"Sans VPN, les IPs internes 10.13.37.0/24 sont inaccessibles.\n" +
		"Mécanisme : authentification + chiffrement TLS 1.3.\n\n" +
		"Vecteur d'attaque : credentials volés → accès réseau interne.")


func cmd_ps():
	print_line("  PID TTY          TIME CMD", "yellow")
	print_line("    1 pts/0    00:00:00 bash", "white")
	print_line("   42 pts/0    00:00:00 ps", "white")


func cmd_kill(args: Array[String]):
	if args.is_empty(): print_line("Usage: kill <pid>", "red"); return
	print_line("kill: (%s) - No such process" % args[0], "red")


func cmd_hydra(args: Array[String]):
	var raw := " ".join(args)
	if args.is_empty() or not "-l" in raw:
		print_line("Usage: hydra -l <user> -P <wordlist> ssh://<host>", "red")
		return
	if not "-P" in raw:
		print_line("Hydra: option -P <wordlist> manquante.", "red")
		print_line("Exemple : hydra -l admin -P rockyou.txt ssh://10.13.37.1", "yellow")
		return
	if not "ssh://" in raw:
		print_line("Hydra: cible requise (ex: ssh://10.13.37.1).", "red")
		return
	if not MissionManager.vpn_connected:
		interrupted = false
		is_typing = true
		print_line("Hydra v9.5 (c) 2023 by van Hauser/THC & David Maciejak", "gray")
		await get_tree().create_timer(0.4).timeout
		if interrupted: is_typing = false; return
		if "10.13.37.1" in raw:
			await get_tree().create_timer(0.6).timeout
			if interrupted: is_typing = false; return
			print_line("[ERROR] Could not connect to 10.13.37.1:22 — No route to host", "red")
		else:
			print_line("[ERROR] Target unreachable or invalid protocol", "red")
		is_typing = false
		return
	interrupted = false
	is_typing = true
	print_line("Hydra v9.5 (c) 2023 by van Hauser/THC & David Maciejak", "gray")
	print_line("[WARNING] Use for legal purposes only!", "yellow")
	print_line("", "")
	await get_tree().create_timer(0.4).timeout
	if interrupted: is_typing = false; return
	print_line("[INFO] Testing ssh://10.13.37.1 with login 'admin'", "gray")
	print_line("[DATA] 16 tasks | 1 server | 500 login tries (l:1/p:500)", "gray")
	await get_tree().create_timer(0.5).timeout
	if interrupted: is_typing = false; return
	const ATTEMPTS := [
		"password", "admin123", "123456", "nexcorp", "admin",
		"password1", "qwerty", "letmein", "nexcorp2024", "Admin!2024",
		"n3xc0rp!", "adm1n", "adm1n_p@ss"
	]
	for i in range(ATTEMPTS.size()):
		await get_tree().create_timer(0.16).timeout
		if interrupted: is_typing = false; return
		if i == ATTEMPTS.size() - 1:
			display.append_text(
				"[color=lightgreen][ATTEMPT] target 10.13.37.1 — login: admin — pass: %s  ✓ FOUND[/color]\n"
				% ATTEMPTS[i]
			)
		else:
			print_line("[ATTEMPT] target 10.13.37.1 — login: admin — pass: %s" % ATTEMPTS[i], "gray")
		scroll_bottom()
	await get_tree().create_timer(0.5).timeout
	if interrupted: is_typing = false; return
	print_line("", "")
	display.append_text(
		"[color=#22cc66][22][ssh] host: 10.13.37.1   login: admin   password: adm1n_p@ss[/color]\n"
	)
	scroll_bottom()
	print_line("[1 of 1 target successfully completed, 1 valid password found]", "lightgreen")
	print_line("", "")
	is_typing = false
	MissionManager.show_tech_note("bruteforce",
		"Hydra vs Hashcat — Deux stratégies d'attaque",
		"Hydra — attaque en ligne (online)\n" +
		"Teste les mots de passe directement contre le service.\n" +
		"Pas besoin de hash. Fonctionne sur SSH, FTP, HTTP...\n" +
		"Ici : 13 tentatives suffisent — le mot de passe est faible.\n" +
		"\n" +
		"Hashcat — craquage hors ligne (offline)\n" +
		"Nécessite un hash extrait au préalable (/etc/shadow).\n" +
		"Très rapide (GPU). Aucune connexion réseau requise.\n" +
		"Ici : inutilisable sans accès préalable au serveur.\n" +
		"\n" +
		"Défense : fail2ban, 2FA, clés SSH, mots de passe longs.")


func cmd_hashcat(args: Array[String]):
	interrupted = false
	is_typing = true
	print_line("hashcat v6.2.6 (c) 2023 by atom and m00nl1ght", "gray")
	await get_tree().create_timer(0.4).timeout
	if interrupted: is_typing = false; return
	print_line("* Device #1: CPU (host), Intel(R) Core(TM) i5 @ 2.40GHz", "gray")
	print_line("", "")
	print_line("Hashes: 0 digests; input file is empty or not found.", "gray")
	await get_tree().create_timer(0.3).timeout
	if interrupted: is_typing = false; return
	print_line("[ERROR] No hash to crack.", "red")
	print_line("        hashcat travaille sur des hashes extraits (/etc/shadow, dump BDD...).", "gray")
	print_line("        Pour attaquer SSH directement, utilise un outil d'attaque en ligne.", "yellow")
	print_line("", "")
	is_typing = false


func cmd_md5sum(args: Array[String]):
	if args.is_empty():
		print_line("Usage: md5sum <file>", "red")
		return
	for fname in args:
		var node = GameFS.resolve_path(fname, current_dir)
		if node == null or node.is_folder:
			print_line("md5sum: %s: No such file or directory" % fname, "red")
			continue
		print_line("a3f8c2e1d94b7f05a3f8c2e1d94b7f05  %s" % fname)


# ─────────────────────────────────────────────────
# SHELL DISTANT (SSH)
# ─────────────────────────────────────────────────
const REMOTE_FS: Dictionary = {
	"/":                         ["home", "data", "etc", "var"],
	"/home":                     ["admin"],
	"/home/admin":               [".bash_history", ".profile", "notes.txt"],
	"/data":                     ["confidentiel"],
	"/data/confidentiel":        ["LISEZMOI.txt", "nexus_registry.dat", "archive_2025.tar.gz", "access.log"],
	"/etc":                      ["passwd", "hostname", "shadow"],
	"/var":                      ["log"],
	"/var/log":                  ["auth.log", "syslog"],
}

const REMOTE_FILES: Dictionary = {
	"/home/admin/.bash_history":
		"ls\n" +
		"pwd\n" +
		"find /data -name '*.dat'\n" +
		"cd /data/confidentiel\n" +
		"ls -la\n" +
		"cat LISEZMOI.txt\n" +
		"cat nexus_registry.dat\n" +
		"tar tf archive_2025.tar.gz\n" +
		"exit",
	"/home/admin/.profile":
		"# ~/.profile: executed by login shells.\nexport PATH=$PATH:/usr/local/bin\numask 022",
	"/home/admin/notes.txt":
		"mémo perso — à ne pas laisser traîner\n\n" +
		"dossier confidentiel : /data/confidentiel/\n" +
		"  → nexus_registry.dat — NE PAS OUVRIR sans autorisation\n" +
		"  → archive_2025.tar.gz — docs internes archivés\n\n" +
		"accès restreint : admin only.\n" +
		"shadow : pas touche.",
	"/data/confidentiel/LISEZMOI.txt":
		"ACCÈS RESTREINT — NexCorp Intranet\n" +
		"Dossier : Données opérationnelles\n\n" +
		"  nexus_registry.dat  — registre opérationnel (accès OMÉGA)\n" +
		"  archive_2025.tar.gz — documents de travail archivés\n" +
		"  access.log          — journal d'accès\n\n" +
		"Toute consultation non autorisée est enregistrée.",
	"/data/confidentiel/nexus_registry.dat":
		"NEXUS — REGISTRE OPÉRATIONNEL\n" +
		"Classification : CONFIDENTIEL\n" +
		"Dernière synchronisation : 2026-06-14  03:41\n\n" +
		"──────────────────────────────────────────\n" +
		"ASSETS — STATUTS\n\n" +
		"  ASSET_01 ............. [EXPURGÉ]\n" +
		"  ASSET_02 ............. [EXPURGÉ]\n" +
		"  ASSET_03 ............. INACTIF\n" +
		"  ASSET_04 ............. COMPROMIS\n" +
		"  ASSET_05 ............. [EXPURGÉ]\n" +
		"  ASSET_06 ............. ACTIF / handler : UNKNOWN_▓▓▓\n" +
		"  ASSET_07 ............. ACTIF / handler : UNKNOWN_▓▓▓\n" +
		"                         acquisition démarrée : 14/10\n" +
		"                         phase : 1  →  PHASE 2 EN ATTENTE\n\n" +
		"──────────────────────────────────────────\n" +
		"INFRASTRUCTURE COMPROMISE\n\n" +
		"  nexcorp-srv-01     [ ACCÈS CONFIRMÉ ]\n" +
		"  nexcorp-intranet   [ EN COURS       ]\n" +
		"  cible_B            [ [EXPURGÉ]      ]\n" +
		"  cible_C            [ [EXPURGÉ]      ]\n\n" +
		"──────────────────────────────────────────\n" +
		"PROCHAINE ÉTAPE\n\n" +
		"  PHASE 2 — activation sur signal handler.\n" +
		"  Délai estimé : imminent.\n" +
		"  Détails : [EXPURGÉ]\n\n" +
		"──────────────────────────────────────────\n" +
		"AVERTISSEMENT SYSTÈME\n" +
		"  Ce fichier est surveillé en lecture.\n" +
		"  Toute consultation non autorisée\n" +
		"  déclenche une alerte niveau 3.",
	"/data/confidentiel/access.log":
		"[2026-06-29 00:58:11] sshd: Failed password for admin from 203.0.113.47\n" +
		"[2026-06-29 00:58:14] sshd: Failed password for admin from 203.0.113.47\n" +
		"[2026-06-29 00:58:19] sshd: Failed password for admin from 203.0.113.47\n" +
		"[2026-06-29 01:13:55] sshd: Accepted password for admin from 10.13.37.42\n" +
		"[2026-06-29 01:14:02] admin: cd /data/confidentiel",
	"/data/confidentiel/archive_2025.tar.gz":
		"[ERREUR] Fichier binaire — utiliser 'tar tf' pour lister le contenu.",
	"/etc/passwd":
		"root:x:0:0:root:/root:/bin/bash\n" +
		"admin:x:1000:1000:NexCorp Admin:/home/admin:/bin/bash\n" +
		"www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin\n" +
		"nexcorp-svc:x:1001:1001:Service Account:/home/nexcorp-svc:/bin/bash",
	"/etc/hostname":
		"nexcorp-srv-01",
	"/etc/shadow":
		"cat: /etc/shadow: Permission denied",
	"/var/log/auth.log":
		"[2026-06-29 01:13:55] sshd: Accepted password for admin from 10.13.37.42\n" +
		"[2026-06-29 01:14:22] sshd: session opened for user admin\n" +
		"[2026-06-29 01:14:22] PAM: pam_unix(sshd:session): session opened for user admin",
	"/var/log/syslog":
		"[2026-06-29 00:00:01] kernel: NexCorp Security Layer v3.2.1 — ACTIVE\n" +
		"[2026-06-29 01:13:00] firewall: Connexion interne autorisée 10.13.37.42:22\n" +
		"[2026-06-29 01:14:00] IDS: [ALERTE] Activité anormale détectée — /data/confidentiel\n" +
		"[2026-06-29 01:14:01] IDS: Analyse en cours... origine: 10.13.37.42",
}


func run_remote_command(command: String, args: Array[String]):
	match command:
		"ls":       _remote_ls(args)
		"cd":       _remote_cd(args)
		"pwd":      print_line(remote_path)
		"cat":      _remote_cat(args)
		"find":     _remote_find(args)
		"grep":     _remote_grep(args)
		"tar":      _remote_tar(args)
		"md5sum":   _remote_md5sum(args)
		"whoami":   print_line(ssh_user)
		"hostname": print_line("nexcorp-srv-01")
		"uname":    print_line("Linux nexcorp-srv-01 5.15.0-nexcorp #1 SMP x86_64 GNU/Linux")
		"clear":    display.clear()
		"ps":
			print_line("  PID TTY          TIME CMD", "yellow")
			print_line("    1 ?        00:00:00 systemd", "white")
			print_line("  422 ?        00:00:00 sshd", "white")
			print_line("  891 pts/0    00:00:00 bash", "white")
			print_line("  892 pts/0    00:00:00 ps", "white")
		"history":
			for line in REMOTE_FILES["/home/admin/.bash_history"].split("\n"):
				if line != "":
					print_line("  " + line, "gray")
		"exit":
			_ssh_disconnect()
		_:
			print_line("bash: %s: command not found" % command, "red")


func _remote_ls(args: Array[String]):
	var show_long := false
	for a in args:
		if "l" in a and a.begins_with("-"):
			show_long = true
	var target := remote_path
	for a in args:
		if not a.begins_with("-"):
			target = _remote_resolve(a)
			break
	var entries: Array = []
	if REMOTE_FS.has(target):
		entries = REMOTE_FS[target]
	elif _tar_dirs.has(target):
		entries = _tar_dirs[target]
	else:
		print_line("ls: cannot access '%s': No such file or directory" % target, "red")
		return
	if entries.is_empty():
		return
	var base: String = "" if target == "/" else target
	if show_long:
		print_line("total %d" % entries.size(), "gray")
		for e in entries:
			var full: String = base + "/" + e
			var is_dir := REMOTE_FS.has(full) or _tar_dirs.has(full)
			if is_dir:
				print_line("drwxr-x---  2 admin nexcorp  4096 Jun 29 01:14 [color=deepskyblue]%s/[/color]" % e)
			elif e.ends_with(".enc"):
				print_line("-rw-------  1 admin nexcorp  4096 Jun 28 23:59 [color=yellow]%s[/color]" % e)
			else:
				print_line("-rw-r--r--  1 admin nexcorp  1024 Jun 28 23:59 [color=lightgreen]%s[/color]" % e)
	else:
		var out: Array[String] = []
		for e in entries:
			var full: String = base + "/" + e
			if REMOTE_FS.has(full) or _tar_dirs.has(full):
				out.append("[color=deepskyblue]%s/[/color]" % e)
			elif e.ends_with(".enc"):
				out.append("[color=yellow]%s[/color]" % e)
			else:
				out.append("[color=lightgreen]%s[/color]" % e)
		display.append_text("  ".join(out) + "\n")
		scroll_bottom()


func _remote_cd(args: Array[String]):
	if args.is_empty():
		remote_path = "/home/admin"
		update_prompt_label()
		return
	var target := _remote_resolve(args[0])
	if REMOTE_FS.has(target) or _tar_dirs.has(target):
		remote_path = target
		update_prompt_label()
	else:
		print_line("bash: cd: %s: No such file or directory" % args[0], "red")


func _remote_cat(args: Array[String]):
	if args.is_empty():
		print_line("Usage: cat <file>", "red")
		return
	for fname in args:
		var full := _remote_resolve(fname)
		if REMOTE_FS.has(full) or _tar_dirs.has(full):
			print_line("cat: %s: Is a directory" % fname, "red")
			continue
		var content := ""
		if REMOTE_FILES.has(full):
			content = REMOTE_FILES[full]
		elif _tar_extracted.has(full):
			content = _tar_extracted[full]
		else:
			print_line("cat: %s: No such file or directory" % fname, "red")
			continue
		if full == "/etc/shadow":
			print_line("cat: /etc/shadow: Permission denied", "red")
			continue
		for line in content.split("\n"):
			print_line(line)


func _remote_find(args: Array[String]) -> void:
	var search_root := remote_path
	var name_filter := ""
	var type_filter := ""
	var i := 0
	while i < args.size():
		var a := args[i]
		if (a == "-name" or a == "--name") and i + 1 < args.size():
			name_filter = args[i + 1].strip_edges().trim_prefix("'").trim_suffix("'").trim_prefix('"').trim_suffix('"')
			i += 2
		elif (a == "-type" or a == "--type") and i + 1 < args.size():
			type_filter = args[i + 1]
			i += 2
		elif not a.begins_with("-"):
			search_root = _remote_resolve(a)
			i += 1
		else:
			i += 1
	if not REMOTE_FS.has(search_root):
		print_line("find: '%s': No such file or directory" % search_root, "red")
		return
	var results: Array[String] = []
	_rfind_recursive(search_root, name_filter, type_filter, results)
	for r in results:
		if r.ends_with(".enc"):
			print_line("[color=yellow]%s[/color]" % r)
		elif REMOTE_FS.has(r) or _tar_dirs.has(r):
			print_line("[color=deepskyblue]%s[/color]" % r)
		else:
			print_line(r)


func _rfind_recursive(path: String, name_filter: String, type_filter: String, results: Array[String]) -> void:
	var entries: Array = REMOTE_FS.get(path, [])
	var base: String = "" if path == "/" else path
	for e in entries:
		var full: String = base + "/" + e
		var is_dir := REMOTE_FS.has(full)
		var matches_name := name_filter.is_empty() or _glob_match(e, name_filter)
		var matches_type := type_filter.is_empty() or (type_filter == "d" and is_dir) or (type_filter == "f" and not is_dir)
		if matches_name and matches_type:
			results.append(full)
		if is_dir:
			_rfind_recursive(full, name_filter, type_filter, results)


func _glob_match(text: String, pattern: String) -> bool:
	if not pattern.contains("*"):
		return text == pattern
	if pattern.begins_with("*"):
		return text.ends_with(pattern.substr(1))
	if pattern.ends_with("*"):
		return text.begins_with(pattern.substr(0, pattern.length() - 1))
	return text == pattern


func _remote_grep(args: Array[String]) -> void:
	if args.size() < 2:
		print_line("Usage: grep <pattern> <file...>", "red")
		return
	var pattern := args[0].to_lower()
	var found_any := false
	for i in range(1, args.size()):
		var full := _remote_resolve(args[i])
		var content := ""
		if REMOTE_FILES.has(full):
			content = REMOTE_FILES[full]
		elif _tar_extracted.has(full):
			content = _tar_extracted[full]
		else:
			print_line("grep: %s: No such file or directory" % args[i], "red")
			continue
		for line in content.split("\n"):
			if pattern in line.to_lower():
				print_line(line)
				found_any = true


func _remote_tar(args: Array[String]) -> void:
	if args.is_empty():
		print_line("Usage: tar [tf|xf] <archive.tar.gz>", "red")
		return
	var flags := ""
	var archive_arg := ""
	for a in args:
		if a.begins_with("-"):
			flags += a.substr(1)
		elif flags.is_empty():
			flags = a
		else:
			archive_arg = a
	if archive_arg.is_empty():
		for a in args:
			if a.ends_with(".tar.gz") or a.ends_with(".tgz"):
				archive_arg = a
				break
	if archive_arg.is_empty():
		print_line("tar: archive non spécifiée", "red")
		return
	var full_path := _remote_resolve(archive_arg)
	if not REMOTE_FILES.has(full_path):
		print_line("tar: %s: fichier introuvable" % archive_arg, "red")
		return
	var listing := [
		"archive_2025/",
		"archive_2025/infra_nexcorp.txt",
		"archive_2025/contacts_internes.csv",
		"archive_2025/planning_ops.txt",
	]
	if "t" in flags:
		for item in listing:
			if item.ends_with("/"):
				print_line("[color=deepskyblue]%s[/color]" % item)
			else:
				print_line(item, "gray")
	elif "x" in flags:
		print_line("tar: extraction vers ./archive_2025/", "gray")
		for item in listing:
			if not item.ends_with("/"):
				print_line("  inflating: " + item, "gray")
		var dir_base: String = "" if remote_path == "/" else remote_path
		var ext_dir: String = dir_base + "/archive_2025"
		_tar_dirs[ext_dir] = ["infra_nexcorp.txt", "contacts_internes.csv", "planning_ops.txt"]
		_tar_extracted[ext_dir + "/infra_nexcorp.txt"] = \
			"NEXCORP — CARTOGRAPHIE INFRASTRUCTURE (INTERNE)\n\n" + \
			"Serveurs exposés :\n" + \
			"  10.13.37.1   nexcorp-srv-01   SSH:22  HTTP:80\n" + \
			"  10.13.37.2   nexcorp-intranet  HTTP:8080  [AUTH REQUISE]\n" + \
			"  10.13.37.5   nexcorp-backup    FTP:21   [DEPRECATED]\n\n" + \
			"Accès VPN : nexcorp_vpn (voir docs RH)\n" + \
			"Politique : pas de connexion directe externe autorisée.\n\n" + \
			"Dernière mise à jour : sept. 2025"
		_tar_extracted[ext_dir + "/contacts_internes.csv"] = \
			"nom,poste,email,acces\n" + \
			"J. Laurent,CFO,j.laurent@nexcorp.fr,ADMIN\n" + \
			"M. Fontaine,DSI,m.fontaine@nexcorp.fr,ADMIN\n" + \
			"A. Mercer,Responsable sécurité,a.mercer@nexcorp.fr,LEVEL2\n" + \
			"P. Dubois,Développeur,p.dubois@nexcorp.fr,STANDARD\n" + \
			"...(38 entrées supplémentaires)"
		_tar_extracted[ext_dir + "/planning_ops.txt"] = \
			"PLANNING OPÉRATIONNEL — CONFIDENTIEL\n\n" + \
			"T4 2025 :\n" + \
			"  - Audit sécurité interne (prestataire externe)\n" + \
			"  - Migration données vers nexcorp-intranet\n" + \
			"  - Révision politique accès LEVEL2+\n\n" + \
			"T1 2026 :\n" + \
			"  - [EXPURGÉ]\n" + \
			"  - [EXPURGÉ]\n\n" + \
			"Contact : m.fontaine@nexcorp.fr"
		print_line("Extraction terminée.", "green")
	else:
		print_line("tar: option(s) non reconnue(s) : %s" % flags, "red")


func _remote_md5sum(args: Array[String]):
	if args.is_empty():
		print_line("Usage: md5sum <file>", "red")
		return
	for fname in args:
		var full := _remote_resolve(fname)
		if REMOTE_FS.has(full):
			print_line("md5sum: %s: Is a directory" % fname, "red")
			continue
		if not REMOTE_FILES.has(full):
			print_line("md5sum: %s: No such file or directory" % fname, "red")
			continue
		print_line("a3f8c2e1d94b7f05a3f8c2e1d94b7f05  %s" % fname)


func _remote_resolve(path: String) -> String:
	if path.begins_with("/"):
		return path.rstrip("/") if path.length() > 1 else "/"
	if path == "..":
		if remote_path == "/": return "/"
		var p := remote_path.rsplit("/", true, 1)
		return p[0] if p[0] != "" else "/"
	if path == "." or path == "":
		return remote_path
	if path == "~":
		return "/home/admin"
	var base := "" if remote_path == "/" else remote_path
	return base + "/" + path


func _ssh_disconnect():
	print_line("logout", "gray")
	print_line("Connection to %s closed." % ssh_host, "gray")
	ssh_connected = false
	ssh_host = ""
	ssh_user = ""
	remote_path = "/home/admin"
	update_prompt_label()


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
