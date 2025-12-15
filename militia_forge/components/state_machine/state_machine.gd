## State Machine Component
##
## A flexible, reusable state machine component for managing entity states.
## States are added as child nodes and the state machine handles transitions between them.
##
## Features:
## - Automatic state discovery from children
## - Conditional transitions
## - State history tracking (optional)
## - Debug visualization
## - Signal-based communication
##
## Usage:
## 1. Add StateMachine component to a ComponentHost
## 2. Add State nodes as children of the StateMachine
## 3. Set the initial_state_name
## 4. States will automatically transition based on their update() return values
##
## @tutorial(State Machine): res://docs/components/state_machine.md

class_name StateMachine extends Component

#region Signals
## Emitted when the state changes
signal state_changed(from_state: State, to_state: State)

## Emitted when a state transition is blocked/rejected
signal transition_blocked(from_state: State, to_state: State, reason: String)
#endregion

#region Exports
## Name of the initial state to start in
@export var initial_state_name: String = ""

## Whether to keep a history of state transitions
@export var track_history: bool = false

## Maximum number of states to keep in history (if track_history is true)
@export var max_history_size: int = 10

## Whether to print debug messages when states change
@export var debug_transitions: bool = false

@export_group("Advanced")
## Allow the state machine to process even when paused
@export var process_when_paused: bool = false

## Whether states can transition to themselves
@export var allow_self_transitions: bool = false
#endregion

#region Private Variables
## Dictionary of all states by name
var _states: Dictionary = {}

## Current active state
var _current_state: State = null

## Previous state (for reference)
var _previous_state: State = null

## History of state transitions (if track_history is enabled)
var _state_history: Array[String] = []

## Whether the state machine has been initialized
var _initialized: bool = false
#endregion

#region Component Lifecycle
func initialize(host_node: ComponentHost) -> void:
	super.initialize(host_node)
	_discover_states()

func component_ready() -> void:
	if not _initialized:
		_initialize_state_machine()

func component_process(delta: float) -> void:
	if _current_state and _current_state.is_active:
		# Update time in state
		_current_state.time_in_state += delta
		
		# Call state's update and check for transition
		var next_state_name = _current_state.update(delta)
		if next_state_name and next_state_name != "":
			change_state(next_state_name)

func component_physics_process(delta: float) -> void:
	if _current_state and _current_state.is_active:
		# Call state's physics update and check for transition
		var next_state_name = _current_state.physics_update(delta)
		if next_state_name and next_state_name != "":
			change_state(next_state_name)

func cleanup() -> void:
	if _current_state:
		_current_state.exit(null)
		_current_state = null
	
	_states.clear()
	_state_history.clear()
	super.cleanup()
#endregion

#region State Management
## Change to a different state by name.
##
## This is the main method for transitioning between states.
## It handles exit/enter callbacks and validation.
##
## @param state_name: Name of the state to transition to
## @returns: true if transition was successful, false otherwise
func change_state(state_name: String) -> bool:
	if not state_name or state_name == "":
		_emit_error("Cannot change to empty state name")
		return false
	
	# Check if state exists
	if not _states.has(state_name):
		_emit_error("State '%s' does not exist" % state_name)
		return false
	
	var next_state: State = _states[state_name]
	
	# Check for self-transition
	if next_state == _current_state:
		if not allow_self_transitions:
			if debug_transitions:
				print("[StateMachine] Self-transition to '%s' blocked" % state_name)
			return false
	
	# Check if transition is allowed
	if _current_state and not _current_state.can_transition_to(next_state):
		var reason = "Transition condition not met"
		if debug_transitions:
			print("[StateMachine] Transition from '%s' to '%s' blocked: %s" % [
				_current_state.name, state_name, reason
			])
		transition_blocked.emit(_current_state, next_state, reason)
		return false
	
	# Perform transition
	_transition_to_state(next_state)
	return true

## Force a state change without checking conditions.
##
## Use with caution - bypasses can_transition_to checks.
##
## @param state_name: Name of the state to force transition to
## @returns: true if state exists and transition occurred
func force_state(state_name: String) -> bool:
	if not _states.has(state_name):
		_emit_error("Cannot force to non-existent state '%s'" % state_name)
		return false
	
	_transition_to_state(_states[state_name])
	return true

## Get a state by name.
##
## @param state_name: Name of the state to retrieve
## @returns: The state, or null if not found
func get_state(state_name: String) -> State:
	return _states.get(state_name, null)

## Get the current active state.
##
## @returns: The current state, or null if no state is active
func get_current_state() -> State:
	return _current_state

## Get the name of the current active state.
##
## @returns: Current state name, or empty string if no state is active
func get_current_state_name() -> String:
	return _current_state.name if _current_state else ""

## Get the previous state.
##
## @returns: The previous state, or null if no previous state
func get_previous_state() -> State:
	return _previous_state

## Get all available state names.
##
## @returns: Array of state names
func get_all_state_names() -> Array[String]:
	var names: Array[String] = []
	names.assign(_states.keys())
	return names

## Check if a state exists by name.
##
## @param state_name: Name of the state to check
## @returns: true if state exists
func has_state(state_name: String) -> bool:
	return _states.has(state_name)

## Get the state transition history (if tracking is enabled).
##
## @returns: Array of state names in chronological order
func get_history() -> Array[String]:
	return _state_history.duplicate()

## Clear the state history.
func clear_history() -> void:
	_state_history.clear()
#endregion

#region Private Methods
## Discover and register all State child nodes.
func _discover_states() -> void:
	for child in get_children():
		if child is State:
			_register_state(child)
	
	if debug_transitions:
		print("[StateMachine] Discovered %d states: %s" % [_states.size(), _states.keys()])

## Register a state in the state machine.
##
## @param state: The state to register
func _register_state(state: State) -> void:
	if _states.has(state.name):
		push_warning("State '%s' already exists, overwriting" % state.name)
	
	_states[state.name] = state
	state.state_machine = self
	state.host = host
	
	# Connect to state's transition requests
	if not state.transition_requested.is_connected(_on_transition_requested):
		state.transition_requested.connect(_on_transition_requested)

## Initialize the state machine and set the initial state.
func _initialize_state_machine() -> void:
	if _states.is_empty():
		_emit_error("No states found! Add State nodes as children.")
		return
	
	# Determine initial state
	var initial_state: State = null
	
	if initial_state_name and _states.has(initial_state_name):
		initial_state = _states[initial_state_name]
	else:
		# Default to first state
		initial_state = _states.values()[0]
		if debug_transitions:
			print("[StateMachine] No initial state set, defaulting to '%s'" % initial_state.name)
	
	_transition_to_state(initial_state)
	_initialized = true

## Perform the actual state transition.
##
## @param next_state: The state to transition to
func _transition_to_state(next_state: State) -> void:
	var previous_state = _current_state
	
	# Exit current state
	if _current_state:
		_current_state.exit(next_state)
	
	# Update state references
	_previous_state = _current_state
	_current_state = next_state
	
	# Enter new state
	_current_state.enter(previous_state)
	
	# Track history
	if track_history:
		_add_to_history(_current_state.name)
	
	# Debug output
	if debug_transitions:
		var from_name = previous_state.name if previous_state else "none"
		print("[StateMachine] State changed: %s → %s" % [from_name, _current_state.name])
	
	# Emit signal
	state_changed.emit(previous_state, _current_state)

## Add a state to the history.
##
## @param state_name: Name of the state to add to history
func _add_to_history(state_name: String) -> void:
	_state_history.append(state_name)
	
	# Limit history size
	if _state_history.size() > max_history_size:
		_state_history.pop_front()

## Handle transition requests from states.
##
## @param to_state_name: Name of the state to transition to
func _on_transition_requested(to_state_name: String) -> void:
	change_state(to_state_name)
#endregion

#region Debug Methods
## Print debug information about the state machine.
func debug_print_info() -> void:
	print("=== State Machine Debug ===")
	print("Current State: %s" % get_current_state_name())
	print("Previous State: %s" % (_previous_state.name if _previous_state else "none"))
	print("Available States: %s" % get_all_state_names())
	
	if _current_state:
		print("Current State Info:")
		var debug_info = _current_state.get_debug_info()
		for key in debug_info:
			print("  %s: %s" % [key, debug_info[key]])
	
	if track_history and not _state_history.is_empty():
		print("State History: %s" % _state_history)
	
	print("=========================")
#endregion
