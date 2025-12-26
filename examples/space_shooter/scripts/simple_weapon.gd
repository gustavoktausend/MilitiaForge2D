## Simple Weapon for Space Shooter
##
## Simplified weapon component that extends WeaponComponent from the core framework.
## Demonstrates how to use the framework's weapon system with custom configurations.
##
## Now properly inherits from WeaponComponent (eliminating 100+ lines of duplication!)

class_name SimpleWeapon extends WeaponComponent

#region Configuration
## Whether this is a player weapon (affects collision layers)
@export var is_player_weapon: bool = true
#endregion

#region Component Lifecycle
func initialize(host_node: ComponentHost) -> void:
	# Set team based on player/enemy (if not already set)
	if projectile_team == ProjectileComponent.Team.PLAYER:
		# Default is already PLAYER, check if we need to change
		if not is_player_weapon:
			projectile_team = ProjectileComponent.Team.ENEMY

	# Set pooled projectile type based on player/enemy (if not already set)
	if pooled_projectile_type.is_empty():
		pooled_projectile_type = "player_laser" if is_player_weapon else "enemy_laser"

	super.initialize(host_node)

func component_ready() -> void:
	super.component_ready()
#endregion

#region Public API (compatibility with old SimpleWeapon interface)
## Fire at specific position and direction (compatibility method)
##
## @param spawn_position: Global position to spawn projectile
## @param fire_direction: Direction to fire
## @returns: true if weapon fired successfully
func fire_at(spawn_position: Vector2, fire_direction: Vector2) -> bool:
	# Check if can fire
	if not _can_fire():
		return false

	# Set cooldown
	_fire_cooldown = fire_rate

	# Spawn projectile directly with custom position and direction
	var projectile: Node2D = null

	# Use object pooling (enemy weapons should have this enabled)
	if use_object_pooling and _pool_manager and not pooled_projectile_type.is_empty():
		if _pool_manager.has_method("spawn_entity"):
			projectile = await _pool_manager.spawn_entity(pooled_projectile_type, {
				"position": spawn_position,
				"direction": fire_direction.normalized(),
				"speed": projectile_speed,
				"damage": damage,
				"is_player_projectile": projectile_team == ProjectileComponent.Team.PLAYER
			})

	if projectile:
		weapon_fired.emit(1)
		return true

	return false

## Setup weapon with projectiles container (Dependency Injection)
##
## @param container: Node where projectiles will be added
func setup_weapon(container: Node) -> void:
	set_projectiles_container(container)

## Stop firing (for auto-fire mode)
func stop_fire_weapon() -> void:
	stop_fire()
#endregion
