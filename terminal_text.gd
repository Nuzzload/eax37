extends TextEdit

# Prompt du terminal
var prompt: String = "hacker@eax37>"

func _ready() -> void:
	# Affiche le prompt
	text = prompt + " "
	editable = true
	caret_blink = true
	# Curseur à la fin
	set_caret_line(get_line_count() - 1)
	set_caret_column(prompt.length())

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# Bloque Backspace avant le prompt
		if event.keycode == KEY_BACKSPACE:
			if get_caret_column() <= prompt.length():
				accept_event()

		# Entrée = exécuter la commande
		elif event.keycode == KEY_ENTER:
			run_command()
			accept_event()

func run_command() -> void:
	var last_line_index = get_line_count() - 1
	var line_text = get_line(last_line_index)
	# Supprime le prompt pour récupérer la commande
	var command = line_text.substr(prompt.length()).strip_edges()
	process_command(command)
	# Ajoute un nouveau prompt
	text += "\n" + prompt + " "
	# Place le curseur après le prompt
	set_caret_line(get_line_count() - 1)
	set_caret_column(prompt.length())

func process_command(command: String) -> void:
	if command == "":
		return
	match command:
		"help":
			print_line("Available commands: help ls")
		"ls":
			print_line("documents")
			print_line("password.txt")
		_:
			print_line("command not found")

func print_line(message: String) -> void:
	text += "\n" + message
