## NeonFadeTransition - Hotline Miami Style Neon Fade
##
## Extension of FadeTransition with neon colors and screen flash.
## Specific to Space Shooter's aesthetic.

extends "res://addons/scene_transition/effects/fade_transition.gd"

#region Neon Colors
const NEON_PINK: Color = Color(1.0, 0.08, 0.58)
const NEON_CYAN: Color = Color(0.0, 0.94, 0.94)
const NEON_PURPLE: Color = Color(0.58, 0.0, 0.83)
#endregion

#region Private Variables
var _flash_rect: ColorRect = null
#endregion

func _setup() -> void:
	super._setup()

	# Use dark purple instead of black for neon aesthetic
	set_fade_color(Color(0.05, 0.0, 0.1))

	# Add neon flash overlay
	_flash_rect = ColorRect.new()
	_flash_rect.color = NEON_CYAN
	_flash_rect.anchor_right = 1.0
	_flash_rect.anchor_bottom = 1.0
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.modulate.a = 0.0
	add_child(_flash_rect)

## Override to add neon flash at midpoint
func _animate_in(tween: Tween, half_duration: float) -> void:
	super._animate_in(tween, half_duration)

	# Add quick neon flash at the peak
	tween.parallel().tween_property(_flash_rect, "modulate:a", 0.3, half_duration * 0.5)
	tween.tween_property(_flash_rect, "modulate:a", 0.0, half_duration * 0.5)

## Override to add neon flash on reveal
func _animate_out(tween: Tween, half_duration: float) -> void:
	# Quick flash when new scene appears
	_flash_rect.color = NEON_PINK
	_flash_rect.modulate.a = 0.2
	tween.tween_property(_flash_rect, "modulate:a", 0.0, half_duration * 0.3)

	# Then normal fade out
	tween.parallel().tween_property(_color_rect, "modulate:a", 0.0, half_duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
