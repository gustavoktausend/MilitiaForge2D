## Space Background with Parallax Scrolling
##
## Creates a scrolling starfield background for the space shooter.
## Uses ScrollComponent from MilitiaForge2D.

extends Node2D

#region Exports
@export var scroll_speed: float = 50.0
@export var num_stars: int = 100
@export var star_color: Color = Color(1.0, 1.0, 1.0, 0.8)
#endregion

#region Private Variables
var stars: Array[Dictionary] = []
var viewport_size: Vector2
#endregion

func _ready() -> void:
	viewport_size = get_viewport_rect().size
	_create_starfield()

func _create_starfield() -> void:
	# Create multiple layers of stars for parallax effect
	_create_star_layer(30, 20.0, 1.0, Color(0.5, 0.5, 0.6, 0.3))  # Far stars (slow, small, dim)
	_create_star_layer(40, 40.0, 2.0, Color(0.8, 0.8, 1.0, 0.6))  # Mid stars
	_create_star_layer(30, scroll_speed, 3.0, Color(1.0, 1.0, 1.0, 1.0))  # Near stars (fast, large, bright)

func _create_star_layer(count: int, speed: float, size: float, color: Color) -> void:
	for i in range(count):
		var star = {
			"position": Vector2(
				randf_range(0, viewport_size.x),
				randf_range(0, viewport_size.y)
			),
			"speed": speed,
			"size": size,
			"color": color,
			"twinkle": randf_range(0, TAU)
		}
		stars.append(star)

func _process(delta: float) -> void:
	_update_stars(delta)
	queue_redraw()

func _update_stars(delta: float) -> void:
	for star in stars:
		# Move star down
		star.position.y += star.speed * delta

		# Wrap around when going off screen
		if star.position.y > viewport_size.y + 10:
			star.position.y = -10
			star.position.x = randf_range(0, viewport_size.x)

		# Update twinkle
		star.twinkle += delta * 2.0

func _draw() -> void:
	for star in stars:
		# Add subtle twinkling effect
		var twinkle_alpha = 0.8 + sin(star.twinkle) * 0.2
		var star_color_twinkle = star.color
		star_color_twinkle.a *= twinkle_alpha

		# Draw star
		draw_circle(star.position, star.size, star_color_twinkle)

		# Add glow for larger stars
		if star.size > 2.0:
			var glow_color = star_color_twinkle
			glow_color.a *= 0.3
			draw_circle(star.position, star.size * 2.0, glow_color)
