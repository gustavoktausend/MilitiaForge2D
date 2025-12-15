## Enemy Factory
##
## Factory Pattern for creating and configuring enemies.
## Provides centralized enemy creation with object pooling support.
##
## Features:
## - Type-based enemy creation
## - Configuration via dictionaries
## - Object pooling for performance
## - Easy extensibility for new enemy types
##
## Usage:
## ```
## var enemy = EnemyFactory.create_enemy(EnemyType.MET, Vector2(100, 200), {
##     "health": 50,
##     "speed": 100
## })
## ```

class_name PlatformerEnemyFactory extends Node

#region Enemy Types
enum EnemyType {
	MET, ## Ground enemy that hides and shoots
	FLYING, ## Flying enemy that chases player
	TURRET ## Fixed turret that aims and shoots
}
#endregion

#region Export
@export_group("Enemy Scenes")
## Met enemy scene
@export var met_scene: PackedScene

## Flying enemy scene
@export var flying_scene: PackedScene

## Turret enemy scene
@export var turret_scene: PackedScene

@export_group("Pooling")
## Enable object pooling
@export var use_pooling: bool = true

## Pool size per enemy type
@export var pool_size_per_type: int = 10

@export_group("Debug")
## Print debug messages
@export var debug_factory: bool = false
#endregion

#region Private Variables
## Enemy scene dictionary
var _enemy_scenes: Dictionary = {}

## Object pools (EnemyType -> Array[Node2D])
var _pools: Dictionary = {}

## Active enemies tracking
var _active_enemies: Array[Node2D] = []

## Parent node for enemies
var _enemy_container: Node2D = null
#endregion

#region Initialization
func _ready() -> void:
	# Build enemy scenes dictionary
	_enemy_scenes[EnemyType.MET] = met_scene
	_enemy_scenes[EnemyType.FLYING] = flying_scene
	_enemy_scenes[EnemyType.TURRET] = turret_scene
	
	# Initialize pools
	if use_pooling:
		_initialize_pools()
	
	# Create enemy container
	_enemy_container = Node2D.new()
	_enemy_container.name = "Enemies"
	add_child(_enemy_container)
	
	if debug_factory:
		print("[EnemyFactory] Initialized with pooling: %s" % use_pooling)

## Initialize object pools
func _initialize_pools() -> void:
	for type in EnemyType.values():
		_pools[type] = []
		
		# Pre-create pooled enemies
		var scene = _enemy_scenes.get(type)
		if scene:
			for i in range(pool_size_per_type):
				var enemy = scene.instantiate()
				enemy.visible = false
				enemy.process_mode = Node.PROCESS_MODE_DISABLED
				_enemy_container.add_child(enemy)
				_pools[type].append(enemy)
			
			if debug_factory:
				print("[EnemyFactory] Created pool for %s: %d enemies" % [
					EnemyType.keys()[type],
					pool_size_per_type
				])
#endregion

#region Factory Methods
## Create an enemy instance
##
## @param type: Type of enemy to create
## @param position: Spawn position
## @param config: Configuration dictionary (optional)
## @returns: Enemy node instance
func create_enemy(type: EnemyType, position: Vector2, config: Dictionary = {}) -> Node2D:
	var enemy: Node2D = null
	
	# Try to get from pool
	if use_pooling:
		enemy = _get_from_pool(type)
	
	# Create new if pool empty or pooling disabled
	if not enemy:
		enemy = _instantiate_enemy(type)
	
	if not enemy:
		push_error("[EnemyFactory] Failed to create enemy of type %s" % EnemyType.keys()[type])
		return null
	
	# Configure enemy
	_configure_enemy(enemy, position, config)
	
	# Track active
	if enemy not in _active_enemies:
		_active_enemies.append(enemy)
	
	# Connect death signal for cleanup
	_connect_enemy_signals(enemy)
	
	if debug_factory:
		print("[EnemyFactory] Created %s at %s" % [EnemyType.keys()[type], position])
	
	return enemy

## Destroy/return enemy to pool
##
## @param enemy: Enemy to destroy
func destroy_enemy(enemy: Node2D) -> void:
	if not enemy:
		return
	
	# Remove from active tracking
	_active_enemies.erase(enemy)
	
	# Return to pool or delete
	if use_pooling:
		_return_to_pool(enemy)
	else:
		enemy.queue_free()
	
	if debug_factory:
		print("[EnemyFactory] Destroyed enemy: %s" % enemy.name)

## Get from pool
func _get_from_pool(type: EnemyType) -> Node2D:
	if not _pools.has(type):
		return null
	
	var pool = _pools[type]
	for enemy in pool:
		if not enemy.visible: # Inactive enemy
			return enemy
	
	# Pool exhausted, create new
	if debug_factory:
		print("[EnemyFactory] Pool exhausted for %s, creating new" % EnemyType.keys()[type])
	
	return null

## Return to pool
func _return_to_pool(enemy: Node2D) -> void:
	# Reset enemy
	enemy.visible = false
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	enemy.position = Vector2.ZERO
	
	# Disconnect signals to prevent leaks
	_disconnect_enemy_signals(enemy)

## Instantiate new enemy
func _instantiate_enemy(type: EnemyType) -> Node2D:
	var scene = _enemy_scenes.get(type)
	if not scene:
		push_error("[EnemyFactory] No scene configured for type %s" % EnemyType.keys()[type])
		return null
	
	var enemy = scene.instantiate()
	_enemy_container.add_child(enemy)
	return enemy

## Configure enemy
func _configure_enemy(enemy: Node2D, position: Vector2, config: Dictionary) -> void:
	# Activate enemy
	enemy.visible = true
	enemy.process_mode = Node.PROCESS_MODE_INHERIT
	enemy.global_position = position
	
	# Apply configuration if enemy has configure method
	if enemy.has_method("configure"):
		enemy.configure(config)
	else:
		# Fallback: set properties directly
		for key in config:
			if key in enemy:
				enemy.set(key, config[key])

## Connect enemy signals
func _connect_enemy_signals(enemy: Node2D) -> void:
	# Look for ComponentHost and HealthComponent
	var host = enemy as ComponentHost
	if not host and enemy.has_method("get_node"):
		host = enemy.get_node_or_null("ComponentHost") as ComponentHost
	
	if host:
		var health = host.get_component("HealthComponent")
		if health and health.has_signal("died"):
			if not health.died.is_connected(_on_enemy_died):
				health.died.connect(_on_enemy_died.bind(enemy))

## Disconnect enemy signals
func _disconnect_enemy_signals(enemy: Node2D) -> void:
	var host = enemy as ComponentHost
	if not host and enemy.has_method("get_node"):
		host = enemy.get_node_or_null("ComponentHost") as ComponentHost
	
	if host:
		var health = host.get_component("HealthComponent")
		if health and health.has_signal("died"):
			if health.died.is_connected(_on_enemy_died):
				health.died.disconnect(_on_enemy_died)
#endregion

#region Batch Operations
## Create multiple enemies at once
##
## @param spawn_data: Array of {type, position, config} dictionaries
## @returns: Array of created enemies
func create_enemies_batch(spawn_data: Array) -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	
	for data in spawn_data:
		var enemy = create_enemy(
			data.get("type", EnemyType.MET),
			data.get("position", Vector2.ZERO),
			data.get("config", {})
		)
		if enemy:
			enemies.append(enemy)
	
	return enemies

## Destroy all active enemies
func destroy_all_enemies() -> void:
	var enemies_to_destroy = _active_enemies.duplicate()
	for enemy in enemies_to_destroy:
		destroy_enemy(enemy)
	
	if debug_factory:
		print("[EnemyFactory] Destroyed all %d active enemies" % enemies_to_destroy.size())

## Get count of active enemies
func get_active_enemy_count() -> int:
	return _active_enemies.size()

## Get all active enemies
func get_active_enemies() -> Array[Node2D]:
	return _active_enemies.duplicate()

## Get active enemies of specific type
func get_enemies_of_type(type: EnemyType) -> Array[Node2D]:
	var result: Array[Node2D] = []
	var type_name = EnemyType.keys()[type]
	
	for enemy in _active_enemies:
		# Check enemy type (this assumes enemies have a type property)
		if enemy.get("enemy_type") == type:
			result.append(enemy)
	
	return result
#endregion

#region Signal Handlers
## Called when an enemy dies
func _on_enemy_died(enemy: Node2D) -> void:
	# Wait a bit for death animation
	await get_tree().create_timer(0.5).timeout
	
	# Destroy enemy
	destroy_enemy(enemy)
#endregion

#region Cleanup
func _exit_tree() -> void:
	destroy_all_enemies()
#endregion

#region Debug
func print_pool_status() -> void:
	print("=== Enemy Factory Pool Status ===")
	print("Active enemies: %d" % _active_enemies.size())
	
	for type in _pools:
		var pool = _pools[type]
		var inactive_count = 0
		for enemy in pool:
			if not enemy.visible:
				inactive_count += 1
		
		print("%s: %d total, %d available" % [
			EnemyType.keys()[type],
			pool.size(),
			inactive_count
		])
	
	print("================================")
#endregion
