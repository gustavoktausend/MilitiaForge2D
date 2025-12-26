## Weapon Component
##
## Manages weapon firing, projectile spawning, and weapon configurations.
## Supports multiple weapon types, firing patterns, and power-up systems.
##
## Features:
## - Multiple weapon types (single, spread, burst, beam)
## - Configurable fire rate and cooldown
## - Auto-fire support
## - Projectile spawning with patterns
## - Ammo system (optional)
## - Power-up system for weapon upgrades
## - Firing point customization
##
## @tutorial(Combat System): res://docs/components/combat.md

class_name WeaponComponent extends Component

#region Signals
## Emitted when weapon fires
signal weapon_fired(projectile_count: int)

## Emitted when weapon is out of ammo
signal out_of_ammo()

## Emitted when ammo changes
signal ammo_changed(current: int, maximum: int)

## Emitted when weapon is upgraded
signal weapon_upgraded(level: int)
#endregion

#region Enums
## Weapon firing types
enum WeaponType {
	SINGLE,    ## Single projectile
	SPREAD,    ## Multiple projectiles in spread pattern
	BURST,     ## Multiple projectiles in sequence
	BEAM       ## Continuous beam (special handling)
}
#endregion

#region Exports
@export_group("Weapon")
## Projectile scene to spawn
@export var projectile_scene: PackedScene

## Weapon type
@export var weapon_type: WeaponType = WeaponType.SINGLE

## Damage per projectile
@export var damage: int = 10

## Projectile speed
@export var projectile_speed: float = 500.0

@export_group("Fire Rate")
## Time between shots (seconds)
@export var fire_rate: float = 0.2

## Whether weapon fires automatically when fire() is held
@export var auto_fire: bool = false

@export_group("Spread Settings")
## Number of projectiles for SPREAD type
@export var spread_count: int = 3

## Angle between spread projectiles (degrees)
@export var spread_angle: float = 15.0

@export_group("Burst Settings")
## Number of projectiles for BURST type
@export var burst_count: int = 3

## Delay between burst shots (seconds)
@export var burst_delay: float = 0.05

@export_group("Ammo")
## Whether weapon uses ammo
@export var use_ammo: bool = false

## Current ammo count
@export var current_ammo: int = 100

## Maximum ammo capacity
@export var max_ammo: int = 100

## Whether weapon can fire with 0 ammo
@export var infinite_ammo: bool = false

@export_group("Firing Point")
## Offset from host position for projectile spawn
@export var firing_offset: Vector2 = Vector2(0, -20)

## Whether to use a specific firing point node
@export var use_firing_point: bool = false

## Path to firing point node
@export var firing_point_path: NodePath = NodePath()

@export_group("Power-Ups")
## Current weapon level
@export var weapon_level: int = 1

## Maximum weapon level
@export var max_weapon_level: int = 5

@export_group("Advanced")
## Team for projectiles
@export var projectile_team: ProjectileComponent.Team = ProjectileComponent.Team.PLAYER

## Whether to print debug messages
@export var debug_weapon: bool = false

@export_group("Object Pooling")
## Whether to use object pooling for projectiles
@export var use_object_pooling: bool = false

## Pool type identifier (e.g., "player_laser", "enemy_laser")
@export var pooled_projectile_type: String = ""
#endregion

#region Private Variables
## Fire cooldown timer
var _fire_cooldown: float = 0.0

## Burst firing state
var _burst_active: bool = false
var _burst_remaining: int = 0
var _burst_timer: float = 0.0

## Firing point node
var _firing_point: Node2D = null

## Whether weapon is currently trying to fire
var _wants_to_fire: bool = false

## Reference to EntityPoolManager (if using pooling)
var _pool_manager: Node = null

## Container for spawned projectiles (dependency injection)
var _projectiles_container: Node = null
#endregion

#region Component Lifecycle
func initialize(host_node: ComponentHost) -> void:
	super.initialize(host_node)
	
	# Validate projectile scene
	if not projectile_scene:
		push_warning("[WeaponComponent] No projectile scene assigned!")

func component_ready() -> void:
	# Find firing point if specified
	if use_firing_point and not firing_point_path.is_empty():
		_firing_point = get_node_or_null(firing_point_path)

		if not _firing_point:
			push_warning("[WeaponComponent] Firing point not found: %s" % firing_point_path)

	# Setup object pooling if enabled
	if use_object_pooling:
		_setup_pool_manager()

	# Setup projectiles container fallback (can be overridden via set_projectiles_container)
	if not _projectiles_container:
		_setup_projectiles_container()

	if debug_weapon:
		print("[WeaponComponent] Ready - Type: %s, Rate: %.2f, Damage: %d, Pooling: %s" % [
			WeaponType.keys()[weapon_type],
			fire_rate,
			damage,
			use_object_pooling
		])

func component_process(delta: float) -> void:
	# Update cooldowns
	if _fire_cooldown > 0:
		_fire_cooldown -= delta
		if debug_weapon and _fire_cooldown <= 0:
			print("[WeaponComponent] Cooldown reached zero!")

	# Update burst
	if _burst_active:
		_update_burst(delta)

	# Auto-fire
	if auto_fire and _wants_to_fire and _can_fire():
		_execute_fire()

func cleanup() -> void:
	_firing_point = null
	super.cleanup()
#endregion

#region Public Methods - Firing
## Attempt to fire the weapon
##
## @returns: true if weapon fired, false otherwise
func fire() -> bool:
	_wants_to_fire = true

	if not _can_fire():
		if debug_weapon:
			print("[WeaponComponent] fire() called but _can_fire() returned false")
		return false

	if debug_weapon:
		print("[WeaponComponent] fire() - executing!")
	return await _execute_fire()

## Stop firing (for auto-fire)
func stop_fire() -> void:
	_wants_to_fire = false

## Force fire regardless of cooldown (cheat/debug)
func force_fire() -> void:
	_fire_cooldown = 0.0
	await _execute_fire()
#endregion

#region Public Methods - Ammo
## Add ammo
##
## @param amount: Amount to add
## @returns: Actual amount added
func add_ammo(amount: int) -> int:
	if not use_ammo:
		return 0
	
	var old_ammo = current_ammo
	current_ammo = mini(current_ammo + amount, max_ammo)
	var added = current_ammo - old_ammo
	
	if added > 0:
		ammo_changed.emit(current_ammo, max_ammo)
		
		if debug_weapon:
			print("[WeaponComponent] Ammo added: +%d (now %d/%d)" % [added, current_ammo, max_ammo])
	
	return added

## Set ammo to maximum
func refill_ammo() -> void:
	if use_ammo:
		current_ammo = max_ammo
		ammo_changed.emit(current_ammo, max_ammo)

## Check if weapon has ammo
func has_ammo() -> bool:
	if not use_ammo or infinite_ammo:
		return true
	return current_ammo > 0
#endregion

#region Public Methods - Upgrades
## Upgrade weapon to next level
##
## @returns: true if upgraded, false if already max
func upgrade() -> bool:
	if weapon_level >= max_weapon_level:
		return false
	
	weapon_level += 1
	_apply_upgrade()
	weapon_upgraded.emit(weapon_level)
	
	if debug_weapon:
		print("[WeaponComponent] Upgraded to level %d" % weapon_level)
	
	return true

## Set weapon level directly
func set_weapon_level(level: int) -> void:
	weapon_level = clampi(level, 1, max_weapon_level)
	_apply_upgrade()
	weapon_upgraded.emit(weapon_level)
#endregion

#region Public Methods - Queries
## Check if weapon can fire
func can_fire() -> bool:
	return _can_fire()

## Get current cooldown remaining
func get_cooldown_remaining() -> float:
	return maxf(0.0, _fire_cooldown)

## Get cooldown as percentage (0.0 = ready, 1.0 = just fired)
func get_cooldown_percentage() -> float:
	if fire_rate <= 0:
		return 0.0
	return clampf(_fire_cooldown / fire_rate, 0.0, 1.0)
#endregion

#region Public Methods - Configuration
## Set projectiles container (Dependency Injection)
##
## @param container: Node where projectiles will be added as children
func set_projectiles_container(container: Node) -> void:
	_projectiles_container = container
	if debug_weapon:
		print("[WeaponComponent] Projectiles container set: %s" % container.name if container else "null")

## Set pool manager manually (Dependency Injection)
##
## @param pool_manager: EntityPoolManager or ProjectilePoolManager instance
func set_pool_manager(pool_manager: Node) -> void:
	_pool_manager = pool_manager
	if debug_weapon:
		print("[WeaponComponent] Pool manager set: %s" % pool_manager.name if pool_manager else "null")
#endregion

#region Private Methods - Firing
## Check if weapon can fire
func _can_fire() -> bool:
	# Check cooldown
	if _fire_cooldown > 0:
		if debug_weapon:
			print("[WeaponComponent] Cannot fire - cooldown: %.2fs" % _fire_cooldown)
		return false

	# Check burst
	if _burst_active:
		if debug_weapon:
			print("[WeaponComponent] Cannot fire - burst active")
		return false

	# Check ammo
	if not has_ammo():
		if debug_weapon:
			print("[WeaponComponent] Cannot fire - no ammo")
		return false

	# Check if we have EITHER pooling OR projectile scene
	var has_spawn_method = (use_object_pooling and _pool_manager and not pooled_projectile_type.is_empty()) or projectile_scene != null
	if not has_spawn_method:
		if debug_weapon:
			push_warning("[WeaponComponent] Cannot fire - no projectile scene AND pooling not available")
		return false

	return true

## Execute firing
func _execute_fire() -> bool:
	# Consume ammo
	if use_ammo and not infinite_ammo:
		current_ammo -= 1
		ammo_changed.emit(current_ammo, max_ammo)
		
		if current_ammo <= 0:
			out_of_ammo.emit()
	
	# Fire based on type
	var projectile_count = 0

	match weapon_type:
		WeaponType.SINGLE:
			await _fire_single()
			projectile_count = 1

		WeaponType.SPREAD:
			await _fire_spread()
			projectile_count = spread_count

		WeaponType.BURST:
			await _start_burst()
			projectile_count = burst_count

		WeaponType.BEAM:
			await _fire_beam()
			projectile_count = 1
	
	# Set cooldown
	_fire_cooldown = fire_rate
	
	# Emit signal
	weapon_fired.emit(projectile_count)
	
	if debug_weapon:
		print("[WeaponComponent] Fired %s (%d projectiles)" % [
			WeaponType.keys()[weapon_type],
			projectile_count
		])
	
	return true

## Fire single projectile
func _fire_single() -> void:
	await _spawn_projectile(Vector2.UP, 0.0)

## Fire spread pattern
func _fire_spread() -> void:
	var half_spread = (spread_count - 1) / 2.0

	for i in range(spread_count):
		var angle_offset = (i - half_spread) * spread_angle
		await _spawn_projectile(Vector2.UP, angle_offset)

## Start burst firing
func _start_burst() -> void:
	_burst_active = true
	_burst_remaining = burst_count
	_burst_timer = 0.0

	# Fire first shot immediately
	await _fire_burst_shot()

## Update burst firing
func _update_burst(delta: float) -> void:
	_burst_timer -= delta

	if _burst_timer <= 0 and _burst_remaining > 0:
		await _fire_burst_shot()

## Fire single burst shot
func _fire_burst_shot() -> void:
	await _spawn_projectile(Vector2.UP, 0.0)
	_burst_remaining -= 1

	if _burst_remaining > 0:
		_burst_timer = burst_delay
	else:
		_burst_active = false

## Fire beam (placeholder - needs special handling)
func _fire_beam() -> void:
	# Beams need different handling than projectiles
	# For now, just spawn a projectile
	await _spawn_projectile(Vector2.UP, 0.0)
#endregion

#region Private Methods - Spawning
## Spawn a projectile
##
## @param base_direction: Base direction (usually UP for vertical shooter)
## @param angle_offset: Angle offset in degrees
func _spawn_projectile(base_direction: Vector2, angle_offset: float) -> void:
	var spawn_pos = _get_firing_position()
	var direction = base_direction.rotated(deg_to_rad(angle_offset))
	var projectile: Node2D = null

	# Try object pooling first (if enabled)
	if use_object_pooling and _pool_manager and not pooled_projectile_type.is_empty():
		# Check if pool manager has spawn_projectile method (EntityPoolManager or ProjectilePoolManager)
		if _pool_manager.has_method("spawn_projectile"):
			projectile = await _pool_manager.spawn_projectile(
				pooled_projectile_type,
				spawn_pos,
				direction,
				projectile_speed,
				damage,
				projectile_team == ProjectileComponent.Team.PLAYER
			)

			if projectile and debug_weapon:
				print("[WeaponComponent] ✅ Spawned projectile from pool: %s" % pooled_projectile_type)
		elif _pool_manager.has_method("spawn_entity"):
			# EntityPoolManager method
			projectile = await _pool_manager.spawn_entity(pooled_projectile_type, {
				"position": spawn_pos,
				"direction": direction,
				"speed": projectile_speed,
				"damage": damage,
				"team": projectile_team,
				"is_player_projectile": projectile_team == ProjectileComponent.Team.PLAYER
			})

			if projectile and debug_weapon:
				print("[WeaponComponent] ✅ Spawned projectile from pool (entity): %s" % pooled_projectile_type)

	# Fallback to traditional instantiation
	if not projectile:
		if not projectile_scene:
			if debug_weapon:
				push_warning("[WeaponComponent] No projectile scene assigned!")
			return

		projectile = projectile_scene.instantiate()

		# Set projectile properties if it has ProjectileComponent
		var projectile_comp = null
		if projectile.has_node("ComponentHost"):
			var host_comp = projectile.get_node("ComponentHost")
			# Wait for components to initialize
			await get_tree().process_frame
			projectile_comp = host_comp.get_component("ProjectileComponent")

		if projectile_comp:
			projectile_comp.damage = damage
			projectile_comp.speed = projectile_speed
			projectile_comp.direction = direction
			projectile_comp.team = projectile_team

		# Set initial position
		projectile.global_position = spawn_pos

		# Add to scene (use container if available, otherwise root)
		if _projectiles_container:
			_projectiles_container.add_child(projectile)
		else:
			get_tree().root.add_child(projectile)

		if debug_weapon:
			print("[WeaponComponent] ⚠️ Spawned projectile via instantiate() at %s" % spawn_pos)

## Get the position to spawn projectiles
func _get_firing_position() -> Vector2:
	if _firing_point:
		if debug_weapon:
			print("[WeaponComponent] Using firing_point: %s" % _firing_point.global_position)
		return _firing_point.global_position

	if host:
		# Try to find the physics body (CharacterBody2D) first, as it's what actually moves
		var physics_body = host.get_node_or_null("Body")
		if physics_body:
			var pos = physics_body.global_position + firing_offset
			if debug_weapon:
				print("[WeaponComponent] Using physics_body position: %s + offset %s = %s" % [physics_body.global_position, firing_offset, pos])
			return pos

		# Fallback to host position if no physics body found
		var pos = host.global_position + firing_offset
		if debug_weapon:
			print("[WeaponComponent] Using host position: %s + offset %s = %s" % [host.global_position, firing_offset, pos])
		return pos

	if debug_weapon:
		push_error("[WeaponComponent] No host or firing_point! Returning ZERO")
	return Vector2.ZERO

## Setup pool manager (try EntityPoolManager first, then ProjectilePoolManager)
func _setup_pool_manager() -> void:
	# Try new EntityPoolManager first (registered as autoload)
	_pool_manager = get_node_or_null("/root/EntityPoolManager")

	# If not found, try legacy ProjectilePoolManager
	if not _pool_manager:
		_pool_manager = get_node_or_null("/root/ProjectilePoolManager")

	if _pool_manager:
		if debug_weapon:
			print("[WeaponComponent] ✅ Found pool manager: %s" % _pool_manager.name)
	else:
		if debug_weapon:
			push_warning("[WeaponComponent] ⚠️ Pool manager not found - pooling disabled (use_object_pooling=%s)" % use_object_pooling)

## Setup projectiles container (fallback method)
func _setup_projectiles_container() -> void:
	# Look for "ProjectilesContainer" group (note: case-sensitive!)
	var containers = get_tree().get_nodes_in_group("ProjectilesContainer")
	if containers.size() > 0:
		_projectiles_container = containers[0]
		if debug_weapon:
			print("[WeaponComponent] Found projectiles_container via group: %s" % _projectiles_container.name)
	else:
		# Use root as fallback
		_projectiles_container = get_tree().root
		if debug_weapon:
			print("[WeaponComponent] Using root as projectiles_container (fallback)")
#endregion

#region Private Methods - Upgrades
## Apply upgrade effects
func _apply_upgrade() -> void:
	# Example upgrade scaling (customize as needed)
	match weapon_level:
		1:
			# Base stats
			pass
		2:
			damage = int(damage * 1.2)
		3:
			fire_rate *= 0.9  # Faster firing
			damage = int(damage * 1.3)
		4:
			damage = int(damage * 1.5)
			projectile_speed *= 1.2
		5:
			# Max level
			damage = int(damage * 1.8)
			fire_rate *= 0.8
			
			# Could unlock special features
			if weapon_type == WeaponType.SINGLE:
				weapon_type = WeaponType.SPREAD
				spread_count = 2
#endregion

#region Debug
## Get debug information
func get_debug_info() -> Dictionary:
	return {
		"weapon_type": WeaponType.keys()[weapon_type],
		"damage": damage,
		"fire_rate": "%.2fs" % fire_rate,
		"cooldown": "%.2fs" % _fire_cooldown,
		"can_fire": _can_fire(),
		"ammo": "%d/%d" % [current_ammo, max_ammo] if use_ammo else "infinite",
		"level": "%d/%d" % [weapon_level, max_weapon_level],
		"burst_active": _burst_active
	}
#endregion
