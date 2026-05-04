extends Node2D

@onready var portals: Array = []
@onready var floor_sprite = $Room8

var fondo_abierto = preload("res://Assets/Stage1/floor8open.png")
var enemies_alive: int = 0

func _ready() -> void:
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
	for portal in portals:
		portal.activate()
	if floor_sprite:
		floor_sprite.texture = fondo_abierto

func _process(_delta: float) -> void:
	pass
