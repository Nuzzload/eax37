# settings.gd
extends Control

@onready var crt_toggle: CheckButton = $VBoxContainer/CRTSetting/CRTCheckButton

func _ready():
	# Initialise l'état du toggle depuis les paramètres globaux
	crt_toggle.button_pressed = MissionManager.settings.get("crt_filter", true)
	crt_toggle.toggled.connect(_on_crt_toggled)

func _on_crt_toggled(button_pressed: bool):
	MissionManager.set_setting("crt_filter", button_pressed)
