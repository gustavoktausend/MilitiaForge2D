## Wave Display Component
##
## Displays current wave number with pulse animation on wave change.
## Neon pink styling to match the game's HUD aesthetic.

extends VBoxContainer

#region Constants
const NEON_PINK: Color = Color(1.0, 0.08, 0.58)
const NEON_YELLOW: Color = Color(1.0, 0.94, 0.0)
#endregion

#region Node References
var wave_label: Label
#endregion

func _ready() -> void:
	_create_ui()

func _create_ui() -> void:
	add_theme_constant_override("separation", 10)

	# Wave title
	var wave_title = Label.new()
	wave_title.text = "▼ WAVE ▼"
	wave_title.add_theme_font_size_override("font_size", 22)
	wave_title.add_theme_color_override("font_color", NEON_YELLOW)
	add_child(wave_title)

	# Wave counter
	wave_label = Label.new()
	wave_label.text = "1 / 5"
	wave_label.add_theme_font_size_override("font_size", 38)
	wave_label.add_theme_color_override("font_color", NEON_PINK)
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(wave_label)

	# Add glow effect
	_add_glow_effect(wave_label, NEON_PINK)

	# Start background pulse animation
	_create_pulse_animation()

	# Neon separator
	var sep = _create_neon_separator(NEON_PINK)
	add_child(sep)

func _create_neon_separator(color: Color) -> ColorRect:
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 3)
	sep.color = color
	return sep

func _add_glow_effect(label: Label, glow_color: Color) -> void:
	# Outline effect simulates glow
	label.add_theme_color_override("font_outline_color", glow_color)
	label.add_theme_constant_override("outline_size", 4)

#region Public Methods
func set_wave(current: int, total: int) -> void:
	if wave_label:
		wave_label.text = "%d / %d" % [current, total]
		_pulse()

func get_current_wave_text() -> String:
	if wave_label:
		return wave_label.text
	return "1 / 5"
#endregion

#region Private Methods
func _create_pulse_animation() -> void:
	if not wave_label:
		return

	var tween = create_tween().set_loops()
	tween.tween_property(wave_label, "modulate:a", 0.6, 1.0)
	tween.tween_property(wave_label, "modulate:a", 1.0, 1.0)

func _pulse() -> void:
	if not wave_label:
		return

	# Pulse animation on wave change (more dramatic)
	var tween = create_tween()
	tween.tween_property(wave_label, "scale", Vector2(1.3, 1.3), 0.2)
	tween.tween_property(wave_label, "scale", Vector2(1.0, 1.0), 0.2)
#endregion
