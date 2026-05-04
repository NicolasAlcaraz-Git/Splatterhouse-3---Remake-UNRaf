# portal1.gd
extends Area2D

@export var next_scene_path: String
@export var spawn_point_name: String = "SpawnDefault"
@export var requires_enemies_dead: bool = true

@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if requires_enemies_dead:
		collision.set_deferred("disabled", true)
		monitoring = false

func activate() -> void:
	collision.set_deferred("disabled", false)
	monitoring = true

func _on_body_entered(body):
	if body.name == "Player":
		GameData.spawn_point = spawn_point_name
		GameData.spawn_pendiente = true  # ← marcar que hay spawn pendiente
		print("seteando spawn: ", spawn_point_name)
		get_tree().call_deferred("change_scene_to_file", next_scene_path)
