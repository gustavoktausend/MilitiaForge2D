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
	print("╔════════════════════════════════════════════════════════╗")
	print("║      EntityPoolManager READY CALLED                   ║")
	print("╚════════════════════════════════════════════════════════╝")
	print("[EntityPoolManager] Initializing...")

	# Find or create entities container
	print("[EntityPoolManager] Step 1: Setting up container...")
	await _setup_container()
	print("[EntityPoolManager] Step 1: Container setup complete!")

	# Initialize pools for each entity type
	print("[EntityPoolManager] Step 2: Initializing pools...")
	await _initialize_pools()
	print("[EntityPoolManager] Step 2: Pools initialization complete!")

	print("[EntityPoolManager] ✅ Ready! Total pools created: %d" % _pools.size())
	print("[EntityPoolManager] Pool types: %s" % str(_pools.keys()))

	# Mark as ready
	_is_ready = true
	print("[EntityPoolManager] 🟢 POOLS ARE NOW READY FOR USE 🟢")

func _setup_container() -> void:
	# Try to find existing container
	var containers = get_tree().get_nodes_in_group("entities_container")
	if containers.size() > 0:
		entities_container = containers[0]
		print("[EntityPoolManager] Found existing container: %s" % entities_container.name)
	else:
		# Create new container as child of this autoload (which is already in tree)
		entities_container = Node.new()
		entities_container.name = "EntitiesContainer"
		entities_container.add_to_group("entities_container")
		add_child(entities_container)
		print("[EntityPoolManager] Created new container as child of EntityPoolManager")

	# Verify container is in tree
	print("[EntityPoolManager] Container in_tree: %s, parent: %s" % [
		entities_container.is_inside_tree(),
		entities_container.get_parent().name if entities_container.get_parent() else "null"
	])

func _initialize_pools() -> void:
	print("[EntityPoolManager] _initialize_pools START - entity types to load: %s" % str(_entity_scenes.keys()))

	for entity_type in _entity_scenes.keys():
		print("[EntityPoolManager] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		print("[EntityPoolManager] Processing entity type: '%s'" % entity_type)

		var scene_path = _entity_scenes[entity_type]
		print("[EntityPoolManager] Loading scene for '%s': %s" % [entity_type, scene_path])
		var scene = load(scene_path) as PackedScene

		if not scene:
			push_error("[EntityPoolManager] ❌ Failed to load scene: %s" % scene_path)
			continue

		# Get pool size configuration
		var size_config = _pool_sizes.get(entity_type, {"initial": 20, "max": 100})
		print("[EntityPoolManager] Size config: initial=%d, max=%d" % [size_config["initial"], size_config["max"]])

		# Create pool
		print("[EntityPoolManager] Creating ObjectPool...")
		var pool = ObjectPool.new(scene, size_config["initial"], size_config["max"])
		print("[EntityPoolManager] ObjectPool created: %s" % ("valid" if pool else "null"))
		print("[EntityPoolManager] Calling pool.initialize(entities_container)...")
		print("[EntityPoolManager] entities_container = %s" % (entities_container.name if entities_container else "null"))
		await pool.initialize(entities_container)
		print("[EntityPoolManager] pool.initialize() RETURNED!")

		_pools[entity_type] = pool

		print("[EntityPoolManager] ✅ Created pool for '%s' (initial: %d, max: %d)" % [
			entity_type,
			size_config["initial"],
			size_config["max"]
		])

	print("[EntityPoolManager] _initialize_pools COMPLETE - pools created: %s" % str(_pools.keys()))

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
		push_warning("[EntityPoolManager] ⚠️ Unknown entity type: '%s' (available: %s)" % [entity_type, _pools.keys()])
		return null

	print("[EntityPoolManager] Getting pool for '%s'..." % entity_type)
	var pool: ObjectPool = _pools[entity_type]
	print("[EntityPoolManager] Pool found, calling acquire()...")
	var entity = await pool.acquire()
	print("[EntityPoolManager] acquire() returned: %s" % ("valid entity" if entity else "null"))

	if not entity:
		push_error("[EntityPoolManager] ❌ Failed to acquire entity from pool!")
		return null

	print("[EntityPoolManager] ✅ Acquired '%s' from pool" % entity_type)

	# Configure entity based on type
	# Check for projectiles first (both player and enemy lasers)
	print("[EntityPoolManager] DEBUG: Checking entity type '%s' - ends_with('laser'): %s, contains('projectile'): %s, begins_with('enemy_'): %s" % [
		entity_type,
		entity_type.ends_with("laser"),
		entity_type.contains("projectile"),
		entity_type.begins_with("enemy_")
	])

	if entity_type.ends_with("laser") or entity_type.contains("projectile"):
		print("[EntityPoolManager] → Calling _configure_projectile()")
		_configure_projectile(entity, config)
	elif entity_type.begins_with("enemy_"):
		print("[EntityPoolManager] → Calling _configure_enemy()")
		_configure_enemy(entity, config)
	else:
		print("[EntityPoolManager] → Default: Calling _configure_projectile()")
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
	is_player_projectile: bool = true
) -> Node2D:
	return await spawn_entity(projectile_type, {
		"position": position,
		"direction": direction,
		"speed": speed,
		"damage": damage,
		"is_player_projectile": is_player_projectile
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
	print("[EntityPoolManager] _configure_projectile START - current is_player_projectile: %s" % projectile.is_player_projectile)

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
	if config.has("is_player_projectile"):
		print("[EntityPoolManager] Setting is_player_projectile from %s to %s" % [
			projectile.is_player_projectile, config["is_player_projectile"]
		])
		projectile.is_player_projectile = config["is_player_projectile"]

		# CRITICAL: Update collision layers when is_player_projectile changes
		# This ensures pooled projectiles have correct collision layers
		if projectile.has_method("update_collision_layers"):
			print("[EntityPoolManager] Calling update_collision_layers()...")
			projectile.update_collision_layers()
		else:
			push_error("[EntityPoolManager] ❌ Projectile doesn't have update_collision_layers() method!")

	print("[EntityPoolManager] _configure_projectile END - final is_player_projectile: %s" % projectile.is_player_projectile)

## Configure an enemy entity
func _configure_enemy(enemy: Node2D, config: Dictionary) -> void:
	print("[EntityPoolManager] Configuring enemy - has physics_body: %s, visible: %s, process_mode: %s" % [
		"physics_body" in enemy and enemy.physics_body != null,
		enemy.visible,
		enemy.process_mode
	])

	# Set position
	if config.has("position"):
		enemy.global_position = config["position"]
		print("[EntityPoolManager] Set enemy position to: %s" % config["position"])

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
