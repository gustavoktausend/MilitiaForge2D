## Combo Display Component
##
## Large centered combo counter with scale punch animation and auto fade-out.
## Positioned in the play area for maximum visual impact.

extends Label

#region Constants
const NEON_PINK: Color = Color(1.0, 0.08, 0.58)
const NEON_YELLOW: Color = Color(1.0, 0.94, 0.0)
#endregion

#region Signals
signal combo_flash_requested(color: Color, duration: float)
#endregion

#region Animation Variables
var combo_scale_tween: Tween
var fade_tween: Tween
#endregion

func _ready() -> void:
	_setup_label()

func _setup_label() -> void:
	text = ""
	add_theme_font_size_override("font_size", 72)
	add_theme_color_override("font_color", NEON_YELLOW)
	add_theme_color_override("font_outline_color", NEON_PINK)
	add_theme_constant_override("outline_size", 6)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	visible = false
	z_index = 50

#region Public Methods
func show_combo(combo: int, multiplier: float) -> void:
	if combo > 1:
		text = "◢ COMBO x%d ◣" % combo
		visible = true

		# Scale punch animation
		_play_scale_animation()

		# Auto fade out
		_play_fade_animation()

		# Request screen flash from parent
		combo_flash_requested.emit(Color(NEON_YELLOW.r, NEON_YELLOW.g, 0, 0.2), 0.2)
	else:
		hide_combo()

func hide_combo() -> void:
	visible = false
	text = ""
#endregion

#region Private Methods
func _play_scale_animation() -> void:
	if combo_scale_tween:
		combo_scale_tween.kill()

	combo_scale_tween = create_tween()
	combo_scale_tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
	combo_scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _play_fade_animation() -> void:
	if fade_tween:
		fade_tween.kill()

	# Reset alpha first
	modulate.a = 1.0

	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.8).set_delay(1.2)
	fade_tween.tween_callback(func():
		visible = false
		modulate.a = 1.0  # Reset for next time
	)
#endregion
