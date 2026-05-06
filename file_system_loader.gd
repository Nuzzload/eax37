# filesystem_loader.gd
# Autoload "GameFS"
extends Node


class FSNode extends RefCounted:
	var node_name: String
	var is_folder: bool
	var parent: FSNode
	var children: Array = []
	var _content: String = ""
	var hidden: bool = false

	func _init(p_name: String, p_is_folder: bool, p_content: String = ""):
		node_name = p_name
		is_folder = p_is_folder
		_content = p_content
		hidden = p_name.begins_with(".")

	func get_content() -> String:
		return _content

	func set_content(c: String) -> void:
		_content = c

	func get_filename() -> String:
		return node_name

	func add_child(node: FSNode) -> FSNode:
		node.parent = self
		children.append(node)
		return node

	func get_child(child_name: String) -> FSNode:
		for child in children:
			if child.node_name == child_name:
				return child
		return null

	func get_visible_children(show_hidden: bool = false) -> Array:
		if show_hidden:
			return children
		var result = []
		for child in children:
			if not child.hidden:
				result.append(child)
		return result

	func get_path() -> String:
		if parent == null:
			return ""
		var p = parent.get_path()
		return p + "/" + node_name if p != "" else node_name


# ── ÉTAT ──────────────────────────────────────────────────────────────────────
const FS_ROOT = "res://assets/filesystem/"

var _root: FSNode = null
var _home: FSNode = null


func _ready() -> void:
	_root = FSNode.new("", true)
	_load_directory(FS_ROOT, _root)
	_home = resolve_path("home/hacker", _root)
	if _home == null:
		_home = _root


# ── API PUBLIQUE ──────────────────────────────────────────────────────────────

func get_root() -> FSNode:
	return _root


func get_home() -> FSNode:
	return _home


func resolve_path(path: String, from: FSNode = null) -> FSNode:
	if from == null:
		from = _root
	if path == "" or path == ".":
		return from
	if path == "/":
		return _root
	if path == "~":
		return _home

	if path.begins_with("/"):
		return resolve_path(path.substr(1), _root)
	if path.begins_with("~/"):
		return resolve_path(path.substr(2), _home)

	var parts = path.split("/", false)
	var current = from
	for part in parts:
		if part == "..":
			if current.parent != null:
				current = current.parent
			else:
				current = _root
		elif part == "." or part == "":
			pass
		else:
			var next = current.get_child(part)
			if next == null:
				return null
			current = next
	return current


func create_file(parent: FSNode, p_name: String, content: String) -> FSNode:
	var existing = parent.get_child(p_name)
	if existing:
		existing.set_content(content)
		return existing
	var node = FSNode.new(p_name, false, content)
	parent.add_child(node)
	return node


func create_dir(parent: FSNode, p_name: String) -> FSNode:
	var existing = parent.get_child(p_name)
	if existing:
		return existing
	var node = FSNode.new(p_name, true)
	parent.add_child(node)
	return node


func delete_node(parent: FSNode, p_name: String) -> bool:
	for i in range(parent.children.size()):
		if parent.children[i].node_name == p_name:
			parent.children.remove_at(i)
			return true
	return false


# ── CHARGEMENT DEPUIS RES:// ──────────────────────────────────────────────────

func _load_directory(res_path: String, parent: FSNode) -> void:
	var dir = DirAccess.open(res_path)
	if not dir:
		return

	dir.include_hidden = true
	dir.list_dir_begin()
	var entry = dir.get_next()

	while entry != "":
		if entry == "." or entry == "..":
			entry = dir.get_next()
			continue

		var full_path = res_path + entry

		if dir.current_is_dir():
			var folder = FSNode.new(entry, true)
			parent.add_child(folder)
			_load_directory(full_path + "/", folder)
		else:
			if not entry.ends_with(".import") and not entry.ends_with(".uid"):
				var content = _read_file(full_path)
				var file_node = FSNode.new(entry, false, content)
				parent.add_child(file_node)

		entry = dir.get_next()

	dir.list_dir_end()


func _read_file(path: String) -> String:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return ""
	var content = file.get_as_text()
	file.close()
	return content.strip_edges()
