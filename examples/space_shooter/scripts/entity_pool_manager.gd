## Entity Pool Manager
##
## Manages object pools for different entity types (projectiles, enemies, powerups, etc.).
## Centralizes entity spawning to improve performance.
##
## Usage (as Autoload):
##   var projectile = EntityPoolManager.spawn_entity(
##       "player_laser",
##       {"position": pos, "direction": dir, "speed": 600, "damage": 10}
##   )
##   var enemy = EntityPoolManager.spawn_entity(
##       "enemy_basic",
##       {"position": pos, "target": player}
##   )
##
## Benefits:
## - Up to 10x faster entity spawning
## - Eliminates GC spikes from mass destruction
## - Automatic cleanup when entities leave screen/die
##
## @tutorial(Object Pooling): res://examples/space_shooter/OBJECT_POOLING_SETUP.md

extends Node

#region Pool Configuration
## Registry of entity pools by type
var _pools: Dictionary = {}

## Flag to indicate if pools are ready
var _is_ready: bool = false

## Entity scenes by type
var _entity_scenes: Dictionary = {
	# Projectiles
	"player_laser": "res://examples/space_shooter/scenes/projectile.tscn",
	"enemy_laser": "res://examples/space_shooter/scenes/projectile.tscn",

	# Enemies
	"enemy_basic": "res://examples/space_shooter/scenes/enemy_basic.tscn",
	"enemy_fast": "res://examples/space_shooter/scenes/enemy_fast.tscn",
	"enemy_tank": "res://examples/space_shooter/scenes/enemy_tank.tscn",
}

## Pool sizes by type (adjust based on gameplay)
var _pool_sizes: Dictionary = {
	# Projectiles
	"player_laser": {"initial": 10, "max": 100},
	"enemy_laser": {"initial": 10, "max": 200},

	# Enemies
	"enemy_basic": {"initial": 5, "max": 100},
	"enemy_fast": {"initial": 5, "max": 80},
	"enemy_tank": {"initial": 2, "max": 30},
}
#endregion

#region Container
## Container for pooled entities
var entities_container: Node = null
#endregion

#region Lifecycle
func _ready() -> void:
	# Find or create entities container
	await _setup_container()

	# Initialize pools for each entity type
	await _initialize_pools()

	# Mark as ready
	_is_ready = true

func _setup_container() -> void:
	# Try to find existing container
	var containers = get_tree().get_nodes_in_group("entities_container")
	if containers.size() > 0:
		entities_container = containers[0]
	else:
		# Create new container as child of this autoload (which is already in tree)
		entities_container = Node.new()
		entities_container.name = "EntitiesContainer"
		entities_container.add_to_group("entities_container")
		add_child(entities_container)

func _initialize_pools() -> void:
	for entity_type in _entity_scenes.keys():
		var scene_path = _entity_scenes[entity_type]
		var scene = load(scene_path) as PackedScene

		if not scene:
			push_error("[EntityPoolManager] Failed to load scene: %s" % scene_path)
			continue

		# Get pool size configuration
		var size_config = _pool_sizes.get(entity_type, {"initial": 20, "max": 100})

		# Create pool
		var pool = ObjectPool.new(scene, size_config["initial"], size_config["max"])
		await pool.initialize(entities_container)

		_pools[entity_type] = pool

func _exit_tree() -> void:
	# Cleanup all pools
	for pool in _pools.values():
		pool.cleanup()
	_pools.clear()
#endregion

#region Public API - Generic Entity Spawning
## Spawn an entity from the pool (generic method)
##
## @param entity_type: Type of entity ("player_laser", "enemy_basic", etc.)
## @param config: Dictionary with entity-specific configuration
## Returns: The spawned entity, or null if failed
func spawn_entity(entity_type: String, config: Dictionary) -> Node:
	# Check if pools are ready (don't wait - prevent deadlock!)
	if not _is_ready:
		push_warning("[EntityPoolManager] ⚠️ Pools not ready yet! Cannot spawn '%s' during initialization" % entity_type)
		return null

	if not _pools.has(entity_type):
		push_warning("[EntityPoolManager] Unknown entity type: '%s'" % entity_type)
		return null

	var pool: ObjectPool = _pools[entity_type]
	var entity = await pool.acquire()

	if not entity:
		push_error("[EntityPoolManager] Failed to acquire entity from pool!")
		return null

	# Configure entity based on type
	# Check for projectiles first (both player and enemy lasers)
	if entity_type.ends_with("laser") or entity_type.contains("projectile"):
		_configure_projectile(entity, config)
	elif entity_type.begins_with("enemy_"):
		_configure_enemy(entity, config)
	else:
		_configure_projectile(entity, config)

	# Mark as using pooling
	if "use_pooling" in entity:
		entity.use_pooling = true

	# Connect to entity's despawned signal to return to pool
	if entity.has_signal("despawned"):
		# Disconnect old connections to prevent duplicates
		if entity.despawned.is_connected(_on_entity_despawned):
			entity.despawned.disconnect(_on_entity_despawned)
		# Connect with entity_type bound
		entity.despawned.connect(_on_entity_despawned.bind(entity_type))

	return entity

## Spawn a projectile from the pool (backward compatible)
##
## @param projectile_type: Type of projectile ("player_laser", "enemy_laser")
## @param position: Spawn position
## @param direction: Direction to move (normalized)
## @param speed: Movement speed
## @param damage: Damage amount
## @param is_player_projectile: Whether this is from player (for collision layers)
## Returns: The spawned projectile, or null if failed
func spawn_projectile(
	projectile_type: String,
	position: Vector2,
	direction: Vector2,
	speed: float,
	damage: int,
	is_player_projectile: bool = true,
	visual_scale: float = 1.0
) -> Node2D:
	return await spawn_entity(projectile_type, {
		"position": position,
		"direction": direction,
		"speed": speed,
		"damage": damage,
		"is_player_projectile": is_player_projectile,
		"visual_scale": visual_scale
	})

## Spawn an enemy from the pool (NEW!)
##
## @param enemy_type: Type of enemy ("enemy_basic", "enemy_fast", "enemy_tank")
## @param position: Spawn position
## @param target: Target node (usually player)
## Returns: The spawned enemy, or null if failed
func spawn_enemy(
	enemy_type: String,
	position: Vector2,
	target: Node2D = null
) -> Node2D:
	return await spawn_entity(enemy_type, {
		"position": position,
		"target": target
	})

## Manually return an entity to the pool
##
## @param entity: The entity to return
## @param entity_type: Type of entity
func return_entity(entity: Node, entity_type: String) -> void:
	if not _pools.has(entity_type):
		push_warning("[EntityPoolManager] Unknown entity type: %s" % entity_type)
		return

	var pool: ObjectPool = _pools[entity_type]
	pool.release(entity)

## Get pool statistics for debugging
func get_pool_stats(entity_type: String) -> Dictionary:
	if not _pools.has(entity_type):
		return {}

	var pool: ObjectPool = _pools[entity_type]
	return pool.get_stats()

## Print statistics for all pools
func debug_print_all_stats() -> void:
	print("=== Entity Pool Statistics ===")
	for entity_type in _pools.keys():
		var pool: ObjectPool = _pools[entity_type]
		var stats = pool.get_stats()
		print("[%s] Available: %d | Active: %d | Total: %d/%d" % [
			entity_type,
			stats["available"],
			stats["active"],
			stats["total"],
			stats["max_size"]
		])
	print("==================================")
#endregion

#region Private Configuration Methods
## Configure a projectile entity
func _configure_projectile(projectile: Node2D, config: Dictionary) -> void:
	# Set position
	if config.has("position"):
		projectile.global_position = config["position"]

	# Set direction
	if config.has("direction") and projectile.has_method("set_direction"):
		projectile.set_direction(config["direction"])

	# Set properties
	if config.has("speed"):
		projectile.speed = config["speed"]
	if config.has("damage"):
		projectile.damage = config["damage"]
		# CRITICAL: Update hitbox damage when projectile damage changes
		# This ensures the hitbox deals the correct upgraded damage amount
		if projectile.has_method("update_damage"):
			projectile.update_damage()
	if config.has("is_player_projectile"):
		projectile.is_player_projectile = config["is_player_projectile"]

		# CRITICAL: Update collision layers when is_player_projectile changes
		# This ensures pooled projectiles have correct collision layers
		if projectile.has_method("update_collision_layers"):
			projectile.update_collision_layers()

## Configure an enemy entity
func _configure_enemy(enemy: Node2D, config: Dictionary) -> void:
	# Set position
	if config.has("position"):
		enemy.global_position = config["position"]

	# Set target (dependency injection)
	if config.has("target") and enemy.has_method("set_target"):
		enemy.set_target(config["target"])

	# Additional enemy configuration can be added here
	# (movement pattern, difficulty multiplier, etc.)
#endregion

#region Signal Handlers
## Called when entity signals it should despawn
func _on_entity_despawned(entity: Node, entity_type: String) -> void:
	return_entity(entity, entity_type)
#endregion
