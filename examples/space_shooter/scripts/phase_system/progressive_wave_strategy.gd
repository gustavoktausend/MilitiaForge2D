## Progressive Wave Strategy
##
## Generates waves that progressively increase in difficulty.
## Each wave adds more enemies and introduces new types gradually.

class_name ProgressiveWaveStrategy extends WaveStrategy

@export_group("Difficulty Scaling")
## How many enemies to add per wave
@export_range(1, 10, 1) var enemies_per_wave: int = 2

## Starting number of enemies
@export_range(1, 20, 1) var starting_enemies: int = 5

## Wave number when Fast enemies appear
@export_range(1, 20, 1) var fast_enemy_intro_wave: int = 3

## Wave number when Tank enemies appear
@export_range(1, 20, 1) var tank_enemy_intro_wave: int = 5

## Wave number when shooting enemies appear
@export_range(1, 20, 1) var shooting_intro_wave: int = 4

func generate_wave(wave_number: int, difficulty_multiplier: float = 1.0) -> WaveConfig:
	var groups: Array[EnemySpawnGroup] = []

	# Calculate base enemy count with scaling
	var base_count = starting_enemies + (wave_number - 1) * enemies_per_wave
	base_count = int(base_count * difficulty_multiplier)

	# Always include Basic enemies
	var basic_count = max(3, base_count / 2)
	var basic_can_shoot = wave_number >= shooting_intro_wave
	groups.append(_create_enemy_group(
		"Basic",
		basic_count,
		_get_movement_pattern(wave_number),
		basic_can_shoot
	))

	# Add Fast enemies after intro wave
	if wave_number >= fast_enemy_intro_wave:
		var fast_count = max(2, (wave_number - fast_enemy_intro_wave + 1) * 2)
		fast_count = int(fast_count * difficulty_multiplier)
		groups.append(_create_enemy_group(
			"Fast",
			fast_count,
			1,  # Zigzag movement
			wave_number >= shooting_intro_wave + 1
		))

	# Add Tank enemies after intro wave
	if wave_number >= tank_enemy_intro_wave:
		var tank_count = max(1, (wave_number - tank_enemy_intro_wave + 1))
		tank_count = int(tank_count * difficulty_multiplier)
		groups.append(_create_enemy_group(
			"Tank",
			tank_count,
			0,  # Straight down
			true  # Tanks always shoot
		))

	# Determine difficulty tier
	var difficulty = _get_difficulty_tier(wave_number)

	# Create wave
	var wave = _create_wave(wave_number, groups, difficulty)

	# Adjust wave duration based on wave number
	wave.max_duration = 30.0 + (wave_number * 5.0)
	wave.preparation_time = 2.0
	wave.rest_time = 3.0

	# Increase powerup chance on higher waves
	wave.powerup_chance = 0.15 + (wave_number * 0.02)
	wave.powerup_chance = min(wave.powerup_chance, 0.5)  # Cap at 50%

	# Bonus increases with wave number
	wave.completion_bonus = 500 + (wave_number * 100)

	return wave

## Returns movement pattern based on wave number
func _get_movement_pattern(wave_number: int) -> int:
	# Start simple, add variety as waves progress
	if wave_number <= 2:
		return 0  # Straight down
	elif wave_number <= 5:
		return randi() % 2  # Straight or Zigzag
	elif wave_number <= 8:
		return randi() % 4  # More variety
	else:
		return randi() % 5  # All patterns except StopAndShoot

## Returns difficulty tier based on wave number
func _get_difficulty_tier(wave_number: int) -> String:
	if wave_number <= 3:
		return "Easy"
	elif wave_number <= 7:
		return "Normal"
	elif wave_number <= 12:
		return "Hard"
	else:
		return "Extreme"

func get_strategy_name() -> String:
	return "ProgressiveStrategy"
