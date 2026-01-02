## Engine Trail Particles
##
## Creates a continuous engine trail effect for ships.
## Cyan/blue gradient matching the neon aesthetic.

extends GPUParticles2D

#region Constants
const NEON_CYAN: Color = Color(0.0, 0.94, 0.94)
const NEON_BLUE: Color = Color(0.2, 0.6, 1.0)
#endregion

#region Export Variables
@export var trail_color_start: Color = NEON_CYAN
@export var trail_color_end: Color = NEON_BLUE
@export var trail_length: float = 50.0
@export var particle_intensity: float = 1.0
#endregion

func _ready() -> void:
	_setup_particles()

func _setup_particles() -> void:
	# Particle configuration
	amount = int(30 * particle_intensity)
	lifetime = 0.5
	one_shot = false
	explosiveness = 0.0
	randomness = 0.3
	fixed_fps = 60
	emitting = true

	# Create process material
	var material = ParticleProcessMaterial.new()

	# Emission from point
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 3.0

	# Direction - straight down (ship is moving up)
	material.direction = Vector3(0, 1, 0)
	material.spread = 15.0
	material.flatness = 1.0

	# Initial velocity
	material.initial_velocity_min = trail_length * 1.5
	material.initial_velocity_max = trail_length * 2.5

	# No gravity
	material.gravity = Vector3.ZERO

	# Damping (fade as they move)
	material.damping_min = 20.0
	material.damping_max = 40.0

	# Scale (shrink over time)
	material.scale_min = 2.0
	material.scale_max = 4.0

	var scale_curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))
	scale_curve.add_point(Vector2(0.5, 0.5))
	scale_curve.add_point(Vector2(1.0, 0.1))
	material.scale_curve = scale_curve

	# Color gradient (cyan to blue, fade out)
	var gradient = Gradient.new()
	gradient.add_point(0.0, trail_color_start)
	gradient.add_point(0.5, Color(trail_color_end, 0.7))
	gradient.add_point(1.0, Color(trail_color_end, 0.0))
	material.color_ramp = gradient

	# Apply material
	process_material = material

	# Create texture (simple white circle)
	var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for x in range(8):
		for y in range(8):
			var dist = Vector2(x - 4, y - 4).length()
			if dist < 4.0:
				var alpha = 1.0 - (dist / 4.0)
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	texture = ImageTexture.create_from_image(image)

#region Public Methods
func set_trail_intensity(intensity: float) -> void:
	particle_intensity = intensity
	amount = int(30 * particle_intensity)

func set_trail_colors(start: Color, end: Color) -> void:
	trail_color_start = start
	trail_color_end = end
	if process_material:
		_setup_particles()

func start_trail() -> void:
	emitting = true

func stop_trail() -> void:
	emitting = false
#endregion
