# room_scene.gd
# Attache ce script à un Node3D racine (scène principale)
# La scène terminal doit être dans res://terminal/terminal.tscn
extends Node3D

# Couleurs cyberpunk
const COL_CYAN := Color(1.0, 0.1, 0.1)
const COL_PURPLE := Color(0.6, 0.0, 1.0)
const COL_DARK := Color(0.02, 0.02, 0.05)
const COL_DESK := Color(0.08, 0.08, 0.12)
const COL_SCREEN := Color(0.0, 0.05, 0.0)
const COL_METAL := Color(0.15, 0.15, 0.2)

@onready var sub_viewport: SubViewport = $SubViewport

var camera: Camera3D
var is_at_terminal := false

# Curseur custom dans le SubViewport
var os_cursor = null
var vp_cursor_pos := Vector2(576, 324)  # centre par défaut (1152x648 / 2)
# Taille de l'écran 3D en world units (doit correspondre à la QuadMesh)
const SCREEN_WORLD_SIZE := Vector2(1.18, 0.70)
const VP_SIZE := Vector2(1152, 648)

# Position caméra libre (vue de la pièce)
const CAM_FREE_POS := Vector3(0.3, 1.4, 1.8)
const CAM_FREE_ROT := Vector3(-8, -5, 0)

# Position caméra face à l'écran
const CAM_TERMINAL_POS := Vector3(0.0, 1.35, 0.6)
const CAM_TERMINAL_ROT := Vector3(0, 0, 0)

var tween: Tween
@onready var screen_mesh: MeshInstance3D = $ScreenMesh

# Rotation caméra souris
var mouse_look := false
var cam_rotation := Vector2(-8, -5)  # pitch, yaw en degrés
const MOUSE_SENSITIVITY := 0.15
const PITCH_MIN := -30.0
const PITCH_MAX := 20.0
const YAW_MIN := -40.0
const YAW_MAX := 10.0


func _ready():
	_setup_environment()
	_build_room()
	_build_desk()
	_build_monitor()
	_build_keyboard()
	_build_decorations()
	_build_wall_decorations()
	_setup_lights()
	_setup_camera()
	# Confine la souris dans la fenêtre dès le départ
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED


func _notification(what: int):
	# Quand la fenêtre reprend le focus, reconfine la souris
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if is_at_terminal:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	# Quand on perd le focus, libère la souris
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# -----------------------------
# ENVIRONMENT
# -----------------------------
func _apply_screen_texture():
	# La texture est assignée dans l'éditeur, on configure juste le SubViewport
	if sub_viewport:
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		print("SubViewport ready!")


func _setup_environment():
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = COL_DARK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.02, 0.02, 0.08)
	env.ambient_light_energy = 1.0
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.3
	env.glow_hdr_threshold = 0.7

	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


# -----------------------------
# ROOM (sol + murs)
# -----------------------------
func _build_room():
	# Sol
	_make_box(
		Vector3(0, -0.05, 0),
		Vector3(6.0, 0.1, 5.0),
		Color(0.05, 0.05, 0.08)
	)
	# Mur arrière
	_make_box(
		Vector3(0, 1.5, -2.5),
		Vector3(6.0, 3.0, 0.1),
		Color(0.04, 0.04, 0.07)
	)
	# Mur gauche
	_make_box(
		Vector3(-3.0, 1.5, 0),
		Vector3(0.1, 3.0, 5.0),
		Color(0.04, 0.04, 0.07)
	)


# -----------------------------
# BUREAU
# -----------------------------
func _build_desk():
	# Plateau du bureau
	_make_box(
		Vector3(0, 0.75, 0),
		Vector3(2.4, 0.06, 1.0),
		COL_DESK
	)
	# Pied gauche
	_make_box(
		Vector3(-1.1, 0.37, 0),
		Vector3(0.08, 0.75, 0.08),
		COL_METAL
	)
	# Pied droit
	_make_box(
		Vector3(1.1, 0.37, 0),
		Vector3(0.08, 0.75, 0.08),
		COL_METAL
	)
	# Tiroir décoratif
	_make_box(
		Vector3(0.8, 0.55, 0.0),
		Vector3(0.6, 0.25, 0.95),
		Color(0.1, 0.1, 0.15)
	)
	# Poignée tiroir
	_make_box(
		Vector3(0.8, 0.55, 0.48),
		Vector3(0.2, 0.03, 0.03),
		COL_CYAN
	)


# -----------------------------
# MONITEUR
# -----------------------------
func _build_monitor():
	# Base pied moniteur (sur la surface du bureau y=0.78)
	_make_box(
		Vector3(0, 0.795, -0.25),
		Vector3(0.18, 0.025, 0.18),
		COL_METAL
	)
	# Col du pied (monte de 0.81 jusqu'au bas du chassis à 0.94, hauteur=0.13)
	_make_box(
		Vector3(0, 0.875, -0.3),
		Vector3(0.04, 0.16, 0.04),
		COL_METAL
	)
	# Chassis écran
	_make_box(
		Vector3(0, 1.35, -0.32),
		Vector3(1.3, 0.82, 0.06),
		COL_METAL
	)
	# Bordure néon rouge sur le BORD du chassis (derrière, pas devant l'écran)
	_make_box(
		Vector3(0, 1.35, -0.36),
		Vector3(1.32, 0.84, 0.01),
		COL_CYAN,
		true
	)

	# SubViewport setup
	if sub_viewport:
		sub_viewport.size = Vector2i(1152, 648)
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		sub_viewport.gui_disable_input = true
		sub_viewport.handle_input_locally = false


# -----------------------------
# CLAVIER
# -----------------------------
func _build_keyboard():
	# Base clavier
	_make_box(
		Vector3(0, 0.785, 0.2),
		Vector3(0.9, 0.025, 0.32),
		Color(0.06, 0.06, 0.1)
	)
	# Rangées de touches (déco)
	for row in range(4):
		for col in range(10):
			_make_box(
				Vector3(-0.4 + col * 0.085, 0.802, 0.09 + row * 0.072),
				Vector3(0.07, 0.012, 0.06),
				Color(0.1, 0.1, 0.16)
			)
	# Barre espace
	_make_box(
		Vector3(0.0, 0.802, 0.37),
		Vector3(0.35, 0.012, 0.06),
		Color(0.12, 0.12, 0.18)
	)
	# Liseré néon sur le clavier
	_make_box(
		Vector3(0, 0.797, 0.2),
		Vector3(0.92, 0.005, 0.33),
		COL_PURPLE,
		true
	)


# -----------------------------
# DÉCORATIONS
# -----------------------------
func _build_decorations():
	# Tasse de café (cylindre)
	_make_cylinder(
		Vector3(-0.85, 0.875, 0.1),
		0.055, 0.1,
		Color(0.12, 0.06, 0.06)
	)
	# Café dans la tasse
	_make_cylinder(
		Vector3(-0.85, 0.925, 0.1),
		0.048, 0.01,
		Color(0.15, 0.08, 0.04)
	)

	# Lampe de bureau
	# Base lampe
	_make_cylinder(
		Vector3(0.9, 0.782, -0.1),
		0.07, 0.015,
		COL_METAL
	)
	# Bras lampe bas
	_make_box(
		Vector3(0.9, 0.88, -0.1),
		Vector3(0.025, 0.22, 0.025),
		COL_METAL
	)
	# Bras lampe angle
	_make_box(
		Vector3(0.88, 0.99, -0.15),
		Vector3(0.025, 0.025, 0.14),
		COL_METAL
	)
	# Abat-jour
	_make_box(
		Vector3(0.88, 0.98, -0.22),
		Vector3(0.12, 0.06, 0.1),
		COL_METAL
	)

	# Post-it sur le mur
	_make_box(
		Vector3(-0.4, 1.6, -2.44),
		Vector3(0.18, 0.18, 0.01),
		Color(0.9, 0.85, 0.1)
	)
	_make_box(
		Vector3(0.2, 1.45, -2.44),
		Vector3(0.14, 0.14, 0.01),
		Color(0.1, 0.8, 0.6)
	)

	# Petite plante cactus
	_make_cylinder(
		Vector3(-1.0, 0.82, -0.3),
		0.04, 0.08,
		Color(0.1, 0.5, 0.2)
	)
	_make_cylinder(
		Vector3(-1.0, 0.9, -0.3),
		0.025, 0.06,
		Color(0.15, 0.55, 0.25)
	)
	# Pot cactus
	_make_cylinder(
		Vector3(-1.0, 0.795, -0.3),
		0.05, 0.04,
		Color(0.5, 0.25, 0.15)
	)

	# Câbles décoratifs (petits cubes)
	for i in range(5):
		_make_box(
			Vector3(-0.05 + i * 0.04, 0.78, -0.1),
			Vector3(0.025, 0.01, 0.025),
			COL_CYAN if i % 2 == 0 else COL_PURPLE,
			true
		)


# -----------------------------
# DÉCORATIONS MURALES ET FOND
# -----------------------------
func _build_wall_decorations():
	# --- Mur arrière ---
	# Affiche s.p.l.i.t (dédicace) - haut droite du mur
	_make_box(Vector3(1.3, 2.1, -2.44), Vector3(0.85, 0.65, 0.02), Color(0.02, 0.02, 0.05))
	_make_box(Vector3(1.3, 2.1, -2.43), Vector3(0.81, 0.61, 0.01), Color(0.05, 0.05, 0.12))
	# Bande de couleur en haut de l'affiche (rouge comme s.p.l.i.t)
	_make_box(Vector3(1.3, 2.38, -2.425), Vector3(0.81, 0.08, 0.005), COL_CYAN, true)
	# Lignes de texte simulées "s.p.l.i.t"
	_make_box(Vector3(1.3, 2.2, -2.425), Vector3(0.55, 0.04, 0.005), Color(0.9, 0.9, 0.9))
	_make_box(Vector3(1.18, 2.1, -2.425), Vector3(0.3, 0.025, 0.005), Color(0.5, 0.5, 0.6))
	_make_box(Vector3(1.3, 2.02, -2.425), Vector3(0.45, 0.025, 0.005), Color(0.5, 0.5, 0.6))
	_make_box(Vector3(1.25, 1.94, -2.425), Vector3(0.35, 0.025, 0.005), Color(0.4, 0.4, 0.5))
	# Petit logo carré
	_make_box(Vector3(1.62, 2.1, -2.424), Vector3(0.1, 0.1, 0.005), COL_PURPLE, true)
	_make_box(Vector3(1.62, 2.1, -2.422), Vector3(0.07, 0.07, 0.005), Color(0.02, 0.02, 0.05))

	# Grande affiche glitch art - centre haut
	_make_box(Vector3(0.0, 2.15, -2.44), Vector3(0.9, 0.55, 0.02), Color(0.05, 0.0, 0.1))
	_make_box(Vector3(0.0, 2.15, -2.43), Vector3(0.86, 0.51, 0.01), Color(0.08, 0.0, 0.18))
	# Lignes glitch
	for i in range(5):
		_make_box(
			Vector3(0.0, 1.95 + i * 0.1, -2.425),
			Vector3(0.6 if i % 2 == 0 else 0.35, 0.018, 0.005),
			COL_CYAN if i % 3 == 0 else COL_PURPLE,
			true
		)
	# Carré déco affiche
	_make_box(Vector3(-0.3, 2.2, -2.424), Vector3(0.15, 0.15, 0.005), COL_CYAN, true)
	_make_box(Vector3(-0.3, 2.2, -2.422), Vector3(0.11, 0.11, 0.005), Color(0.02, 0.0, 0.08))

	# Liseré néon vertical sur le mur gauche
	_make_box(Vector3(-2.94, 1.5, -0.5), Vector3(0.02, 2.5, 0.05), COL_CYAN, true)
	_make_box(Vector3(-2.94, 1.5, 0.5), Vector3(0.02, 2.5, 0.05), COL_PURPLE, true)

	# Étagère murale gauche
	_make_box(Vector3(-2.5, 1.7, -1.2), Vector3(0.8, 0.04, 0.2), COL_METAL)
	_make_box(Vector3(-2.5, 1.3, -1.2), Vector3(0.8, 0.04, 0.2), COL_METAL)
	# Supports étagère
	_make_box(Vector3(-2.12, 1.5, -1.2), Vector3(0.03, 0.4, 0.03), COL_METAL)
	_make_box(Vector3(-2.88, 1.5, -1.2), Vector3(0.03, 0.4, 0.03), COL_METAL)
	# Objets sur étagère (petites boites colorées)
	_make_box(Vector3(-2.7, 1.77, -1.2), Vector3(0.1, 0.12, 0.1), Color(0.6, 0.0, 0.0))
	_make_box(Vector3(-2.55, 1.76, -1.2), Vector3(0.08, 0.1, 0.08), Color(0.0, 0.3, 0.5))
	_make_box(Vector3(-2.38, 1.77, -1.2), Vector3(0.12, 0.12, 0.1), Color(0.1, 0.1, 0.15))
	# Petite lumière étagère
	_make_box(Vector3(-2.5, 1.72, -1.1), Vector3(0.6, 0.01, 0.02), COL_CYAN, true)

	# Étagère basse (livres/boites)
	_make_box(Vector3(-2.5, 0.6, -1.5), Vector3(0.7, 0.04, 0.18), COL_METAL)
	_make_box(Vector3(-2.46, 0.64, -1.5), Vector3(0.06, 0.08, 0.15), Color(0.7, 0.1, 0.1))
	_make_box(Vector3(-2.38, 0.64, -1.5), Vector3(0.05, 0.09, 0.15), Color(0.1, 0.5, 0.3))
	_make_box(Vector3(-2.31, 0.64, -1.5), Vector3(0.05, 0.07, 0.15), Color(0.5, 0.4, 0.1))
	_make_box(Vector3(-2.23, 0.64, -1.5), Vector3(0.05, 0.1, 0.15), Color(0.2, 0.2, 0.6))



	# Câbles au sol
	for i in range(4):
		_make_box(
			Vector3(-0.3 + i * 0.15, 0.01, 0.5),
			Vector3(0.02, 0.02, 1.2),
			Color(0.05, 0.05, 0.05)
		)

	# Serveur/tour PC sous le bureau
	_make_box(Vector3(-0.9, 0.38, -0.25), Vector3(0.2, 0.7, 0.35), Color(0.06, 0.06, 0.09))
	# Leds tour PC
	for i in range(3):
		_make_box(
			Vector3(-0.81, 0.55 + i * 0.08, -0.07),
			Vector3(0.02, 0.015, 0.015),
			COL_CYAN if i == 0 else (Color(0.0, 1.0, 0.3) if i == 1 else COL_PURPLE),
			true
		)
	# Lecteur disquette déco
	_make_box(Vector3(-0.81, 0.38, -0.07), Vector3(0.1, 0.02, 0.04), Color(0.1, 0.1, 0.15))

	# Horloge murale
	_make_cylinder(Vector3(0.5, 2.1, -2.43), 0.14, 0.03, Color(0.12, 0.12, 0.18))
	_make_cylinder(Vector3(0.5, 2.1, -2.41), 0.12, 0.01, Color(0.08, 0.08, 0.1))
	# Aiguilles horloge
	_make_box(Vector3(0.5, 2.13, -2.40), Vector3(0.01, 0.09, 0.01), COL_CYAN, true)
	_make_box(Vector3(0.505, 2.1, -2.40), Vector3(0.07, 0.01, 0.01), Color(0.8, 0.8, 0.8))

	# Grille de ventilation mur gauche
	_make_box(Vector3(-2.94, 0.8, 0.8), Vector3(0.02, 0.3, 0.4), Color(0.08, 0.08, 0.1))
	for i in range(4):
		_make_box(Vector3(-2.93, 0.7 + i * 0.07, 0.8), Vector3(0.02, 0.01, 0.35), Color(0.12, 0.12, 0.15))

	# Sol : lignes néon au sol (grille cyberpunk)
	for i in range(4):
		_make_box(
			Vector3(-1.5 + i * 1.0, 0.001, 0.0),
			Vector3(0.01, 0.001, 4.0),
			COL_PURPLE if i % 2 == 0 else COL_CYAN,
			true
		)


# -----------------------------
# LUMIÈRES
# -----------------------------
func _setup_lights():
	# Lumière principale froide (dessus)
	var main_light := DirectionalLight3D.new()
	main_light.light_color = Color(0.7, 0.8, 1.0)
	main_light.light_energy = 0.4
	main_light.rotation_degrees = Vector3(-45, 30, 0)
	add_child(main_light)

	# Néon cyan (côté gauche du bureau)
	_add_omni_light(Vector3(-1.5, 1.2, 0.0), COL_CYAN, 2.0, 3.5)

	# Néon violet (côté droit)
	_add_omni_light(Vector3(1.5, 1.4, -1.0), COL_PURPLE, 1.8, 3.0)

	# Lueur de l'écran (très faible pour pas écraser la texture)
	_add_omni_light(Vector3(0, 1.35, 0.2), Color(0.2, 0.8, 0.3), 0.3, 0.8)

	# Lampe de bureau (spot chaud)
	_add_omni_light(Vector3(0.88, 0.95, -0.22), Color(0.8, 0.6, 0.3), 1.2, 1.0)

	# Lumière ambiante sol (reflet néon)
	_add_omni_light(Vector3(0, 0.1, 0), COL_PURPLE, 0.3, 4.0)


func _add_omni_light(pos: Vector3, color: Color, energy: float, radius: float):
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = radius
	light.shadow_enabled = false
	add_child(light)


# -----------------------------
# CAMÉRA
# -----------------------------
func _setup_camera():
	camera = Camera3D.new()
	camera.position = CAM_FREE_POS
	camera.rotation_degrees = CAM_FREE_ROT
	camera.fov = 60
	add_child(camera)


# -----------------------------
# SWITCH CAMÉRA
# -----------------------------
func _unhandled_input(event: InputEvent):
	# Alt+E pour toggler le terminal
	if event is InputEventKey and event.pressed and event.keycode == KEY_E and event.alt_pressed:
		_toggle_terminal_view()
		return

	# Si on est sur le terminal, rediriger tous les inputs vers le SubViewport
	if is_at_terminal and sub_viewport:
		sub_viewport.push_input(event)
		get_viewport().set_input_as_handled()

	# Clic droit : activer/désactiver mouse look
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if not is_at_terminal:
			mouse_look = event.pressed
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mouse_look else Input.MOUSE_MODE_CONFINED

	# Mouvement souris
	if event is InputEventMouseMotion and mouse_look and not is_at_terminal:
		cam_rotation.x -= event.relative.y * MOUSE_SENSITIVITY
		cam_rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		cam_rotation.x = clamp(cam_rotation.x, PITCH_MIN, PITCH_MAX)
		cam_rotation.y = clamp(cam_rotation.y, YAW_MIN, YAW_MAX)
		camera.rotation_degrees = Vector3(cam_rotation.x, cam_rotation.y, 0)

	# Déplace le curseur custom dans le SubViewport
	if event is InputEventMouseMotion and is_at_terminal:
		vp_cursor_pos += event.relative
		vp_cursor_pos.x = clamp(vp_cursor_pos.x, 0, VP_SIZE.x)
		vp_cursor_pos.y = clamp(vp_cursor_pos.y, 0, VP_SIZE.y)
		# Déplace le curseur visuel
		if os_cursor:
			os_cursor.move_to(vp_cursor_pos)
		# Notifie le window manager du mouvement
		if os_main:
			os_main.on_cursor_move(vp_cursor_pos)
		# Envoie le mouvement au SubViewport pour les hover etc.
		var vp_event = InputEventMouseMotion.new()
		vp_event.position = vp_cursor_pos
		vp_event.global_position = vp_cursor_pos
		vp_event.relative = event.relative
		sub_viewport.push_input(vp_event)
		get_viewport().set_input_as_handled()

	# Clics souris → SubViewport + window manager
	if event is InputEventMouseButton and is_at_terminal:
		if os_main:
			os_main.on_cursor_press(vp_cursor_pos, event.pressed)
		_send_mouse_to_viewport(event)
		get_viewport().set_input_as_handled()


func _toggle_terminal_view():
	is_at_terminal = !is_at_terminal

	# Annule le tween précédent si en cours
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)

	if is_at_terminal:
		# Zoom vers l'écran
		tween.tween_property(camera, "position", CAM_TERMINAL_POS, 0.6)
		tween.tween_property(camera, "rotation_degrees", CAM_TERMINAL_ROT, 0.6)
		# Active l'input du SubViewport après la transition
		tween.chain().tween_callback(func():
			sub_viewport.handle_input_locally = true
			sub_viewport.gui_disable_input = false
			sub_viewport.push_input(InputEventKey.new())
			# Cache la vraie souris, active le curseur custom
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN  # curseur custom prend le relais
			_find_os_cursor()
		)
	else:
		# Désactive l'input du terminal
		sub_viewport.handle_input_locally = false
		sub_viewport.gui_disable_input = true
		# Reconfine la souris dans la fenêtre (sans la cacher)
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED
		os_cursor = null
		# Recule vers la vue libre
		tween.tween_property(camera, "position", CAM_FREE_POS, 0.6)
		tween.tween_property(camera, "rotation_degrees", CAM_FREE_ROT, 0.6)


# -----------------------------
# CURSEUR CUSTOM OS
# -----------------------------
var os_main = null

func _find_os_cursor():
	var os_node = sub_viewport.get_node_or_null("OS")
	if os_node:
		os_cursor = os_node.get_node_or_null("CursorLayer/Cursor")
		os_main = os_node


func _send_mouse_to_viewport(event: InputEventMouseButton):
	# Envoie d'abord un MouseMotion pour que Godot sache où est le curseur
	var move_event = InputEventMouseMotion.new()
	move_event.position = vp_cursor_pos
	move_event.global_position = vp_cursor_pos
	move_event.relative = Vector2.ZERO
	sub_viewport.push_input(move_event)

	# Puis envoie le clic à la position simulée
	var vp_event = InputEventMouseButton.new()
	vp_event.button_index = event.button_index
	vp_event.pressed = event.pressed
	vp_event.position = vp_cursor_pos
	vp_event.global_position = vp_cursor_pos
	sub_viewport.push_input(vp_event)


# -----------------------------
# HELPERS MESH
# -----------------------------
func _make_box(pos: Vector3, size: Vector3, color: Color, emissive: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if emissive:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.0
	mi.material_override = mat
	add_child(mi)
	return mi


func _make_cylinder(pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mi.mesh = mesh
	mi.position = pos

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	add_child(mi)
	return mi
