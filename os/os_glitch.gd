# os_glitch.gd
# Attache à un CanvasLayer "GlitchLayer" dans OS.tscn
# layer: 200
extends CanvasLayer

@onready var root: Control = $GlitchRoot

# Dossier des photos compromettantes
# Mets tes images dans res://assets/blackmail_photos/
# Formats supportés : .png .jpg .webp
const PHOTOS_PATH = "res://assets/blackmail_photos/"

var _photo_frames: Array = []


func _ready() -> void:
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GlitchManager.glitch_requested.connect(_on_glitch_requested)


func _on_glitch_requested(intensity: float, duration: float) -> void:
	_run_glitch(intensity, duration)


func _run_glitch(intensity: float, duration: float) -> void:
	for child in root.get_children():
		child.queue_free()
	_photo_frames.clear()

	var vp := get_viewport().get_visible_rect().size
	var end_time := Time.get_ticks_msec() + int(duration * 1000)

	# Charge les photos disponibles
	var photos := _load_photos()

	# Phase 1 : glitch intense court
	var glitch_end := Time.get_ticks_msec() + int(duration * 1000)
	while Time.get_ticks_msec() < glitch_end:
		var bar_count := randi_range(int(4 * intensity), int(14 * intensity))
		for _i in bar_count:
			var bar := ColorRect.new()
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var h := randf_range(2.0, 12.0 * intensity)
			var w := randf_range(vp.x * 0.1, vp.x * intensity)
			bar.size = Vector2(w, h)
			bar.position = Vector2(
				randf_range(0.0, vp.x - w),
				randf_range(0.0, vp.y)
			)
			var colors = [
				Color(0.9, 0.0, 0.1, randf_range(0.4, 0.85)),
				Color(1.0, 1.0, 1.0, randf_range(0.15, 0.4)),
				Color(0.0, 0.9, 0.9, randf_range(0.2, 0.6)),
				Color(0.0, 0.0, 0.0, randf_range(0.3, 0.7)),
			]
			bar.color = colors[randi() % colors.size()]
			root.add_child(bar)
			# Les barres sont derrière les photos
			root.move_child(bar, 0)

		if randf() < 0.4 * intensity:
			var flash := ColorRect.new()
			flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
			flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			flash.color = Color(0.7, 0.0, 0.05, randf_range(0.06, 0.18 * intensity))
			root.add_child(flash)
			root.move_child(flash, 0)

		await get_tree().process_frame

		# Supprime uniquement les barres (pas les photos)
		for child in root.get_children():
			if child not in _photo_frames:
				child.queue_free()

		await get_tree().create_timer(randf_range(0.02, 0.06)).timeout

	# Phase 2 : les photos apparaissent dans le calme
	if photos.size() > 0:
		var count := mini(randi_range(1, 3), photos.size())
		var used_positions: Array = []
		for _i in count:
			var photo: Texture2D = photos[randi() % photos.size()]
			var pos := _find_free_position(vp, used_positions)
			used_positions.append(pos)
			_spawn_photo_frame(photo, pos, vp)

	# Pause — le joueur voit les photos
	await get_tree().create_timer(randf_range(2.5, 3.5)).timeout

	# Phase 3 : second glitch court puis fermeture brutale
	var glitch2_end := Time.get_ticks_msec() + 400
	while Time.get_ticks_msec() < glitch2_end:
		var bar_count := randi_range(6, 16)
		for _i in bar_count:
			var bar := ColorRect.new()
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bar.size = Vector2(randf_range(vp.x * 0.1, vp.x), randf_range(2.0, 10.0))
			bar.position = Vector2(randf_range(0.0, vp.x * 0.3), randf_range(0.0, vp.y))
			var colors = [Color(0.9, 0.0, 0.1, 0.7), Color(1.0, 1.0, 1.0, 0.3), Color(0.0, 0.0, 0.0, 0.8)]
			bar.color = colors[randi() % colors.size()]
			root.add_child(bar)
			root.move_child(bar, 0)
		await get_tree().process_frame
		for child in root.get_children():
			if child not in _photo_frames:
				child.queue_free()
		await get_tree().create_timer(0.03).timeout

	# Fermeture brutale des photos
	_fade_out_photos()


func _load_photos() -> Array:
	var photos: Array = []
	var dir := DirAccess.open(PHOTOS_PATH)
	if not dir:
		# Dossier inexistant — retourne liste vide silencieusement
		return photos
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if not dir.current_is_dir():
			var ext := file.get_extension().to_lower()
			if ext in ["png", "jpg", "jpeg", "webp"]:
				var tex := load(PHOTOS_PATH + file)
				if tex:
					photos.append(tex)
		file = dir.get_next()
	return photos


func _find_free_position(vp: Vector2, used: Array) -> Vector2:
	var photo_size := Vector2(180, 140)
	var margin := 20.0
	var attempts := 0
	while attempts < 20:
		var pos := Vector2(
			randf_range(margin, vp.x - photo_size.x - margin),
			randf_range(margin, vp.y - photo_size.y - margin - 40)  # évite la taskbar
		)
		var valid := true
		for used_pos in used:
			if pos.distance_to(used_pos) < photo_size.x + 20:
				valid = false
				break
		if valid:
			return pos
		attempts += 1
	# Fallback : position aléatoire
	return Vector2(randf_range(20, vp.x - 200), randf_range(20, vp.y - 180))


func _spawn_photo_frame(texture: Texture2D, pos: Vector2, vp: Vector2) -> void:
	# Conteneur principal de la photo (style Polaroid)
	var frame := PanelContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.position = pos
	# Légère rotation aléatoire
	frame.rotation = randf_range(-0.12, 0.12)

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#111111")
	style.border_color = Color("#cc2233")
	style.set_border_width_all(2)
	style.set_content_margin_all(6)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.shadow_color = Color(0, 0, 0, 0.8)
	style.shadow_size = 12
	frame.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	frame.add_child(vbox)

	# Image
	var img := TextureRect.new()
	img.texture = texture
	img.custom_minimum_size = Vector2(168, 110)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(img)

	# Légende style hacker
	var caption := Label.new()
	caption.text = _random_caption()
	caption.add_theme_font_size_override("font_size", 9)
	caption.add_theme_color_override("font_color", Color("#cc2233"))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(caption)

	root.add_child(frame)
	_photo_frames.append(frame)

	# Apparition rapide
	frame.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(frame, "modulate:a", 1.0, 0.08)


func _random_caption() -> String:
	var captions = [
		"JE SAIS",
		"JE VOIS TOUT",
		"TU TE SOUVIENS ?",
		"▓▓▓▓▓▓",
		"PREUVE #%d" % randi_range(1, 47),
		"FICHIER CONFIDENTIEL",
		"NE PAS PARTAGER",
		"COLLECTION_%d" % randi_range(100, 999),
	]
	return captions[randi() % captions.size()]


func _fade_out_photos() -> void:
	for frame in _photo_frames:
		if is_instance_valid(frame):
			# Animation "fermeture de fenêtre" : rétrécit vers le coin supérieur droit
			var tw := create_tween()
			tw.set_parallel(true)
			tw.tween_property(frame, "scale", Vector2(0.0, 0.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tw.tween_property(frame, "modulate:a", 0.0, 0.08)
			tw.tween_callback(frame.queue_free).set_delay(0.12)
	_photo_frames.clear()
