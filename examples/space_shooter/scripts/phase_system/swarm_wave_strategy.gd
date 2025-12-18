## Swarm Wave Strategy
##
## Generates waves with large numbers of fast, weak enemies.
## Focus on overwhelming the player with quantity over quality.

class_name SwarmWaveStrategy extends WaveStrategy

@export_group("Swarm Configuration")
## Base number of enemies in a swarm
@export_range(10, 50, 5) var base_swarm_size: int = 20

## How much to increase swarm size per wave
@export_range(2, 20, 2) var swarm_growth: int = 5

## Percentage of enemies that should be fast (0.0 - 1.0)
@export_range(0.0, 1.0, 0.1) var fast_enemy_ratio: float = 0.7

func generate_wave(wave_number: int, difficulty_multiplier: float = 1.0) -> WaveConfig:
	var groups: Array[EnemySpawnGroup] = []

	# Calculate total swarm size
	var total_enemies = base_swarm_size + (wave_number - 1) * swarm_growth
	total_enemies = int(total_enemies * difficulty_multiplier)

	# Split between Fast and Basic
	var fast_count = int(total_enemies * fast_enemy_ratio)
	var basic_count = total_enemies - fast_count

	# Create Fast enemy swarm (main threat)
	if fast_count > 0:
		var fast_group = _create_enemy_group("Fast", fast_count, 1, false)  # Zigzag, no shooting
		fast_group.speed_multiplier = 1.2  # Even faster!
		fast_group.health_override = max(5, 10 - wave_number)  # Very weak
		fast_group.spawn_interval = 0.2  # Spawn quickly
		groups.append(fast_group)

	# Create Basic enemy support group
	if basic_count > 0:
		var basic_group = _create_enemy_group("Basic", basic_count, 0, wave_number >= 3)
		basic_group.spawn_interval = 0.3
		basic_group.spawn_delay = 2.0  # Come after fast enemies
		groups.append(basic_group)

	# Every 3rd wave, add a few tanks as "mini-bosses"
	if wave_number % 3 == 0:
		var tank_count = max(1, wave_number / 3)
		var tank_group = _create_enemy_group("Tank", tank_count, 5, true)  # StopAndShoot
		tank_group.spawn_delay = 5.0  # Come later
		tank_group.spawn_interval = 2.0  # Spawn slowly
		groups.append(tank_group)

	# Swarm waves are shorter but more intense
	var wave = _create_wave(wave_number, groups, _get_difficulty_tier(wave_number))
	wave.max_duration = 25.0 + (wave_number * 3.0)
	wave.preparation_time = 1.5  # Less prep time
	wave.rest_time = 4.0  # More rest after intense swarm
	wave.group_spawn_interval = 1.0  # Groups overlap more

	# Higher powerup chance due to more enemies
	wave.powerup_chance = 0.20
	wave.completion_bonus = 800 + (wave_number * 150)

	return wave

func _get_difficulty_tier(wave_number: int) -> String:
	# Swarms ramp up difficulty faster
	if wave_number <= 2:
		return "Normal"
	elif wave_number <= 5:
		return "Hard"
	else:
		return "Extreme"

func get_strategy_name() -> String:
	return "SwarmStrategy"
