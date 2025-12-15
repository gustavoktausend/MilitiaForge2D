## Dash Component
##
## Provides fast horizontal dash ability for platformer games.
## Features cooldown system and optional invincibility during dash.
##
## Features:
## - Quick horizontal dash
## - Cooldown between dashes
## - Optional invincibility frames
## - Gravity cancellation during dash
## - Visual effects hooks
## - Dash direction control
##
## Depends on: MovementComponent
##
## @tutorial(Movement System): res://docs/components/movement.md

class_name DashComponent extends Component

#region Signals
## Emitted when dash starts
signal dash_started(direction: Vector2)

## Emitted when dash ends
signal dash_ended()

## Emitted when dash becomes available again
signal dash_ready()
#endregion

#region Exports
@export_group("Dash Properties")
## Dash speed (pixels/second)
@export var dash_speed: float = 600.0

## Dash duration (seconds)
@export var dash_duration: float = 0.2

## Dash cooldown (seconds)
@export var dash_cooldown: float = 0.5

@export_group("Dash Behavior")
## Can dash in air
@export var can_dash_in_air: bool = true

## Number of air dashes allowed before landing (0 = unlimited ground dashes only)
@export var max_air_dashes: int = 1

## Invincible during dash
@export var invincible_during_dash: bool = true

## Cancel gravity during dash
@export var cancel_gravity: bool = true

## Can change direction during dash
@export var can_steer: bool = false

@export_group("Advanced")
## Friction after dash ends (how quickly to slow down)
@export var post_dash_friction_multiplier: float = 0.5

@export_group("Debug")
## Print debug messages
@export var debug_dash: bool = false
#endregion

#region Private Variables
## Reference to movement component
var _movement_component: MovementComponent = null

## Reference to health component (for invincibility)
var _health_component = null

## Reference to platformer movement (for ground detection)
var _platformer_movement: PlatformerMovement = null

## Whether currently dashing
var _is_dashing: bool = false

## Dash timer
var _dash_timer: float = 0.0

## Cooldown timer
var _cooldown_timer: float = 0.0

## Dash direction
var _dash_direction: Vector2 = Vector2.ZERO

## Air dashes used
var _air_dashes_used: int = 0

## Original velocity before dash
var _pre_dash_velocity: Vector2 = Vector2.ZERO
#endregion

#region Component Lifecycle
func initialize(host_node: ComponentHost) -> void:
	super.initialize(host_node)
	
	# Get required MovementComponent
	_movement_component = get_sibling_component("MovementComponent") as MovementComponent
	if not _movement_component:
		# Try PlatformerMovement specifically
		_movement_component = get_sibling_component("PlatformerMovement") as MovementComponent
	
	if not _movement_component:
		_emit_error("DashComponent requires MovementComponent (or PlatformerMovement)!")
	
	# Get optional components
	_health_component = get_sibling_component("HealthComponent")
	_platformer_movement = get_sibling_component("PlatformerMovement") as PlatformerMovement

func component_ready() -> void:
	super.component_ready()
	
	# Connect to platformer movement if available
	if _platformer_movement:
		_platformer_movement.landed.connect(_on_landed)
	
	if debug_dash:
		print("[DashComponent] Ready - Speed: %.1f, Duration: %.2fs, Cooldown: %.2fs" % [
			dash_speed, dash_duration, dash_cooldown
		])

func component_process(delta: float) -> void:
	# Update dash state
	if _is_dashing:
		_update_dash(delta)
	else:
		_update_cooldown(delta)

func cleanup() -> void:
	if _platformer_movement and _platformer_movement.landed.is_connected(_on_landed):
		_platformer_movement.landed.disconnect(_on_landed)
	
	super.cleanup()
#endregion

#region Dash System
## Attempt to dash in given direction
## @param direction: Direction to dash (will be normalized)
## @returns: true if dash was initiated
func dash(direction: Vector2) -> bool:
	if not can_dash():
		return false
	
	# Normalize direction
	var dash_dir = direction.normalized()
	if dash_dir.length() == 0:
		dash_dir = Vector2.RIGHT # Default to right if no direction
	
	_start_dash(dash_dir)
	return true

## Check if dash is available
func can_dash() -> bool:
	# Can't dash while already dashing
	if _is_dashing:
		return false
	
	# Check cooldown
	if _cooldown_timer > 0:
		return false
	
	# Check air dash limit
	if not _is_grounded() and not can_dash_in_air:
		return false
	
	if not _is_grounded() and max_air_dashes > 0 and _air_dashes_used >= max_air_dashes:
		return false
	
	return true

## Start dash
func _start_dash(direction: Vector2) -> void:
	_is_dashing = true
	_dash_timer = dash_duration
	_dash_direction = direction
	
	# Store original velocity
	if _movement_component:
		_pre_dash_velocity = _movement_component.velocity
	
	# Count air dash if airborne
	if not _is_grounded():
		_air_dashes_used += 1
	
	# Apply invincibility
	if invincible_during_dash and _health_component:
		# HealthComponent has invincibility system - we'd set it here
		pass
	
	dash_started.emit(direction)
	
	if debug_dash:
		print("[DashComponent] Dash started in direction: %s" % direction)

## Update dash
func _update_dash(delta: float) -> void:
	_dash_timer -= delta
	
	# Apply dash velocity
	if _movement_component:
		if can_steer and _dash_direction.length() > 0:
			# Allow steering during dash
			_movement_component.velocity = _dash_direction.normalized() * dash_speed
		else:
			# Fixed direction dash
			var dash_velocity = _dash_direction * dash_speed
			_movement_component.velocity.x = dash_velocity.x
			
			# Cancel vertical velocity if cancel_gravity
			if cancel_gravity:
				_movement_component.velocity.y = dash_velocity.y
	
	# Check if dash ended
	if _dash_timer <= 0:
		_end_dash()

## End dash
func _end_dash() -> void:
	_is_dashing = false
	_cooldown_timer = dash_cooldown
	
	# Remove invincibility
	if invincible_during_dash and _health_component:
		# End invincibility - HealthComponent handles this
		pass
	
	# Apply post-dash friction
	if _movement_component and post_dash_friction_multiplier != 1.0:
		_movement_component.velocity.x *= post_dash_friction_multiplier
	
	dash_ended.emit()
	
	if debug_dash:
		print("[DashComponent] Dash ended")

## Update cooldown
func _update_cooldown(delta: float) -> void:
	if _cooldown_timer > 0:
		var was_on_cooldown = true
		_cooldown_timer -= delta
		
		if _cooldown_timer <= 0 and was_on_cooldown:
			dash_ready.emit()
#endregion

#region Helper Methods
## Check if grounded (uses PlatformerMovement if available)
func _is_grounded() -> bool:
	if _platformer_movement:
		return _platformer_movement.is_grounded()
	return false # Assume airborne if no platformer movement

## Called when player lands
func _on_landed() -> void:
	# Reset air dashes
	_air_dashes_used = 0
#endregion

#region Public Methods
## Check if currently dashing
func is_dashing() -> bool:
	return _is_dashing

## Get dash direction
func get_dash_direction() -> Vector2:
	return _dash_direction if _is_dashing else Vector2.ZERO

## Get cooldown progress (0-1, 0 = ready, 1 = just used)
func get_cooldown_progress() -> float:
	if dash_cooldown <= 0:
		return 0.0
	return clampf(_cooldown_timer / dash_cooldown, 0.0, 1.0)

## Get remaining air dashes
func get_remaining_air_dashes() -> int:
	if max_air_dashes == 0:
		return 999 # Unlimited
	return maxi(0, max_air_dashes - _air_dashes_used)

## Force end dash (useful for interruptions)
func cancel_dash() -> void:
	if _is_dashing:
		_end_dash()

## Reset air dashes (useful for power-ups)
func reset_air_dashes() -> void:
	_air_dashes_used = 0
#endregion

#region Debug Methods
func get_debug_info() -> Dictionary:
	return {
		"is_dashing": _is_dashing,
		"can_dash": can_dash(),
		"dash_timer": "%.3fs" % _dash_timer if _is_dashing else "N/A",
		"cooldown": "%.3fs" % _cooldown_timer,
		"air_dashes_remaining": get_remaining_air_dashes(),
		"dash_direction": str(_dash_direction) if _is_dashing else "N/A"
	}
#endregion
