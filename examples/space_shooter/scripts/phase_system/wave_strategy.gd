## Wave Strategy Base Class
##
## Abstract base class for wave generation strategies.
## Subclasses implement specific algorithms for generating waves dynamically.

class_name WaveStrategy extends Resource

## Generates a WaveConfig for the given wave number
## This is the main method that subclasses must implement
func generate_wave(wave_number: int, difficulty_multiplier: float = 1.0) -> WaveConfig:
	push_error("WaveStrategy: generate_wave() must be implemented by subclass!")
	return null

## Helper: Creates a basic enemy group
func _create_enemy_group(
	enemy_type: String,
	count: int,
	movement_pattern: int = 0,
	can_shoot: bool = false
) -> EnemySpawnGroup:
	var group = EnemySpawnGroup.new()
	group.enemy_type = enemy_type
	group.count = count
	group.movement_pattern = movement_pattern
	group.can_shoot = can_shoot
	return group

## Helper: Creates a wave config with given groups
func _create_wave(
	wave_number: int,
	groups: Array[EnemySpawnGroup],
	difficulty: String = "Normal"
) -> WaveConfig:
	var wave = WaveConfig.new()
	wave.wave_number = wave_number
	wave.wave_name = "Wave %d" % wave_number
	wave.difficulty = difficulty
	wave.enemy_groups = groups
	return wave

## Returns the strategy name (for debugging)
func get_strategy_name() -> String:
	return "BaseStrategy"
