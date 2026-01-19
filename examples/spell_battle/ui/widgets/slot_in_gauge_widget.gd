## Slot-In Gauge Widget
##
## Displays Slot-In gauge that fills from 0% to 100%.
## Features smooth animations and visual feedback when full.
##
## @tutorial(Spell Battle): res://examples/spell_battle/README.md

class_name SlotInGaugeWidget extends Control

#region Signals
## Emitted when gauge percentage changes
signal gauge_updated(percentage: float)

## Emitted when gauge reaches 100%
signal gauge_full_visual()
#endregion

#region Exports
@export_group("Visual Nodes")
## Progress bar for gauge visualization
@export var gauge_bar: ProgressBar

## Label for percentage display (optional)
@export var percentage_label: Label

@export_group("Settings")
## Animation duration for gauge changes
@export var animation_duration: float = 0.2

## Enable smooth animations
@export var animate_changes: bool = true

## Enable flash effect when full
@export var flash_when_full: bool = true

## Flash color when gauge is full
@export var flash_color: Color = Color(0.0, 1.0, 1.0, 0.5)  # Cyan semi-transparent
#endregion

#region Private Variables
## Current tween animation
var _tween: Tween

## Current percentage (0.0-1.0)
var _current_percentage: float = 0.0

## Is gauge currently full
var _is_full: bool = false

## Flash tween for full effect
var _flash_tween: Tween
#endregion

#region Lifecycle
func _ready() -> void:
	# Auto-create nodes if not assigned
	if not gauge_bar:
		_create_gauge_bar()

	if not percentage_label:
		_create_percentage_label()

	# Setup initial state
	if gauge_bar:
		gauge_bar.max_value = 100.0
		gauge_bar.value = 0.0
#endregion

#region Public API
## Initialize gauge
func initialize() -> void:
	set_gauge_percentage(0.0, false)

## Set gauge percentage
## @param percentage: Gauge value as 0.0-1.0
## @param animate: Whether to animate the change
func set_gauge_percentage(percentage: float, animate: bool = true) -> void:
	_current_percentage = clampf(percentage, 0.0, 1.0)

	# Update label if present
	if percentage_label:
		percentage_label.text = "%d%%" % int(_current_percentage * 100.0)

	# Animate or instantly set value
	if animate and animate_changes and is_inside_tree():
		_animate_gauge_change(_current_percentage * 100.0)
	else:
		if gauge_bar:
			gauge_bar.value = _current_percentage * 100.0

	# Check if gauge is full
	if _current_percentage >= 1.0 and not _is_full:
		_is_full = true
		if flash_when_full:
			flash_full()
		gauge_full_visual.emit()
	elif _current_percentage < 1.0:
		_is_full = false

	gauge_updated.emit(_current_percentage)

## Flash effect when gauge is full
func flash_full() -> void:
	if not gauge_bar:
		return

	# Kill existing flash tween
	if _flash_tween:
		_flash_tween.kill()

	# Create modulate overlay
	var original_modulate = gauge_bar.modulate

	# Create flash animation
	_flash_tween = create_tween()
	_flash_tween.set_loops(2)

	# Flash sequence: white → original (2 times)
	_flash_tween.tween_property(gauge_bar, "modulate", Color.WHITE, 0.15)
	_flash_tween.tween_property(gauge_bar, "modulate", original_modulate, 0.15)

## Get current percentage
## @returns: Percentage as 0.0-1.0
func get_percentage() -> float:
	return _current_percentage

## Check if gauge is full
## @returns: True if percentage >= 1.0
func is_full() -> bool:
	return _is_full
#endregion

#region Private Methods
## Animate gauge change with Tween
func _animate_gauge_change(target_value: float) -> void:
	if not gauge_bar:
		return

	# Kill existing tween
	if _tween:
		_tween.kill()

	# Create new tween
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_LINEAR)  # Linear for smooth filling
	_tween.set_ease(Tween.EASE_IN_OUT)

	# Animate bar value
	_tween.tween_property(gauge_bar, "value", target_value, animation_duration)

## Create gauge bar programmatically if not assigned
func _create_gauge_bar() -> void:
	gauge_bar = ProgressBar.new()
	gauge_bar.custom_minimum_size = Vector2(200, 30)
	gauge_bar.show_percentage = false
	gauge_bar.max_value = 100.0
	gauge_bar.value = 0.0

	# Create background style
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.125, 0.125, 0.188)  # Dark gray (#202030)
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.0, 0.941, 0.941)  # Cyan (#00F0F0)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	gauge_bar.add_theme_stylebox_override("background", bg_style)

	# Create fill style with gradient (cyan → green)
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.0, 0.941, 0.941)  # Cyan
	fill_style.border_width_left = 0
	fill_style.border_width_right = 0
	fill_style.border_width_top = 0
	fill_style.border_width_bottom = 0
	fill_style.corner_radius_top_left = 2
	fill_style.corner_radius_top_right = 2
	fill_style.corner_radius_bottom_left = 2
	fill_style.corner_radius_bottom_right = 2

	# Add gradient effect (cyan to green)
	# Note: StyleBoxFlat doesn't support gradients directly
	# We'll use a solid cyan color; gradient can be added via shader if needed
	gauge_bar.add_theme_stylebox_override("fill", fill_style)

	add_child(gauge_bar)

## Create percentage label programmatically if not assigned
func _create_percentage_label() -> void:
	percentage_label = Label.new()
	percentage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	percentage_label.text = "0%"

	# Add font outline for better visibility
	percentage_label.add_theme_color_override("font_outline_color", Color.BLACK)
	percentage_label.add_theme_constant_override("outline_size", 2)

	# Position label below gauge bar
	if gauge_bar:
		percentage_label.position = Vector2(0, gauge_bar.custom_minimum_size.y + 4)

	add_child(percentage_label)
#endregion
