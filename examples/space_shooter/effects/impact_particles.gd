## Impact Particles
##
## Creates a quick burst effect when projectiles hit targets.
## Yellow/orange flash matching the neon aesthetic.

extends GPUParticles2D

#region Constants
const NEON_YELLOW: Color = Color(1.0, 0.94, 0.0)
const NEON_ORANGE: Color = Color(1.0, 0.5, 0.0)
const NEON_WHITE: Color = Color(1.0, 1.0, 1.0)
#endregion

#region Export Variables
@export var impact_color: Color = NEON_YELLOW
@export var particle_count: int = 20
@export var impact_size: float = 30.0
#endregion

func _ready() -> void:
	# NÃO chamar _setup_particles() aqui ainda
	# Aguardar as propriedades serem configuradas primeiro
	pass

func start_impact() -> void:
	print("[ImpactParticles] Iniciando impacto com cor: ", impact_color)
	_setup_particles()

	# Auto-free after particles are done
	one_shot = true
	emitting = true

	# Wait for particles to finish, then free
	await get_tree().create_timer(lifetime + 0.1).timeout
	queue_free()

func _setup_particles() -> void:
	# Particle configuration - IMPACTO RÁPIDO E DISPERSO
	amount = particle_count
	lifetime = 0.15
	one_shot = true
	explosiveness = 1.0
	randomness = 0.8  # Mais randomness para dispersão
	fixed_fps = 60

	# Create process material
	var material = ParticleProcessMaterial.new()

	# Emission from point
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 1.0

	# Direction - RADIAL 360° sem viés vertical
	material.particle_flag_disable_z = true
	material.direction = Vector3(0, 0, 0)  # Sem direção preferencial
	material.spread = 180.0  # Dispersão completa
	material.flatness = 1.0

	# Initial velocity (burst rápido e disperso)
	material.initial_velocity_min = impact_size * 6.0
	material.initial_velocity_max = impact_size * 10.0  # Ainda mais variação

	# Radial accel - espalha partículas radialmente
	material.radial_accel_min = impact_size * 2.0
	material.radial_accel_max = impact_size * 4.0

	# No gravity
	material.gravity = Vector3.ZERO

	# Damping (slow down MUITO rápido)
	material.damping_min = 250.0
	material.damping_max = 350.0

	# Scale (partículas FINAS - menores que antes)
	material.scale_min = 0.8  # Mais fino
	material.scale_max = 1.8  # Máximo menor

	# Scale curve (shrink instantâneo)
	var scale_curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))
	scale_curve.add_point(Vector2(0.15, 0.3))  # Encolhe muito rápido
	scale_curve.add_point(Vector2(1.0, 0.0))
	material.scale_curve = scale_curve

	# Color inicial
	material.color = impact_color

	# Color gradient - SEM flash branco, direto na cor neon
	var gradient = Gradient.new()
	gradient.add_point(0.0, impact_color)  # Começa direto na cor neon
	gradient.add_point(0.3, impact_color)  # Mantém a cor
	gradient.add_point(0.6, Color(impact_color.r, impact_color.g, impact_color.b, 0.6))
	gradient.add_point(1.0, Color(impact_color.r, impact_color.g, impact_color.b, 0.0))
	material.color_ramp = gradient

	print("[ImpactParticles] Gradiente configurado com cor: ", impact_color)
	print("[ImpactParticles] Material.color definido para: ", material.color)

	# Apply material
	process_material = material

	# Create texture - LINHA FINA (não círculo)
	# Textura alongada para criar efeito de "faísca"
	var image = Image.create(2, 6, false, Image.FORMAT_RGBA8)  # 2x6 = linha vertical fina
	for y in range(6):
		for x in range(2):
			# Gradiente vertical (mais intenso no centro)
			var center_dist = abs(y - 2.5) / 3.0  # Distância do centro vertical
			var alpha = 1.0 - center_dist
			alpha = clamp(alpha, 0.0, 1.0)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	texture = ImageTexture.create_from_image(image)

#region Public Methods
func set_impact_color(color: Color) -> void:
	impact_color = color
	if process_material:
		_setup_particles()

func set_impact_size(size: float) -> void:
	impact_size = size
	if process_material:
		var material = process_material as ParticleProcessMaterial
		material.initial_velocity_min = impact_size * 6.0
		material.initial_velocity_max = impact_size * 10.0
		material.radial_accel_min = impact_size * 2.0
		material.radial_accel_max = impact_size * 4.0
#endregion
