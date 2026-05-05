# room_scene.gd
# Chambre réaliste, vétuste et sombre — avec fenêtre à grille et rayons de lumière
extends Node3D

# ─── Palette couleurs réalistes / vétustes ───────────────────────────────────
const COL_WALL         := Color(0.52, 0.47, 0.40)   # peinture vieillie
const COL_WALL_DARK    := Color(0.35, 0.30, 0.24)   # zones sombres / taches
const COL_WALL_STAIN   := Color(0.28, 0.24, 0.18)   # humidité / moisissures
const COL_FLOOR        := Color(0.26, 0.18, 0.10)   # parquet sombre usé
const COL_FLOOR_DARK   := Color(0.18, 0.12, 0.07)   # joints / bords parquet
const COL_CEILING      := Color(0.44, 0.40, 0.35)   # plafond jauni
const COL_CEILING_STAIN:= Color(0.32, 0.28, 0.22)   # auréoles plafond
const COL_WOOD_DARK    := Color(0.20, 0.13, 0.07)   # bois foncé (bureau, lit)
const COL_WOOD_MED     := Color(0.32, 0.22, 0.12)   # bois moyen
const COL_WOOD_LIGHT   := Color(0.48, 0.34, 0.20)   # bois plus clair (cadre fenêtre)
const COL_METAL_RUST   := Color(0.30, 0.22, 0.15)   # métal rouillé
const COL_METAL_DARK   := Color(0.18, 0.16, 0.14)   # métal foncé
const COL_SCREEN       := Color(0.0, 0.05, 0.0)
const COL_SUNLIGHT     := Color(1.0, 0.90, 0.68)    # lumière extérieure chaude
const COL_BULB         := Color(1.0, 0.80, 0.45)    # ampoule incandescente
const COL_DESK_SCREEN  := Color(0.15, 0.15, 0.18)   # cadre moniteur gris foncé

# ─── Paramètres fenêtre (centraux pour mur arrière) ──────────────────────────
const WIN_X    := 0.0
const WIN_Y    := 1.72
const WIN_Z    := -2.46
const WIN_W    := 2.8     # largeur totale de la fenêtre
const WIN_H    := 1.75    # hauteur
const WIN_COLS := 4       # divisions verticales (barreaux)
const WIN_ROWS := 3       # divisions horizontales

# ─── Caméra ──────────────────────────────────────────────────────────────────
const CAM_FREE_POS      := Vector3(0.0, 1.5, 1.8)
const CAM_FREE_ROT      := Vector3(-8, 0, 0)
const CAM_TERMINAL_POS  := Vector3(0.0, 1.35, 0.6)
const CAM_TERMINAL_ROT  := Vector3(0, 0, 0)
const SCREEN_WORLD_SIZE := Vector2(1.18, 0.70)
const VP_SIZE           := Vector2(1152, 648)
const MOUSE_SENSITIVITY := 0.15
const PITCH_MIN := -30.0
const PITCH_MAX := 20.0
const YAW_MIN   := -35.0
const YAW_MAX   := 35.0

# ─── Variables ───────────────────────────────────────────────────────────────
@onready var sub_viewport: SubViewport = $SubViewport
@onready var screen_mesh: MeshInstance3D = $ScreenMesh

var camera: Camera3D
var is_at_terminal := false
var os_cursor = null
var os_main = null
var vp_cursor_pos := Vector2(576, 324)
var tween: Tween
var mouse_look := false
var cam_rotation := Vector2(-8, 0)
var desk_lamp_light: OmniLight3D
var lamp_enabled := true


func _ready():
	_setup_environment()
	_build_room()
	_build_window()
	_build_god_rays()
	_build_desk()
	_build_monitor()
	_build_keyboard()
	_build_bed()
	_build_decorations()
	_build_wall_decorations()
	_setup_lights()
	_setup_camera()
	_build_crt_overlay()
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED


func _notification(what: int):
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if is_at_terminal:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# ─── ENVIRONNEMENT ────────────────────────────────────────────────────────────
func _setup_environment():
	var env := Environment.new()

	# Fond très sombre
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.04, 0.05)

	# Lumière ambiante minimale (on veut du NOIR)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color  = Color(0.06, 0.05, 0.04)
	env.ambient_light_energy = 0.6

	# ── Brouillard volumétrique → rayons de lumière ──
	env.volumetric_fog_enabled   = true
	env.volumetric_fog_density   = 0.025         # densité modérée
	env.volumetric_fog_albedo    = Color(0.88, 0.82, 0.72)
	env.volumetric_fog_emission  = Color(0, 0, 0)
	env.volumetric_fog_emission_energy = 0.0
	env.volumetric_fog_anisotropy = 0.6          # forward scattering → rayons visibles
	env.volumetric_fog_length    = 32.0
	env.volumetric_fog_detail_spread = 2.0
	env.volumetric_fog_gi_inject = 1.0

	# ── Brouillard de distance (légère profondeur) ──
	env.fog_enabled     = true
	env.fog_light_color = Color(0.10, 0.09, 0.07)
	env.fog_density     = 0.02
	env.fog_aerial_perspective = 0.1

	# ── Glow réaliste (bloom doux, pas cyberpunk) ──
	env.glow_enabled          = true
	env.glow_intensity        = 0.5
	env.glow_bloom            = 0.15
	env.glow_hdr_threshold    = 0.8
	env.glow_normalized       = false

	# ── Correction colorimétrique ──
	env.adjustment_enabled     = true
	env.adjustment_brightness  = 0.85
	env.adjustment_contrast    = 1.15
	env.adjustment_saturation  = 0.80   # légèrement désaturé → look anxiogène

	# ── SSAO ──
	env.ssao_enabled = true
	env.ssao_radius  = 1.2
	env.ssao_intensity = 2.0

	# ── SSIL (éclairage indirect par surface) ──
	env.ssil_enabled = true
	env.ssil_radius  = 3.0
	env.ssil_intensity = 0.8

	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


# ─── PIÈCE ────────────────────────────────────────────────────────────────────
func _build_room():
	# Sol — parquet sombre, planches
	_make_box(Vector3(0, -0.05, 0), Vector3(6.0, 0.1, 5.0), COL_FLOOR)
	# Joints de parquet
	for i in range(7):
		_make_box(
			Vector3(-3.0 + i * 1.0, 0.001, 0),
			Vector3(0.018, 0.001, 5.0),
			COL_FLOOR_DARK
		)
	# Rayures d'usure longitudinales
	for i in range(4):
		_make_box(
			Vector3(-1.5 + i * 1.0, 0.001, 0),
			Vector3(0.006, 0.001, 4.0),
			Color(0.15, 0.10, 0.06)
		)

	# Plafond
	_make_box(Vector3(0, 3.05, 0), Vector3(6.0, 0.1, 5.0), COL_CEILING)
	# Auréole humidité plafond
	_make_box(Vector3(-1.0, 3.04, -0.5), Vector3(0.9, 0.01, 0.7), COL_CEILING_STAIN)
	_make_box(Vector3(1.2, 3.04, 0.3), Vector3(0.5, 0.01, 0.4), COL_CEILING_STAIN)

	# ── Mur ARRIÈRE — avec trou de fenêtre ──
	# Fenêtre : WIN_X ± WIN_W/2, WIN_Y ± WIN_H/2  → x ∈ [-1.4, 1.4], y ∈ [0.845, 2.595]
	var fw2 := WIN_W * 0.5
	var fh2 := WIN_H * 0.5
	var w_xmin := WIN_X - fw2
	var w_xmax := WIN_X + fw2
	var w_ymin := WIN_Y - fh2
	var w_ymax := WIN_Y + fh2

	# Bande basse (pleine largeur)
	_make_box(Vector3(0, w_ymin * 0.5, -2.5), Vector3(6.0, w_ymin, 0.12), COL_WALL)
	# Bande haute
	var top_y  := (w_ymax + 3.0) * 0.5
	var top_h  := 3.0 - w_ymax
	_make_box(Vector3(0, top_y, -2.5), Vector3(6.0, top_h, 0.12), COL_WALL)
	# Partie gauche (côté fenêtre)
	var left_w := 3.0 + w_xmin   # = 3 - WIN_W/2
	_make_box(Vector3(-3.0 + left_w * 0.5, WIN_Y, -2.5), Vector3(left_w, WIN_H, 0.12), COL_WALL)
	# Partie droite
	var right_w := 3.0 - w_xmax
	_make_box(Vector3(3.0 - right_w * 0.5, WIN_Y, -2.5), Vector3(right_w, WIN_H, 0.12), COL_WALL)

	# Taches / usure mur arrière
	_make_box(Vector3(-2.0, 0.5, -2.44), Vector3(0.8, 0.6, 0.01), COL_WALL_STAIN)
	_make_box(Vector3(2.2, 1.0, -2.44), Vector3(0.5, 0.4, 0.01), COL_WALL_STAIN)

	# ── Mur GAUCHE ──
	_make_box(Vector3(-3.0, 1.5, 0), Vector3(0.12, 3.0, 5.0), COL_WALL)
	# Taches humidité
	_make_box(Vector3(-2.95, 0.45, -1.5), Vector3(0.02, 1.0, 0.8), COL_WALL_STAIN)
	_make_box(Vector3(-2.95, 0.25, 0.8), Vector3(0.02, 0.5, 0.5), COL_WALL_STAIN)
	# Papier peint qui se décolle (coin bas)
	_make_box(Vector3(-2.97, 0.35, 1.8), Vector3(0.01, 0.55, 0.45), Color(0.55, 0.50, 0.40))

	# ── Mur DROIT ──
	_make_box(Vector3(3.0, 1.5, 0), Vector3(0.12, 3.0, 5.0), COL_WALL)
	_make_box(Vector3(2.95, 0.6, 1.0), Vector3(0.02, 0.7, 0.5), COL_WALL_DARK)

	# ── Mur AVANT (derrière joueur) ──
	_make_box(Vector3(0, 1.5, 2.5), Vector3(6.0, 3.0, 0.12), COL_WALL)

	# ── Plinthes ──
	var plinth_h   := 0.14
	var plinth_col := COL_WOOD_DARK
	_make_box(Vector3(0, plinth_h * 0.5, -2.44),  Vector3(6.0, plinth_h, 0.04), plinth_col)
	_make_box(Vector3(-2.94, plinth_h * 0.5, 0),  Vector3(0.04, plinth_h, 5.0), plinth_col)
	_make_box(Vector3(2.94, plinth_h * 0.5, 0),   Vector3(0.04, plinth_h, 5.0), plinth_col)
	_make_box(Vector3(0, plinth_h * 0.5, 2.44),   Vector3(6.0, plinth_h, 0.04), plinth_col)


# ─── FENÊTRE ──────────────────────────────────────────────────────────────────
func _build_window():
	var fw2  := WIN_W * 0.5
	var fh2  := WIN_H * 0.5
	var ft   := 0.065   # épaisseur cadre
	var bt   := 0.028   # épaisseur barreau

	# ── Cadre extérieur ──
	var fc := COL_WOOD_LIGHT
	_make_box(Vector3(WIN_X, WIN_Y + fh2 + ft * 0.5, WIN_Z),    Vector3(WIN_W + ft * 2, ft, 0.1), fc)
	_make_box(Vector3(WIN_X, WIN_Y - fh2 - ft * 0.5, WIN_Z),    Vector3(WIN_W + ft * 2, ft, 0.1), fc)
	_make_box(Vector3(WIN_X - fw2 - ft * 0.5, WIN_Y, WIN_Z),    Vector3(ft, WIN_H, 0.1), fc)
	_make_box(Vector3(WIN_X + fw2 + ft * 0.5, WIN_Y, WIN_Z),    Vector3(ft, WIN_H, 0.1), fc)

	# ── Barreaux verticaux ──
	for i in range(1, WIN_COLS):
		var bx := WIN_X - fw2 + (WIN_W / WIN_COLS) * i
		_make_box(Vector3(bx, WIN_Y, WIN_Z), Vector3(bt, WIN_H, 0.08), fc)

	# ── Barreaux horizontaux ──
	for i in range(1, WIN_ROWS):
		var by := WIN_Y - fh2 + (WIN_H / WIN_ROWS) * i
		_make_box(Vector3(WIN_X, by, WIN_Z), Vector3(WIN_W, bt, 0.08), fc)

	# ── Vitres (semi-transparentes, une par carreau) ──
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color    = Color(0.80, 0.88, 1.0, 0.12)
	glass_mat.transparency    = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness       = 0.0
	glass_mat.metallic        = 0.05
	glass_mat.emission_enabled = true
	glass_mat.emission        = Color(0.9, 0.82, 0.60)
	glass_mat.emission_energy_multiplier = 0.6   # lueur chaude depuis l'extérieur

	var cell_w := WIN_W / WIN_COLS
	var cell_h := WIN_H / WIN_ROWS
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

	# ── Rebord de fenêtre (tablette) ──
	_make_box(
		Vector3(WIN_X, WIN_Y - fh2 - ft - 0.025, WIN_Z + 0.12),
		Vector3(WIN_W + ft * 2 + 0.1, 0.05, 0.28),
		COL_WOOD_LIGHT
	)


# ─── RAYONS DE LUMIÈRE (faux volumétriques visuels) ──────────────────────────
func _build_god_rays():
	# En complément du fog volumétrique, des plans semi-transparents angled
	# donnent un aspect dramatique garanti même sans Forward+ parfait
	var ray_mat := StandardMaterial3D.new()
	ray_mat.albedo_color        = Color(1.0, 0.92, 0.68, 0.045)
	ray_mat.transparency        = BaseMaterial3D.TRANSPARENCY_ALPHA
	ray_mat.emission_enabled    = true
	ray_mat.emission            = Color(1.0, 0.88, 0.60)
	ray_mat.emission_energy_multiplier = 0.08
	ray_mat.shading_mode        = BaseMaterial3D.SHADING_MODE_UNSHADED
	ray_mat.cull_mode           = BaseMaterial3D.CULL_DISABLED
	ray_mat.no_depth_test       = false

	# Disposition des barreaux → 4 colonnes = 4 faisceaux principaux
	var col_w := WIN_W / WIN_COLS
	for i in range(WIN_COLS):
		var cx := WIN_X - WIN_W * 0.5 + col_w * (i + 0.5)
		# Chaque rayon part du centre de chaque carreau et descend en biais
		_add_god_ray(ray_mat, cx, i)

	# Quelques rayons secondaires entre les barreaux
	for i in range(WIN_COLS - 1):
		var cx := WIN_X - WIN_W * 0.5 + col_w * (i + 1.0)
		var ray_mat2 := StandardMaterial3D.new()
		ray_mat2.albedo_color = Color(1.0, 0.90, 0.65, 0.022)
		ray_mat2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ray_mat2.emission_enabled = true
		ray_mat2.emission = Color(1.0, 0.85, 0.55)
		ray_mat2.emission_energy_multiplier = 0.04
		ray_mat2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ray_mat2.cull_mode = BaseMaterial3D.CULL_DISABLED
		_add_god_ray(ray_mat2, cx, i)


func _add_god_ray(mat: StandardMaterial3D, cx: float, idx: int) -> void:
	# Plan incliné qui simule un faisceau de lumière
	var ray_mi   := MeshInstance3D.new()
	var ray_mesh := BoxMesh.new()

	# Longueur du rayon depuis la fenêtre jusqu'au sol / fond de pièce
	var ray_len  := 3.5 + idx * 0.2
	var ray_w    := WIN_W / WIN_COLS * 0.82   # presque toute la largeur du carreau
	var ray_h    := 0.025

	ray_mesh.size = Vector3(ray_w, ray_h, ray_len)
	ray_mi.mesh   = ray_mesh

	# Angle : légèrement incliné vers le bas et de côté pour avoir un look naturel
	ray_mi.rotation_degrees = Vector3(-18 - idx * 2.5, 0, 0)
	# Position : depuis la fenêtre vers l'intérieur
	var ray_z := WIN_Z + 0.1 + ray_len * 0.5 * cos(deg_to_rad(18 + idx * 2.5))
	var ray_y := WIN_Y - ray_len * 0.5 * sin(deg_to_rad(18 + idx * 2.5))
	ray_mi.position = Vector3(cx, ray_y, ray_z)
	ray_mi.material_override = mat
	add_child(ray_mi)


# ─── BUREAU ───────────────────────────────────────────────────────────────────
func _build_desk():
	# Plateau — vieux bois foncé
	_make_box(Vector3(0, 0.75, 0), Vector3(2.4, 0.055, 1.0), COL_WOOD_DARK)
	# Bord légèrement plus clair (usure)
	_make_box(Vector3(0, 0.773, 0.5), Vector3(2.4, 0.01, 0.01), COL_WOOD_MED)

	# 4 pieds métal rouillé
	for sx in [-1.1, 1.1]:
		for sz in [0.0, -0.45]:
			_make_box(Vector3(sx, 0.37, sz), Vector3(0.055, 0.75, 0.055), COL_METAL_RUST)

	# Traverse horizontale (renfort)
	_make_box(Vector3(0, 0.2, -0.2), Vector3(2.2, 0.03, 0.04), COL_METAL_DARK)

	# Tiroir (droite)
	_make_box(Vector3(0.82, 0.56, 0.0), Vector3(0.58, 0.22, 0.92), Color(0.18, 0.12, 0.07))
	# Poignée
	_make_cylinder(Vector3(0.82, 0.56, 0.465), 0.012, 0.1, COL_METAL_RUST)

	# Fond du bureau (panneau arrière déco)
	_make_box(Vector3(0, 0.37, -0.5), Vector3(2.3, 0.7, 0.02), Color(0.16, 0.11, 0.06))


# ─── MONITEUR ────────────────────────────────────────────────────────────────
func _build_monitor():
	# Base pied
	_make_box(Vector3(0, 0.793, -0.25), Vector3(0.20, 0.022, 0.20), COL_METAL_DARK)
	# Colonne pied
	_make_box(Vector3(0, 0.875, -0.29), Vector3(0.035, 0.168, 0.035), COL_METAL_DARK)
	# Chassis écran (gris foncé vieilli)
	_make_box(Vector3(0, 1.35, -0.32), Vector3(1.3, 0.82, 0.055), COL_DESK_SCREEN)
	# Bordure intérieure (légèrement plus sombre)
	_make_box(Vector3(0, 1.35, -0.295), Vector3(1.22, 0.74, 0.01), Color(0.08, 0.08, 0.10))

	# SubViewport
	if sub_viewport:
		sub_viewport.size = Vector2i(1152, 648)
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		sub_viewport.gui_disable_input = true
		sub_viewport.handle_input_locally = false


# ─── CLAVIER ─────────────────────────────────────────────────────────────────
func _build_keyboard():
	# Base clavier (plastique vieilli jaunâtre)
	_make_box(Vector3(0, 0.784, 0.2), Vector3(0.9, 0.022, 0.32), Color(0.30, 0.27, 0.22))
	# Rangées de touches
	for row in range(4):
		for col in range(10):
			_make_box(
				Vector3(-0.4 + col * 0.085, 0.800, 0.09 + row * 0.072),
				Vector3(0.068, 0.010, 0.058),
				Color(0.28, 0.25, 0.20) if (row + col) % 3 != 0 else Color(0.22, 0.20, 0.16)
			)
	# Barre espace
	_make_box(Vector3(0.0, 0.800, 0.37), Vector3(0.35, 0.010, 0.058), Color(0.32, 0.29, 0.24))


# ─── LIT ──────────────────────────────────────────────────────────────────────
func _build_bed():
	# Tête de lit contre mur gauche
	_make_box(Vector3(-2.35, 1.05, -1.5), Vector3(0.08, 1.3, 1.9), COL_WOOD_DARK)
	# Panneau tête de lit (déco vertical)
	for i in range(3):
		_make_box(
			Vector3(-2.30, 0.9, -1.85 + i * 0.65),
			Vector3(0.02, 0.9, 0.5),
			Color(0.16, 0.10, 0.06)
		)
	# Pied de lit
	_make_box(Vector3(-2.35, 0.45, 0.55), Vector3(0.08, 0.55, 0.1), COL_WOOD_DARK)

	# Cadre lattes
	_make_box(Vector3(-1.82, 0.24, -0.5), Vector3(1.02, 0.04, 2.0), COL_WOOD_DARK)
	# Lattes (partiellement visibles)
	for i in range(5):
		_make_box(
			Vector3(-1.82, 0.268, -1.35 + i * 0.45),
			Vector3(0.95, 0.025, 0.07),
			COL_WOOD_MED
		)

	# Matelas
	_make_box(Vector3(-1.82, 0.52, -0.5), Vector3(1.0, 0.25, 2.0), Color(0.42, 0.36, 0.30))
	# Drap froissé (plusieurs couches d'épaisseur variable)
	_make_box(Vector3(-1.72, 0.665, -0.35), Vector3(0.80, 0.06, 0.8),  Color(0.58, 0.54, 0.49))
	_make_box(Vector3(-1.92, 0.70, -0.0),   Vector3(0.55, 0.08, 0.5),  Color(0.52, 0.48, 0.43))
	_make_box(Vector3(-1.60, 0.685, 0.3),   Vector3(0.65, 0.055, 0.4), Color(0.60, 0.56, 0.50))
	# Bord drap replié
	_make_box(Vector3(-1.82, 0.675, -1.35), Vector3(0.95, 0.04, 0.08), Color(0.62, 0.58, 0.52))

	# Oreiller
	_make_box(Vector3(-1.82, 0.65, -1.32), Vector3(0.80, 0.13, 0.42), Color(0.68, 0.64, 0.58))
	# Légère dépression oreiller
	_make_box(Vector3(-1.78, 0.712, -1.32), Vector3(0.40, 0.01, 0.28), Color(0.62, 0.58, 0.52))


# ─── DÉCORATIONS ─────────────────────────────────────────────────────────────
func _build_decorations():
	# ── Lampe de bureau ──
	_make_cylinder(Vector3(0.90, 0.781, -0.10), 0.060, 0.014, COL_METAL_DARK)
	_make_box(Vector3(0.90, 0.88, -0.10), Vector3(0.020, 0.205, 0.020), COL_METAL_RUST)
	_make_box(Vector3(0.88, 0.99, -0.16), Vector3(0.020, 0.020, 0.130), COL_METAL_RUST)
	# Abat-jour conique
	_make_box(Vector3(0.88, 0.975, -0.24), Vector3(0.120, 0.065, 0.115), Color(0.38, 0.28, 0.18))
	_make_box(Vector3(0.88, 0.940, -0.24), Vector3(0.100, 0.020, 0.095), Color(0.30, 0.22, 0.14))
	# Ampoule visible
	_make_cylinder(Vector3(0.88, 0.960, -0.24), 0.022, 0.04, Color(1.0, 0.95, 0.80), true)

	# ── Tasse ──
	_make_cylinder(Vector3(-0.85, 0.875, 0.12), 0.050, 0.090, Color(0.38, 0.33, 0.27))
	_make_cylinder(Vector3(-0.85, 0.919, 0.12), 0.044, 0.012, Color(0.10, 0.05, 0.02))
	# Anse
	_make_box(Vector3(-0.80, 0.875, 0.12), Vector3(0.030, 0.050, 0.012), Color(0.38, 0.33, 0.27))

	# ── Livre ouvert ──
	_make_box(Vector3(-1.0, 0.787, -0.12), Vector3(0.26, 0.020, 0.18), Color(0.55, 0.45, 0.32))
	_make_box(Vector3(-0.875, 0.800, -0.12), Vector3(0.12, 0.005, 0.17), Color(0.92, 0.88, 0.80))
	_make_box(Vector3(-1.125, 0.800, -0.12), Vector3(0.12, 0.005, 0.17), Color(0.90, 0.86, 0.78))
	# Lignes de texte simulées
	for ln in range(5):
		_make_box(
			Vector3(-0.875, 0.807, -0.16 + ln * 0.03),
			Vector3(0.09 if ln % 3 != 2 else 0.06, 0.002, 0.005),
			Color(0.30, 0.25, 0.18)
		)

	# ── Câbles bureau ──
	for i in range(3):
		_make_box(Vector3(-0.05 + i * 0.04, 0.778, 0.1), Vector3(0.016, 0.008, 0.6), Color(0.08, 0.07, 0.06))

	# ── Objet sur rebord fenêtre ──
	# Pot de plante morte (branch cassée)
	_make_cylinder(Vector3(-0.4, 0.94, -2.22), 0.038, 0.060, Color(0.38, 0.26, 0.14))
	_make_cylinder(Vector3(-0.4, 0.975, -2.22), 0.028, 0.06, Color(0.22, 0.20, 0.16))
	_make_box(Vector3(-0.4, 1.01, -2.22), Vector3(0.008, 0.06, 0.008), Color(0.20, 0.17, 0.12))
	# Vieille canette (rebord fenêtre droite)
	_make_cylinder(Vector3(0.5, 0.935, -2.20), 0.035, 0.070, Color(0.35, 0.30, 0.25))
	_make_cylinder(Vector3(0.5, 0.975, -2.20), 0.028, 0.010, Color(0.25, 0.22, 0.18))

	# ── Interrupteur mural ──
	_make_box(Vector3(-2.93, 1.22, 1.45), Vector3(0.020, 0.10, 0.07), Color(0.50, 0.46, 0.40))
	_make_box(Vector3(-2.92, 1.22, 1.45), Vector3(0.010, 0.055, 0.030), Color(0.80, 0.76, 0.70))

	# ── Prise électrique ──
	_make_box(Vector3(-2.93, 0.45, 1.8), Vector3(0.018, 0.08, 0.06), Color(0.48, 0.44, 0.38))
	_make_box(Vector3(-2.92, 0.48, 1.78), Vector3(0.008, 0.012, 0.012), Color(0.20, 0.18, 0.16))
	_make_box(Vector3(-2.92, 0.42, 1.78), Vector3(0.008, 0.012, 0.012), Color(0.20, 0.18, 0.16))


# ─── DÉCORATIONS MURALES ──────────────────────────────────────────────────────
func _build_wall_decorations():
	# ── Affiche délavée (mur arrière droit) ──
	_make_box(Vector3(2.0, 1.8, -2.44), Vector3(0.75, 1.0, 0.018), Color(0.35, 0.30, 0.24))
	_make_box(Vector3(2.0, 1.8, -2.432), Vector3(0.70, 0.95, 0.010), Color(0.30, 0.26, 0.20))
	# Contenu flou — bandes de couleur
	_make_box(Vector3(2.0, 2.18, -2.428), Vector3(0.60, 0.06, 0.005), Color(0.42, 0.34, 0.24))
	_make_box(Vector3(1.9, 2.05, -2.428), Vector3(0.45, 0.035, 0.005), Color(0.38, 0.32, 0.22))
	_make_box(Vector3(2.0, 1.90, -2.428), Vector3(0.55, 0.028, 0.005), Color(0.36, 0.30, 0.20))
	# Coin déchiré
	_make_box(Vector3(2.36, 2.25, -2.435), Vector3(0.04, 0.16, 0.006), Color(0.38, 0.33, 0.26))
	_make_box(Vector3(2.37, 2.18, -2.430), Vector3(0.02, 0.08, 0.012), Color(0.52, 0.47, 0.40))

	# ── Fissures mur arrière ──
	# Fissure principale (départ plafond)
	_make_box(Vector3(-1.8, 2.75, -2.44), Vector3(0.008, 0.5, 0.005), Color(0.25, 0.20, 0.16))
	_make_box(Vector3(-1.77, 2.55, -2.44), Vector3(0.005, 0.25, 0.005), Color(0.22, 0.18, 0.14))
	_make_box(Vector3(-1.82, 2.62, -2.44), Vector3(0.12, 0.005, 0.005), Color(0.22, 0.18, 0.14))

	# ── Étagère murale gauche (avec livres) ──
	_make_box(Vector3(-2.55, 1.85, -1.0), Vector3(0.75, 0.038, 0.20), COL_WOOD_MED)
	# Supports
	_make_box(Vector3(-2.20, 1.65, -1.0), Vector3(0.025, 0.40, 0.025), COL_METAL_DARK)
	_make_box(Vector3(-2.90, 1.65, -1.0), Vector3(0.025, 0.40, 0.025), COL_METAL_DARK)
	# Livres
	var book_cols := [Color(0.50, 0.10, 0.08), Color(0.08, 0.22, 0.40), Color(0.30, 0.28, 0.10), Color(0.22, 0.40, 0.22)]
	for i in range(4):
		var bw := 0.06 + (i % 2) * 0.02
		var bh := 0.15 + (i % 3) * 0.04
		_make_box(Vector3(-2.80 + i * 0.14, 1.888 + bh * 0.5, -1.0), Vector3(bw, bh, 0.17), book_cols[i])
		# Tranche
		_make_box(Vector3(-2.80 + i * 0.14, 1.888 + bh * 0.5, -0.91), Vector3(bw - 0.01, bh + 0.004, 0.005), Color(0.88, 0.84, 0.75))

	# ── Tour PC (sous bureau) ──
	_make_box(Vector3(-0.90, 0.40, -0.26), Vector3(0.19, 0.74, 0.40), Color(0.22, 0.20, 0.18))
	# Fentes ventilation
	for i in range(6):
		_make_box(Vector3(-0.81, 0.55 + i * 0.055, -0.065), Vector3(0.018, 0.022, 0.22), Color(0.12, 0.10, 0.08))
	# LED power (seul truc qui brille)
	_make_box(Vector3(-0.81, 0.39, -0.065), Vector3(0.018, 0.008, 0.008), Color(0.0, 0.9, 0.2), true)
	# Lecteur optique
	_make_box(Vector3(-0.81, 0.42, -0.065), Vector3(0.14, 0.018, 0.35), Color(0.18, 0.16, 0.14))
	# Câble tombant
	_make_box(Vector3(-0.82, 0.2, 0.1), Vector3(0.012, 0.4, 0.012), Color(0.08, 0.07, 0.06))

	# ── Câbles au sol ──
	for i in range(3):
		_make_box(
			Vector3(-0.15 + i * 0.06, 0.004, 0.5),
			Vector3(0.014, 0.008, 1.5),
			Color(0.08, 0.07, 0.06)
		)

	# ── Radiateur (mur gauche, bas) ──
	_make_box(Vector3(-2.80, 0.30, 0.6), Vector3(0.22, 0.42, 0.70), COL_METAL_RUST)
	# Ailettes
	for i in range(5):
		_make_box(
			Vector3(-2.70, 0.30, 0.32 + i * 0.12),
			Vector3(0.015, 0.38, 0.045),
			COL_METAL_DARK
		)
	# Robinets
	_make_cylinder(Vector3(-2.70, 0.55, 0.26), 0.020, 0.06, COL_METAL_RUST)
	_make_cylinder(Vector3(-2.70, 0.55, 0.94), 0.020, 0.06, COL_METAL_RUST)

	# ── Placard / armoire (mur droit) ──
	_make_box(Vector3(2.62, 1.4, -1.5), Vector3(0.65, 2.8, 1.0), Color(0.30, 0.24, 0.16))
	# Portes placard
	_make_box(Vector3(2.62, 1.4, -1.75), Vector3(0.62, 2.7, 0.02), Color(0.34, 0.28, 0.20))
	_make_box(Vector3(2.62, 1.4, -1.25), Vector3(0.62, 2.7, 0.02), Color(0.34, 0.28, 0.20))
	# Fente entre portes
	_make_box(Vector3(2.62, 1.4, -1.50), Vector3(0.63, 2.72, 0.008), Color(0.14, 0.12, 0.08))
	# Poignées
	_make_cylinder(Vector3(2.62, 1.4, -1.62), 0.012, 0.08, COL_METAL_RUST)
	_make_cylinder(Vector3(2.62, 1.4, -1.38), 0.012, 0.08, COL_METAL_RUST)

	# ── Fissure plafond ──
	_make_box(Vector3(0.5, 3.04, -0.8), Vector3(0.008, 0.005, 0.65), Color(0.28, 0.24, 0.18))
	_make_box(Vector3(0.62, 3.04, -0.7), Vector3(0.22, 0.005, 0.006), Color(0.28, 0.24, 0.18))


# ─── LUMIÈRES ────────────────────────────────────────────────────────────────
func _setup_lights():
	# ── Lumière principale depuis fenêtre ──
	# DirectionalLight avec shadows → crée des barreaux dans le fog volumétrique
	var sun := DirectionalLight3D.new()
	sun.light_color  = COL_SUNLIGHT
	sun.light_energy = 1.8
	sun.rotation_degrees = Vector3(-28, 12, 0)   # angle rasant = beaux rayons
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_split_1 = 0.1
	sun.directional_shadow_split_2 = 0.2
	sun.directional_shadow_split_3 = 0.5
	sun.shadow_blur = 3.0
	add_child(sun)

	# OmniLight concentrée côté fenêtre (renforce la lumière qui entre)
	_add_omni_light(Vector3(WIN_X, WIN_Y, WIN_Z + 0.5), COL_SUNLIGHT, 2.5, 4.5)

	# Reflet sol (lumière rebondissant sur le parquet)
	_add_omni_light(Vector3(0.0, 0.05, -1.0), Color(0.9, 0.75, 0.50), 0.4, 3.5)

	# ── Ampoule plafond (très faible, juste filament) ──
	# Câble
	_make_box(Vector3(0.5, 2.92, -0.5), Vector3(0.006, 0.16, 0.006), Color(0.08, 0.07, 0.06))
	# Douille
	_make_cylinder(Vector3(0.5, 2.80, -0.5), 0.025, 0.04, COL_METAL_DARK)
	# Ampoule (géo)
	_make_cylinder(Vector3(0.5, 2.77, -0.5), 0.038, 0.06, Color(0.92, 0.88, 0.75), true)
	# Sa lumière (très faible)
	_add_omni_light(Vector3(0.5, 2.73, -0.5), COL_BULB, 0.08, 2.5)

	# ── Lampe de bureau ──
	desk_lamp_light = _add_omni_light(Vector3(0.88, 0.95, -0.24), COL_BULB, 1.5, 1.6)

	# ── Lueur écran moniteur ──
	_add_omni_light(Vector3(0, 1.35, 0.18), Color(0.25, 0.90, 0.45), 0.18, 0.9)


func _add_omni_light(pos: Vector3, color: Color, energy: float, radius: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position     = pos
	light.light_color  = color
	light.light_energy = energy
	light.omni_range   = radius
	light.shadow_enabled = false
	add_child(light)
	return light


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
		if os_cursor:
			os_cursor.move_to(vp_cursor_pos)
		if os_main:
			os_main.on_cursor_move(vp_cursor_pos)
		var vp_event := InputEventMouseMotion.new()
		vp_event.position = vp_cursor_pos
		vp_event.global_position = vp_cursor_pos
		vp_event.relative = event.relative
		sub_viewport.push_input(vp_event)
		get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and is_at_terminal:
		if os_main:
			os_main.on_cursor_press(vp_cursor_pos, event.pressed)
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
	if d2 < 0.1 * 0.1:
		_toggle_lamp()


func _toggle_lamp():
	lamp_enabled = !lamp_enabled
	if desk_lamp_light:
		var lt := create_tween()
		lt.tween_property(desk_lamp_light, "light_energy", 1.5 if lamp_enabled else 0.0, 0.12)


func _toggle_terminal_view():
	is_at_terminal = !is_at_terminal
	if tween:
		tween.kill()
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
		os_main = os_node


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

	# Scanlines
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

	# Bande phosphore
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
