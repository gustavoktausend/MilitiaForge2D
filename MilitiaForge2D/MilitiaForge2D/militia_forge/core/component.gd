## Base Component Class
##
## Abstract base class for all components in the MilitiaForge2D framework.
## Components are self-contained, reusable pieces of functionality that can be
## attached to a ComponentHost to add specific behaviors.
##
## Components follow a standardized lifecycle:
## 1. _init() - Constructor
## 2. _ready() - Node ready in scene tree
## 3. initialize(host) - Component-specific initialization
## 4. component_ready() - Called after component is fully initialized
## 5. component_process(delta) - Called every frame (optional)
## 6. component_physics_process(delta) - Called every physics frame (optional)
## 7. cleanup() - Called when component is being removed
##
## @tutorial(Component System): res://docs/architecture/SOLID_PRINCIPLES.md
## @tutorial(Creating Components): res://docs/guidelines/COMPONENT_CREATION.md

class_name Component extends Node

#region Signals
## Emitted when the component is fully initialized and ready
signal component_initialized

## Emitted when the component encounters an error
signal component_error(error_message: String)
#endregion

#region Component State
## Reference to the ComponentHost that owns this component
var host: ComponentHost = null

## Whether the component has been initialized
var _is_initialized: bool = false

## Whether the component is currently enabled
var _is_enabled: bool = true
#endregion

#region Lifecycle Methods
## Called by the ComponentHost to initialize this component.
##
## This is the first lifecycle method called after the component is added to the host.
## Override this method to perform component-specific initialization.
## Always call super.initialize(host) first when overriding.
##
## @param host_node: The ComponentHost that owns this component
func initialize(host_node: ComponentHost) -> void:
	if _is_initialized:
		push_warning("Component %s is already initialized" % name)
		return
	
	host = host_node
	_is_initialized = true
	component_initialized.emit()

## Called after the component is initialized and ready to operate.
##
## This is called after initialize() and after the component is added to the scene tree.
## Override this method to perform setup that requires the component to be in the scene.
## This is similar to _ready() but specifically for component logic.
func component_ready() -> void:
	pass

## Called every frame if the component needs per-frame updates.
##
## Only override this if your component needs to update every frame.
## The ComponentHost will automatically call this if it's overridden.
##
## @param delta: Time elapsed since the last frame in seconds
func component_process(_delta: float) -> void:
	pass

## Called every physics frame if the component needs physics updates.
##
## Only override this if your component needs physics-related updates.
## The ComponentHost will automatically call this if it's overridden.
##
## @param delta: Fixed time step for physics (usually 1/60)
func component_physics_process(_delta: float) -> void:
	pass

## Called when the component is being removed or the host is being destroyed.
##
## Override this to perform cleanup operations like disconnecting signals,
## freeing resources, or saving state.
func cleanup() -> void:
	_is_initialized = false
	host = null
#endregion

#region Public Methods
## Enables this component, allowing it to process and operate normally.
func enable() -> void:
	if not _is_enabled:
		_is_enabled = true
		_on_enabled()

## Disables this component, preventing it from processing but keeping it in memory.
func disable() -> void:
	if _is_enabled:
		_is_enabled = false
		_on_disabled()

## Returns whether this component is currently enabled.
func is_enabled() -> bool:
	return _is_enabled

## Returns whether this component has been initialized.
func is_initialized() -> bool:
	return _is_initialized

## Gets the ComponentHost that owns this component.
func get_host() -> ComponentHost:
	return host
#endregion

#region Protected Methods (Override in subclasses)
## Called when the component is enabled.
## Override this to perform actions when enabling.
func _on_enabled() -> void:
	pass

## Called when the component is disabled.
## Override this to perform actions when disabling.
func _on_disabled() -> void:
	pass
#endregion

#region Helper Methods
## Emits an error signal with a formatted message.
##
## @param message: The error message to emit
func _emit_error(message: String) -> void:
	var full_message = "[%s] %s" % [get_class(), message]
	push_error(full_message)
	component_error.emit(full_message)

## Gets another component of the specified type from the host.
##
## This is a convenience method to get sibling components.
## Returns null if the component is not found.
##
## @param component_type: The class name of the component to find
func get_sibling_component(component_type: String) -> Component:
	if not host:
		_emit_error("Cannot get sibling component: host is null")
		return null
	
	return host.get_component(component_type)

## Gets all components of the specified type from the host.
##
## @param component_type: The class name of the components to find
func get_sibling_components(component_type: String) -> Array[Component]:
	if not host:
		_emit_error("Cannot get sibling components: host is null")
		return []
	
	return host.get_components(component_type)
#endregion
