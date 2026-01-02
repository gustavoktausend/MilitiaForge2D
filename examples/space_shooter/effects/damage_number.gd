## Damage Number
##
## Floating damage number that appears when entities take damage.
## Animates upward with fade out and scale effects.

extends Label

#region Constants
const NEON_WHITE: Color = Color(1.0, 1.0, 1.0)
const NEON_YELLOW: Color = Color(1.0, 0.94, 0.0)
const NEON_ORANGE: Color = Color(1.0, 0.5, 0.0)
const NEON_RED: Color = Color(1.0, 0.08, 0.08)
#endregion

#region Configuration
const FLOAT_SPEED: float = 60.0  # Pixels per second upward
const LIFETIME: float = 1.0  # Total animation duration
const FADE_START: float = 0.5  # When to start fading (percentage of lifetime)
const SCALE_BOUNCE: float = 1.3  # Initial scale bounce
const LATERAL_SPREAD: float = 30.0  # Random horizontal offset
#endregion

#region State
var _velocity: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0
var _start_position: Vector2
#endregion

func _ready() -> void:
	# Configure label appearance
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Add outline for better visibility (neon effect)
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	add_theme_constant_override("outline_size", 3)

	# Start position
	_start_position = position

	# Random lateral movement
	_velocity.x = randf_range(-LATERAL_SPREAD, LATERAL_SPREAD)
	_velocity.y = -FLOAT_SPEED

	# Initial scale bounce animation
	scale = Vector2.ONE * SCALE_BOUNCE
	var scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_elapsed += delta

	# Move upward with deceleration
	var progress = _elapsed / LIFETIME
	var decel = 1.0 - progress  # Slow down over time
	position += _velocity * delta * decel

	# Fade out in second half of lifetime
	if progress > FADE_START:
		var fade_progress = (progress - FADE_START) / (1.0 - FADE_START)
		modulate.a = 1.0 - fade_progress

	# Auto-destroy when finished
	if _elapsed >= LIFETIME:
		queue_free()

#region Public Methods
## Setup the damage number with value and color
func setup(damage: int, is_critical: bool = false, color: Color = NEON_WHITE) -> void:
	text = str(damage)

	# Determine color and size based on damage type
	if is_critical:
		add_theme_color_override("font_color", NEON_YELLOW)
		add_theme_font_size_override("font_size", 32)
	else:
		add_theme_color_override("font_color", color)
		add_theme_font_size_override("font_size", 24)

	# Larger numbers for bigger damage
	if damage >= 50:
		add_theme_font_size_override("font_size", 36)
	elif damage >= 25:
		add_theme_font_size_override("font_size", 28)

## Create a damage number at a specific position
static func create(damage: int, world_position: Vector2, parent: Node, is_critical: bool = false, color: Color = NEON_WHITE) -> void:
	var damage_number = Label.new()
	damage_number.set_script(load("res://examples/space_shooter/effects/damage_number.gd"))
	damage_number.position = world_position

	parent.add_child(damage_number)
	damage_number.setup(damage, is_critical, color)
#endregion
