extends Sprite2D # extiende de Floor2

# cargo la imagen con las puertas abiertas
var fondo_abierto = preload("res://Assets/Stage1/floor2open.png")

func _on_timer_timeout() -> void: # se conecta a un timer al no estar los enemigos todavia
	texture = fondo_abierto
