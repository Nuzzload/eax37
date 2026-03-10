extends TextEdit

# -----------------------
# Prompt Linux-style
# -----------------------
var user: String = "hacker"
var hostname: String = "eax37"

# -----------------------
# Root du filesystem (enfant direct de TerminalText)
# -----------------------
@onready var filesystem_root: Node = $filesystem_root
var current_node: Node
var path_stack: Array = [] # pile pour cd ..

# -----------------------
# Initialisation
# -----------------------
func _ready():
	if filesystem_root == null:
		print_line("ERROR: filesystem_root is null ! Check node path")
		return
	current_node = filesystem_root
	text = get_prompt()
	editable = true
	caret_blink = true
	set_caret_line(get_line_count() - 1)
	set_caret_column(get_caret_line_length(get_line_count() - 1))

# -----------------------
# Gestion de l'input
# -----------------------
func _gui_input(event):
	if event is InputEventKey and event.pressed:
		# Bloque Backspace avant le prompt
		if event.keycode == KEY_BACKSPACE:
			if get_caret_column() <= get_prompt().length():
				accept_event()
		elif event.keycode == KEY_ENTER:
			run_command()
			accept_event()

# -----------------------
# Prompt dynamique Linux-style (ignore filesystem_root)
# -----------------------
func get_prompt() -> String:
	var path = ""
	if path_stack.size() == 0:
		path = "/"
	else:
		for node in path_stack:
			if node != filesystem_root:
				path += node.name + "/"
		if current_node != filesystem_root:
			path += current_node.name
		if path == "":
			path = "/"
		else:
			path = "/" + path
	return "%s@%s:%s$ " % [user, hostname, path]

# -----------------------
# Exécuter la commande
# -----------------------
func run_command():
	if current_node == null:
		print_line("Error: current_node is null")
		return
	var last_line_index = get_line_count() - 1
	var line_text = get_line(last_line_index)
	var prompt_text = get_prompt()
	var command = line_text.substr(prompt_text.length()).strip_edges()
	process_command(command)
	text += "\n" + get_prompt()
	set_caret_line(get_line_count() - 1)
	set_caret_column(get_caret_line_length(get_line_count() - 1))

# -----------------------
# Traiter les commandes
# -----------------------
func process_command(command: String):
	if command == "":
		return
	var parts = command.split(" ")
	match parts[0]:
		"help":
			print_line("Available commands: help ls cd cat pwd exit")
		"ls":
			if current_node == null:
				print_line("Error: current_node is null")
				return
			for child in current_node.get_children():
				if child.has_method("get_content"): # fichier
					print_line(child.filename)
				else: # dossier
					print_line(child.name)
		"cd":
			if parts.size() < 2:
				print_line("cd: missing argument")
			elif parts[1] == "..":
				if path_stack.size() > 0:
					current_node = path_stack.pop_back()
				else:
					print_line("Already at root")
			elif parts[1] == ".":
				# cd . ne fait rien
				pass
			else:
				if current_node == null:
					print_line("Error: current_node is null")
					return
				var folder = current_node.get_node_or_null(parts[1])
				if folder != null and folder.get_child_count() >= 0:
					path_stack.append(current_node)
					current_node = folder
				else:
					print_line("cd: folder not found")
		"cat":
			if parts.size() < 2:
				print_line("cat: missing filename")
			else:
				if current_node == null:
					print_line("Error: current_node is null")
					return
				var found = false
				for child in current_node.get_children():
					if child.has_method("get_content") and child.filename == parts[1]:
						print_line(child.get_content())
						found = true
						break
				if not found:
					print_line("cat: file not found")
		"pwd":
			var path = ""
			if path_stack.size() == 0:
				path = "/"
			else:
				for node in path_stack:
					if node != filesystem_root:
						path += "/" + node.name
				if current_node != filesystem_root:
					path += "/" + current_node.name
				if path == "":
					path = "/"
			print_line(path)
		"exit":
			get_tree().quit()
		_:
			print_line("command not found")

# -----------------------
# Afficher une ligne
# -----------------------
func print_line(message: String):
	text += "\n" + message

# -----------------------
# Longueur d'une ligne pour le curseur
# -----------------------
func get_caret_line_length(line_idx: int) -> int:
	return get_line(line_idx).length()
