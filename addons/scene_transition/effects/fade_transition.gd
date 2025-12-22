## FadeTransition - Simple Fade to Black
##
## Classic fade transition effect.
## Fades to black, changes scene, then fades back in.

extends TransitionEffect

#region Configuration
var fade_color: Color = Color.BLACK
#endregion

#region Private Variables
var _color_rect: ColorRect = null
#endregion

func _setup() -> void:
	_color_rect = ColorRect.new()
	_color_rect.color = fade_color
	_color_rect.anchor_right = 1.0
	_color_rect.anchor_bottom = 1.0
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_color_rect)

## Fade IN - Screen goes black
func _animate_in(tween: Tween, half_duration: float) -> void:
	_color_rect.modulate.a = 0.0

	tween.tween_property(_color_rect, "modulate:a", 1.0, half_duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)

	# Emit midpoint when fade completes
	tween.tween_callback(emit_midpoint)

## Fade OUT - New scene fades in
func _animate_out(tween: Tween, half_duration: float) -> void:
	tween.tween_property(_color_rect, "modulate:a", 0.0, half_duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

## Allow custom fade color
func set_fade_color(color: Color) -> void:
	fade_color = color
	if _color_rect:
		_color_rect.color = color
