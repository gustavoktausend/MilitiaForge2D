## Run State
##
## Example state representing a running behavior.
## Demonstrates state with faster movement and loop back to idle.

class_name RunState extends State

#region Exports
## Running speed (faster than walking)
@export var run_speed: float = 200.0

## Time to run before getting tired
@export var run_duration: float = 2.5

## State to transition to when tired
@export var next_state_name: String = "Idle"
#endregion

#region Lifecycle
func enter(previous_state: State = null) -> void:
	super.enter(previous_state)
	print("[RunState] Started running at speed %.1f" % run_speed)

func update(delta: float) -> String:
	# Simulate running logic here
	# In a real game, you'd move the character faster
	
	# Transition when tired
	if time_in_state >= run_duration:
		print("[RunState] Got tired, returning to %s" % next_state_name)
		return next_state_name
	
	return ""

func exit(next_state: State = null) -> void:
	print("[RunState] Stopped running")
	super.exit(next_state)
#endregion

#region Debug
func get_debug_info() -> Dictionary:
	var info = super.get_debug_info()
	info["run_speed"] = run_speed
	info["stamina"] = "%.1f%%" % ((1.0 - (time_in_state / run_duration)) * 100)
	return info
#endregion
