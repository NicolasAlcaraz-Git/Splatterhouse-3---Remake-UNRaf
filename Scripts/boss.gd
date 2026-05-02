extends CharacterBody2D

enum State {
	INTRO,       # Eating
	STALK,       # camina en rectangulo alrededor del jugador
	ATTACK,      # Punch o Lick
	HIT,         # recibe daño
	DEFENSE,     # se defiende
	FALL,        # cae
	RECOVERY,    # se levanta
	HEAD,        # cinematica cabeza (entre fase 1 y 2)
	CRAZY,       # animacion frenética final
	DEATH,       # muere
	COOLDOWN     # espera después de golpear al jugador
}

# ──────────────────────────────────────────────
#  PARAMETROS AJUSTABLES
# ──────────────────────────────────────────────
@export var speed: float = 120.0
@export var stalk_radius_x: float = 80.0  # distancia horizontal
@export var stalk_radius_y: float = 20.0   # distancia vertical
@export var attack_range: float = 50.0
@export var stalk_time: float = 3.0
@export var defense_chance: float = 0.50
@export var defense_duration: float = 5.0
@export var cooldown_after_hit: float = 5.0
@export var hits_to_interrupt: int = 3  # golpes antes de volver al acecho (2-4)

# ──────────────────────────────────────────────
#  NODOS
# ──────────────────────────────────────────────
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var punch_collision: CollisionShape2D = $Punch/CollisionShape2D
@onready var punch_area: Area2D = $Punch
@onready var lick_collision: CollisionShape2D = $Lick/CollisionShape2D
@onready var lick_area: Area2D = $Lick
@onready var hitbox: Area2D = $Hitbox

# ──────────────────────────────────────────────
#  VARIABLES
# ──────────────────────────────────────────────
var state: State = State.INTRO
var is_bloody: bool = false
var hit_count: int = 0          # golpes recibidos en el ciclo actual
var total_hits_phase1: int = 0  # acumulado fase 1 (max 16)
var total_hits_phase2: int = 0  # acumulado fase 2 (max 8)
var hits_this_encounter: int = 0  # golpes recibidos en este acercamiento
var player: Node2D = null
var stalk_timer: float = 0.0
var defense_timer: float = 0.0
var cooldown_timer: float = 0.0
var stalk_direction: float = 1.0  # 1 o -1, sentido de circulacion
var punch_offset_right: float = - 20  # ajustá según tu sprite
var lick_offset_right: float = -50.0  # ajustá este valor según tu sprite
var is_invulnerable: bool = false

const PUNCH_ACTIVE_FRAME: int = 1
const LICK_ACTIVE_FRAME: int = 3

func _ready() -> void:
	punch_collision.set_deferred("disabled", true)
	lick_collision.set_deferred("disabled", true)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	punch_area.area_entered.connect(_on_punch_area_entered)   # ← esta
	lick_area.area_entered.connect(_on_lick_area_entered)     # ← y esta

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	# Dirección de acecho aleatoria al inicio
	stalk_direction = 1.0 if randf() > 0.5 else -1.0

	_play_animation("Eating")


func _physics_process(delta: float) -> void:
	_actualizar_hitboxes()

	match state:
		State.INTRO, State.FALL, State.RECOVERY, State.HEAD, State.CRAZY, State.DEATH:
			velocity = Vector2.ZERO
		State.STALK:
			_handle_stalk(delta)
		State.ATTACK, State.HIT, State.DEFENSE:
			velocity = Vector2.ZERO
		State.COOLDOWN:
			_handle_cooldown(delta)

	move_and_slide()
# ──────────────────────────────────────────────
#  HITBOXES
# ──────────────────────────────────────────────
func _actualizar_hitboxes() -> void:
	if sprite.flip_h:
		punch_area.position.x = -punch_offset_right
		lick_area.position.x = -lick_offset_right
	else:
		punch_area.position.x = punch_offset_right
		lick_area.position.x = lick_offset_right

# ──────────────────────────────────────────────
#  ACECHO — camina en rectangulo alrededor del jugador
# ──────────────────────────────────────────────
func _handle_stalk(delta: float) -> void:
	if player == null:
		return

	stalk_timer -= delta

	if stalk_timer <= 0.0:
		_enter_attack()
		return

	var diff = global_position - player.global_position

	# Radio elíptico — más ancho en X que en Y
	var ellipse_dist = Vector2(diff.x / stalk_radius_x, diff.y / stalk_radius_y).length()
	var to_player_dir = -diff.normalized()
	var tangent = Vector2(-diff.y / stalk_radius_y, diff.x / stalk_radius_x).normalized() * stalk_direction

	if ellipse_dist > 1.1:
		velocity = to_player_dir * speed
	elif ellipse_dist < 0.9:
		velocity = -to_player_dir * speed
	else:
		velocity = tangent * speed

	if is_on_wall():
		stalk_direction *= -1

	sprite.flip_h = (player.global_position.x > global_position.x)

# ──────────────────────────────────────────────
#  COOLDOWN después de golpear al jugador
# ──────────────────────────────────────────────
func _handle_cooldown(delta: float) -> void:
	cooldown_timer -= delta
	# Alejarse del jugador durante el cooldown
	if player != null:
		var away = (global_position - player.global_position).normalized()
		velocity = away * speed
		sprite.flip_h = (player.global_position.x > global_position.x)
	if cooldown_timer <= 0.0:
		_enter_stalk()

# ──────────────────────────────────────────────
#  TRANSICIONES
# ──────────────────────────────────────────────
func _enter_stalk() -> void:
	state = State.STALK
	stalk_timer = stalk_time
	hits_this_encounter = 0
	# Cambiar sentido de circulación aleatoriamente
	stalk_direction = 1.0 if randf() > 0.5 else -1.0
	_play_animation("Walk" if not is_bloody else "WalkBlood")
	# Desactivar invulnerabilidad después de 1.5 segundos
	await get_tree().create_timer(1.5).timeout
	is_invulnerable = false

func _enter_attack() -> void:
	state = State.ATTACK
	# Elegir ataque: en fase 2 puede usar Lick
	if is_bloody and randf() > 0.5:
		_play_animation("Lick")
	else:
		_play_animation("Punch" if not is_bloody else "PunchBlood")

func _enter_hit() -> void:
	state = State.HIT
	punch_collision.set_deferred("disabled", true)
	lick_collision.set_deferred("disabled", true)
	_play_animation("Hit" if not is_bloody else "HitBlood")

func _enter_defense() -> void:
	state = State.DEFENSE
	defense_timer = defense_duration
	_play_animation("Defense" if not is_bloody else "DefenseBlood")

func _enter_fall() -> void:
	state = State.FALL
	punch_collision.set_deferred("disabled", true)
	lick_collision.set_deferred("disabled", true)
	_play_animation("Fall" if not is_bloody else "FallBlood")

func _enter_recovery() -> void:
	state = State.RECOVERY
	hit_count = 0
	hits_this_encounter = 0
	_play_animation("Recovery" if not is_bloody else "RecoveryBlood")

func _enter_cooldown() -> void:
	state = State.COOLDOWN
	cooldown_timer = cooldown_after_hit
	_play_animation("Walk" if not is_bloody else "WalkBlood")

# ──────────────────────────────────────────────
#  RECIBIR DAÑO
# ──────────────────────────────────────────────
func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.get_parent() == self:
		return
	if area.is_in_group("player_punch"):
		call_deferred("take_damage")

func take_damage() -> void:
	if is_invulnerable:
		return
	if state == State.FALL or state == State.RECOVERY or state == State.DEATH or state == State.INTRO or state == State.HEAD or state == State.CRAZY:
		return
	if state == State.FALL or state == State.RECOVERY or state == State.DEATH or state == State.INTRO or state == State.HEAD or state == State.CRAZY:
		return

	# Chance de defensa
	if randf() < defense_chance:
		_enter_defense()
		return

	# Acumular golpes
	if not is_bloody:
		total_hits_phase1 += 1
	else:
		total_hits_phase2 += 1

	hits_this_encounter += 1

	# Verificar si cae
	if not is_bloody and total_hits_phase1 >= 16:
		_enter_fall()
		return
	if is_bloody and total_hits_phase2 >= 8:
		_enter_fall()
		return

	# Recibe el golpe y vuelve al acecho después de 2-4 golpes
	_enter_hit()
	if hits_this_encounter >= hits_to_interrupt:
		# Después de Hit volverá al acecho (lo maneja _on_animation_finished)
		hits_this_encounter = 0

# ──────────────────────────────────────────────
#  GOLPEAR AL JUGADOR
# ──────────────────────────────────────────────
func _on_punch_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if player and player.has_method("recibir_golpe_jefe"):
			player.recibir_golpe_jefe()
		_enter_cooldown()

func _on_lick_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if player and player.has_method("recibir_golpe_jefe"):
			player.recibir_golpe_jefe()
		_enter_cooldown()

# ──────────────────────────────────────────────
#  SEÑALES SPRITE
# ──────────────────────────────────────────────
func _on_animation_finished() -> void:
	match state:
		State.INTRO:
			_enter_stalk()

		State.HIT:
			# Si recibió suficientes golpes, vuelve al acecho
			_enter_stalk()

		State.ATTACK:
			punch_collision.set_deferred("disabled", true)
			lick_collision.set_deferred("disabled", true)
			# Si no golpeó al jugador, vuelve al acecho
			if state != State.COOLDOWN:
				_enter_stalk()

		State.DEFENSE:
			_enter_stalk()

		State.FALL:
			if not is_bloody:
				# Primera caída → cinematica Head → segunda fase
				state = State.HEAD
				_play_animation("Head")
			else:
				# Segunda o tercera caída
				if total_hits_phase2 >= 16:
					# Muerto
					state = State.CRAZY
					_play_animation("Crazy")
				else:
					_enter_recovery()

		State.HEAD:
			is_bloody = true
			hit_count = 0
			total_hits_phase2 = 0
			_enter_stalk()

		State.RECOVERY:
			_enter_stalk()

		State.CRAZY:
			state = State.DEATH
			_play_animation("Death")

		State.DEATH:
			await get_tree().create_timer(0.5).timeout
			queue_free()


func _on_frame_changed() -> void:
	# Punch
	if state == State.ATTACK and sprite.animation in ["Punch", "PunchBlood"]:
		punch_collision.set_deferred("disabled", sprite.frame != PUNCH_ACTIVE_FRAME)
	else:
		if not punch_collision.disabled:
			punch_collision.set_deferred("disabled", true)

	# Lick
	if state == State.ATTACK and sprite.animation == "Lick":
		lick_collision.set_deferred("disabled", sprite.frame != LICK_ACTIVE_FRAME)
	else:
		if not lick_collision.disabled:
			lick_collision.set_deferred("disabled", true)

# ──────────────────────────────────────────────
#  MUERTE
# ──────────────────────────────────────────────
func _die() -> void:
	state = State.CRAZY
	_play_animation("Crazy")

# ──────────────────────────────────────────────
#  HELPER
# ──────────────────────────────────────────────
func _play_animation(anim_name: String) -> void:
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	else:
		push_warning("Jefe: animacion '%s' no encontrada." % anim_name)
