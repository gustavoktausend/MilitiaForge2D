## Targeting Component
##
## Generic component for managing targeting systems (area, directional, cursor-based).
## Supports target validation, area preview, and multi-target selection.
##
## Features:
## - Multiple targeting modes (single, multi, area, cone, line)
## - Target validation and filtering
## - Area/range preview
## - Cursor-based targeting
## - Target priority system
## - Signal-based communication
##
## @tutorial(Targeting System): res://docs/components/targeting_component.md

class_name TargetingComponent extends Component

#region Enums
enum TargetingMode {
	SINGLE,      ## Single target
	MULTI,       ## Multiple targets (up to max_targets)
	AREA,        ## Area of effect (circle)
	CONE,        ## Cone-shaped area
	LINE,        ## Line/ray
	SELF,        ## Self-target only
	ALL_ENEMIES, ## All valid enemies
	ALL_ALLIES   ## All valid allies
}

enum TargetType {
	ENEMY,   ## Target enemies
	ALLY,    ## Target allies
	ANY,     ## Target anyone
	SELF     ## Only self
}
#endregion

#region Signals
## Emitted when a target is selected
signal target_selected(target: Node)

## Emitted when a target is deselected
signal target_deselected(target: Node)

## Emitted when targeting mode changes
signal targeting_mode_changed(new_mode: TargetingMode)

## Emitted when target validation fails
signal target_invalid(target: Node, reason: String)

## Emitted when all targets are confirmed
signal targets_confirmed(targets: Array[Node])
#endregion

#region Exports
@export_group("Targeting Settings")
## Current targeting mode
@export var targeting_mode: TargetingMode = TargetingMode.SINGLE

## What type of entities can be targeted
@export var target_type: TargetType = TargetType.ENEMY

## Maximum number of targets for MULTI mode
@export var max_targets: int = 3

## Maximum targeting range (0 = infinite)
@export var max_range: float = 500.0

@export_group("Area Settings")
## Radius for AREA targeting
@export var area_radius: float = 100.0

## Angle for CONE targeting (degrees)
@export var cone_angle: float = 90.0

## Length for LINE targeting
@export var line_length: float = 300.0

## Width for LINE targeting
@export var line_width: float = 50.0

@export_group("Validation")
## Whether to require line of sight
@export var require_line_of_sight: bool = false

## Collision mask for line of sight checks
@export var los_collision_mask: int = 1

## Whether dead/disabled entities can be targeted
@export var can_target_dead: bool = false

@export_group("Visual")
## Whether to show targeting preview
@export var show_preview: bool = true

## Preview color for valid targets
@export var valid_target_color: Color = Color(0.0, 1.0, 0.0, 0.3)

## Preview color for invalid targets
@export var invalid_target_color: Color = Color(1.0, 0.0, 0.0, 0.3)

@export_group("Advanced")
## Whether to print debug messages
@export var debug_targeting: bool = false
#endregion

#region Private Variables
## Currently selected targets
var _selected_targets: Array[Node] = []

## Current targeting position (for cursor-based targeting)
var _target_position: Vector2 = Vector2.ZERO

## Entities within targeting range/area
var _valid_targets: Array[Node] = []

## Reference to the entity that owns this targeting component
var _owner_entity: Node = null
#endregion

#region Component Lifecycle
func component_ready() -> void:
	_owner_entity = host

	if debug_targeting:
		print("[TargetingComponent] Ready. Mode: %s, Type: %s" % [
			TargetingMode.keys()[targeting_mode],
			TargetType.keys()[target_type]
		])

func cleanup() -> void:
	clear_targets()
	super.cleanup()
#endregion

#region Public Methods - Target Selection
## Select a target
## @param target: Entity to target
## @returns: true if target was selected
func select_target(target: Node) -> bool:
	# Validate target
	if not is_valid_target(target):
		target_invalid.emit(target, "Invalid target")
		return false

	# Check targeting mode limits
	match targeting_mode:
		TargetingMode.SINGLE:
			# Replace existing target
			clear_targets()
			_selected_targets.append(target)
		TargetingMode.MULTI:
			# Add if not at limit
			if _selected_targets.size() >= max_targets:
				target_invalid.emit(target, "Max targets reached")
				return false
			if target in _selected_targets:
				return false
			_selected_targets.append(target)
		TargetingMode.SELF:
			# Can only target self
			if target != _owner_entity:
				target_invalid.emit(target, "Can only target self")
				return false
			_selected_targets = [target]
		_:
			_selected_targets.append(target)

	target_selected.emit(target)

	if debug_targeting:
		print("[TargetingComponent] Selected target: %s. Total: %d" % [
			target.name, _selected_targets.size()
		])

	return true

## Deselect a target
## @param target: Entity to deselect
## @returns: true if target was deselected
func deselect_target(target: Node) -> bool:
	var index = _selected_targets.find(target)
	if index == -1:
		return false

	_selected_targets.remove_at(index)
	target_deselected.emit(target)

	if debug_targeting:
		print("[TargetingComponent] Deselected target: %s" % target.name)

	return true

## Clear all selected targets
func clear_targets() -> void:
	for target in _selected_targets:
		target_deselected.emit(target)

	_selected_targets.clear()

	if debug_targeting:
		print("[TargetingComponent] Cleared all targets")

## Confirm current target selection
## @returns: Array of confirmed targets
func confirm_targets() -> Array[Node]:
	var confirmed = _selected_targets.duplicate()
	targets_confirmed.emit(confirmed)

	if debug_targeting:
		print("[TargetingComponent] Confirmed %d targets" % confirmed.size())

	return confirmed
#endregion

#region Public Methods - Area Targeting
## Get all valid targets in an area
## @param position: Center position
## @param radius: Area radius (uses area_radius if 0)
## @returns: Array of valid targets in area
func get_targets_in_area(position: Vector2, radius: float = 0.0) -> Array[Node]:
	if radius <= 0.0:
		radius = area_radius

	var targets: Array[Node] = []
	var all_entities = _get_all_potential_targets()

	for entity in all_entities:
		if not is_instance_valid(entity):
			continue

		var entity_pos = _get_entity_position(entity)
		var distance = position.distance_to(entity_pos)

		if distance <= radius and is_valid_target(entity):
			targets.append(entity)

	if debug_targeting:
		print("[TargetingComponent] Found %d targets in area (radius: %.1f)" % [targets.size(), radius])

	return targets

## Get all valid targets in a cone
## @param origin: Cone origin
## @param direction: Cone direction (normalized)
## @param angle_degrees: Cone angle (uses cone_angle if 0)
## @param range: Cone range (uses max_range if 0)
## @returns: Array of valid targets in cone
func get_targets_in_cone(origin: Vector2, direction: Vector2, angle_degrees: float = 0.0, range: float = 0.0) -> Array[Node]:
	if angle_degrees <= 0.0:
		angle_degrees = cone_angle
	if range <= 0.0:
		range = max_range

	var targets: Array[Node] = []
	var all_entities = _get_all_potential_targets()
	var half_angle = deg_to_rad(angle_degrees / 2.0)

	for entity in all_entities:
		if not is_instance_valid(entity):
			continue

		var entity_pos = _get_entity_position(entity)
		var to_entity = entity_pos - origin

		# Check range
		if to_entity.length() > range:
			continue

		# Check angle
		var angle_to_entity = direction.angle_to(to_entity.normalized())
		if abs(angle_to_entity) <= half_angle and is_valid_target(entity):
			targets.append(entity)

	if debug_targeting:
		print("[TargetingComponent] Found %d targets in cone (angle: %.1f°)" % [targets.size(), angle_degrees])

	return targets

## Get all valid targets in a line
## @param origin: Line origin
## @param direction: Line direction (normalized)
## @param length: Line length (uses line_length if 0)
## @param width: Line width (uses line_width if 0)
## @returns: Array of valid targets in line
func get_targets_in_line(origin: Vector2, direction: Vector2, length: float = 0.0, width: float = 0.0) -> Array[Node]:
	if length <= 0.0:
		length = line_length
	if width <= 0.0:
		width = line_width

	var targets: Array[Node] = []
	var all_entities = _get_all_potential_targets()
	var line_end = origin + direction.normalized() * length

	for entity in all_entities:
		if not is_instance_valid(entity):
			continue

		var entity_pos = _get_entity_position(entity)

		# Check if point is within line bounds
		var distance_to_line = _point_to_line_distance(entity_pos, origin, line_end)

		if distance_to_line <= width / 2.0 and is_valid_target(entity):
			targets.append(entity)

	if debug_targeting:
		print("[TargetingComponent] Found %d targets in line" % targets.size())

	return targets
#endregion

#region Public Methods - Validation
## Check if a target is valid
## @param target: Entity to validate
## @returns: true if target is valid
func is_valid_target(target: Node) -> bool:
	if not is_instance_valid(target):
		return false

	# Check if self-targeting only
	if target_type == TargetType.SELF and target != _owner_entity:
		return false

	# Check target type (enemy/ally)
	if not _is_correct_target_type(target):
		return false

	# Check if dead
	if not can_target_dead and _is_entity_dead(target):
		return false

	# Check range
	if max_range > 0.0:
		var distance = _get_distance_to_target(target)
		if distance > max_range:
			return false

	# Check line of sight
	if require_line_of_sight and not _has_line_of_sight(target):
		return false

	return true

## Get distance to a target
## @param target: Target entity
## @returns: Distance in pixels
func get_distance_to_target(target: Node) -> float:
	return _get_distance_to_target(target)

## Check if target is in range
## @param target: Target entity
## @returns: true if in range
func is_in_range(target: Node) -> bool:
	if max_range <= 0.0:
		return true
	return _get_distance_to_target(target) <= max_range
#endregion

#region Public Methods - Getters
## Get currently selected targets
## @returns: Array of selected targets
func get_selected_targets() -> Array[Node]:
	return _selected_targets.duplicate()

## Get first selected target (for SINGLE mode)
## @returns: First target or null
func get_selected_target() -> Node:
	if _selected_targets.is_empty():
		return null
	return _selected_targets[0]

## Get number of selected targets
## @returns: Count of selected targets
func get_selected_count() -> int:
	return _selected_targets.size()

## Check if has selected targets
## @returns: true if any targets selected
func has_selected_targets() -> bool:
	return not _selected_targets.is_empty()

## Get all valid targets currently available
## @returns: Array of valid targets
func get_all_valid_targets() -> Array[Node]:
	var targets: Array[Node] = []
	var all_entities = _get_all_potential_targets()

	for entity in all_entities:
		if is_valid_target(entity):
			targets.append(entity)

	return targets
#endregion

#region Private Methods
## Get all potential targets based on groups/scene
func _get_all_potential_targets() -> Array[Node]:
	var targets: Array[Node] = []

	# Get all nodes in "targetable" group
	targets.append_array(get_tree().get_nodes_in_group("targetable"))

	# Also check "enemies" and "allies" groups
	targets.append_array(get_tree().get_nodes_in_group("enemies"))
	targets.append_array(get_tree().get_nodes_in_group("allies"))

	return targets

## Check if target is correct type (enemy/ally/etc)
func _is_correct_target_type(target: Node) -> bool:
	match target_type:
		TargetType.SELF:
			return target == _owner_entity
		TargetType.ENEMY:
			return target.is_in_group("enemies")
		TargetType.ALLY:
			return target.is_in_group("allies")
		TargetType.ANY:
			return true

	return false

## Check if entity is dead
func _is_entity_dead(entity: Node) -> bool:
	# Try to get HealthComponent
	if entity.has_method("get_component"):
		var health = entity.get_component("HealthComponent")
		if health and health.has_method("is_dead"):
			return health.is_dead()

	# Try direct method
	if entity.has_method("is_dead"):
		return entity.is_dead()

	return false

## Get entity position
func _get_entity_position(entity: Node) -> Vector2:
	if entity is Node2D:
		return entity.global_position
	return Vector2.ZERO

## Get distance to target
func _get_distance_to_target(target: Node) -> float:
	if not _owner_entity is Node2D:
		return INF

	var owner_pos = _owner_entity.global_position
	var target_pos = _get_entity_position(target)
	return owner_pos.distance_to(target_pos)

## Check line of sight to target
func _has_line_of_sight(target: Node) -> bool:
	if not _owner_entity is Node2D:
		return false

	var space_state = _owner_entity.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		_owner_entity.global_position,
		_get_entity_position(target)
	)
	query.collision_mask = los_collision_mask
	query.exclude = [_owner_entity, target]

	var result = space_state.intersect_ray(query)
	return result.is_empty()

## Calculate distance from point to line segment
func _point_to_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	var line_length = line_vec.length()

	if line_length == 0.0:
		return point.distance_to(line_start)

	var t = clampf(point_vec.dot(line_vec) / (line_length * line_length), 0.0, 1.0)
	var projection = line_start + t * line_vec
	return point.distance_to(projection)
#endregion

#region Debug Methods
## Print targeting state
func debug_print_state() -> void:
	print("=== Targeting Component State ===")
	print("Mode: %s" % TargetingMode.keys()[targeting_mode])
	print("Target Type: %s" % TargetType.keys()[target_type])
	print("Selected Targets: %d" % _selected_targets.size())
	for target in _selected_targets:
		print("  - %s" % target.name)
	print("Max Range: %.1f" % max_range)
	print("================================")
#endregion
