## Enemy Factory for Space Shooter
##
## Factory pattern for creating enemy instances with configuration.
## Centralizes enemy creation and makes it easy to add new types.

class_name EnemyFactory extends RefCounted

#region Enemy Type Registry
## Registry of enemy types and their scene paths
static var _enemy_registry: Dictionary = {
	"Basic": "res://examples/space_shooter/scenes/enemy_basic.tscn",
	"Fast": "res://examples/space_shooter/scenes/enemy_fast.tscn",
	"Tank": "res://examples/space_shooter/scenes/enemy_tank.tscn",
}

## Cached PackedScenes for performance
static var _scene_cache: Dictionary = {}
#endregion

#region Public API
## Create an enemy instance with optional property overrides
static func create_enemy(enemy_type: String, config: Dictionary = {}) -> Node2D:
	# Validate enemy type
	if not _enemy_registry.has(enemy_type):
		push_error("[EnemyFactory] Unknown enemy type: %s" % enemy_type)
		return null

	# Get or load scene
	var scene = _get_scene(enemy_type)
	if not scene:
		push_error("[EnemyFactory] Failed to load scene for enemy type: %s" % enemy_type)
		return null

	# Instantiate enemy
	var enemy = scene.instantiate()
	if not enemy:
		push_error("[EnemyFactory] Failed to instantiate enemy: %s" % enemy_type)
		return null

	# Apply configuration overrides
	_apply_config(enemy, config)

	return enemy

## Register a new enemy type
static func register_enemy_type(enemy_type: String, scene_path: String) -> void:
	_enemy_registry[enemy_type] = scene_path
	# Clear cache for this type if it exists
	if _scene_cache.has(enemy_type):
		_scene_cache.erase(enemy_type)
	print("[EnemyFactory] Registered enemy type: %s -> %s" % [enemy_type, scene_path])

## Check if an enemy type is registered
static func has_enemy_type(enemy_type: String) -> bool:
	return _enemy_registry.has(enemy_type)

## Get all registered enemy types
static func get_registered_types() -> Array:
	return _enemy_registry.keys()

## Clear the scene cache (useful for hot-reloading)
static func clear_cache() -> void:
	_scene_cache.clear()
	print("[EnemyFactory] Scene cache cleared")
#endregion

#region Private Methods
## Get scene from cache or load it
static func _get_scene(enemy_type: String) -> PackedScene:
	# Check cache first
	if _scene_cache.has(enemy_type):
		return _scene_cache[enemy_type]

	# Load scene
	var scene_path = _enemy_registry[enemy_type]
	var scene = load(scene_path) as PackedScene

	if scene:
		_scene_cache[enemy_type] = scene

	return scene

## Apply configuration dictionary to enemy instance
static func _apply_config(enemy: Node2D, config: Dictionary) -> void:
	for property in config:
		if property in enemy:
			enemy.set(property, config[property])
		else:
			push_warning("[EnemyFactory] Enemy has no property: %s" % property)
#endregion

#region Presets
## Factory method: Create a basic enemy with custom health
static func create_basic(health_override: int = -1) -> Node2D:
	var config = {}
	if health_override > 0:
		config["health"] = health_override
	return create_enemy("Basic", config)

## Factory method: Create a fast enemy with custom speed
static func create_fast(speed_override: float = -1) -> Node2D:
	var config = {}
	if speed_override > 0:
		config["speed"] = speed_override
	return create_enemy("Fast", config)

## Factory method: Create a tank enemy with custom fire rate
static func create_tank(fire_rate_override: float = -1) -> Node2D:
	var config = {}
	if fire_rate_override > 0:
		config["fire_rate"] = fire_rate_override
	return create_enemy("Tank", config)

## Factory method: Create an enemy from wave data
static func create_from_wave_data(wave_data: Dictionary) -> Node2D:
	if not wave_data.has("type"):
		push_error("[EnemyFactory] Wave data missing 'type' field")
		return null

	var enemy_type = wave_data["type"]
	var config = {
		"health": wave_data.get("health", 20),
		"speed": wave_data.get("speed", 100.0),
		"score_value": wave_data.get("score", 100),
	}

	return create_enemy(enemy_type, config)
#endregion
