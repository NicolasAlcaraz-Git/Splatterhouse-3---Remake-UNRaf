# hud.gd
extends CanvasLayer

const MAX_HP = 10
const MAX_POW = 100.0

var tiempo_restante: float = GameData.tiempo_restante
var tiempo_agotado: bool = false

var life_fill: ColorRect
var pow_fill: ColorRect
var time_label: Label
var lives_label: Label

var W: float = 1280.0
var H: float = 960.0
var S: float = 4.0

var font: FontFile

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	font = load("res://Assets/Items/PressStart2P.ttf")
	_crear_hud()

func _crear_hud() -> void:
	var font_size = int(10 * S)
	var bar_h = int(12 * S)
	var top_h = int(30 * S)
	var bottom_h = int(25 * S)
	
	var mapa = TextureRect.new()
	mapa.name = "Mapa"
	mapa.texture = load("res://Assets/Items/map.png")
	mapa.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mapa.size = Vector2(800, 600)
	mapa.position = Vector2(250, 190)
	mapa.visible = false
	add_child(mapa)

	# ── BARRA SUPERIOR ──
	var top_bg = ColorRect.new()
	top_bg.color = Color(0.022, 0.022, 0.022, 1.0)
	top_bg.position = Vector2(0, 0)
	top_bg.size = Vector2(W, top_h)
	add_child(top_bg)

	time_label = Label.new()
	time_label.text = "TIME  06:00"
	time_label.position = Vector2(W * 0.10, 12 * S)
	time_label.add_theme_font_size_override("font_size", font_size)
	time_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	if font:
		time_label.add_theme_font_override("font", font)
	add_child(time_label)

	# Cráneo — usando TextureRect con filtro nearest para pixel art
	var skull = TextureRect.new()
	skull.texture = load("res://Assets/Items/life.png")
	skull.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # ← pixelado nítido
	skull.position = Vector2(W * 0.62, 6 * S)
	skull.size = Vector2(20 * S, 20 * S)
	skull.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(skull)

	lives_label = Label.new()
	lives_label.text = "x%02d" % GameData.player_lives
	lives_label.position = Vector2(W * 0.64 + 16 * S, 10 * S)
	lives_label.add_theme_font_size_override("font_size", font_size)
	lives_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	if font:
		lives_label.add_theme_font_override("font", font)
	add_child(lives_label)

	# ── BARRA INFERIOR ──
	var bottom_bg = ColorRect.new()
	bottom_bg.color = Color(0.022, 0.022, 0.022, 1.0)
	bottom_bg.position = Vector2(0, H - bottom_h)
	bottom_bg.size = Vector2(W, bottom_h)
	add_child(bottom_bg)

	# POW
	var pow_label = Label.new()
	pow_label.text = "POW"
	pow_label.position = Vector2(4 * S, H - bottom_h + 7 * S)
	pow_label.add_theme_font_size_override("font_size", font_size)
	pow_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	if font:
		pow_label.add_theme_font_override("font", font)
	add_child(pow_label)

	var pow_bar_w = W * 0.35
	var pow_x = 40 * S
	var bar_y_pow = H - bottom_h + 8 * S

	var pow_bg = ColorRect.new()
	pow_bg.color = Color(0.2, 0.2, 0.2)
	pow_bg.position = Vector2(pow_x, bar_y_pow)
	pow_bg.size = Vector2(pow_bar_w, bar_h)
	add_child(pow_bg)

	pow_fill = ColorRect.new()
	pow_fill.color = Color(0.7, 0.7, 0.7, 1.0)
	pow_fill.position = Vector2(pow_x, bar_y_pow)
	pow_fill.size = Vector2(0, bar_h)  # empieza vacía
	add_child(pow_fill)

	# LIFE
	var life_label_node = Label.new()
	life_label_node.text = "LIFE"
	life_label_node.position = Vector2(W * 0.49, H - bottom_h + 7 * S)
	life_label_node.add_theme_font_size_override("font_size", font_size)
	life_label_node.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	if font:
		life_label_node.add_theme_font_override("font", font)
	add_child(life_label_node)

	var life_bar_w = W * 0.35
	var life_x = W * 0.55 + 26 * S
	var bar_y_life = H - bottom_h + 8 * S

	var life_bg = ColorRect.new()
	life_bg.color = Color(0.2, 0.2, 0.2)
	life_bg.position = Vector2(life_x, bar_y_life)
	life_bg.size = Vector2(life_bar_w, bar_h)
	add_child(life_bg)

	life_fill = ColorRect.new()
	life_fill.color = Color(0.686, 0.055, 0.059, 1.0)
	life_fill.position = Vector2(life_x, bar_y_life)
	life_fill.size = Vector2(life_bar_w, bar_h)
	add_child(life_fill)

	life_fill.set_meta("max_w", life_bar_w)
	pow_fill.set_meta("max_w", pow_bar_w)

func _process(_delta: float) -> void:
	# Pausa — siempre se ejecuta
	if Input.is_action_just_pressed("Pause"):
		var mapa = get_node_or_null("Mapa")
		if mapa:
			var pausando = not mapa.visible
			mapa.visible = pausando
			get_tree().paused = pausando

	# Todo lo siguiente NO corre si está pausado
	if get_tree().paused:
		return

	# TIEMPO
	GameData.tiempo_restante = tiempo_restante
	if not tiempo_agotado:
		tiempo_restante -= _delta
		if tiempo_restante <= 0:
			tiempo_restante = 0
			tiempo_agotado = true
			GameData.tiempo_agotado = true
		var minutos = int(tiempo_restante) / 60
		var segundos = int(tiempo_restante) % 60
		time_label.text = "TIME  %02d:%02d" % [minutos, segundos]

	# BARRAS y VIDAS
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var life_max_w = life_fill.get_meta("max_w")
		var pow_max_w = pow_fill.get_meta("max_w")

		# LIFE
		var life_pct = float(player.hp) / float(MAX_HP)
		life_fill.size.x = life_max_w * clamp(life_pct, 0.0, 1.0)

		# POW — lee de GameData para persistir entre escenas
		var pow_pct = GameData.player_pow / MAX_POW
		pow_fill.size.x = pow_max_w * clamp(pow_pct, 0.0, 1.0)

		# VIDAS — sincroniza con el jugador
		lives_label.text = "x%02d" % player.lives
