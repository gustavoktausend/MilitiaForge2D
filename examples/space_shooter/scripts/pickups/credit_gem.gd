## Credit Gem
##
## Grants credits (currency) to the player when collected.
## Comes in 3 sizes: Small (25), Medium (50), Large (100)

extends PowerUpBase

#region Enums
enum GemSize {
	SMALL,   # 25 credits
	MEDIUM,  # 50 credits
	LARGE    # 100 credits
}
#endregion

#region Export Variables
@export var gem_size: GemSize = GemSize.SMALL
#endregion

#region Constants
const CREDIT_VALUES = {
	GemSize.SMALL: 25,
	GemSize.MEDIUM: 50,
	GemSize.LARGE: 100
}

const GEM_SIZES = {
	GemSize.SMALL: Vector2(16, 16),
	GemSize.MEDIUM: Vector2(24, 24),
	GemSize.LARGE: Vector2(32, 32)
}
#endregion

func _ready() -> void:
	pickup_value = CREDIT_VALUES[gem_size]
	despawn_time = 20.0  # Credits stay longer
	pickup_color = NEON_CYAN

	super._ready()

	# Create visual
	_create_gem_visual()

	# Create collision
	var size = GEM_SIZES[gem_size]
	create_collision_shape(size)

	print("[CreditGem] Created %s gem worth %d credits" % [GemSize.keys()[gem_size], pickup_value])

func _create_gem_visual() -> void:
	var visual_container = Node2D.new()
	visual_container.name = "Visual"
	add_child(visual_container)

	var size = GEM_SIZES[gem_size]

	# Diamond shape (4 triangles)
	var diamond = Polygon2D.new()
	var points = PackedVector2Array([
		Vector2(0, -size.y / 2),      # Top
		Vector2(size.x / 2, 0),        # Right
		Vector2(0, size.y / 2),        # Bottom
		Vector2(-size.x / 2, 0)        # Left
	])
	diamond.polygon = points
	diamond.color = NEON_CYAN
	visual_container.add_child(diamond)

	# Inner highlight
	var highlight = Polygon2D.new()
	var highlight_points = PackedVector2Array([
		Vector2(0, -size.y / 4),
		Vector2(size.x / 4, 0),
		Vector2(0, size.y / 4),
		Vector2(-size.x / 4, 0)
	])
	highlight.polygon = highlight_points
	highlight.color = Color(1.0, 1.0, 1.0, 0.6)
	visual_container.add_child(highlight)

	# Glow
	var glow_size = size * 1.5
	var glow = ColorRect.new()
	glow.size = glow_size
	glow.position = -glow_size / 2.0
	glow.color = Color(NEON_CYAN, 0.3)
	glow.z_index = -1
	visual_container.add_child(glow)

	visual_node = visual_container

	# Rotation + pulsing animation
	var tween = create_tween()
	tween.set_loops()
	tween.set_parallel(true)

	# Rotate
	tween.tween_property(visual_container, "rotation", TAU, 3.0)

	# Pulse
	tween.set_parallel(false)
	tween.tween_property(visual_container, "scale", Vector2(1.15, 1.15), 0.4)
	tween.tween_property(visual_container, "scale", Vector2(1.0, 1.0), 0.4)

func apply_effect(player: Node) -> void:
	# FASE 2: Add credits to game controller
	var game_controller = get_tree().get_first_node_in_group("game_controller")

	if game_controller and game_controller.has_method("add_credits"):
		game_controller.add_credits(pickup_value)
		print("[CreditGem] Added %d credits to player" % pickup_value)
	else:
		push_warning("[CreditGem] GameController not found or doesn't have add_credits method")

func _play_collect_feedback() -> void:
	# Override to play different pitch based on gem size
	_spawn_collect_particles()

	# Play sound with pitch variation
	if AudioManager and AudioManager.has_method("play_sfx"):
		var pitch = 1.0
		match gem_size:
			GemSize.SMALL:
				pitch = 1.0
			GemSize.MEDIUM:
				pitch = 1.2
			GemSize.LARGE:
				pitch = 1.4

		AudioManager.play_sfx("pickup_credit", 0.5)
