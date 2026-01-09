## Turn Counter Display
##
## Displays current turn number with dynamic color coding.
## Changes color based on turn progress (cyan → yellow → red).
##
## @tutorial(Spell Battle): res://examples/spell_battle/README.md

class_name TurnCounterDisplay extends Label

#region Signals
## Emitted when turn changes
signal turn_updated(current_turn: int, max_turns: int)

## Emitted when entering final turns
signal final_turns_warning()
#endregion

#region Exports
@export_group("Settings")
## Color for early turns (0-50%)
@export var early_color: Color = Color(0.0, 0.941, 0.941)  # Cyan

## Color for mid turns (50-80%)
@export var mid_color: Color = Color(1.0, 1.0, 0.0)  # Yellow

## Color for late turns (80-100%)
@export var late_color: Color = Color(1.0, 0.0, 0.0)  # Red

## Threshold for mid game (0.0-1.0)
@export var mid_threshold: float = 0.5

## Threshold for late game (0.0-1.0)
@export var late_threshold: float = 0.8

## Enable pulse animation in late game
@export var pulse_in_late_game: bool = true
#endregion

#region Private Variables
## Current turn number
var _current_turn: int = 0

## Maximum turns
var _max_turns: int = 10

## Is in late game
var _is_late_game: bool = false

## Pulse tween
var _pulse_tween: Tween
#endregion

#region Lifecycle
func _ready() -> void:
	# Setup default styling
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Add font outline for visibility
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 2)

	# Set initial text
	update_turn(0, 10)
#endregion

#region Public API
## Update turn display
## @param current_turn: Current turn number
## @param max_turns: Maximum number of turns
func update_turn(current_turn: int, max_turns: int) -> void:
	_current_turn = current_turn
	_max_turns = max_turns

	# Update text
	text = "TURN %d / %d" % [current_turn, max_turns]

	# Calculate turn progress
	var turn_progress: float = 0.0
	if max_turns > 0:
		turn_progress = float(current_turn) / float(max_turns)

	# Update color based on progress
	_update_color(turn_progress)

	# Start pulse animation if late game
	if turn_progress >= late_threshold and not _is_late_game:
		_is_late_game = true
		final_turns_warning.emit()
		if pulse_in_late_game:
			_start_pulse()
	elif turn_progress < late_threshold and _is_late_game:
		_is_late_game = false
		_stop_pulse()

	turn_updated.emit(current_turn, max_turns)

## Get current turn
## @returns: Current turn number
func get_current_turn() -> int:
	return _current_turn

## Get max turns
## @returns: Maximum turns
func get_max_turns() -> int:
	return _max_turns

## Get turn progress
## @returns: Progress as 0.0-1.0
func get_turn_progress() -> float:
	if _max_turns == 0:
		return 0.0
	return float(_current_turn) / float(_max_turns)
#endregion

#region Private Methods
## Update color based on turn progress
## @param progress: Turn progress as 0.0-1.0
func _update_color(progress: float) -> void:
	var display_color: Color

	if progress >= late_threshold:
		# Late game: Red
		display_color = late_color
	elif progress >= mid_threshold:
		# Mid game: Yellow
		display_color = mid_color
	else:
		# Early game: Cyan
		display_color = early_color

	# Apply color
	add_theme_color_override("font_color", display_color)

## Start pulse animation for late game
func _start_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()

	# Create pulsing scale animation
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()  # Infinite loop

	# Pulse from 1.0 to 1.2 and back
	_pulse_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)

	_pulse_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)

## Stop pulse animation
func _stop_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null

	# Reset scale
	scale = Vector2(1.0, 1.0)
#endregion
