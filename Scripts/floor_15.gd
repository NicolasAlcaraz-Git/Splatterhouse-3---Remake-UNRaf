extends Sprite2D # extiende de Floor15

# cargo la imagen con las puertas abiertas
var fondo_abierto = preload("res://Assets/Stage2/floor15open.png")

func _on_timer_timeout() -> void: # se conecta a un timer al no estar los enemigos todavia
	texture = fondo_abierto
