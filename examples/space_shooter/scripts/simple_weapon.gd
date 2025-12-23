## Simple Weapon System for Space Shooter
##
## Simplified weapon that spawns projectiles.
## Integrates with player controller.

extends Node

#region Signals
## Emitted when weapon successfully fires a projectile
## Observer Pattern: Allows systems to react to firing (UI, audio, stats, etc.)
signal weapon_fired(projectile: Node2D, direction: Vector2)

## Emitted when fire attempt fails (cooldown, no ammo, etc.)
signal fire_failed(reason: String)
#endregion

#region Exports
@export var projectile_scene: PackedScene
@export var fire_rate: float = 0.2
@export var projectile_speed: float = 600.0
@export var projectile_damage: int = 10
@export var auto_fire: bool = true
@export var is_player_weapon: bool = true  # Determines projectile collision layers
@export var use_object_pooling: bool = true  # Use ProjectilePoolManager if available
@export var pooled_projectile_type: String = "player_laser"  # Type for pool manager
#endregion

#region Private Variables
var fire_cooldown: float = 0.0
var wants_to_fire: bool = false
var projectiles_container: Node = null
var _pool_manager: Node = null  # Reference to ProjectilePoolManager (if available)
#endregion

func _ready() -> void:
	# Container will be injected via setup_weapon() - Dependency Injection pattern
	# Fallback to searching if not injected (for backwards compatibility)
	if not projectiles_container:
		call_deferred("_find_projectiles_container")

	# Try to find ProjectilePoolManager if using object pooling
	if use_object_pooling:
		_pool_manager = get_node_or_null("/root/ProjectilePoolManager")
		if _pool_manager:
			print("[SimpleWeapon] ✅ Found ProjectilePoolManager - using object pooling")
		else:
			print("[SimpleWeapon] ⚠️ ProjectilePoolManager not found - falling back to instantiate()")

## Dependency Injection: Setup weapon with projectiles container
## This decouples SimpleWeapon from scene tree structure
func setup_weapon(container: Node) -> void:
	projectiles_container = container
	print("[SimpleWeapon] Projectiles container injected: %s" % container.name if container else "null")

func _find_projectiles_container() -> void:
	# Fallback method for backwards compatibility
	var containers = get_tree().get_nodes_in_group("projectiles_container")
	if containers.size() > 0:
		projectiles_container = containers[0]
		print("[SimpleWeapon] Found projectiles_container via group search (fallback)")
	else:
		# Use root as last resort
		projectiles_container = get_tree().root
		push_warning("[SimpleWeapon] No projectiles_container found, using root as fallback")

func _process(delta: float) -> void:
	if fire_cooldown > 0:
		fire_cooldown -= delta

	if auto_fire and wants_to_fire and can_fire():
		execute_fire(get_parent().global_position, Vector2.UP)

func fire(position: Vector2, direction: Vector2) -> bool:
	wants_to_fire = true

	if not can_fire():
		if fire_cooldown > 0:
			fire_failed.emit("cooldown")
		elif not projectile_scene:
			fire_failed.emit("no_projectile_scene")
		return false

	return execute_fire(position, direction)

func stop_fire() -> void:
	wants_to_fire = false

func can_fire() -> bool:
	return fire_cooldown <= 0 and projectile_scene != null

func execute_fire(spawn_position: Vector2, direction: Vector2) -> bool:
	var projectile: Node2D = null

	# Try object pooling first (if enabled and available)
	if use_object_pooling and _pool_manager and _pool_manager.has_method("spawn_projectile"):
		projectile = _pool_manager.spawn_projectile(
			pooled_projectile_type,
			spawn_position,
			direction,
			projectile_speed,
			projectile_damage,
			is_player_weapon
		)

		if not projectile:
			push_warning("[SimpleWeapon] Pool spawn failed, falling back to instantiate()")

	# Fallback to traditional instantiation
	if not projectile:
		if not projectile_scene:
			fire_failed.emit("no_projectile_scene")
			return false

		projectile = projectile_scene.instantiate()

		# Set projectile properties
		if projectile.has_method("set_direction"):
			projectile.set_direction(direction)

		projectile.speed = projectile_speed
		projectile.damage = projectile_damage
		projectile.is_player_projectile = is_player_weapon
		projectile.global_position = spawn_position

		# Add to scene
		if projectiles_container:
			projectiles_container.add_child(projectile)
		else:
			get_tree().root.add_child(projectile)

	# Set cooldown
	fire_cooldown = fire_rate

	# Observer Pattern: Emit signal so systems can react to weapon firing
	weapon_fired.emit(projectile, direction)

	return true
