# room_scene.gd  v3
# Chambre vétuste et sombre — ambiance anxiogène, nuit, lampadaire, scintillements
extends Node3D

# ─── Palette ─────────────────────────────────────────────────────────────────
const COL_WALL          := Color(0.38, 0.34, 0.28)   # peinture vieillie / encrassée
const COL_WALL_DARK     := Color(0.22, 0.19, 0.15)   # zones très sombres
const COL_WALL_STAIN    := Color(0.18, 0.15, 0.10)   # humidité / moisissures
const COL_FLOOR         := Color(0.22, 0.15, 0.09)   # parquet sombre usé
const COL_FLOOR_DARK    := Color(0.14, 0.09, 0.05)   # joints / bords parquet
const COL_CEILING       := Color(0.32, 0.29, 0.24)   # plafond jauni / sale
const COL_CEILING_STAIN := Color(0.22, 0.18, 0.13)   # auréoles humidité plafond
const COL_WOOD_DARK     := Color(0.18, 0.11, 0.06)   # bois très foncé
const COL_WOOD_MED      := Color(0.28, 0.19, 0.10)   # bois moyen
const COL_WOOD_LIGHT    := Color(0.40, 0.29, 0.17)   # cadre fenêtre
const COL_METAL_RUST    := Color(0.28, 0.20, 0.13)   # métal rouillé
const COL_METAL_DARK    := Color(0.15, 0.14, 0.12)   # métal foncé
const COL_DESK_SCREEN   := Color(0.12, 0.12, 0.14)   # chassis moniteur
const COL_BULB          := Color(1.0, 0.78, 0.42)    # ampoule incandescente
const COL_STREET_LAMP   := Color(1.0, 0.60, 0.18)    # lampadaire sodium orange
const COL_NIGHT_COLD    := Color(0.35, 0.45, 0.65)   # lumière froide nuit

# ─── Fenêtre ─────────────────────────────────────────────────────────────────
const WIN_X    := 0.0
const WIN_Y    := 1.72
const WIN_Z    := -2.46
const WIN_W    := 2.8
const WIN_H    := 1.75
const WIN_COLS := 4
const WIN_ROWS := 3

# ─── Caméra ──────────────────────────────────────────────────────────────────
const CAM_FREE_POS     := Vector3(0.0, 1.5, 1.8)
const CAM_FREE_ROT     := Vector3(-8, 0, 0)
const CAM_TERMINAL_POS := Vector3(0.0, 1.35, 0.6)
const CAM_TERMINAL_ROT := Vector3(0, 0, 0)
const VP_SIZE          := Vector2(1152, 648)
const MOUSE_SENSITIVITY := 0.15
const PITCH_MIN := -30.0
const PITCH_MAX := 20.0
const YAW_MIN   := -40.0
const YAW_MAX   := 40.0

# ─── Variables ───────────────────────────────────────────────────────────────
@onready var sub_viewport: SubViewport = $SubViewport
@onready var screen_mesh: MeshInstance3D = $ScreenMesh

var camera: Camera3D
var is_at_terminal   := false
var os_cursor        = null
var os_main          = null
var vp_cursor_pos    := Vector2(576, 324)
var tween: Tween
var mouse_look       := false
var cam_rotation     := Vector2(-8, 0)
var desk_lamp_light: OmniLight3D
var lamp_enabled     := true
var street_lamp_light: OmniLight3D
var window_cold_light: OmniLight3D

# ─────────────────────────────────────────────────────────────────────────────
func _ready():
	_setup_environment()
	_build_room()
	_build_window()
	_build_outside_view()
	_build_desk()
	_build_monitor()
	_build_keyboard()
	_build_radio()
	_build_bed()
	_build_decorations()
	_build_wall_decorations()
	_build_mirror()
	_build_mess()
	_setup_lights()
	_setup_camera()
	_build_crt_overlay()
	_build_vignette()
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	_start_flicker.call_deferred()
	_start_street_lamp_flicker.call_deferred()


func _notification(what: int):
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if is_at_terminal else Input.MOUSE_MODE_CONFINED
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# ─── ENVIRONNEMENT ────────────────────────────────────────────────────────────
func _setup_environment():
	var env := Environment.new()

	# Fond nuit profonde
	env.background_mode  = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.03)

	# Lumière ambiante quasiment nulle → contraste extrême
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color  = Color(0.04, 0.04, 0.05)
	env.ambient_light_energy = 0.4

	# ── Fog volumétrique ──────────────────────────────────────────────────────
	env.volumetric_fog_enabled      = true
	env.volumetric_fog_density      = 0.018          # fin mais visible
	env.volumetric_fog_albedo       = Color(0.75, 0.70, 0.62)
	env.volumetric_fog_emission     = Color(0, 0, 0)
	env.volumetric_fog_anisotropy   = 0.5            # forward scattering
	env.volumetric_fog_length       = 24.0
	env.volumetric_fog_detail_spread = 2.0
	env.volumetric_fog_gi_inject    = 1.0

	# ── Fog de distance ───────────────────────────────────────────────────────
	env.fog_enabled     = true
	env.fog_light_color = Color(0.05, 0.04, 0.03)
	env.fog_density     = 0.015

	# ── Glow — très subtil mais important ────────────────────────────────────
	env.glow_enabled       = true
	env.glow_intensity     = 0.6
	env.glow_bloom         = 0.2
	env.glow_hdr_threshold = 0.7

	# ── SSR (Screen Space Reflections) pour le miroir ─────────────────────────
	env.ssr_enabled         = true
	env.ssr_max_steps       = 64
	env.ssr_fade_in         = 0.15
	env.ssr_fade_out        = 2.0
	env.ssr_depth_tolerance = 0.2

	# ── SSAO agressif → coins très sombres ────────────────────────────────────
	env.ssao_enabled   = true
	env.ssao_radius    = 1.8
	env.ssao_intensity = 3.5
	env.ssao_power     = 1.5

	# ── SSIL ─────────────────────────────────────────────────────────────────
	env.ssil_enabled   = true
	env.ssil_radius    = 2.5
	env.ssil_intensity = 1.0

	# ── Correction colorimétrique ─────────────────────────────────────────────
	env.adjustment_enabled    = true
	env.adjustment_brightness = 0.80     # plus sombre
	env.adjustment_contrast   = 1.35     # contraste dur
	env.adjustment_saturation = 0.70     # très désaturé → look anxiogène

	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


# ─── PIÈCE ────────────────────────────────────────────────────────────────────
func _build_room():
	# Sol — parquet sombre
	_make_box(Vector3(0, -0.05, 0), Vector3(6.0, 0.1, 5.0), COL_FLOOR)
	for i in range(7):
		_make_box(Vector3(-3.0 + i * 1.0, 0.001, 0), Vector3(0.018, 0.001, 5.0), COL_FLOOR_DARK)
	for i in range(5):
		_make_box(Vector3(-2.0 + i * 0.8, 0.001, 0), Vector3(0.005, 0.001, randf_range(1.5, 4.5)), Color(0.12, 0.08, 0.04))

	# Plafond
	_make_box(Vector3(0, 3.05, 0), Vector3(6.0, 0.1, 5.0), COL_CEILING)
	_make_box(Vector3(-1.2, 3.04, -0.4), Vector3(1.2, 0.01, 0.9), COL_CEILING_STAIN)
	_make_box(Vector3(0.8, 3.04, 0.5),  Vector3(0.7, 0.01, 0.5), COL_CEILING_STAIN)
	# Fissure plafond
	_make_box(Vector3(0.3, 3.04, -0.6), Vector3(0.006, 0.005, 0.9), Color(0.18, 0.14, 0.10))
	_make_box(Vector3(0.5, 3.04, -0.3), Vector3(0.28, 0.005, 0.005), Color(0.18, 0.14, 0.10))

	# ── Mur ARRIÈRE (avec trou fenêtre) ───────────────────────────────────────
	var fw2   := WIN_W * 0.5
	var fh2   := WIN_H * 0.5
	var w_ymin := WIN_Y - fh2
	var w_ymax := WIN_Y + fh2
	var w_xmin := WIN_X - fw2
	var w_xmax := WIN_X + fw2

	_make_box(Vector3(0, w_ymin * 0.5, -2.5), Vector3(6.0, w_ymin, 0.12), COL_WALL)
	var top_h := 3.0 - w_ymax
	_make_box(Vector3(0, w_ymax + top_h * 0.5, -2.5), Vector3(6.0, top_h, 0.12), COL_WALL)
	var lw := 3.0 + w_xmin
	_make_box(Vector3(-3.0 + lw * 0.5, WIN_Y, -2.5), Vector3(lw, WIN_H, 0.12), COL_WALL)
	var rw := 3.0 - w_xmax
	_make_box(Vector3(3.0 - rw * 0.5, WIN_Y, -2.5), Vector3(rw, WIN_H, 0.12), COL_WALL)

	# Détails mur arrière
	_make_box(Vector3(-2.2, 0.55, -2.44), Vector3(0.9, 0.7, 0.01), COL_WALL_STAIN)
	_make_box(Vector3(2.3, 0.8,  -2.44), Vector3(0.4, 0.5, 0.01), COL_WALL_STAIN)
	_make_box(Vector3(2.1, 2.5,  -2.44), Vector3(0.6, 0.2, 0.01), COL_WALL_DARK)
	# Fissures
	_make_box(Vector3(-2.0, 2.7, -2.44), Vector3(0.006, 0.55, 0.005), COL_WALL_DARK)
	_make_box(Vector3(-1.96, 2.52, -2.44), Vector3(0.15, 0.005, 0.005), COL_WALL_DARK)
	_make_box(Vector3(-2.0, 2.25, -2.44), Vector3(0.005, 0.28, 0.005), COL_WALL_DARK)

	# ── Mur GAUCHE ──────────────────────────────────────────────────────────
	_make_box(Vector3(-3.0, 1.5, 0), Vector3(0.12, 3.0, 5.0), COL_WALL)
	_make_box(Vector3(-2.95, 0.50, -1.5), Vector3(0.02, 1.1, 0.9), COL_WALL_STAIN)
	_make_box(Vector3(-2.95, 0.22, 0.8),  Vector3(0.02, 0.55, 0.6), COL_WALL_STAIN)
	_make_box(Vector3(-2.95, 1.2,  1.0),  Vector3(0.02, 0.40, 0.3), COL_WALL_DARK)
	# Papier peint décollé bas-gauche
	_make_box(Vector3(-2.975, 0.38, 1.85), Vector3(0.008, 0.65, 0.55), Color(0.48, 0.42, 0.34))
	_make_box(Vector3(-2.97,  0.22, 2.0),  Vector3(0.010, 0.30, 0.25), Color(0.42, 0.36, 0.28))

	# ── Mur DROIT ───────────────────────────────────────────────────────────
	_make_box(Vector3(3.0, 1.5, 0), Vector3(0.12, 3.0, 5.0), COL_WALL)
	_make_box(Vector3(2.95, 0.6, 1.2), Vector3(0.02, 0.8, 0.6), COL_WALL_STAIN)

	# ── Mur AVANT ───────────────────────────────────────────────────────────
	_make_box(Vector3(0, 1.5, 2.5), Vector3(6.0, 3.0, 0.12), COL_WALL)

	# ── Plinthes ────────────────────────────────────────────────────────────
	var ph := 0.13
	_make_box(Vector3(0,     ph*0.5, -2.44), Vector3(6.0, ph, 0.04), COL_WOOD_DARK)
	_make_box(Vector3(-2.94, ph*0.5,  0),    Vector3(0.04, ph, 5.0), COL_WOOD_DARK)
	_make_box(Vector3(2.94,  ph*0.5,  0),    Vector3(0.04, ph, 5.0), COL_WOOD_DARK)
	_make_box(Vector3(0,     ph*0.5,  2.44), Vector3(6.0, ph, 0.04), COL_WOOD_DARK)

	# Câble électrique en surface de mur (gauche, monte vers le plafond)
	_make_box(Vector3(-2.94, 1.5, -0.2), Vector3(0.018, 2.8, 0.018), Color(0.10, 0.08, 0.06))
	_make_box(Vector3(-2.94, 1.5,  0.8), Vector3(0.014, 2.2, 0.014), Color(0.08, 0.07, 0.05))


# ─── FENÊTRE ─────────────────────────────────────────────────────────────────
func _build_window():
	var fw2 := WIN_W * 0.5
	var fh2 := WIN_H * 0.5
	var ft  := 0.065
	var bt  := 0.030
	var fc  := COL_WOOD_LIGHT

	# Cadre extérieur
	_make_box(Vector3(WIN_X, WIN_Y + fh2 + ft*0.5, WIN_Z), Vector3(WIN_W + ft*2, ft, 0.10), fc)
	_make_box(Vector3(WIN_X, WIN_Y - fh2 - ft*0.5, WIN_Z), Vector3(WIN_W + ft*2, ft, 0.10), fc)
	_make_box(Vector3(WIN_X - fw2 - ft*0.5, WIN_Y, WIN_Z), Vector3(ft, WIN_H, 0.10), fc)
	_make_box(Vector3(WIN_X + fw2 + ft*0.5, WIN_Y, WIN_Z), Vector3(ft, WIN_H, 0.10), fc)

	# Barreaux
	for i in range(1, WIN_COLS):
		var bx := WIN_X - fw2 + (WIN_W / WIN_COLS) * i
		_make_box(Vector3(bx, WIN_Y, WIN_Z), Vector3(bt, WIN_H, 0.08), fc)
	for i in range(1, WIN_ROWS):
		var by := WIN_Y - fh2 + (WIN_H / WIN_ROWS) * i
		_make_box(Vector3(WIN_X, by, WIN_Z), Vector3(WIN_W, bt, 0.08), fc)

	# Vitres — teintées très légèrement, reflet nocturne (quasi transparent)
	var cell_w := WIN_W / WIN_COLS
	var cell_h := WIN_H / WIN_ROWS
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color     = Color(0.55, 0.65, 0.80, 0.08)
	glass_mat.transparency     = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness        = 0.0
	glass_mat.metallic         = 0.08
	glass_mat.emission_enabled = true
	glass_mat.emission         = Color(0.30, 0.38, 0.55)  # reflet bleu nuit
	glass_mat.emission_energy_multiplier = 0.12

	for col in range(WIN_COLS):
		for row in range(WIN_ROWS):
			var cx := WIN_X - fw2 + cell_w * (col + 0.5)
			var cy := WIN_Y - fh2 + cell_h * (row + 0.5)
			var pane := MeshInstance3D.new()
			var pm   := BoxMesh.new()
			pm.size  = Vector3(cell_w - bt, cell_h - bt, 0.01)
			pane.mesh = pm
			pane.position = Vector3(cx, cy, WIN_Z + 0.01)
			pane.material_override = glass_mat
			add_child(pane)

	# Tablette fenêtre + poussière / mégot
	_make_box(Vector3(WIN_X, WIN_Y - fh2 - ft - 0.025, WIN_Z + 0.14),
			  Vector3(WIN_W + ft*2 + 0.12, 0.048, 0.30), COL_WOOD_LIGHT)
	# Tache sur tablette
	_make_box(Vector3(0.3, WIN_Y - fh2 - ft - 0.0, WIN_Z + 0.18),
			  Vector3(0.12, 0.002, 0.09), Color(0.22, 0.18, 0.12))


# ─── EXTÉRIEUR (vue depuis la fenêtre) ───────────────────────────────────────
func _build_outside_view():
	# Fond nuit — plan lointain
	var sky_mat := StandardMaterial3D.new()
	sky_mat.albedo_color     = Color(0.04, 0.04, 0.07)
	sky_mat.emission_enabled = true
	sky_mat.emission         = Color(0.03, 0.03, 0.05)
	sky_mat.emission_energy_multiplier = 1.0
	sky_mat.shading_mode     = BaseMaterial3D.SHADING_MODE_UNSHADED

	var sky_mi   := MeshInstance3D.new()
	var sky_mesh := BoxMesh.new()
	sky_mesh.size = Vector3(WIN_W * 1.4, WIN_H * 1.4, 0.05)
	sky_mi.mesh  = sky_mesh
	sky_mi.position = Vector3(WIN_X, WIN_Y, WIN_Z - 1.8)
	sky_mi.material_override = sky_mat
	add_child(sky_mi)

	# Bâtiment sombre face à la fenêtre
	var bld_mat := StandardMaterial3D.new()
	bld_mat.albedo_color = Color(0.06, 0.06, 0.08)
	bld_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Corps du bâtiment
	_make_box_with_mat(Vector3(-0.6, 2.1, WIN_Z - 1.4), Vector3(1.1, 2.5, 0.04), bld_mat)
	# Fenêtres du bâtiment — une seule allumée (orange, lointaine)
	for row in range(3):
		for col in range(2):
			var lit := (row == 1 and col == 1)
			var wm := StandardMaterial3D.new()
			wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			wm.albedo_color = Color(0.55, 0.40, 0.12) if lit else Color(0.05, 0.05, 0.06)
			if lit:
				wm.emission_enabled = true
				wm.emission = Color(0.6, 0.40, 0.10)
				wm.emission_energy_multiplier = 1.0
			_make_box_with_mat(
				Vector3(-0.85 + col * 0.45, 1.55 + row * 0.55, WIN_Z - 1.38),
				Vector3(0.28, 0.28, 0.02), wm
			)

	# Enseigne lointaine (vague, lumineuse, angoissante)
	var sign_mat := StandardMaterial3D.new()
	sign_mat.shading_mode    = BaseMaterial3D.SHADING_MODE_UNSHADED
	sign_mat.albedo_color    = Color(0.6, 0.05, 0.05)
	sign_mat.emission_enabled = true
	sign_mat.emission        = Color(0.55, 0.02, 0.02)
	sign_mat.emission_energy_multiplier = 0.8
	_make_box_with_mat(Vector3(0.9, 2.3, WIN_Z - 1.5), Vector3(0.35, 0.08, 0.02), sign_mat)

	# Reflet lampadaire sur le sol extérieur (lueur orange en bas de la fenêtre)
	var glow_mat := StandardMaterial3D.new()
	glow_mat.shading_mode    = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.albedo_color    = Color(0.6, 0.35, 0.05, 0.4)
	glow_mat.transparency    = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.emission_enabled = true
	glow_mat.emission        = Color(0.65, 0.38, 0.06)
	glow_mat.emission_energy_multiplier = 0.6
	_make_box_with_mat(Vector3(WIN_X, WIN_Y - WIN_H * 0.5 - 0.2, WIN_Z - 0.5),
					   Vector3(WIN_W * 0.8, 0.3, 0.02), glow_mat)


# ─── BUREAU ───────────────────────────────────────────────────────────────────
func _build_desk():
	_make_box(Vector3(0, 0.75, 0), Vector3(2.4, 0.055, 1.0), COL_WOOD_DARK)
	_make_box(Vector3(0, 0.773, 0.5), Vector3(2.4, 0.008, 0.008), COL_WOOD_MED)
	for sx in [-1.1, 1.1]:
		for sz in [0.0, -0.45]:
			_make_box(Vector3(sx, 0.37, sz), Vector3(0.055, 0.75, 0.055), COL_METAL_RUST)
	_make_box(Vector3(0, 0.20, -0.2), Vector3(2.2, 0.028, 0.04), COL_METAL_DARK)
	_make_box(Vector3(0.82, 0.56, 0.0), Vector3(0.58, 0.22, 0.92), Color(0.16, 0.10, 0.06))
	_make_cylinder(Vector3(0.82, 0.56, 0.462), 0.011, 0.09, COL_METAL_RUST)
	_make_box(Vector3(0, 0.37, -0.5), Vector3(2.3, 0.7, 0.02), Color(0.14, 0.09, 0.05))


# ─── MONITEUR ────────────────────────────────────────────────────────────────
func _build_monitor():
	_make_box(Vector3(0, 0.793, -0.25), Vector3(0.20, 0.022, 0.20), COL_METAL_DARK)
	_make_box(Vector3(0, 0.875, -0.29), Vector3(0.034, 0.165, 0.034), COL_METAL_DARK)
	_make_box(Vector3(0, 1.35, -0.32), Vector3(1.3, 0.82, 0.055), COL_DESK_SCREEN)
	_make_box(Vector3(0, 1.35, -0.295), Vector3(1.22, 0.74, 0.010), Color(0.07, 0.07, 0.09))
	if sub_viewport:
		sub_viewport.size = Vector2i(1152, 648)
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		sub_viewport.gui_disable_input = true
		sub_viewport.handle_input_locally = false


# ─── CLAVIER ─────────────────────────────────────────────────────────────────
func _build_keyboard():
	_make_box(Vector3(0, 0.784, 0.2), Vector3(0.9, 0.022, 0.32), Color(0.26, 0.23, 0.19))
	for row in range(4):
		for col in range(10):
			_make_box(
				Vector3(-0.4 + col * 0.085, 0.800, 0.09 + row * 0.072),
				Vector3(0.065, 0.009, 0.056),
				Color(0.24, 0.21, 0.17) if (row + col) % 4 != 0 else Color(0.19, 0.17, 0.14)
			)
	_make_box(Vector3(0.0, 0.800, 0.37), Vector3(0.35, 0.009, 0.056), Color(0.28, 0.25, 0.21))


# ─── RADIO ───────────────────────────────────────────────────────────────────
func _build_radio():
	# Corps de la radio (vieille radio portable, droite du bureau)
	_make_box(Vector3(0.75, 0.815, -0.38), Vector3(0.28, 0.12, 0.15), Color(0.25, 0.20, 0.14))
	# Face avant légèrement plus claire
	_make_box(Vector3(0.75, 0.815, -0.305), Vector3(0.26, 0.10, 0.006), Color(0.30, 0.25, 0.18))
	# Grille speaker (hachures)
	for i in range(5):
		_make_box(
			Vector3(0.68 + i * 0.025, 0.815, -0.302),
			Vector3(0.008, 0.08, 0.005),
			Color(0.18, 0.14, 0.10)
		)
	# Cadran (LED rouge très faible)
	_make_box(Vector3(0.62, 0.825, -0.302), Vector3(0.08, 0.03, 0.005), Color(0.08, 0.04, 0.04))
	_make_box(Vector3(0.60, 0.825, -0.300), Vector3(0.02, 0.016, 0.002), Color(0.8, 0.05, 0.05), true)
	# Antenne
	_make_box(Vector3(0.87, 0.885, -0.36), Vector3(0.010, 0.130, 0.010), Color(0.22, 0.18, 0.14))
	_make_box(Vector3(0.90, 0.940, -0.37), Vector3(0.008, 0.100, 0.008), Color(0.22, 0.18, 0.14))
	# Boutons (2 petits)
	_make_cylinder(Vector3(0.79, 0.826, -0.302), 0.012, 0.015, Color(0.20, 0.16, 0.12))
	_make_cylinder(Vector3(0.82, 0.826, -0.302), 0.010, 0.015, Color(0.20, 0.16, 0.12))
	# Câble d'alimentation
	_make_box(Vector3(0.60, 0.785, -0.38), Vector3(0.012, 0.006, 0.4), Color(0.10, 0.08, 0.06))


# ─── LIT ──────────────────────────────────────────────────────────────────────
func _build_bed():
	# Tête de lit
	_make_box(Vector3(-2.36, 1.0, -1.5), Vector3(0.08, 1.25, 1.9), COL_WOOD_DARK)
	for i in range(3):
		_make_box(Vector3(-2.31, 0.85, -1.82 + i * 0.65),
				  Vector3(0.018, 0.82, 0.50), Color(0.14, 0.09, 0.05))
	_make_box(Vector3(-2.36, 0.44, 0.55), Vector3(0.08, 0.52, 0.10), COL_WOOD_DARK)
	# Structure
	_make_box(Vector3(-1.82, 0.24, -0.5), Vector3(1.02, 0.04, 2.0), COL_WOOD_DARK)
	for i in range(5):
		_make_box(Vector3(-1.82, 0.268, -1.35 + i * 0.45), Vector3(0.95, 0.022, 0.065), COL_WOOD_MED)
	# Matelas (vieux, affaissé)
	_make_box(Vector3(-1.82, 0.50, -0.5), Vector3(1.0, 0.23, 2.0), Color(0.35, 0.30, 0.24))
	# Draps froissés
	_make_box(Vector3(-1.70, 0.648, -0.38), Vector3(0.78, 0.058, 0.82), Color(0.50, 0.46, 0.40))
	_make_box(Vector3(-1.92, 0.672, 0.05),  Vector3(0.52, 0.075, 0.48), Color(0.44, 0.40, 0.35))
	_make_box(Vector3(-1.60, 0.660, 0.28),  Vector3(0.62, 0.052, 0.38), Color(0.52, 0.48, 0.42))
	_make_box(Vector3(-1.82, 0.658, -1.30), Vector3(0.95, 0.038, 0.08), Color(0.55, 0.50, 0.44))
	# Oreiller (affaissé, pas centré)
	_make_box(Vector3(-1.78, 0.630, -1.30), Vector3(0.75, 0.115, 0.40), Color(0.60, 0.56, 0.50))
	_make_box(Vector3(-1.76, 0.690, -1.30), Vector3(0.38, 0.008, 0.26), Color(0.55, 0.51, 0.45))


# ─── DÉCORATIONS ─────────────────────────────────────────────────────────────
func _build_decorations():
	# ── Lampe de bureau ──
	_make_cylinder(Vector3(0.90, 0.781, -0.10), 0.058, 0.013, COL_METAL_DARK)
	_make_box(Vector3(0.90, 0.880, -0.10), Vector3(0.018, 0.200, 0.018), COL_METAL_RUST)
	_make_box(Vector3(0.88, 0.990, -0.16), Vector3(0.018, 0.018, 0.125), COL_METAL_RUST)
	_make_box(Vector3(0.88, 0.972, -0.24), Vector3(0.115, 0.060, 0.110), Color(0.32, 0.24, 0.15))
	_make_box(Vector3(0.88, 0.938, -0.24), Vector3(0.095, 0.018, 0.090), Color(0.25, 0.18, 0.12))
	_make_cylinder(Vector3(0.88, 0.958, -0.24), 0.020, 0.038, Color(1.0, 0.95, 0.80), true)

	# ── Tasse avec fond de café séché ──
	_make_cylinder(Vector3(-0.85, 0.875, 0.12), 0.048, 0.088, Color(0.32, 0.28, 0.22))
	_make_cylinder(Vector3(-0.85, 0.920, 0.12), 0.042, 0.010, Color(0.08, 0.04, 0.01))
	_make_box(Vector3(-0.80, 0.875, 0.12), Vector3(0.028, 0.048, 0.010), Color(0.32, 0.28, 0.22))

	# ── Cendrier avec mégots ──
	_make_cylinder(Vector3(-0.60, 0.788, 0.25), 0.055, 0.018, Color(0.30, 0.26, 0.20))
	_make_cylinder(Vector3(-0.60, 0.796, 0.25), 0.048, 0.010, Color(0.22, 0.18, 0.13))
	# Mégots
	for i in range(3):
		var angle := i * 1.4
		_make_box(Vector3(-0.60 + cos(angle) * 0.03, 0.800, 0.25 + sin(angle) * 0.03),
				  Vector3(0.006, 0.004, 0.038), Color(0.55, 0.40, 0.28))

	# ── Livre ouvert ──
	_make_box(Vector3(-1.02, 0.787, -0.14), Vector3(0.25, 0.018, 0.17), Color(0.48, 0.38, 0.26))
	_make_box(Vector3(-0.900, 0.798, -0.14), Vector3(0.11, 0.004, 0.16), Color(0.88, 0.84, 0.76))
	_make_box(Vector3(-1.140, 0.798, -0.14), Vector3(0.11, 0.004, 0.16), Color(0.86, 0.82, 0.74))
	for ln in range(5):
		_make_box(Vector3(-0.900, 0.804, -0.18 + ln*0.032),
				  Vector3(0.085 if ln % 3 != 2 else 0.055, 0.002, 0.005), Color(0.28, 0.22, 0.16))

	# ── Câbles bureaux ──
	for i in range(3):
		_make_box(Vector3(-0.05 + i*0.04, 0.778, 0.1), Vector3(0.014, 0.007, 0.55), Color(0.08, 0.07, 0.05))

	# ── Objet rebord fenêtre ──
	_make_cylinder(Vector3(-0.40, 0.940, -2.22), 0.036, 0.058, Color(0.35, 0.24, 0.12))
	_make_cylinder(Vector3(-0.40, 0.972, -2.22), 0.026, 0.055, Color(0.20, 0.18, 0.14))
	_make_box(Vector3(-0.40, 1.005, -2.22), Vector3(0.007, 0.055, 0.007), Color(0.18, 0.15, 0.10))
	# Vieille canette
	_make_cylinder(Vector3(0.52, 0.933, -2.20), 0.033, 0.068, Color(0.32, 0.28, 0.22))
	_make_cylinder(Vector3(0.52, 0.972, -2.20), 0.026, 0.009, Color(0.22, 0.20, 0.16))

	# ── Interrupteur + prise ──
	_make_box(Vector3(-2.93, 1.22, 1.45), Vector3(0.020, 0.098, 0.068), Color(0.44, 0.40, 0.35))
	_make_box(Vector3(-2.92, 1.22, 1.45), Vector3(0.010, 0.052, 0.028), Color(0.76, 0.72, 0.66))
	_make_box(Vector3(-2.93, 0.45, 1.82), Vector3(0.018, 0.078, 0.058), Color(0.42, 0.38, 0.33))
	_make_box(Vector3(-2.92, 0.48, 1.80), Vector3(0.008, 0.011, 0.011), Color(0.18, 0.16, 0.14))
	_make_box(Vector3(-2.92, 0.42, 1.80), Vector3(0.008, 0.011, 0.011), Color(0.18, 0.16, 0.14))


# ─── DÉCORATIONS MURALES ──────────────────────────────────────────────────────
func _build_wall_decorations():
	# ── Affiche très délavée ──
	_make_box(Vector3(2.05, 1.80, -2.44), Vector3(0.78, 1.05, 0.018), Color(0.28, 0.24, 0.18))
	_make_box(Vector3(2.05, 1.80, -2.432), Vector3(0.72, 0.99, 0.009), Color(0.24, 0.20, 0.15))
	_make_box(Vector3(2.05, 2.18, -2.428), Vector3(0.58, 0.055, 0.005), Color(0.36, 0.28, 0.18))
	_make_box(Vector3(1.95, 2.04, -2.428), Vector3(0.42, 0.030, 0.005), Color(0.32, 0.26, 0.16))
	_make_box(Vector3(2.05, 1.90, -2.428), Vector3(0.52, 0.025, 0.005), Color(0.30, 0.24, 0.15))
	# Coins déchirés
	_make_box(Vector3(2.40, 2.26, -2.435), Vector3(0.04, 0.18, 0.007), Color(0.32, 0.27, 0.20))
	_make_box(Vector3(2.42, 2.16, -2.430), Vector3(0.02, 0.08, 0.013), Color(0.40, 0.35, 0.28))
	_make_box(Vector3(1.68, 1.28, -2.434), Vector3(0.05, 0.12, 0.008), Color(0.32, 0.27, 0.20))

	# ── Étagère murale gauche ──
	_make_box(Vector3(-2.55, 1.88, -1.0), Vector3(0.75, 0.036, 0.20), COL_WOOD_MED)
	_make_box(Vector3(-2.20, 1.68, -1.0), Vector3(0.022, 0.40, 0.022), COL_METAL_DARK)
	_make_box(Vector3(-2.90, 1.68, -1.0), Vector3(0.022, 0.40, 0.022), COL_METAL_DARK)
	var bc := [Color(0.45, 0.09, 0.07), Color(0.07, 0.20, 0.38), Color(0.28, 0.26, 0.09), Color(0.20, 0.38, 0.20)]
	for i in range(4):
		var bw := 0.058 + (i % 2) * 0.018
		var bh := 0.14 + (i % 3) * 0.038
		_make_box(Vector3(-2.80 + i * 0.14, 1.90 + bh*0.5, -1.0), Vector3(bw, bh, 0.16), bc[i])
		_make_box(Vector3(-2.80 + i * 0.14, 1.90 + bh*0.5, -0.91), Vector3(bw - 0.009, bh + 0.004, 0.004), Color(0.84, 0.80, 0.72))

	# ── Tour PC ──
	_make_box(Vector3(-0.90, 0.40, -0.26), Vector3(0.19, 0.74, 0.40), Color(0.20, 0.18, 0.16))
	for i in range(6):
		_make_box(Vector3(-0.81, 0.55 + i*0.055, -0.062), Vector3(0.016, 0.020, 0.22), Color(0.10, 0.09, 0.07))
	_make_box(Vector3(-0.81, 0.39, -0.062), Vector3(0.016, 0.007, 0.007), Color(0.0, 0.85, 0.18), true)
	_make_box(Vector3(-0.81, 0.42, -0.062), Vector3(0.13, 0.016, 0.35), Color(0.16, 0.14, 0.12))
	_make_box(Vector3(-0.82, 0.2, 0.1), Vector3(0.011, 0.38, 0.011), Color(0.07, 0.06, 0.05))

	# ── Câbles sol ──
	for i in range(3):
		_make_box(Vector3(-0.15 + i*0.06, 0.004, 0.5), Vector3(0.012, 0.007, 1.6), Color(0.07, 0.06, 0.05))

	# ── Radiateur ──
	_make_box(Vector3(-2.80, 0.28, 0.62), Vector3(0.20, 0.40, 0.72), COL_METAL_RUST)
	for i in range(5):
		_make_box(Vector3(-2.70, 0.28, 0.34 + i*0.12), Vector3(0.014, 0.36, 0.042), COL_METAL_DARK)
	_make_cylinder(Vector3(-2.70, 0.52, 0.28), 0.019, 0.055, COL_METAL_RUST)
	_make_cylinder(Vector3(-2.70, 0.52, 0.96), 0.019, 0.055, COL_METAL_RUST)

	# ── Placard mur droit ──
	_make_box(Vector3(2.62, 1.4, -1.5), Vector3(0.65, 2.8, 1.05), Color(0.26, 0.20, 0.14))
	_make_box(Vector3(2.62, 1.4, -1.76), Vector3(0.62, 2.72, 0.020), Color(0.30, 0.24, 0.18))
	_make_box(Vector3(2.62, 1.4, -1.24), Vector3(0.62, 2.72, 0.020), Color(0.30, 0.24, 0.18))
	_make_box(Vector3(2.62, 1.4, -1.50), Vector3(0.63, 2.74, 0.007), Color(0.12, 0.10, 0.07))
	_make_cylinder(Vector3(2.62, 1.4, -1.63), 0.011, 0.075, COL_METAL_RUST)
	_make_cylinder(Vector3(2.62, 1.4, -1.37), 0.011, 0.075, COL_METAL_RUST)

	# ── Note post-it sur le mur (cryptique) ──
	_make_box(Vector3(-0.2, 1.62, -2.44), Vector3(0.18, 0.18, 0.010), Color(0.78, 0.70, 0.28))
	_make_box(Vector3(-0.2, 1.67, -2.435), Vector3(0.12, 0.008, 0.003), Color(0.20, 0.16, 0.10))
	_make_box(Vector3(-0.2, 1.64, -2.435), Vector3(0.10, 0.007, 0.003), Color(0.20, 0.16, 0.10))
	_make_box(Vector3(-0.2, 1.61, -2.435), Vector3(0.08, 0.007, 0.003), Color(0.20, 0.16, 0.10))
	_make_box(Vector3(-0.2, 1.58, -2.435), Vector3(0.11, 0.007, 0.003), Color(0.20, 0.16, 0.10))

	# ── Câble ampoule plafond ──
	_make_box(Vector3(0.5, 2.92, -0.5), Vector3(0.006, 0.16, 0.006), Color(0.07, 0.06, 0.05))
	_make_cylinder(Vector3(0.5, 2.80, -0.5), 0.024, 0.038, COL_METAL_DARK)
	_make_cylinder(Vector3(0.5, 2.77, -0.5), 0.035, 0.055, Color(0.85, 0.80, 0.65), true)

	# ── Fissures mur gauche ──
	_make_box(Vector3(-2.94, 1.85, -0.8), Vector3(0.005, 0.50, 0.005), COL_WALL_DARK)
	_make_box(Vector3(-2.94, 1.68, -0.6), Vector3(0.005, 0.20, 0.005), COL_WALL_DARK)


# ─── MIROIR (mur droit, avant le placard) ────────────────────────────────────
func _build_mirror():
	# Cadre miroir
	var frame_col := Color(0.22, 0.16, 0.10)
	_make_box(Vector3(2.94, 1.7, 0.6), Vector3(0.04, 1.05, 0.65), frame_col)
	# Bordure intérieure
	_make_box(Vector3(2.935, 1.7, 0.6), Vector3(0.03, 0.98, 0.58), Color(0.18, 0.13, 0.09))

	# Surface réfléchissante (SSR activé sur l'env)
	var mirror_mat := StandardMaterial3D.new()
	mirror_mat.metallic       = 1.0
	mirror_mat.roughness      = 0.02
	mirror_mat.albedo_color   = Color(0.85, 0.85, 0.85)
	mirror_mat.clearcoat      = 1.0
	mirror_mat.clearcoat_roughness = 0.01

	var mir := MeshInstance3D.new()
	var mm  := BoxMesh.new()
	mm.size = Vector3(0.015, 0.92, 0.52)
	mir.mesh = mm
	mir.position = Vector3(2.928, 1.7, 0.6)
	mir.material_override = mirror_mat
	add_child(mir)

	# Tache / condensation en bas du miroir
	var fog_mat := StandardMaterial3D.new()
	fog_mat.albedo_color = Color(0.50, 0.48, 0.44, 0.45)
	fog_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fog_mat.roughness    = 0.5
	var fog_mi   := MeshInstance3D.new()
	var fog_mesh := BoxMesh.new()
	fog_mesh.size = Vector3(0.016, 0.18, 0.52)
	fog_mi.mesh  = fog_mesh
	fog_mi.position = Vector3(2.927, 1.24, 0.6)
	fog_mi.material_override = fog_mat
	add_child(fog_mi)


# ─── BAZAR AU SOL ─────────────────────────────────────────────────────────────
func _build_mess():
	# Vêtements froissés (pile)
	_make_box(Vector3(-1.3, 0.065, 0.8), Vector3(0.45, 0.055, 0.38), Color(0.28, 0.24, 0.38))
	_make_box(Vector3(-1.2, 0.100, 0.85), Vector3(0.30, 0.040, 0.25), Color(0.22, 0.22, 0.25))
	_make_box(Vector3(-1.35, 0.085, 0.7), Vector3(0.20, 0.032, 0.18), Color(0.32, 0.24, 0.18))

	# Canettes vides au sol
	_make_cylinder(Vector3(0.4, 0.058, 1.1), 0.032, 0.090, Color(0.30, 0.26, 0.20))
	_make_cylinder(Vector3(0.5, 0.030, 1.1), 0.030, 0.085, Color(0.28, 0.24, 0.18))  # couchée
	_make_cylinder(Vector3(-0.2, 0.058, 1.4), 0.030, 0.088, Color(0.25, 0.22, 0.16))

	# Sac plastique froissé
	_make_box(Vector3(0.8, 0.030, 1.3), Vector3(0.22, 0.028, 0.18), Color(0.65, 0.62, 0.55, 0.7))

	# Livre tombé au sol (dos vers le haut)
	var book_mi  := MeshInstance3D.new()
	var book_mesh := BoxMesh.new()
	book_mesh.size = Vector3(0.19, 0.024, 0.13)
	book_mi.mesh  = book_mesh
	book_mi.position = Vector3(0.15, 0.012, 1.6)
	book_mi.rotation_degrees = Vector3(0, 23, 0)
	var bkm := StandardMaterial3D.new()
	bkm.albedo_color = Color(0.38, 0.15, 0.10)
	book_mi.material_override = bkm
	add_child(book_mi)

	# Poussière / peluches dans les coins
	_make_box(Vector3(-2.85, 0.002, 2.2), Vector3(0.25, 0.004, 0.12), Color(0.25, 0.22, 0.17))
	_make_box(Vector3(2.82, 0.002, 2.1), Vector3(0.20, 0.004, 0.10), Color(0.24, 0.21, 0.16))
	_make_box(Vector3(-2.82, 0.002, -2.2), Vector3(0.18, 0.004, 0.10), Color(0.24, 0.21, 0.16))

	# Bout de câble traînant
	_make_box(Vector3(-0.5, 0.004, 1.2), Vector3(0.012, 0.008, 0.65), Color(0.08, 0.07, 0.05))
	_make_box(Vector3(-0.3, 0.004, 1.52), Vector3(0.38, 0.008, 0.012), Color(0.08, 0.07, 0.05))

	# Papier froissé
	_make_box(Vector3(0.9, 0.018, 0.9), Vector3(0.12, 0.022, 0.10), Color(0.78, 0.74, 0.66))
	_make_box(Vector3(-0.8, 0.018, 1.2), Vector3(0.10, 0.020, 0.09), Color(0.80, 0.76, 0.68))

	# Chaussure isolée (l'autre est introuvable)
	_make_box(Vector3(1.5, 0.04, 0.8), Vector3(0.12, 0.06, 0.28), Color(0.18, 0.14, 0.10))
	_make_box(Vector3(1.5, 0.08, 0.9), Vector3(0.10, 0.08, 0.12), Color(0.14, 0.11, 0.08))


# ─── LUMIÈRES ────────────────────────────────────────────────────────────────
func _setup_lights():
	# ── LAMPADAIRE EXTÉRIEUR (sodium orange) ──────────────────────────────────
	# Entre les barreaux, depuis l'extérieur bas
	street_lamp_light = _add_omni_light(
		Vector3(WIN_X + 0.3, WIN_Y - WIN_H * 0.5 - 0.3, WIN_Z - 0.6),
		COL_STREET_LAMP, 2.8, 5.5
	)

	# ── Lumière froide nuit (depuis la fenêtre, haut) ─────────────────────────
	window_cold_light = _add_omni_light(
		Vector3(WIN_X, WIN_Y + 0.3, WIN_Z + 0.2),
		COL_NIGHT_COLD, 0.55, 3.5
	)

	# ── Lampe de bureau (chaud, principale) ───────────────────────────────────
	desk_lamp_light = _add_omni_light(
		Vector3(0.88, 0.95, -0.24), COL_BULB, 1.6, 1.8
	)

	# ── Ampoule plafond (quasi-éteinte) ───────────────────────────────────────
	_add_omni_light(Vector3(0.5, 2.73, -0.5), COL_BULB, 0.06, 2.0)

	# ── Lueur écran PC ────────────────────────────────────────────────────────
	_add_omni_light(Vector3(0, 1.35, 0.18), Color(0.20, 0.85, 0.40), 0.15, 0.85)

	# ── LED rouge radio (minuscule) ───────────────────────────────────────────
	_add_omni_light(Vector3(0.60, 0.826, -0.30), Color(0.8, 0.05, 0.02), 0.04, 0.25)

	# ── Reflet lampadaire sur le sol (intérieur) ──────────────────────────────
	_add_omni_light(Vector3(0.0, 0.02, -1.5), COL_STREET_LAMP, 0.18, 2.2)


func _add_omni_light(pos: Vector3, color: Color, energy: float, radius: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position     = pos
	light.light_color  = color
	light.light_energy = energy
	light.omni_range   = radius
	light.shadow_enabled = false
	add_child(light)
	return light


# ─── SCINTILLEMENT LAMPE DE BUREAU ───────────────────────────────────────────
func _start_flicker() -> void:
	await get_tree().create_timer(1.5).timeout
	while is_inside_tree():
		await get_tree().create_timer(randf_range(6.0, 22.0)).timeout
		if not lamp_enabled: continue
		# Séquence de flicker
		var flicker_n := randi_range(2, 8)
		for _i in range(flicker_n):
			if desk_lamp_light and lamp_enabled:
				desk_lamp_light.light_energy = randf_range(0.05, 0.50)
			await get_tree().create_timer(randf_range(0.03, 0.12)).timeout
			if desk_lamp_light and lamp_enabled:
				desk_lamp_light.light_energy = randf_range(1.0, 1.8)
			await get_tree().create_timer(randf_range(0.04, 0.14)).timeout
		# Extinction longue rare (2% de chance)
		if randf() < 0.02:
			if desk_lamp_light:
				desk_lamp_light.light_energy = 0.0
			await get_tree().create_timer(randf_range(0.8, 3.5)).timeout
			if desk_lamp_light and lamp_enabled:
				desk_lamp_light.light_energy = 1.6
		elif desk_lamp_light and lamp_enabled:
			desk_lamp_light.light_energy = 1.6


# ─── SCINTILLEMENT LAMPADAIRE ────────────────────────────────────────────────
func _start_street_lamp_flicker() -> void:
	await get_tree().create_timer(3.0).timeout
	while is_inside_tree():
		await get_tree().create_timer(randf_range(12.0, 40.0)).timeout
		if not street_lamp_light: continue
		var base_e := 2.8
		var n := randi_range(1, 4)
		for _i in range(n):
			street_lamp_light.light_energy = randf_range(0.3, 1.2)
			await get_tree().create_timer(randf_range(0.05, 0.18)).timeout
			street_lamp_light.light_energy = base_e
			await get_tree().create_timer(randf_range(0.06, 0.20)).timeout
		street_lamp_light.light_energy = base_e


# ─── VIGNETTE ─────────────────────────────────────────────────────────────────
func _build_vignette() -> void:
	# CanvasLayer par-dessus la 3D
	var cl := CanvasLayer.new()
	cl.layer = 10
	add_child(cl)

	var ctrl := Control.new()
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(ctrl)

	# 4 dégradés noirs sur les bords (top, bottom, left, right)
	var vigs := [
		# [position_anchor, size_anchor, color]
		[Vector2(0, 0), Vector2(1, 0.22)],   # haut
		[Vector2(0, 0.78), Vector2(1, 0.22)], # bas
		[Vector2(0, 0), Vector2(0.18, 1)],    # gauche
		[Vector2(0.82, 0), Vector2(0.18, 1)], # droite
	]

	var vig_col := Color(0.0, 0.0, 0.0, 0.72)

	for v in vigs:
		var cr := ColorRect.new()
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cr.color = vig_col
		cr.set_anchors_preset(Control.PRESET_FULL_RECT)
		# On utilise AnchorMin/Max pour positionner
		cr.anchor_left   = v[0].x
		cr.anchor_top    = v[0].y
		cr.anchor_right  = v[0].x + v[1].x
		cr.anchor_bottom = v[0].y + v[1].y
		ctrl.add_child(cr)

	# Vignette centrale (cercle simulé via ColorRect semi-transparent arrondi)
	# Simple: un rectangle noir transparent au centre pour accentuer les bords
	var center_vig := ColorRect.new()
	center_vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_vig.color = Color(0.0, 0.0, 0.0, 0.0)
	ctrl.add_child(center_vig)


# ─── CAMÉRA ──────────────────────────────────────────────────────────────────
func _setup_camera():
	camera = Camera3D.new()
	camera.position = CAM_FREE_POS
	camera.rotation_degrees = CAM_FREE_ROT
	camera.fov = 62
	add_child(camera)


# ─── INPUT ───────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == KEY_E and event.alt_pressed:
		_toggle_terminal_view()
		return

	if is_at_terminal and sub_viewport:
		sub_viewport.push_input(event)
		get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_at_terminal:
			_interact_with_object()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if not is_at_terminal:
			mouse_look = event.pressed
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mouse_look else Input.MOUSE_MODE_CONFINED

	if event is InputEventMouseMotion and mouse_look and not is_at_terminal:
		cam_rotation.x -= event.relative.y * MOUSE_SENSITIVITY
		cam_rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		cam_rotation.x = clamp(cam_rotation.x, PITCH_MIN, PITCH_MAX)
		cam_rotation.y = clamp(cam_rotation.y, YAW_MIN, YAW_MAX)
		camera.rotation_degrees = Vector3(cam_rotation.x, cam_rotation.y, 0)

	if event is InputEventMouseMotion and is_at_terminal:
		vp_cursor_pos += event.relative
		vp_cursor_pos.x = clamp(vp_cursor_pos.x, 0, VP_SIZE.x)
		vp_cursor_pos.y = clamp(vp_cursor_pos.y, 0, VP_SIZE.y)
		if os_cursor: os_cursor.move_to(vp_cursor_pos)
		if os_main:   os_main.on_cursor_move(vp_cursor_pos)
		var vpe := InputEventMouseMotion.new()
		vpe.position = vp_cursor_pos
		vpe.global_position = vp_cursor_pos
		vpe.relative = event.relative
		sub_viewport.push_input(vpe)
		get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and is_at_terminal:
		if os_main: os_main.on_cursor_press(vp_cursor_pos, event.pressed)
		_send_mouse_to_viewport(event)
		get_viewport().set_input_as_handled()


func _interact_with_object():
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	var lamp_pos := Vector3(0.88, 0.95, -0.24)
	var L := lamp_pos - ray_origin
	var tca := L.dot(ray_dir)
	var d2 := L.dot(L) - tca * tca
	if d2 < 0.12 * 0.12:
		_toggle_lamp()


func _toggle_lamp():
	lamp_enabled = !lamp_enabled
	if desk_lamp_light:
		var lt := create_tween()
		lt.tween_property(desk_lamp_light, "light_energy", 1.6 if lamp_enabled else 0.0, 0.10)


func _toggle_terminal_view():
	is_at_terminal = !is_at_terminal
	if tween: tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)

	if is_at_terminal:
		tween.tween_property(camera, "position", CAM_TERMINAL_POS, 0.6)
		tween.tween_property(camera, "rotation_degrees", CAM_TERMINAL_ROT, 0.6)
		tween.chain().tween_callback(func():
			sub_viewport.handle_input_locally = true
			sub_viewport.gui_disable_input = false
			sub_viewport.push_input(InputEventKey.new())
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			_find_os_cursor()
		)
	else:
		sub_viewport.handle_input_locally = false
		sub_viewport.gui_disable_input = true
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED
		os_cursor = null
		tween.tween_property(camera, "position", CAM_FREE_POS, 0.6)
		tween.tween_property(camera, "rotation_degrees", CAM_FREE_ROT, 0.6)


# ─── CURSEUR OS ──────────────────────────────────────────────────────────────
func _find_os_cursor():
	var os_node := sub_viewport.get_node_or_null("OS")
	if os_node:
		os_cursor = os_node.get_node_or_null("CursorLayer/Cursor")
		os_main   = os_node


func _send_mouse_to_viewport(event: InputEventMouseButton):
	var move_event := InputEventMouseMotion.new()
	move_event.position = vp_cursor_pos
	move_event.global_position = vp_cursor_pos
	move_event.relative = Vector2.ZERO
	sub_viewport.push_input(move_event)
	var vp_event := InputEventMouseButton.new()
	vp_event.button_index = event.button_index
	vp_event.pressed = event.pressed
	vp_event.position = vp_cursor_pos
	vp_event.global_position = vp_cursor_pos
	sub_viewport.push_input(vp_event)


# ─── OVERLAY CRT ─────────────────────────────────────────────────────────────
func _build_crt_overlay() -> void:
	if not sub_viewport: return

	var layer := CanvasLayer.new()
	layer.layer = 100
	sub_viewport.add_child(layer)

	var vp := Vector2(float(sub_viewport.size.x), float(sub_viewport.size.y))

	var scanline_root := Control.new()
	scanline_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(scanline_root)

	var spacing := 5.5
	var idx := 0
	while idx * spacing < vp.y + spacing:
		var line := ColorRect.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.size = Vector2(vp.x, 1.0)
		line.position = Vector2(0.0, idx * spacing)
		line.color = Color(0.0, 0.0, 0.0, 0.055)
		scanline_root.add_child(line)
		idx += 1

	var band_group := Control.new()
	band_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(band_group)

	var band_specs := [
		[40.0, Color(0.55, 1.0, 0.55, 0.004)],
		[24.0, Color(0.65, 1.0, 0.65, 0.011)],
		[14.0, Color(0.80, 1.0, 0.80, 0.022)],
		[24.0, Color(0.65, 1.0, 0.65, 0.011)],
		[40.0, Color(0.55, 1.0, 0.55, 0.004)],
	]

	var y := 0.0
	for spec in band_specs:
		var h: float = spec[0]
		var col: Color = spec[1]
		var rect := ColorRect.new()
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.size = Vector2(vp.x, h)
		rect.position = Vector2(0.0, y)
		rect.color = col
		band_group.add_child(rect)
		y += h

	var band_h := y
	band_group.position.y = -band_h
	_run_phosphor_sweep(band_group, vp.y, band_h)


func _run_phosphor_sweep(band_group: Control, vp_h: float, band_h: float) -> void:
	while is_inside_tree():
		band_group.position.y = -band_h
		var tw := create_tween()
		tw.tween_property(band_group, "position:y", vp_h + 10.0, 5.5).set_trans(Tween.TRANS_LINEAR)
		await tw.finished
		await get_tree().create_timer(randf_range(0.0, 0.2)).timeout


# ─── HELPERS MESH ─────────────────────────────────────────────────────────────
func _make_box(pos: Vector3, size: Vector3, color: Color, emissive: bool = false) -> MeshInstance3D:
	var mi   := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh   = mesh
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


func _make_box_with_mat(pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi   := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh   = mesh
	mi.position = pos
	mi.material_override = mat
	add_child(mi)
	return mi


func _make_cylinder(pos: Vector3, radius: float, height: float, color: Color, emissive: bool = false) -> MeshInstance3D:
	var mi   := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius    = radius
	mesh.bottom_radius = radius
	mesh.height        = height
	mi.mesh   = mesh
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if emissive:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.8
	mi.material_override = mat
	add_child(mi)
	return mi
