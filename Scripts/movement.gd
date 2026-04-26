extends CharacterBody2D

var speed : float = 120
var atacando : bool = false

func _ready () -> void:
	name = "Player"

func _process(_delta: float) -> void:
	if atacando:
		return 
	
	var movement = Vector2()
	
	# movimiento y correccion de sprite
	if Input.is_action_pressed("ui_right"):
		movement.x += 1
		$AnimatedSprite2D.flip_h = false
		$AnimatedSprite2D.offset.x = 0 # posicion normal mirando a la derecha
	elif Input.is_action_pressed("ui_left"):
		movement.x -= 1
		$AnimatedSprite2D.flip_h = true
		$AnimatedSprite2D.offset.x = -30 # se ajusta la posicion al girarse
		
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

	# botones de acciones
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
		$AnimatedSprite2D.play ("Idle") # se golpea y se regresa al estado Idle
	
	if $AnimatedSprite2D.animation == "Jump":
		$AnimatedSprite2D.play("Idle")
