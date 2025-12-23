## PathFollowMovement Component
##
## specific movement type that follows a Path2D.
## Requires the host entity to be a child of a PathFollow2D node.
##
## @tutorial(Movement System): res://docs/components/movement.md

class_name PathFollowMovement extends MovementComponent

#region Enums
enum LoopType {
	LOOP, ## Restarts from beginning when end reached
	PING_PONG, ## Reverses direction when end reached
	ONE_SHOT ## Stops when end reached
}
#endregion

#region Exports
@export_group("Path Following")
## Type of path looping behavior
@export var loop_type: LoopType = LoopType.LOOP

## Whether to rotate the entity to follow the path curve
@export var rotate_to_path: bool = true

## Random start progress range (0.0 to 1.0)
## If max > min, a random starting position will be chosen
@export var random_start_min: float = 0.0
@export var random_start_max: float = 0.0
#endregion

#region Private Variables
var _path_follow: PathFollow2D = null
var _moving_forward: bool = true
#endregion

#region Component Lifecycle
func component_ready() -> void:
	super.component_ready()
	
	# Find PathFollow2D parent (search up to 2 levels: parent -> grandparent)
	var parent = host.get_parent()
	if parent is PathFollow2D:
		_path_follow = parent
	elif parent.get_parent() is PathFollow2D:
		_path_follow = parent.get_parent()
		
	if _path_follow:
		_path_follow.rotates = rotate_to_path
		_path_follow.loop = false # We handle looping manually to support types
		
		# Apply random start
		if random_start_max > random_start_min:
			var ratio = randf_range(random_start_min, random_start_max)
			_path_follow.progress_ratio = ratio
	else:
		_emit_error("PathFollowMovement requires an ancestor to be PathFollow2D")
		disable()

func _update_movement_state() -> void:
	# Override to calculate velocity based on path movement
	# Since we move the parent, the local velocity is zero, 
	# but we can simulate velocity for visuals/logic
	if _is_moving:
		# Just use the forward vector of the path rotation times speed
		direction = Vector2.RIGHT.rotated(host.global_rotation)
		velocity = direction * get_speed()
	else:
		velocity = Vector2.ZERO
	
	super._update_movement_state()
#endregion

#region Protected Methods
## Calculate velocity (or in this case, update path progress)
func _calculate_velocity(delta: float) -> void:
	if not _path_follow:
		return
		
	var move_amount = max_speed * delta * (1.0 if _moving_forward else -1.0)
	var old_progress = _path_follow.progress
	
	_path_follow.progress += move_amount
	var new_progress = _path_follow.progress
	
	# Check limits based on loop type
	if loop_type == LoopType.LOOP:
		if _path_follow.progress_ratio >= 1.0:
			_path_follow.progress_ratio = 0.0
			
	elif loop_type == LoopType.PING_PONG:
		if _path_follow.progress_ratio >= 1.0:
			_path_follow.progress_ratio = 1.0
			_moving_forward = false
		elif _path_follow.progress_ratio <= 0.0:
			_path_follow.progress_ratio = 0.0
			_moving_forward = true
			
	elif loop_type == LoopType.ONE_SHOT:
		if _path_follow.progress_ratio >= 1.0:
			_path_follow.progress_ratio = 1.0
			stop()

## Override apply velocity to do nothing, as we moved the PathFollow2D directly
func _apply_velocity() -> void:
	pass
#endregion
