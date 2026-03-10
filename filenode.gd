extends Node

# Le vrai nom du fichier, affiché dans le terminal
@export var filename: String = "file.txt"

# Contenu du fichier
@export var content: String = "Hello World!"

# Méthode pour retourner le contenu
func get_content() -> String:
	return content
