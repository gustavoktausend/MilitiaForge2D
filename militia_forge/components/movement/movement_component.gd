## Movement Component Base
##
## Abstract base class for all movement components.
## Provides common functionality for different movement types.
##
## This component expects the host to have a CharacterBody2D or RigidBody2D.
## Movement components handle velocity calculation and physics integration.
##
## Subclasses implement specific movement types:
## - TopDownMovement: 8-directional free movement
## - PlatformerMovement: Side-scrolling with jumping and gravity
## - GridMovement: Tile-based discrete movement
##
## @tutorial(Movement System): res://docs/components/movement.md

class_name MovementComponent extends Component

#region Signals
## Emitted when movement starts
signal movement_started(direction: Vector2)

## Emitted when movement stops
signal movement_stopped()

## Emitted when velocity changes significantly
signal velocity_changed(new_velocity: Vector2)

## Emitted when the entity changes direction
signal direction_changed(new_direction: Vector2)
#endregion

#region Exports
@export_group("Speed")
## Maximum movement speed
@export var max_speed: float = 200.0

## Acceleration rate (pixels per second squared)
@export var acceleration: float = 1000.0

## Deceleration/friction rate (pixels per second squared)
@export var friction: float = 1000.0

@export_group("Advanced")
## Whether movement is currently enabled
@export var movement_enabled: bool = true

## Whether to emit debug messages
@export var debug_movement: bool = false
#endregion

#region Protected Variables
## Current velocity
var velocity: Vector2 = Vector2.ZERO

## Current movement direction (normalized)
var direction: Vector2 = Vector2.ZERO

## Reference to the physics body (CharacterBody2D or RigidBody2D)
var _physics_body: Node2D = null

## Whether the entity is currently moving
var _is_moving: bool = false

## Last frame's velocity (for change detection)
var _last_velocity: Vector2 = Vector2.ZERO
#endregion

#region Component Lifecycle
func initialize(host_node: ComponentHost) -> void:
	super.initialize(host_node)
	_find_physics_body()

func component_ready() -> void:
	if not _physics_body:
		_emit_error("No CharacterBody2D or RigidBody2D found in host hierarchy")
		disable()

func component_physics_process(delta: float) -> void:
	if not movement_enabled or not _physics_body:
		return
	
	# Calculate velocity (implemented by subclasses)
	_calculate_velocity(delta)
	
	# Apply velocity to physics body
	_apply_velocity()
	
	# Detect state changes
	_update_movement_state()

func cleanup() -> void:
	velocity = Vector2.ZERO
	direction = Vector2.ZERO
	_physics_body = null
	super.cleanup()
#endregion

#region Public Methods
## Set the movement direction (normalized vector expected)
##
## @param new_direction: The direction to move in (will be normalized)
func set_direction(new_direction: Vector2) -> void:
	var normalized = new_direction.normalized() if new_direction.length() > 0 else Vector2.ZERO
	
	if normalized != direction:
		direction = normalized
		direction_changed.emit(direction)
		
		if debug_movement:
			print("[MovementComponent] Direction changed to: %s" % direction)

## Stop all movement immediately
func stop() -> void:
	velocity = Vector2.ZERO
	direction = Vector2.ZERO
	
	if _is_moving:
		_is_moving = false
		movement_stopped.emit()

## Enable movement
func enable_movement() -> void:
	movement_enabled = true

## Disable movement
func disable_movement() -> void:
	movement_enabled = false
	stop()

## Get current velocity
func get_velocity() -> Vector2:
	return velocity

## Get current speed (magnitude of velocity)
func get_speed() -> float:
	return velocity.length()

## Check if currently moving
func is_moving() -> bool:
	return _is_moving

## Get the physics body reference
func get_physics_body() -> Node2D:
	return _physics_body
#endregion

#region Protected Methods (Override in subclasses)
## Calculate velocity based on movement type.
## Must be implemented by subclasses.
##
## @param delta: Physics time step
func _calculate_velocity(_delta: float) -> void:
	push_error("_calculate_velocity must be implemented by subclass")

## Called when movement starts.
## Override to add custom behavior.
func _on_movement_started() -> void:
	pass

## Called when movement stops.
## Override to add custom behavior.
func _on_movement_stopped() -> void:
	pass
#endregion

#region Private Methods
## Find the physics body in the host hierarchy
func _find_physics_body() -> void:
	if not host:
		return

	# Search in host's children (ComponentHost should have physics body as child)
	for child in host.get_children():
		if child is CharacterBody2D or child is RigidBody2D:
			_physics_body = child
			return

	# Search in host's parent
	var parent = host.get_parent()
	if parent and (parent is CharacterBody2D or parent is RigidBody2D):
		_physics_body = parent

## Apply calculated velocity to the physics body
func _apply_velocity() -> void:
	if not _physics_body:
		return
	
	if _physics_body is CharacterBody2D:
		_physics_body.velocity = velocity
		_physics_body.move_and_slide()
	elif _physics_body is RigidBody2D:
		_physics_body.linear_velocity = velocity

## Update movement state and emit signals
func _update_movement_state() -> void:
	var currently_moving = velocity.length() > 1.0  # Small threshold to avoid jitter
	
	# Detect movement start
	if currently_moving and not _is_moving:
		_is_moving = true
		movement_started.emit(direction)
		_on_movement_started()
		
		if debug_movement:
			print("[MovementComponent] Movement started")
	
	# Detect movement stop
	elif not currently_moving and _is_moving:
		_is_moving = false
		movement_stopped.emit()
		_on_movement_stopped()
		
		if debug_movement:
			print("[MovementComponent] Movement stopped")
	
	# Detect significant velocity change
	if _last_velocity.distance_to(velocity) > 10.0:
		velocity_changed.emit(velocity)
		_last_velocity = velocity
#endregion

#region Helper Methods
## Apply friction to velocity
##
## @param delta: Time step
## @param friction_amount: Friction to apply
func _apply_friction(delta: float, friction_amount: float) -> void:
	if velocity.length() > 0:
		var friction_vector = velocity.normalized() * friction_amount * delta
		
		if friction_vector.length() > velocity.length():
			velocity = Vector2.ZERO
		else:
			velocity -= friction_vector

## Accelerate towards a target velocity
##
## @param delta: Time step
## @param target_velocity: The velocity to accelerate towards
## @param accel_amount: Acceleration to apply
func _accelerate_to(delta: float, target_velocity: Vector2, accel_amount: float) -> void:
	velocity = velocity.move_toward(target_velocity, accel_amount * delta)

## Clamp velocity to max speed
func _clamp_velocity() -> void:
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
#endregion

#region Debug Methods
## Get debug information about movement state
func get_debug_info() -> Dictionary:
	return {
		"velocity": velocity,
		"speed": get_speed(),
		"direction": direction,
		"is_moving": _is_moving,
		"movement_enabled": movement_enabled,
		"max_speed": max_speed,
		"has_physics_body": _physics_body != null
	}
#endregion
