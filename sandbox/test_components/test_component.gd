## Test Component
##
## A simple test component used to validate the core component system.
## This component prints debug messages during its lifecycle to verify
## that all lifecycle methods are being called correctly.

class_name TestComponent extends Component

#region Exports
## Message to print when the component is ready
@export var ready_message: String = "TestComponent is ready!"

## Whether to print process updates
@export var print_process: bool = false

## How often to print process updates (in seconds)
@export var process_print_interval: float = 1.0
#endregion

#region Private Variables
var _time_since_last_print: float = 0.0
var _process_count: int = 0
#endregion

#region Lifecycle Methods
func initialize(host_node: ComponentHost) -> void:
	super.initialize(host_node)
	print("[TestComponent] Initialized on host: %s" % host_node.name)

func component_ready() -> void:
	print("[TestComponent] %s" % ready_message)
	print("[TestComponent] Host has %d components" % host.get_all_components().size())

func component_process(delta: float) -> void:
	if not print_process:
		return
	
	_time_since_last_print += delta
	_process_count += 1
	
	if _time_since_last_print >= process_print_interval:
		print("[TestComponent] Process called %d times in %.2f seconds" % [_process_count, _time_since_last_print])
		_time_since_last_print = 0.0
		_process_count = 0

func cleanup() -> void:
	print("[TestComponent] Cleaning up...")
	super.cleanup()
#endregion

#region Protected Methods
func _on_enabled() -> void:
	print("[TestComponent] Enabled")

func _on_disabled() -> void:
	print("[TestComponent] Disabled")
#endregion
