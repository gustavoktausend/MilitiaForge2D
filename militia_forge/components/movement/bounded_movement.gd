## Bounded Movement Component
##
## Movement component with screen/area boundary restrictions.
## Perfect for vertical shooters, horizontal scrollers, and arcade games.
##
## Features:
## - Screen bounds restriction with multiple modes
## - Auto-detection of viewport bounds
## - Custom boundary areas
## - Configurable margins/offsets
## - Different boundary behaviors (clamp, bounce, wrap, destroy)
## - Support for scrolling cameras
## - Edge collision signals
##
## @tutorial(Movement System): res://docs/components/movement.md

class_name BoundedMovement extends MovementComponent

#region Signals
## Emitted when entity touches a boundary
signal boundary_touched(edge: BoundaryEdge, position: Vector2)

## Emitted when entity is destroyed by boundary
signal destroyed_by_boundary(edge: BoundaryEdge)
#endregion

#region Enums
## Boundary behavior modes
enum BoundaryMode {
	CLAMP,      ## Stop at boundary (player ship)
	BOUNCE,     ## Bounce off boundary (enemies, power-ups)
	WRAP,       ## Wrap to opposite side (Asteroids-style)
	DESTROY     ## Destroy when leaving bounds (projectiles)
}

## Boundary edges
enum BoundaryEdge {
	NONE,
	TOP,
	BOTTOM,
	LEFT,
	RIGHT
}
#endregion

#region Exports
@export_group("Bounded Movement")
## Boundary behavior mode
@export var boundary_mode: BoundaryMode = BoundaryMode.CLAMP

## Whether to automatically use viewport bounds
@export var use_viewport_bounds: bool = true

## Custom bounds (used if use_viewport_bounds is false)
@export var custom_bounds: Rect2 = Rect2(0, 0, 1280, 720)

## Margin from edges (pixels inward from boundary)
@export var boundary_margin: Vector2 = Vector2(32, 32)

## Bounce factor (0.0 to 1.0, only for BOUNCE mode)
@export_range(0.0, 1.0) var bounce_factor: float = 0.8

## Whether to destroy host node on boundary destroy
@export var destroy_host_on_boundary: bool = true

@export_group("Camera Support")
## Whether to follow camera for bounds calculation
@export var follow_camera: bool = true

## Camera node path (if empty, auto-detects)
@export var camera_path: NodePath = NodePath()
#endregion

#region Private Variables
## Current effective bounds
var _current_bounds: Rect2 = Rect2()

## Camera reference
var _camera: Camera2D = null

## Last edge touched
var _last_edge_touched: BoundaryEdge = BoundaryEdge.NONE

## Whether bounds need recalculation
var _bounds_dirty: bool = true
#endregion

#region Component Lifecycle
func component_ready() -> void:
	super.component_ready()
	
	# Find camera if needed
	if follow_camera:
		_find_camera()
	
	# Calculate initial bounds
	_update_bounds()
	
	if debug_movement:
		print("[BoundedMovement] Ready - Mode: %s, Bounds: %s" % [
			BoundaryMode.keys()[boundary_mode],
			_current_bounds
		])

func component_physics_process(delta: float) -> void:
	# Update bounds if following camera
	if follow_camera and _camera:
		_update_bounds()

	# Calculate velocity (from base class)
	super.component_physics_process(delta)

	# Apply boundary restrictions
	_apply_boundaries()

## Calculate velocity based on direction (simple 8-directional movement)
func _calculate_velocity(delta: float) -> void:
	# Calculate target velocity based on direction
	var target_velocity = direction * max_speed

	# Apply acceleration or friction
	if direction.length() > 0:
		# Accelerate towards target
		_accelerate_to(delta, target_velocity, acceleration)
	else:
		# Apply friction when no input
		_apply_friction(delta, friction)

	# Clamp to max speed
	_clamp_velocity()
#endregion

#region Boundary System
## Apply boundary restrictions based on mode
func _apply_boundaries() -> void:
	if not _physics_body:
		return
	
	var pos = _physics_body.global_position
	var new_pos = pos
	var edge_touched = BoundaryEdge.NONE
	
	match boundary_mode:
		BoundaryMode.CLAMP:
			new_pos = _apply_clamp(pos)
			edge_touched = _detect_edge_touch(pos, new_pos)
			
		BoundaryMode.BOUNCE:
			var result = _apply_bounce(pos)
			new_pos = result.position
			edge_touched = result.edge
			
		BoundaryMode.WRAP:
			new_pos = _apply_wrap(pos)
			edge_touched = _detect_edge_touch(pos, new_pos)
			
		BoundaryMode.DESTROY:
			if _is_outside_bounds(pos):
				edge_touched = _get_outside_edge(pos)
				_destroy_entity(edge_touched)
				return
	
	# Update position if changed
	if new_pos != pos:
		_physics_body.global_position = new_pos
	
	# Emit signal if touched edge
	if edge_touched != BoundaryEdge.NONE and edge_touched != _last_edge_touched:
		boundary_touched.emit(edge_touched, new_pos)
		_last_edge_touched = edge_touched
		
		if debug_movement:
			print("[BoundedMovement] Touched %s edge" % BoundaryEdge.keys()[edge_touched])
	elif edge_touched == BoundaryEdge.NONE:
		_last_edge_touched = BoundaryEdge.NONE

## Clamp position to bounds
func _apply_clamp(pos: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, _current_bounds.position.x, _current_bounds.end.x),
		clampf(pos.y, _current_bounds.position.y, _current_bounds.end.y)
	)

## Apply bounce behavior
func _apply_bounce(pos: Vector2) -> Dictionary:
	var new_pos = pos
	var edge = BoundaryEdge.NONE
	
	# Check horizontal bounds
	if pos.x < _current_bounds.position.x:
		new_pos.x = _current_bounds.position.x
		velocity.x = abs(velocity.x) * bounce_factor
		edge = BoundaryEdge.LEFT
	elif pos.x > _current_bounds.end.x:
		new_pos.x = _current_bounds.end.x
		velocity.x = -abs(velocity.x) * bounce_factor
		edge = BoundaryEdge.RIGHT
	
	# Check vertical bounds
	if pos.y < _current_bounds.position.y:
		new_pos.y = _current_bounds.position.y
		velocity.y = abs(velocity.y) * bounce_factor
		edge = BoundaryEdge.TOP
	elif pos.y > _current_bounds.end.y:
		new_pos.y = _current_bounds.end.y
		velocity.y = -abs(velocity.y) * bounce_factor
		edge = BoundaryEdge.BOTTOM
	
	return { "position": new_pos, "edge": edge }

## Apply wrap-around behavior
func _apply_wrap(pos: Vector2) -> Vector2:
	var new_pos = pos
	
	# Wrap horizontal
	if pos.x < _current_bounds.position.x:
		new_pos.x = _current_bounds.end.x
	elif pos.x > _current_bounds.end.x:
		new_pos.x = _current_bounds.position.x
	
	# Wrap vertical
	if pos.y < _current_bounds.position.y:
		new_pos.y = _current_bounds.end.y
	elif pos.y > _current_bounds.end.y:
		new_pos.y = _current_bounds.position.y
	
	return new_pos

## Check if position is outside bounds
func _is_outside_bounds(pos: Vector2) -> bool:
	return not _current_bounds.has_point(pos)

## Get which edge is outside
func _get_outside_edge(pos: Vector2) -> BoundaryEdge:
	if pos.x < _current_bounds.position.x:
		return BoundaryEdge.LEFT
	if pos.x > _current_bounds.end.x:
		return BoundaryEdge.RIGHT
	if pos.y < _current_bounds.position.y:
		return BoundaryEdge.TOP
	if pos.y > _current_bounds.end.y:
		return BoundaryEdge.BOTTOM
	return BoundaryEdge.NONE

## Detect which edge was touched
func _detect_edge_touch(old_pos: Vector2, new_pos: Vector2) -> BoundaryEdge:
	if new_pos == old_pos:
		return BoundaryEdge.NONE
	
	# Check horizontal edges
	if new_pos.x != old_pos.x:
		if new_pos.x == _current_bounds.position.x:
			return BoundaryEdge.LEFT
		if new_pos.x == _current_bounds.end.x:
			return BoundaryEdge.RIGHT
	
	# Check vertical edges
	if new_pos.y != old_pos.y:
		if new_pos.y == _current_bounds.position.y:
			return BoundaryEdge.TOP
		if new_pos.y == _current_bounds.end.y:
			return BoundaryEdge.BOTTOM
	
	return BoundaryEdge.NONE

## Destroy entity when leaving bounds
func _destroy_entity(edge: BoundaryEdge) -> void:
	destroyed_by_boundary.emit(edge)
	
	if debug_movement:
		print("[BoundedMovement] Destroyed at %s edge" % BoundaryEdge.keys()[edge])
	
	if destroy_host_on_boundary and host:
		host.queue_free()
#endregion

#region Bounds Calculation
## Update current bounds based on settings
func _update_bounds() -> void:
	if use_viewport_bounds:
		_calculate_viewport_bounds()
	else:
		_current_bounds = custom_bounds
	
	# Apply margin
	_current_bounds = _current_bounds.grow_individual(
		-boundary_margin.x,  # left
		-boundary_margin.y,  # top
		-boundary_margin.x,  # right
		-boundary_margin.y   # bottom
	)
	
	_bounds_dirty = false

## Calculate bounds from viewport/camera
func _calculate_viewport_bounds() -> void:
	if _camera:
		# Use camera bounds
		var viewport_size = get_viewport().get_visible_rect().size
		var camera_pos = _camera.get_screen_center_position()
		var zoom = _camera.zoom
		
		var half_size = viewport_size / zoom / 2.0
		
		_current_bounds = Rect2(
			camera_pos - half_size,
			viewport_size / zoom
		)
	else:
		# Use raw viewport
		var viewport_rect = get_viewport().get_visible_rect()
		_current_bounds = viewport_rect

## Force bounds recalculation
func recalculate_bounds() -> void:
	_bounds_dirty = true
	_update_bounds()
#endregion

#region Public Methods
## Set boundary mode
func set_boundary_mode(mode: BoundaryMode) -> void:
	boundary_mode = mode
	
	if debug_movement:
		print("[BoundedMovement] Mode changed to: %s" % BoundaryMode.keys()[mode])

## Set custom bounds
func set_custom_bounds(bounds: Rect2) -> void:
	custom_bounds = bounds
	use_viewport_bounds = false
	recalculate_bounds()

## Get current effective bounds
func get_current_bounds() -> Rect2:
	return _current_bounds

## Check if position is within bounds
func is_within_bounds(pos: Vector2) -> bool:
	return _current_bounds.has_point(pos)

## Get distance to nearest boundary
func get_distance_to_boundary(pos: Vector2) -> float:
	var distances = [
		abs(pos.x - _current_bounds.position.x),      # left
		abs(pos.x - _current_bounds.end.x),           # right
		abs(pos.y - _current_bounds.position.y),      # top
		abs(pos.y - _current_bounds.end.y)            # bottom
	]
	
	return distances.min()
#endregion

#region Private Helpers
## Find camera in scene
func _find_camera() -> void:
	if not camera_path.is_empty():
		_camera = get_node_or_null(camera_path)
		if _camera:
			return
	
	# Auto-detect camera
	# Check if host has camera
	if host and host.has_node("Camera2D"):
		_camera = host.get_node("Camera2D")
		return
	
	# Check physics body
	if _physics_body and _physics_body.has_node("Camera2D"):
		_camera = _physics_body.get_node("Camera2D")
		return
	
	# Search in viewport
	var cameras = get_tree().get_nodes_in_group("camera")
	if cameras.size() > 0:
		_camera = cameras[0]
#endregion

#region Debug
## Get debug information
func get_debug_info() -> Dictionary:
	var base_info = super.get_debug_info()
	
	base_info.merge({
		"boundary_mode": BoundaryMode.keys()[boundary_mode],
		"current_bounds": _current_bounds,
		"within_bounds": is_within_bounds(_physics_body.global_position if _physics_body else Vector2.ZERO),
		"distance_to_boundary": "%.1f" % get_distance_to_boundary(_physics_body.global_position if _physics_body else Vector2.ZERO),
		"last_edge": BoundaryEdge.keys()[_last_edge_touched]
	})
	
	return base_info
#endregion
