## Platformer Movement Component
##
## Implements 2D platformer movement with gravity, variable jump height, coyote time,
## and jump buffering. Perfect for platformer games like Mega Man, Celeste, Mario.
##
## Features:
## - Gravity with terminal velocity
## - Variable jump height (hold jump = higher jump)
## - Coyote time (can jump briefly after leaving platform)
## - Jump buffering (press jump before landing)
## - Ground detection via raycasts
## - Optional double jump
## - Configurable jump parameters
##
## @tutorial(Movement System): res://docs/components/movement.md

class_name PlatformerMovement extends MovementComponent

#region Signals
## Emitted when player jumps
signal jumped()

## Emitted when player lands on ground
signal landed()

## Emitted when player leaves ground
signal left_ground()

## Emitted when double jump is used
signal double_jumped()
#endregion

#region Exports
@export_group("Gravity")
## Gravity acceleration (pixels/second²)
@export var gravity: float = 980.0

## Maximum fall speed (pixels/second)
@export var max_fall_speed: float = 500.0

## Gravity multiplier when falling (makes fall feel snappier)
@export var fall_gravity_multiplier: float = 1.5

@export_group("Jump")
## Initial jump velocity (negative = up)
@export var jump_velocity: float = -400.0

## Minimum jump height (when button released early)
@export var min_jump_velocity: float = -200.0

## Jump button release gravity multiplier (for variable jump height)
@export var jump_release_multiplier: float = 0.5

@export_group("Advanced Jump")
## Allow double jump
@export var allow_double_jump: bool = false

## Coyote time duration (seconds) - can jump after leaving platform
@export var coyote_time: float = 0.1

## Jump buffer time (seconds) - can press jump before landing
@export var jump_buffer_time: float = 0.1

@export_group("Ground Detection")
## Distance to check for ground below player
@export var ground_check_distance: float = 10.0

## Offset for ground check raycast (from center)
@export var ground_check_offset: Vector2 = Vector2(0, 0)

@export_group("Air Control")
## Movement acceleration while in air (multiplier of ground acceleration)
@export var air_control: float = 0.8

@export_group("Debug")
## Show debug raycast lines
@export var debug_ground_check: bool = false
#endregion

#region Private Variables
## Whether player is currently on ground
var _is_grounded: bool = false

## Was grounded in previous frame
var _was_grounded: bool = false

## Coyote time remaining
var _coyote_time_remaining: float = 0.0

## Jump buffer remaining
var _jump_buffer_remaining: float = 0.0

## Whether jump button is currently held
var _jump_held: bool = false

## Whether player has double jumped
var _has_double_jumped: bool = false

## Whether player released jump button during current jump
var _jump_released: bool = false

## Ground check raycasts
var _ground_raycasts: Array[RayCast2D] = []
#endregion

#region Component Lifecycle
func component_ready() -> void:
	super.component_ready()
	
	# Create ground detection raycasts
	_setup_ground_detection()
	
	if debug_movement:
		print("[PlatformerMovement] Ready - Gravity: %.1f, Jump: %.1f" % [gravity, jump_velocity])

func component_physics_process(delta: float) -> void:
	# Update ground state
	_update_ground_state()
	
	# Apply gravity
	_apply_gravity(delta)
	
	# Update timers
	_update_timers(delta)
	
	# Apply movement
	super.component_physics_process(delta)
#endregion

#region Movement Calculation
func _calculate_velocity(delta: float) -> void:
	# Horizontal movement (with air control)
	var move_acceleration = acceleration
	var move_friction = friction
	
	if not _is_grounded:
		move_acceleration *= air_control
		move_friction *= air_control
	
	# Calculate horizontal velocity
	if direction.x != 0:
		_accelerate_horizontal(delta, direction.x * max_speed, move_acceleration)
	else:
		_apply_horizontal_friction(delta, move_friction)
	
	# Clamp horizontal velocity
	velocity.x = clampf(velocity.x, -max_speed, max_speed)

## Apply gravity to vertical velocity
func _apply_gravity(delta: float) -> void:
	if not _is_grounded:
		var applied_gravity = gravity
		
		# Increase gravity when falling for snappier feel
		if velocity.y > 0:
			applied_gravity *= fall_gravity_multiplier
		
		# Reduce gravity when releasing jump early (variable jump height)
		if velocity.y < 0 and _jump_released and not _jump_held:
			applied_gravity *= jump_release_multiplier
		
		velocity.y += applied_gravity * delta
		
		# Clamp to terminal velocity
		velocity.y = minf(velocity.y, max_fall_speed)

## Accelerate horizontal velocity
func _accelerate_horizontal(delta: float, target: float, accel: float) -> void:
	velocity.x = move_toward(velocity.x, target, accel * delta)

## Apply horizontal friction
func _apply_horizontal_friction(delta: float, fric: float) -> void:
	velocity.x = move_toward(velocity.x, 0, fric * delta)
#endregion

#region Jump System
## Attempt to jump
## @returns: true if jump was successful
func jump() -> bool:
	# Can jump if grounded or within coyote time
	var can_jump = _is_grounded or _coyote_time_remaining > 0
	
	if can_jump:
		_execute_jump()
		return true
	
	# Try double jump
	if allow_double_jump and not _has_double_jumped and not _is_grounded:
		_execute_double_jump()
		return true
	
	# Buffer the jump for landing
	_jump_buffer_remaining = jump_buffer_time
	return false

## Set jump button held state
func set_jump_held(held: bool) -> void:
	_jump_held = held
	
	# Track when jump is released during a jump
	if not held and velocity.y < 0:
		_jump_released = true

## Execute jump
func _execute_jump() -> void:
	velocity.y = jump_velocity
	_coyote_time_remaining = 0.0
	_jump_buffer_remaining = 0.0
	_jump_released = false
	jumped.emit()
	
	if debug_movement:
		print("[PlatformerMovement] Jumped with velocity: %.1f" % velocity.y)

## Execute double jump
func _execute_double_jump() -> void:
	velocity.y = jump_velocity
	_has_double_jumped = true
	_jump_released = false
	double_jumped.emit()
	
	if debug_movement:
		print("[PlatformerMovement] Double jumped")
#endregion

#region Ground Detection
## Setup ground detection raycasts
func _setup_ground_detection() -> void:
	# Create 3 raycasts for better ground detection
	var offsets = [Vector2(-8, 0), Vector2(0, 0), Vector2(8, 0)]
	
	for offset in offsets:
		var raycast = RayCast2D.new()
		raycast.target_position = Vector2(0, ground_check_distance)
		raycast.position = ground_check_offset + offset
		raycast.enabled = true
		raycast.collision_mask = 1 # World layer
		
		if host:
			host.add_child(raycast)
		
		_ground_raycasts.append(raycast)
	
	if debug_ground_check:
		for raycast in _ground_raycasts:
			raycast.visible = true

## Update ground state
func _update_ground_state() -> void:
	_was_grounded = _is_grounded
	
	# Check if any raycast is colliding
	_is_grounded = false
	for raycast in _ground_raycasts:
		if raycast.is_colliding():
			_is_grounded = true
			break
	
	# Update coyote time
	if _was_grounded and not _is_grounded:
		_coyote_time_remaining = coyote_time
		left_ground.emit()
		
		if debug_movement:
			print("[PlatformerMovement] Left ground - Coyote time active")
	
	# Check for landing
	if not _was_grounded and _is_grounded:
		_on_landed()

## Called when player lands
func _on_landed() -> void:
	_has_double_jumped = false
	_jump_released = false
	
	# Check jump buffer
	if _jump_buffer_remaining > 0:
		_execute_jump()
	else:
		landed.emit()
		
		if debug_movement:
			print("[PlatformerMovement] Landed")
#endregion

#region Update Methods
## Update timers
func _update_timers(delta: float) -> void:
	if _coyote_time_remaining > 0:
		_coyote_time_remaining -= delta
	
	if _jump_buffer_remaining > 0:
		_jump_buffer_remaining -= delta
#endregion

#region Public Methods
## Check if player is grounded
func is_grounded() -> bool:
	return _is_grounded

## Check if player can jump
func can_jump() -> bool:
	return _is_grounded or _coyote_time_remaining > 0 or (allow_double_jump and not _has_double_jumped)

## Get current fall speed
func get_fall_speed() -> float:
	return velocity.y if velocity.y > 0 else 0.0

## Force ground state (useful for moving platforms, etc)
func set_grounded(grounded: bool) -> void:
	_is_grounded = grounded

## Reset double jump (for power-ups, etc)
func reset_double_jump() -> void:
	_has_double_jumped = false
#endregion

#region Debug Methods
func get_debug_info() -> Dictionary:
	return {
		"is_grounded": _is_grounded,
		"velocity_y": "%.1f" % velocity.y,
		"coyote_time": "%.3fs" % _coyote_time_remaining,
		"jump_buffer": "%.3fs" % _jump_buffer_remaining,
		"can_jump": can_jump(),
		"has_double_jumped": _has_double_jumped
	}
#endregion
