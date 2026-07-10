# screen_glitch.gd
# Attache à un CanvasLayer "ScreenGlitch" dans room.tscn
# Écoute GlitchManager et affiche un effet glitch par-dessus la scène 3D
# Structure :
#   CanvasLayer "ScreenGlitch"  (screen_glitch.gd)
#   └── Control "GlitchRoot"   — Full Rect, Mouse Filter Ignore
extends CanvasLayer

@onready var root: Control = $GlitchRoot

func _ready() -> void:
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Connecte le signal du GlitchManager
	GlitchManager.glitch_requested.connect(_on_glitch_requested)


# Palettes de barres, par "kind" — hacker = rouge sang, sentinel = vert (contact allié)
const PALETTES := {
	"hacker": [
		Color(0.8, 0.0, 0.1, 0.7),
		Color(1.0, 1.0, 1.0, 0.3),
		Color(0.0, 0.8, 0.8, 0.5),
	],
	"sentinel": [
		Color(0.1, 0.8, 0.35, 0.7),
		Color(1.0, 1.0, 1.0, 0.3),
		Color(0.0, 0.8, 0.6, 0.5),
	],
}
const FLASH_COLORS := {
	"hacker":   Color(0.6, 0.0, 0.05, 1.0),
	"sentinel": Color(0.05, 0.55, 0.2, 1.0),
}


func _on_glitch_requested(intensity: float, duration: float, kind: String = "hacker") -> void:
	_run_glitch(intensity, duration, kind)


func _run_glitch(intensity: float, duration: float, kind: String = "hacker") -> void:
	# Nettoie les anciens éléments
	for child in root.get_children():
		child.queue_free()

	var palette: Array = PALETTES.get(kind, PALETTES["hacker"])
	var flash_color: Color = FLASH_COLORS.get(kind, FLASH_COLORS["hacker"])
	var vp := get_viewport().get_visible_rect().size
	var end_time := Time.get_ticks_msec() + int(duration * 1000)

	while Time.get_ticks_msec() < end_time:
		# Spawn des barres de glitch
		var bar_count := randi_range(int(3 * intensity), int(10 * intensity))
		for _i in bar_count:
			var bar := ColorRect.new()
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var h := randf_range(1.0, 8.0 * intensity)
			var w := randf_range(vp.x * 0.05, vp.x * intensity)
			bar.size = Vector2(w, h)
			bar.position = Vector2(
				randf_range(0.0, vp.x - w),
				randf_range(0.0, vp.y)
			)
			var c: Color = palette[randi() % palette.size()]
			c.a = randf_range(c.a * 0.4, c.a)
			bar.color = c
			root.add_child(bar)

		# Flash global occasionnel
		if randf() < 0.3 * intensity:
			var flash := ColorRect.new()
			flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
			flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			flash.color = Color(flash_color.r, flash_color.g, flash_color.b, randf_range(0.05, 0.15 * intensity))
			root.add_child(flash)

		await get_tree().process_frame

		# Nettoie les barres
		for child in root.get_children():
			child.queue_free()

		# Pause courte entre les frames de glitch
		await get_tree().create_timer(randf_range(0.03, 0.08)).timeout

	# Nettoyage final
	for child in root.get_children():
		child.queue_free()
