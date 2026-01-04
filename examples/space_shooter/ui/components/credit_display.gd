## Credit Display Component
##
## Displays player's credits (currency) with neon cyberpunk aesthetic.
## Smooth counter animation and visual feedback when gaining/spending credits.
## FASE 2: Economy System

extends VBoxContainer

#region Constants
const NEON_CYAN: Color = Color(0.0, 0.94, 0.94)
const NEON_YELLOW: Color = Color(1.0, 0.94, 0.0)
const NEON_GREEN: Color = Color(0.0, 1.0, 0.5)
const NEON_PINK: Color = Color(1.0, 0.08, 0.58)
#endregion

#region Node References
var credit_label: Label
var credit_shadow: Label
var credit_icon: Label
#endregion

#region Animation Variables
var pulse_tween: Tween
var current_credits: int = 0
var target_credits: int = 0
var animation_speed: float = 200.0
#endregion

func _ready() -> void:
	_create_ui()

func _process(delta: float) -> void:
	# Smooth credit counter animation
	if current_credits < target_credits:
		current_credits += int(animation_speed * delta)
		if current_credits > target_credits:
			current_credits = target_credits
		_update_display()
	elif current_credits > target_credits:
		current_credits -= int(animation_speed * delta)
		if current_credits < target_credits:
			current_credits = target_credits
		_update_display()

func _create_ui() -> void:
	custom_minimum_size = Vector2(0, 120)
	add_theme_constant_override("separation", 10)

	# CREDITS SECTION - With chromatic aberration
	var credit_container = Control.new()
	credit_container.custom_minimum_size = Vector2(0, 120)
	add_child(credit_container)

	var credit_title = Label.new()
	credit_title.text = "💎 CREDITS 💎"
	credit_title.add_theme_font_size_override("font_size", 20)
	credit_title.add_theme_color_override("font_color", NEON_CYAN)
	credit_title.position = Vector2(0, 0)
	credit_container.add_child(credit_title)

	# Credit shadow (chromatic aberration - green offset)
	credit_shadow = Label.new()
	credit_shadow.text = "0"
	credit_shadow.add_theme_font_size_override("font_size", 48)
	credit_shadow.add_theme_color_override("font_color", Color(0, NEON_GREEN.g, 0, 0.4))
	credit_shadow.position = Vector2(-2, 37)
	credit_container.add_child(credit_shadow)

	# Main credit label (cyan on top)
	credit_label = Label.new()
	credit_label.text = "0"
	credit_label.add_theme_font_size_override("font_size", 48)
	credit_label.add_theme_color_override("font_color", NEON_CYAN)
	credit_label.position = Vector2(0, 35)
	credit_container.add_child(credit_label)

	# Neon separator
	var sep = _create_neon_separator(NEON_CYAN)
	add_child(sep)

func _create_neon_separator(color: Color) -> ColorRect:
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 2)
	sep.color = color
	return sep

#region Public Methods
func set_credits(new_credits: int, delta: int = 0) -> void:
	target_credits = new_credits

	# Visual feedback based on gain/loss
	if delta > 0:
		_pulse_gain()
	elif delta < 0:
		_pulse_loss()

func get_current_credits() -> int:
	return current_credits
#endregion

#region Private Methods
func _update_display() -> void:
	if credit_label:
		credit_label.text = "%d" % current_credits
	if credit_shadow:
		credit_shadow.text = "%d" % current_credits

func _pulse_gain() -> void:
	# Green pulse when gaining credits
	if pulse_tween:
		pulse_tween.kill()

	pulse_tween = create_tween()
	pulse_tween.set_parallel(true)
	pulse_tween.tween_property(credit_label, "scale", Vector2(1.3, 1.3), 0.1)
	pulse_tween.tween_property(credit_label, "modulate", NEON_GREEN, 0.1)
	pulse_tween.set_parallel(false)
	pulse_tween.tween_property(credit_label, "scale", Vector2(1.0, 1.0), 0.15)
	pulse_tween.tween_property(credit_label, "modulate", NEON_CYAN, 0.15)

func _pulse_loss() -> void:
	# Pink pulse when spending credits
	if pulse_tween:
		pulse_tween.kill()

	pulse_tween = create_tween()
	pulse_tween.set_parallel(true)
	pulse_tween.tween_property(credit_label, "scale", Vector2(0.9, 0.9), 0.1)
	pulse_tween.tween_property(credit_label, "modulate", NEON_PINK, 0.1)
	pulse_tween.set_parallel(false)
	pulse_tween.tween_property(credit_label, "scale", Vector2(1.0, 1.0), 0.15)
	pulse_tween.tween_property(credit_label, "modulate", NEON_CYAN, 0.15)
#endregion
