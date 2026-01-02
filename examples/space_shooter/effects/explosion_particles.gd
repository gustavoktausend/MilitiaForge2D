## Neon Explosion Particles
##
## Creates a burst of neon particles for enemy explosions.
## Matches the game's Hotline Miami aesthetic with pink/cyan colors.

extends GPUParticles2D

#region Constants
const NEON_PINK: Color = Color(1.0, 0.08, 0.58)
const NEON_CYAN: Color = Color(0.0, 0.94, 0.94)
const NEON_YELLOW: Color = Color(1.0, 0.94, 0.0)
const NEON_PURPLE: Color = Color(0.58, 0.0, 0.83)
#endregion

#region Export Variables
@export var explosion_color: Color = NEON_PINK
@export var particle_count: int = 50
@export var explosion_radius: float = 100.0
@export var particle_lifetime: float = 1.0
@export var particle_scale: float = 3.0
#endregion

func _ready() -> void:
	_setup_particles()

	# Auto-free after particles are done
	one_shot = true
	emitting = true

	# Wait for particles to finish, then free
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _setup_particles() -> void:
	# Particle configuration - EXPLOSÃO RADIAL 360°
	amount = particle_count
	lifetime = particle_lifetime
	one_shot = true
	explosiveness = 0.9  # Pequena variação para efeito mais natural
	randomness = 0.7  # Mais randomness para variedade
	fixed_fps = 60

	# Create process material
	var material = ParticleProcessMaterial.new()

	# Emission from center point
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 3.0

	# Direction - RADIAL 360° (usando POINT ao invés de direcional)
	material.particle_flag_disable_z = true
	material.direction = Vector3(0, 0, 0)  # Sem direção preferencial
	material.spread = 180.0  # 180° = esfera completa em 2D
	material.flatness = 1.0  # Completamente flat (2D)

	# RADIAL velocity - explode em todas as direções
	material.initial_velocity_min = explosion_radius * 1.5
	material.initial_velocity_max = explosion_radius * 4.0  # Grande variação de velocidade

	# Radial accel - empurra partículas para fora do centro
	material.radial_accel_min = explosion_radius * 0.5
	material.radial_accel_max = explosion_radius * 1.5

	# Gravity effect (muito sutil, apenas para dar peso)
	material.gravity = Vector3(0, 20, 0)  # Gravidade leve para baixo

	# Damping (desacelera gradualmente)
	material.damping_min = 30.0
	material.damping_max = 80.0

	# Scale com grande variação para profundidade visual
	material.scale_min = particle_scale * 0.3
	material.scale_max = particle_scale * 2.0

	# Scale curve - partículas crescem um pouco e depois encolhem
	var scale_curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.5))  # Começam pequenas
	scale_curve.add_point(Vector2(0.2, 1.2))  # Crescem rápido
	scale_curve.add_point(Vector2(0.6, 0.8))  # Encolhem
	scale_curve.add_point(Vector2(1.0, 0.0))  # Desaparecem
	material.scale_curve = scale_curve

	# Color gradient (bright flash inicial, depois cor, depois fade)
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 1.0, 1.0, 1.0))  # Flash branco inicial
	gradient.add_point(0.1, explosion_color)  # Cor principal
	gradient.add_point(0.4, Color(explosion_color, 0.9))
	gradient.add_point(0.7, Color(explosion_color, 0.5))
	gradient.add_point(1.0, Color(explosion_color, 0.0))  # Fade completo
	material.color_ramp = gradient

	# Apply material
	process_material = material

	# Create texture (círculo com gradiente suave para melhor visual)
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
func set_explosion_color(color: Color) -> void:
	explosion_color = color
	if process_material:
		_setup_particles()

func set_explosion_size(radius: float) -> void:
	explosion_radius = radius
	if process_material:
		var material = process_material as ParticleProcessMaterial
		material.initial_velocity_min = explosion_radius * 1.5
		material.initial_velocity_max = explosion_radius * 4.0
		material.radial_accel_min = explosion_radius * 0.5
		material.radial_accel_max = explosion_radius * 1.5
#endregion
