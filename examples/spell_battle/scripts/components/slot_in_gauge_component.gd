## Slot-In Gauge Component
##
## Game-specific component that manages the Slot-In Gauge for spell-battle.
## The gauge fills by 5% with each chip used or action taken.
##
## Features:
## - Gauge fills 5% per action
## - Triggers Slot-In when 100% full
## - Auto-resets after activation
## - Visual feedback support
##
## @tutorial(Spell Battle): res://examples/spell_battle/README.md

class_name SlotInGaugeComponent extends Component

#region Signals
## Emitted when gauge value changes
signal gauge_changed(current_value: float, max_value: float)

## Emitted when gauge fills to 100%
signal gauge_full()

## Emitted when Slot-In is activated
signal slot_in_ready()

## Emitted when gauge is reset
signal gauge_reset()

## Emitted on gauge increment
signal gauge_incremented(increment_amount: float)
#endregion

#region Exports
@export_group("Gauge Settings")
## Maximum gauge value (100%)
@export var max_gauge: float = 100.0

## Current gauge value
@export var current_gauge: float = 0.0

## Increment per action (5% default)
@export var increment_per_action: float = 5.0

## Whether gauge is enabled
@export var gauge_enabled: bool = true

@export_group("Auto Behavior")
## Whether to auto-activate Slot-In when full
@export var auto_activate_on_full: bool = false

## Whether to auto-reset after activation
@export var auto_reset_after_activation: bool = true

@export_group("Visual")
## Visual gauge node (ProgressBar, TextureProgressBar, etc.)
@export var visual_gauge: Range

@export_group("Advanced")
## Whether to print debug messages
@export var debug_gauge: bool = false
#endregion

#region Private Variables
## Whether gauge is currently full
var _is_full: bool = false

## Number of actions performed
var _action_count: int = 0
#endregion

#region Component Lifecycle
func _ready() -> void:
	# Initialize component if not using ComponentHost
	if not _is_initialized:
		# Only set host if parent is a ComponentHost
		var parent = get_parent()
		if parent is ComponentHost:
			host = parent
		_is_initialized = true
	component_ready()

func component_ready() -> void:
	# Sync visual gauge if assigned
	if visual_gauge:
		visual_gauge.max_value = max_gauge
		visual_gauge.value = current_gauge

	if debug_gauge:
		print("[SlotInGaugeComponent] Ready. Current: %.1f%% (%.1f/%.1f)" % [
			get_gauge_percentage() * 100, current_gauge, max_gauge
		])

func cleanup() -> void:
	super.cleanup()
#endregion

#region Public Methods - Gauge Management
## Increment gauge by action amount
## @param custom_amount: Custom increment (uses increment_per_action if 0)
func increment(custom_amount: float = 0.0) -> void:
	if not gauge_enabled:
		return

	var amount = custom_amount if custom_amount > 0.0 else increment_per_action

	current_gauge += amount
	_action_count += 1

	# Clamp to max
	if current_gauge > max_gauge:
		current_gauge = max_gauge

	gauge_changed.emit(current_gauge, max_gauge)
	gauge_incremented.emit(amount)

	# Update visual
	if visual_gauge:
		visual_gauge.value = current_gauge

	if debug_gauge:
		print("[SlotInGaugeComponent] Incremented by %.1f (Total: %.1f%%, Actions: %d)" % [
			amount, get_gauge_percentage() * 100, _action_count
		])

	# Check if full
	if current_gauge >= max_gauge and not _is_full:
		_on_gauge_full()

## Fill gauge to maximum
func fill() -> void:
	current_gauge = max_gauge
	gauge_changed.emit(current_gauge, max_gauge)

	if visual_gauge:
		visual_gauge.value = current_gauge

	if not _is_full:
		_on_gauge_full()

	if debug_gauge:
		print("[SlotInGaugeComponent] Gauge filled to 100%%")

## Reset gauge to zero
func reset() -> void:
	current_gauge = 0.0
	_is_full = false

	gauge_changed.emit(current_gauge, max_gauge)
	gauge_reset.emit()

	if visual_gauge:
		visual_gauge.value = current_gauge

	if debug_gauge:
		print("[SlotInGaugeComponent] Gauge reset to 0%%")

## Set gauge to specific value
## @param value: New gauge value
func set_gauge(value: float) -> void:
	current_gauge = clampf(value, 0.0, max_gauge)

	gauge_changed.emit(current_gauge, max_gauge)

	if visual_gauge:
		visual_gauge.value = current_gauge

	# Check full state
	if current_gauge >= max_gauge and not _is_full:
		_on_gauge_full()
	elif current_gauge < max_gauge:
		_is_full = false

## Activate Slot-In (consumes full gauge)
func activate_slot_in() -> bool:
	if not is_gauge_full():
		if debug_gauge:
			print("[SlotInGaugeComponent] Cannot activate - gauge not full (%.1f%%)" % (get_gauge_percentage() * 100))
		return false

	slot_in_ready.emit()

	if auto_reset_after_activation:
		reset()

	if debug_gauge:
		print("[SlotInGaugeComponent] Slot-In activated!")

	return true
#endregion

#region Public Methods - Queries
## Check if gauge is full
## @returns: true if at 100%
func is_gauge_full() -> bool:
	return current_gauge >= max_gauge

## Get gauge percentage
## @returns: Percentage from 0.0 to 1.0
func get_gauge_percentage() -> float:
	if max_gauge <= 0.0:
		return 0.0
	return current_gauge / max_gauge

## Get remaining gauge value
## @returns: Amount needed to fill
func get_remaining_gauge() -> float:
	return maxf(max_gauge - current_gauge, 0.0)

## Get number of actions needed to fill
## @returns: Actions remaining
func get_actions_to_fill() -> int:
	if increment_per_action <= 0.0:
		return 0

	var remaining = get_remaining_gauge()
	return ceili(remaining / increment_per_action)

## Get total action count
## @returns: Number of actions performed
func get_action_count() -> int:
	return _action_count

## Check if gauge is enabled
## @returns: true if enabled
func is_enabled() -> bool:
	return gauge_enabled

## Enable/disable gauge
## @param enabled: New enabled state
func set_enabled(enabled: bool) -> void:
	gauge_enabled = enabled

	if debug_gauge:
		print("[SlotInGaugeComponent] Gauge %s" % ("enabled" if enabled else "disabled"))
#endregion

#region Private Methods
## Handle gauge becoming full
func _on_gauge_full() -> void:
	_is_full = true
	gauge_full.emit()

	if debug_gauge:
		print("[SlotInGaugeComponent] Gauge FULL! (Actions: %d)" % _action_count)

	if auto_activate_on_full:
		activate_slot_in()
#endregion

#region Debug Methods
## Print gauge state
func debug_print_state() -> void:
	print("=== Slot-In Gauge State ===")
	print("Current: %.1f / %.1f (%.1f%%)" % [current_gauge, max_gauge, get_gauge_percentage() * 100])
	print("Increment per Action: %.1f" % increment_per_action)
	print("Actions Performed: %d" % _action_count)
	print("Actions to Fill: %d" % get_actions_to_fill())
	print("Is Full: %s" % is_gauge_full())
	print("Enabled: %s" % gauge_enabled)
	print("=========================")
#endregion
