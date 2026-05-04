extends CharacterBody2D

enum State {
	INTRO, STALK, ATTACK, HIT, DEFENSE,
	FALL, RECOVERY, HEAD, CRAZY, DEATH, COOLDOWN
}

@export var speed: float = 120.0
@export var stalk_radius_x: float = 80.0
@export var stalk_radius_y: float = 20.0
@export var stalk_time: float = 3.0
@export var defense_chance: float = 0.50
@export var cooldown_after_hit: float = 2.0
@export var hits_to_interrupt: int = 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var punch_collision: CollisionShape2D = $Punch/CollisionShape2D
@onready var punch_area: Area2D = $Punch
@onready var lick_collision: CollisionShape2D = $Lick/CollisionShape2D
@onready var lick_area: Area2D = $Lick
@onready var hitbox: Area2D = $Hitbox

var state: State = State.INTRO
var is_bloody: bool = false
var total_hits_phase1: int = 0
var total_hits_phase2: int = 0
var hits_this_encounter: int = 0
var golpes_sin_escapar: int = 0
var player: Node2D = null
var stalk_timer: float = 0.0
var cooldown_timer: float = 0.0
var stalk_direction: float = 1.0
var punch_offset_right: float = -20.0
var lick_offset_right: float = -50.0
var is_invulnerable: bool = false
var going_to_attack: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO

const PUNCH_ACTIVE_FRAME: int = 1
const LICK_ACTIVE_FRAME: int = 3
const MAX_HITS_PHASE1: int = 32
const MAX_HITS_PHASE2: int = 16
const MAX_GOLPES_SIN_ESCAPAR: int = 2

func _ready() -> void:
	punch_collision.set_deferred("disabled", true)
	lick_collision.set_deferred("disabled", true)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	punch_area.area_entered.connect(_on_punch_area_entered)
	lick_area.area_entered.connect(_on_lick_area_entered)

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

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

	if knockback_velocity.length() > 0:
		global_position += knockback_velocity * delta
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 300.0 * delta)

	move_and_slide()


func _actualizar_hitboxes() -> void:
	if sprite.flip_h:
		punch_area.position.x = -punch_offset_right
		lick_area.position.x = -lick_offset_right
	else:
		punch_area.position.x = punch_offset_right
		lick_area.position.x = lick_offset_right


func _handle_stalk(delta: float) -> void:
	if player == null:
		return

	stalk_timer -= delta
	var diff = global_position - player.global_position
	var dist = diff.length()

	# Cuando el timer llega a 0, ir directo al jugador
	if stalk_timer <= 0.0 or going_to_attack:
		going_to_attack = true
		if dist <= 60.0:
			going_to_attack = false
			_enter_attack()
			return
		velocity = -diff.normalized() * speed
		if abs(velocity.x) > 10.0:
			sprite.flip_h = (player.global_position.x > global_position.x)
		return

	# Circulación elíptica normal
	var ellipse_dist = Vector2(diff.x / stalk_radius_x, diff.y / stalk_radius_y).length()
	var tangent = Vector2(-diff.y / stalk_radius_y, diff.x / stalk_radius_x).normalized() * stalk_direction

	if ellipse_dist > 1.1:
		velocity = -diff.normalized() * speed
	elif ellipse_dist < 0.9:
		velocity = diff.normalized() * speed
	else:
		velocity = tangent * speed

	if is_on_wall():
		stalk_direction *= -1

	if abs(velocity.x) > 10.0:
		sprite.flip_h = (player.global_position.x > global_position.x)


func _handle_cooldown(delta: float) -> void:
	cooldown_timer -= delta
	if player != null:
		var away = (global_position - player.global_position).normalized()
		velocity = away * speed
		if abs(velocity.x) > 10.0:
			sprite.flip_h = (player.global_position.x > global_position.x)
	if cooldown_timer <= 0.0:
		_enter_stalk()


# ──────────────────────────────────────────────
#  TRANSICIONES
# ──────────────────────────────────────────────
func _enter_stalk() -> void:
	state = State.STALK
	going_to_attack = false
	golpes_sin_escapar = 0
	stalk_timer = stalk_time
	hits_this_encounter = 0
	stalk_direction = 1.0 if randf() > 0.5 else -1.0
	is_invulnerable = true
	_play_animation("Walk" if not is_bloody else "WalkBlood")
	await get_tree().create_timer(0.2).timeout
	is_invulnerable = false

func _enter_attack() -> void:
	state = State.ATTACK
	golpes_sin_escapar = 0
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
	is_invulnerable = true
	_play_animation("Defense" if not is_bloody else "DefenseBlood")

func _enter_fall() -> void:
	state = State.FALL
	golpes_sin_escapar = 0
	punch_collision.set_deferred("disabled", true)
	lick_collision.set_deferred("disabled", true)
	_play_animation("Fall" if not is_bloody else "FallBlood")

func _enter_recovery() -> void:
	state = State.RECOVERY
	hits_this_encounter = 0
	_play_animation("Recovery" if not is_bloody else "RecoveryBlood")

func _enter_cooldown() -> void:
	state = State.COOLDOWN
	golpes_sin_escapar = 0
	cooldown_timer = cooldown_after_hit
	_play_animation("Walk" if not is_bloody else "WalkBlood")

func _forzar_escape() -> void:
	if state == State.FALL or state == State.DEATH:
		return
	# Si el jugador está cerca, contraatacar directamente
	var dist = global_position.distance_to(player.global_position) if player else 999.0
	if dist <= 80.0:
		golpes_sin_escapar = 0
		_enter_attack()
		return
	# Si está lejos, escapar
	is_invulnerable = true
	golpes_sin_escapar = 0
	var escape_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-0.5, 0.5)).normalized()
	state = State.COOLDOWN
	cooldown_timer = 1.5
	velocity = escape_dir * speed * 2.0
	_play_animation("Walk" if not is_bloody else "WalkBlood")
	await get_tree().create_timer(0.8).timeout
	is_invulnerable = false


# ──────────────────────────────────────────────
#  RECIBIR DAÑO
# ──────────────────────────────────────────────
func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.get_parent() == self:
		return
	if area.is_in_group("player_punch"):
		var damage = 1
		if player and player.has_method("golpes_para_derribar"):
			damage = player.golpes_para_derribar()
		call_deferred("take_damage", damage)

func take_damage(damage: int = 1) -> void:
	if is_invulnerable:
		return
	if state in [State.FALL, State.RECOVERY, State.DEATH, State.INTRO, State.HEAD, State.CRAZY, State.DEFENSE]:
		return

	# Chance de defensa — antes de acumular golpes
	if randf() < defense_chance:
		_enter_defense()
		return

	# Knockback
	if player != null:
		var dir_x = sign(global_position.x - player.global_position.x)
		knockback_velocity = Vector2(dir_x * 80.0, 0.0)

	# Acumular golpes según fase
	if not is_bloody:
		total_hits_phase1 += damage
	else:
		total_hits_phase2 += damage

	hits_this_encounter += 1
	golpes_sin_escapar += 1

	# Verificar caída
	if not is_bloody and total_hits_phase1 >= MAX_HITS_PHASE1:
		_enter_fall()
		return
	if is_bloody and total_hits_phase2 >= MAX_HITS_PHASE2:
		_enter_fall()
		return

	# Si recibió demasiados golpes seguidos, escapar
	if golpes_sin_escapar >= MAX_GOLPES_SIN_ESCAPAR:
		call_deferred("_forzar_escape")
		return

	_enter_hit()
	if hits_this_encounter >= hits_to_interrupt:
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
			var dist = global_position.distance_to(player.global_position) if player else 999.0
			if dist <= 60.0:
				_enter_attack()
			else:
				_enter_stalk()

		State.ATTACK:
			punch_collision.set_deferred("disabled", true)
			lick_collision.set_deferred("disabled", true)
			if state != State.COOLDOWN:
				_enter_stalk()

		State.DEFENSE:
			is_invulnerable = false
			_enter_stalk()

		State.FALL:
			if not is_bloody:
				state = State.HEAD
				_play_animation("Head")
			else:
				if total_hits_phase2 >= MAX_HITS_PHASE2 * 2:
					state = State.CRAZY
					_play_animation("Crazy")
				else:
					_enter_recovery()

		State.HEAD:
			is_bloody = true
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
	if state == State.ATTACK and sprite.animation in ["Punch", "PunchBlood"]:
		punch_collision.set_deferred("disabled", sprite.frame != PUNCH_ACTIVE_FRAME)
	else:
		if not punch_collision.disabled:
			punch_collision.set_deferred("disabled", true)

	if state == State.ATTACK and sprite.animation == "Lick":
		lick_collision.set_deferred("disabled", sprite.frame != LICK_ACTIVE_FRAME)
	else:
		if not lick_collision.disabled:
			lick_collision.set_deferred("disabled", true)


func _play_animation(anim_name: String) -> void:
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	else:
		push_warning("Jefe: animacion '%s' no encontrada." % anim_name)
