## Navi Health Widget
##
## Displays Navi HP with animated progress bar and numeric text.
## Features smooth Tween animations and color-coded HP percentage.
##
## @tutorial(Spell Battle): res://examples/spell_battle/README.md

class_name NaviHealthWidget extends Control

#region Signals
## Emitted when HP changes
signal hp_updated(current_hp: int, max_hp: int)

## Emitted when HP reaches critical level (< 25%)
signal critical_hp()
#endregion

#region Exports
@export_group("Visual Nodes")
## Progress bar for HP visualization
@export var hp_bar: ProgressBar

## Label for numeric HP display
@export var hp_label: Label

@export_group("Settings")
## Animation duration for HP changes
@export var animation_duration: float = 0.3

## Enable smooth animations
@export var animate_changes: bool = true

## Critical HP threshold (0.0-1.0)
@export var critical_threshold: float = 0.25
#endregion

#region Private Variables
## Current tween animation
var _tween: Tween

## Navi theme color
var _navi_color: Color = Color.CYAN

## Is HP currently critical
var _is_critical: bool = false
#endregion

#region Lifecycle
func _ready() -> void:
	# Auto-create nodes if not assigned
	if not hp_bar:
		_create_hp_bar()

	if not hp_label:
		_create_hp_label()

	# Setup initial state
	if hp_bar:
		hp_bar.value = hp_bar.max_value
#endregion

#region Public API
## Initialize widget with Navi data
## @param max_hp: Maximum HP value
## @param current_hp: Current HP value (defaults to max_hp)
func initialize(max_hp: int, current_hp: int = -1) -> void:
	if current_hp < 0:
		current_hp = max_hp

	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp

	update_hp(current_hp, max_hp, false)

## Update HP display
## @param current_hp: New current HP
## @param max_hp: Maximum HP
## @param animate: Whether to animate the change
func update_hp(current_hp: int, max_hp: int, animate: bool = true) -> void:
	if not hp_bar or not hp_label:
		return

	# Update max value
	hp_bar.max_value = max_hp

	# Update label text
	hp_label.text = "%d / %d HP" % [current_hp, max_hp]

	# Animate or instantly set value
	if animate and animate_changes and is_inside_tree():
		_animate_hp_change(current_hp)
	else:
		hp_bar.value = current_hp
		_update_hp_color(float(current_hp) / float(max_hp))

	# Check critical HP
	var hp_percentage = float(current_hp) / float(max_hp)
	if hp_percentage <= critical_threshold and not _is_critical:
		_is_critical = true
		critical_hp.emit()
	elif hp_percentage > critical_threshold:
		_is_critical = false

	hp_updated.emit(current_hp, max_hp)

## Set Navi theme color for the widget
## @param color: Navi's color theme
func set_navi_color(color: Color) -> void:
	_navi_color = color

	# Update bar color immediately
	if hp_bar and hp_bar.max_value > 0:
		var hp_percentage = hp_bar.value / hp_bar.max_value
		_update_hp_color(hp_percentage)

## Get current HP percentage
## @returns: HP as 0.0-1.0
func get_hp_percentage() -> float:
	if not hp_bar or hp_bar.max_value == 0:
		return 0.0
	return hp_bar.value / hp_bar.max_value
#endregion

#region Private Methods
## Animate HP change with Tween
func _animate_hp_change(target_hp: int) -> void:
	# Kill existing tween
	if _tween:
		_tween.kill()

	# Create new tween
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_OUT)

	# Animate bar value
	_tween.tween_property(hp_bar, "value", float(target_hp), animation_duration)

	# Update color during animation
	_tween.tween_callback(_update_hp_color.bind(float(target_hp) / hp_bar.max_value))

## Update HP bar color based on percentage
## @param hp_percentage: HP as 0.0-1.0
func _update_hp_color(hp_percentage: float) -> void:
	if not hp_bar:
		return

	var bar_color: Color

	# Color gradient based on HP percentage
	if hp_percentage > 0.75:
		# High HP: Green
		bar_color = Color(0.0, 1.0, 0.0)  # Green
	elif hp_percentage > 0.5:
		# Medium-High HP: Yellow-Green
		var lerp_factor = (hp_percentage - 0.5) / 0.25
		bar_color = Color(0.0, 1.0, 0.0).lerp(Color(1.0, 1.0, 0.0), 1.0 - lerp_factor)
	elif hp_percentage > 0.25:
		# Medium HP: Yellow to Orange
		var lerp_factor = (hp_percentage - 0.25) / 0.25
		bar_color = Color(1.0, 1.0, 0.0).lerp(Color(1.0, 0.5, 0.0), 1.0 - lerp_factor)
	else:
		# Low HP: Orange to Red
		var lerp_factor = hp_percentage / 0.25
		bar_color = Color(1.0, 0.5, 0.0).lerp(Color(1.0, 0.0, 0.0), 1.0 - lerp_factor)

	# Apply color to progress bar
	if hp_bar.has_theme_stylebox_override("fill"):
		var fill_style = hp_bar.get_theme_stylebox("fill")
		if fill_style is StyleBoxFlat:
			fill_style.bg_color = bar_color
	else:
		# Create StyleBoxFlat if doesn't exist
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = bar_color
		fill_style.border_width_left = 2
		fill_style.border_width_right = 2
		fill_style.border_width_top = 2
		fill_style.border_width_bottom = 2
		fill_style.border_color = _navi_color
		hp_bar.add_theme_stylebox_override("fill", fill_style)

## Create HP bar programmatically if not assigned
func _create_hp_bar() -> void:
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(200, 24)
	hp_bar.show_percentage = false
	hp_bar.max_value = 100
	hp_bar.value = 100

	# Create background style
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.125, 0.125, 0.188)  # Dark gray
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = _navi_color
	hp_bar.add_theme_stylebox_override("background", bg_style)

	# Create fill style (will be updated by _update_hp_color)
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.0, 1.0, 0.0)  # Green
	fill_style.border_width_left = 0
	fill_style.border_width_right = 0
	fill_style.border_width_top = 0
	fill_style.border_width_bottom = 0
	hp_bar.add_theme_stylebox_override("fill", fill_style)

	add_child(hp_bar)

## Create HP label programmatically if not assigned
func _create_hp_label() -> void:
	hp_label = Label.new()
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.text = "0 / 0 HP"

	# Add font outline for better visibility
	hp_label.add_theme_color_override("font_outline_color", Color.BLACK)
	hp_label.add_theme_constant_override("outline_size", 2)

	add_child(hp_label)
#endregion
