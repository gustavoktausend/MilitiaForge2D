## Component Host
##
## Manages the lifecycle and coordination of attached components.
## This is the central node that components are added to and interact with.
##
## The ComponentHost is responsible for:
## - Registering and initializing components
## - Managing component lifecycle (ready, process, physics_process)
## - Providing component lookup and communication
## - Coordinating component cleanup
##
## Usage:
## 1. Create a scene with a ComponentHost node
## 2. Add Component nodes as children (in editor or via code)
## 3. ComponentHost will automatically initialize and manage them
##
## @tutorial(Component System): res://docs/architecture/SOLID_PRINCIPLES.md

class_name ComponentHost extends Node2D

#region Signals
## Emitted when a component is added to this host
signal component_added(component: Component)

## Emitted when a component is removed from this host
signal component_removed(component: Component)

## Emitted when all components are ready
signal all_components_ready
#endregion

#region Private Variables
## Dictionary of components organized by type for fast lookup
var _components_by_type: Dictionary = {}

## Array of all components in insertion order
var _components: Array[Component] = []

## Whether all components have been initialized
var _all_ready: bool = false
#endregion

#region Lifecycle Methods
func _ready() -> void:
	_discover_and_initialize_components()

func _process(delta: float) -> void:
	for component in _components:
		if component.is_enabled():
			component.component_process(delta)

func _physics_process(delta: float) -> void:
	for component in _components:
		if component.is_enabled():
			component.component_physics_process(delta)

func _exit_tree() -> void:
	cleanup_all_components()
#endregion

#region Component Management
## Adds a component to this host programmatically.
##
## This method can be used to add components at runtime.
## The component will be initialized immediately if the host is ready.
##
## @param component: The component to add
func add_component(component: Component) -> void:
	if not component:
		push_error("Cannot add null component")
		return
	
	if component.get_parent() != self:
		add_child(component)
	
	_register_component(component)
	
	# Initialize immediately if host is already ready
	if _all_ready:
		component.initialize(self)
		component.component_ready()

## Removes a component from this host.
##
## The component will be cleaned up and removed from the scene tree.
##
## @param component: The component to remove
func remove_component(component: Component) -> void:
	if not component:
		push_error("Cannot remove null component")
		return
	
	_unregister_component(component)
	component.cleanup()
	
	if component.get_parent() == self:
		remove_child(component)
	
	component_removed.emit(component)

## Gets the first component of the specified type.
##
## @param component_type: The class name of the component to find
## Returns: The component if found, null otherwise
func get_component(component_type: String) -> Component:
	if _components_by_type.has(component_type):
		var components_array = _components_by_type[component_type]
		if components_array.size() > 0:
			return components_array[0]
	return null

## Gets all components of the specified type.
##
## @param component_type: The class name of the components to find
## Returns: Array of components (empty if none found)
func get_components(component_type: String) -> Array[Component]:
	if _components_by_type.has(component_type):
		return _components_by_type[component_type].duplicate()
	return []

## Gets all components attached to this host.
##
## Returns: Array of all components
func get_all_components() -> Array[Component]:
	return _components.duplicate()

## Checks if a component of the specified type exists.
##
## @param component_type: The class name to check for
func has_component(component_type: String) -> bool:
	return _components_by_type.has(component_type) and _components_by_type[component_type].size() > 0

## Enables all components attached to this host.
func enable_all_components() -> void:
	for component in _components:
		component.enable()

## Disables all components attached to this host.
func disable_all_components() -> void:
	for component in _components:
		component.disable()

## Cleans up and removes all components.
func cleanup_all_components() -> void:
	for component in _components.duplicate():
		component.cleanup()
	
	_components.clear()
	_components_by_type.clear()
#endregion

#region Private Methods
## Discovers all child Component nodes and initializes them.
func _discover_and_initialize_components() -> void:
	# Find all Component children
	for child in get_children():
		if child is Component:
			_register_component(child)
	
	# Initialize all components
	for component in _components:
		component.initialize(self)
	
	# Call component_ready on all components
	for component in _components:
		component.component_ready()
	
	_all_ready = true
	all_components_ready.emit()

## Registers a component in the internal tracking structures.
##
## @param component: The component to register
func _register_component(component: Component) -> void:
	# Add to main array
	_components.append(component)
	
	# Add to type dictionary
	var component_type = component.get_class()
	if not _components_by_type.has(component_type):
		_components_by_type[component_type] = []
	
	_components_by_type[component_type].append(component)
	
	component_added.emit(component)

## Unregisters a component from the internal tracking structures.
##
## @param component: The component to unregister
func _unregister_component(component: Component) -> void:
	# Remove from main array
	_components.erase(component)
	
	# Remove from type dictionary
	var component_type = component.get_class()
	if _components_by_type.has(component_type):
		_components_by_type[component_type].erase(component)
		
		# Clean up empty arrays
		if _components_by_type[component_type].size() == 0:
			_components_by_type.erase(component_type)
#endregion

#region Debug Methods
## Prints information about all attached components (debug only).
func debug_print_components() -> void:
	print("=== ComponentHost: %s ===" % name)
	print("Total components: %d" % _components.size())
	print("Components by type:")
	for component_type in _components_by_type.keys():
		print("  - %s: %d" % [component_type, _components_by_type[component_type].size()])
	print("===========================")
#endregion
