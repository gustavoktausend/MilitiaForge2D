## Charge Shot Component
##
## Weapon system with charge-based damage scaling. Hold button to charge,
## release to fire. Perfect for Mega Man-style games.
##
## Features:
## - 3 charge levels (normal, half charge, full charge)
## - Visual/audio feedback per level
## - Damage scaling by charge level
## - Different projectiles per level
## - Charge time Configurable
## - Auto-fire prevention while charging
##
## Extends: WeaponComponent
##
## @tutorial(Combat System): res://docs/components/combat.md

class_name ChargeShotComponent extends Component

#region Signals
## Emitted when charging starts
signal charge_started()

## Emitted when charge level up (level: 0=normal, 1=half, 2=full)
signal charge_level_reached(level: int)

## Emitted when charge shot is fired (level: charge level)
signal charge_shot_fired(level: int, projectile: Node2D)

## Emitted when charge is cancelled
signal charge_cancelled()
#endregion

#region Charge Levels
enum ChargeLevel {
	NORMAL = 0, ## No charge - standard shot
	HALF = 1, ## Half charge - medium power
	FULL = 2 ## Full charge - maximum power
}
#endregion

#region Exports
@export_group("Projectile Scenes")
## Projectile for normal shot (no charge)
@export var projectile_normal: PackedScene

## Projectile for half charge
@export var projectile_half_charge: PackedScene

## Projectile for full charge
@export var projectile_full_charge: PackedScene

@export_group("Charge Timing")
## Time to reach half charge (seconds)
@export var charge_time_half: float = 0.5

## Time to reach full charge (seconds)
@export var charge_time_full: float = 1.5

@export_group("Damage")
## Damage for normal shot
@export var damage_normal: int = 10

## Damage for half charge
@export var damage_half: int = 20

## Damage for full charge
@export var damage_full: int = 40

@export_group("Fire Rate")
## Cooldown after normal shot (seconds)
@export var fire_rate_normal: float = 0.15

## Cooldown after charged shot (seconds)
@export var fire_rate_charged: float = 0.3

@export_group("Projectile Settings")
## Speed for normal projectile
@export var speed_normal: float = 400.0

## Speed for charged projectiles
@export var speed_charged: float = 500.0

## Direction offset for firing (from host position)
@export var firing_offset: Vector2 = Vector2(20, 0)

## Node path to firing point (optional, overrides offset)
@export var firing_point_path: NodePath = NodePath()

@export_group("Advanced")
## Can move while charging
@export var can_move_while_charging: bool = true

## Auto-release at full charge
@export var auto_release_full_charge: bool = false

## Team for projectiles
@export var projectile_team: int = 0 # 0 = player, 1 = enemy

@export_group("Debug")
## Print debug messages
@export var debug_charge: bool = false
#endregion

#region Private Variables
## Whether currently charging
var _is_charging: bool = false

## Current charge time
var _charge_time: float = 0.0

## Current charge level
var _current_charge_level: ChargeLevel = ChargeLevel.NORMAL

## Fire cooldown timer
var _fire_cooldown: float = 0.0

## Firing point node (optional)
var _firing_point: Node2D = null

## Reference to weapon component for compatibility
var _weapon_component = null
#endregion

#region Component Lifecycle
func initialize(host_node: ComponentHost) -> void:
	super.initialize(host_node)
	
	# Try to get WeaponComponent for teamwork
	_weapon_component = get_sibling_component("WeaponComponent")

func component_ready() -> void:
	super.component_ready()
	
	# Get firing point if specified
	if firing_point_path and not firing_point_path.is_empty():
		if host:
			_firing_point = host.get_node_or_null(firing_point_path)
		if not _firing_point:
			push_warning("[ChargeShotComponent] Firing point not found: %s" % firing_point_path)
	
	if debug_charge:
		print("[ChargeShotComponent] Ready - Half: %.2fs, Full: %.2fs" % [
			charge_time_half, charge_time_full
		])

func component_process(delta: float) -> void:
	# Update charging
	if _is_charging:
		_update_charge(delta)
	
	# Update cooldown
	if _fire_cooldown > 0:
		_fire_cooldown -= delta
#endregion

#region Charge System
## Start charging
func start_charge() -> void:
	if _fire_cooldown > 0:
		return
	
	if not _is_charging:
		_is_charging = true
		_charge_time = 0.0
		_current_charge_level = ChargeLevel.NORMAL
		charge_started.emit()
		
		if debug_charge:
			print("[ChargeShotComponent] Charge started")

## Stop charging and fire
func release_charge() -> void:
	if not _is_charging:
		return
	
	# Fire based on charge level
	_fire_charge_shot()
	
	# Reset charge
	_is_charging = false
	_charge_time = 0.0
	_current_charge_level = ChargeLevel.NORMAL

## Cancel charging without firing
func cancel_charge() -> void:
	if _is_charging:
		_is_charging = false
		_charge_time = 0.0
		_current_charge_level = ChargeLevel.NORMAL
		charge_cancelled.emit()
		
		if debug_charge:
			print("[ChargeShotComponent] Charge cancelled")

## Update charge level
func _update_charge(delta: float) -> void:
	_charge_time += delta
	
	# Check charge level transitions
	var old_level = _current_charge_level
	
	if _charge_time >= charge_time_full:
		_current_charge_level = ChargeLevel.FULL
	elif _charge_time >= charge_time_half:
		_current_charge_level = ChargeLevel.HALF
	else:
		_current_charge_level = ChargeLevel.NORMAL
	
	# Emit signal on level up
	if _current_charge_level != old_level:
		charge_level_reached.emit(_current_charge_level)
		
		if debug_charge:
			var level_name = ChargeLevel.keys()[_current_charge_level]
			print("[ChargeShotComponent] Charge level reached: %s" % level_name)
	
	# Auto-release at full charge if enabled
	if auto_release_full_charge and _current_charge_level == ChargeLevel.FULL:
		release_charge()
#endregion

#region Firing
## Fire charge shot
func _fire_charge_shot() -> void:
	# Get projectile scene based on charge level
	var projectile_scene: PackedScene = null
	var damage: int = 0
	var speed: float = 0
	var cooldown: float = 0
	
	match _current_charge_level:
		ChargeLevel.NORMAL:
			projectile_scene = projectile_normal
			damage = damage_normal
			speed = speed_normal
			cooldown = fire_rate_normal
		ChargeLevel.HALF:
			projectile_scene = projectile_half_charge if projectile_half_charge else projectile_normal
			damage = damage_half
			speed = speed_charged
			cooldown = fire_rate_charged
		ChargeLevel.FULL:
			projectile_scene = projectile_full_charge if projectile_full_charge else projectile_normal
			damage = damage_full
			speed = speed_charged
			cooldown = fire_rate_charged
	
	if not projectile_scene:
		push_warning("[ChargeShotComponent] No projectile scene configured for level %d" % _current_charge_level)
		return
	
	# Spawn projectile
	var projectile = _spawn_projectile(projectile_scene, damage, speed)
	
	# Set cooldown
	_fire_cooldown = cooldown
	
	# Emit signal
	charge_shot_fired.emit(_current_charge_level, projectile)
	
	if debug_charge:
		var level_name = ChargeLevel.keys()[_current_charge_level]
		print("[ChargeShotComponent] Fired %s shot - Damage: %d" % [level_name, damage])

## Spawn projectile
func _spawn_projectile(scene: PackedScene, damage: int, speed: float) -> Node2D:
	var projectile = scene.instantiate()
	
	# Position
	var spawn_pos = _get_firing_position()
	projectile.global_position = spawn_pos
	
	# Configure projectile if it has ProjectileComponent
	var projectile_comp = null
	if projectile.has_method("get_component"):
		projectile_comp = projectile.get_component("ProjectileComponent")
	
	if projectile_comp:
		projectile_comp.damage = damage
		projectile_comp.speed = speed
		projectile_comp.team = projectile_team
		# Direction is set based on host facing
		var direction = Vector2.RIGHT if _get_facing_direction() > 0 else Vector2.LEFT
		projectile_comp.direction = direction
	
	# Add to scene
	if host:
		host.get_parent().add_child(projectile)
	
	return projectile

## Get firing position
func _get_firing_position() -> Vector2:
	if _firing_point:
		return _firing_point.global_position
	
	if host:
		var facing = _get_facing_direction()
		var offset = firing_offset * Vector2(facing, 1)
		return host.global_position + offset
	
	return Vector2.ZERO

## Get facing direction (1 = right, -1 = left)
func _get_facing_direction() -> float:
	# Try to get from movement component
	var movement = get_sibling_component("MovementComponent") as MovementComponent
	if movement and movement.direction.x != 0:
		return signf(movement.direction.x)
	
	# Default to right
	return 1.0
#endregion

#region Public Methods
## Check if currently charging
func is_charging() -> bool:
	return _is_charging

## Get current charge level
func get_charge_level() -> ChargeLevel:
	return _current_charge_level if _is_charging else ChargeLevel.NORMAL

## Get charge progress (0-1) for current level
func get_charge_progress() -> float:
	if not _is_charging:
		return 0.0
	
	match _current_charge_level:
		ChargeLevel.NORMAL:
			if charge_time_half > 0:
				return clampf(_charge_time / charge_time_half, 0.0, 1.0)
		ChargeLevel.HALF:
			if charge_time_full > charge_time_half:
				var time_in_level = _charge_time - charge_time_half
				var level_duration = charge_time_full - charge_time_half
				return clampf(time_in_level / level_duration, 0.0, 1.0)
		ChargeLevel.FULL:
			return 1.0
	
	return 0.0

## Check if can fire
func can_fire() -> bool:
	return _fire_cooldown <= 0

## Get cooldown progress (0-1, 0 = ready)
func get_cooldown_progress() -> float:
	var max_cooldown = maxf(fire_rate_normal, fire_rate_charged)
	if max_cooldown <= 0:
		return 0.0
	return clampf(_fire_cooldown / max_cooldown, 0.0, 1.0)
#endregion

#region Debug Methods
func get_debug_info() -> Dictionary:
	return {
		"is_charging": _is_charging,
		"charge_time": "%.3fs" % _charge_time if _is_charging else "N/A",
		"charge_level": ChargeLevel.keys()[_current_charge_level] if _is_charging else "N/A",
		"charge_progress": "%.1f%%" % (get_charge_progress() * 100) if _is_charging else "N/A",
		"fire_cooldown": "%.3fs" % _fire_cooldown if _fire_cooldown > 0 else "ready",
		"can_fire": can_fire()
	}
#endregion
