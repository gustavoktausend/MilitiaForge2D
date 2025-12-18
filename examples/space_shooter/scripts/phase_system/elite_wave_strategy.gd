## Elite Wave Strategy
##
## Generates waves with fewer but stronger enemies.
## Focus on quality over quantity - challenging individual encounters.

class_name EliteWaveStrategy extends WaveStrategy

@export_group("Elite Configuration")
## Base number of elite enemies
@export_range(3, 15, 1) var base_elite_count: int = 5

## How many elites to add per wave
@export_range(1, 5, 1) var elite_growth: int = 1

## Health multiplier for elite enemies
@export_range(1.5, 5.0, 0.5) var health_multiplier: float = 2.0

## Speed multiplier for elite enemies
@export_range(0.8, 2.0, 0.1) var speed_multiplier: float = 1.2

func generate_wave(wave_number: int, difficulty_multiplier: float = 1.0) -> WaveConfig:
	var groups: Array[EnemySpawnGroup] = []

	# Calculate total elite count
	var total_elites = base_elite_count + (wave_number - 1) * elite_growth
	total_elites = int(total_elites * difficulty_multiplier)

	# Distribute across enemy types
	var tank_count = max(2, total_elites / 3)
	var fast_count = max(2, total_elites / 4)
	var basic_count = max(1, total_elites - tank_count - fast_count)

	# Elite Tank group - slow but deadly
	var tank_group = _create_enemy_group("Tank", tank_count, 5, true)  # StopAndShoot
	tank_group.health_override = int(50 * health_multiplier * (1.0 + wave_number * 0.1))
	tank_group.speed_multiplier = speed_multiplier * 0.8  # Slower
	tank_group.fire_rate_override = max(0.5, 1.5 - wave_number * 0.1)  # Faster shooting
	tank_group.damage_override = 30 + wave_number * 2
	tank_group.spawn_interval = 1.5
	groups.append(tank_group)

	# Elite Fast group - hard to hit
	var fast_group = _create_enemy_group("Fast", fast_count, 2, wave_number >= 3)  # Circular
	fast_group.health_override = int(15 * health_multiplier)
	fast_group.speed_multiplier = speed_multiplier * 1.5  # Much faster
	fast_group.fire_rate_override = 1.0
	fast_group.spawn_delay = 3.0  # Come after tanks
	fast_group.spawn_interval = 1.0
	groups.append(fast_group)

	# Elite Basic group - balanced threat
	if basic_count > 0:
		var basic_group = _create_enemy_group("Basic", basic_count, 4, true)  # Tracking
		basic_group.health_override = int(30 * health_multiplier)
		basic_group.speed_multiplier = speed_multiplier
		basic_group.fire_rate_override = 1.2
		basic_group.spawn_delay = 6.0  # Come last
		basic_group.spawn_interval = 1.2
		groups.append(basic_group)

	# Boss wave every 5 waves
	if wave_number % 5 == 0:
		var boss_group = _create_enemy_group("Tank", 1, 4, true)  # Single tracking tank
		boss_group.health_override = int(200 * health_multiplier * wave_number * 0.5)
		boss_group.speed_multiplier = 0.6  # Slow
		boss_group.fire_rate_override = 0.3  # Very fast shooting
		boss_group.damage_override = 50
		boss_group.score_override = 2000 + wave_number * 500
		boss_group.spawn_delay = 10.0  # Appears last
		groups.append(boss_group)

	var wave = _create_wave(wave_number, groups, _get_difficulty_tier(wave_number))

	# Elite waves last longer due to tougher enemies
	wave.max_duration = 40.0 + (wave_number * 5.0)
	wave.preparation_time = 3.0  # More time to prepare
	wave.rest_time = 5.0  # More rest after tough battle
	wave.group_spawn_interval = 2.0

	# Lower powerup chance but guaranteed on boss waves
	wave.powerup_chance = 0.10
	wave.completion_bonus = 1200 + (wave_number * 200)

	return wave

func _get_difficulty_tier(wave_number: int) -> String:
	# Elite waves start harder
	if wave_number <= 2:
		return "Normal"
	elif wave_number <= 4:
		return "Hard"
	else:
		return "Extreme"

func get_strategy_name() -> String:
	return "EliteStrategy"
