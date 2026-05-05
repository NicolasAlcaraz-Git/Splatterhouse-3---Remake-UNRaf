extends Node2D
 
var font: FontFile
 
func _ready() -> void:
	GameData.play_music("res://Assets/Sound/Jennifer.mp3")
	font = load("res://Assets/Items/PressStart2P.ttf")
	_mostrar_ending()
 
func _mostrar_ending() -> void:
	if not GameData.boss_derrotado:
		_mostrar_game_over()
		return
	
	var img_path: String
	if not GameData.tiempo_agotado:
		img_path = "res://Assets/Titles/Good.png"
	else:
		img_path = "res://Assets/Titles/Bad.png"
	
	var bg = TextureRect.new()
	bg.texture = load(img_path)
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.size = Vector2(1280, 960)
	add_child(bg)
	
	# Fade de entrada desde negro
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 1)  # empieza opaco
	fade.size = Vector2(1280, 960)
	add_child(fade)
	var tween = create_tween()
	tween.tween_property(fade, "color:a", 0.0, 2)  # se vuelve transparente
	await tween.finished
	
	# Mostrar la imagen unos segundos antes de pasar a game over
	await get_tree().create_timer(4.0).timeout
	_mostrar_game_over()
 
func _mostrar_game_over() -> void:
	# Fade a negro
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.size = Vector2(1280, 960)
	add_child(fade)
	var tween = create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.8)
	await tween.finished
	
	# Limpiar pantalla y mostrar Game Over
	for child in get_children():
		child.queue_free()
	
	var bg = TextureRect.new()
	bg.texture = load("res://Assets/Titles/GameOver.png")
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.size = Vector2(1280, 960)
	add_child(bg)
	
	var press_label = Label.new()
	press_label.text = "PRESS  START"
	press_label.add_theme_font_override("font", font)
	press_label.add_theme_font_size_override("font_size", 32)
	press_label.add_theme_color_override("font_color", Color(1, 1, 1))
	press_label.position = Vector2(1280 * 0.10, 960 * 0.78)
	add_child(press_label)
	
	# Esperar input para volver al título
	await _esperar_input()
	
	var fade2 = ColorRect.new()
	fade2.color = Color(0, 0, 0, 0)
	fade2.size = Vector2(1280, 960)
	add_child(fade2)
	var tween2 = create_tween()
	tween2.tween_property(fade2, "color:a", 1.0, 0.8)
	await tween2.finished
	GameData.stop_music()
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")
 
func _esperar_input() -> void:
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("Punch"):
			return
