## TransitionEffect - Base Class
##
## Abstract base class for all transition effects.
## Follows Open/Closed Principle - open for extension, closed for modification.
##
## To create custom effects:
##   1. Extend this class
##   2. Override _setup() to create your visual elements
##   3. Override _animate_in() to show the effect
##   4. Override _animate_out() to hide the effect
##   5. Call emit_midpoint() when screen is fully covered
##   6. Call emit_finished() when animation completes

extends Control
class_name TransitionEffect

#region Signals
signal transition_midpoint()  # Emitted when screen is fully covered (scene change happens here)
signal transition_finished()  # Emitted when entire transition completes
#endregion

#region Protected Variables
var _duration: float = 1.0
var _tween: Tween = null
var _is_ready: bool = false
#endregion

func _init() -> void:
	# Fill entire screen
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	hide()  # Hidden by default
	_setup()
	_is_ready = true

## Override this to setup your visual elements (nodes, materials, etc)
func _setup() -> void:
	pass

## Main entry point - plays the full transition
func play_transition(duration: float) -> void:
	_duration = duration

	# Ensure _ready() was called
	if not _is_ready:
		push_warning("[TransitionEffect] play_transition called before _ready()! Calling _setup() manually...")
		_setup()
		_is_ready = true

	show()

	# Kill existing tween
	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()

	# Transition IN (cover screen)
	_animate_in(_tween, duration / 2.0)

	# Wait for midpoint callback from child class
	# Child MUST call emit_midpoint() when screen is fully covered!

	# Transition OUT (reveal new scene)
	_animate_out(_tween, duration / 2.0)

	# Finish
	_tween.tween_callback(_on_animation_complete)

## Override this to animate the effect IN (covering the screen)
## MUST call emit_midpoint() when screen is fully covered!
func _animate_in(tween: Tween, half_duration: float) -> void:
	push_error("[TransitionEffect] _animate_in() not implemented in subclass!")

## Override this to animate the effect OUT (revealing new scene)
func _animate_out(tween: Tween, half_duration: float) -> void:
	push_error("[TransitionEffect] _animate_out() not implemented in subclass!")

## Called when transition animation completes
func _on_animation_complete() -> void:
	hide()
	emit_finished()

## Call this from _animate_in() when screen is fully covered
func emit_midpoint() -> void:
	transition_midpoint.emit()

## Call this when transition is complete
func emit_finished() -> void:
	transition_finished.emit()

## Cleanup
func _exit_tree() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
