# room_scene.gd  v4  — polish pass : vignette shader + objets détaillés
extends Node3D

# ─── Palette ─────────────────────────────────────────────────────────────────
const COL_WALL          := Color(0.38, 0.34, 0.28)
const COL_WALL_DARK     := Color(0.22, 0.19, 0.15)
const COL_WALL_STAIN    := Color(0.18, 0.15, 0.10)
const COL_FLOOR         := Color(0.22, 0.15, 0.09)
const COL_FLOOR_DARK    := Color(0.14, 0.09, 0.05)
const COL_CEILING       := Color(0.32, 0.29, 0.24)
const COL_CEILING_STAIN := Color(0.22, 0.18, 0.13)
const COL_WOOD_DARK     := Color(0.18, 0.11, 0.06)
const COL_WOOD_MED      := Color(0.28, 0.19, 0.10)
const COL_WOOD_LIGHT    := Color(0.40, 0.29, 0.17)
const COL_METAL_RUST    := Color(0.28, 0.20, 0.13)
const COL_METAL_DARK    := Color(0.15, 0.14, 0.12)
const COL_DESK_SCREEN   := Color(0.12, 0.12, 0.14)
const COL_BULB          := Color(1.0, 0.78, 0.42)
const COL_STREET_LAMP   := Color(1.0, 0.60, 0.18)
const COL_NIGHT_COLD    := Color(0.35, 0.45, 0.65)

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
var lamp_enabled      := true
var street_lamp_light: OmniLight3D
var window_cold_light: OmniLight3D
var sun_light: DirectionalLight3D
var screen_glow_light: OmniLight3D
var env_ref: Environment
var is_day_mode := false
var day_tween: Tween
var vignette_cr: ColorRect

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
	env.background_mode  = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color  = Color(0.08, 0.07, 0.06)
	env.ambient_light_energy = 1.2

	env.volumetric_fog_enabled      = true
	env.volumetric_fog_density      = 0.018
	env.volumetric_fog_albedo       = Color(0.75, 0.70, 0.62)
	env.volumetric_fog_emission     = Color(0, 0, 0)
	env.volumetric_fog_anisotropy   = 0.5
	env.volumetric_fog_length       = 24.0
	env.volumetric_fog_detail_spread = 2.0
	env.volumetric_fog_gi_inject    = 1.0

	env.fog_enabled     = true
	env.fog_light_color = Color(0.05, 0.04, 0.03)
	env.fog_density     = 0.015

	env.glow_enabled       = true
	env.glow_intensity     = 0.6
	env.glow_bloom         = 0.2
	env.glow_hdr_threshold = 0.7

	env.ssr_enabled         = true
	env.ssr_max_steps       = 64
	env.ssr_fade_in         = 0.15
	env.ssr_fade_out        = 2.0
	env.ssr_depth_tolerance = 0.2

	env.ssao_enabled   = true
	env.ssao_radius    = 1.8
	env.ssao_intensity = 2.5
	env.ssao_power     = 1.2

	env.ssil_enabled   = true
	env.ssil_radius    = 2.5
	env.ssil_intensity = 1.0

	env.adjustment_enabled    = true
	env.adjustment_brightness = 0.95
	env.adjustment_contrast   = 1.20
	env.adjustment_saturation = 0.72

	env_ref = env
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


# ─── PIÈCE ────────────────────────────────────────────────────────────────────
func _build_room():
	# Sol — parquet sombre avec lames plus définies
	_make_box(Vector3(0, -0.05, 0), Vector3(6.0, 0.1, 5.0), COL_FLOOR)
	for i in range(7):
		_make_box(Vector3(-3.0 + i * 1.0, 0.001, 0), Vector3(0.018, 0.001, 5.0), COL_FLOOR_DARK)
	# Fissures/veines dans le bois
	for i in range(5):
		_make_box(Vector3(-2.0 + i * 0.8, 0.001, 0), Vector3(0.005, 0.001, randf_range(1.5, 4.5)), Color(0.12, 0.08, 0.04))
	# Traces / usure au sol
	_make_box(Vector3(-0.3, 0.001, 0.5), Vector3(1.2, 0.001, 0.6), Color(0.18, 0.12, 0.07))
	_make_box(Vector3(-1.6, 0.001, -0.2), Vector3(0.5, 0.001, 0.4), Color(0.16, 0.10, 0.06))

	# Plafond avec moulure périmétrique
	_make_box(Vector3(0, 3.05, 0), Vector3(6.0, 0.1, 5.0), COL_CEILING)
	_make_box(Vector3(-1.2, 3.04, -0.4), Vector3(1.2, 0.01, 0.9), COL_CEILING_STAIN)
	_make_box(Vector3(0.8, 3.04, 0.5),  Vector3(0.7, 0.01, 0.5), COL_CEILING_STAIN)
	# Moulures plafond (corniche)
	var mc := Color(0.30, 0.27, 0.22)
	_make_box(Vector3(0,    3.0, -2.45), Vector3(6.0, 0.055, 0.055), mc)
	_make_box(Vector3(0,    3.0,  2.45), Vector3(6.0, 0.055, 0.055), mc)
	_make_box(Vector3(-2.95, 3.0, 0),   Vector3(0.055, 0.055, 5.0), mc)
	_make_box(Vector3(2.95,  3.0, 0),   Vector3(0.055, 0.055, 5.0), mc)
	# Fissure plafond
	_make_box(Vector3(0.3, 3.04, -0.6), Vector3(0.006, 0.005, 0.9), Color(0.18, 0.14, 0.10))
	_make_box(Vector3(0.5, 3.04, -0.3), Vector3(0.28, 0.005, 0.005), Color(0.18, 0.14, 0.10))
	# Branchement crack
	_make_box(Vector3(0.38, 3.04, -0.48), Vector3(0.004, 0.004, 0.22), Color(0.16, 0.12, 0.09))

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

	# Détails mur arrière — taches + fissures réseau
	_make_box(Vector3(-2.2, 0.55, -2.44), Vector3(0.9, 0.7, 0.01), COL_WALL_STAIN)
	_make_box(Vector3(2.3,  0.8,  -2.44), Vector3(0.4, 0.5, 0.01), COL_WALL_STAIN)
	_make_box(Vector3(2.1,  2.5,  -2.44), Vector3(0.6, 0.2, 0.01), COL_WALL_DARK)
	# Réseau de fissures en bas-gauche
	_make_box(Vector3(-2.0, 2.70, -2.44), Vector3(0.006, 0.55, 0.005), COL_WALL_DARK)
	_make_box(Vector3(-1.96, 2.52, -2.44), Vector3(0.15, 0.005, 0.005), COL_WALL_DARK)
	_make_box(Vector3(-2.0, 2.25, -2.44), Vector3(0.005, 0.28, 0.005), COL_WALL_DARK)
	_make_box(Vector3(-1.88, 2.35, -2.44), Vector3(0.004, 0.18, 0.004), COL_WALL_DARK)

	# ── Mur GAUCHE ──────────────────────────────────────────────────────────
	_make_box(Vector3(-3.0, 1.5, 0), Vector3(0.12, 3.0, 5.0), COL_WALL)
	_make_box(Vector3(-2.95, 0.50, -1.5), Vector3(0.02, 1.1, 0.9), COL_WALL_STAIN)
	_make_box(Vector3(-2.95, 0.22, 0.8),  Vector3(0.02, 0.55, 0.6), COL_WALL_STAIN)
	_make_box(Vector3(-2.95, 1.2,  1.0),  Vector3(0.02, 0.40, 0.3), COL_WALL_DARK)
	# Papier peint décollé
	_make_box(Vector3(-2.975, 0.38, 1.85), Vector3(0.008, 0.65, 0.55), Color(0.48, 0.42, 0.34))
	_make_box(Vector3(-2.97,  0.22, 2.0),  Vector3(0.010, 0.30, 0.25), Color(0.42, 0.36, 0.28))
	# Fissures mur gauche
	_make_box(Vector3(-2.94, 1.85, -0.8), Vector3(0.005, 0.50, 0.005), COL_WALL_DARK)
	_make_box(Vector3(-2.94, 1.68, -0.6), Vector3(0.005, 0.20, 0.005), COL_WALL_DARK)
	_make_box(Vector3(-2.94, 2.10, -1.1), Vector3(0.004, 0.30, 0.004), COL_WALL_DARK)

	# ── Mur DROIT ───────────────────────────────────────────────────────────
	_make_box(Vector3(3.0, 1.5, 0), Vector3(0.12, 3.0, 5.0), COL_WALL)
	_make_box(Vector3(2.95, 0.6, 1.2), Vector3(0.02, 0.8, 0.6), COL_WALL_STAIN)
	_make_box(Vector3(2.95, 1.9, 0.5), Vector3(0.02, 0.35, 0.28), COL_WALL_DARK)

	# ── Mur AVANT ───────────────────────────────────────────────────────────
	_make_box(Vector3(0, 1.5, 2.5), Vector3(6.0, 3.0, 0.12), COL_WALL)
	_make_box(Vector3(1.0, 0.8, 2.44), Vector3(0.35, 0.5, 0.01), COL_WALL_STAIN)

	# ── Plinthes ────────────────────────────────────────────────────────────
	var ph := 0.13
	var pc := COL_WOOD_DARK
	_make_box(Vector3(0,     ph*0.5, -2.44), Vector3(6.0, ph, 0.04), pc)
	_make_box(Vector3(-2.94, ph*0.5,  0),    Vector3(0.04, ph, 5.0), pc)
	_make_box(Vector3(2.94,  ph*0.5,  0),    Vector3(0.04, ph, 5.0), pc)
	_make_box(Vector3(0,     ph*0.5,  2.44), Vector3(6.0, ph, 0.04), pc)
	# Haut des plinthes (petit listel)
	var lc := Color(0.22, 0.14, 0.08)
	_make_box(Vector3(0,     ph + 0.006, -2.44), Vector3(6.0, 0.012, 0.042), lc)
	_make_box(Vector3(-2.94, ph + 0.006, 0),     Vector3(0.042, 0.012, 5.0), lc)
	_make_box(Vector3(2.94,  ph + 0.006, 0),     Vector3(0.042, 0.012, 5.0), lc)
	_make_box(Vector3(0,     ph + 0.006,  2.44), Vector3(6.0, 0.012, 0.042), lc)

	# Câbles électriques en surface de mur
	_make_box(Vector3(-2.94, 1.5, -0.2), Vector3(0.018, 2.8, 0.018), Color(0.10, 0.08, 0.06))
	_make_box(Vector3(-2.94, 1.5,  0.8), Vector3(0.014, 2.2, 0.014), Color(0.08, 0.07, 0.05))


# ─── FENÊTRE ─────────────────────────────────────────────────────────────────
func _build_window():
	var fw2 := WIN_W * 0.5
	var fh2 := WIN_H * 0.5
	var ft  := 0.065
	var bt  := 0.030
	var fc  := COL_WOOD_LIGHT

	# Cadre extérieur — avec face avant légèrement plus claire (bord exposé)
	_make_box(Vector3(WIN_X, WIN_Y + fh2 + ft*0.5, WIN_Z), Vector3(WIN_W + ft*2, ft, 0.10), fc)
	_make_box(Vector3(WIN_X, WIN_Y - fh2 - ft*0.5, WIN_Z), Vector3(WIN_W + ft*2, ft, 0.10), fc)
	_make_box(Vector3(WIN_X - fw2 - ft*0.5, WIN_Y, WIN_Z), Vector3(ft, WIN_H, 0.10), fc)
	_make_box(Vector3(WIN_X + fw2 + ft*0.5, WIN_Y, WIN_Z), Vector3(ft, WIN_H, 0.10), fc)
	# Bords intérieurs du cadre (retours)
	var fi := Color(0.35, 0.25, 0.13)
	_make_box(Vector3(WIN_X, WIN_Y + fh2 + ft*0.5, WIN_Z + 0.03), Vector3(WIN_W + ft*2, ft - 0.012, 0.04), fi)
	_make_box(Vector3(WIN_X, WIN_Y - fh2 - ft*0.5, WIN_Z + 0.03), Vector3(WIN_W + ft*2, ft - 0.012, 0.04), fi)

	# Barreaux intérieurs
	for i in range(1, WIN_COLS):
		var bx := WIN_X - fw2 + (WIN_W / WIN_COLS) * i
		_make_box(Vector3(bx, WIN_Y, WIN_Z), Vector3(bt, WIN_H, 0.08), fc)
	for i in range(1, WIN_ROWS):
		var by := WIN_Y - fh2 + (WIN_H / WIN_ROWS) * i
		_make_box(Vector3(WIN_X, by, WIN_Z), Vector3(WIN_W, bt, 0.08), fc)

	# Vitres
	var cell_w := WIN_W / WIN_COLS
	var cell_h := WIN_H / WIN_ROWS
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color     = Color(0.55, 0.65, 0.80, 0.08)
	glass_mat.transparency     = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness        = 0.0
	glass_mat.metallic         = 0.08
	glass_mat.emission_enabled = true
	glass_mat.emission         = Color(0.30, 0.38, 0.55)
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

	# Tablette fenêtre en bois peint — avec bord arrondi simulé
	_make_box(Vector3(WIN_X, WIN_Y - fh2 - ft - 0.025, WIN_Z + 0.14),
			  Vector3(WIN_W + ft*2 + 0.12, 0.048, 0.30), COL_WOOD_LIGHT)
	# Nez de tablette (arête avant légèrement différente)
	_make_box(Vector3(WIN_X, WIN_Y - fh2 - ft - 0.006, WIN_Z + 0.285),
			  Vector3(WIN_W + ft*2 + 0.12, 0.012, 0.014), Color(0.36, 0.26, 0.14))
	# Tache + eau sèche sur tablette
	_make_box(Vector3(0.3, WIN_Y - fh2 - ft - 0.0, WIN_Z + 0.18),
			  Vector3(0.12, 0.002, 0.09), Color(0.22, 0.18, 0.12))
	_make_box(Vector3(-0.55, WIN_Y - fh2 - ft + 0.001, WIN_Z + 0.22),
			  Vector3(0.06, 0.001, 0.06), Color(0.26, 0.21, 0.14))


# ─── EXTÉRIEUR ───────────────────────────────────────────────────────────────
func _build_outside_view():
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

	# Bâtiment sombre
	var bld_mat := StandardMaterial3D.new()
	bld_mat.albedo_color = Color(0.06, 0.06, 0.08)
	bld_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_make_box_with_mat(Vector3(-0.6, 2.1, WIN_Z - 1.4), Vector3(1.1, 2.5, 0.04), bld_mat)

	# Fenêtres du bâtiment
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

	# Enseigne rouge angoissante
	var sign_mat := StandardMaterial3D.new()
	sign_mat.shading_mode    = BaseMaterial3D.SHADING_MODE_UNSHADED
	sign_mat.albedo_color    = Color(0.6, 0.05, 0.05)
	sign_mat.emission_enabled = true
	sign_mat.emission        = Color(0.55, 0.02, 0.02)
	sign_mat.emission_energy_multiplier = 0.8
	_make_box_with_mat(Vector3(0.9, 2.3, WIN_Z - 1.5), Vector3(0.35, 0.08, 0.02), sign_mat)

	# Lueur lampadaire sol extérieur
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
	# Plateau — avec grain et bord avant
	_make_box(Vector3(0, 0.750, 0),    Vector3(2.4, 0.055, 1.0), COL_WOOD_DARK)
	# Bord avant (bois légèrement plus clair = lumière rasante)
	_make_box(Vector3(0, 0.750, 0.502), Vector3(2.4, 0.053, 0.014), Color(0.22, 0.14, 0.08))
	# Bord latéral gauche
	_make_box(Vector3(-1.202, 0.750, 0), Vector3(0.010, 0.053, 1.0), Color(0.20, 0.13, 0.07))
	# Filet de grain
	_make_box(Vector3(0, 0.773, 0.40), Vector3(2.4, 0.008, 0.008), COL_WOOD_MED)
	_make_box(Vector3(0, 0.773, 0.10), Vector3(2.4, 0.006, 0.006), Color(0.22, 0.14, 0.07))
	_make_box(Vector3(0, 0.773, -0.20), Vector3(1.5, 0.005, 0.005), Color(0.20, 0.13, 0.06))

	# Pieds métalliques (4) avec légère rouille
	for sx in [-1.1, 1.1]:
		for sz in [0.0, -0.45]:
			_make_box(Vector3(sx, 0.37, sz), Vector3(0.055, 0.75, 0.055), COL_METAL_RUST)
			# Pied : détail de soudure en bas
			_make_box(Vector3(sx, 0.04, sz), Vector3(0.062, 0.016, 0.062), COL_METAL_DARK)
	# Traverse basse
	_make_box(Vector3(0, 0.20, -0.2), Vector3(2.2, 0.028, 0.04), COL_METAL_DARK)

	# Tiroir (corps + façade + poignée)
	_make_box(Vector3(0.82, 0.56, 0.0), Vector3(0.58, 0.22, 0.92), Color(0.16, 0.10, 0.06))
	# Façade tiroir (bois légèrement différent)
	_make_box(Vector3(0.82, 0.56, 0.462), Vector3(0.56, 0.20, 0.012), Color(0.20, 0.13, 0.08))
	# Rainure décorative façade
	_make_box(Vector3(0.82, 0.56, 0.470), Vector3(0.52, 0.005, 0.008), Color(0.14, 0.09, 0.05))
	# Poignée tiroir (cylindrique)
	_make_cylinder(Vector3(0.82, 0.56, 0.474), 0.011, 0.09, COL_METAL_RUST)
	# Panneau arrière bureau
	_make_box(Vector3(0, 0.37, -0.5), Vector3(2.3, 0.7, 0.02), Color(0.14, 0.09, 0.05))


# ─── MONITEUR ────────────────────────────────────────────────────────────────
func _build_monitor():
	# Base du moniteur — pied + socle
	_make_box(Vector3(0, 0.793, -0.25), Vector3(0.22, 0.022, 0.22), COL_METAL_DARK)
	# Bord socle
	_make_box(Vector3(0, 0.800, -0.25), Vector3(0.22, 0.006, 0.22), Color(0.20, 0.19, 0.17))
	_make_box(Vector3(0, 0.875, -0.29), Vector3(0.034, 0.165, 0.034), COL_METAL_DARK)
	# Châssis moniteur
	_make_box(Vector3(0, 1.35, -0.32), Vector3(1.3, 0.82, 0.055), COL_DESK_SCREEN)
	# Bord interne / bezel
	_make_box(Vector3(0, 1.35, -0.296), Vector3(1.26, 0.78, 0.012), Color(0.09, 0.09, 0.11))
	# Écran
	_make_box(Vector3(0, 1.35, -0.295), Vector3(1.22, 0.74, 0.010), Color(0.07, 0.07, 0.09))
	# Fentes de ventilation en bas de châssis
	for i in range(6):
		_make_box(Vector3(-0.22 + i * 0.082, 0.958, -0.294), Vector3(0.038, 0.009, 0.006), Color(0.08, 0.08, 0.10))
	# LED de statut bleu (droite bas)
	_make_box(Vector3(0.58, 0.970, -0.294), Vector3(0.010, 0.010, 0.003), Color(0.0, 0.3, 1.0), true)
	# Câble moniteur vers bas
	_make_box(Vector3(0.1, 0.90, -0.348), Vector3(0.012, 0.9, 0.012), Color(0.08, 0.07, 0.06))

	if sub_viewport:
		sub_viewport.size = Vector2i(1152, 648)
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		sub_viewport.gui_disable_input = true
		sub_viewport.handle_input_locally = false


# ─── CLAVIER ─────────────────────────────────────────────────────────────────
func _build_keyboard():
	# Boîtier clavier (légèrement incliné simulé via épaisseur avant/arrière)
	_make_box(Vector3(0, 0.784, 0.20), Vector3(0.92, 0.022, 0.36), Color(0.26, 0.23, 0.19))
	# Bord avant plus fin (forme inclinée)
	_make_box(Vector3(0, 0.782, 0.375), Vector3(0.92, 0.010, 0.012), Color(0.22, 0.19, 0.15))
	# Bord arrière
	_make_box(Vector3(0, 0.784, 0.015), Vector3(0.92, 0.024, 0.012), Color(0.24, 0.21, 0.17))

	var kc1 := Color(0.25, 0.22, 0.18)  # touche normale vieillie
	var kc2 := Color(0.20, 0.17, 0.14)  # touche plus sombre (alternance)
	var kc3 := Color(0.23, 0.20, 0.16)  # modificateurs

	# Rangée F-keys (plus petites, en haut)
	for col in range(12):
		_make_box(Vector3(-0.41 + col * 0.072, 0.797, 0.045),
				  Vector3(0.058, 0.007, 0.040), kc2)

	# Rangée chiffres (10 touches)
	for col in range(13):
		var c := kc1 if col % 3 != 0 else kc2
		_make_box(Vector3(-0.41 + col * 0.068, 0.797, 0.108),
				  Vector3(0.057, 0.009, 0.052), c)

	# 4 rangées principales
	for row in range(4):
		for col in range(13):
			var c := kc1 if (row + col) % 4 != 0 else kc2
			_make_box(Vector3(-0.41 + col * 0.068, 0.799, 0.175 + row * 0.058),
					  Vector3(0.057, 0.010, 0.048), c)

	# Barre espace (large)
	_make_box(Vector3(0.04, 0.800, 0.360), Vector3(0.34, 0.010, 0.048), Color(0.28, 0.25, 0.21))

	# Modificateurs gauche (Shift, Ctrl, Alt — plus larges)
	_make_box(Vector3(-0.35, 0.799, 0.302), Vector3(0.095, 0.009, 0.048), kc3)
	_make_box(Vector3(-0.37, 0.799, 0.360), Vector3(0.088, 0.009, 0.048), kc3)
	_make_box(Vector3( 0.36, 0.799, 0.302), Vector3(0.080, 0.009, 0.048), kc3)

	# LED status (vert Caps Lock)
	_make_box(Vector3(0.42, 0.801, 0.048), Vector3(0.006, 0.004, 0.006), Color(0.0, 0.8, 0.1), true)


# ─── RADIO ───────────────────────────────────────────────────────────────────
func _build_radio():
	# Corps
	_make_box(Vector3(0.75, 0.815, -0.38), Vector3(0.28, 0.12, 0.15), Color(0.25, 0.20, 0.14))
	# Arêtes de la radio (bandes légèrement différentes pour casser le bloc)
	_make_box(Vector3(0.75, 0.877, -0.38), Vector3(0.28, 0.008, 0.152), Color(0.20, 0.16, 0.11))
	_make_box(Vector3(0.75, 0.753, -0.38), Vector3(0.28, 0.008, 0.152), Color(0.20, 0.16, 0.11))
	# Face avant
	_make_box(Vector3(0.75, 0.815, -0.305), Vector3(0.26, 0.10, 0.006), Color(0.30, 0.25, 0.18))
	# Grille speaker
	for i in range(5):
		_make_box(Vector3(0.68 + i * 0.025, 0.815, -0.302), Vector3(0.008, 0.08, 0.005), Color(0.18, 0.14, 0.10))
	# Cadran
	_make_box(Vector3(0.62, 0.825, -0.302), Vector3(0.08, 0.03, 0.005), Color(0.08, 0.04, 0.04))
	_make_box(Vector3(0.60, 0.825, -0.300), Vector3(0.02, 0.016, 0.002), Color(0.8, 0.05, 0.05), true)
	# Antenne articulée (2 segments légèrement désaxés)
	_make_box(Vector3(0.870, 0.885, -0.360), Vector3(0.010, 0.130, 0.010), Color(0.22, 0.18, 0.14))
	_make_box(Vector3(0.892, 0.948, -0.368), Vector3(0.008, 0.110, 0.008), Color(0.22, 0.18, 0.14))
	# Joint d'antenne
	_make_cylinder(Vector3(0.880, 0.878, -0.362), 0.013, 0.018, COL_METAL_DARK)
	# Boutons
	_make_cylinder(Vector3(0.790, 0.826, -0.302), 0.012, 0.015, Color(0.20, 0.16, 0.12))
	_make_cylinder(Vector3(0.820, 0.826, -0.302), 0.010, 0.015, Color(0.20, 0.16, 0.12))
	# Câble d'alimentation
	_make_box(Vector3(0.60, 0.785, -0.38), Vector3(0.012, 0.006, 0.4), Color(0.10, 0.08, 0.06))


# ─── LIT ──────────────────────────────────────────────────────────────────────
func _build_bed():
	# Tête de lit — avec panneaux verticaux sculptés
	_make_box(Vector3(-2.36, 1.0, -1.5), Vector3(0.08, 1.25, 1.9), COL_WOOD_DARK)
	# Panneaux sculptés (retraits dans la tête de lit)
	for i in range(3):
		_make_box(Vector3(-2.313, 0.85, -1.82 + i * 0.65),
				  Vector3(0.018, 0.82, 0.50), Color(0.14, 0.09, 0.05))
	# Rail horizontal de tête de lit (bas + haut)
	_make_box(Vector3(-2.36, 0.44, -1.5), Vector3(0.082, 0.06, 1.9), Color(0.22, 0.14, 0.08))
	_make_box(Vector3(-2.36, 1.58, -1.5), Vector3(0.082, 0.06, 1.9), Color(0.22, 0.14, 0.08))
	# Pied de lit avant
	_make_box(Vector3(-2.36, 0.44, 0.55), Vector3(0.08, 0.52, 0.10), COL_WOOD_DARK)

	# Châssis lit — lattes visibles
	_make_box(Vector3(-1.82, 0.24, -0.5), Vector3(1.02, 0.04, 2.0), COL_WOOD_DARK)
	for i in range(7):
		_make_box(Vector3(-1.82, 0.268, -1.35 + i * 0.38), Vector3(0.95, 0.020, 0.058), COL_WOOD_MED)
		# Ombre entre lattes
		_make_box(Vector3(-1.82, 0.258, -1.31 + i * 0.38), Vector3(0.90, 0.008, 0.008), COL_WOOD_DARK)

	# Matelas (vieux, affaissé) avec bandes de ticking
	_make_box(Vector3(-1.82, 0.50, -0.5), Vector3(1.0, 0.23, 2.0), Color(0.35, 0.30, 0.24))
	# Bandes de ticking (tissu matelas)
	for i in range(5):
		_make_box(Vector3(-1.82, 0.617, -1.25 + i * 0.50), Vector3(0.995, 0.002, 0.045), Color(0.28, 0.24, 0.19))
	# Boutons de capitonnage
	for i in range(3):
		_make_cylinder(Vector3(-1.82, 0.620, -1.0 + i * 0.5), 0.012, 0.014, Color(0.30, 0.26, 0.20))

	# Draps froissés — couches multiples pour volume
	_make_box(Vector3(-1.70, 0.648, -0.38), Vector3(0.78, 0.058, 0.82), Color(0.50, 0.46, 0.40))
	_make_box(Vector3(-1.92, 0.672, 0.05),  Vector3(0.52, 0.075, 0.48), Color(0.44, 0.40, 0.35))
	_make_box(Vector3(-1.60, 0.660, 0.28),  Vector3(0.62, 0.052, 0.38), Color(0.52, 0.48, 0.42))
	_make_box(Vector3(-1.82, 0.658, -1.30), Vector3(0.95, 0.038, 0.08), Color(0.55, 0.50, 0.44))
	# Pli du drap au pied du lit
	_make_box(Vector3(-1.82, 0.660, 0.62),  Vector3(0.95, 0.062, 0.06), Color(0.48, 0.44, 0.38))

	# Oreiller (affaissé) — 2 moitiés + pli central
	_make_box(Vector3(-1.82, 0.630, -1.30), Vector3(0.75, 0.115, 0.40), Color(0.60, 0.56, 0.50))
	# Pli central de l'oreiller
	_make_box(Vector3(-1.82, 0.644, -1.30), Vector3(0.005, 0.120, 0.38), Color(0.52, 0.48, 0.43))
	# Froissement surface oreiller
	_make_box(Vector3(-1.76, 0.690, -1.30), Vector3(0.38, 0.008, 0.26), Color(0.55, 0.51, 0.45))
	_make_box(Vector3(-1.88, 0.688, -1.20), Vector3(0.22, 0.006, 0.14), Color(0.53, 0.49, 0.44))


# ─── DÉCORATIONS ─────────────────────────────────────────────────────────────
func _build_decorations():
	# ── Lampe de bureau — bras articulé ──
	_make_cylinder(Vector3(0.90, 0.781, -0.10), 0.060, 0.013, COL_METAL_DARK) # base
	_make_cylinder(Vector3(0.90, 0.790, -0.10), 0.042, 0.009, Color(0.12, 0.11, 0.09)) # col base
	# Bras bas (vertical)
	_make_box(Vector3(0.90, 0.880, -0.10), Vector3(0.018, 0.200, 0.018), COL_METAL_RUST)
	# Joint coude
	_make_cylinder(Vector3(0.90, 0.980, -0.10), 0.016, 0.025, COL_METAL_DARK)
	# Bras haut (légèrement incliné vers l'avant en simulant une position)
	_make_box(Vector3(0.885, 0.995, -0.165), Vector3(0.016, 0.016, 0.122), COL_METAL_RUST)
	# Second coude
	_make_cylinder(Vector3(0.885, 0.994, -0.228), 0.014, 0.022, COL_METAL_DARK)
	# Abat-jour
	_make_box(Vector3(0.880, 0.972, -0.248), Vector3(0.118, 0.062, 0.115), Color(0.32, 0.24, 0.15))
	_make_box(Vector3(0.880, 0.938, -0.248), Vector3(0.098, 0.018, 0.094), Color(0.25, 0.18, 0.12))
	# Intérieur abat-jour (blanc cassé réfléchissant)
	_make_box(Vector3(0.880, 0.956, -0.248), Vector3(0.090, 0.044, 0.086), Color(0.72, 0.68, 0.58))
	_make_cylinder(Vector3(0.880, 0.958, -0.248), 0.020, 0.038, Color(1.0, 0.95, 0.80), true)

	# ── Tasse avec fond de café séché ──
	_make_cylinder(Vector3(-0.85, 0.875, 0.12), 0.050, 0.090, Color(0.32, 0.28, 0.22))
	# Anneau de fond (cerclage)
	_make_cylinder(Vector3(-0.85, 0.830, 0.12), 0.052, 0.008, Color(0.28, 0.24, 0.19))
	_make_cylinder(Vector3(-0.85, 0.920, 0.12), 0.042, 0.010, Color(0.08, 0.04, 0.01))
	_make_box(Vector3(-0.80, 0.875, 0.12), Vector3(0.028, 0.048, 0.010), Color(0.32, 0.28, 0.22))
	# Tache séchée sur la soucoupe
	_make_cylinder(Vector3(-0.85, 0.830, 0.12), 0.065, 0.002, Color(0.24, 0.18, 0.10))

	# ── Cendrier avec mégots ──
	_make_cylinder(Vector3(-0.60, 0.788, 0.25), 0.058, 0.018, Color(0.30, 0.26, 0.20))
	_make_cylinder(Vector3(-0.60, 0.796, 0.25), 0.048, 0.010, Color(0.22, 0.18, 0.13))
	for i in range(3):
		var angle := i * 1.4
		_make_box(Vector3(-0.60 + cos(angle) * 0.03, 0.800, 0.25 + sin(angle) * 0.03),
				  Vector3(0.006, 0.004, 0.038), Color(0.55, 0.40, 0.28))
	# Cendre résiduelle (grise) au fond du cendrier
	_make_cylinder(Vector3(-0.60, 0.798, 0.25), 0.040, 0.003, Color(0.42, 0.40, 0.38))

	# ── Livre ouvert — pages + lignes de texte ──
	_make_box(Vector3(-1.02, 0.787, -0.14), Vector3(0.26, 0.018, 0.18), Color(0.48, 0.38, 0.26))
	# Dos du livre (pli central)
	_make_box(Vector3(-1.020, 0.793, -0.14), Vector3(0.005, 0.010, 0.175), Color(0.38, 0.28, 0.16))
	# Pages droite
	_make_box(Vector3(-0.900, 0.798, -0.14), Vector3(0.11, 0.004, 0.16), Color(0.88, 0.84, 0.76))
	# Pages gauche
	_make_box(Vector3(-1.140, 0.798, -0.14), Vector3(0.11, 0.004, 0.16), Color(0.86, 0.82, 0.74))
	# Lignes de texte sur les pages
	for ln in range(7):
		var lw2 := 0.082 if ln % 3 != 2 else 0.052
		_make_box(Vector3(-0.900, 0.803, -0.19 + ln * 0.026), Vector3(lw2, 0.002, 0.004), Color(0.28, 0.22, 0.16))
	for ln in range(7):
		var lw2 := 0.078 if ln % 2 != 1 else 0.060
		_make_box(Vector3(-1.140, 0.803, -0.19 + ln * 0.026), Vector3(lw2, 0.002, 0.004), Color(0.28, 0.22, 0.16))

	# ── Stylo / crayon sur le bureau ──
	_make_box(Vector3(-0.30, 0.789, 0.30), Vector3(0.008, 0.008, 0.145), Color(0.18, 0.14, 0.10))
	_make_box(Vector3(-0.300, 0.789, 0.375), Vector3(0.007, 0.007, 0.010), Color(0.62, 0.52, 0.08))
	_make_cylinder(Vector3(-0.300, 0.789, 0.225), 0.005, 0.010, Color(0.72, 0.18, 0.12))

	# ── Câbles bureaux ──
	for i in range(3):
		_make_box(Vector3(-0.05 + i*0.04, 0.778, 0.1), Vector3(0.014, 0.007, 0.55), Color(0.08, 0.07, 0.05))

	# ── Objets rebord fenêtre ──
	# Pot de plante séchée
	_make_cylinder(Vector3(-0.40, 0.940, -2.22), 0.038, 0.062, Color(0.35, 0.24, 0.12))
	_make_cylinder(Vector3(-0.40, 0.973, -2.22), 0.027, 0.058, Color(0.20, 0.18, 0.14))
	_make_box(Vector3(-0.40, 1.006, -2.22), Vector3(0.007, 0.060, 0.007), Color(0.18, 0.15, 0.10))
	# Feuille sèche (2 branches)
	_make_box(Vector3(-0.380, 1.032, -2.218), Vector3(0.004, 0.024, 0.004), Color(0.22, 0.18, 0.10))
	_make_box(Vector3(-0.416, 1.028, -2.220), Vector3(0.004, 0.020, 0.004), Color(0.20, 0.17, 0.09))
	# Vieille canette sur rebord
	_make_cylinder(Vector3(0.52, 0.933, -2.20), 0.034, 0.070, Color(0.32, 0.28, 0.22))
	_make_cylinder(Vector3(0.52, 0.972, -2.20), 0.027, 0.009, Color(0.22, 0.20, 0.16))
	_make_cylinder(Vector3(0.52, 0.831, -2.20), 0.022, 0.008, Color(0.22, 0.20, 0.16))
	# Étiquette canette
	_make_box(Vector3(0.555, 0.900, -2.200), Vector3(0.003, 0.042, 0.052), Color(0.45, 0.12, 0.10))

	# ── Interrupteur + prise ──
	_make_box(Vector3(-2.93, 1.22, 1.45), Vector3(0.020, 0.098, 0.068), Color(0.44, 0.40, 0.35))
	_make_box(Vector3(-2.92, 1.22, 1.45), Vector3(0.010, 0.052, 0.028), Color(0.76, 0.72, 0.66))
	# Vis de plaque
	_make_cylinder(Vector3(-2.920, 1.270, 1.450), 0.004, 0.005, Color(0.55, 0.52, 0.48))
	_make_cylinder(Vector3(-2.920, 1.170, 1.450), 0.004, 0.005, Color(0.55, 0.52, 0.48))
	_make_box(Vector3(-2.93, 0.45, 1.82), Vector3(0.018, 0.078, 0.058), Color(0.42, 0.38, 0.33))
	_make_box(Vector3(-2.92, 0.48, 1.80), Vector3(0.008, 0.011, 0.011), Color(0.18, 0.16, 0.14))
	_make_box(Vector3(-2.92, 0.42, 1.80), Vector3(0.008, 0.011, 0.011), Color(0.18, 0.16, 0.14))


# ─── DÉCORATIONS MURALES ──────────────────────────────────────────────────────
func _build_wall_decorations():
	# ── Affiche très délavée + bords déchirés ──
	_make_box(Vector3(2.05, 1.80, -2.44), Vector3(0.78, 1.05, 0.018), Color(0.28, 0.24, 0.18))
	_make_box(Vector3(2.05, 1.80, -2.432), Vector3(0.72, 0.99, 0.009), Color(0.24, 0.20, 0.15))
	_make_box(Vector3(2.05, 2.18, -2.428), Vector3(0.58, 0.055, 0.005), Color(0.36, 0.28, 0.18))
	_make_box(Vector3(1.95, 2.04, -2.428), Vector3(0.42, 0.030, 0.005), Color(0.32, 0.26, 0.16))
	_make_box(Vector3(2.05, 1.90, -2.428), Vector3(0.52, 0.025, 0.005), Color(0.30, 0.24, 0.15))
	# Coins déchirés
	_make_box(Vector3(2.40, 2.26, -2.435), Vector3(0.04, 0.18, 0.007), Color(0.32, 0.27, 0.20))
	_make_box(Vector3(2.42, 2.16, -2.430), Vector3(0.02, 0.08, 0.013), Color(0.40, 0.35, 0.28))
	_make_box(Vector3(1.68, 1.28, -2.434), Vector3(0.05, 0.12, 0.008), Color(0.32, 0.27, 0.20))
	# Trou de punaise (4 coins de l'affiche)
	_make_cylinder(Vector3(2.40, 2.33, -2.432), 0.005, 0.006, Color(0.30, 0.25, 0.18))
	_make_cylinder(Vector3(1.68, 2.33, -2.432), 0.005, 0.006, Color(0.30, 0.25, 0.18))

	# ── Étagère murale gauche ──
	_make_box(Vector3(-2.55, 1.88, -1.0), Vector3(0.75, 0.036, 0.20), COL_WOOD_MED)
	# Lèvre avant de l'étagère
	_make_box(Vector3(-2.55, 1.868, -0.905), Vector3(0.75, 0.014, 0.020), Color(0.32, 0.22, 0.12))
	# Supports
	_make_box(Vector3(-2.20, 1.68, -1.0), Vector3(0.022, 0.40, 0.022), COL_METAL_DARK)
	_make_box(Vector3(-2.90, 1.68, -1.0), Vector3(0.022, 0.40, 0.022), COL_METAL_DARK)
	# Vis de fixation
	_make_cylinder(Vector3(-2.20, 1.88, -0.915), 0.006, 0.008, COL_METAL_DARK)
	_make_cylinder(Vector3(-2.90, 1.88, -0.915), 0.006, 0.008, COL_METAL_DARK)
	# Livres sur l'étagère — avec dos colorés et titres simulés
	var bc := [Color(0.45, 0.09, 0.07), Color(0.07, 0.20, 0.38), Color(0.28, 0.26, 0.09), Color(0.20, 0.38, 0.20)]
	for i in range(4):
		var bw := 0.058 + (i % 2) * 0.018
		var bh := 0.14 + (i % 3) * 0.038
		var bpos := Vector3(-2.80 + i * 0.148, 1.90 + bh*0.5, -1.0)
		_make_box(bpos, Vector3(bw, bh, 0.17), bc[i])
		# Tranche (pages) — couleur crème
		_make_box(bpos + Vector3(0, 0, 0.086), Vector3(bw - 0.008, bh + 0.004, 0.005), Color(0.85, 0.81, 0.73))
		# Titre simulé (trait sur la couverture)
		_make_box(bpos + Vector3(0, bh * 0.1, -0.001), Vector3(bw * 0.7, 0.006, 0.003),
				  Color(bc[i].r * 1.5, bc[i].g * 1.5, bc[i].b * 1.5).clamp())
	# Petit objet coincé entre livres
	_make_cylinder(Vector3(-2.54, 1.900, -1.0), 0.018, 0.095, Color(0.25, 0.22, 0.18))

	# ── Tour PC ──
	_make_box(Vector3(-0.90, 0.40, -0.26), Vector3(0.19, 0.74, 0.40), Color(0.20, 0.18, 0.16))
	# Face avant de la tour (panel avec détails)
	_make_box(Vector3(-0.81, 0.40, -0.062), Vector3(0.012, 0.72, 0.39), Color(0.18, 0.17, 0.15))
	for i in range(6):
		_make_box(Vector3(-0.81, 0.55 + i*0.055, -0.062), Vector3(0.016, 0.020, 0.22), Color(0.10, 0.09, 0.07))
	# LED verte power
	_make_box(Vector3(-0.81, 0.39, -0.062), Vector3(0.016, 0.007, 0.007), Color(0.0, 0.85, 0.18), true)
	# Bouton power
	_make_cylinder(Vector3(-0.812, 0.44, -0.062), 0.014, 0.010, Color(0.22, 0.20, 0.18))
	# Drive baie
	_make_box(Vector3(-0.81, 0.42, -0.062), Vector3(0.013, 0.016, 0.35), Color(0.16, 0.14, 0.12))
	# Vis de panneau (4 coins)
	_make_cylinder(Vector3(-0.810, 0.76, -0.250), 0.005, 0.006, Color(0.20, 0.19, 0.17))
	_make_cylinder(Vector3(-0.810, 0.76,  0.130), 0.005, 0.006, Color(0.20, 0.19, 0.17))
	_make_cylinder(Vector3(-0.810, 0.04, -0.250), 0.005, 0.006, Color(0.20, 0.19, 0.17))
	_make_cylinder(Vector3(-0.810, 0.04,  0.130), 0.005, 0.006, Color(0.20, 0.19, 0.17))
	_make_box(Vector3(-0.82, 0.2, 0.1), Vector3(0.011, 0.38, 0.011), Color(0.07, 0.06, 0.05))

	# ── Câbles sol ──
	for i in range(3):
		_make_box(Vector3(-0.15 + i*0.06, 0.004, 0.5), Vector3(0.012, 0.007, 1.6), Color(0.07, 0.06, 0.05))

	# ── Radiateur ──
	_make_box(Vector3(-2.80, 0.28, 0.62), Vector3(0.20, 0.40, 0.72), COL_METAL_RUST)
	# Ailettes du radiateur (avec ombres)
	for i in range(6):
		var fz := 0.30 + i * 0.10
		_make_box(Vector3(-2.70, 0.28, fz), Vector3(0.014, 0.36, 0.042), COL_METAL_DARK)
		# Espace inter-ailette (légèrement plus sombre)
		if i < 5:
			_make_box(Vector3(-2.700, 0.28, fz + 0.065), Vector3(0.012, 0.33, 0.006), Color(0.11, 0.09, 0.07))
	# Robinets de radiateur
	_make_cylinder(Vector3(-2.70, 0.52, 0.28), 0.020, 0.058, COL_METAL_RUST)
	_make_cylinder(Vector3(-2.70, 0.52, 0.96), 0.020, 0.058, COL_METAL_RUST)
	# Tuyau de raccordement
	_make_box(Vector3(-2.84, 0.08, 0.62), Vector3(0.042, 0.12, 0.042), COL_METAL_RUST)
	_make_box(Vector3(-2.90, 0.02, 0.62), Vector3(0.12, 0.028, 0.038), COL_METAL_DARK)

	# ── Placard mur droit ──
	_make_box(Vector3(2.62, 1.4, -1.5), Vector3(0.65, 2.8, 1.05), Color(0.26, 0.20, 0.14))
	# Portes de placard (avec ligne de séparation centrale)
	_make_box(Vector3(2.62, 1.4, -1.76), Vector3(0.62, 2.72, 0.020), Color(0.30, 0.24, 0.18))
	_make_box(Vector3(2.62, 1.4, -1.24), Vector3(0.62, 2.72, 0.020), Color(0.30, 0.24, 0.18))
	# Joint central entre portes
	_make_box(Vector3(2.62, 1.4, -1.50), Vector3(0.63, 2.74, 0.007), Color(0.12, 0.10, 0.07))
	# Moulure décorative sur les portes
	_make_box(Vector3(2.62, 1.4, -1.732), Vector3(0.58, 2.40, 0.006), Color(0.28, 0.22, 0.16))
	_make_box(Vector3(2.62, 1.4, -1.268), Vector3(0.58, 2.40, 0.006), Color(0.28, 0.22, 0.16))
	# Poignées
	_make_cylinder(Vector3(2.62, 1.42, -1.63), 0.011, 0.080, COL_METAL_RUST)
	_make_cylinder(Vector3(2.62, 1.42, -1.37), 0.011, 0.080, COL_METAL_RUST)
	# Goupille de charnière (haut + bas)
	_make_cylinder(Vector3(2.962, 2.75, -1.76), 0.008, 0.030, COL_METAL_DARK)
	_make_cylinder(Vector3(2.962, 0.05, -1.76), 0.008, 0.030, COL_METAL_DARK)
	_make_cylinder(Vector3(2.962, 2.75, -1.24), 0.008, 0.030, COL_METAL_DARK)
	_make_cylinder(Vector3(2.962, 0.05, -1.24), 0.008, 0.030, COL_METAL_DARK)

	# ── Note post-it (légèrement incliné) ──
	var postit := _make_box_rot(
		Vector3(-0.2, 1.62, -2.438),
		Vector3(0.18, 0.18, 0.010),
		Color(0.78, 0.70, 0.28),
		Vector3(0, 3.5, 0)
	)
	_make_box(Vector3(-0.2, 1.67, -2.434), Vector3(0.12, 0.008, 0.003), Color(0.20, 0.16, 0.10))
	_make_box(Vector3(-0.2, 1.64, -2.434), Vector3(0.10, 0.007, 0.003), Color(0.20, 0.16, 0.10))
	_make_box(Vector3(-0.2, 1.61, -2.434), Vector3(0.08, 0.007, 0.003), Color(0.20, 0.16, 0.10))
	_make_box(Vector3(-0.2, 1.58, -2.434), Vector3(0.11, 0.007, 0.003), Color(0.20, 0.16, 0.10))

	# ── Câble ampoule plafond ──
	_make_box(Vector3(0.5, 2.92, -0.5), Vector3(0.006, 0.16, 0.006), Color(0.07, 0.06, 0.05))
	_make_cylinder(Vector3(0.5, 2.80, -0.5), 0.024, 0.038, COL_METAL_DARK)
	_make_cylinder(Vector3(0.5, 2.77, -0.5), 0.035, 0.055, Color(0.85, 0.80, 0.65), true)
	# Globe de l'ampoule
	_make_cylinder(Vector3(0.5, 2.745, -0.5), 0.030, 0.042, Color(0.80, 0.78, 0.72))

	# ── Petit cadre photo sur le mur gauche ──
	_make_box(Vector3(-2.94, 2.0, 0.80), Vector3(0.015, 0.22, 0.18), Color(0.20, 0.15, 0.10))
	_make_box(Vector3(-2.932, 2.0, 0.80), Vector3(0.009, 0.19, 0.15), Color(0.10, 0.09, 0.08))
	# Photo (vieille, désaturée)
	_make_box(Vector3(-2.930, 2.0, 0.80), Vector3(0.008, 0.17, 0.13), Color(0.45, 0.42, 0.38))


# ─── MIROIR ──────────────────────────────────────────────────────────────────
func _build_mirror():
	# Cadre miroir — 4 pièces distinctes (haut / bas / gauche / droite)
	var frame_col := Color(0.22, 0.16, 0.10)
	var frame_inner := Color(0.28, 0.20, 0.13)
	# Côtés
	_make_box(Vector3(2.935, 2.15, 0.600), Vector3(0.040, 0.065, 0.68), frame_col)  # haut
	_make_box(Vector3(2.935, 1.25, 0.600), Vector3(0.040, 0.065, 0.68), frame_col)  # bas
	_make_box(Vector3(2.935, 1.70, 0.273), Vector3(0.040, 0.90, 0.060), frame_col)  # gauche
	_make_box(Vector3(2.935, 1.70, 0.927), Vector3(0.040, 0.90, 0.060), frame_col)  # droite
	# Listel intérieur
	_make_box(Vector3(2.930, 1.70, 0.600), Vector3(0.030, 0.84, 0.60), frame_inner)

	# Surface réfléchissante (SSR)
	var mirror_mat := StandardMaterial3D.new()
	mirror_mat.metallic       = 1.0
	mirror_mat.roughness      = 0.02
	mirror_mat.albedo_color   = Color(0.85, 0.85, 0.85)
	mirror_mat.clearcoat      = 1.0
	mirror_mat.clearcoat_roughness = 0.01
	var mir := MeshInstance3D.new()
	var mm  := BoxMesh.new()
	mm.size = Vector3(0.015, 0.82, 0.54)
	mir.mesh = mm
	mir.position = Vector3(2.924, 1.70, 0.600)
	mir.material_override = mirror_mat
	add_child(mir)

	# Tache / condensation bas du miroir
	var fog_mat := StandardMaterial3D.new()
	fog_mat.albedo_color = Color(0.50, 0.48, 0.44, 0.45)
	fog_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fog_mat.roughness    = 0.5
	var fog_mi   := MeshInstance3D.new()
	var fog_mesh := BoxMesh.new()
	fog_mesh.size = Vector3(0.016, 0.18, 0.52)
	fog_mi.mesh  = fog_mesh
	fog_mi.position = Vector3(2.923, 1.30, 0.600)
	fog_mi.material_override = fog_mat
	add_child(fog_mi)


# ─── BAZAR AU SOL ─────────────────────────────────────────────────────────────
func _build_mess():
	# Vêtements froissés (pile) — avec rotation sur certains
	_make_box(Vector3(-1.3, 0.065, 0.8), Vector3(0.45, 0.055, 0.38), Color(0.28, 0.24, 0.38))
	_make_box(Vector3(-1.2, 0.100, 0.85), Vector3(0.30, 0.040, 0.25), Color(0.22, 0.22, 0.25))
	_make_box(Vector3(-1.35, 0.085, 0.7), Vector3(0.20, 0.032, 0.18), Color(0.32, 0.24, 0.18))
	# T-shirt légèrement de travers
	_make_box_rot(Vector3(-1.28, 0.090, 0.72), Vector3(0.38, 0.022, 0.28), Color(0.24, 0.20, 0.28), Vector3(0, 8.0, 0))

	# Canettes vides — une debout, une couchée, une en équilibre
	_make_cylinder(Vector3(0.40, 0.058, 1.1), 0.033, 0.092, Color(0.30, 0.26, 0.20))
	_make_cylinder(Vector3(0.40, 0.034, 1.1), 0.022, 0.008, Color(0.22, 0.20, 0.16))  # base canette
	# Canette couchée (rotation 90° simulée par box)
	_make_box_rot(Vector3(0.52, 0.034, 1.1), Vector3(0.066, 0.064, 0.064), Color(0.28, 0.24, 0.18), Vector3(0, 0, 90))
	_make_cylinder(Vector3(-0.2, 0.058, 1.4), 0.031, 0.090, Color(0.25, 0.22, 0.16))

	# Sac plastique froissé (transparent)
	var bag_mat := StandardMaterial3D.new()
	bag_mat.albedo_color = Color(0.65, 0.62, 0.55, 0.45)
	bag_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bag_mat.roughness    = 0.4
	var bag_mi := MeshInstance3D.new()
	var bag_mesh := BoxMesh.new()
	bag_mesh.size = Vector3(0.24, 0.025, 0.20)
	bag_mi.mesh = bag_mesh
	bag_mi.position = Vector3(0.8, 0.030, 1.3)
	bag_mi.rotation_degrees = Vector3(0, 15, 0)
	bag_mi.material_override = bag_mat
	add_child(bag_mi)
	# Plis du sac
	_make_box_rot(Vector3(0.78, 0.038, 1.28), Vector3(0.10, 0.012, 0.08), Color(0.60, 0.58, 0.52, 0.3), Vector3(0, 15, 0))

	# Livre tombé au sol (légèrement de travers)
	_make_box_rot(Vector3(0.15, 0.012, 1.6), Vector3(0.19, 0.024, 0.13), Color(0.38, 0.15, 0.10), Vector3(0, 23, 0))
	# Couverture légèrement ouverte
	_make_box_rot(Vector3(0.16, 0.025, 1.62), Vector3(0.06, 0.004, 0.12), Color(0.82, 0.78, 0.70), Vector3(0, 20, -4))

	# Poussière / peluches dans les coins
	_make_box(Vector3(-2.85, 0.002, 2.2), Vector3(0.25, 0.004, 0.12), Color(0.25, 0.22, 0.17))
	_make_box(Vector3(2.82,  0.002, 2.1), Vector3(0.20, 0.004, 0.10), Color(0.24, 0.21, 0.16))
	_make_box(Vector3(-2.82, 0.002, -2.2), Vector3(0.18, 0.004, 0.10), Color(0.24, 0.21, 0.16))
	_make_box(Vector3(2.80,  0.002, -2.3), Vector3(0.15, 0.004, 0.08), Color(0.23, 0.20, 0.16))

	# Câbles traînants (courbe simulée par 2 segments)
	_make_box(Vector3(-0.5, 0.004, 1.2),  Vector3(0.012, 0.008, 0.65), Color(0.08, 0.07, 0.05))
	_make_box(Vector3(-0.30, 0.004, 1.52), Vector3(0.38, 0.008, 0.012), Color(0.08, 0.07, 0.05))
	_make_box_rot(Vector3(-0.16, 0.004, 1.44), Vector3(0.20, 0.007, 0.012), Color(0.08, 0.07, 0.05), Vector3(0, -30, 0))

	# Papiers froissés
	_make_box_rot(Vector3(0.9, 0.018, 0.9), Vector3(0.12, 0.022, 0.10), Color(0.78, 0.74, 0.66), Vector3(0, 12, 0))
	_make_box_rot(Vector3(-0.8, 0.018, 1.2), Vector3(0.10, 0.020, 0.09), Color(0.80, 0.76, 0.68), Vector3(0, -8, 0))
	_make_box_rot(Vector3(1.2, 0.015, 1.5), Vector3(0.08, 0.016, 0.07), Color(0.76, 0.72, 0.64), Vector3(0, 35, 0))

	# Chaussure isolée
	_make_box(Vector3(1.5, 0.040, 0.8), Vector3(0.12, 0.060, 0.28), Color(0.18, 0.14, 0.10))
	_make_box(Vector3(1.5, 0.080, 0.9), Vector3(0.10, 0.080, 0.12), Color(0.14, 0.11, 0.08))
	# Semelle
	_make_box(Vector3(1.5, 0.008, 0.8), Vector3(0.125, 0.010, 0.285), Color(0.10, 0.08, 0.06))
	# Lacet pendant
	_make_box_rot(Vector3(1.46, 0.10, 0.85), Vector3(0.005, 0.006, 0.09), Color(0.72, 0.68, 0.62), Vector3(0, 20, 30))


# ─── LUMIÈRES ────────────────────────────────────────────────────────────────
func _setup_lights():
	street_lamp_light = _add_omni_light(
		Vector3(WIN_X + 0.3, WIN_Y - WIN_H * 0.5 - 0.3, WIN_Z - 0.6),
		COL_STREET_LAMP, 3.8, 6.5
	)
	window_cold_light = _add_omni_light(
		Vector3(WIN_X, WIN_Y + 0.3, WIN_Z + 0.2),
		COL_NIGHT_COLD, 0.9, 5.0
	)
	desk_lamp_light = _add_omni_light(
		Vector3(0.88, 0.95, -0.24), COL_BULB, 1.6, 1.8
	)
	_add_omni_light(Vector3(0.5, 2.73, -0.5), COL_BULB, 0.06, 2.0)
	screen_glow_light = _add_omni_light(Vector3(0, 1.35, 0.18), Color(0.20, 0.85, 0.40), 0.15, 0.85)
	_add_omni_light(Vector3(0.60, 0.826, -0.30), Color(0.8, 0.05, 0.02), 0.04, 0.25)
	_add_omni_light(Vector3(0.0, 0.02, -1.5), COL_STREET_LAMP, 0.18, 2.2)

	sun_light = DirectionalLight3D.new()
	sun_light.light_color  = Color(1.0, 0.96, 0.85)
	sun_light.light_energy = 0.0
	sun_light.rotation_degrees = Vector3(-42, 25, 0)
	sun_light.shadow_enabled = true
	sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun_light.shadow_blur = 2.0
	add_child(sun_light)


func _add_omni_light(pos: Vector3, color: Color, energy: float, radius: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position     = pos
	light.light_color  = color
	light.light_energy = energy
	light.omni_range   = radius
	light.shadow_enabled = false
	add_child(light)
	return light


# ─── SCINTILLEMENT LAMPE ─────────────────────────────────────────────────────
func _start_flicker() -> void:
	await get_tree().create_timer(1.5).timeout
	while is_inside_tree():
		await get_tree().create_timer(randf_range(6.0, 22.0)).timeout
		if not lamp_enabled: continue
		var flicker_n := randi_range(2, 8)
		for _i in range(flicker_n):
			if desk_lamp_light and lamp_enabled:
				desk_lamp_light.light_energy = randf_range(0.05, 0.50)
			await get_tree().create_timer(randf_range(0.03, 0.12)).timeout
			if desk_lamp_light and lamp_enabled:
				desk_lamp_light.light_energy = randf_range(1.0, 1.8)
			await get_tree().create_timer(randf_range(0.04, 0.14)).timeout
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


# ─── VIGNETTE (shader radial doux) ───────────────────────────────────────────
func _build_vignette() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 10
	add_child(cl)

	var ctrl := Control.new()
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(ctrl)

	# Shader de vignette radiale progressive
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float strength : hint_range(0.0, 2.0) = 0.88;
uniform float inner_radius : hint_range(0.0, 1.0) = 0.28;
uniform float smoothness : hint_range(0.0, 1.0) = 0.72;
uniform float aspect : hint_range(0.5, 2.5) = 1.778;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	uv.x *= aspect;
	float dist = length(uv) * 2.0;
	float vignette = smoothstep(inner_radius, inner_radius + smoothness, dist) * strength;
	vignette = clamp(vignette, 0.0, 1.0);
	COLOR = vec4(0.0, 0.0, 0.0, vignette);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader

	var cr := ColorRect.new()
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cr.set_anchors_preset(Control.PRESET_FULL_RECT)
	cr.material = mat
	ctrl.add_child(cr)
	vignette_cr = cr


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

	if event is InputEventKey and event.pressed and event.keycode == KEY_K and event.ctrl_pressed:
		if not is_at_terminal:
			_toggle_day_night()
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


func _toggle_day_night() -> void:
	is_day_mode = !is_day_mode
	if day_tween: day_tween.kill()
	day_tween = create_tween()
	day_tween.set_ease(Tween.EASE_IN_OUT)
	day_tween.set_trans(Tween.TRANS_CUBIC)
	day_tween.set_parallel(true)
	var dur := 1.4

	if is_day_mode:
		day_tween.tween_property(sun_light,         "light_energy", 4.0,  dur)
		day_tween.tween_property(street_lamp_light, "light_energy", 0.0,  dur * 0.4)
		day_tween.tween_property(window_cold_light, "light_energy", 3.5,  dur)
		day_tween.tween_property(desk_lamp_light,   "light_energy", 0.0,  dur * 0.4)
		day_tween.tween_property(screen_glow_light, "light_energy", 0.0,  dur * 0.4)
		day_tween.tween_method(_set_env_ambient_energy, env_ref.ambient_light_energy, 8.0,  dur)
		day_tween.tween_method(_set_env_brightness,    env_ref.adjustment_brightness, 1.4,  dur)
		day_tween.tween_method(_set_env_contrast,      env_ref.adjustment_contrast,   1.0,  dur)
		day_tween.tween_method(_set_env_saturation,    env_ref.adjustment_saturation, 1.1,  dur)
		day_tween.tween_method(_set_env_fog_density,   env_ref.fog_density,            0.0,  dur)
		day_tween.tween_method(_set_env_vfog_density,  env_ref.volumetric_fog_density, 0.0,  dur)
	else:
		day_tween.tween_property(sun_light,          "light_energy", 0.0,  dur)
		day_tween.tween_property(street_lamp_light,  "light_energy", 3.8,  dur)
		day_tween.tween_property(window_cold_light,  "light_energy", 0.9,  dur)
		day_tween.tween_property(desk_lamp_light,    "light_energy", 1.6 if lamp_enabled else 0.0, dur)
		day_tween.tween_property(screen_glow_light,  "light_energy", 0.15, dur)
		day_tween.tween_method(_set_env_ambient_energy, env_ref.ambient_light_energy, 1.2,   dur)
		day_tween.tween_method(_set_env_brightness,    env_ref.adjustment_brightness, 0.95,  dur)
		day_tween.tween_method(_set_env_contrast,      env_ref.adjustment_contrast,   1.20,  dur)
		day_tween.tween_method(_set_env_saturation,    env_ref.adjustment_saturation, 0.72,  dur)
		day_tween.tween_method(_set_env_fog_density,   env_ref.fog_density,            0.015, dur)
		day_tween.tween_method(_set_env_vfog_density,  env_ref.volumetric_fog_density, 0.018, dur)


func _set_env_ambient_energy(v: float) -> void:
	if env_ref: env_ref.ambient_light_energy = v
func _set_env_brightness(v: float)     -> void:
	if env_ref: env_ref.adjustment_brightness = v
func _set_env_contrast(v: float)       -> void:
	if env_ref: env_ref.adjustment_contrast = v
func _set_env_saturation(v: float)     -> void:
	if env_ref: env_ref.adjustment_saturation = v
func _set_env_fog_density(v: float)    -> void:
	if env_ref: env_ref.fog_density = v
func _set_env_vfog_density(v: float)   -> void:
	if env_ref: env_ref.volumetric_fog_density = v


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
		if vignette_cr:
			tween.tween_property(vignette_cr, "modulate:a", 0.0, 0.4)
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
		if vignette_cr:
			tween.tween_property(vignette_cr, "modulate:a", 1.0, 0.5)


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


func _make_box_rot(pos: Vector3, size: Vector3, color: Color, rot_deg: Vector3, emissive: bool = false) -> MeshInstance3D:
	var mi   := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh   = mesh
	mi.position = pos
	mi.rotation_degrees = rot_deg
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
