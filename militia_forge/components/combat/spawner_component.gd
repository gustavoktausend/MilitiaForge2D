## Spawner Component
##
## Manages spawning of entities (enemies, power-ups, etc.) with patterns and waves.
## Perfect for vertical shooters, wave-based games, and enemy management.
##
## Features:
## - Spawn enemies/objects at intervals
## - Multiple spawn patterns (line, formation, random, circle)
## - Wave system with progression
## - Spawn point management
## - Spawn limits and conditions
## - Event-driven spawning
##
## @tutorial(Combat System): res://docs/components/combat.md

class_name SpawnerComponent extends Component

#region Signals
## Emitted when an entity is spawned
signal entity_spawned(entity: Node, spawn_point: Vector2)

## Emitted when a wave starts
signal wave_started(wave_number: int)

## Emitted when a wave completes
signal wave_completed(wave_number: int)

## Emitted when all waves are complete
signal all_waves_completed()

## Emitted when spawn limit is reached
signal spawn_limit_reached()
#endregion

#region Enums
## Spawn patterns
enum SpawnPattern {
	SINGLE, ## Single spawn at center
	LINE, ## Horizontal line
	COLUMN, ## Vertical column
	FORMATION, ## Predefined formation
	RANDOM, ## Random positions
	CIRCLE, ## Circle pattern
	WAVE ## Wave formation
}
#endregion

#region Exports
@export_group("Spawning")
## Entity scene to spawn
@export var entity_scene: PackedScene

## Whether to start spawning automatically
@export var auto_start: bool = false

## Time between spawns (seconds)
@export var spawn_interval: float = 2.0

## Spawn pattern
@export var spawn_pattern: SpawnPattern = SpawnPattern.SINGLE

@export_group("Spawn Area")
## Spawn area center position (relative to host)
@export var spawn_area_center: Vector2 = Vector2(0, -300)

## Spawn area size
@export var spawn_area_size: Vector2 = Vector2(800, 100)

## Whether to use viewport bounds for spawn area
@export var use_viewport_bounds: bool = false

@export_group("Limits")
## Maximum entities alive at once (0 = unlimited)
@export var max_alive: int = 0

## Maximum total spawns (0 = unlimited)
@export var max_total_spawns: int = 0

## Stop spawning when max reached
@export var stop_at_max: bool = true

@export_group("Pattern Settings")
## Number of entities per spawn (for patterns)
@export var entities_per_spawn: int = 1

## Spacing between entities (for LINE and COLUMN)
@export var entity_spacing: float = 50.0

## Radius for CIRCLE pattern
@export var circle_radius: float = 100.0

@export_group("Wave System")
## Whether to use wave system
@export var use_waves: bool = false

## Current wave number
@export var current_wave: int = 0

## Entities per wave
@export var entities_per_wave: int = 10

## Time between waves (seconds)
@export var wave_delay: float = 5.0

## Whether to increase difficulty each wave
@export var scale_difficulty: bool = true

@export_group("Advanced")
## Whether spawned entities are parented to spawner
@export var parent_to_spawner: bool = false

## Specific node to parent spawned entities to (overrides parent_to_spawner and root)
@export var spawn_parent_path: NodePath

## Whether to print debug messages
@export var debug_spawner: bool = false
#endregion

#region Private Variables
## Spawn timer
var _spawn_timer: float = 0.0

## Total entities spawned
var _total_spawned: int = 0

## Currently alive entities
var _alive_entities: Array[Node] = []

## Wave timer
var _wave_timer: float = 0.0

## Entities spawned in current wave
var _wave_spawned: int = 0

## Whether spawner is active
var _is_active: bool = false

## Whether waiting between waves
var _waiting_for_wave: bool = false

## Parent node to spawn into
var _spawn_parent: Node = null
#endregion

#region Component Lifecycle
func component_ready() -> void:
	if not entity_scene:
		push_warning("[SpawnerComponent] No entity scene assigned!")
		return
	
	if not spawn_parent_path.is_empty():
		_spawn_parent = get_node_or_null(spawn_parent_path)
		if not _spawn_parent:
			push_warning("[SpawnerComponent] Spawn parent not found: %s" % spawn_parent_path)
	
	if auto_start:
		start_spawning()
	
	if debug_spawner:
		print("[SpawnerComponent] Ready - Pattern: %s, Interval: %.2fs" % [
			SpawnPattern.keys()[spawn_pattern],
			spawn_interval
		])

func component_process(delta: float) -> void:
	if not _is_active:
		return
	
	# Clean up dead entities
	_cleanup_dead_entities()
	
	# Handle wave system
	if use_waves:
		_update_wave_system(delta)
	else:
		_update_continuous_spawning(delta)

func cleanup() -> void:
	_alive_entities.clear()
	super.cleanup()
#endregion

#region Public Methods - Control
## Start spawning
func start_spawning() -> void:
	_is_active = true
	_spawn_timer = spawn_interval
	
	if use_waves and current_wave == 0:
		_start_next_wave()
	
	if debug_spawner:
		print("[SpawnerComponent] Started spawning")

## Stop spawning
func stop_spawning() -> void:
	_is_active = false
	
	if debug_spawner:
		print("[SpawnerComponent] Stopped spawning")

## Reset spawner
func reset() -> void:
	_total_spawned = 0
	_wave_spawned = 0
	current_wave = 0
	_alive_entities.clear()
	_is_active = false
	_waiting_for_wave = false

## Force spawn immediately
func force_spawn() -> void:
	_perform_spawn()
#endregion

#region Public Methods - Waves
## Start next wave manually
func start_next_wave() -> void:
	if use_waves:
		_start_next_wave()

## Skip to specific wave
func set_wave(wave_number: int) -> void:
	current_wave = wave_number
	_wave_spawned = 0
	
	if use_waves and _is_active:
		_start_next_wave()
#endregion

#region Public Methods - Queries
## Get number of alive entities
func get_alive_count() -> int:
	return _alive_entities.size()

## Check if at spawn limit
func is_at_limit() -> bool:
	if max_alive > 0 and _alive_entities.size() >= max_alive:
		return true
	if max_total_spawns > 0 and _total_spawned >= max_total_spawns:
		return true
	return false

## Check if spawner is active
func is_spawning() -> bool:
	return _is_active
#endregion

#region Private Methods - Spawning Logic
## Update continuous (non-wave) spawning
func _update_continuous_spawning(delta: float) -> void:
	_spawn_timer -= delta
	
	if _spawn_timer <= 0:
		if not is_at_limit():
			_perform_spawn()
			_spawn_timer = spawn_interval
		elif stop_at_max:
			stop_spawning()
			spawn_limit_reached.emit()

## Update wave system
func _update_wave_system(delta: float) -> void:
	if _waiting_for_wave:
		_wave_timer -= delta
		if _wave_timer <= 0:
			_waiting_for_wave = false
			_start_next_wave()
		return
	
	# Check if wave is complete
	if _wave_spawned >= entities_per_wave:
		_complete_wave()
		return
	
	# Spawn timer
	_spawn_timer -= delta
	
	if _spawn_timer <= 0:
		if not is_at_limit():
			_perform_spawn()
			_wave_spawned += 1
			_spawn_timer = spawn_interval

## Start next wave
func _start_next_wave() -> void:
	current_wave += 1
	_wave_spawned = 0
	
	# Apply difficulty scaling
	if scale_difficulty:
		_apply_wave_difficulty()
	
	wave_started.emit(current_wave)
	
	if debug_spawner:
		print("[SpawnerComponent] Wave %d started" % current_wave)

## Complete current wave
func _complete_wave() -> void:
	wave_completed.emit(current_wave)
	
	if debug_spawner:
		print("[SpawnerComponent] Wave %d completed" % current_wave)
	
	# Check if there are more waves
	if max_total_spawns > 0 and _total_spawned >= max_total_spawns:
		all_waves_completed.emit()
		stop_spawning()
	else:
		# Wait for next wave
		_waiting_for_wave = true
		_wave_timer = wave_delay

## Apply difficulty scaling for waves
func _apply_wave_difficulty() -> void:
	# Example scaling - customize as needed
	# Increase entities per wave
	entities_per_wave = int(entities_per_wave * 1.1)
	
	# Decrease spawn interval (faster spawning)
	spawn_interval = maxf(0.5, spawn_interval * 0.95)
#endregion

#region Private Methods - Spawn Execution
## Perform spawn based on pattern
func _perform_spawn() -> void:
	var spawn_positions: Array[Vector2] = []
	
	match spawn_pattern:
		SpawnPattern.SINGLE:
			spawn_positions = _get_single_spawn()
		SpawnPattern.LINE:
			spawn_positions = _get_line_spawn()
		SpawnPattern.COLUMN:
			spawn_positions = _get_column_spawn()
		SpawnPattern.FORMATION:
			spawn_positions = _get_formation_spawn()
		SpawnPattern.RANDOM:
			spawn_positions = _get_random_spawn()
		SpawnPattern.CIRCLE:
			spawn_positions = _get_circle_spawn()
		SpawnPattern.WAVE:
			spawn_positions = _get_wave_spawn()
	
	# Spawn at each position
	for pos in spawn_positions:
		_spawn_entity_at(pos)

## Spawn entity at specific position
func _spawn_entity_at(position: Vector2) -> void:
	if not entity_scene:
		return
	
	var entity = entity_scene.instantiate()
	entity.global_position = position
	
	# Parent handling
	if _spawn_parent:
		_spawn_parent.add_child(entity)
	elif parent_to_spawner:
		add_child(entity)
	else:
		get_tree().root.add_child(entity)
	
	# Track entity
	_alive_entities.append(entity)
	_total_spawned += 1
	
	# Emit signal
	entity_spawned.emit(entity, position)
	
	if debug_spawner:
		print("[SpawnerComponent] Spawned entity at %s (total: %d, alive: %d)" % [
			position, _total_spawned, _alive_entities.size()
		])
#endregion

#region Private Methods - Spawn Patterns
## Single spawn at center
func _get_single_spawn() -> Array[Vector2]:
	return [_get_spawn_center()]

## Line formation
func _get_line_spawn() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var center = _get_spawn_center()
	var half_count = (entities_per_spawn - 1) / 2.0
	
	for i in range(entities_per_spawn):
		var offset = (i - half_count) * entity_spacing
		positions.append(center + Vector2(offset, 0))
	
	return positions

## Column formation
func _get_column_spawn() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var center = _get_spawn_center()
	var half_count = (entities_per_spawn - 1) / 2.0
	
	for i in range(entities_per_spawn):
		var offset = (i - half_count) * entity_spacing
		positions.append(center + Vector2(0, offset))
	
	return positions

## Formation pattern (V-shape)
func _get_formation_spawn() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var center = _get_spawn_center()
	
	for i in range(entities_per_spawn):
		var offset_x = (i - entities_per_spawn / 2.0) * entity_spacing
		var offset_y = abs(offset_x) * 0.5 # V-shape
		positions.append(center + Vector2(offset_x, offset_y))
	
	return positions

## Random positions
func _get_random_spawn() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var area = _get_spawn_area()
	
	for i in range(entities_per_spawn):
		var random_pos = Vector2(
			randf_range(area.position.x, area.end.x),
			randf_range(area.position.y, area.end.y)
		)
		positions.append(random_pos)
	
	return positions

## Circle pattern
func _get_circle_spawn() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var center = _get_spawn_center()
	var angle_step = TAU / entities_per_spawn
	
	for i in range(entities_per_spawn):
		var angle = i * angle_step
		var offset = Vector2(cos(angle), sin(angle)) * circle_radius
		positions.append(center + offset)
	
	return positions

## Wave pattern
func _get_wave_spawn() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var center = _get_spawn_center()
	var half_count = (entities_per_spawn - 1) / 2.0
	
	for i in range(entities_per_spawn):
		var x_offset = (i - half_count) * entity_spacing
		var y_offset = sin(i * 0.5) * 30.0 # Wave curve
		positions.append(center + Vector2(x_offset, y_offset))
	
	return positions
#endregion

#region Private Methods - Helpers
## Get spawn area center
func _get_spawn_center() -> Vector2:
	if use_viewport_bounds:
		var viewport = get_viewport().get_visible_rect()
		return Vector2(viewport.size.x / 2, spawn_area_center.y)
	
	return host.global_position + spawn_area_center if host else spawn_area_center

## Get spawn area rectangle
func _get_spawn_area() -> Rect2:
	var center = _get_spawn_center()
	return Rect2(center - spawn_area_size / 2, spawn_area_size)

## Clean up dead entities from tracking
func _cleanup_dead_entities() -> void:
	for i in range(_alive_entities.size() - 1, -1, -1):
		if not is_instance_valid(_alive_entities[i]):
			_alive_entities.remove_at(i)
#endregion

#region Debug
## Get debug information
func get_debug_info() -> Dictionary:
	return {
		"is_active": _is_active,
		"pattern": SpawnPattern.keys()[spawn_pattern],
		"total_spawned": _total_spawned,
		"alive": _alive_entities.size(),
		"spawn_interval": "%.2fs" % spawn_interval,
		"next_spawn": "%.2fs" % _spawn_timer if _is_active else "N/A",
		"current_wave": current_wave if use_waves else "N/A",
		"wave_progress": "%d/%d" % [_wave_spawned, entities_per_wave] if use_waves else "N/A"
	}
#endregion
