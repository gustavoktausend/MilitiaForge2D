## Base UI Widget
##
## Abstract base class for all smart UI widgets in the MilitiaForge2D framework.
## This class handles the connection to the logic layer (ComponentHost) adhering
## to the Mediator pattern where the HUD manages the connection.
##
## Features:
## - Automatic ComponentHost integration
## - Virtual methods for component setup
## - Safe signal connection handling
##
## @tutorial(UI System): res://docs/ui/README.md

class_name BaseUIWidget extends Control

#region Signals
## Emitted when the widget has successfully connected to its cached host
signal widget_connected
#endregion

#region Variables
## The ComponentHost this widget is currently observing
var _host: ComponentHost = null

## Whether to auto-search for host if not provided (optional fallback)
@export var auto_find_host: bool = false
#endregion

#region Lifecycle
func _ready() -> void:
	if auto_find_host and not _host:
		_find_host_in_tree()

func _exit_tree() -> void:
	_disconnect_signals()
	_host = null
#endregion

#region Public Methods
## Setup this widget with a specific ComponentHost.
## This is usually called by the parent BaseHUD (Mediator).
##
## @param host_node: The ComponentHost to observe
func setup(host_node: ComponentHost) -> void:
	# Disconnect from previous host if any
	if _host:
		_disconnect_signals()
	
	if not host_node:
		push_warning("BaseUIWidget: setup called with null host")
		return
		
	_host = host_node
	_connect_to_components()
	_update_visuals()
	widget_connected.emit()

## Get the current ComponentHost
func get_host() -> ComponentHost:
	return _host
#endregion

#region Virtual Methods (Override in subclasses)
## Override this to connect to specific component signals.
## Use safe_connect() helper for best practices.
func _connect_to_components() -> void:
	pass

## Override this to update the UI based on current component state.
## Called immediately after connection.
func _update_visuals() -> void:
	pass

## Override this to disconnect custom signals if needed.
## The base implementation clears _host reference.
func _disconnect_signals() -> void:
	pass
#endregion

#region Helper Methods
## Safely connects a signal to a callable if not already connected.
##
## @param source: Object emitting the signal
## @param signal_name: Name of the signal
## @param callback: Callable to execute
func safe_connect(source: Object, signal_name: String, callback: Callable) -> void:
	if source and source.has_signal(signal_name):
		if not source.is_connected(signal_name, callback):
			source.connect(signal_name, callback)
	else:
		push_warning("BaseUIWidget: Cannot connect to signal '%s' on %s" % [signal_name, source])

## Attempts to find a ComponentHost in the scene tree parents.
func _find_host_in_tree() -> void:
	var parent = get_parent()
	while parent:
		if parent is ComponentHost:
			setup(parent)
			return
		parent = parent.get_parent()
#endregion
