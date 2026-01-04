## Power-Up Base Class
##
## Base class for all collectible power-ups in Space Shooter.
## Handles common behavior: collision detection, despawn timer, fade out.

class_name PowerUpBase extends Area2D

#region Signals
signal collected(player: Node)
signal despawned
#endregion

#region Constants
const NEON_GREEN: Color = Color(0.0, 1.0, 0.5)
const NEON_CYAN: Color = Color(0.0, 0.94, 0.94)
const NEON_YELLOW: Color = Color(1.0, 0.94, 0.0)
const NEON_PINK: Color = Color(1.0, 0.08, 0.58)
#endregion

#region Export Variables
@export var pickup_value: int = 1
@export var despawn_time: float = 15.0  # Time before auto-despawn
@export var fade_start_time: float = 3.0  # Start fading X seconds before despawn
@export var pickup_color: Color = NEON_GREEN
#endregion

#region Private Variables
var time_alive: float = 0.0
var is_collected: bool = false
var visual_node: Node2D = null
var original_modulate: Color = Color.WHITE
#endregion

func _ready() -> void:
	# Setup collision
	collision_layer = 16  # Pickup layer
	collision_mask = 1  # Player layer
	monitoring = true
	monitorable = true

	# Connect signals
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	# Store original color
	original_modulate = modulate

	print("[PowerUp] %s created at %v" % [get_class(), global_position])

func _process(delta: float) -> void:
	if is_collected:
		return

	time_alive += delta

	# Fade out before despawn
	var time_until_despawn = despawn_time - time_alive
	if time_until_despawn <= fade_start_time:
		var fade_progress = time_until_despawn / fade_start_time
		modulate.a = fade_progress

	# Auto-despawn after timer
	if time_alive >= despawn_time:
		_despawn()

func _on_area_entered(area: Area2D) -> void:
	# Check if it's player's hurtbox
	if area is Hurtbox:
		var player = _find_player_from_hurtbox(area)
		if player:
			collect(player)

func _on_body_entered(body: Node2D) -> void:
	# Check if it's the player's physics body
	if body.get_parent() and body.get_parent().is_in_group("player"):
		var player = body.get_parent()
		collect(player)
	elif body.is_in_group("player"):
		collect(body)

func _find_player_from_hurtbox(hurtbox: Area2D) -> Node:
	# Navigate up the tree to find player node
	var current = hurtbox.get_parent()
	while current:
		if current.is_in_group("player"):
			return current
		current = current.get_parent()
	return null

#region Public Methods
func collect(player: Node) -> void:
	if is_collected:
		return

	is_collected = true
	print("[PowerUp] Collected %s by player" % get_class())

	# Apply effect (override in subclasses)
	apply_effect(player)

	# Emit signal
	collected.emit(player)

	# Play collection particles/sound
	_play_collect_feedback()

	# Remove from scene
	queue_free()

## Override in subclasses to implement specific effect
func apply_effect(player: Node) -> void:
	push_warning("PowerUpBase.apply_effect() not implemented in %s" % get_class())

func _play_collect_feedback() -> void:
	# Spawn collection particles
	_spawn_collect_particles()

	# Play sound if AudioManager exists
	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("pickup", 0.4)

func _spawn_collect_particles() -> void:
	# Simple particle burst when collected
	var particles = GPUParticles2D.new()
	particles.global_position = global_position
	particles.amount = 15
	particles.lifetime = 0.3
	particles.one_shot = true
	particles.explosiveness = 1.0

	# Material
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 0, 0)
	material.spread = 180.0
	material.flatness = 1.0
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 100.0
	material.gravity = Vector3.ZERO
	material.damping_min = 100.0
	material.damping_max = 150.0
	material.scale_min = 1.0
	material.scale_max = 2.0

	# Color
	var gradient = Gradient.new()
	gradient.add_point(0.0, pickup_color)
	gradient.add_point(0.5, Color(pickup_color, 0.7))
	gradient.add_point(1.0, Color(pickup_color, 0.0))
	material.color_ramp = gradient

	particles.process_material = material

	# Texture
	var image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	particles.texture = ImageTexture.create_from_image(image)

	# Add to scene
	get_tree().root.add_child(particles)
	particles.emitting = true

	# Auto-free
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	particles.queue_free()

func _despawn() -> void:
	if is_collected:
		return

	print("[PowerUp] %s despawned (timeout)" % get_class())
	despawned.emit()
	queue_free()
#endregion

#region Visual Helpers
func create_visual(color: Color, size: Vector2 = Vector2(32, 32)) -> void:
	# Simple colored rect as fallback visual
	var visual = ColorRect.new()
	visual.size = size
	visual.position = -size / 2.0
	visual.color = color
	add_child(visual)
	visual_node = visual

func create_collision_shape(size: Vector2 = Vector2(32, 32)) -> void:
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	add_child(collision)
#endregion
