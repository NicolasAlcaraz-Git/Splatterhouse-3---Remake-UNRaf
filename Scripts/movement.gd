extends CharacterBody2D

var speed: float = 120
var atacando: bool = false
var hp: int = 5

@onready var punch_collision: CollisionShape2D = $Punch/CollisionShape2D
@onready var punch_area: Area2D = $Punch
@onready var hitbox: Area2D = $Hitbox
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var punch_offset_right: float = 0.0
var mirando_derecha: bool = true

const PUNCH_ACTIVE_FRAME: int = 1

func _ready() -> void:
	print("SCRIPT CARGADO CORRECTAMENTE")
	punch_collision.set_deferred("disabled", true)
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)  # ← agregá esta
	punch_offset_right = 21.0
	punch_area.position.x = punch_offset_right

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Punch"):
		print("Punch presionado, atacando vale: ", atacando)

	# Actualizar dirección SIEMPRE, incluso si está atacando
	if Input.is_action_pressed("ui_right"):
		sprite.flip_h = false
		sprite.offset.x = 0
		mirando_derecha = true
	elif Input.is_action_pressed("ui_left"):
		sprite.flip_h = true
		sprite.offset.x = -30
		mirando_derecha = false

	_actualizar_punch()  # ← ANTES del return

	if atacando:
		return

	var movement = Vector2()

	if Input.is_action_pressed("ui_right"):
		movement.x += 1
	elif Input.is_action_pressed("ui_left"):
		movement.x -= 1

	if Input.is_action_pressed("ui_down"):
		movement.y += 1
	elif Input.is_action_pressed("ui_up"):
		movement.y -= 1

	movement = movement.normalized()

	if movement != Vector2.ZERO:
		velocity = movement * speed
		sprite.play("Walk")
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		sprite.play("Idle")

	if Input.is_action_just_pressed("Punch"):
		ejecutar_golpe()

	if Input.is_action_just_pressed("Jump"):
		sprite.play("Jump")
		
func _actualizar_punch() -> void:
	if mirando_derecha:
		punch_area.position.x = punch_offset_right
	else:
		punch_area.position.x = -punch_offset_right
	print("punch_area.x ahora vale: ", punch_area.position.x)

func ejecutar_golpe() -> void:
	atacando = true
	_actualizar_punch()  # asegurar posición correcta al golpear
	sprite.play("Punch")

func _on_frame_changed() -> void:
	if sprite.animation != "Punch":
		if not punch_collision.disabled:
			punch_collision.set_deferred("disabled", true)
		return
	# Activar solo en el frame de impacto
	punch_collision.set_deferred("disabled", sprite.frame != PUNCH_ACTIVE_FRAME)

func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "Punch":
		atacando = false
		punch_collision.set_deferred("disabled", true)
		sprite.play("Idle")
	if sprite.animation == "Jump":
		sprite.play("Idle")

func _on_hitbox_area_entered(area: Area2D) -> void:
	if not area.is_in_group("zombie_punch"):
		return
	call_deferred("recibir_danio")

func recibir_danio() -> void:
	hp -= 1
	print("Jugador HP: ", hp)
	if hp <= 0:
		print("Jugador muerto")
