extends CharacterBody2D

var speed: float = 120
var atacando: bool = false
var hp: int = 5
var lives: int = 3
var is_z_form: bool = false
var combo_count: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW: float = 0.6

@onready var punch_collision: CollisionShape2D = $Punch/CollisionShape2D
@onready var punch_area: Area2D = $Punch
@onready var hitbox: Area2D = $Hitbox
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var punch_offset_right: float = 25.0
var mirando_derecha: bool = true
var caido: bool = false
var muerto: bool = false
var invulnerable: bool = false
var caida_por_jefe: bool = false

# Knockback al ser derribado
var knockback_velocity: Vector2 = Vector2.ZERO

const PUNCH_ACTIVE_FRAME: int = 1
# Golpes para derribar enemigo — normal: 4, transformado: 2
const GOLPES_NORMALES: int = 4
const GOLPES_Z: int = 2

func _ready() -> void:
	punch_collision.set_deferred("disabled", true)
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)


func _process(delta: float) -> void:
	if muerto or caido:
		return

	if combo_timer > 0:
		combo_timer -= delta
	else:
		combo_count = 0

	if Input.is_action_pressed("ui_right"):
		sprite.flip_h = false
		sprite.offset.x = 0
		mirando_derecha = true
	elif Input.is_action_pressed("ui_left"):
		sprite.flip_h = true
		sprite.offset.x = -30
		mirando_derecha = false

	_actualizar_punch()

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
		sprite.play("WalkZ" if is_z_form else "Walk")
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		sprite.play("IdleZ" if is_z_form else "Idle")

	if Input.is_action_just_pressed("Punch"):
		ejecutar_golpe()

	if Input.is_action_just_pressed("Transform"):
		intentar_transformar()


func _physics_process(_delta: float) -> void:
	# Knockback al ser derribado
	if knockback_velocity.length() > 10:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 10 * _delta)
		move_and_slide()


func _actualizar_punch() -> void:
	punch_area.position.x = punch_offset_right if mirando_derecha else -punch_offset_right

# ──────────────────────────────────────────────
#  COMBO
# ──────────────────────────────────────────────
func ejecutar_golpe() -> void:
	combo_count += 1
	combo_timer = COMBO_WINDOW
	atacando = true

	var anim = ""
	if is_z_form:
		match combo_count:
			1: anim = "PunchZ"
			2: anim = "PunchZ2"
			3:
				anim = "PunchZ3"
				combo_count = 0
			_:
				anim = "PunchZ"
				combo_count = 1
	else:
		match combo_count:
			1, 2: anim = "Punch"
			3: anim = "Punch2"
			4:
				anim = "Punch3"
				combo_count = 0
			_:
				anim = "Punch"
				combo_count = 1

	sprite.play(anim)

# ──────────────────────────────────────────────
#  TRANSFORMACION
# ──────────────────────────────────────────────
func intentar_transformar() -> void:
	if atacando or caido or muerto:
		return
	if is_z_form:
		_destransformar()
	else:
		_transformar()

func _transformar() -> void:
	atacando = true
	sprite.play("Transform")

func _destransformar() -> void:
	atacando = true
	is_z_form = false
	sprite.play("Destransform")

func golpes_para_derribar() -> int:
	return 2 if is_z_form else 1  # daño por golpe, no total

# ──────────────────────────────────────────────
#  RECIBIR DAÑO
# ──────────────────────────────────────────────
func _on_hitbox_area_entered(area: Area2D) -> void:
	if not area.is_in_group("zombie_punch"):
		return
	call_deferred("recibir_danio")

func recibir_danio() -> void:
	if caido or muerto or invulnerable:
		return
	hp -= 1
	atacando = false
	punch_collision.set_deferred("disabled", true)
	combo_count = 0

	if hp <= 0:
		_entrar_caida()
	else:
		sprite.play("HitZ" if is_z_form else "Hit")
		atacando = true

func recibir_derribo(atacante_pos: Vector2) -> void:
	if caido or muerto or invulnerable:
		return
	atacando = false
	punch_collision.set_deferred("disabled", true)
	combo_count = 0
	# Empujar en dirección contraria al atacante
	var dir_x = sign(global_position.x - atacante_pos.x)
	knockback_velocity = Vector2(dir_x * 80.0, 0.0)
	_entrar_caida_sin_vida()

func recibir_golpe_jefe() -> void:
	if caido or muerto or invulnerable:
		return
	atacando = false
	punch_collision.set_deferred("disabled", true)
	combo_count = 0
	caida_por_jefe = true
	hp -= 2
	knockback_velocity = Vector2(-80.0 if mirando_derecha else 80.0, 0.0)
	_entrar_caida_sin_vida()

# ──────────────────────────────────────────────
#  CAIDA Y MUERTE
# ──────────────────────────────────────────────
func _entrar_caida() -> void:
	caido = true
	invulnerable = true
	atacando = false
	punch_collision.set_deferred("disabled", true)
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	# Knockback alejándose del centro de la pantalla
	knockback_velocity = Vector2(-80.0 if mirando_derecha else 80.0, 0.0)
	sprite.play("FallZ" if is_z_form else "Fall")
	
func _entrar_caida_sin_vida() -> void:
	caido = true
	invulnerable = true
	atacando = false
	punch_collision.set_deferred("disabled", true)
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	sprite.play("FallZ" if is_z_form else "Fall")

func _entrar_recuperacion() -> void:
	hp = 5
	caido = false
	knockback_velocity = Vector2.ZERO
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	sprite.play("RecoveryZ" if is_z_form else "Recovery")
	atacando = true

func _entrar_muerte() -> void:
	muerto = true
	caido = false
	knockback_velocity = Vector2.ZERO
	sprite.play("DeathZ" if is_z_form else "Death")

# ──────────────────────────────────────────────
#  SEÑALES SPRITE
# ──────────────────────────────────────────────
func _on_animation_finished() -> void:
	var anim = sprite.animation

	if anim in ["Punch", "Punch2", "Punch3", "PunchZ", "PunchZ2", "PunchZ3"]:
		atacando = false
		punch_collision.set_deferred("disabled", true)
		sprite.play("IdleZ" if is_z_form else "Idle")

	elif anim in ["Hit", "HitZ"]:
		atacando = false
		sprite.play("IdleZ" if is_z_form else "Idle")

	elif anim in ["Fall", "FallZ"]:
		if caida_por_jefe:
			caida_por_jefe = false
			if hp <= 0:
				lives -= 1
				if lives <= 0:
					_entrar_muerte()
				else:
					hp = 5
					_entrar_recuperacion()
			else:
				_entrar_recuperacion()  # se levanta sin perder vida
		elif hp <= 0:
			lives -= 1
			if lives <= 0:
				_entrar_muerte()
			else:
				hp = 5
				_entrar_recuperacion()
		else:
			_entrar_recuperacion()

	elif anim in ["Recovery", "RecoveryZ"]:
		atacando = false
		invulnerable = false
		hitbox.set_deferred("monitoring", true)
		hitbox.set_deferred("monitorable", true)
		sprite.play("IdleZ" if is_z_form else "Idle")

	elif anim == "Transform":
		is_z_form = true
		atacando = false
		sprite.play("IdleZ")

	elif anim == "Destransform":
		atacando = false
		sprite.play("Idle")

	elif anim in ["Death", "DeathZ"]:
		pass  # acá después: game over

# ──────────────────────────────────────────────
#  FRAME CHANGED
# ──────────────────────────────────────────────
func _on_frame_changed() -> void:
	var anim = sprite.animation
	if anim in ["Punch", "Punch2", "Punch3", "PunchZ", "PunchZ2", "PunchZ3"]:
		punch_collision.set_deferred("disabled", sprite.frame != PUNCH_ACTIVE_FRAME)
	else:
		if not punch_collision.disabled:
			punch_collision.set_deferred("disabled", true)
