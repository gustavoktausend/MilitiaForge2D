## Ammo Segmented Bar - Megaman X Style
##
## Displays ammo as individual vertical bars (segments) instead of a continuous bar.
## Classic retro aesthetic with neon styling.
##
## Features:
## - Individual segments for each ammo unit
## - Fills from bottom to top (like Megaman X)
## - Different colors for different states (full, low, empty)
## - Pulse/flash animations when low or empty
## - Smooth fill/drain animations
##
## Design Pattern: Single Responsibility - only handles visual display of ammo

extends Control
class_name AmmoSegmentedBar

#region Signals
## Emitted when ammo display animation completes
signal animation_finished()
#endregion

#region Constants
# Megaman X style colors (neon version)
const COLOR_FULL: Color = Color(0.0, 0.94, 0.94)      # Bright cyan (full)
const COLOR_MID: Color = Color(1.0, 0.94, 0.0)        # Yellow (medium)
const COLOR_LOW: Color = Color(1.0, 0.41, 0.0)        # Orange (low)
const COLOR_CRITICAL: Color = Color(1.0, 0.08, 0.58)  # Hot pink (critical)
const COLOR_EMPTY: Color = Color(0.2, 0.2, 0.3)       # Dark gray (empty)
const COLOR_INFINITE: Color = Color(0.0, 1.0, 0.5)    # Toxic green (infinite)

# Segment dimensions
const SEGMENT_WIDTH: float = 8.0
const SEGMENT_HEIGHT: float = 16.0
const SEGMENT_SPACING: float = 2.0
const SEGMENTS_PER_ROW: int = 10  # 10 segments per row (like Megaman X)
#endregion

#region Exports
@export_group("Ammo Settings")
## Current ammo amount
@export var current_ammo: int = 0:
	set(value):
		if value != current_ammo:
			var old_ammo = current_ammo
			current_ammo = value
			_animate_ammo_change(old_ammo, current_ammo)
			queue_redraw()

## Maximum ammo capacity (-1 = infinite)
@export var max_ammo: int = 20:
	set(value):
		max_ammo = value
		_update_segments()
		queue_redraw()

## Whether to show infinite symbol instead of segments
@export var is_infinite: bool = false:
	set(value):
		is_infinite = value
		queue_redraw()

@export_group("Visual Settings")
## Segment fill direction (true = bottom to top, false = top to bottom)
@export var fill_bottom_to_top: bool = true

## Whether to animate ammo changes
@export var animate_changes: bool = true

## Whether to pulse when ammo is low
@export var pulse_when_low: bool = true

## Low ammo threshold (percentage)
@export_range(0.0, 1.0) var low_ammo_threshold: float = 0.25
#endregion

#region Private Variables
var _segments: Array[Rect2] = []
var _pulse_tween: Tween
var _fill_tween: Tween
var _pulse_alpha: float = 1.0
#endregion

#region Lifecycle
func _ready() -> void:
	custom_minimum_size = _calculate_minimum_size()
	_update_segments()

	# Start pulse animation if ammo is low
	if pulse_when_low and _is_ammo_low():
		_start_pulse_animation()

func _draw() -> void:
	if is_infinite:
		_draw_infinite_symbol()
	else:
		_draw_segments()

func _process(_delta: float) -> void:
	# Continuous check for low ammo pulse
	if pulse_when_low and not is_infinite:
		if _is_ammo_low() and not _pulse_tween:
			_start_pulse_animation()
		elif not _is_ammo_low() and _pulse_tween:
			_stop_pulse_animation()
#endregion

#region Public Methods
## Set ammo with animation
func set_ammo(new_ammo: int, new_max: int = -1) -> void:
	if new_max >= 0:
		max_ammo = new_max
	current_ammo = new_ammo

## Set infinite mode
func set_infinite(infinite: bool) -> void:
	is_infinite = infinite

## Flash the ammo display (for feedback)
func flash(color: Color = COLOR_CRITICAL, duration: float = 0.2) -> void:
	var original_modulate = modulate
	modulate = color

	var tween = create_tween()
	tween.tween_property(self, "modulate", original_modulate, duration)
#endregion

#region Private Methods - Drawing
## Draw infinite symbol (∞)
func _draw_infinite_symbol() -> void:
	var center = size / 2.0

	# Draw ∞ symbol using Label (simpler)
	var infinity_text = "∞"
	var font_size = 48

	# Draw glow effect
	draw_string(ThemeDB.fallback_font, center + Vector2(2, 2), infinity_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(COLOR_INFINITE, 0.3))

	# Draw main symbol
	draw_string(ThemeDB.fallback_font, center, infinity_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, COLOR_INFINITE)

## Draw segmented ammo bars
func _draw_segments() -> void:
	if _segments.is_empty():
		return

	var filled_segments = current_ammo

	for i in range(_segments.size()):
		var segment = _segments[i]
		var is_filled = i < filled_segments

		# Determine color based on fill state and ammo level
		var color: Color
		if is_filled:
			color = _get_segment_color(i, filled_segments)
		else:
			color = COLOR_EMPTY

		# Apply pulse alpha if low ammo
		if is_filled and _is_ammo_low():
			color.a = _pulse_alpha

		# Draw segment background (border)
		draw_rect(segment, Color(color, 0.3), false, 1.0)

		# Draw segment fill
		if is_filled:
			var inner_rect = segment.grow(-1.5)
			draw_rect(inner_rect, color, true)

			# Add glow effect
			var glow_rect = segment.grow(1.0)
			draw_rect(glow_rect, Color(color, 0.2), false, 2.0)

## Get color for a specific segment based on ammo level
func _get_segment_color(segment_index: int, total_filled: int) -> Color:
	var ammo_percentage = float(total_filled) / float(max_ammo)

	if ammo_percentage <= 0.1:  # Critical (10%)
		return COLOR_CRITICAL
	elif ammo_percentage <= low_ammo_threshold:  # Low
		return COLOR_LOW
	elif ammo_percentage <= 0.5:  # Medium
		return COLOR_MID
	else:  # Full
		return COLOR_FULL
#endregion

#region Private Methods - Layout
## Calculate minimum size based on max ammo
func _calculate_minimum_size() -> Vector2:
	if max_ammo <= 0:
		# Infinite ammo - just need space for symbol
		return Vector2(60, 60)

	# Calculate rows needed
	var rows = ceili(float(max_ammo) / float(SEGMENTS_PER_ROW))

	var width = SEGMENTS_PER_ROW * (SEGMENT_WIDTH + SEGMENT_SPACING) - SEGMENT_SPACING + 10
	var height = rows * (SEGMENT_HEIGHT + SEGMENT_SPACING) - SEGMENT_SPACING + 10

	return Vector2(width, height)

## Update segment positions
func _update_segments() -> void:
	_segments.clear()

	if max_ammo <= 0:
		return

	var rows = ceili(float(max_ammo) / float(SEGMENTS_PER_ROW))
	var start_pos = Vector2(5, 5)

	for i in range(max_ammo):
		var row: int
		var col: int

		if fill_bottom_to_top:
			# Fill from bottom-left, going right, then up
			var reverse_index = max_ammo - 1 - i
			row = reverse_index / SEGMENTS_PER_ROW
			col = reverse_index % SEGMENTS_PER_ROW
			row = rows - 1 - row  # Flip vertically
		else:
			# Fill from top-left, going right, then down
			row = i / SEGMENTS_PER_ROW
			col = i % SEGMENTS_PER_ROW

		var x = start_pos.x + col * (SEGMENT_WIDTH + SEGMENT_SPACING)
		var y = start_pos.y + row * (SEGMENT_HEIGHT + SEGMENT_SPACING)

		var segment_rect = Rect2(x, y, SEGMENT_WIDTH, SEGMENT_HEIGHT)
		_segments.append(segment_rect)

	custom_minimum_size = _calculate_minimum_size()
#endregion

#region Private Methods - Animations
## Animate ammo change (fill or drain)
func _animate_ammo_change(old_value: int, new_value: int) -> void:
	if not animate_changes:
		queue_redraw()
		return

	# Kill existing animation
	if _fill_tween:
		_fill_tween.kill()

	# Determine if filling or draining
	var is_filling = new_value > old_value

	# Create smooth animation
	_fill_tween = create_tween()

	# Animate step by step for visual feedback
	var steps = abs(new_value - old_value)
	var duration_per_step = 0.03  # Fast like Megaman X

	for i in range(steps):
		var target = old_value + (1 if is_filling else -1) * (i + 1)
		_fill_tween.tween_callback(func(): queue_redraw())
		_fill_tween.tween_interval(duration_per_step)

	_fill_tween.tween_callback(func(): animation_finished.emit())

## Start pulse animation for low ammo
func _start_pulse_animation() -> void:
	if _pulse_tween:
		return

	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(self, "_pulse_alpha", 0.3, 0.4)
	_pulse_tween.tween_callback(queue_redraw)
	_pulse_tween.tween_property(self, "_pulse_alpha", 1.0, 0.4)
	_pulse_tween.tween_callback(queue_redraw)

## Stop pulse animation
func _stop_pulse_animation() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
		_pulse_alpha = 1.0
		queue_redraw()

## Check if ammo is low
func _is_ammo_low() -> bool:
	if max_ammo <= 0:
		return false
	return float(current_ammo) / float(max_ammo) <= low_ammo_threshold
#endregion

#region Debug
## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"current_ammo": current_ammo,
		"max_ammo": max_ammo,
		"is_infinite": is_infinite,
		"segments_count": _segments.size(),
		"is_low": _is_ammo_low(),
		"pulse_active": _pulse_tween != null
	}
#endregion
