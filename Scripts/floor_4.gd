extends Sprite2D # extiende de Floor4

# cargo la imagen con las puertas abiertas
var fondo_abierto = preload("res://Assets/Stage1/floor4open.png")

func _on_timer_timeout() -> void: # se conecta a un timer al no estar los enemigos todavia
	texture = fondo_abierto
