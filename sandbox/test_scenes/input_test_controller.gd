## Input Test Controller
##
## Controls the test scene for the InputComponent.

extends Node

#region Node References
@onready var player: CharacterBody2D = $"../Player"
@onready var component_host: ComponentHost = $"../Player/ComponentHost"
var input_comp: InputComponent = null

# UI Labels
@onready var context_label: Label = $"../UI/Panel/VBoxContainer/Context"
@onready var input_enabled_label: Label = $"../UI/Panel/VBoxContainer/InputEnabled"
@onready var active_actions_label: Label = $"../UI/Panel/VBoxContainer/ActiveActions"
@onready var buffer_status_label: Label = $"../UI/Panel/VBoxContainer/BufferStatus"
@onready var action_log_label: Label = $"../UI/Panel/VBoxContainer/ActionLog"
#endregion

#region Private Variables
var _action_log: Array[String] = []
var _max_log_size: int = 5
#endregion

#region Lifecycle
func _ready() -> void:
	await get_tree().process_frame
	
	input_comp = component_host.get_component("InputComponent")
	
	if not input_comp:
		push_error("InputComponent not found!")
		return
	
	# Connect to input component signals
	input_comp.action_pressed.connect(_on_action_pressed)
	input_comp.action_released.connect(_on_action_released)
	input_comp.context_changed.connect(_on_context_changed)
	
	print("[TestController] Input test ready!")

func _process(_delta: float) -> void:
	_handle_test_input()
	_update_ui()
#endregion

#region Test Input Handling
func _handle_test_input() -> void:
	if not input_comp:
		return
	
	# Toggle input enable
	if Input.is_key_pressed(KEY_1):
		if input_comp.input_enabled:
			input_comp.disable_input()
		else:
			input_comp.enable_input()
		await get_tree().create_timer(0.2).timeout
	
	# Push menu context
	if Input.is_key_pressed(KEY_2):
		input_comp.push_context("menu")
		print("[TestController] Pushed 'menu' context")
		await get_tree().create_timer(0.2).timeout
	
	# Pop context
	if Input.is_key_pressed(KEY_3):
		input_comp.pop_context()
		print("[TestController] Popped context")
		await get_tree().create_timer(0.2).timeout
	
	# Toggle buffer
	if Input.is_key_pressed(KEY_4):
		input_comp.buffer_enabled = not input_comp.buffer_enabled
		print("[TestController] Buffer: %s" % ("ON" if input_comp.buffer_enabled else "OFF"))
		await get_tree().create_timer(0.2).timeout
	
	# Rebind jump to K
	if Input.is_key_pressed(KEY_R):
		input_comp.clear_action_keys("jump")
		input_comp.bind_key("jump", KEY_K)
		print("[TestController] Jump rebound to 'K'")
		await get_tree().create_timer(0.2).timeout
	
	# Reset jump to Space
	if Input.is_key_pressed(KEY_T):
		input_comp.clear_action_keys("jump")
		input_comp.bind_key("jump", KEY_SPACE)
		print("[TestController] Jump reset to 'Space'")
		await get_tree().create_timer(0.2).timeout
	
	# Debug print
	if Input.is_key_pressed(KEY_D):
		input_comp.debug_print_state()
		await get_tree().create_timer(0.5).timeout
	
	# Quit
	if Input.is_key_pressed(KEY_Q):
		get_tree().quit()
#endregion

#region UI Updates
func _update_ui() -> void:
	if not input_comp:
		return
	
	# Context
	context_label.text = "Context: %s" % input_comp.current_context
	
	# Input enabled
	if input_comp.input_enabled:
		input_enabled_label.text = "Input Enabled: Yes"
		input_enabled_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		input_enabled_label.text = "Input Enabled: No"
		input_enabled_label.add_theme_color_override("font_color", Color.RED)
	
	# Active actions
	var active_actions: Array[String] = []
	for action_name in input_comp.get_all_actions():
		if input_comp.is_action_pressed(action_name):
			active_actions.append(action_name)
	
	if active_actions.size() > 0:
		active_actions_label.text = "Active Actions: %s" % ", ".join(active_actions)
	else:
		active_actions_label.text = "Active Actions: None"
	
	# Buffer status
	buffer_status_label.text = "Buffer: %s (%d frames)\nDeadzone: %.1f" % [
		"ON" if input_comp.buffer_enabled else "OFF",
		input_comp.buffer_size,
		input_comp.analog_deadzone
	]
	
	# Action log
	_update_action_log()
#endregion

#region Action Log
func _update_action_log() -> void:
	var log_text = "Recent Actions:"
	
	if _action_log.size() == 0:
		log_text += "\n(Press buttons to see log)"
	else:
		for entry in _action_log:
			log_text += "\n" + entry
	
	action_log_label.text = log_text

func _add_to_log(message: String) -> void:
	_action_log.push_front(message)
	
	# Maintain max size
	while _action_log.size() > _max_log_size:
		_action_log.pop_back()
#endregion

#region Signal Callbacks
func _on_action_pressed(action_name: String) -> void:
	var timestamp = "%.2f" % (Time.get_ticks_msec() / 1000.0)
	_add_to_log("[%s] ▼ %s" % [timestamp, action_name])

func _on_action_released(action_name: String) -> void:
	var timestamp = "%.2f" % (Time.get_ticks_msec() / 1000.0)
	_add_to_log("[%s] ▲ %s" % [timestamp, action_name])

func _on_context_changed(new_context: String) -> void:
	print("[TestController] Context changed to: %s" % new_context)
#endregion
