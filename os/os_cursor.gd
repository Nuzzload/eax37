# os_cursor.gd
# Attache à un Control "Cursor" dans OS.tscn
# Ce nœud doit être le DERNIER enfant de OS (au-dessus de tout)
# Layout : Full Rect, Mouse Filter : Ignore
extends Control

# Le point visible du curseur
var dot: Control


func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)  # déplacé uniquement via move_to()

	# Crée le curseur visuellement
	dot = Control.new()
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.size = Vector2(20, 20)
	add_child(dot)

	# Dessine le curseur custom via un sous-nœud
	var cursor_draw = _CursorDraw.new()
	cursor_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_draw.size = Vector2(20, 20)
	dot.add_child(cursor_draw)


func move_to(pos: Vector2):
	# Clamp dans les limites de l'écran
	var clamped = Vector2(
		clamp(pos.x, 0, size.x - 1),
		clamp(pos.y, 0, size.y - 1)
	)
	dot.position = clamped


# Classe interne pour dessiner le curseur
class _CursorDraw extends Control:
	func _draw():
		var c_main = Color("#e8e8f0")
		var c_accent = Color("#22cc66")
		var c_shadow = Color(0, 0, 0, 0.4)

		# Ombre
		draw_line(Vector2(2, 2), Vector2(2, 14), c_shadow, 1.5)
		draw_line(Vector2(2, 2), Vector2(9, 9), c_shadow, 1.5)
		draw_line(Vector2(9, 9), Vector2(7, 14), c_shadow, 1.5)

		# Flèche principale
		draw_line(Vector2(1, 1), Vector2(1, 13), c_main, 1.5)
		draw_line(Vector2(1, 1), Vector2(8, 8), c_main, 1.5)
		draw_line(Vector2(8, 8), Vector2(6, 13), c_main, 1.5)
		draw_line(Vector2(6, 13), Vector2(1, 13), c_main, 1.5)

		# Point accent couleur
		draw_rect(Rect2(1, 1, 3, 3), c_accent)
