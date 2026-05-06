# glitch_manager.gd
# Autoload GlitchManager
# Permet à n'importe quel script d'émettre un glitch sur l'écran
extends Node

signal glitch_requested(intensity: float, duration: float)

func trigger(intensity: float = 1.0, duration: float = 0.6) -> void:
	glitch_requested.emit(intensity, duration)
