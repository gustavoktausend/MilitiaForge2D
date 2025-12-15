## State Base Class
##
## Abstract base class for all states in a state machine.
## Each state represents a distinct behavior or mode that an entity can be in.
##
## States have a simple lifecycle:
## 1. enter(previous_state) - Called when transitioning INTO this state
## 2. update(delta) - Called every frame while in this state
## 3. physics_update(delta) - Called every physics frame while in this state
## 4. exit(next_state) - Called when transitioning OUT OF this state
##
## States can request transitions to other states by returning the state name
## from their update methods, or by calling the state machine's change_state method.
##
## @tutorial(State Machine): res://docs/components/state_machine.md

class_name State extends Node

#region Signals
## Emitted when this state wants to transition to another state
signal transition_requested(to_state_name: String)

## Emitted when this state is entered
signal state_entered(previous_state: State)

## Emitted when this state is exited
signal state_exited(next_state: State)
#endregion

#region Properties
## Reference to the state machine that owns this state
var state_machine: StateMachine = null

## Reference to the entity/host that this state controls
var host: Node = null

## Whether this state is currently active
var is_active: bool = false

## Time spent in this state (in seconds)
var time_in_state: float = 0.0
#endregion

#region Lifecycle Methods
## Called when entering this state.
##
## Override this to perform setup when transitioning into this state.
## Examples: start animations, reset timers, initialize variables.
##
## @param previous_state: The state we're transitioning from (null if first state)
func enter(previous_state: State = null) -> void:
	is_active = true
	time_in_state = 0.0
	state_entered.emit(previous_state)

## Called every frame while this state is active.
##
## Override this to implement per-frame state logic.
## Return a state name (String) to request a transition to that state.
## Return empty string or null to stay in current state.
##
## @param delta: Time elapsed since last frame
## @returns: Name of state to transition to, or "" to stay in current state
func update(_delta: float) -> String:
	return ""

## Called every physics frame while this state is active.
##
## Override this to implement physics-related state logic.
## Return a state name (String) to request a transition to that state.
## Return empty string or null to stay in current state.
##
## @param delta: Fixed time step for physics
## @returns: Name of state to transition to, or "" to stay in current state
func physics_update(_delta: float) -> String:
	return ""

## Called when exiting this state.
##
## Override this to perform cleanup when transitioning out of this state.
## Examples: stop animations, clear temporary data, reset flags.
##
## @param next_state: The state we're transitioning to
func exit(next_state: State = null) -> void:
	is_active = false
	state_exited.emit(next_state)
#endregion

#region Helper Methods
## Request a transition to another state.
##
## This is a convenience method that emits the transition_requested signal.
## Can be called from anywhere within the state logic.
##
## @param to_state_name: Name of the state to transition to
func request_transition(to_state_name: String) -> void:
	if to_state_name and to_state_name != "":
		transition_requested.emit(to_state_name)

## Get a reference to a sibling state by name.
##
## @param state_name: Name of the state to find
## @returns: The state node, or null if not found
func get_sibling_state(state_name: String) -> State:
	if not state_machine:
		push_warning("State %s has no state machine reference" % name)
		return null
	
	return state_machine.get_state(state_name)

## Check if we can transition to a specific state.
##
## Override this to implement custom transition conditions.
## By default, all transitions are allowed.
##
## @param to_state: The state we want to transition to
## @returns: true if transition is allowed, false otherwise
func can_transition_to(_to_state: State) -> bool:
	return true

## Get the host node (the entity this state controls).
##
## @returns: The host node
func get_host() -> Node:
	return host
#endregion

#region Debug Methods
## Get debug information about this state.
##
## Override this to provide custom debug information.
##
## @returns: Dictionary with debug information
func get_debug_info() -> Dictionary:
	return {
		"state_name": name,
		"is_active": is_active,
		"time_in_state": "%.2f" % time_in_state,
		"class": get_class()
	}
#endregion
