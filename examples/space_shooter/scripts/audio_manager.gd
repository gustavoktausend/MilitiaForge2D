extends Node
## AudioManager - Sistema centralizado de áudio do jogo
##
## Gerencia música de fundo, efeitos sonoros de UI, gameplay, armas, etc.
## Uso: AudioManager.play_ui_sound("button_click")

#region Sound Categories
## Paths para diferentes categorias de sons
const AUDIO_BASE_PATH = "res://examples/space_shooter/assets/audio/"
const MUSIC_PATH = AUDIO_BASE_PATH + "music/"
const SFX_UI_PATH = AUDIO_BASE_PATH + "sfx/ui/"
const SFX_WEAPONS_PATH = AUDIO_BASE_PATH + "sfx/weapons/"
const SFX_IMPACTS_PATH = AUDIO_BASE_PATH + "sfx/impacts/"
const SFX_PICKUPS_PATH = AUDIO_BASE_PATH + "sfx/pickups/"
#endregion

#region Audio Players
## Pool de AudioStreamPlayers para efeitos sonoros
var sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE = 16  # Número de players simultâneos

## Player dedicado para música
var music_player: AudioStreamPlayer
var current_music: String = ""
var music_tween: Tween
#endregion

#region Volume Settings
## Volumes padrão para cada categoria
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var ui_volume: float = 0.9
#endregion

#region Cache
## Cache de AudioStreams já carregados
var audio_cache: Dictionary = {}
#endregion

func _ready() -> void:
	_initialize_audio_players()
	print("[AudioManager] Initialized with %d SFX players" % SFX_POOL_SIZE)

func _initialize_audio_players() -> void:
	# Criar player de música
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	add_child(music_player)

	# Criar pool de players de SFX
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % i
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

#region Music Control
## Toca uma música de fundo com fade opcional
func play_music(music_name: String, fade_duration: float = 1.0, loop: bool = true) -> void:
	# Se já está tocando a mesma música, não faz nada
	if current_music == music_name and music_player.playing:
		return

	var music_path = MUSIC_PATH + music_name + ".ogg"
	var stream = _load_audio_stream(music_path)

	if not stream:
		push_warning("[AudioManager] Music not found: %s" % music_path)
		return

	# Se tem música tocando, fade out primeiro
	if music_player.playing:
		await fade_out_music(fade_duration * 0.5)

	# Configurar e tocar nova música
	music_player.stream = stream

	# Configurar loop
	if stream is AudioStreamOggVorbis:
		stream.loop = loop

	current_music = music_name
	music_player.play()

	# Fade in
	fade_in_music(fade_duration)

## Fade in da música atual
func fade_in_music(duration: float = 1.0) -> void:
	if music_tween:
		music_tween.kill()

	music_player.volume_db = -80.0
	music_tween = create_tween()
	music_tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

## Fade out da música atual
func fade_out_music(duration: float = 0.5) -> void:
	if music_tween:
		music_tween.kill()

	music_tween = create_tween()
	music_tween.tween_property(music_player, "volume_db", -80.0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await music_tween.finished

## Para a música atual
func stop_music(fade_duration: float = 0.5) -> void:
	if not music_player.playing:
		return

	await fade_out_music(fade_duration)
	music_player.stop()
	current_music = ""

## Pausa/Resume da música
func pause_music() -> void:
	music_player.stream_paused = true

func resume_music() -> void:
	music_player.stream_paused = false
#endregion

#region SFX Control
## Toca um efeito sonoro de UI
func play_ui_sound(sound_name: String, volume_multiplier: float = 1.0) -> void:
	var sound_path = SFX_UI_PATH + sound_name + ".ogg"
	_play_sfx(sound_path, "UI", volume_multiplier * ui_volume)

## Toca um efeito sonoro de arma
func play_weapon_sound(sound_name: String, volume_multiplier: float = 1.0) -> void:
	var sound_path = SFX_WEAPONS_PATH + sound_name + ".ogg"
	_play_sfx(sound_path, "Gameplay", volume_multiplier * sfx_volume)

## Toca um efeito sonoro de impacto
func play_impact_sound(sound_name: String, volume_multiplier: float = 1.0) -> void:
	var sound_path = SFX_IMPACTS_PATH + sound_name + ".ogg"
	_play_sfx(sound_path, "Gameplay", volume_multiplier * sfx_volume)

## Toca um efeito sonoro de pickup
func play_pickup_sound(sound_name: String, volume_multiplier: float = 1.0) -> void:
	var sound_path = SFX_PICKUPS_PATH + sound_name + ".ogg"
	_play_sfx(sound_path, "Gameplay", volume_multiplier * sfx_volume)

## Toca um SFX genérico
func _play_sfx(sound_path: String, bus: String = "SFX", volume: float = 1.0) -> void:
	var stream = _load_audio_stream(sound_path)

	if not stream:
		# Não dá warning se o arquivo não existir ainda (em desenvolvimento)
		# push_warning("[AudioManager] SFX not found: %s" % sound_path)
		return

	# Encontrar um player disponível
	var player = _get_available_sfx_player()

	if not player:
		push_warning("[AudioManager] No available SFX player (pool full)")
		return

	# Configurar e tocar
	player.stream = stream
	player.bus = bus
	player.volume_db = linear_to_db(volume)
	player.play()

## Retorna um player de SFX disponível
func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player

	# Se todos estão ocupados, retorna o primeiro (vai interromper o som mais antigo)
	return sfx_players[0]
#endregion

#region Volume Control
## Define o volume master
func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))

## Define o volume da música
func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	if music_player.playing:
		music_player.volume_db = linear_to_db(music_volume)

## Define o volume dos SFX
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)

## Define o volume dos sons de UI
func set_ui_volume(volume: float) -> void:
	ui_volume = clamp(volume, 0.0, 1.0)
#endregion

#region Utility
## Carrega um AudioStream do cache ou do disco
func _load_audio_stream(path: String) -> AudioStream:
	# Verificar cache primeiro
	if audio_cache.has(path):
		return audio_cache[path]

	# Verificar se o arquivo existe
	if not FileAccess.file_exists(path):
		return null

	# Carregar e cachear
	var stream = load(path) as AudioStream
	if stream:
		audio_cache[path] = stream

	return stream

## Limpa o cache de áudio (útil para economizar memória)
func clear_audio_cache() -> void:
	audio_cache.clear()
	print("[AudioManager] Audio cache cleared")
#endregion
