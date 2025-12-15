## Walk State
##
## Example state representing a walking behavior.
## Demonstrates state with movement and conditional transition.

class_name WalkState extends State

#region Exports
## Walking speed
@export var walk_speed: float = 100.0

## Time to walk before transitioning
@export var walk_duration: float = 3.0

## State to transition to after walking
@export var next_state_name: String = "Run"
#endregion

#region Lifecycle
func enter(previous_state: State = null) -> void:
	super.enter(previous_state)
	print("[WalkState] Started walking at speed %.1f" % walk_speed)

func update(delta: float) -> String:
	# Simulate walking logic here
	# In a real game, you'd move the character
	
	# Transition after walk duration
	if time_in_state >= walk_duration:
		print("[WalkState] Walk complete, transitioning to %s" % next_state_name)
		return next_state_name
	
	return ""

func exit(next_state: State = null) -> void:
	print("[WalkState] Stopped walking")
	super.exit(next_state)
#endregion

#region Debug
func get_debug_info() -> Dictionary:
	var info = super.get_debug_info()
	info["walk_speed"] = walk_speed
	info["progress"] = "%.1f%%" % ((time_in_state / walk_duration) * 100)
	return info
#endregion
