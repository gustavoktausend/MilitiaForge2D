## GlitchTransition - Hotline Miami Style Glitch Effect
##
## Creates a chaotic glitch/distortion effect with:
## - RGB color separation (chromatic aberration)
## - Screen tearing simulation
## - Static noise
## - Random color flashing
##
## Perfect for Hotline Miami aesthetic!

extends TransitionEffect

#region Neon Colors (Hotline Miami Palette)
const NEON_PINK: Color = Color(1.0, 0.08, 0.58)
const NEON_CYAN: Color = Color(0.0, 0.94, 0.94)
const NEON_YELLOW: Color = Color(1.0, 0.94, 0.0)
const NEON_PURPLE: Color = Color(0.58, 0.0, 0.83)
#endregion

#region Configuration
var glitch_intensity: float = 1.0
var color_separation: float = 10.0
var flash_count: int = 8
#endregion

#region Private Variables
var _main_overlay: ColorRect = null
var _glitch_layers: Array[ColorRect] = []
var _noise_rect: ColorRect = null
var _tear_lines: Array[ColorRect] = []
#endregion

func _setup() -> void:
	# Main black overlay
	_main_overlay = ColorRect.new()
	_main_overlay.color = Color.BLACK
	_main_overlay.anchor_right = 1.0
	_main_overlay.anchor_bottom = 1.0
	_main_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_main_overlay)

	# RGB separation layers
	_create_rgb_layers()

	# Screen tear simulation
	_create_tear_lines()

	# Static noise overlay
	_create_noise_overlay()

func _create_rgb_layers() -> void:
	# Red layer
	var red_layer = ColorRect.new()
	red_layer.color = Color(1, 0, 0, 0.3)
	red_layer.anchor_right = 1.0
	red_layer.anchor_bottom = 1.0
	red_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(red_layer)
	_glitch_layers.append(red_layer)

	# Green layer
	var green_layer = ColorRect.new()
	green_layer.color = Color(0, 1, 0, 0.3)
	green_layer.anchor_right = 1.0
	green_layer.anchor_bottom = 1.0
	green_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(green_layer)
	_glitch_layers.append(green_layer)

	# Blue layer
	var blue_layer = ColorRect.new()
	blue_layer.color = Color(0, 0, 1, 0.3)
	blue_layer.anchor_right = 1.0
	blue_layer.anchor_bottom = 1.0
	blue_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(blue_layer)
	_glitch_layers.append(blue_layer)

func _create_tear_lines() -> void:
	# Create horizontal "tear" lines
	for i in range(5):
		var tear = ColorRect.new()
		tear.color = NEON_CYAN
		tear.anchor_right = 1.0
		tear.size.y = randf_range(2, 5)
		tear.position.y = randf_range(0, 1080)
		tear.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tear.modulate.a = 0.0
		add_child(tear)
		_tear_lines.append(tear)

func _create_noise_overlay() -> void:
	_noise_rect = ColorRect.new()
	_noise_rect.color = Color.WHITE
	_noise_rect.anchor_right = 1.0
	_noise_rect.anchor_bottom = 1.0
	_noise_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_noise_rect.modulate.a = 0.0
	add_child(_noise_rect)

## Glitch IN - Chaos intensifies
func _animate_in(tween: Tween, half_duration: float) -> void:
	_main_overlay.modulate.a = 0.0

	# Main overlay fade in
	tween.tween_property(_main_overlay, "modulate:a", 1.0, half_duration * 0.7)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_IN)

	# RGB chromatic aberration
	_animate_rgb_separation(tween, half_duration)

	# Screen tears
	_animate_tears(tween, half_duration)

	# Flash effects
	_animate_flashes(tween, half_duration)

	# Static noise bursts
	_animate_noise(tween, half_duration)

	# Emit midpoint at 70% through the IN animation
	tween.tween_callback(emit_midpoint).set_delay(half_duration * 0.7)

## Glitch OUT - Chaos fades away
func _animate_out(tween: Tween, half_duration: float) -> void:
	# Quick fade out of all elements
	tween.tween_property(_main_overlay, "modulate:a", 0.0, half_duration)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_OUT)

	for layer in _glitch_layers:
		tween.parallel().tween_property(layer, "modulate:a", 0.0, half_duration)

	for tear in _tear_lines:
		tween.parallel().tween_property(tear, "modulate:a", 0.0, half_duration)

	tween.parallel().tween_property(_noise_rect, "modulate:a", 0.0, half_duration)

func _animate_rgb_separation(tween: Tween, duration: float) -> void:
	# Offset each RGB layer to create chromatic aberration
	tween.parallel().tween_property(_glitch_layers[0], "position:x", color_separation, duration * 0.3)
	tween.parallel().tween_property(_glitch_layers[1], "position:x", -color_separation, duration * 0.3)
	tween.parallel().tween_property(_glitch_layers[2], "position:y", color_separation * 0.5, duration * 0.3)

	# Fade in RGB layers
	for layer in _glitch_layers:
		tween.parallel().tween_property(layer, "modulate:a", 0.5, duration * 0.3)

	# Jitter effect - rapid position changes
	for i in range(flash_count):
		var delay = (duration * 0.3) + (i * (duration * 0.4 / flash_count))
		tween.tween_callback(func(): _jitter_rgb_layers()).set_delay(delay / flash_count)

func _animate_tears(tween: Tween, duration: float) -> void:
	for i in range(_tear_lines.size()):
		var tear = _tear_lines[i]
		var delay = i * (duration / _tear_lines.size())

		# Flash in
		tween.tween_property(tear, "modulate:a", 0.8, 0.05).set_delay(delay)
		# Move horizontally (screen tear effect)
		tween.parallel().tween_property(tear, "position:x", randf_range(-50, 50), 0.1)
		# Flash out
		tween.tween_property(tear, "modulate:a", 0.0, 0.1)

func _animate_flashes(tween: Tween, duration: float) -> void:
	var flash_interval = duration / flash_count

	for i in range(flash_count):
		var delay = i * flash_interval
		tween.tween_callback(func(): _random_color_flash()).set_delay(delay)

func _animate_noise(tween: Tween, duration: float) -> void:
	# Random noise bursts
	for i in range(4):
		var delay = randf_range(0, duration)
		tween.tween_property(_noise_rect, "modulate:a", 0.3, 0.03).set_delay(delay)
		tween.tween_property(_noise_rect, "modulate:a", 0.0, 0.03)

func _jitter_rgb_layers() -> void:
	for layer in _glitch_layers:
		layer.position = Vector2(
			randf_range(-color_separation, color_separation),
			randf_range(-color_separation * 0.5, color_separation * 0.5)
		)

func _random_color_flash() -> void:
	var colors = [NEON_PINK, NEON_CYAN, NEON_YELLOW, NEON_PURPLE]
	_main_overlay.color = colors[randi() % colors.size()]

	# Quick return to black
	var flash_tween = create_tween()
	flash_tween.tween_property(_main_overlay, "color", Color.BLACK, 0.05)
