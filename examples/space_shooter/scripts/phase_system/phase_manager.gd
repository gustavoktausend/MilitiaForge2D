## Phase Manager
##
## Manages game progression through phases and waves.
## Coordinates with WaveManager and GameController.

class_name PhaseManager extends Node

#region Signals
## Emitted when a new phase starts
signal phase_started(phase_config: PhaseConfig)

## Emitted when current phase is completed
signal phase_completed(phase_config: PhaseConfig, score: int)

## Emitted when a new wave starts within current phase
signal wave_started(wave_config: WaveConfig, wave_index: int)

## Emitted when current wave is completed
signal wave_completed(wave_config: WaveConfig, enemies_defeated: int, score: int)

## Emitted when entering boss battle
signal boss_battle_started(boss_config: Dictionary)

## Emitted when boss is defeated
signal boss_defeated(score: int)

## Emitted when all phases are complete
signal all_phases_completed(total_score: int)
#endregion

#region Configuration
@export_group("Phase Progression")
## All phases in the game (in order)
@export var phases: Array[PhaseConfig] = []

## Starting phase index
@export var starting_phase: int = 0

## Whether to use dynamic wave generation (Strategy pattern)
@export var use_dynamic_waves: bool = false

## Wave strategy to use if dynamic waves enabled
@export var wave_strategy: WaveStrategy = null
#endregion

#region State
## Current phase index
var current_phase_index: int = -1

## Current wave index within phase
var current_wave_index: int = 0

## Current phase config
var current_phase: PhaseConfig = null

## Current wave config
var current_wave: WaveConfig = null

## Number of loops completed (for endless mode)
var loop_count: int = 0

## Whether currently in boss battle
var in_boss_battle: bool = false

## Total score accumulated
var total_score: int = 0
#endregion

#region References
## Reference to WaveManager
var wave_manager: Node = null

## Reference to GameController
var game_controller: Node = null
#endregion

func _ready() -> void:
	print("╔═══════════════════════════════════════════════════════╗")
	print("║            🎮 PHASE MANAGER INITIALIZED 🎮            ║")
	print("╚═══════════════════════════════════════════════════════╝")

	# Find dependencies
	call_deferred("_find_dependencies")

func _find_dependencies() -> void:
	# Find WaveManager
	var wave_managers = get_tree().get_nodes_in_group("wave_manager")
	if wave_managers.size() > 0:
		wave_manager = wave_managers[0]
		print("[PhaseManager] Found WaveManager: %s" % wave_manager.name)
	else:
		push_error("[PhaseManager] WaveManager not found!")

	# Find GameController
	var controllers = get_tree().get_nodes_in_group("game_controller")
	if controllers.size() > 0:
		game_controller = controllers[0]
		print("[PhaseManager] Found GameController: %s" % game_controller.name)
	else:
		push_error("[PhaseManager] GameController not found!")

## Starts the phase system from the beginning or specified phase
func start(phase_index: int = -1) -> void:
	if phase_index < 0:
		phase_index = starting_phase

	if phases.is_empty():
		push_error("[PhaseManager] No phases configured!")
		return

	print("[PhaseManager] Starting phase system at phase %d" % phase_index)
	_start_phase(phase_index)

## Starts a specific phase
func _start_phase(phase_index: int) -> void:
	if phase_index < 0 or phase_index >= phases.size():
		push_error("[PhaseManager] Invalid phase index: %d" % phase_index)
		return

	current_phase_index = phase_index
	current_phase = phases[phase_index]
	current_wave_index = 0
	loop_count = 0
	in_boss_battle = false

	# Validate phase
	if not current_phase.validate():
		push_error("[PhaseManager] Phase validation failed!")
		return

	print("╔═══════════════════════════════════════════════════════╗")
	print("║               📍 PHASE %d STARTED 📍                    ║" % (phase_index + 1))
	print("║  %s" % current_phase.phase_name.lpad(50))
	print("╠═══════════════════════════════════════════════════════╣")
	print("║  Waves: %d" % current_phase.wave_count)
	print("║  Total Enemies: %d" % current_phase.total_enemy_count)
	print("║  Has Boss: %s" % ("Yes" if current_phase.has_boss else "No"))
	print("╚═══════════════════════════════════════════════════════╝")

	phase_started.emit(current_phase)

	# Start first wave
	await get_tree().create_timer(2.0).timeout
	_start_next_wave()

## Starts the next wave in current phase
func _start_next_wave() -> void:
	if not current_phase:
		push_error("[PhaseManager] No active phase!")
		return

	# Check if we should enter boss battle
	if current_wave_index >= current_phase.waves.size():
		if current_phase.has_boss and not in_boss_battle:
			_start_boss_battle()
			return
		elif current_phase.loop_waves:
			_loop_phase()
			return
		else:
			_complete_phase()
			return

	# Get next wave (either from config or generate dynamically)
	if use_dynamic_waves and wave_strategy:
		var difficulty_mult = current_phase.get_difficulty_multiplier() if current_phase.has_method("get_difficulty_multiplier") else 1.0
		current_wave = wave_strategy.generate_wave(current_wave_index + 1, difficulty_mult)
	else:
		current_wave = current_phase.get_wave(current_wave_index)

	if not current_wave:
		push_error("[PhaseManager] Failed to get wave %d" % current_wave_index)
		return

	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("     🌊 WAVE %d/%d: %s" % [current_wave_index + 1, current_phase.wave_count, current_wave.wave_name])
	print("     Enemies: %d | Difficulty: %s" % [current_wave.total_enemy_count, current_wave.difficulty])
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	wave_started.emit(current_wave, current_wave_index)

	# Tell WaveManager to start this wave
	if wave_manager and wave_manager.has_method("start_wave_from_config"):
		wave_manager.start_wave_from_config(current_wave)
	else:
		push_warning("[PhaseManager] WaveManager doesn't support start_wave_from_config()")

	current_wave_index += 1

## Called when current wave is completed
func on_wave_completed(enemies_defeated: int, score_earned: int) -> void:
	if not current_wave:
		return

	print("[PhaseManager] Wave completed! Enemies: %d, Score: %d" % [enemies_defeated, score_earned])

	total_score += score_earned + current_wave.completion_bonus

	wave_completed.emit(current_wave, enemies_defeated, score_earned)

	# Wait rest time before next wave
	await get_tree().create_timer(current_wave.rest_time).timeout
	_start_next_wave()

## Loops the current phase (endless mode)
func _loop_phase() -> void:
	loop_count += 1
	current_wave_index = 0

	print("[PhaseManager] 🔄 Looping phase! Loop count: %d" % loop_count)

	# TODO: Apply difficulty scaling
	_start_next_wave()

## Starts boss battle
func _start_boss_battle() -> void:
	in_boss_battle = true

	var boss_config = {
		"type": current_phase.boss_type,
		"health": current_phase.boss_health,
		"score": current_phase.boss_score,
		"movement_pattern": current_phase.boss_movement_pattern
	}

	print("╔═══════════════════════════════════════════════════════╗")
	print("║              👹 BOSS BATTLE BEGINS! 👹                ║")
	print("║  %s" % current_phase.boss_type.lpad(50))
	print("║  Health: %d" % current_phase.boss_health)
	print("╚═══════════════════════════════════════════════════════╝")

	boss_battle_started.emit(boss_config)

	# TODO: Spawn boss through WaveManager
	# For now, just complete phase after delay
	await get_tree().create_timer(5.0).timeout
	on_boss_defeated()

## Called when boss is defeated
func on_boss_defeated() -> void:
	print("[PhaseManager] 🎉 Boss defeated!")

	total_score += current_phase.boss_score
	boss_defeated.emit(current_phase.boss_score)

	in_boss_battle = false

	await get_tree().create_timer(3.0).timeout
	_complete_phase()

## Completes current phase and moves to next
func _complete_phase() -> void:
	if not current_phase:
		return

	var phase_score = current_phase.phase_completion_bonus

	print("╔═══════════════════════════════════════════════════════╗")
	print("║            ✅ PHASE %d COMPLETE! ✅                     ║" % (current_phase_index + 1))
	print("║  Bonus: %d points" % phase_score)
	print("╚═══════════════════════════════════════════════════════╝")

	total_score += phase_score
	phase_completed.emit(current_phase, phase_score)

	# Move to next phase
	if current_phase_index + 1 < phases.size():
		await get_tree().create_timer(5.0).timeout
		_start_phase(current_phase_index + 1)
	else:
		_complete_all_phases()

## Called when all phases are completed
func _complete_all_phases() -> void:
	print("╔═══════════════════════════════════════════════════════╗")
	print("║         🏆 ALL PHASES COMPLETED! 🏆                   ║")
	print("║  Total Score: %d" % total_score)
	print("╚═══════════════════════════════════════════════════════╝")

	all_phases_completed.emit(total_score)

## Returns current phase progress (0.0 - 1.0)
func get_phase_progress() -> float:
	if not current_phase or current_phase.wave_count == 0:
		return 0.0
	return float(current_wave_index) / float(current_phase.wave_count)

## Returns overall game progress (0.0 - 1.0)
func get_overall_progress() -> float:
	if phases.is_empty():
		return 0.0
	var completed_phases = current_phase_index
	var phase_progress = get_phase_progress()
	return (completed_phases + phase_progress) / float(phases.size())
