## Projectile for Space Shooter
##
## Simple projectile that moves in a direction and deals damage.
## Integrates with MilitiaForge2D's Hitbox component.

extends Node2D

#region Exports
@export var speed: float = 500.0
@export var damage: int = 10
@export var lifetime: float = 3.0
@export var is_player_projectile: bool = true
#endregion

#region Private Variables
var direction: Vector2 = Vector2.UP
var time_alive: float = 0.0
#endregion

func _ready() -> void:
	print("[Projectile] Created: is_player=%s" % is_player_projectile)

	# Create visual
	_create_visual()

	# Create Hitbox component to damage enemies
	_create_hitbox()

func _create_visual() -> void:
	var visual = ColorRect.new()
	if is_player_projectile:
		visual.size = Vector2(4, 12)
		visual.position = Vector2(-2, -6)
		visual.color = Color(0.3, 0.8, 1.0)  # Cyan
	else:
		visual.size = Vector2(6, 6)
		visual.position = Vector2(-3, -3)
		visual.color = Color(1.0, 0.3, 0.3)  # Red

	add_child(visual)

	# Add glow effect
	var glow = ColorRect.new()
	glow.size = visual.size * 1.5
	glow.position = visual.position - visual.size * 0.25
	glow.color = visual.color
	glow.color.a = 0.3
	add_child(glow)
	glow.z_index = -1

func _create_hitbox() -> void:
	# Create Hitbox component that will damage Hurtboxes
	var hitbox = Hitbox.new()
	hitbox.name = "ProjectileHitbox"
	hitbox.damage = damage
	hitbox.hit_once_per_target = true  # Only hit once per target
	# NOTE: Don't use one_shot here - it causes race condition with Hurtbox checking hitbox.active
	# The projectile will be destroyed via queue_free() in _on_hitbox_hit callback instead
	hitbox.debug_hitbox = true  # Enable debug

	# Setup collision layers
	if is_player_projectile:
		hitbox.collision_layer = 4  # Player projectile layer
		hitbox.collision_mask = 2   # Enemy layer
	else:
		hitbox.collision_layer = 8  # Enemy projectile layer
		hitbox.collision_mask = 1   # Player layer

	# IMPORTANT: Explicitly enable monitoring and monitorable for Area2D collision
	hitbox.monitoring = true
	hitbox.monitorable = true

	# Create collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	if is_player_projectile:
		shape.size = Vector2(4, 12)
	else:
		shape.size = Vector2(6, 6)
	collision.shape = shape
	hitbox.add_child(collision)

	add_child(hitbox)

	# Connect hitbox signals to destroy projectile when it hits
	hitbox.hit_landed.connect(_on_hitbox_hit)

	# Add direct area_entered debug connection
	hitbox.area_entered.connect(func(area):
		print("[Projectile] Hitbox.area_entered SIGNAL called! Area: %s (is Hurtbox: %s)" % [
			area.name, area is Hurtbox
		])
	)

	print("[Projectile] Hitbox created: damage=%d, layer=%d, mask=%d, monitoring=%s, monitorable=%s" % [
		damage, hitbox.collision_layer, hitbox.collision_mask, hitbox.monitoring, hitbox.monitorable
	])

func _on_hitbox_hit(target: Node, damage_dealt: int) -> void:
	print("[Projectile] Hit target %s for %d damage! Destroying projectile..." % [target.name, damage_dealt])
	queue_free()

func _process(delta: float) -> void:
	# Move projectile
	position += direction * speed * delta

	# Update lifetime
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()

	# Remove if off screen
	var viewport_rect = get_viewport_rect()
	if position.x < -50 or position.x > viewport_rect.size.x + 50 or \
	   position.y < -50 or position.y > viewport_rect.size.y + 50:
		queue_free()

func set_direction(new_direction: Vector2) -> void:
	direction = new_direction.normalized()

	# Rotate visual to match direction
	rotation = direction.angle() + PI / 2
