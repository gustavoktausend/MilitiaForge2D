## Base HUD
##
## Central controller (Mediator) for the User Interface.
## Manages a collection of BaseUIWidgets and orchestrates their connection
## to the game logic (ComponentHost).
##
## Features:
## - Recursive widget discovery
## - Centralized dependency injection
## - Player/Entity observation
##
## @tutorial(UI System): res://docs/ui/README.md

class_name BaseHUD extends CanvasLayer

#region Exports
## Path to the target ComponentHost (usually the Player)
## If empty, you must call set_target_host() manually.
@export var target_host_path: NodePath
#endregion

#region Variables
var _target_host: ComponentHost = null
var _widgets: Array[BaseUIWidget] = []
#endregion

#region Lifecycle
func _ready() -> void:
	_find_all_widgets()
	
	if not target_host_path.is_empty():
		var node = get_node_or_null(target_host_path)
		if node and node is ComponentHost:
			set_target_host(node as ComponentHost)
#endregion

#region Public Methods
## Sets the ComponentHost that this HUD should display.
## Propagates the host to all registered widgets.
##
## @param host: The ComponentHost to observe
func set_target_host(host: ComponentHost) -> void:
	_target_host = host
	
	if not _target_host:
		push_warning("BaseHUD: set_target_host called with null")
		return
		
	# Propagate to all widgets
	for widget in _widgets:
		widget.setup(_target_host)
		
	# Listen for host destruction
	if _target_host.has_signal("tree_exiting"):
		if not _target_host.is_connected("tree_exiting", _on_host_exiting):
			_target_host.tree_exiting.connect(_on_host_exiting)

## Refresh the list of widgets by scanning children recursively.
## Call this if you dynamically add widgets at runtime.
func refresh_widgets() -> void:
	_widgets.clear()
	_find_all_widgets()
	if _target_host:
		set_target_host(_target_host)
#endregion

#region Private Methods
## Recursively finds all BaseUIWidget children.
func _find_all_widgets(node: Node = self) -> void:
	for child in node.get_children():
		if child is BaseUIWidget:
			_widgets.append(child)
		
		# Continue recursion strictly for visual containers
		# Stop if we hit another independent scene root to avoid bleeding
		if child.get_child_count() > 0:
			_find_all_widgets(child)

func _on_host_exiting() -> void:
	_target_host = null
	# Optional: Notify widgets or clear state
#endregion
