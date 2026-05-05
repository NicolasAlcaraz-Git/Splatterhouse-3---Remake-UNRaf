extends Area2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_body"):
		var sfx = AudioStreamPlayer.new()
		sfx.stream = load("res://Assets/Sound/Power-Up.mp3")
		get_tree().root.add_child(sfx)
		sfx.play()
		sfx.finished.connect(sfx.queue_free)
		GameData.player_pow = min(GameData.player_pow + 34, 100.0)
		queue_free()
