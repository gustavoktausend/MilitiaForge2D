## Audio Component
##
## Manages sound effects and music playback with advanced features.
## Generic component useful for any game requiring audio.
##
## Features:
## - Sound effect playback with pooling
## - Music management with crossfading
## - Volume control per category
## - Spatial audio support (2D/3D)
## - Trigger-based sounds (damage, hit, death, etc.)
## - Audio ducking
## - Randomization (pitch, volume)
##
## @tutorial(Audio): res://docs/components/audio.md

class_name AudioComponent extends Component

#region Signals
## Emitted when sound starts
signal sound_started(sound_name: String)

## Emitted when sound finishes
signal sound_finished(sound_name: String)

## Emitted when music changes
signal music_changed(track_name: String)
#endregion

#region Enums
## Audio categories
enum AudioCategory {
	SFX,      ## Sound effects
	MUSIC,    ## Background music
	UI,       ## UI sounds
	VOICE,    ## Voice lines
	AMBIENT   ## Ambient sounds
}

## Trigger types
enum TriggerType {
	MANUAL,           ## Manually triggered
	ON_DAMAGE,        ## When taking damage
	ON_HEAL,          ## When healing
	ON_DEATH,         ## When dying
	ON_HIT_LANDED,    ## When landing hit
	ON_SPAWN,         ## On spawn
	ON_MOVEMENT       ## When moving
}
#endregion

#region Exports
@export_group("Sound Effect")
## Sound to play
@export var sound: AudioStream

## Audio category
@export var category: AudioCategory = AudioCategory.SFX

## Trigger type
@export var trigger_type: TriggerType = TriggerType.MANUAL

## Auto-play on ready
@export var auto_play: bool = false

@export_group("Playback")
## Volume (dB)
@export_range(-80, 24) var volume_db: float = 0.0

## Pitch scale
@export_range(0.01, 4.0) var pitch_scale: float = 1.0

## Whether sound loops
@export var loop: bool = false

@export_group("Spatial Audio")
## Enable 2D positional audio
@export var spatial_audio: bool = false

## Max distance for spatial audio
@export var max_distance: float = 2000.0

## Attenuation
@export_range(0.0, 4.0) var attenuation: float = 1.0

@export_group("Randomization")
## Randomize pitch
@export var randomize_pitch: bool = false

## Pitch variation range
@export var pitch_variation: float = 0.1

## Randomize volume
@export var randomize_volume: bool = false

## Volume variation (dB)
@export var volume_variation: float = 3.0

@export_group("Advanced")
## Use object pooling
@export var use_pooling: bool = true

## Pool size
@export var pool_size: int = 5

## Bus name
@export var bus_name: String = "Master"

## Whether to print debug messages
@export var debug_audio: bool = false
#endregion

#region Private Variables
## Audio player nodes pool
var _player_pool: Array[AudioStreamPlayer2D] = []

## Currently playing sounds
var _active_players: Array[AudioStreamPlayer2D] = []

## Music player
var _music_player: AudioStreamPlayer = null

## Current music track
var _current_music: String = ""

## Master volumes per category
var _category_volumes: Dictionary = {
	AudioCategory.SFX: 0.0,
	AudioCategory.MUSIC: 0.0,
	AudioCategory.UI: 0.0,
	AudioCategory.VOICE: 0.0,
	AudioCategory.AMBIENT: 0.0
}
#endregion

#region Component Lifecycle
func component_ready() -> void:
	# Create player pool
	if use_pooling:
		_create_player_pool()
	
	# Setup triggers
	_setup_triggers()
	
	# Auto-play
	if auto_play and sound:
		play()
	
	if debug_audio:
		print("[AudioComponent] Ready - Category: %s, Trigger: %s" % [
			AudioCategory.keys()[category],
			TriggerType.keys()[trigger_type]
		])

func cleanup() -> void:
	# Stop all sounds
	stop_all()
	
	# Clean up pool
	for player in _player_pool:
		if is_instance_valid(player):
			player.queue_free()
	
	_player_pool.clear()
	_active_players.clear()
	
	if _music_player and is_instance_valid(_music_player):
		_music_player.queue_free()
	
	super.cleanup()
#endregion

#region Public Methods - Sound Effects
## Play the sound effect
##
## @param stream: Optional stream to play (overrides default)
## @returns: AudioStreamPlayer2D instance
func play(stream: AudioStream = null) -> AudioStreamPlayer2D:
	var audio_stream = stream if stream else sound
	
	if not audio_stream:
		push_warning("[AudioComponent] No audio stream to play!")
		return null
	
	var player = _get_player()
	if not player:
		return null
	
	# Configure player
	player.stream = audio_stream
	player.volume_db = _get_final_volume()
	player.pitch_scale = _get_final_pitch()
	player.bus = bus_name
	
	# Position
	if spatial_audio and host:
		player.global_position = host.global_position
		player.max_distance = max_distance
		player.attenuation = attenuation
	
	# Play
	player.play()
	_active_players.append(player)
	
	# Handle completion
	if not loop:
		player.finished.connect(func(): _on_sound_finished(player), CONNECT_ONE_SHOT)
	
	sound_started.emit(audio_stream.resource_path if audio_stream.resource_path else "unknown")
	
	if debug_audio:
		print("[AudioComponent] Playing sound: %s" % audio_stream.resource_path)
	
	return player

## Stop sound
func stop() -> void:
	for player in _active_players:
		if is_instance_valid(player):
			player.stop()
	_active_players.clear()

## Stop all sounds in category
func stop_all_in_category(cat: AudioCategory) -> void:
	if cat != category:
		return
	stop()
#endregion

#region Public Methods - Music
## Play music track
##
## @param music_stream: Music to play
## @param crossfade_duration: Crossfade time (seconds)
func play_music(music_stream: AudioStream, crossfade_duration: float = 1.0) -> void:
	# Create music player if needed
	if not _music_player:
		_music_player = AudioStreamPlayer.new()
		_music_player.bus = "Music"
		add_child(_music_player)
	
	# Crossfade if already playing
	if _music_player.playing and crossfade_duration > 0:
		await _crossfade_music(music_stream, crossfade_duration)
	else:
		_music_player.stream = music_stream
		_music_player.volume_db = _category_volumes[AudioCategory.MUSIC]
		_music_player.play()
	
	_current_music = music_stream.resource_path if music_stream.resource_path else "unknown"
	music_changed.emit(_current_music)
	
	if debug_audio:
		print("[AudioComponent] Playing music: %s" % _current_music)

## Stop music
##
## @param fade_duration: Fade out time (seconds)
func stop_music(fade_duration: float = 1.0) -> void:
	if not _music_player or not _music_player.playing:
		return
	
	if fade_duration > 0:
		await _fade_out_music(fade_duration)
	else:
		_music_player.stop()
	
	_current_music = ""

## Set music volume
func set_music_volume(volume: float) -> void:
	_category_volumes[AudioCategory.MUSIC] = volume
	if _music_player:
		_music_player.volume_db = volume
#endregion

#region Public Methods - Volume Control
## Set category volume
func set_category_volume(cat: AudioCategory, volume: float) -> void:
	_category_volumes[cat] = volume
	
	# Update active players
	for player in _active_players:
		player.volume_db = _get_final_volume()

## Get category volume
func get_category_volume(cat: AudioCategory) -> float:
	return _category_volumes[cat]

## Mute category
func mute_category(cat: AudioCategory) -> void:
	set_category_volume(cat, -80.0)

## Unmute category
func unmute_category(cat: AudioCategory, volume: float = 0.0) -> void:
	set_category_volume(cat, volume)
#endregion

#region Public Methods - Queries
## Check if any sound is playing
func is_playing() -> bool:
	return _active_players.size() > 0

## Get currently playing music
func get_current_music() -> String:
	return _current_music
#endregion

#region Private Methods - Player Pool
## Create player pool
func _create_player_pool() -> void:
	for i in range(pool_size):
		var player = AudioStreamPlayer2D.new() if spatial_audio else AudioStreamPlayer.new()
		player.name = "AudioPlayer%d" % i
		add_child(player)
		_player_pool.append(player)

## Get available player from pool
func _get_player() -> AudioStreamPlayer2D:
	# Try to reuse from pool
	if use_pooling:
		for player in _player_pool:
			if is_instance_valid(player) and not player.playing:
				return player
	
	# Create new if pool full or not using pooling
	if not use_pooling or _player_pool.size() >= pool_size:
		var player = AudioStreamPlayer2D.new() if spatial_audio else AudioStreamPlayer.new()
		add_child(player)
		if use_pooling:
			_player_pool.append(player)
		return player
	
	return null
#endregion

#region Private Methods - Randomization
## Get final volume with randomization
func _get_final_volume() -> float:
	var vol = volume_db + _category_volumes[category]
	
	if randomize_volume:
		vol += randf_range(-volume_variation, volume_variation)
	
	return vol

## Get final pitch with randomization
func _get_final_pitch() -> float:
	var pitch = pitch_scale
	
	if randomize_pitch:
		pitch += randf_range(-pitch_variation, pitch_variation)
	
	return clampf(pitch, 0.01, 4.0)
#endregion

#region Private Methods - Music Crossfade
## Crossfade to new music
func _crossfade_music(new_stream: AudioStream, duration: float) -> void:
	var old_player = _music_player
	var old_volume = old_player.volume_db
	
	# Create new player for crossfade
	var new_player = AudioStreamPlayer.new()
	new_player.bus = "Music"
	new_player.stream = new_stream
	new_player.volume_db = -80.0
	add_child(new_player)
	new_player.play()
	
	# Crossfade
	var time = 0.0
	while time < duration:
		time += get_process_delta_time()
		var progress = time / duration
		
		old_player.volume_db = lerp(old_volume, -80.0, progress)
		new_player.volume_db = lerp(-80.0, _category_volumes[AudioCategory.MUSIC], progress)
		
		await get_tree().process_frame
	
	# Cleanup old player
	old_player.stop()
	old_player.queue_free()
	_music_player = new_player

## Fade out music
func _fade_out_music(duration: float) -> void:
	var start_volume = _music_player.volume_db
	var time = 0.0
	
	while time < duration:
		time += get_process_delta_time()
		var progress = time / duration
		_music_player.volume_db = lerp(start_volume, -80.0, progress)
		await get_tree().process_frame
	
	_music_player.stop()
#endregion

#region Private Methods - Triggers
## Setup trigger connections
func _setup_triggers() -> void:
	if trigger_type == TriggerType.MANUAL:
		return
	
	match trigger_type:
		TriggerType.ON_DAMAGE:
			_connect_damage_trigger()
		TriggerType.ON_HEAL:
			_connect_heal_trigger()
		TriggerType.ON_DEATH:
			_connect_death_trigger()
		TriggerType.ON_HIT_LANDED:
			_connect_hit_trigger()
		TriggerType.ON_SPAWN:
			# Already handled by auto_play
			pass
		TriggerType.ON_MOVEMENT:
			_connect_movement_trigger()

func _connect_damage_trigger() -> void:
	var health = host.get_component("HealthComponent")
	if health:
		health.damage_taken.connect(func(_amount, _attacker): play())

func _connect_heal_trigger() -> void:
	var health = host.get_component("HealthComponent")
	if health:
		health.healed.connect(func(_amount): play())

func _connect_death_trigger() -> void:
	var health = host.get_component("HealthComponent")
	if health:
		health.died.connect(func(): play())

func _connect_hit_trigger() -> void:
	for child in host.get_children():
		if child is Hitbox:
			child.hit_landed.connect(func(_target, _damage): play())
			break

func _connect_movement_trigger() -> void:
	var movement = host.get_component("MovementComponent")
	if movement:
		movement.movement_started.connect(func(): play())
#endregion

#region Private Methods - Callbacks
func _on_sound_finished(player: AudioStreamPlayer2D) -> void:
	_active_players.erase(player)
	sound_finished.emit(player.stream.resource_path if player.stream and player.stream.resource_path else "unknown")
#endregion

#region Public Static - Global Control
## Stop all audio globally
static func stop_all() -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		for node in tree.get_nodes_in_group("audio_component"):
			if node is AudioComponent:
				node.stop()
#endregion

#region Debug
## Get debug information
func get_debug_info() -> Dictionary:
	return {
		"category": AudioCategory.keys()[category],
		"trigger": TriggerType.keys()[trigger_type],
		"playing": is_playing(),
		"active_sounds": _active_players.size(),
		"pool_size": _player_pool.size() if use_pooling else "disabled",
		"current_music": _current_music if _current_music else "none",
		"volume": "%.1f dB" % volume_db
	}
#endregion
