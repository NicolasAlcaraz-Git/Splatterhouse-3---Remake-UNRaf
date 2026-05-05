extends Area2D

enum State { MOVE }
var state: State

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	state = State.MOVE
	sprite.play("Move")

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_body"):
		var sfx = AudioStreamPlayer.new()
		sfx.stream = load("res://Assets/Sound/Power-Up.mp3")
		get_tree().root.add_child(sfx)
		sfx.play()
		sfx.finished.connect(sfx.queue_free)
		var player = area.get_parent()  # el jugador es el padre del Hitbox
		var new_hp = min(player.hp + 2, 10)
		player.hp = new_hp
		GameData.player_hp = new_hp
		queue_free()
