## Component Foundation Test Controller
##
## Controls the test scene for the component foundation system.
## Allows interactive testing of component add/remove, enable/disable, etc.

extends Node

#region Node References
@onready var test_host: ComponentHost = $"../TestHost"
@onready var info_label: Label = $"../UI/Panel/VBoxContainer/InfoLabel"
@onready var component_count_label: Label = $"../UI/Panel/VBoxContainer/ComponentCount"
#endregion

#region Lifecycle Methods
func _ready() -> void:
	_update_ui()
	
	# Connect to ComponentHost signals
	test_host.component_added.connect(_on_component_added)
	test_host.component_removed.connect(_on_component_removed)
	test_host.all_components_ready.connect(_on_all_components_ready)

func _process(_delta: float) -> void:
	_handle_input()
	_update_ui()
#endregion

#region Input Handling
func _handle_input() -> void:
	# Add component
	if Input.is_action_just_pressed("ui_text_backspace") or Input.is_key_pressed(KEY_1):
		_add_test_component()
	
	# Remove component
	if Input.is_key_pressed(KEY_2):
		_remove_test_component()
	
	# Enable all
	if Input.is_key_pressed(KEY_3):
		_enable_all_components()
	
	# Disable all
	if Input.is_key_pressed(KEY_4):
		_disable_all_components()
	
	# Debug print
	if Input.is_key_pressed(KEY_D):
		test_host.debug_print_components()
	
	# Quit
	if Input.is_key_pressed(KEY_Q):
		get_tree().quit()
#endregion

#region Component Actions
func _add_test_component() -> void:
	var new_component = TestComponent.new()
	new_component.name = "TestComponent_Runtime_%d" % Time.get_ticks_msec()
	new_component.ready_message = "Runtime component added!"
	new_component.print_process = false
	
	test_host.add_component(new_component)
	_update_info("Component added: %s" % new_component.name)

func _remove_test_component() -> void:
	var components = test_host.get_all_components()
	if components.size() > 0:
		var component_to_remove = components[-1]  # Remove last component
		_update_info("Removing component: %s" % component_to_remove.name)
		test_host.remove_component(component_to_remove)
	else:
		_update_info("No components to remove")

func _enable_all_components() -> void:
	test_host.enable_all_components()
	_update_info("All components enabled")

func _disable_all_components() -> void:
	test_host.disable_all_components()
	_update_info("All components disabled")
#endregion

#region UI Updates
func _update_ui() -> void:
	var component_count = test_host.get_all_components().size()
	component_count_label.text = "Components: %d" % component_count

func _update_info(message: String) -> void:
	info_label.text = message
	print("[TestController] %s" % message)
#endregion

#region Signal Callbacks
func _on_component_added(component: Component) -> void:
	print("[TestController] Component added signal received: %s" % component.name)

func _on_component_removed(component: Component) -> void:
	print("[TestController] Component removed signal received: %s" % component.name)

func _on_all_components_ready() -> void:
	print("[TestController] All components ready!")
	_update_info("System initialized - all components ready!")
#endregion
