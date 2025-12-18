## Wave Configuration Resource
##
## Defines a complete wave with multiple enemy groups and timing.
## This is a Resource so it can be configured visually in the Godot Inspector.

class_name WaveConfig extends Resource

#region Wave Identity
@export_group("Wave Info")
## Wave number (for display purposes)
@export var wave_number: int = 1

## Wave name/description
@export var wave_name: String = "Wave 1"

## Wave difficulty (affects spawn rates and enemy stats)
@export_enum("Easy", "Normal", "Hard", "Extreme") var difficulty: String = "Normal"
#endregion

#region Enemy Groups
@export_group("Enemy Composition")
## Groups of enemies to spawn in this wave
@export var enemy_groups: Array[EnemySpawnGroup] = []

## Total number of enemies across all groups (calculated)
var total_enemy_count: int:
	get:
		var count = 0
		for group in enemy_groups:
			count += group.count
		return count
#endregion

#region Timing
@export_group("Wave Duration")
## Maximum duration of the wave in seconds (0 = until all enemies defeated)
@export_range(0.0, 300.0, 5.0) var max_duration: float = 60.0

## Time between spawning different groups
@export_range(0.0, 10.0, 0.5) var group_spawn_interval: float = 2.0

## Countdown before wave starts
@export_range(0.0, 10.0, 0.5) var preparation_time: float = 2.0
#endregion

#region Power-ups
@export_group("Rewards")
## Chance for power-ups to drop (0.0 - 1.0)
@export_range(0.0, 1.0, 0.05) var powerup_chance: float = 0.15

## Types of power-ups that can drop
@export_flags("Health", "Weapon", "Speed", "Shield") var allowed_powerups: int = 15  # All flags enabled
#endregion

#region Wave Completion
@export_group("Completion")
## Bonus score for completing the wave
@export_range(0, 5000, 100) var completion_bonus: int = 500

## Message to display when wave completes
@export var completion_message: String = "Wave Complete!"

## Rest time before next wave (seconds)
@export_range(0.0, 15.0, 0.5) var rest_time: float = 3.0
#endregion

## Returns difficulty multiplier
func get_difficulty_multiplier() -> float:
	match difficulty:
		"Easy": return 0.75
		"Normal": return 1.0
		"Hard": return 1.5
		"Extreme": return 2.0
		_: return 1.0

## Returns whether a specific powerup type is allowed
func is_powerup_allowed(powerup_type: String) -> bool:
	match powerup_type:
		"Health": return (allowed_powerups & 1) != 0
		"Weapon": return (allowed_powerups & 2) != 0
		"Speed": return (allowed_powerups & 4) != 0
		"Shield": return (allowed_powerups & 8) != 0
		_: return false

## Creates a summary dictionary for this wave
func get_summary() -> Dictionary:
	return {
		"wave_number": wave_number,
		"wave_name": wave_name,
		"difficulty": difficulty,
		"total_enemies": total_enemy_count,
		"groups_count": enemy_groups.size(),
		"max_duration": max_duration,
		"completion_bonus": completion_bonus
	}

## Validates the wave configuration
func validate() -> bool:
	if enemy_groups.is_empty():
		push_error("WaveConfig: No enemy groups defined!")
		return false

	if wave_number < 1:
		push_error("WaveConfig: Wave number must be >= 1")
		return false

	return true
