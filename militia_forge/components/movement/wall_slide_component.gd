## Wall Slide Component
##
## Enables wall sliding and wall jumping mechanics for platformers.
## Detects walls via raycasts and allows player to slide down walls
## and jump off them.
##
## Features:
## - Wall detection (left and right)
## - Reduced slide speed on walls
## - Wall jump with directional boost
## - Cooldown to prevent instant re-grab
## - Visual feedback hooks (particles, animation)
##
## Depends on: PlatformerMovement component
##
## @tutorial(Movement System): res://docs/components/movement.md

class_name WallSlideComponent extends Component

#region Signals
## Emitted when player starts wall sliding
signal wall_slide_started(wall_normal: Vector2)

## Emitted when player stops wall sliding
signal wall_slide_ended()

## Emitted when player wall jumps
signal wall_jumped(direction: Vector2)
#endregion

#region Exports
@export_group("Wall Detection")
## Distance to check for walls
@export var wall_detection_distance: float = 12.0

## Offset for wall check (from center)
@export var wall_check_offset: Vector2 = Vector2(0, 0)

@export_group("Wall Slide")
## Slide speed when on wall (gravity override)
@export var slide_speed: float = 50.0

## Multiplier for gravity when sliding (0 = no gravity, 1 = normal)
@export var slide_gravity_multiplier: float = 0.2

@export_group("Wall Jump")
## Enable wall jumping
@export var can_wall_jump: bool = true

## Wall jump velocity (horizontal away from wall, vertical up)
@export var wall_jump_velocity: Vector2 = Vector2(300, -400)

## Time after wall jump before can grab wall again (seconds)
@export var wall_jump_cooldown: float = 0.2

## Time after wall jump where horizontal input is reduced (for better arc)
@export var wall_jump_lock_time: float = 0.1

@export_group("Advanced")
## Minimum vertical velocity to start wall slide (prevents sliding upward)
@export var min_slide_velocity: float = 0.0

## Can only wall slide when not grounded
@export var require_airborne: bool = true

@export_group("Debug")
## Show debug raycast lines
@export var debug_wall_check: bool = false

## Print debug messages
@export var debug_wall_slide: bool = false
#endregion

#region Private Variables
## Reference to PlatformerMovement component
var _platformer_movement: PlatformerMovement = null

## Whether currently wall sliding
var _is_wall_sliding: bool = false

## Current wall normal (-1 = left wall, 1 = right wall)
var _wall_normal: int = 0

## Wall jump cooldown timer
var _wall_jump_cooldown_timer: float = 0.0

## Wall jump lock timer (reduces air control temporarily)
var _wall_jump_lock_timer: float = 0.0

## Raycasts for wall detection
var _wall_raycast_left: RayCast2D = null
var _wall_raycast_right: RayCast2D = null
#endregion

#region Component Lifecycle
func initialize(host_node: ComponentHost) -> void:
	super.initialize(host_node)
	
	# Get required PlatformerMovement component
	_platformer_movement = get_sibling_component("PlatformerMovement") as PlatformerMovement
	
	if not _platformer_movement:
		_emit_error("WallSlideComponent requires PlatformerMovement component!")

func component_ready() -> void:
	super.component_ready()
	
	# Setup wall detection
	_setup_wall_detection()
	
	if debug_wall_slide:
		print("[WallSlideComponent] Ready - Detection distance: %.1f" % wall_detection_distance)

func component_physics_process(delta: float) -> void:
	# Update timers
	_update_timers(delta)
	
	# Update wall slide state
	_update_wall_slide_state()
	
	# Apply wall slide physics
	if _is_wall_sliding:
		_apply_wall_slide_physics()

func cleanup() -> void:
	# Clean up raycasts
	if _wall_raycast_left:
		_wall_raycast_left.queue_free()
	if _wall_raycast_right:
		_wall_raycast_right.queue_free()
	
	super.cleanup()
#endregion

#region Wall Detection
## Setup wall detection raycasts
func _setup_wall_detection() -> void:
	# Left wall raycast
	_wall_raycast_left = RayCast2D.new()
	_wall_raycast_left.target_position = Vector2(-wall_detection_distance, 0)
	_wall_raycast_left.position = wall_check_offset
	_wall_raycast_left.enabled = true
	_wall_raycast_left.collision_mask = 1 # World layer
	
	# Right wall raycast
	_wall_raycast_right = RayCast2D.new()
	_wall_raycast_right.target_position = Vector2(wall_detection_distance, 0)
	_wall_raycast_right.position = wall_check_offset
	_wall_raycast_right.enabled = true
	_wall_raycast_right.collision_mask = 1 # World layer
	
	if host:
		host.add_child(_wall_raycast_left)
		host.add_child(_wall_raycast_right)
	
	if debug_wall_check:
		_wall_raycast_left.visible = true
		_wall_raycast_right.visible = true

## Check which wall is being touched
## @returns: -1 for left wall, 1 for right wall, 0 for no wall
func _detect_wall() -> int:
	# Can't detect wall during cooldown
	if _wall_jump_cooldown_timer > 0:
		return 0
	
	# Check if airborne (if required)
	if require_airborne and _platformer_movement and _platformer_movement.is_grounded():
		return 0
	
	# Check left wall
	if _wall_raycast_left and _wall_raycast_left.is_colliding():
		return -1
	
	# Check right wall
	if _wall_raycast_right and _wall_raycast_right.is_colliding():
		return 1
	
	return 0

## Update wall slide state
func _update_wall_slide_state() -> void:
	if not _platformer_movement:
		return
	
	var wall = _detect_wall()
	var was_sliding = _is_wall_sliding
	
	# Start wall slide
	if wall != 0:
		# Check if falling fast enough
		var velocity_y = _platformer_movement.velocity.y
		if velocity_y >= min_slide_velocity:
			_is_wall_sliding = true
			_wall_normal = wall
			
			if not was_sliding:
				wall_slide_started.emit(Vector2(_wall_normal, 0))
				
				if debug_wall_slide:
					var side = "left" if _wall_normal == -1 else "right"
					print("[WallSlideComponent] Started sliding on %s wall" % side)
	else:
		# Stop wall slide
		if _is_wall_sliding:
			_is_wall_sliding = false
			_wall_normal = 0
			wall_slide_ended.emit()
			
			if debug_wall_slide:
				print("[WallSlideComponent] Stopped wall sliding")
#endregion

#region Wall Slide Physics
## Apply wall slide physics
func _apply_wall_slide_physics() -> void:
	if not _platformer_movement:
		return
	
	# Override gravity with slide speed
	var current_velocity = _platformer_movement.velocity
	
	# Clamp vertical velocity to slide speed
	if current_velocity.y > slide_speed:
		_platformer_movement.velocity.y = slide_speed
#endregion

#region Wall Jump
## Attempt wall jump
## @returns: true if wall jump was successful
func wall_jump() -> bool:
	if not can_wall_jump or not _is_wall_sliding:
		return false
	
	if not _platformer_movement:
		return false
	
	# Execute wall jump
	_execute_wall_jump()
	return true

## Execute wall jump
func _execute_wall_jump() -> void:
	# Jump away from wall
	var jump_direction = Vector2(_wall_normal * -1, 0) # Opposite of wall normal
	
	_platformer_movement.velocity.x = wall_jump_velocity.x * jump_direction.x
	_platformer_movement.velocity.y = wall_jump_velocity.y
	
	# Start cooldown
	_wall_jump_cooldown_timer = wall_jump_cooldown
	_wall_jump_lock_timer = wall_jump_lock_time
	
	# Stop wall sliding
	_is_wall_sliding = false
	var old_normal = _wall_normal
	_wall_normal = 0
	
	wall_jumped.emit(jump_direction)
	
	if debug_wall_slide:
		print("[WallSlideComponent] Wall jumped with velocity: %s" % _platformer_movement.velocity)
#endregion

#region Update Methods
## Update timers
func _update_timers(delta: float) -> void:
	if _wall_jump_cooldown_timer > 0:
		_wall_jump_cooldown_timer -= delta
	
	if _wall_jump_lock_timer > 0:
		_wall_jump_lock_timer -= delta
#endregion

#region Public Methods
## Check if currently wall sliding
func is_wall_sliding() -> bool:
	return _is_wall_sliding

## Get current wall normal
## @returns: -1 for left wall, 1 for right wall, 0 for no wall
func get_wall_normal() -> int:
	return _wall_normal if _is_wall_sliding else 0

## Check if wall jump is available
func can_wall_jump_now() -> bool:
	return can_wall_jump and _is_wall_sliding

## Check if in wall jump lock period (reduced air control)
func is_wall_jump_locked() -> bool:
	return _wall_jump_lock_timer > 0

## Get wall jump lock ratio (0-1, 0 = no lock, 1 = full lock)
func get_wall_jump_lock_ratio() -> float:
	if wall_jump_lock_time <= 0:
		return 0.0
	return clampf(_wall_jump_lock_timer / wall_jump_lock_time, 0.0, 1.0)
#endregion

#region Debug Methods
func get_debug_info() -> Dictionary:
	return {
		"is_wall_sliding": _is_wall_sliding,
		"wall_normal": _wall_normal,
		"can_wall_jump": can_wall_jump_now(),
		"jump_cooldown": "%.3fs" % _wall_jump_cooldown_timer,
		"jump_lock": "%.3fs" % _wall_jump_lock_timer
	}
#endregion
