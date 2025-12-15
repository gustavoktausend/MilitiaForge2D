## Scroll Component
##
## Manages automatic scrolling of backgrounds and parallax layers.
## Useful for side-scrollers, vertical shooters, and any game with scrolling backgrounds.
##
## Features:
## - Multi-layer parallax scrolling
## - Auto-scrolling with configurable speed
## - Seamless looping
## - Directional scrolling (vertical, horizontal, both)
## - Speed modulation over time
## - Individual layer control
##
## @tutorial(Environment): res://docs/components/environment.md

class_name ScrollComponent extends Component

#region Signals
## Emitted when scroll completes a full cycle (for looping)
signal scroll_cycle_completed()

## Emitted when scroll speed changes
signal scroll_speed_changed(new_speed: Vector2)
#endregion

#region Enums
## Scroll direction
enum ScrollDirection {
	VERTICAL_DOWN,    ## Scroll downward (vertical shooter)
	VERTICAL_UP,      ## Scroll upward (side-scroller jumping)
	HORIZONTAL_LEFT,  ## Scroll left (side-scroller)
	HORIZONTAL_RIGHT, ## Scroll right
	CUSTOM            ## Custom direction vector
}
#endregion

#region Exports
@export_group("Scroll Settings")
## Scroll direction preset
@export var scroll_direction: ScrollDirection = ScrollDirection.VERTICAL_DOWN

## Custom scroll direction (used if direction is CUSTOM)
@export var custom_direction: Vector2 = Vector2.DOWN

## Base scroll speed (pixels per second)
@export var scroll_speed: float = 100.0

## Whether scrolling is enabled
@export var auto_scroll: bool = true

## Whether to loop seamlessly
@export var loop_seamlessly: bool = true

@export_group("Parallax")
## Whether to use parallax effect
@export var use_parallax: bool = false

## Parallax layers (0 = background, 1 = foreground)
## Higher values scroll faster
@export var parallax_layers: Array[float] = [0.3, 0.6, 1.0]

@export_group("Speed Modulation")
## Whether speed changes over time
@export var modulate_speed: bool = false

## Speed multiplier range (min, max)
@export var speed_multiplier_range: Vector2 = Vector2(0.5, 1.5)

## Speed modulation frequency (seconds for full cycle)
@export var modulation_period: float = 10.0

@export_group("Advanced")
## Whether to print debug messages
@export var debug_scroll: bool = false
#endregion

#region Private Variables
## Current scroll offset
var _scroll_offset: Vector2 = Vector2.ZERO

## Current speed multiplier (for modulation)
var _speed_multiplier: float = 1.0

## Modulation timer
var _modulation_timer: float = 0.0

## Cached direction vector
var _direction: Vector2 = Vector2.DOWN

## Layer nodes (if using parallax)
var _layer_nodes: Array[Node] = []
#endregion

#region Component Lifecycle
func initialize(host_node: ComponentHost) -> void:
	super.initialize(host_node)
	
	# Calculate direction vector
	_update_direction_vector()

func component_ready() -> void:
	# Find layer nodes if using parallax
	if use_parallax:
		_find_layer_nodes()
	
	if debug_scroll:
		print("[ScrollComponent] Ready - Direction: %s, Speed: %.1f px/s" % [
			ScrollDirection.keys()[scroll_direction] if scroll_direction != ScrollDirection.CUSTOM else "CUSTOM",
			scroll_speed
		])

func component_process(delta: float) -> void:
	if not auto_scroll:
		return
	
	# Update speed modulation
	if modulate_speed:
		_update_speed_modulation(delta)
	
	# Calculate scroll amount
	var scroll_amount = _direction * scroll_speed * _speed_multiplier * delta
	
	# Apply scroll
	_scroll_offset += scroll_amount
	
	# Update layers
	if use_parallax and _layer_nodes.size() > 0:
		_update_parallax_layers()
	else:
		_update_single_layer()

func cleanup() -> void:
	_layer_nodes.clear()
	super.cleanup()
#endregion

#region Public Methods - Control
## Start scrolling
func start_scroll() -> void:
	auto_scroll = true
	
	if debug_scroll:
		print("[ScrollComponent] Scroll started")

## Stop scrolling
func stop_scroll() -> void:
	auto_scroll = false
	
	if debug_scroll:
		print("[ScrollComponent] Scroll stopped")

## Set scroll speed
func set_scroll_speed(speed: float) -> void:
	scroll_speed = speed
	scroll_speed_changed.emit(Vector2(_direction.x * speed, _direction.y * speed))

## Add to scroll speed (relative adjustment)
func adjust_scroll_speed(delta_speed: float) -> void:
	set_scroll_speed(scroll_speed + delta_speed)

## Reset scroll offset
func reset_scroll() -> void:
	_scroll_offset = Vector2.ZERO
	_modulation_timer = 0.0
	_speed_multiplier = 1.0
#endregion

#region Public Methods - Direction
## Set scroll direction preset
func set_direction(direction: ScrollDirection) -> void:
	scroll_direction = direction
	_update_direction_vector()

## Set custom direction vector
func set_custom_direction(direction: Vector2) -> void:
	custom_direction = direction.normalized()
	scroll_direction = ScrollDirection.CUSTOM
	_update_direction_vector()
#endregion

#region Public Methods - Queries
## Get current scroll offset
func get_scroll_offset() -> Vector2:
	return _scroll_offset

## Get current scroll velocity
func get_scroll_velocity() -> Vector2:
	return _direction * scroll_speed * _speed_multiplier

## Get current speed multiplier
func get_speed_multiplier() -> float:
	return _speed_multiplier
#endregion

#region Private Methods - Scrolling
## Update direction vector based on preset
func _update_direction_vector() -> void:
	match scroll_direction:
		ScrollDirection.VERTICAL_DOWN:
			_direction = Vector2.DOWN
		ScrollDirection.VERTICAL_UP:
			_direction = Vector2.UP
		ScrollDirection.HORIZONTAL_LEFT:
			_direction = Vector2.LEFT
		ScrollDirection.HORIZONTAL_RIGHT:
			_direction = Vector2.RIGHT
		ScrollDirection.CUSTOM:
			_direction = custom_direction.normalized()

## Update speed modulation
func _update_speed_modulation(delta: float) -> void:
	_modulation_timer += delta
	
	# Sine wave modulation
	var progress = (_modulation_timer / modulation_period) * TAU
	var normalized = (sin(progress) + 1.0) / 2.0  # 0.0 to 1.0
	
	_speed_multiplier = lerp(
		speed_multiplier_range.x,
		speed_multiplier_range.y,
		normalized
	)

## Update single layer (no parallax)
func _update_single_layer() -> void:
	if not host:
		return
	
	# Apply to host position
	host.position = -_scroll_offset
	
	# Handle looping
	if loop_seamlessly:
		_handle_seamless_loop()

## Update parallax layers
func _update_parallax_layers() -> void:
	for i in range(_layer_nodes.size()):
		var layer = _layer_nodes[i]
		if not is_instance_valid(layer):
			continue
		
		# Get parallax factor (default to index if array too small)
		var parallax_factor = parallax_layers[i] if i < parallax_layers.size() else float(i) / _layer_nodes.size()
		
		# Apply scroll with parallax
		layer.position = -_scroll_offset * parallax_factor
		
		# Handle looping per layer
		if loop_seamlessly:
			_handle_layer_loop(layer, parallax_factor)

## Handle seamless looping for single layer
func _handle_seamless_loop() -> void:
	# This is a simple version - extend based on your needs
	# For proper seamless looping, you typically need duplicate sprites
	pass

## Handle looping for specific layer
func _handle_layer_loop(layer: Node, parallax_factor: float) -> void:
	# Implement layer-specific looping logic
	# This depends heavily on your sprite setup
	pass
#endregion

#region Private Methods - Layer Management
## Find layer nodes in hierarchy
func _find_layer_nodes() -> void:
	_layer_nodes.clear()
	
	if not host:
		return
	
	# Look for nodes named "Layer0", "Layer1", etc.
	for i in range(10):  # Support up to 10 layers
		var layer_name = "Layer%d" % i
		var layer = host.get_node_or_null(layer_name)
		
		if layer:
			_layer_nodes.append(layer)
		else:
			break  # Stop when no more sequential layers found
	
	if debug_scroll:
		print("[ScrollComponent] Found %d parallax layers" % _layer_nodes.size())

## Add a layer programmatically
func add_layer(layer_node: Node, parallax_factor: float = 1.0) -> void:
	if layer_node not in _layer_nodes:
		_layer_nodes.append(layer_node)
		
		# Extend parallax_layers array if needed
		if _layer_nodes.size() > parallax_layers.size():
			parallax_layers.append(parallax_factor)

## Remove a layer
func remove_layer(layer_node: Node) -> void:
	var index = _layer_nodes.find(layer_node)
	if index >= 0:
		_layer_nodes.remove_at(index)
		if index < parallax_layers.size():
			parallax_layers.remove_at(index)
#endregion

#region Debug
## Get debug information
func get_debug_info() -> Dictionary:
	return {
		"auto_scroll": auto_scroll,
		"direction": ScrollDirection.keys()[scroll_direction] if scroll_direction != ScrollDirection.CUSTOM else "CUSTOM",
		"speed": "%.1f px/s" % scroll_speed,
		"speed_multiplier": "%.2f" % _speed_multiplier,
		"offset": "%.1f, %.1f" % [_scroll_offset.x, _scroll_offset.y],
		"velocity": "%.1f, %.1f" % [get_scroll_velocity().x, get_scroll_velocity().y],
		"parallax_layers": _layer_nodes.size() if use_parallax else 0
	}

## Visualize scroll direction (for debugging)
func debug_draw_direction(canvas: CanvasItem, position: Vector2, length: float = 50.0) -> void:
	var end_pos = position + _direction * length
	canvas.draw_line(position, end_pos, Color.YELLOW, 2.0)
	
	# Arrow head
	var arrow_size = 10.0
	var arrow_angle = 30.0
	var left = end_pos + _direction.rotated(deg_to_rad(180 - arrow_angle)) * arrow_size
	var right = end_pos + _direction.rotated(deg_to_rad(180 + arrow_angle)) * arrow_size
	
	canvas.draw_line(end_pos, left, Color.YELLOW, 2.0)
	canvas.draw_line(end_pos, right, Color.YELLOW, 2.0)
#endregion
