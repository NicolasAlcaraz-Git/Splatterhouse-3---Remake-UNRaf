extends CharacterBody2D

enum State { IDLE, WALK, HIT, PUNCH, FALL, RECOVERY, DEATH }

@export var speed: float = 40.0
@export var detection_range: float = 200.0
@export var punch_range: float = 45.0
@export var punch_cooldown: float = 1.8

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var punch_collision: CollisionShape2D = $Punch/CollisionShape2D
@onready var punch_area: Area2D = $Punch
@onready var hitbox: Area2D = $Hitbox

var state: State = State.IDLE
var hit_count: int = 0        # golpes en el ciclo actual (se resetea cada caida)
var fall_count: int = 0       # cuantas veces ha caido (0 a 3)
var player: Node2D = null
var punch_timer: float = 0.0
var can_punch: bool = true
var punch_offset_right: float = 30

const PUNCH_ACTIVE_FRAME: int = 3
const MAX_FALLS: int = 4  # muere a la 4ta caida

# Animaciones según cantidad de caidas
const ANIM_WALK     = ["Walk",      "Walk",      "WalkBlood",  "WalkBlood"]
const ANIM_PUNCH    = ["Punch",     "Punch",     "PunchBlood", "PunchBlood"]
const ANIM_HIT      = ["Hit",       "Hit",       "HitBlood",   "HitBlood"]
const ANIM_FALL     = ["Fall",      "Fall",      "FallBlood",  "FallBlood"]
const ANIM_RECOVERY = ["Recovery",  "RecoveryMid", "RecoveryBlood", "Death"]

func _ready() -> void:
	punch_collision.set_deferred("disabled", true)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	hitbox.area_entered.connect(_on_hitbox_area_entered)

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		
	sprite.flip_h = true

	state = State.WALK
	_play_animation(ANIM_WALK[fall_count])


func _physics_process(delta: float) -> void:
	_actualizar_punch()

	match state:
		State.IDLE:  _handle_idle()
		State.WALK:  _handle_walk()
		State.PUNCH, State.HIT, State.FALL, State.RECOVERY, State.DEATH:
			velocity = Vector2.ZERO

	if not can_punch:
		punch_timer -= delta
		if punch_timer <= 0.0:
			can_punch = true

	move_and_slide()


func _actualizar_punch() -> void:
	if sprite.flip_h:
		punch_area.position.x = -punch_offset_right
	else:
		punch_area.position.x = punch_offset_right


func _handle_idle() -> void:
	velocity = Vector2.ZERO
	if player == null:
		return
	var dist = global_position.distance_to(player.global_position)
	if dist <= punch_range and can_punch:
		_enter_punch()
	elif dist <= detection_range:
		_enter_walk()


func _handle_walk() -> void:
	if player == null:
		velocity = Vector2.ZERO
		return

	var dist = global_position.distance_to(player.global_position)

	if dist <= punch_range and can_punch:
		velocity = Vector2.ZERO
		_enter_punch()
		return

	if dist > detection_range:
		velocity = Vector2.ZERO
		state = State.IDLE
		return

	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	if direction.x != 0:
		sprite.flip_h = (direction.x < 0)

# ── TRANSICIONES ──────────────────────────────
func _enter_walk() -> void:
	state = State.WALK
	_play_animation(ANIM_WALK[fall_count])

func _enter_punch() -> void:
	state = State.PUNCH
	can_punch = false
	punch_timer = punch_cooldown
	_play_animation(ANIM_PUNCH[fall_count])

func _enter_hit() -> void:
	state = State.HIT
	punch_collision.set_deferred("disabled", true)
	_play_animation(ANIM_HIT[fall_count])

func _enter_fall() -> void:
	state = State.FALL
	punch_collision.set_deferred("disabled", true)
	_play_animation(ANIM_FALL[fall_count])

func _enter_recovery() -> void:
	state = State.RECOVERY
	hit_count = 0
	_play_animation(ANIM_RECOVERY[fall_count - 1])  # ← fall_count - 1

# ── RECIBIR DAÑO ──────────────────────────────
func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.get_parent() == self:
		return
	if area.is_in_group("player_punch"):
		call_deferred("take_damage")

func take_damage() -> void:
	if state == State.FALL or state == State.RECOVERY or state == State.DEATH:
		return
	hit_count += 1
	if hit_count >= 4:
		_enter_fall()
	else:
		_enter_hit()

# ── SEÑALES SPRITE ────────────────────────────
func _on_animation_finished() -> void:
	match state:
		State.HIT:
			_enter_walk()
		State.PUNCH:
			punch_collision.set_deferred("disabled", true)
			_enter_walk()
		State.FALL:
			fall_count += 1
			if fall_count >= MAX_FALLS:
				_die()
			else:
				_enter_recovery()
		State.RECOVERY:
			_enter_walk()

func _on_frame_changed() -> void:
	if state != State.PUNCH:
		if not punch_collision.disabled:
			punch_collision.set_deferred("disabled", true)
		return
	punch_collision.set_deferred("disabled", sprite.frame != PUNCH_ACTIVE_FRAME)

# ── MUERTE ────────────────────────────────────
func _die() -> void:
	state = State.DEATH
	_play_animation("Death")
	await get_tree().create_timer(5.0).timeout
	queue_free()

func _play_animation(anim_name: String) -> void:
	if anim_name == "":
		return
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	else:
		push_warning("Enemigo: animacion '%s' no encontrada." % anim_name)
