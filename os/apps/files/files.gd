# files_explorer.gd
extends Control

@onready var path_label: Label = $VBoxContainer/Toolbar/PathLabel
@onready var back_btn: Button = $VBoxContainer/Toolbar/BackBtn
@onready var grid_container: GridContainer = $VBoxContainer/ScrollContainer/GridContainer

var current_node: Node
var path_stack: Array[Node] = []
var root_node: Node

func _ready():
	_find_filesystem()
	_update_view()
	back_btn.pressed.connect(_on_back_pressed)


func _find_filesystem():
	# On cherche le terminal pour récupérer son filesystem_root par commodité
	# Ou on pourrait l'avoir en global. Ici on va chercher dans la scène OS.
	var os = get_tree().root.find_child("OS", true, false)
	if os:
		var terminal = os.find_child("Terminal", true, false)
		if terminal:
			root_node = terminal.get_node("filesystem_root")
			current_node = root_node


func _update_view():
	# Nettoie la grille
	for child in grid_container.get_children():
		child.queue_free()
	
	if not current_node:
		return
		
	path_label.text = _get_path_string()
	back_btn.disabled = path_stack.is_empty()

	for node in current_node.get_children():
		_create_icon(node)


func _get_path_string() -> String:
	var p = "~"
	for n in path_stack:
		if n != root_node:
			p += "/" + n.name
	if current_node != root_node:
		p += "/" + current_node.name
	return p


func _create_icon(node: Node):
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(80, 90)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var is_folder = node.get("is_folder") == true
	# Placeholder icons (on pourrait charger des vrais assets)
	if is_folder:
		icon.modulate = Color("#ccaa22") # Jaune pour dossier
	else:
		icon.modulate = Color("#e8e8f0") # Blanc pour fichier
		
	var label = Label.new()
	label.text = node.get("filename") if node.get("filename") != null else node.name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 10)
	
	vbox.add_child(icon)
	vbox.add_child(label)
	grid_container.add_child(vbox)
	
	vbox.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.double_click:
			if is_folder:
				path_stack.append(current_node)
				current_node = node
				_update_view()
			else:
				_open_file(node)
	)


func _on_back_pressed():
	if not path_stack.is_empty():
		current_node = path_stack.pop_back()
		_update_view()


func _open_file(node: Node):
	if node.has_method("get_content"):
		# On pourrait ouvrir un éditeur de texte, mais pour l'instant on simule
		print("Opening file: ", node.name)
		# TODO: Implémenter un TextEditor simplifié
