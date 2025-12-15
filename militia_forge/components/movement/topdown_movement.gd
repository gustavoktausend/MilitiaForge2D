## Top-Down Movement Component
##
## Implements 8-directional top-down movement with smooth acceleration.
## Perfect for RPGs, twin-stick shooters, and top-down games.
##
## Features:
## - 8-directional movement with diagonal normalization
## - Smooth acceleration and deceleration
## - Optional sprint/dash system
## - Configurable friction
## - Input integration ready
##
## @tutorial(Movement System): res://docs/components/movement.md

class_name TopDownMovement extends MovementComponent

#region Signals
## Emitted when sprint/dash starts
signal sprint_started()

## Emitted when sprint/dash ends
signal sprint_ended()
#endregion

#region Exports
@export_group("Top-Down Settings")
## Whether to normalize diagonal movement (prevents faster diagonal movement)
@export var normalize_diagonal: bool = true

## Input deadzone for analog sticks (0.0 to 1.0)
@export var input_deadzone: float = 0.1

@export_group("Sprint/Dash")
## Whether sprinting is enabled
@export var sprint_enabled: bool = true

## Sprint speed multiplier
@export var sprint_multiplier: float = 1.5

## Sprint acceleration multiplier
@export var sprint_acceleration_multiplier: float = 1.2
#endregion

#region Private Variables
## Whether currently sprinting
var _is_sprinting: bool = false

## Base max speed (for sprint calculation)
var _base_max_speed: float = 0.0

## Base acceleration (for sprint calculation)
var _base_acceleration: float = 0.0
#endregion

#region Component Lifecycle
func component_ready() -> void:
	super.component_ready()
	
	# Store base values for sprint
	_base_max_speed = max_speed
	_base_acceleration = acceleration
	
	if debug_movement:
		print("[TopDownMovement] Component ready - Max Speed: %.1f, Acceleration: %.1f" % [max_speed, acceleration])
#endregion

#region Movement Calculation
func _calculate_velocity(delta: float) -> void:
	# Handle sprinting state
	_update_sprint_state()
	
	# Apply deadzone to direction
	var input_direction = _apply_deadzone(direction)
	
	# Normalize diagonal if enabled
	if normalize_diagonal and input_direction.length() > 1.0:
		input_direction = input_direction.normalized()
	
	# Calculate target velocity
	var target_velocity = input_direction * max_speed
	
	# Apply acceleration or friction
	if input_direction.length() > 0:
		# Accelerate towards target
		_accelerate_to(delta, target_velocity, acceleration)
	else:
		# Apply friction when no input
		_apply_friction(delta, friction)
	
	# Clamp to max speed
	_clamp_velocity()
#endregion

#region Sprint System
## Start sprinting
func start_sprint() -> void:
	if not sprint_enabled or _is_sprinting:
		return
	
	_is_sprinting = true
	
	# Apply sprint multipliers
	max_speed = _base_max_speed * sprint_multiplier
	acceleration = _base_acceleration * sprint_acceleration_multiplier
	
	sprint_started.emit()
	
	if debug_movement:
		print("[TopDownMovement] Sprint started - Speed: %.1f" % max_speed)

## Stop sprinting
func stop_sprint() -> void:
	if not _is_sprinting:
		return
	
	_is_sprinting = false
	
	# Restore base values
	max_speed = _base_max_speed
	acceleration = _base_acceleration
	
	sprint_ended.emit()
	
	if debug_movement:
		print("[TopDownMovement] Sprint ended - Speed: %.1f" % max_speed)

## Toggle sprint on/off
func toggle_sprint() -> void:
	if _is_sprinting:
		stop_sprint()
	else:
		start_sprint()

## Check if currently sprinting
func is_sprinting() -> bool:
	return _is_sprinting
#endregion

#region Public Methods
## Set movement direction from input (handles normalization)
##
## @param input_vector: Raw input vector (e.g., from Input.get_vector())
func set_input_direction(input_vector: Vector2) -> void:
	set_direction(input_vector)

## Move in a specific direction for one frame
##
## Useful for AI or scripted movement
## @param move_direction: Direction to move (will be normalized)
func move_in_direction(move_direction: Vector2) -> void:
	set_direction(move_direction)
#endregion

#region Protected Methods
func _on_movement_started() -> void:
	if debug_movement:
		print("[TopDownMovement] Started moving in direction: %s" % direction)

func _on_movement_stopped() -> void:
	# Auto-stop sprint when movement stops
	if _is_sprinting:
		stop_sprint()
	
	if debug_movement:
		print("[TopDownMovement] Stopped moving")
#endregion

#region Private Methods
## Apply input deadzone to direction
func _apply_deadzone(input_dir: Vector2) -> Vector2:
	if input_dir.length() < input_deadzone:
		return Vector2.ZERO
	return input_dir

## Update sprint state based on movement
func _update_sprint_state() -> void:
	# Auto-stop sprint if not moving
	if _is_sprinting and direction.length() == 0:
		stop_sprint()
#endregion

#region Debug Methods
## Get debug information about current movement state
func get_debug_info() -> Dictionary:
	return {
		"velocity": "%.1f, %.1f" % [velocity.x, velocity.y],
		"speed": "%.1f" % get_speed(),
		"direction": "%.2f, %.2f" % [direction.x, direction.y],
		"is_moving": _is_moving,
		"is_sprinting": _is_sprinting,
		"max_speed": "%.1f" % max_speed,
	}
#endregion
