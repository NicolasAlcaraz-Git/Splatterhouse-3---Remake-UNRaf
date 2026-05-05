# game_data.gd
extends Node

var spawn_point: String = "SpawnDefault"
var spawn_pendiente: bool = false
var tiempo_agotado: bool = false
var tiempo_restante: float = 360.0
var player_hp: int = 5
var player_lives: int = 3
var player_pow: float = 0.0
var player_is_z_form: bool = false
var boss_derrotado: bool = false

var music_player: AudioStreamPlayer = null

func play_music(path: String) -> void:
	if music_player == null:
		music_player = AudioStreamPlayer.new()
		add_child(music_player)
	# Si ya está sonando la misma canción, no reiniciar
	if music_player.stream and music_player.stream.resource_path == path and music_player.playing:
		return
	music_player.stream = load(path)
	music_player.play()

func play_music_fresh(path: String) -> void:
	if music_player == null:
		music_player = AudioStreamPlayer.new()
		add_child(music_player)
	music_player.stream = load(path)
	music_player.play()

func stop_music() -> void:
	if music_player:
		music_player.stop()
