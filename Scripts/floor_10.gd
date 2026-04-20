extends Sprite2D # extiende de Floor10

# cargo la imagen con las puertas abiertas
var fondo_abierto = preload("res://Assets/Stage 1/floor10open.png")

func _on_timer_timeout() -> void: # se conecta a un timer al no estar los enemigos todavia
	texture = fondo_abierto
