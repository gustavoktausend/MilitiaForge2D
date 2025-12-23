## Projectile Pool Manager
##
## Manages object pools for different projectile types.
## Centralizes projectile spawning to improve performance.
##
## Usage (as Autoload):
##   var projectile = ProjectilePoolManager.spawn_projectile(
##       "player_laser",
##       position,
##       direction,
##       speed,
##       damage
##   )
##
## Benefits:
## - Up to 10x faster projectile spawning
## - Eliminates GC spikes from mass destruction
## - Automatic cleanup when projectiles leave screen

extends Node

#region Pool Configuration
## Registry of projectile pools by type
var _pools: Dictionary = {}

## Projectile scenes by type
var _projectile_scenes: Dictionary = {
	"player_laser": "res://examples/space_shooter/scenes/projectile.tscn",
	"enemy_laser": "res://examples/space_shooter/scenes/projectile.tscn",
}

## Pool sizes by type (adjust based on gameplay)
var _pool_sizes: Dictionary = {
	"player_laser": {"initial": 30, "max": 100},
	"enemy_laser": {"initial": 50, "max": 200},
}
#endregion

#region Container
## Container for pooled projectiles
var projectiles_container: Node = null
#endregion

#region Lifecycle
func _ready() -> void:
	print("[ProjectilePoolManager] Initializing...")

	# Find or create projectiles container
	_setup_container()

	# Initialize pools for each projectile type
	_initialize_pools()

	print("[ProjectilePoolManager] ✅ Ready!")

func _setup_container() -> void:
	# Try to find existing container
	var containers = get_tree().get_nodes_in_group("projectiles_container")
	if containers.size() > 0:
		projectiles_container = containers[0]
		print("[ProjectilePoolManager] Found existing container: %s" % projectiles_container.name)
	else:
		# Create new container
		projectiles_container = Node.new()
		projectiles_container.name = "ProjectilesContainer"
		projectiles_container.add_to_group("projectiles_container")
		get_tree().root.add_child(projectiles_container)
		print("[ProjectilePoolManager] Created new container")

func _initialize_pools() -> void:
	for projectile_type in _projectile_scenes.keys():
		var scene_path = _projectile_scenes[projectile_type]
		var scene = load(scene_path) as PackedScene

		if not scene:
			push_error("[ProjectilePoolManager] Failed to load scene: %s" % scene_path)
			continue

		# Get pool size configuration
		var size_config = _pool_sizes.get(projectile_type, {"initial": 20, "max": 100})

		# Create pool
		var pool = ObjectPool.new(scene, size_config["initial"], size_config["max"])
		pool.initialize(projectiles_container)

		_pools[projectile_type] = pool

		print("[ProjectilePoolManager] Created pool for '%s' (initial: %d, max: %d)" % [
			projectile_type,
			size_config["initial"],
			size_config["max"]
		])

func _exit_tree() -> void:
	# Cleanup all pools
	for pool in _pools.values():
		pool.cleanup()
	_pools.clear()
#endregion

#region Public API
## Spawn a projectile from the pool
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
	if not _pools.has(projectile_type):
		push_error("[ProjectilePoolManager] Unknown projectile type: %s" % projectile_type)
		return null

	var pool: ObjectPool = _pools[projectile_type]
	var projectile = pool.acquire() as Node2D

	if not projectile:
		push_error("[ProjectilePoolManager] Failed to acquire projectile from pool!")
		return null

	# Configure projectile
	projectile.global_position = position

	if projectile.has_method("set_direction"):
		projectile.set_direction(direction)

	projectile.speed = speed
	projectile.damage = damage
	projectile.is_player_projectile = is_player_projectile

	# Mark as using pooling so it returns via signal instead of queue_free
	if "use_pooling" in projectile:
		projectile.use_pooling = true

	# Connect to projectile's despawned signal to return to pool
	if projectile.has_signal("despawned"):
		# Disconnect old connections to prevent duplicates
		if projectile.despawned.is_connected(_on_projectile_despawned):
			projectile.despawned.disconnect(_on_projectile_despawned)
		# Connect with projectile_type bound
		projectile.despawned.connect(_on_projectile_despawned.bind(projectile_type))

	return projectile

## Manually return a projectile to the pool
##
## @param projectile: The projectile to return
## @param projectile_type: Type of projectile
func return_projectile(projectile: Node2D, projectile_type: String) -> void:
	if not _pools.has(projectile_type):
		push_warning("[ProjectilePoolManager] Unknown projectile type: %s" % projectile_type)
		return

	var pool: ObjectPool = _pools[projectile_type]
	pool.release(projectile)

## Get pool statistics for debugging
func get_pool_stats(projectile_type: String) -> Dictionary:
	if not _pools.has(projectile_type):
		return {}

	var pool: ObjectPool = _pools[projectile_type]
	return pool.get_stats()

## Print statistics for all pools
func debug_print_all_stats() -> void:
	print("=== Projectile Pool Statistics ===")
	for projectile_type in _pools.keys():
		var pool: ObjectPool = _pools[projectile_type]
		var stats = pool.get_stats()
		print("[%s] Available: %d | Active: %d | Total: %d/%d" % [
			projectile_type,
			stats["available"],
			stats["active"],
			stats["total"],
			stats["max_size"]
		])
	print("==================================")
#endregion

#region Signal Handlers
## Called when projectile is destroyed (leaves scene tree)
func _on_projectile_destroyed(projectile: Node2D, projectile_type: String) -> void:
	return_projectile(projectile, projectile_type)

## Called when projectile signals it should despawn
func _on_projectile_despawned(projectile: Node2D, projectile_type: String) -> void:
	return_projectile(projectile, projectile_type)
#endregion
