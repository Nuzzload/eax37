# glitch_manager.gd
# Autoload GlitchManager
# Permet à n'importe quel script d'émettre un glitch sur l'écran
extends Node

# kind détermine la palette de couleurs utilisée par les écouteurs :
#   "hacker"   — rouge/blanc/cyan, UNKNOWN_▓▓▓ (menace, blackmail)
#   "sentinel" — vert/blanc/cyan, SENTINELLE (contact allié)
signal glitch_requested(intensity: float, duration: float, kind: String)

func trigger(intensity: float = 1.0, duration: float = 0.6, kind: String = "hacker") -> void:
	glitch_requested.emit(intensity, duration, kind)
