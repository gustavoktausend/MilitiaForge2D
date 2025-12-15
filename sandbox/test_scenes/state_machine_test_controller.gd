## State Machine Test Controller
##
## Controls the test scene for the StateMachine component.
## Allows interactive testing of state transitions, debugging, etc.

extends Node

#region Node References
@onready var test_host: ComponentHost = $"../TestHost"
@onready var state_machine: StateMachine = null

@onready var current_state_label: Label = $"../UI/Panel/VBoxContainer/CurrentState"
@onready var previous_state_label: Label = $"../UI/Panel/VBoxContainer/PreviousState"
@onready var time_label: Label = $"../UI/Panel/VBoxContainer/TimeInState"
@onready var transition_count_label: Label = $"../UI/Panel/VBoxContainer/TransitionCount"
@onready var state_info_label: Label = $"../UI/Panel/VBoxContainer/StateInfo"
@onready var auto_mode_label: Label = $"../UI/Panel/VBoxContainer/AutoMode"
#endregion

#region Private Variables
var _transition_count: int = 0
var _auto_transitions: bool = true
#endregion

#region Lifecycle
func _ready() -> void:
	# Get StateMachine component
	await get_tree().process_frame  # Wait for components to initialize
	state_machine = test_host.get_component("StateMachine")
	
	if not state_machine:
		push_error("StateMachine component not found!")
		return
	
	# Connect to signals
	state_machine.state_changed.connect(_on_state_changed)
	state_machine.transition_blocked.connect(_on_transition_blocked)
	
	_update_ui()
	print("[TestController] State Machine test ready!")

func _process(_delta: float) -> void:
	_handle_input()
	_update_ui()
#endregion

#region Input Handling
func _handle_input() -> void:
	# Force state transitions
	if Input.is_key_pressed(KEY_1):
		_force_state("Idle")
	
	if Input.is_key_pressed(KEY_2):
		_force_state("Walk")
	
	if Input.is_key_pressed(KEY_3):
		_force_state("Run")
	
	# Show history
	if Input.is_action_just_pressed("ui_select") or Input.is_key_pressed(KEY_H):
		_show_history()
	
	# Debug print
	if Input.is_key_pressed(KEY_D):
		state_machine.debug_print_info()
	
	# Toggle auto-transitions
	if Input.is_key_pressed(KEY_SPACE):
		_toggle_auto_transitions()
	
	# Quit
	if Input.is_key_pressed(KEY_Q):
		get_tree().quit()
#endregion

#region State Control
func _force_state(state_name: String) -> void:
	if not _auto_transitions:
		print("[TestController] Forcing state to: %s" % state_name)
		state_machine.force_state(state_name)
	else:
		print("[TestController] Cannot force state while auto-transitions are ON")

func _toggle_auto_transitions() -> void:
	_auto_transitions = not _auto_transitions
	
	if _auto_transitions:
		# Re-enable component
		state_machine.enable()
		auto_mode_label.text = "Auto-transitions: ON"
		auto_mode_label.add_theme_color_override("font_color", Color(0.596, 0.941, 0.439))
		print("[TestController] Auto-transitions enabled")
	else:
		# Disable component to stop automatic transitions
		state_machine.disable()
		auto_mode_label.text = "Auto-transitions: OFF (Manual Mode)"
		auto_mode_label.add_theme_color_override("font_color", Color(0.941, 0.439, 0.439))
		print("[TestController] Auto-transitions disabled - use 1/2/3 to force states")

func _show_history() -> void:
	var history = state_machine.get_history()
	if history.is_empty():
		print("[TestController] No state history")
	else:
		print("[TestController] State History: %s" % " → ".join(history))
#endregion

#region UI Updates
func _update_ui() -> void:
	if not state_machine:
		return
	
	var current = state_machine.get_current_state()
	var previous = state_machine.get_previous_state()
	
	if current:
		current_state_label.text = "Current State: %s" % current.name
		time_label.text = "Time in State: %.2fs" % current.time_in_state
		
		# Show state-specific debug info
		var debug_info = current.get_debug_info()
		var info_text = ""
		for key in debug_info:
			if key != "state_name" and key != "is_active" and key != "time_in_state":
				info_text += "%s: %s  " % [key, debug_info[key]]
		
		state_info_label.text = "State Info: %s" % (info_text if info_text != "" else "-")
	else:
		current_state_label.text = "Current State: None"
		time_label.text = "Time in State: 0.0s"
		state_info_label.text = "State Info: -"
	
	if previous:
		previous_state_label.text = "Previous State: %s" % previous.name
	else:
		previous_state_label.text = "Previous State: None"
	
	transition_count_label.text = "Transitions: %d" % _transition_count
#endregion

#region Signal Callbacks
func _on_state_changed(from_state: State, to_state: State) -> void:
	_transition_count += 1
	
	var from_name = from_state.name if from_state else "none"
	var to_name = to_state.name if to_state else "none"
	
	print("[TestController] ✓ State transition: %s → %s (total: %d)" % [
		from_name, to_name, _transition_count
	])

func _on_transition_blocked(from_state: State, to_state: State, reason: String) -> void:
	print("[TestController] ✗ Transition blocked: %s → %s (%s)" % [
		from_state.name, to_state.name, reason
	])
#endregion
