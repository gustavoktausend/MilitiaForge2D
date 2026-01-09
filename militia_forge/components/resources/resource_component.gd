## Resource Component
##
## Generic component for managing any type of resource (mana, energy, stamina, etc.)
## Provides functionality for resource consumption, regeneration, and depletion tracking.
##
## Features:
## - Current/max resource tracking
## - Regeneration over time with delay
## - Resource consumption with overflow prevention
## - Depletion and full state detection
## - Signal-based communication
##
## @tutorial(Resource Management): res://docs/components/resource_component.md

class_name ResourceComponent extends Component

#region Signals
## Emitted when resource value changes
signal resource_changed(current: float, maximum: float)

## Emitted when resource is depleted (reaches 0)
signal resource_depleted()

## Emitted when resource reaches maximum
signal resource_full()

## Emitted when resource is consumed
signal resource_consumed(amount: float)

## Emitted when resource is restored
signal resource_restored(amount: float)
#endregion

#region Exports
@export_group("Resource Settings")
## Current resource value
@export var current_resource: float = 100.0:
	set(value):
		var old_value = current_resource
		current_resource = clampf(value, 0.0, max_resource)

		if current_resource != old_value:
			resource_changed.emit(current_resource, max_resource)

			if current_resource <= 0.0 and old_value > 0.0:
				resource_depleted.emit()
			elif current_resource >= max_resource and old_value < max_resource:
				resource_full.emit()

## Maximum resource capacity
@export var max_resource: float = 100.0:
	set(value):
		max_resource = maxf(value, 0.0)
		current_resource = minf(current_resource, max_resource)

## Whether resource starts at maximum
@export var start_at_max: bool = true

@export_group("Regeneration")
## Whether resource regenerates over time
@export var enable_regeneration: bool = false

## Amount of resource regenerated per second
@export var regeneration_rate: float = 5.0

## Delay before regeneration starts after consumption (seconds)
@export var regeneration_delay: float = 2.0

## Whether regeneration continues when resource is full
@export var regenerate_when_full: bool = false

@export_group("Advanced")
## Whether to print debug messages
@export var debug_resource: bool = false
#endregion

#region Private Variables
## Timer for regeneration delay
var _regen_delay_timer: float = 0.0

## Whether regeneration is currently active
var _is_regenerating: bool = false
#endregion

#region Component Lifecycle
func component_ready() -> void:
	if start_at_max:
		current_resource = max_resource

	if debug_resource:
		print("[ResourceComponent] Initialized: %d/%d" % [current_resource, max_resource])

func component_process(delta: float) -> void:
	if not enable_regeneration:
		return

	# Handle regeneration delay
	if _regen_delay_timer > 0.0:
		_regen_delay_timer -= delta
		if _regen_delay_timer <= 0.0:
			_is_regenerating = true
			if debug_resource:
				print("[ResourceComponent] Regeneration started")

	# Regenerate resource
	if _is_regenerating:
		if current_resource < max_resource or regenerate_when_full:
			var old_value = current_resource
			current_resource += regeneration_rate * delta

			if debug_resource and int(old_value) != int(current_resource):
				print("[ResourceComponent] Regenerated: %d/%d" % [current_resource, max_resource])
#endregion

#region Public Methods
## Consume resource
## @param amount: Amount to consume
## @returns: true if consumption was successful, false if insufficient resource
func consume(amount: float) -> bool:
	if amount < 0.0:
		push_warning("[ResourceComponent] Cannot consume negative amount")
		return false

	if current_resource < amount:
		if debug_resource:
			print("[ResourceComponent] Insufficient resource: need %d, have %d" % [amount, current_resource])
		return false

	current_resource -= amount
	resource_consumed.emit(amount)

	# Reset regeneration delay
	if enable_regeneration:
		_regen_delay_timer = regeneration_delay
		_is_regenerating = false

	if debug_resource:
		print("[ResourceComponent] Consumed %d. Remaining: %d/%d" % [amount, current_resource, max_resource])

	return true

## Restore resource
## @param amount: Amount to restore
func restore(amount: float) -> void:
	if amount < 0.0:
		push_warning("[ResourceComponent] Cannot restore negative amount")
		return

	var old_value = current_resource
	current_resource += amount

	if current_resource > old_value:
		resource_restored.emit(amount)

		if debug_resource:
			print("[ResourceComponent] Restored %d. Current: %d/%d" % [amount, current_resource, max_resource])

## Check if there is enough resource
## @param amount: Amount to check
## @returns: true if resource is sufficient
func has_resource(amount: float) -> bool:
	return current_resource >= amount

## Get resource percentage (0.0 to 1.0)
## @returns: Current resource as percentage of maximum
func get_resource_percent() -> float:
	if max_resource <= 0.0:
		return 0.0
	return current_resource / max_resource

## Check if resource is depleted
## @returns: true if resource is at 0
func is_depleted() -> bool:
	return current_resource <= 0.0

## Check if resource is full
## @returns: true if resource is at maximum
func is_full() -> bool:
	return current_resource >= max_resource

## Set resource to maximum
func refill() -> void:
	current_resource = max_resource

	if debug_resource:
		print("[ResourceComponent] Refilled to maximum: %d" % max_resource)

## Set resource to zero
func deplete() -> void:
	current_resource = 0.0

	if debug_resource:
		print("[ResourceComponent] Depleted to zero")

## Modify maximum resource and optionally scale current
## @param new_max: New maximum value
## @param scale_current: Whether to scale current resource proportionally
func set_max_resource(new_max: float, scale_current: bool = false) -> void:
	if scale_current and max_resource > 0.0:
		var ratio = current_resource / max_resource
		max_resource = new_max
		current_resource = max_resource * ratio
	else:
		max_resource = new_max

	if debug_resource:
		print("[ResourceComponent] Max resource changed to %d. Current: %d" % [max_resource, current_resource])
#endregion

#region Debug Methods
## Get debug information
## @returns: Dictionary with component state
func get_debug_info() -> Dictionary:
	return {
		"current": current_resource,
		"max": max_resource,
		"percent": get_resource_percent() * 100.0,
		"is_regenerating": _is_regenerating,
		"regen_delay": _regen_delay_timer,
		"is_depleted": is_depleted(),
		"is_full": is_full()
	}

## Print debug information
func debug_print() -> void:
	var info = get_debug_info()
	print("=== ResourceComponent Debug ===")
	print("Current: %.1f / %.1f (%.1f%%)" % [info.current, info.max, info.percent])
	print("Regenerating: %s (delay: %.1fs)" % [info.is_regenerating, info.regen_delay])
	print("State: %s%s" % [
		"DEPLETED" if info.is_depleted else "",
		"FULL" if info.is_full else ""
	])
	print("=============================")
#endregion
