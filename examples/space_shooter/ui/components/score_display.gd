## Score Display Component
##
## Displays score with chromatic aberration effect and smooth counter animation.
## Neon cyberpunk style matching the game's HUD aesthetic.

extends VBoxContainer

#region Constants
const NEON_PINK: Color = Color(1.0, 0.08, 0.58)
const NEON_CYAN: Color = Color(0.0, 0.94, 0.94)
const NEON_YELLOW: Color = Color(1.0, 0.94, 0.0)
const NEON_PURPLE: Color = Color(0.58, 0.0, 0.83)
#endregion

#region Node References
var score_label: Label
var score_shadow: Label
var high_score_label: Label
#endregion

#region Animation Variables
var score_pulse_tween: Tween
var current_score: int = 0
var target_score: int = 0
var score_animation_speed: float = 500.0
#endregion

func _ready() -> void:
	_create_ui()

func _process(delta: float) -> void:
	# Smooth score counter animation
	if current_score < target_score:
		current_score += int(score_animation_speed * delta)
		if current_score > target_score:
			current_score = target_score
		_update_score_display()

func _create_ui() -> void:
	custom_minimum_size = Vector2(0, 150)
	add_theme_constant_override("separation", 40)

	# SCORE SECTION - With chromatic aberration
	var score_container = Control.new()
	score_container.custom_minimum_size = Vector2(0, 150)
	add_child(score_container)

	var score_title = Label.new()
	score_title.text = "▼ SCORE ▼"
	score_title.add_theme_font_size_override("font_size", 22)
	score_title.add_theme_color_override("font_color", NEON_YELLOW)
	score_title.position = Vector2(0, 0)
	score_container.add_child(score_title)

	# Score shadow (chromatic aberration - red offset)
	score_shadow = Label.new()
	score_shadow.text = "0"
	score_shadow.add_theme_font_size_override("font_size", 56)
	score_shadow.add_theme_color_override("font_color", Color(NEON_PINK.r, 0, 0, 0.5))
	score_shadow.position = Vector2(-3, 43)
	score_container.add_child(score_shadow)

	# Main score label (cyan on top)
	score_label = Label.new()
	score_label.text = "0"
	score_label.add_theme_font_size_override("font_size", 56)
	score_label.add_theme_color_override("font_color", NEON_CYAN)
	score_label.position = Vector2(0, 40)
	score_container.add_child(score_label)

	high_score_label = Label.new()
	high_score_label.text = "◆ HI: 0"
	high_score_label.add_theme_font_size_override("font_size", 18)
	high_score_label.add_theme_color_override("font_color", NEON_PURPLE)
	high_score_label.position = Vector2(0, 110)
	score_container.add_child(high_score_label)

	# Neon separator
	var sep = _create_neon_separator(NEON_YELLOW)
	add_child(sep)

func _create_neon_separator(color: Color) -> ColorRect:
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 3)
	sep.color = color
	return sep

#region Public Methods
func set_score(new_score: int) -> void:
	target_score = new_score
	_pulse()

func set_high_score(high_score: int) -> void:
	if high_score_label:
		high_score_label.text = "◆ HI: %d" % high_score

func get_current_score() -> int:
	return current_score

func set_animation_speed(speed: float) -> void:
	score_animation_speed = speed
#endregion

#region Private Methods
func _update_score_display() -> void:
	if score_label:
		score_label.text = "%d" % current_score
	if score_shadow:
		score_shadow.text = "%d" % current_score

func _pulse() -> void:
	if score_pulse_tween:
		score_pulse_tween.kill()

	score_pulse_tween = create_tween()
	score_pulse_tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.1)
	score_pulse_tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1)
#endregion
