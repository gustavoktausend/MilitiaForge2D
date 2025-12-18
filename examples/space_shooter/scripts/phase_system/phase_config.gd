## Phase Configuration Resource
##
## Defines a complete game phase with multiple waves, themes, and progression.
## This is a Resource so it can be configured visually in the Godot Inspector.

class_name PhaseConfig extends Resource

#region Phase Identity
@export_group("Phase Info")
## Phase number
@export var phase_number: int = 1

## Phase name
@export var phase_name: String = "Phase 1: Beginning"

## Phase description (displayed when phase starts)
@export_multiline var description: String = "The invasion begins..."
#endregion

#region Visual Theme
@export_group("Appearance")
## Background theme/color
@export_enum("Space", "Nebula", "Asteroid", "Station") var background_theme: String = "Space"

## Background color tint
@export var background_color: Color = Color(0.05, 0.05, 0.15)

## Music track to play (path to audio file)
@export_file("*.ogg", "*.mp3", "*.wav") var music_track: String = ""
#endregion

#region Waves
@export_group("Wave Progression")
## All waves in this phase
@export var waves: Array[WaveConfig] = []

## Whether to loop waves after completing all (endless mode)
@export var loop_waves: bool = false

## Difficulty increase per loop (only if loop_waves = true)
@export_range(0.0, 1.0, 0.1) var loop_difficulty_increase: float = 0.2
#endregion

#region Boss Configuration
@export_group("Boss Battle")
## Whether this phase has a boss at the end
@export var has_boss: bool = false

## Boss enemy type
@export var boss_type: String = "Boss"

## Boss health
@export_range(100, 10000, 100) var boss_health: int = 1000

## Boss score value
@export_range(1000, 50000, 500) var boss_score: int = 5000

## Boss movement pattern
@export_enum("StraightDown:0", "Zigzag:1", "Circular:2", "SineWave:3", "Tracking:4", "StopAndShoot:5")
var boss_movement_pattern: int = 4  # Tracking by default
#endregion

#region Phase Completion
@export_group("Completion Rewards")
## Score bonus for completing the phase
@export_range(0, 20000, 500) var phase_completion_bonus: int = 2000

## Message displayed on phase completion
@export var completion_message: String = "Phase Complete!"

## Whether completing this phase unlocks next phase
@export var unlocks_next_phase: bool = true
#endregion

#region Power-up Configuration
@export_group("Power-ups")
## Global power-up chance multiplier for this phase
@export_range(0.0, 3.0, 0.1) var powerup_chance_multiplier: float = 1.0

## Guaranteed power-up after boss (if has_boss = true)
@export var boss_guaranteed_powerup: bool = true
#endregion

## Total number of waves in this phase
var wave_count: int:
	get:
		return waves.size()

## Total enemy count across all waves (calculated)
var total_enemy_count: int:
	get:
		var count = 0
		for wave in waves:
			count += wave.total_enemy_count
		return count

## Estimated phase duration in seconds (calculated)
var estimated_duration: float:
	get:
		var duration = 0.0
		for wave in waves:
			duration += wave.max_duration + wave.preparation_time + wave.rest_time
		return duration

## Gets a specific wave by index
func get_wave(index: int) -> WaveConfig:
	if index < 0 or index >= waves.size():
		push_error("PhaseConfig: Invalid wave index %d" % index)
		return null
	return waves[index]

## Gets wave at index, with looping support
func get_wave_looped(index: int) -> WaveConfig:
	if not loop_waves or waves.is_empty():
		return get_wave(index)

	var looped_index = index % waves.size()
	var wave = waves[looped_index]

	# Apply difficulty scaling for looped waves
	if index >= waves.size():
		# TODO: Create modified copy with increased difficulty
		pass

	return wave

## Returns whether this is the final wave
func is_final_wave(wave_index: int) -> bool:
	if loop_waves:
		return false  # Never final in loop mode
	return wave_index >= waves.size() - 1

## Creates a summary dictionary for this phase
func get_summary() -> Dictionary:
	return {
		"phase_number": phase_number,
		"phase_name": phase_name,
		"wave_count": wave_count,
		"total_enemies": total_enemy_count,
		"has_boss": has_boss,
		"estimated_duration": estimated_duration,
		"completion_bonus": phase_completion_bonus
	}

## Validates the phase configuration
func validate() -> bool:
	if waves.is_empty():
		push_error("PhaseConfig: No waves defined!")
		return false

	if phase_number < 1:
		push_error("PhaseConfig: Phase number must be >= 1")
		return false

	# Validate all waves
	for i in range(waves.size()):
		var wave = waves[i]
		if wave == null:
			push_error("PhaseConfig: Wave %d is null!" % i)
			return false
		if not wave.validate():
			push_error("PhaseConfig: Wave %d validation failed" % i)
			return false

	return true
