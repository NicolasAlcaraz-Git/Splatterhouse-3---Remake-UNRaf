extends Node2D
 
var blink_timer: float = 0.0
var press_label: Label
 
func _ready() -> void:
	var music = AudioStreamPlayer.new()
	music.stream = load("res://Assets/Sound/Title.mp3")
	music.autoplay = true
	add_child(music)
	
	var bg = TextureRect.new()
	bg.texture = load("res://Assets/Titles/Title.png")
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.size = Vector2(1280, 960)
	add_child(bg)
	
	# Press Start
	press_label = Label.new()
	press_label.add_theme_font_size_override("font_size", 32)
	press_label.add_theme_color_override("font_color", Color(1, 1, 1))
	press_label.position = Vector2(1280 * 0.28, 960 * 0.72)
	add_child(press_label)
	
	# Resetear GameData para nueva partida
	GameData.spawn_point = "SpawnDefault"
	GameData.tiempo_restante = 360.0
	GameData.tiempo_agotado = false
	GameData.player_hp = 10
	GameData.player_lives = 3
	GameData.player_pow = 0.0
	GameData.player_is_z_form = false
	GameData.boss_derrotado = false
 
func _process(delta: float) -> void:
	# Parpadeo del texto
	blink_timer += delta
	if blink_timer >= 0.6:
		blink_timer = 0.0
		press_label.visible = not press_label.visible
	
	# Cualquier tecla/botón inicia el juego con fade
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("Punch"):
		_iniciar_juego()
 
func _iniciar_juego() -> void:
	# Fade a negro
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.size = Vector2(1280, 960)
	add_child(fade)
	
	var tween = create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.8)
	await tween.finished
	get_tree().change_scene_to_file("res://Scenes/Stage1/room1.tscn")
