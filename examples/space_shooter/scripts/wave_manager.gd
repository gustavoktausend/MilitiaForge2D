## Wave Manager for Space Shooter
##
## Manages enemy waves, spawning patterns, and difficulty progression.
## Uses EnemyFactory for creating enemy instances.

extends Node2D

# Preload EnemyFactory
const EnemyFactory = preload("res://examples/space_shooter/scripts/enemy_factory.gd")

#region Signals
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed()
#endregion

#region Exports
@export var start_delay: float = 2.0
@export var wave_delay: float = 3.0
@export var enemy_scene: PackedScene  # Will be set to enemy_base.gd scene
@export var spawn_area_width: float = 400.0
#endregion

#region Wave Configuration
var wave_definitions: Array[Dictionary] = [
	# Wave 1 - Easy introduction
	{
		"enemies": [
			{"type": "Basic", "count": 5, "health": 20, "speed": 100, "score": 100},
		],
		"spawn_delay": 1.0
	},
	# Wave 2 - More enemies
	{
		"enemies": [
			{"type": "Basic", "count": 8, "health": 20, "speed": 120, "score": 100},
			{"type": "Fast", "count": 2, "health": 10, "speed": 200, "score": 150},
		],
		"spawn_delay": 0.8
	},
	# Wave 3 - Mixed with shooting enemies
	{
		"enemies": [
			{"type": "Basic", "count": 6, "health": 25, "speed": 100, "score": 100},
			{"type": "Fast", "count": 4, "health": 15, "speed": 200, "score": 150},
			{"type": "Tank", "count": 2, "health": 50, "speed": 60, "score": 300},
		],
		"spawn_delay": 0.7
	},
	# Wave 4 - Challenging
	{
		"enemies": [
			{"type": "Basic", "count": 10, "health": 30, "speed": 130, "score": 120},
			{"type": "Fast", "count": 5, "health": 20, "speed": 220, "score": 180},
			{"type": "Tank", "count": 3, "health": 60, "speed": 70, "score": 350},
		],
		"spawn_delay": 0.6
	},
	# Wave 5 - Final wave
	{
		"enemies": [
			{"type": "Basic", "count": 12, "health": 35, "speed": 150, "score": 150},
			{"type": "Fast", "count": 8, "health": 25, "speed": 250, "score": 200},
			{"type": "Tank", "count": 5, "health": 80, "speed": 80, "score": 400},
		],
		"spawn_delay": 0.5
	},
]
#endregion

#region Private Variables
var current_wave: int = 0
var enemies_remaining: int = 0
var is_spawning: bool = false
var spawn_timer: float = 0.0
var enemies_to_spawn: Array[Dictionary] = []
var game_controller: Node = null
#endregion

func _ready() -> void:
	print("[WaveManager] Ready! Will start first wave in %d seconds..." % start_delay)
	# Start first wave after delay
	await get_tree().create_timer(start_delay).timeout
	print("[WaveManager] Delay finished, starting wave...")
	start_next_wave()

func _process(delta: float) -> void:
	if is_spawning:
		_update_spawning(delta)

func start_next_wave() -> void:
	if current_wave >= wave_definitions.size():
		all_waves_completed.emit()
		print("[WaveManager] All waves completed!")
		return

	var wave_data = wave_definitions[current_wave]
	current_wave += 1

	print("[WaveManager] Starting wave %d" % current_wave)
	wave_started.emit(current_wave)

	# Prepare enemies to spawn
	_prepare_wave_enemies(wave_data)

	# Start spawning
	is_spawning = true
	spawn_timer = 0.0

func _prepare_wave_enemies(wave_data: Dictionary) -> void:
	enemies_to_spawn.clear()

	for enemy_group in wave_data["enemies"]:
		for i in range(enemy_group["count"]):
			enemies_to_spawn.append(enemy_group.duplicate())

	# Shuffle for variety
	enemies_to_spawn.shuffle()
	enemies_remaining = enemies_to_spawn.size()

func _update_spawning(delta: float) -> void:
	if enemies_to_spawn.is_empty():
		is_spawning = false
		return

	var wave_data = wave_definitions[current_wave - 1]
	spawn_timer += delta

	if spawn_timer >= wave_data["spawn_delay"]:
		spawn_timer = 0.0
		_spawn_enemy(enemies_to_spawn.pop_front())

func _spawn_enemy(enemy_data: Dictionary) -> void:
	# Use EnemyFactory to create enemy with configuration
	var enemy = EnemyFactory.create_from_wave_data(enemy_data)

	if not enemy:
		push_error("[WaveManager] Failed to create enemy from wave data: %s" % enemy_data)
		return

	# Random spawn position at top of play area (between HUD panels)
	# Updated for 1920x1080: Play area is 960px wide, starting at x=480
	var play_area_center = 480 + 480  # Left panel + half of play area
	var play_area_half_width = 480  # Half of 960px play area
	var spawn_x = randf_range(-play_area_half_width + 50, play_area_half_width - 50)  # Keep enemies away from edges
	enemy.global_position = Vector2(
		play_area_center + spawn_x,
		-50
	)

	# IMPORTANT: Connect to enemy_died signal BEFORE adding to tree
	# This prevents race condition where enemy could die before we connect
	if enemy.has_signal("enemy_died"):
		enemy.enemy_died.connect(_on_enemy_died)
		print("[WaveManager] Connected to %s enemy signals" % enemy_data["type"])
	else:
		push_error("[WaveManager] ERROR: Enemy %s missing enemy_died signal!" % enemy_data["type"])

	# Find EnemiesContainer or use parent as fallback
	var container = get_parent().get_node_or_null("EnemiesContainer")
	if container:
		container.add_child(enemy)
	else:
		get_parent().add_child(enemy)

	print("[WaveManager] Spawned %s enemy at %v with %d health" % [enemy_data["type"], enemy.global_position, enemy.health])

func _on_enemy_died(enemy: Node, score_value: int) -> void:
	enemies_remaining -= 1

	# Notify game controller about score
	if game_controller and game_controller.has_method("add_score"):
		game_controller.add_score(score_value)

	print("[WaveManager] Enemy died! Remaining: %d" % enemies_remaining)

	# Check if wave is complete
	if enemies_remaining <= 0 and not is_spawning:
		_complete_wave()

func _complete_wave() -> void:
	print("[WaveManager] Wave %d completed!" % current_wave)
	wave_completed.emit(current_wave)

	# Start next wave after delay
	await get_tree().create_timer(wave_delay).timeout
	start_next_wave()

func set_game_controller(controller: Node) -> void:
	game_controller = controller

func get_current_wave() -> int:
	return current_wave

func get_total_waves() -> int:
	return wave_definitions.size()

func get_enemies_remaining() -> int:
	return enemies_remaining

## NEW: Starts a wave from a WaveConfig resource (Phase System integration)
func start_wave_from_config(wave_config: Resource) -> void:
	if not wave_config:
		push_error("[WaveManager] start_wave_from_config called with null config!")
		return

	print("[WaveManager] Starting wave from WaveConfig: %s" % wave_config.wave_name)

	# Convert WaveConfig to old wave_data format
	var wave_data = _convert_wave_config_to_data(wave_config)

	# Prepare enemies to spawn
	_prepare_wave_enemies(wave_data)

	# Start spawning
	is_spawning = true
	spawn_timer = 0.0

	# Note: Don't emit wave_started here - PhaseManager handles that

## Converts WaveConfig resource to internal wave_data Dictionary
func _convert_wave_config_to_data(wave_config: Resource) -> Dictionary:
	var wave_data: Dictionary = {
		"enemies": [],
		"spawn_delay": 0.8  # Default
	}

	# Process each enemy group in the wave config
	if wave_config.has("enemy_groups"):
		var enemy_groups = wave_config.get("enemy_groups")

		for group in enemy_groups:
			if not group:
				continue

			# Get spawn config from group
			var spawn_config = group.to_spawn_config() if group.has_method("to_spawn_config") else {}

			# Create enemy data entry
			var enemy_data = {
				"type": spawn_config.get("enemy_type", "Basic"),
				"count": spawn_config.get("count", 1),
				"health": spawn_config.get("health", 20),
				"speed": spawn_config.get("speed", 100.0),
				"score": spawn_config.get("score_value", 100),
				"damage_to_player": spawn_config.get("damage_to_player", 20),
				"movement_pattern": spawn_config.get("movement_pattern", 0),
				"can_shoot": spawn_config.get("can_shoot", false),
				"fire_rate": spawn_config.get("fire_rate", 1.5)
			}

			wave_data["enemies"].append(enemy_data)

		# Use average spawn interval from groups
		if enemy_groups.size() > 0:
			var total_interval = 0.0
			var count = 0
			for group in enemy_groups:
				if group.has("spawn_interval"):
					total_interval += group.get("spawn_interval")
					count += 1
			if count > 0:
				wave_data["spawn_delay"] = total_interval / count

	return wave_data
