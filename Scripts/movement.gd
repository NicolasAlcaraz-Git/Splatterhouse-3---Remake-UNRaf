extends CharacterBody2D

var speed: float = 120
var atacando: bool = false
var hp: int = 10
var lives: int = 3
var is_z_form: bool = false
var combo_count: int = 0
var combo_timer: float = 0.0
var energia: float = 0.0
const POW_DRAIN: float = 3.0
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
var spawn_aplicado: bool = false
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
	energia = GameData.player_pow
	
	# Restaurar estado guardado
	hp = GameData.player_hp
	lives = GameData.player_lives
	is_z_form = GameData.player_is_z_form

	# Spawn point
	if GameData.spawn_point != "SpawnDefault":
		print("spawn_point vale: ", GameData.spawn_point)
		var spawn = _buscar_nodo(get_tree().current_scene, GameData.spawn_point)
		if spawn:
			print("encontrado: ", spawn.name, " pos: ", spawn.global_position)
			global_position = spawn.global_position
		else:
			print("NO encontrado")
			
	# Límites de cámara automáticos
	var cam: Camera2D = $Camera2D
	var room_sprite = _buscar_sprite_fondo(get_tree().current_scene)
	if room_sprite and room_sprite.texture:
		var tex_size = room_sprite.texture.get_size() * room_sprite.scale
		var pos = room_sprite.global_position
		# El sprite en Godot se centra en su posición por defecto
		cam.limit_left = int(pos.x - tex_size.x / 2)
		cam.limit_right = int(pos.x + tex_size.x / 2)
		cam.limit_top = int(pos.y - tex_size.y / 2)
		cam.limit_bottom = int(pos.y + tex_size.y / 2)
		
func _play_sfx(path: String) -> void:
	var sfx = AudioStreamPlayer.new()
	sfx.stream = load(path)
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

func _buscar_nodo(nodo: Node, nombre: String) -> Node:
	if nodo.name == nombre:
		return nodo
	for child in nodo.get_children():
		var resultado = _buscar_nodo(child, nombre)
		if resultado:
			return resultado
	return null
	

func _buscar_sprite_fondo(nodo: Node) -> Sprite2D:
	for child in nodo.get_children():
		if child is Sprite2D:
			return child
		var resultado = _buscar_sprite_fondo(child)
		if resultado:
			return resultado
	return null

func _process(delta: float) -> void:
	energia = GameData.player_pow
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
	if is_z_form:
		energia -= POW_DRAIN * delta
		energia = max(energia, 0.0)
		GameData.player_pow = energia
		if energia <= 0.0:
			_destransformar()


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
		return  # no podés destransformarte manualmente
	else:
		if energia >= 100.0:  # solo si está llena
			_transformar()

func _transformar() -> void:
	_play_sfx("res://Assets/Sound/Transform.mp3")
	atacando = true
	is_z_form = true
	GameData.player_is_z_form = true
	sprite.play("Transform")

func _destransformar() -> void:
	_play_sfx("res://Assets/Sound/Transform.mp3")
	atacando = true
	is_z_form = false
	energia = 0.0
	GameData.player_pow = 0.0
	GameData.player_is_z_form = false
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
	GameData.player_hp = hp
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
	hp -= 1
	GameData.player_hp = hp
	var dir_x = sign(global_position.x - atacante_pos.x)
	knockback_velocity = Vector2(dir_x * 80.0, 0.0)
	if hp <= 0:
		_entrar_caida()  # esta sí descuenta vida al levantarse
	else:
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
	_play_sfx("res://Assets/Sound/Player.mp3")
	caido = true
	invulnerable = true
	atacando = false
	punch_collision.set_deferred("disabled", true)
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	knockback_velocity = Vector2(-80.0 if mirando_derecha else 80.0, 0.0)
	# Pre-guardar HP restaurado por si cambia escena durante la animación
	if hp <= 0:
		var lives_after = lives - 1
		if lives_after > 0:
			GameData.player_hp = 10
			GameData.player_lives = lives_after
	sprite.play("FallZ" if is_z_form else "Fall")
	
func _entrar_caida_sin_vida() -> void:
	_play_sfx("res://Assets/Sound/Player.mp3")
	print("entrar_caida_sin_vida llamado")
	caido = true
	invulnerable = true
	atacando = false
	punch_collision.set_deferred("disabled", true)
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	sprite.play("FallZ" if is_z_form else "Fall")

func _entrar_recuperacion() -> void:
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
	# Esperar que termine la animación y mostrar game over
	await sprite.animation_finished
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://Scenes/ending.tscn")

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
				GameData.player_lives = lives
				if lives <= 0:
					_entrar_muerte()
				else:
					hp = 10
					GameData.player_lives = lives
					_entrar_recuperacion()
			else:
				_entrar_recuperacion()  # se levanta sin perder vida
		elif hp <= 0:
			lives -= 1
			GameData.player_lives = lives
			if lives <= 0:
				_entrar_muerte()
			else:
				hp = 10
				GameData.player_lives = lives
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
