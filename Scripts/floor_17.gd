extends Sprite2D # extiende de Floor17

# cargo la imagen con las puertas abiertas
var fondo_abierto = preload("res://Assets/Stage2/floor17open.png")

func _on_timer_timeout() -> void: # se conecta a un timer al no estar los enemigos todavia
	texture = fondo_abierto
