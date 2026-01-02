## Projectile for Space Shooter
##
## Simple projectile that moves in a direction and deals damage.
## Integrates with MilitiaForge2D's Hitbox component.

extends Node2D

#region Signals
## Emitted when projectile should be returned to pool (instead of queue_free)
signal despawned
#endregion

#region Exports
@export var speed: float = 500.0
@export var damage: int = 10
@export var lifetime: float = 3.0
@export var is_player_projectile: bool = true
#endregion

#region Private Variables
var direction: Vector2 = Vector2.UP
var time_alive: float = 0.0
var hitbox: Node = null # Reference to Hitbox for cleanup
var is_being_destroyed: bool = false # Prevent multiple destruction calls
var use_pooling: bool = false # Set by pool manager if spawned from pool
#endregion

func _ready() -> void:
	print("[Projectile] Created: is_player=%s" % is_player_projectile)

	# Create visual
	_create_visual()

	# Create Hitbox component to damage enemies
	_create_hitbox()

func _create_visual() -> void:
	# Try to load sprite first
	var sprite_path: String
	var target_size: Vector2
	var fallback_color: Color
	
	if is_player_projectile:
		sprite_path = "res://examples/space_shooter/assets/sprites/player/projectiles/laser_blue.png"
		# Updated for 1920x1080: balanced size for visibility (4x12 -> 14x42)
		target_size = Vector2(14, 42)
		fallback_color = Color(0.3, 0.8, 1.0) # Cyan
	else:
		sprite_path = "res://examples/space_shooter/assets/sprites/enemies/projectiles/laser_red.png"
		# Updated for 1920x1080: increased 50% (6x6 -> 9x9)
		target_size = Vector2(9, 9)
		fallback_color = Color(1.0, 0.3, 0.3) # Red
	
	# Check if sprite exists
	var sprite_texture = load(sprite_path) if ResourceLoader.exists(sprite_path) else null
	
	if sprite_texture:
		# Use sprite
		var sprite = Sprite2D.new()
		sprite.texture = sprite_texture
		sprite.name = "ProjectileSprite"
		sprite.centered = true # Use Godot's built-in centering
		
		# Calculate scale to match target size
		var texture_size = sprite_texture.get_size()
		var scale_factor = target_size / texture_size
		sprite.scale = scale_factor
		
		add_child(sprite)
		print("[Projectile] Using sprite: %s (scale: %s, size: %s)" % [sprite_path, scale_factor, target_size])
	else:
		# Fallback to ColorRect
		print("[Projectile] Sprite not found (%s), using ColorRect fallback" % sprite_path)
		
		var visual = ColorRect.new()
		visual.size = target_size
		visual.position = - target_size / 2.0
		visual.color = fallback_color
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
	hitbox = Hitbox.new() # Store reference
	hitbox.name = "ProjectileHitbox"
	hitbox.damage = damage
	hitbox.hit_once_per_target = true # Only hit once per target
	# NOTE: Don't use one_shot here - it causes race condition with Hurtbox checking hitbox.active
	# The projectile will be destroyed via queue_free() in _on_hitbox_hit callback instead
	hitbox.debug_hitbox = true # Enable debug

	# Setup collision layers
	if is_player_projectile:
		hitbox.collision_layer = 4 # Player projectile layer
		hitbox.collision_mask = 2 # Enemy layer
	else:
		hitbox.collision_layer = 8 # Enemy projectile layer
		hitbox.collision_mask = 1 # Player layer

	# IMPORTANT: Explicitly enable monitoring and monitorable for Area2D collision
	hitbox.monitoring = true
	hitbox.monitorable = true

	# Create collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	if is_player_projectile:
		# Updated for 1920x1080: balanced size for visibility (4x12 -> 14x42)
		shape.size = Vector2(14, 42)
	else:
		# Updated for 1920x1080: increased 50% (6x6 -> 9x9)
		shape.size = Vector2(9, 9)
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
	# Prevent multiple calls
	if is_being_destroyed:
		return
	is_being_destroyed = true

	print("[Projectile] Hit target %s for %d damage! Destroying projectile..." % [target.name, damage_dealt])

	# Spawn impact particles at hit location
	_spawn_impact_particles()

	# Disable hitbox immediately to prevent further collisions
	# but keep it alive long enough for Hurtbox to process the damage
	if hitbox and is_instance_valid(hitbox):
		hitbox.monitoring = false
		hitbox.monitorable = false

	# Use call_deferred to ensure Hurtbox processes damage before projectile is destroyed
	call_deferred("_destroy_or_pool")

func _process(delta: float) -> void:
	# Move projectile
	position += direction * speed * delta

	# Update lifetime
	time_alive += delta
	if time_alive >= lifetime:
		_destroy_or_pool()
		return

	# Remove if off screen
	var viewport_rect = get_viewport_rect()
	if position.x < -50 or position.x > viewport_rect.size.x + 50 or \
	   position.y < -50 or position.y > viewport_rect.size.y + 50:
		_destroy_or_pool()

func set_direction(new_direction: Vector2) -> void:
	direction = new_direction.normalized()

	# Rotate visual to match direction
	rotation = direction.angle() + PI / 2

## Update collision layers based on is_player_projectile
## CRITICAL: Must be called when projectile is reconfigured from pool
func update_collision_layers() -> void:
	if not hitbox or not is_instance_valid(hitbox):
		return

	# Update collision layers to match current is_player_projectile setting
	if is_player_projectile:
		hitbox.collision_layer = 4 # Player projectile layer
		hitbox.collision_mask = 2 # Enemy layer
	else:
		hitbox.collision_layer = 8 # Enemy projectile layer
		hitbox.collision_mask = 1 # Player layer

	print("[Projectile] Collision layers updated: is_player=%s, layer=%d, mask=%d" % [
		is_player_projectile, hitbox.collision_layer, hitbox.collision_mask
	])

## Object Pooling: Reset projectile to default state when returned to pool
func reset_for_pool() -> void:
	# Reset state
	time_alive = 0.0
	is_being_destroyed = false
	direction = Vector2.UP

	# Re-enable hitbox if it was disabled
	if hitbox and is_instance_valid(hitbox):
		hitbox.monitoring = true
		hitbox.monitorable = true
		hitbox.active = true

	# Reset visual
	rotation = 0.0
	modulate = Color.WHITE

	print("[Projectile] Reset for pool reuse")

## Helper: Destroy or return to pool based on use_pooling flag
func _destroy_or_pool() -> void:
	if use_pooling:
		# Return to pool via signal
		despawned.emit(self)
	else:
		# Traditional destruction
		queue_free()

func _spawn_impact_particles() -> void:
	# Load impact particles script
	var ImpactParticles = load("res://examples/space_shooter/effects/impact_particles.gd")
	if not ImpactParticles:
		return

	# Create instance
	var impact = GPUParticles2D.new()
	impact.set_script(ImpactParticles)

	# Set color based on projectile type
	var impact_color: Color
	if is_player_projectile:
		impact_color = Color(1.0, 0.94, 0.0) # NEON_YELLOW for player
	else:
		impact_color = Color(1.0, 0.08, 0.58) # NEON_PINK for enemy

	# Position at impact location
	impact.global_position = global_position

	# Add to game world (not as child of projectile since projectile is being destroyed)
	get_tree().root.add_child(impact)

	# Configure impact ANTES de iniciar
	impact.set("impact_color", impact_color)
	impact.set("impact_size", 30.0)

	# Iniciar o impacto (isso chama _setup_particles com as cores corretas)
	impact.call("start_impact")

	# Play audio if AudioManager exists
	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("impact", 0.3)
