extends CharacterBody2D

var speed : float = 120
var atacando : bool = false

func _process(_delta: float) -> void:
	if atacando:
		return 
	
	var movement = Vector2()
	
	# MOVIMIENTO Y CORRECCIÓN DE GIRO (OFFSET)
	if Input.is_action_pressed("ui_right"):
		movement.x += 1
		$AnimatedSprite2D.flip_h = false
		$AnimatedSprite2D.offset.x = 0 # Posición normal cuando mira a la derecha
	elif Input.is_action_pressed("ui_left"):
		movement.x -= 1
		$AnimatedSprite2D.flip_h = true
		# AQUÍ VA LA CORRECCIÓN: Ajusta el -20 hasta que Rick deje de "saltar"
		$AnimatedSprite2D.offset.x = -30 
		
	if Input.is_action_pressed("ui_down"):
		movement.y += 1
	elif Input.is_action_pressed("ui_up"):
		movement.y -= 1
		
	movement = movement.normalized()
	
	if movement != Vector2.ZERO:
		velocity = movement * speed
		$AnimatedSprite2D.play("Walk")
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("Idle")

	# BOTONES DE ACCIÓN
	if Input.is_action_just_pressed("Punch"):
		ejecutar_golpe()
	
	if Input.is_action_just_pressed("Jump"):
		$AnimatedSprite2D.play("Jump")

func ejecutar_golpe():
	atacando = true
	$AnimatedSprite2D.play("Punch")

func _on_animated_sprite_2d_animation_finished():
	if $AnimatedSprite2D.animation == "Punch":
		atacando = false
		$AnimatedSprite2D.play ("Idle") # Forzamos el regreso al estado de espera
	
	# También puedes agregar aquí el salto si hiciste uno
	if $AnimatedSprite2D.animation == "Jump":
		$AnimatedSprite2D.play("Idle")
