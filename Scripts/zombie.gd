extends CharacterBody2D

enum State { IDLE, WALK, HIT, PUNCH, FALL, RECOVERY, DEAD }

@export var speed: float = 50.0
@export var detection_range: float = 200.0
@export var punch_range: float = 45.0
@export var punch_cooldown: float = 0.5
@export var idle_before_attack: float = 0.5

@onready var punch_area: Area2D = $Punch
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var punch_collision: CollisionShape2D = $Punch/CollisionShape2D
@onready var hitbox: Area2D = $Hitbox

var state: State = State.IDLE
var is_bloody: bool = false
var hit_count: int = 0
var player: Node2D = null
var punch_timer: float = 0.0
var can_punch: bool = true
var idle_timer: float = 0.0
var punch_offset_right: float = 30.0
var en_rango_ataque: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO

const PUNCH_ACTIVE_FRAME: int = 1

func _ready() -> void:
	punch_collision.set_deferred("disabled", true)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	hitbox.area_entered.connect(_on_hitbox_area_entered)

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	state = State.WALK
	_play_animation("Walk")

func _physics_process(delta: float) -> void:
	_actualizar_punch()

	match state:
		State.IDLE:    _handle_idle(delta)
		State.WALK:    _handle_walk()
		State.PUNCH, State.HIT, State.RECOVERY, State.DEAD:
			velocity = Vector2.ZERO
		State.FALL:
			if knockback_velocity.length() > 0:
				global_position += knockback_velocity * delta
				knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 200.0 * delta)
			else:
				velocity = Vector2.ZERO

	if not can_punch:
		punch_timer -= delta
		if punch_timer <= 0.0:
			can_punch = true

	move_and_slide()

func _actualizar_punch() -> void:
	if sprite.flip_h:
		punch_area.position.x = punch_offset_right
	else:
		punch_area.position.x = -punch_offset_right

# ──────────────────────────────────────────────
#  LOGICA DE ESTADOS
# ──────────────────────────────────────────────
func _handle_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	if player == null:
		return

	var dist = global_position.distance_to(player.global_position)

	if dist > detection_range:
		en_rango_ataque = false
		return
	
	if dist > punch_range * 2.0 and not en_rango_ataque:
		_enter_walk()
		return

	en_rango_ataque = true
	if can_punch:
		idle_timer += delta
		if idle_timer >= idle_before_attack:
			idle_timer = 0.0
			_enter_punch()

func _handle_walk() -> void:
	if player == null:
		velocity = Vector2.ZERO
		return

	var dist = global_position.distance_to(player.global_position)

	if dist > detection_range:
		velocity = Vector2.ZERO
		state = State.IDLE
		return

	if dist <= punch_range:
		velocity = Vector2.ZERO
		en_rango_ataque = true
		_enter_idle_cercano()
		return

	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed

	if abs(direction.x) > 0.3:
		sprite.flip_h = (direction.x > 0)

func _enter_idle_cercano() -> void:
	state = State.IDLE
	idle_timer = 0.0
	_play_animation("Idle" if not is_bloody else "IdleZ")

# ──────────────────────────────────────────────
#  TRANSICIONES
# ──────────────────────────────────────────────
func _enter_walk() -> void:
	state = State.WALK
	hitbox.set_deferred("monitoring", true)
	_play_animation("Walk" if not is_bloody else "WalkBlood")

func _enter_punch() -> void:
	state = State.PUNCH
	can_punch = false
	punch_timer = punch_cooldown
	_play_animation("Punch" if not is_bloody else "PunchBlood")

func _enter_hit() -> void:
	state = State.HIT
	punch_collision.set_deferred("disabled", true)
	_play_animation("Hit" if not is_bloody else "HitBlood")

func _enter_fall() -> void:
	state = State.FALL
	punch_collision.set_deferred("disabled", true)
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	_play_animation("Fall" if not is_bloody else "FallBlood")
	if player != null:
		var dir_x = sign(global_position.x - player.global_position.x)
		knockback_velocity = Vector2(dir_x * 150.0, 0.0)

func _enter_recovery() -> void:
	state = State.RECOVERY
	is_bloody = true
	hit_count = 0
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	_play_animation("Recovery")

# ──────────────────────────────────────────────
#  RECIBIR DAÑO
# ──────────────────────────────────────────────
func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.get_parent() == self:
		return
	if area.is_in_group("player_punch"):
		# Verificar si el jugador está transformado
		var damage = 1
		if player and player.is_z_form:
			damage = 2
		call_deferred("take_damage", damage)

func take_damage(damage: int = 1) -> void:
	if state == State.FALL or state == State.RECOVERY or state == State.DEAD:
		return
	hit_count += damage
	if hit_count >= 4:
		_enter_fall()
	else:
		_enter_hit()

# ──────────────────────────────────────────────
#  SEÑALES SPRITE
# ──────────────────────────────────────────────
func _on_animation_finished() -> void:
	match state:
		State.HIT:
			_enter_idle_cercano()
		State.PUNCH:
			punch_collision.set_deferred("disabled", true)
			_enter_walk()
		State.FALL:
			if not is_bloody:
				_enter_recovery()
			else:
				_die()
		State.RECOVERY:
			_enter_walk()
		State.IDLE:
			_play_animation("Idle" if not is_bloody else "IdleZ")

func _on_frame_changed() -> void:
	if state != State.PUNCH:
		if not punch_collision.disabled:
			punch_collision.set_deferred("disabled", true)
		return
	punch_collision.set_deferred("disabled", sprite.frame != PUNCH_ACTIVE_FRAME)

# ──────────────────────────────────────────────
#  MUERTE
# ──────────────────────────────────────────────
func _die() -> void:
	state = State.DEAD
	# Subir dos niveles para llegar al Floor1 que tiene el script
	var room = get_parent().get_parent()
	print("buscando room en: ", room.name if room else "null")
	if room and room.has_method("enemy_died"):
		print("llamando enemy_died")
		room.enemy_died()
	await get_tree().create_timer(0.4).timeout
	queue_free()

func _play_animation(anim_name: String) -> void:
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	else:
		push_warning("Zombie: animacion '%s' no encontrada." % anim_name)
