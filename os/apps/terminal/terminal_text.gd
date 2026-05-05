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
var is_typing := false
var interrupted := false

var home_dir: Node  # /home/hacker

# Pour le support des pipes
var capture_mode := false
var capture_buffer: Array[String] = []

const FOLDER_SCRIPT := "res://os/apps/terminal/foldernode.gd"
const FILE_SCRIPT   := "res://os/apps/terminal/filenode.gd"

const COMMANDS := [
	"cat", "cd", "chmod", "clear", "cp", "date", "echo", "exit",
	"find", "grep", "head", "help", "history", "hostname", "kill",
	"ls", "man", "mkdir", "mv", "nmap", "ps", "pwd", "rm",
	"ssh", "sudo", "tail", "touch", "tree", "uname", "wc", "whoami"
]


# ─────────────────────────────────────────────────
# FILESYSTEM BUILDER
# ─────────────────────────────────────────────────
func _create_dir(parent: Node, dir_name: String) -> Node:
	var folder := Node.new()
	folder.name = dir_name
	folder.set_script(load(FOLDER_SCRIPT))
	parent.add_child(folder)
	return folder


func _create_file(parent: Node, filename: String, content: String) -> void:
	var file := Node.new()
	file.name = filename.replace(".", "_").replace("-", "_")
	file.set_script(load(FILE_SCRIPT))
	file.set("filename", filename)
	file.set("content", content)
	parent.add_child(file)


func _build_filesystem() -> void:
	# Purge les éventuels noeuds hérités du .tscn
	for child in filesystem_root.get_children():
		child.free()

	# ── /bin ─────────────────────────────────────
	var bin := _create_dir(filesystem_root, "bin")
	for b in ["bash", "sh", "ls", "cat", "grep", "find", "cp", "mv", "rm", "mkdir", "touch", "chmod", "echo", "date", "uname", "whoami", "hostname", "ps", "kill", "nmap", "ssh", "curl", "wget"]:
		_create_file(bin, b, "ELF 64-bit LSB executable, x86-64, dynamically linked")

	# ── /dev ─────────────────────────────────────
	var dev := _create_dir(filesystem_root, "dev")
	_create_file(dev, "null",   "")
	_create_file(dev, "zero",   "\\x00\\x00\\x00\\x00")
	_create_file(dev, "random", "[kernel entropy pool]")
	_create_file(dev, "stdin",  "")
	_create_file(dev, "stdout", "")
	_create_file(dev, "stderr", "")
	_create_file(dev, "tty",    "")

	# ── /etc ─────────────────────────────────────
	var etc := _create_dir(filesystem_root, "etc")
	_create_file(etc, "hostname", "eax37")
	_create_file(etc, "hosts",
		"127.0.0.1\tlocalhost\n" +
		"::1\t\tlocalhost ip6-localhost\n" +
		"10.13.37.1\ttarget.internal\n" +
		"10.0.0.1\tgateway")
	_create_file(etc, "resolv.conf",
		"nameserver 8.8.8.8\n" +
		"nameserver 1.1.1.1\n" +
		"search local")
	_create_file(etc, "os-release",
		"NAME=\"EAX OS\"\n" +
		"VERSION=\"2.3.1 (Phantom)\"\n" +
		"ID=eax\n" +
		"PRETTY_NAME=\"EAX OS 2.3.1 (Phantom)\"\n" +
		"BUILD_ID=20260501")
	_create_file(etc, "passwd",
		"root:x:0:0:root:/root:/bin/bash\n" +
		"daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin\n" +
		"www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin\n" +
		"hacker:x:1000:1000:hacker,,,:/home/hacker:/bin/bash")
	_create_file(etc, "shadow",   "root:!:19478:0:99999:7:::\nhacker:$6$xyz...:19478:0:99999:7:::")
	_create_file(etc, "group",
		"root:x:0:\n" +
		"sudo:x:27:hacker\n" +
		"docker:x:999:hacker\n" +
		"hacker:x:1000:")
	_create_file(etc, "shells",   "/bin/bash\n/bin/sh\n/usr/bin/bash")
	_create_file(etc, "bash.bashrc",
		"# System-wide bashrc\n" +
		"export PS1='\\u@\\h:\\w\\$ '\n" +
		"alias ll='ls -la'\n" +
		"alias la='ls -A'\n" +
		"alias grep='grep --color=auto'")

	# ── /home/hacker ─────────────────────────────
	var home_root := _create_dir(filesystem_root, "home")
	var hacker    := _create_dir(home_root, "hacker")
	home_dir = hacker

	_create_file(hacker, ".bashrc",
		"# ~/.bashrc\n" +
		"export PATH=/usr/local/bin:/usr/bin:/bin\n" +
		"export TERM=xterm-256color\n" +
		"alias ll='ls -la'\n" +
		"alias la='ls -A'\n" +
		"alias grep='grep --color=auto'")
	_create_file(hacker, ".profile",
		"# ~/.profile\n" +
		"if [ -f ~/.bashrc ]; then\n" +
		"    . ~/.bashrc\n" +
		"fi")
	_create_file(hacker, ".bash_history",
		"ls -la\n" +
		"cat /etc/passwd\n" +
		"nmap 10.13.37.1\n" +
		"grep -r password /etc/\n" +
		"ssh root@10.13.37.1\n" +
		"cat documents/password.txt\n" +
		"whoami")

	var docs := _create_dir(hacker, "documents")
	_create_file(docs, "password.txt", "mysuperpassword")
	_create_file(docs, "note.txt",
		"Don't forget to pay the rent.\n" +
		"The package has been delivered.\n" +
		"Code: see password file.")

	# ── /proc ────────────────────────────────────
	var proc := _create_dir(filesystem_root, "proc")
	_create_file(proc, "version",
		"Linux version 5.15.0-eax (gcc version 11.3.0 (GCC)) #1 SMP Wed May 1 20:00:00 UTC 2026")
	_create_file(proc, "cpuinfo",
		"processor\t: 0\n" +
		"vendor_id\t: GenuineIntel\n" +
		"model name\t: Intel(R) Core(TM) i7-9750H CPU @ 2.60GHz\n" +
		"cpu MHz\t\t: 2600.000\n" +
		"cache size\t: 12288 KB\n" +
		"cpu cores\t: 6")
	_create_file(proc, "meminfo",
		"MemTotal:\t   8388608 kB\n" +
		"MemFree:\t   2097152 kB\n" +
		"MemAvailable:\t   4194304 kB\n" +
		"Buffers:\t    262144 kB\n" +
		"Cached:\t\t   1572864 kB\n" +
		"SwapTotal:\t   2097148 kB\n" +
		"SwapFree:\t   2097148 kB")
	_create_file(proc, "uptime", "3721.55 7244.12")

	# ── /root ────────────────────────────────────
	var root_home := _create_dir(filesystem_root, "root")
	_create_file(root_home, ".bashrc",
		"# root's .bashrc\n" +
		"export PS1='\\[\\e[1;31m\\]\\u@\\h:\\w# \\[\\e[0m\\]'\n" +
		"alias rm='rm -i'")

	# ── /tmp ─────────────────────────────────────
	_create_dir(filesystem_root, "tmp")

	# ── /usr ─────────────────────────────────────
	var usr       := _create_dir(filesystem_root, "usr")
	var usr_bin   := _create_dir(usr, "bin")
	_create_file(usr_bin, "python3", "ELF 64-bit LSB executable, x86-64, dynamically linked")
	_create_file(usr_bin, "curl",    "ELF 64-bit LSB executable, x86-64, dynamically linked")
	_create_file(usr_bin, "wget",    "ELF 64-bit LSB executable, x86-64, dynamically linked")
	_create_file(usr_bin, "vim",     "ELF 64-bit LSB executable, x86-64, dynamically linked")
	var usr_local := _create_dir(usr, "local")
	_create_dir(usr_local, "bin")
	var usr_share := _create_dir(usr, "share")
	_create_dir(usr_share, "man")

	# ── /var ─────────────────────────────────────
	var var_dir := _create_dir(filesystem_root, "var")
	var var_log := _create_dir(var_dir, "log")
	_create_file(var_log, "auth.log",
		"May  1 21:55:03 eax37 sshd[1337]: Failed password for root from 185.220.101.47 port 54231 ssh2\n" +
		"May  1 22:01:14 eax37 sshd[1338]: Failed password for root from 185.220.101.47 port 54232 ssh2\n" +
		"May  1 22:08:31 eax37 login[412]: pam_unix(login:auth): authentication failure; logname= uid=0 euid=0\n" +
		"May  1 22:10:05 eax37 login[412]: pam_unix(login:session): session opened for user hacker")
	_create_file(var_log, "syslog",
		"May  1 22:00:00 eax37 kernel: [    0.000000] Linux version 5.15.0-eax\n" +
		"May  1 22:00:01 eax37 systemd[1]: Started EAX OS 2.3.1.\n" +
		"May  1 22:01:00 eax37 systemd[1]: Started Docker Application Container Engine.\n" +
		"May  1 22:05:33 eax37 CRON[987]: (hacker) CMD (/home/hacker/.local/sync.sh)\n" +
		"May  1 22:10:00 eax37 systemd[1]: Started session-1.scope.")
	_create_file(var_log, "dmesg",
		"[    0.000000] Linux version 5.15.0-eax\n" +
		"[    0.100000] BIOS-e820: [mem 0x0000000000000000-0x000000000009efff] usable\n" +
		"[    1.234567] EXT4-fs (sda1): mounted filesystem with ordered data mode\n" +
		"[    2.100000] eth0: renamed from veth3a2b1c\n" +
		"[    3.000000] IPv6: ADDRCONF(NETDEV_CHANGE): eth0: link becomes ready")
	var var_cache := _create_dir(var_dir, "cache")
	_create_dir(var_cache, "apt")


func _ready():
	_build_filesystem()
	current_dir = filesystem_root
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

	# Démarrer dans /home/hacker comme Docker
	var start_res := _resolve_path_parts(["home", "hacker"], filesystem_root, [])
	if start_res["node"] != null:
		current_dir = start_res["node"]
		path_stack.assign(start_res["stack"])

	update_prompt_label()
	_print_welcome_async()


func _print_welcome_async():
	await print_welcome()


# ─────────────────────────────────────────────────
# PROMPT / PATH
# ─────────────────────────────────────────────────
func get_terminal_path() -> String:
	if current_dir == filesystem_root:
		return "/"

	var p := ""
	for i in range(1, path_stack.size()):
		p += "/" + path_stack[i].name
	p += "/" + current_dir.name

	if p == "/home/hacker":
		return "~"
	if p.begins_with("/home/hacker/"):
		return "~" + p.substr("/home/hacker".length())
	return p


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

	# Raccourcis Ctrl (actifs même pendant is_typing)
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

	# Chaînage avec ';'
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
# PIPELINE (support du pipe |)
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
			# Capturer la sortie du segment courant
			capture_mode = true
			capture_buffer = []
			run_command(seg)
			capture_mode = false
			piped_lines = capture_buffer.duplicate()
		else:
			# Dernier segment : traiter l'entrée pipée
			var parts: PackedStringArray = seg.split(" ", false)
			var fcmd: String = parts[0] if parts.size() > 0 else ""
			var fargs: Array[String] = []
			for j in range(1, parts.size()):
				fargs.append(parts[j])

			match fcmd:
				"grep":
					_piped_grep(fargs, piped_lines)
				"wc":
					_piped_wc(piped_lines)
				"head":
					var n: int = int(fargs[0]) if fargs.size() > 0 and fargs[0].is_valid_int() else 10
					for j in range(min(n, piped_lines.size())):
						print_line(piped_lines[j])
				"tail":
					var n: int = int(fargs[0]) if fargs.size() > 0 and fargs[0].is_valid_int() else 10
					var start: int = max(0, piped_lines.size() - n)
					for j in range(start, piped_lines.size()):
						print_line(piped_lines[j])
				_:
					run_command(seg)


func _piped_grep(args: Array[String], lines: Array[String]):
	if args.is_empty():
		print_line("grep: missing pattern", "red")
		return
	var keyword := args[0]
	var found := false
	for line in lines:
		if keyword.to_lower() in line.to_lower():
			var highlighted: String = line.replace(keyword, "[color=red]%s[/color]" % keyword)
			display.append_text("[color=white]%s[/color]\n" % highlighted)
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
		# Afficher toutes les commandes
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
		for child in current_dir.get_children():
			var entry_name: String = get_entry_name(child)
			var display_name: String = entry_name + ("/" if is_folder(child) else "")
			if entry_name != "" and entry_name.begins_with(target):
				matches.append(display_name)

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
# HELPERS FILESYSTEM
# ─────────────────────────────────────────────────
func is_folder(node: Node) -> bool:
	return node.get("is_folder") == true


func get_entry_name(node: Node) -> String:
	if not is_folder(node):
		return node.get("filename") if node.get("filename") != null else node.name
	return node.name


func strip_bbcode(text: String) -> String:
	var result := ""
	var in_tag := false
	for c in text:
		if c == "[":
			in_tag = true
		elif c == "]":
			in_tag = false
		elif not in_tag:
			result += c
	return result


func _resolve_path_parts(parts: Array, start_node: Node, start_stack: Array) -> Dictionary:
	var node = start_node
	var stack = start_stack.duplicate()
	for part in parts:
		if part == ".." or part == "..":
			if not stack.is_empty():
				node = stack.pop_back()
			else:
				node = filesystem_root
		elif part == "." or part == "":
			pass
		else:
			var found := false
			for child in node.get_children():
				if is_folder(child) and child.name == part:
					stack.append(node)
					node = child
					found = true
					break
			if not found:
				return {"node": null, "stack": []}
	return {"node": node, "stack": stack}


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
		"help":      cmd_help()
		"ls":        cmd_ls(args)
		"cd":        cmd_cd(args)
		"pwd":       cmd_pwd()
		"cat":       cmd_cat(args)
		"tree":      cmd_tree(current_dir, "")
		"grep":      cmd_grep(args)
		"nmap":      cmd_nmap(args)
		"ssh":       cmd_ssh(args)
		"clear":     display.clear()
		"echo":      print_line(" ".join(args))
		"whoami":    print_line(user)
		"hostname":  print_line(host)
		"exit":      _close_app()
		"mkdir":     cmd_mkdir(args)
		"touch":     cmd_touch(args)
		"rm":        cmd_rm(args)
		"mv":        cmd_mv(args)
		"cp":        cmd_cp(args)
		"history":   cmd_history()
		"date":      cmd_date()
		"uname":     cmd_uname(args)
		"man":       cmd_man(args)
		"wc":        cmd_wc(args)
		"head":      cmd_head(args)
		"tail":      cmd_tail(args)
		"find":      cmd_find(args)
		"ps":        cmd_ps()
		"kill":      cmd_kill(args)
		"sudo":
			print_line("%s is not in the sudoers file. This incident will be reported." % user, "red")
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


# ── help ──────────────────────────────────────────
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
		["man <cmd>",        "Show command manual"],
		["ps",               "List running processes"],
		["whoami / hostname","User and host info"],
		["clear",            "Clear terminal"],
		["exit",             "Close terminal"],
	]
	for item in cmds:
		print_line("  %-22s %s" % [item[0], item[1]], "gray")
	print_line("", "")
	print_line("Shortcuts:  Ctrl+C interrupt   Ctrl+L clear   Ctrl+U erase line   Ctrl+A/E sol/eol", "#5a5a6e")
	print_line("Pipes:      ls | grep foo       cat file | wc", "#5a5a6e")
	print_line("Chain:      pwd; ls; whoami", "#5a5a6e")


# ── ls ────────────────────────────────────────────
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

	var target_dir := current_dir
	if path_arg != "":
		var res := _resolve_path_parts(
			(path_arg if path_arg.begins_with("/") else path_arg).split("/", false),
			filesystem_root if path_arg.begins_with("/") else current_dir,
			[] if path_arg.begins_with("/") else path_stack
		)
		if res["node"] == null or not is_folder(res["node"]):
			print_line("ls: cannot access '%s': No such file or directory" % path_arg, "red")
			return
		target_dir = res["node"]

	var all_children: Array[Node] = target_dir.get_children()
	var entries: Array[Node] = []
	for child in all_children:
		if show_hidden or not get_entry_name(child).begins_with("."):
			entries.append(child)

	if entries.is_empty():
		if not capture_mode:
			print_line("(empty directory)", "gray")
		return

	if show_long or capture_mode:
		if show_long:
			print_line("total %d" % entries.size(), "gray")
		for child in entries:
			if is_folder(child):
				var n: String = str(child.name) + "/"
				if capture_mode:
					capture_buffer.append(n)
				else:
					print_line("drwxr-xr-x  2 %s %s  4096 May  1 22:10 [color=deepskyblue]%s[/color]" % [user, user, n], "white")
			elif child.has_method("get_content"):
				var n: String = get_entry_name(child)
				if capture_mode:
					capture_buffer.append(n)
				else:
					var file_size: int = (child.get_content() as String).length()
					print_line("-rw-r--r--  1 %s %s  %4d May  1 22:10 [color=lightgreen]%s[/color]" % [user, user, file_size, n], "white")
	else:
		var parts: Array[String] = []
		for child in entries:
			if is_folder(child):
				parts.append("[color=deepskyblue]%s/[/color]" % child.name)
			elif child.has_method("get_content"):
				parts.append("[color=lightgreen]%s[/color]" % get_entry_name(child))
		if not parts.is_empty():
			display.append_text("  ".join(parts) + "\n")
			scroll_bottom()


# ── cd ────────────────────────────────────────────
func cmd_cd(args: Array[String]):
	if args.is_empty():
		current_dir = filesystem_root
		path_stack.clear()
		return

	var dir := args[0]

	if dir == "/":
		current_dir = filesystem_root
		path_stack.clear()
		return

	if dir == "~":
		var home_res := _resolve_path_parts(["home", "hacker"], filesystem_root, [])
		if home_res["node"] != null:
			current_dir = home_res["node"]
			path_stack.assign(home_res["stack"])
		return

	var is_abs := dir.begins_with("/")
	var parts  := dir.split("/", false)
	var res    := _resolve_path_parts(
		parts,
		filesystem_root if is_abs else current_dir,
		[]              if is_abs else path_stack
	)

	if res["node"] == null:
		print_line("cd: no such directory: %s" % dir, "red")
		return
	if not is_folder(res["node"]):
		print_line("cd: not a directory: %s" % dir, "red")
		return

	current_dir = res["node"]
	path_stack.assign(res["stack"])


# ── pwd ───────────────────────────────────────────
func cmd_pwd():
	var p := get_terminal_path()
	print_line(p)
	if capture_mode and not capture_buffer.has(p):
		capture_buffer.append(p)


# ── cat ───────────────────────────────────────────
func cmd_cat(args: Array[String]):
	if args.is_empty():
		print_line("Usage: cat <file>", "red")
		return
	for fname in args:
		var found := false
		for child in current_dir.get_children():
			if child.has_method("get_content") and get_entry_name(child) == fname:
				if fname == "shadow" and user != "root":
					print_line("cat: %s: Permission denied" % fname, "red")
					found = true
					break
				for line: String in (child.get_content() as String).split("\n"):
					print_line(line)
				found = true
				break
		if not found:
			print_line("cat: %s: No such file or directory" % fname, "red")


# ── tree ──────────────────────────────────────────
func cmd_tree(node: Node, prefix: String):
	var children: Array[Node] = node.get_children()
	for i in range(children.size()):
		var child: Node = children[i]
		var is_last: bool = i == children.size() - 1
		var branch: String = "└── " if is_last else "├── "
		var next: String   = "    " if is_last else "│   "
		if is_folder(child):
			print_line(prefix + branch + child.name + "/", "deepskyblue")
			cmd_tree(child, prefix + next)
		elif child.has_method("get_content"):
			print_line(prefix + branch + get_entry_name(child), "lightgreen")


# ── grep ──────────────────────────────────────────
func cmd_grep(args: Array[String]):
	if args.is_empty():
		print_line("Usage: grep <pattern> [file]", "red")
		return

	var keyword  := args[0]
	var filename := args[1] if args.size() >= 2 else ""

	if filename != "":
		for child in current_dir.get_children():
			if child.has_method("get_content") and get_entry_name(child) == filename:
				var hit := false
				for line: String in (child.get_content() as String).split("\n"):
					if keyword in line:
						var hl: String = line.replace(keyword, "[color=red]%s[/color]" % keyword)
						print_line(hl)
						hit = true
				if not hit:
					print_line("(no match)", "gray")
				return
		print_line("grep: %s: No such file" % filename, "red")
		return

	# Sans fichier → cherche dans tous les fichiers du répertoire courant
	var found := false
	for child in current_dir.get_children():
		if child.has_method("get_content"):
			var content: String = child.get_content() as String
			if keyword in content:
				var fname: String = get_entry_name(child)
				for line: String in content.split("\n"):
					if keyword in line:
						var hl: String = line.replace(keyword, "[color=red]%s[/color]" % keyword)
						print_line("[color=yellow]%s[/color]: %s" % [fname, hl])
						found = true
	if not found:
		print_line("grep: no match for '%s'" % keyword, "gray")


# ── nmap ──────────────────────────────────────────
func cmd_nmap(args: Array[String]):
	if args.is_empty():
		print_line("Usage: nmap <target_ip>", "red")
		return

	interrupted = false
	is_typing   = true

	print_line("Starting Nmap 7.80 ( https://nmap.org ) at 2026-05-01 22:14", "gray")
	await get_tree().create_timer(0.5).timeout
	if interrupted: return

	print_line("Scanning %s..." % args[0], "gray")
	for _i in range(10):
		await get_tree().create_timer(0.2).timeout
		if interrupted: return
		display.append_text("[color=gray]#[/color]")
		scroll_bottom()
	display.append_text("\n")

	await get_tree().create_timer(0.5).timeout
	if interrupted: return

	print_line("Nmap scan report for %s" % args[0], "white")
	print_line("Host is up (0.0021s latency).", "gray")
	print_line("PORT     STATE  SERVICE", "yellow")
	print_line("22/tcp   open   ssh", "lightgreen")
	print_line("80/tcp   open   http", "lightgreen")
	print_line("443/tcp  open   https", "lightgreen")
	print_line("Nmap done: 1 IP address (1 host up) scanned in 2.54 seconds", "gray")
	is_typing = false


# ── ssh ───────────────────────────────────────────
func cmd_ssh(args: Array[String]):
	if args.is_empty():
		print_line("Usage: ssh [user@]host", "red")
		return

	interrupted = false
	is_typing   = true

	print_line("Connecting to %s..." % args[0], "gray")
	await get_tree().create_timer(1.5).timeout
	if interrupted: return

	print_line("ssh: connect to host %s port 22: Connection refused" % args[0], "red")
	is_typing = false


# ── mkdir ─────────────────────────────────────────
func cmd_mkdir(args: Array[String]):
	if args.is_empty():
		print_line("Usage: mkdir <directory>", "red")
		return

	for dir_name in args:
		for child in current_dir.get_children():
			if child.name == dir_name:
				print_line("mkdir: cannot create directory '%s': File exists" % dir_name, "red")
				continue
		var new_folder := Node.new()
		new_folder.name = dir_name
		new_folder.set_script(load("res://os/apps/terminal/foldernode.gd"))
		current_dir.add_child(new_folder)


# ── touch ─────────────────────────────────────────
func cmd_touch(args: Array[String]):
	if args.is_empty():
		print_line("Usage: touch <file>", "red")
		return

	for fname in args:
		var exists := false
		for child in current_dir.get_children():
			if get_entry_name(child) == fname:
				exists = true
				break
		if exists:
			continue  # touch ne fait rien si le fichier existe déjà

		var new_file := Node.new()
		new_file.name = fname.replace(".", "_")
		new_file.set_script(load("res://os/apps/terminal/filenode.gd"))
		new_file.set("filename", fname)
		new_file.set("content", "")
		current_dir.add_child(new_file)


# ── rm ────────────────────────────────────────────
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
		var found := false
		for child in current_dir.get_children():
			if get_entry_name(child) == target:
				if is_folder(child) and not recursive:
					print_line("rm: cannot remove '%s': Is a directory (use rm -r)" % target, "red")
				else:
					child.queue_free()
				found = true
				break
		if not found:
			print_line("rm: cannot remove '%s': No such file or directory" % target, "red")


# ── mv ────────────────────────────────────────────
func cmd_mv(args: Array[String]):
	if args.size() < 2:
		print_line("Usage: mv <source> <destination>", "red")
		return

	var src := args[0]
	var dst := args[1]

	for child in current_dir.get_children():
		if get_entry_name(child) == src:
			if is_folder(child):
				child.name = dst
			else:
				child.set("filename", dst)
				child.name = dst.replace(".", "_")
			return

	print_line("mv: cannot stat '%s': No such file or directory" % src, "red")


# ── cp ────────────────────────────────────────────
func cmd_cp(args: Array[String]):
	if args.size() < 2:
		print_line("Usage: cp <source> <destination>", "red")
		return

	var src := args[0]
	var dst := args[1]

	for child in current_dir.get_children():
		if child.has_method("get_content") and get_entry_name(child) == src:
			var new_file := Node.new()
			new_file.name = dst.replace(".", "_")
			new_file.set_script(load("res://os/apps/terminal/filenode.gd"))
			new_file.set("filename", dst)
			new_file.set("content", child.get_content())
			current_dir.add_child(new_file)
			return

	print_line("cp: cannot stat '%s': No such file or directory" % src, "red")


# ── history ───────────────────────────────────────
func cmd_history():
	if history.is_empty():
		print_line("(no history)", "gray")
		return
	for i in range(history.size()):
		print_line("  %4d  %s" % [i + 1, history[i]], "gray")


# ── date ──────────────────────────────────────────
func cmd_date():
	var dt := Time.get_datetime_dict_from_system()
	var days   := ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
	var months := ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
				   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	print_line("%s %s %2d %02d:%02d:%02d UTC %d" % [
		days[dt.weekday], months[dt.month - 1], dt.day,
		dt.hour, dt.minute, dt.second, dt.year
	])


# ── uname ─────────────────────────────────────────
func cmd_uname(args: Array[String]):
	if "-a" in args:
		print_line("EAX_CORE %s 2.3.1-eax #1 SMP 2026-05-01 x86_64 GNU/Linux" % host)
	elif "-r" in args:
		print_line("2.3.1-eax")
	else:
		print_line("EAX_CORE")


# ── man ───────────────────────────────────────────
func cmd_man(args: Array[String]):
	if args.is_empty():
		print_line("Usage: man <command>", "red")
		return

	var manuals := {
		"ls":     "ls [OPTION] [FILE]\n  List directory contents.\n  -l   long listing format",
		"cd":     "cd [DIR]\n  Change the current directory.\n  cd ~  go to root\n  cd .. go up",
		"cat":    "cat [FILE...]\n  Print file contents to stdout.",
		"grep":   "grep PATTERN [FILE]\n  Search for PATTERN in files.\n  Pipe support: ls | grep foo",
		"rm":     "rm [-r] NAME\n  Remove files or directories.\n  -r   remove directories recursively",
		"mkdir":  "mkdir DIR\n  Create directory.",
		"touch":  "touch FILE\n  Create empty file or update timestamp.",
		"mv":     "mv SOURCE DEST\n  Move or rename a file.",
		"cp":     "cp SOURCE DEST\n  Copy a file.",
		"find":   "find NAME\n  Search for files by name recursively.",
		"nmap":   "nmap TARGET\n  Network scanner. Ctrl+C to interrupt.",
		"ssh":    "ssh [user@]HOST\n  Remote login client.",
		"head":   "head [-N] FILE\n  Output first N lines (default 10).",
		"tail":   "tail [-N] FILE\n  Output last N lines (default 10).",
		"wc":     "wc [FILE]\n  Print line, word, and byte counts.",
		"history":"history\n  Display command history.",
		"date":   "date\n  Display current date and time.",
		"uname":  "uname [-a|-r]\n  Print system information.",
		"tree":   "tree\n  Recursive directory tree.",
		"echo":   "echo [TEXT]\n  Print text to stdout.",
		"ps":     "ps\n  Show running processes.",
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


# ── wc ────────────────────────────────────────────
func cmd_wc(args: Array[String]):
	if args.is_empty():
		print_line("Usage: wc <file>", "red")
		return

	var fname := args[0]
	for child in current_dir.get_children():
		if child.has_method("get_content") and get_entry_name(child) == fname:
			var content: String = child.get_content() as String
			var lines: int      = content.split("\n").size()
			var words: int      = content.split(" ", false).size()
			var chars: int      = content.length()
			print_line("%6d %6d %6d %s" % [lines, words, chars, fname])
			return
	print_line("wc: %s: No such file" % fname, "red")


# ── head ──────────────────────────────────────────
func cmd_head(args: Array[String]):
	var n      := 10
	var fname  := ""
	for arg in args:
		if arg.begins_with("-") and arg.substr(1).is_valid_int():
			n = int(arg.substr(1))
		else:
			fname = arg

	if fname.is_empty():
		print_line("Usage: head [-N] <file>", "red")
		return

	for child in current_dir.get_children():
		if child.has_method("get_content") and get_entry_name(child) == fname:
			var lines: PackedStringArray = (child.get_content() as String).split("\n")
			for i in range(min(n, lines.size())):
				print_line(lines[i])
			return
	print_line("head: %s: No such file" % fname, "red")


# ── tail ──────────────────────────────────────────
func cmd_tail(args: Array[String]):
	var n     := 10
	var fname := ""
	for arg in args:
		if arg.begins_with("-") and arg.substr(1).is_valid_int():
			n = int(arg.substr(1))
		else:
			fname = arg

	if fname.is_empty():
		print_line("Usage: tail [-N] <file>", "red")
		return

	for child in current_dir.get_children():
		if child.has_method("get_content") and get_entry_name(child) == fname:
			var lines: PackedStringArray = (child.get_content() as String).split("\n")
			var start: int = max(0, lines.size() - n)
			for i in range(start, lines.size()):
				print_line(lines[i])
			return
	print_line("tail: %s: No such file" % fname, "red")


# ── find ──────────────────────────────────────────
func cmd_find(args: Array[String]):
	var pattern := args[0] if not args.is_empty() else ""
	_find_recursive(filesystem_root, pattern, "/")


func _find_recursive(node: Node, pattern: String, path: String):
	for child in node.get_children():
		var ename := get_entry_name(child)
		var cpath := path + ename
		if pattern.is_empty() or pattern in ename or pattern == "*":
			print_line(cpath, "lightgreen")
		if is_folder(child):
			_find_recursive(child, pattern, cpath + "/")


# ── ps ────────────────────────────────────────────
func cmd_ps():
	print_line("  PID TTY          TIME CMD", "yellow")
	print_line("    1 pts/0    00:00:00 bash", "white")
	print_line("   42 pts/0    00:00:00 ps", "white")


# ── kill ──────────────────────────────────────────
func cmd_kill(args: Array[String]):
	if args.is_empty():
		print_line("Usage: kill <pid>", "red")
		return
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
