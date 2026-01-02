## Health Display Component
##
## Displays player health using Megaman X style segmented bars.
## Includes color-coded health value label and damage feedback effects.

extends VBoxContainer

#region Constants
const NEON_PINK: Color = Color(1.0, 0.08, 0.58)
const NEON_ORANGE: Color = Color(1.0, 0.41, 0.0)
const NEON_GREEN: Color = Color(0.0, 1.0, 0.5)
#endregion

#region Signals
signal damage_flash_requested(color: Color, duration: float)
signal shake_requested(intensity: float, duration: float)
#endregion

#region Node References
var health_bar: AmmoSegmentedBar
var health_value_label: Label
#endregion

func _ready() -> void:
	_create_ui()

func _create_ui() -> void:
	add_theme_constant_override("separation", 15)

	# Health title
	var health_title = Label.new()
	health_title.text = "▼ HULL INTEGRITY ▼"
	health_title.add_theme_font_size_override("font_size", 20)
	health_title.add_theme_color_override("font_color", NEON_GREEN)
	add_child(health_title)

	# Segmented health bar (Megaman X style)
	health_bar = AmmoSegmentedBar.new()
	health_bar.max_ammo = 100
	health_bar.current_ammo = 100
	health_bar.is_infinite = false
	health_bar.fill_bottom_to_top = true
	health_bar.animate_changes = true
	health_bar.pulse_when_low = true
	health_bar.low_ammo_threshold = 0.25
	health_bar.custom_minimum_size = Vector2(0, 80)
	add_child(health_bar)

	# Health value label (shows HP numerically)
	health_value_label = Label.new()
	health_value_label.text = "100 / 100 HP"
	health_value_label.add_theme_font_size_override("font_size", 20)
	health_value_label.add_theme_color_override("font_color", NEON_GREEN)
	health_value_label.add_theme_color_override("font_outline_color", Color.BLACK)
	health_value_label.add_theme_constant_override("outline_size", 6)
	health_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(health_value_label)

	# Neon separator
	var sep = _create_neon_separator(NEON_GREEN)
	add_child(sep)

func _create_neon_separator(color: Color) -> ColorRect:
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 3)
	sep.color = color
	return sep

#region Public Methods
func set_health(current: int, max_health: int) -> void:
	if not health_bar:
		return

	# Update max if it changed
	if health_bar.max_ammo != max_health:
		health_bar.max_ammo = max_health

	# Update current health (with animation)
	health_bar.current_ammo = current

	# Update text
	if health_value_label:
		health_value_label.text = "%d / %d HP" % [current, max_health]

	# Color shift based on health percentage
	_update_health_color(current, max_health)

func on_damage_taken(amount: int) -> void:
	# Request red screen flash from parent
	damage_flash_requested.emit(Color(NEON_PINK.r, 0, 0, 0.3), 0.15)

	# Flash health bar (Megaman X style)
	if health_bar:
		health_bar.flash(NEON_PINK, 0.2)

	# Shake health bar
	_shake_bar()

	# Request screen shake from parent
	shake_requested.emit(5.0, 0.2)

func initialize_health(max_health: int) -> void:
	if health_bar:
		health_bar.max_ammo = max_health
		health_bar.current_ammo = max_health
	if health_value_label:
		health_value_label.text = "%d / %d HP" % [max_health, max_health]
#endregion

#region Private Methods
func _update_health_color(current: int, max_health: int) -> void:
	if not health_value_label or max_health <= 0:
		return

	var health_percentage = float(current) / float(max_health)

	if health_percentage < 0.25:
		# Critical (below 25%) - Pink
		health_value_label.add_theme_color_override("font_color", NEON_PINK)
	elif health_percentage < 0.5:
		# Low (below 50%) - Orange
		health_value_label.add_theme_color_override("font_color", NEON_ORANGE)
	else:
		# Healthy (above 50%) - Green
		health_value_label.add_theme_color_override("font_color", NEON_GREEN)

func _shake_bar() -> void:
	if not health_bar:
		return

	var original_pos = health_bar.position
	var tween = create_tween()

	for i in range(5):
		tween.tween_property(health_bar, "position", original_pos + Vector2(randf_range(-3, 3), 0), 0.05)

	tween.tween_property(health_bar, "position", original_pos, 0.05)
#endregion
