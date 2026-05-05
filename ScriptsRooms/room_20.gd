extends Node2D

@onready var portals: Array = []
@onready var floor_sprite = $Room20

var fondo_abierto = preload("res://Assets/Stage2/floor20open.png")
var enemies_alive: int = 0

func _ready() -> void:
	GameData.play_music("res://Assets/Sound/Stage.mp3")
	_buscar_nodos(self)
	print("enemigos al inicio: ", enemies_alive)
	print("portales encontrados: ", portals.size())

func _buscar_nodos(nodo: Node) -> void:
	for child in nodo.get_children():
		if child.is_in_group("enemy"):
			enemies_alive += 1
		if child.has_method("activate"):
			portals.append(child)
		_buscar_nodos(child)  # buscar dentro de cada hijo también
	
	# Buscar portales
	for child in get_children():
		if child.has_method("activate"):
			portals.append(child)
	print("portales encontrados: ", portals.size())

func enemy_died() -> void:
	enemies_alive -= 1
	print("enemigo muerto, quedan: ", enemies_alive)
	if enemies_alive <= 0:
		_abrir_portales()

func _abrir_portales() -> void:
	var sfx = AudioStreamPlayer.new()
	sfx.stream = load("res://Assets/Sound/Door.mp3")
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
	GameData.play_music("res://Assets/Sound/Choose.mp3")
	var player = get_tree().get_first_node_in_group("player")
	if player and player.is_z_form:
		player._destransformar()
	
	for portal in portals:
		portal.activate()
	if floor_sprite:
		floor_sprite.texture = fondo_abierto
	set_process(false)

func _process(_delta: float) -> void:
	pass
