## Idle State
##
## Example state representing an idle/waiting behavior.
## Demonstrates basic state implementation with timer-based transition.

class_name IdleState extends State

#region Exports
## Time to wait in idle before transitioning
@export var idle_duration: float = 2.0

## State to transition to after idle duration
@export var next_state_name: String = "Walk"
#endregion

#region Lifecycle
func enter(previous_state: State = null) -> void:
	super.enter(previous_state)
	print("[IdleState] Entered idle state")

func update(delta: float) -> String:
	# Transition after idle duration
	if time_in_state >= idle_duration:
		print("[IdleState] Idle time complete, transitioning to %s" % next_state_name)
		return next_state_name
	
	return ""

func exit(next_state: State = null) -> void:
	print("[IdleState] Exiting idle state")
	super.exit(next_state)
#endregion
