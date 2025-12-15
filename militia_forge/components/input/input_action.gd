## Input Action
##
## Represents a single input action with multiple possible key bindings.
## Used by InputComponent to manage input mappings.

class_name InputAction extends RefCounted

#region Properties
## Name of this action
var action_name: String = ""

## List of keys/buttons that trigger this action
var keys: Array[int] = []

## Whether this action was just pressed this frame
var just_pressed: bool = false

## Whether this action was just released this frame
var just_released: bool = false

## Whether this action is currently pressed
var is_pressed: bool = false

## Strength of the action (0.0 to 1.0, for analog inputs)
var strength: float = 0.0
#endregion

#region Constructor
func _init(name: String, bindings: Array[int] = []) -> void:
	action_name = name
	keys = bindings.duplicate()
#endregion

#region Public Methods
## Add a key binding to this action
func add_key(key: int) -> void:
	if key not in keys:
		keys.append(key)

## Remove a key binding from this action
func remove_key(key: int) -> void:
	keys.erase(key)

## Clear all key bindings
func clear_keys() -> void:
	keys.clear()

## Check if a specific key is bound to this action
func has_key(key: int) -> bool:
	return key in keys

## Update the state of this action based on input
func update_state() -> void:
	var was_pressed = is_pressed
	is_pressed = false
	strength = 0.0
	
	# Check all bound keys
	for key in keys:
		if _is_key_pressed(key):
			is_pressed = true
			strength = _get_key_strength(key)
			break
	
	# Update edge detection
	just_pressed = is_pressed and not was_pressed
	just_released = not is_pressed and was_pressed

## Get debug string representation
func get_debug_string() -> String:
	return "InputAction(%s, keys=%s, pressed=%s)" % [action_name, keys, is_pressed]
#endregion

#region Private Methods
## Check if a key/button is currently pressed
func _is_key_pressed(key: int) -> bool:
	# Keyboard keys
	if key < 4194304:  # KEY_SPECIAL constant
		return Input.is_key_pressed(key)
	
	# Mouse buttons
	if key >= 1 and key <= 9:  # MouseButton enum
		return Input.is_mouse_button_pressed(key)
	
	# Joypad buttons
	if key >= JOY_BUTTON_A and key <= JOY_BUTTON_MAX:
		return Input.is_joy_button_pressed(0, key)
	
	return false

## Get the strength of key press (for analog inputs)
func _get_key_strength(key: int) -> float:
	# Joypad axes handled separately
	# For now, digital inputs return 1.0 when pressed
	if _is_key_pressed(key):
		return 1.0
	return 0.0
#endregion
