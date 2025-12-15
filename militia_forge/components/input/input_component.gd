## Input Component
##
## Centralized input management component with support for multiple input schemes,
## input buffering, rebinding, and context management.
##
## Features:
## - Action-based input mapping
## - Multiple key bindings per action
## - Input buffering for combo systems
## - Context stacking (menu, gameplay, etc.)
## - Deadzone support for analog inputs
## - Easy rebinding
## - Signal-based event system
##
## @tutorial(Input System): res://docs/components/input.md

class_name InputComponent extends Component

#region Signals
## Emitted when an action is pressed
signal action_pressed(action_name: String)

## Emitted when an action is released
signal action_released(action_name: String)

## Emitted when input context changes
signal context_changed(new_context: String)
#endregion

#region Exports
@export_group("Input Settings")
## Whether input is currently enabled
@export var input_enabled: bool = true

## Deadzone for analog inputs (0.0 to 1.0)
@export_range(0.0, 1.0) var analog_deadzone: float = 0.2

@export_group("Input Buffering")
## Whether to buffer inputs
@export var buffer_enabled: bool = true

## How many frames to buffer inputs
@export var buffer_size: int = 5

@export_group("Advanced")
## Current input context (e.g., "gameplay", "menu", "cutscene")
@export var current_context: String = "gameplay"

## Whether to print debug messages
@export var debug_input: bool = false
#endregion

#region Private Variables
## Dictionary of all registered actions
var _actions: Dictionary = {}  # String -> InputAction

## Input buffer (stores recent inputs)
var _input_buffer: Array[Dictionary] = []

## Context stack for managing different input states
var _context_stack: Array[String] = []

## Actions disabled in current context
var _disabled_actions: Array[String] = []
#endregion

#region Component Lifecycle
func initialize(host_node: ComponentHost) -> void:
	super.initialize(host_node)
	_context_stack.append(current_context)

func component_ready() -> void:
	if debug_input:
		print("[InputComponent] Ready with %d actions" % _actions.size())

func component_process(_delta: float) -> void:
	if not input_enabled:
		return
	
	_update_actions()
	_update_buffer()

func cleanup() -> void:
	_actions.clear()
	_input_buffer.clear()
	_context_stack.clear()
	super.cleanup()
#endregion

#region Action Management
## Register a new input action.
##
## @param action_name: Name of the action
## @param keys: Array of key codes to bind (optional)
func add_action(action_name: String, keys: Array[int] = []) -> void:
	if _actions.has(action_name):
		push_warning("Action '%s' already exists, overwriting" % action_name)
	
	_actions[action_name] = InputAction.new(action_name, keys)
	
	if debug_input:
		print("[InputComponent] Added action: %s with keys: %s" % [action_name, keys])

## Remove an input action.
##
## @param action_name: Name of the action to remove
func remove_action(action_name: String) -> void:
	if _actions.erase(action_name):
		if debug_input:
			print("[InputComponent] Removed action: %s" % action_name)

## Bind a key to an action.
##
## @param action_name: Name of the action
## @param key: Key code to bind
func bind_key(action_name: String, key: int) -> void:
	if not _actions.has(action_name):
		push_error("Action '%s' does not exist" % action_name)
		return
	
	_actions[action_name].add_key(key)
	
	if debug_input:
		print("[InputComponent] Bound key %d to action: %s" % [key, action_name])

## Unbind a key from an action.
##
## @param action_name: Name of the action
## @param key: Key code to unbind
func unbind_key(action_name: String, key: int) -> void:
	if not _actions.has(action_name):
		return
	
	_actions[action_name].remove_key(key)

## Clear all key bindings for an action.
##
## @param action_name: Name of the action
func clear_action_keys(action_name: String) -> void:
	if not _actions.has(action_name):
		return
	
	_actions[action_name].clear_keys()
#endregion

#region Input Queries
## Check if an action is currently pressed.
##
## @param action_name: Name of the action
func is_action_pressed(action_name: String) -> bool:
	if not input_enabled or action_name in _disabled_actions:
		return false
	
	if not _actions.has(action_name):
		return false
	
	return _actions[action_name].is_pressed

## Check if an action was just pressed this frame.
##
## @param action_name: Name of the action
func is_action_just_pressed(action_name: String) -> bool:
	if not input_enabled or action_name in _disabled_actions:
		return false
	
	if not _actions.has(action_name):
		return false
	
	return _actions[action_name].just_pressed

## Check if an action was just released this frame.
##
## @param action_name: String) -> bool:
	if not input_enabled or action_name in _disabled_actions:
		return false
	
	if not _actions.has(action_name):
		return false
	
	return _actions[action_name].just_released

## Get the strength of an action (0.0 to 1.0).
##
## Useful for analog inputs.
##
## @param action_name: Name of the action
func get_action_strength(action_name: String) -> float:
	if not input_enabled or action_name in _disabled_actions:
		return 0.0
	
	if not _actions.has(action_name):
		return 0.0
	
	return _actions[action_name].strength

## Get a 2D vector from four directional actions.
##
## Similar to Input.get_vector() but uses our custom actions.
##
## @param negative_x: Action for left/negative X
## @param positive_x: Action for right/positive X
## @param negative_y: Action for up/negative Y
## @param positive_y: Action for down/positive Y
func get_vector(negative_x: String, positive_x: String, negative_y: String, positive_y: String) -> Vector2:
	var vector = Vector2.ZERO
	
	if is_action_pressed(negative_x):
		vector.x -= get_action_strength(negative_x)
	if is_action_pressed(positive_x):
		vector.x += get_action_strength(positive_x)
	if is_action_pressed(negative_y):
		vector.y -= get_action_strength(negative_y)
	if is_action_pressed(positive_y):
		vector.y += get_action_strength(positive_y)
	
	# Apply deadzone
	if vector.length() < analog_deadzone:
		return Vector2.ZERO
	
	# Normalize if needed
	if vector.length() > 1.0:
		vector = vector.normalized()
	
	return vector

## Get an axis value from two opposing actions.
##
## @param negative: Action for negative direction
## @param positive: Action for positive direction
func get_axis(negative: String, positive: String) -> float:
	var value = 0.0
	
	if is_action_pressed(negative):
		value -= get_action_strength(negative)
	if is_action_pressed(positive):
		value += get_action_strength(positive)
	
	# Apply deadzone
	if abs(value) < analog_deadzone:
		return 0.0
	
	return clampf(value, -1.0, 1.0)
#endregion

#region Input Buffer
## Check if an action was pressed within the buffer window.
##
## Useful for combo systems and input buffering.
##
## @param action_name: Name of the action
## @param frames_back: How many frames to look back (default: full buffer)
func was_action_buffered(action_name: String, frames_back: int = -1) -> bool:
	if not buffer_enabled:
		return false
	
	var check_frames = frames_back if frames_back > 0 else buffer_size
	check_frames = mini(check_frames, _input_buffer.size())
	
	for i in range(check_frames):
		if _input_buffer[i].has(action_name):
			return true
	
	return false

## Clear the input buffer.
func clear_buffer() -> void:
	_input_buffer.clear()
#endregion

#region Context Management
## Push a new input context onto the stack.
##
## Useful for switching between gameplay/menu/cutscene contexts.
##
## @param context_name: Name of the context
func push_context(context_name: String) -> void:
	_context_stack.append(context_name)
	current_context = context_name
	context_changed.emit(context_name)
	
	if debug_input:
		print("[InputComponent] Pushed context: %s" % context_name)

## Pop the current context and return to the previous one.
func pop_context() -> void:
	if _context_stack.size() <= 1:
		push_warning("Cannot pop base context")
		return
	
	_context_stack.pop_back()
	current_context = _context_stack.back()
	context_changed.emit(current_context)
	
	if debug_input:
		print("[InputComponent] Popped context, now: %s" % current_context)

## Disable specific actions in the current context.
##
## @param actions: Array of action names to disable
func disable_actions(actions: Array[String]) -> void:
	for action in actions:
		if action not in _disabled_actions:
			_disabled_actions.append(action)

## Re-enable previously disabled actions.
##
## @param actions: Array of action names to enable
func enable_actions(actions: Array[String]) -> void:
	for action in actions:
		_disabled_actions.erase(action)

## Clear all disabled actions.
func clear_disabled_actions() -> void:
	_disabled_actions.clear()
#endregion

#region Utility Methods
## Enable input processing.
func enable_input() -> void:
	input_enabled = true

## Disable input processing.
func disable_input() -> void:
	input_enabled = false

## Get all registered action names.
func get_all_actions() -> Array[String]:
	var actions: Array[String] = []
	actions.assign(_actions.keys())
	return actions

## Check if an action exists.
func has_action(action_name: String) -> bool:
	return _actions.has(action_name)
#endregion

#region Private Methods
## Update all action states.
func _update_actions() -> void:
	for action_name in _actions:
		var action: InputAction = _actions[action_name]
		var was_just_pressed = action.just_pressed
		
		action.update_state()
		
		# Emit signals
		if action.just_pressed:
			action_pressed.emit(action_name)
			
			if debug_input:
				print("[InputComponent] Action pressed: %s" % action_name)
		
		if action.just_released:
			action_released.emit(action_name)
			
			if debug_input:
				print("[InputComponent] Action released: %s" % action_name)

## Update the input buffer.
func _update_buffer() -> void:
	if not buffer_enabled:
		return
	
	# Find actions that were just pressed this frame
	var frame_inputs: Dictionary = {}
	
	for action_name in _actions:
		var action: InputAction = _actions[action_name]
		if action.just_pressed:
			frame_inputs[action_name] = true
	
	# Add to buffer if any inputs this frame
	if not frame_inputs.is_empty():
		_input_buffer.push_front(frame_inputs)
	
	# Maintain buffer size
	while _input_buffer.size() > buffer_size:
		_input_buffer.pop_back()
#endregion

#region Debug Methods
## Print debug information about current input state.
func debug_print_state() -> void:
	print("=== InputComponent Debug ===")
	print("Context: %s" % current_context)
	print("Enabled: %s" % input_enabled)
	print("Registered actions: %d" % _actions.size())
	
	print("\nAction States:")
	for action_name in _actions:
		var action: InputAction = _actions[action_name]
		if action.is_pressed or action.just_pressed or action.just_released:
			print("  %s: pressed=%s, just_pressed=%s, just_released=%s" % [
				action_name, action.is_pressed, action.just_pressed, action.just_released
			])
	
	if buffer_enabled and _input_buffer.size() > 0:
		print("\nBuffer (last %d frames):" % _input_buffer.size())
		for i in range(mini(3, _input_buffer.size())):
			print("  Frame -%d: %s" % [i, _input_buffer[i].keys()])
	
	print("============================")
#endregion
