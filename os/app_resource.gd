# app_resource.gd
extends Resource
class_name AppResource

@export var id: String = ""
@export var label: String = ""
@export var icon: Texture2D
@export var scene: PackedScene
@export var default_size: Vector2 = Vector2(600, 400)
@export var accent_color: Color = Color("#3366cc")
