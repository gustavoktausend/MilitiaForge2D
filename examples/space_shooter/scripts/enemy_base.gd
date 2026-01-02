## Base Enemy Controller for Space Shooter
##
## Base class for all enemy types. Handles common enemy behavior
## using MilitiaForge2D components.

class_name SpaceEnemy extends Node2D

#region Signals
signal enemy_died(enemy: SpaceEnemy, score_value: int)
#endregion

#region Exports
@export_group("Enemy Stats")
@export var enemy_type: String = "Basic"
@export var health: int = 20
@export var speed: float = 100.0
@export var score_value: int = 100
@export var damage_to_player: int = 20

@export_group("Behavior")
@export var movement_pattern: MovementPattern = MovementPattern.STRAIGHT_DOWN
@export var can_shoot: bool = false
@export var fire_rate: float = 1.0
@export var projectile_damage: int = 10
#endregion

#region Enums
enum MovementPattern {
	STRAIGHT_DOWN,
	ZIGZAG,
	CIRCULAR,
	SINE_WAVE,
	TRACKING, # Follows player
	STOP_AND_SHOOT # Descends to a position and stops to shoot
}
#endregion

#region Component References
var host: ComponentHost
var movement_component: BoundedMovement
var health_component: HealthComponent
var weapon: Node # SimpleWeapon instance
var particles: ParticleEffectComponent
var physics_body: CharacterBody2D # Reference to the physics body
#endregion

#region Private Variables
var player: Node2D = null
var movement_time: float = 0.0
var initial_x: float = 0.0
var has_stopped: bool = false # For STOP_AND_SHOOT pattern
var stop_position_y: float = 150.0 # Y position where enemy stops
var shoot_timer: float = 0.0 # Timer for shooting
var lateral_movement_timer: float = 0.0 # For lateral movement while stopped
var zigzag_direction: float = 1.0 # Direction for zigzag movement (1.0 = right, -1.0 = left)
var _is_dying: bool = false # Prevent multiple death notifications
var _is_destroyed: bool = false # Prevent multiple queue_free calls
var _enemy_id: int = 0 # Unique ID for debugging
static var _next_id: int = 0 # Global counter for enemy IDs
#endregion

func _ready() -> void:
	# Assign unique ID for debugging
	_enemy_id = _next_id
	_next_id += 1

	print("[Enemy #%d] Creating %s enemy at position %v" % [_enemy_id, enemy_type, global_position])

	# Initialize zigzag direction randomly
	zigzag_direction = 1.0 if randf() > 0.5 else -1.0

	await _setup_components()
	_setup_visuals()
	_connect_signals()
	initial_x = global_position.x
	print("[Enemy] %s enemy ready! Physics body at: %v" % [enemy_type, physics_body.global_position if physics_body else Vector2.ZERO])

	# Player will be injected via set_target() - Dependency Injection pattern

## Dependency Injection: Set the target player for tracking/shooting
## This decouples Enemy from scene tree structure
func set_target(target_player: Node2D) -> void:
	player = target_player
	if player:
		print("[Enemy #%d] Target player set: %s" % [_enemy_id, player.name])
	else:
		print("[Enemy #%d] Target player cleared" % _enemy_id)

func _setup_components() -> void:
	# Add Physics Body FIRST (at root level)
	physics_body = CharacterBody2D.new()
	physics_body.name = "Body"

	# Configure collision layers for physical collisions
	physics_body.collision_layer = 2  # Enemy layer
	physics_body.collision_mask = 1   # Collide with player

	add_child(physics_body)
	print("[Enemy] %s CharacterBody2D created with layer=%d, mask=%d" % [
		enemy_type,
		physics_body.collision_layer,
		physics_body.collision_mask
	])

	# Add collision shape to physics body for physical collisions
	var body_collision = CollisionShape2D.new()
	var body_shape = RectangleShape2D.new()
	# Size depends on enemy type
	if enemy_type == "Tank":
		body_shape.size = Vector2(96, 96)
	else:
		body_shape.size = Vector2(48, 48)
	body_collision.shape = body_shape
	body_collision.name = "BodyCollisionShape"
	physics_body.add_child(body_collision)
	print("[Enemy] %s CharacterBody2D collision shape added (size: %v)" % [enemy_type, body_shape.size])

	# Create ComponentHost as CHILD of physics body
	# This allows MovementComponent to find the body as parent
	# and Hurtbox to find ComponentHost when searching upward
	host = ComponentHost.new()
	host.name = "EnemyHost"
	physics_body.add_child(host)

	# Add Sprite placeholder
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	physics_body.add_child(sprite)

	# CRITICAL: Wait for ComponentHost to be ready before adding components
	await get_tree().process_frame

	# Setup Health Component FIRST (before Hurtbox needs it)
	health_component = HealthComponent.new()
	health_component.max_health = health
	health_component.can_die = true
	health_component.debug_health = true # Enable debug to see health changes

	print("[Enemy] %s HealthComponent class name: %s" % [enemy_type, health_component.get_class()])
	host.add_component(health_component)
	print("[Enemy] %s HealthComponent added to host" % enemy_type)

	# Debug: Check if component was registered
	var test_lookup = host.get_component(health_component.get_class())
	print("[Enemy] %s Immediate lookup: %s" % [enemy_type, "Found" if test_lookup else "NOT FOUND"])

	# Add Hurtbox (will find HealthComponent when ready)
	# Hurtbox will search upward: Hurtbox -> Body -> finds ComponentHost as child
	var hurtbox = Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.debug_hurtbox = true # Enable debug to see if it's working

	# IMPORTANT: Disable Hurtbox during setup to prevent projectiles hitting before ready
	hurtbox.active = false
	hurtbox.monitoring = false
	hurtbox.monitorable = false

	# Create and add collision shape FIRST
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	# Size depends on enemy type: Tank is double size (96x96), others are 48x48
	if enemy_type == "Tank":
		shape.size = Vector2(96, 96) # Tank is double size
	else:
		shape.size = Vector2(48, 48) # Basic, Fast, and others
	collision.shape = shape
	hurtbox.add_child(collision)

	# Add Hurtbox to scene tree
	physics_body.add_child(hurtbox)

	# Wait for node to be in tree and ready (_ready() will be called during this frame)
	await get_tree().process_frame

	# WORKAROUND: Manually set the health component AFTER _ready() has been called
	# This is necessary because get_component() uses get_class() which returns "Node" instead of "HealthComponent"
	# The _ready() function calls _find_health_component() which sets _health_component to null
	# So we must override it AFTER _ready() has completed
	print("[Enemy] %s Setting _health_component on Hurtbox (before: %s)" % [
		enemy_type, hurtbox.get("_health_component") != null
	])
	hurtbox.set("_health_component", health_component)
	hurtbox.set("_component_host", host)
	print("[Enemy] %s _health_component set (after: %s)" % [
		enemy_type, hurtbox.get("_health_component") != null
	])

	# NOW configure collision layers and monitoring (after node is in tree)
	hurtbox.collision_layer = 2 # Enemy layer
	hurtbox.collision_mask = 4 # Player projectile layer
	hurtbox.active = true # Enable Hurtbox now that setup is complete
	hurtbox.monitoring = true
	hurtbox.monitorable = true

	print("[Enemy] %s Hurtbox ACTIVATED with layer=%d, mask=%d, active=%s, monitoring=%s, monitorable=%s" % [
		enemy_type, hurtbox.collision_layer, hurtbox.collision_mask, hurtbox.active, hurtbox.monitoring, hurtbox.monitorable
	])

	# Verify HealthComponent can be found after Hurtbox is added
	await get_tree().process_frame
	var found_health = host.get_component("HealthComponent")
	print("[Enemy] %s HealthComponent lookup test: %s" % [enemy_type, "Found" if found_health else "NOT FOUND"])

	# Setup Collision Damage Component
	print("[Enemy] %s Creating CollisionDamageComponent..." % enemy_type)
	var collision_damage = CollisionDamageComponent.new()
	collision_damage.damage_on_collision = damage_to_player  # Enemy deals configured damage on collision
	collision_damage.can_take_collision_damage = true  # Enemy takes damage from collisions
	collision_damage.incoming_damage_multiplier = 1.0  # Take full damage
	collision_damage.apply_knockback = true
	collision_damage.knockback_force = 200.0  # Moderate knockback
	collision_damage.collision_cooldown = 0.5
	host.add_component(collision_damage)
	print("[Enemy] %s CollisionDamageComponent ready! Collision damage: %d" % [enemy_type, damage_to_player])

	# Setup Movement Component (now physics body exists)
	movement_component = BoundedMovement.new()
	movement_component.max_speed = speed
	movement_component.acceleration = 500.0
	movement_component.boundary_mode = BoundedMovement.BoundaryMode.DESTROY
	movement_component.use_viewport_bounds = false # Use custom bounds for play area

	# Set custom bounds to match the play area (between HUD panels)
	await get_tree().process_frame
	var viewport_size = get_viewport().get_visible_rect().size
	# Updated for 1920x1080: side panels = 480px, play area = 960px
	var play_area_bounds = Rect2(
		Vector2(480, -100), # Start after left panel, allow spawning above screen
		Vector2(960, viewport_size.y + 200) # Play area width x extended height
	)
	movement_component.set_custom_bounds(play_area_bounds)
	movement_component.boundary_margin = Vector2(0, 0) # No margin, destroy at exact boundaries

	# Connect to boundary signal to handle enemy leaving screen
	if movement_component.has_signal("destroyed_by_boundary"):
		movement_component.destroyed_by_boundary.connect(_on_destroyed_by_boundary)

	host.add_component(movement_component)

	# Setup Weapon if can shoot (using SimpleWeapon for consistency)
	if can_shoot:
		weapon = Node.new()
		weapon.set_script(preload("res://examples/space_shooter/scripts/simple_weapon.gd"))
		weapon.name = "EnemyWeapon"
		add_child(weapon)
		# Configure after adding to tree
		await get_tree().process_frame
		weapon.fire_rate = fire_rate
		weapon.damage = projectile_damage  # FIXED: 'damage' instead of 'projectile_damage'
		weapon.projectile_speed = 400.0
		weapon.auto_fire = false
		weapon.is_player_weapon = false # Enemy weapon, projectiles should target player
		weapon.use_object_pooling = true  # Enable pooling
		weapon.pooled_projectile_type = "enemy_laser"  # Use enemy laser pool
		weapon.projectile_team = 1  # ProjectileComponent.Team.ENEMY (0=PLAYER, 1=ENEMY)

		# CRITICAL: Manually setup pool manager since weapon is not in ComponentHost
		if weapon.has_method("_setup_pool_manager"):
			weapon._setup_pool_manager()

		# Dependency Injection: Inject projectiles container into weapon
		var projectiles_container = get_tree().get_first_node_in_group("ProjectilesContainer")
		if projectiles_container and weapon.has_method("setup_weapon"):
			weapon.setup_weapon(projectiles_container)
			print("[Enemy] %s weapon: Injected ProjectilesContainer" % enemy_type)
		else:
			print("[Enemy] %s weapon: ProjectilesContainer not found, using fallback" % enemy_type)

		# Load projectile scene
		var projectile_scene_instance = load("res://examples/space_shooter/scenes/projectile.tscn")
		if projectile_scene_instance:
			weapon.projectile_scene = projectile_scene_instance
			print("[Enemy] %s weapon ready! Projectile scene loaded." % enemy_type)
		else:
			print("[Enemy] %s weapon ERROR: Projectile scene not found!" % enemy_type)

	# Setup Particle Effects
	particles = ParticleEffectComponent.new()
	host.add_component(particles)

	# Add Hitbox (damages player on collision)
	var hitbox = Hitbox.new()
	hitbox.name = "Hitbox"
	hitbox.damage = damage_to_player
	hitbox.hit_once_per_target = true
	var hitbox_collision = CollisionShape2D.new()
	var hitbox_shape = RectangleShape2D.new()
	# Hitbox size depends on enemy type: Tank is double size
	if enemy_type == "Tank":
		hitbox_shape.size = Vector2(56, 56) # Tank hitbox (slightly smaller than visual)
	else:
		hitbox_shape.size = Vector2(28, 28) # Basic, Fast, and others
	hitbox_collision.shape = hitbox_shape
	hitbox.add_child(hitbox_collision)
	physics_body.add_child(hitbox)

func _setup_visuals() -> void:
	# IMPORTANT: Add visual to physics_body so it moves with the entity
	if not physics_body:
		push_error("[Enemy] Cannot setup visuals - physics_body is null!")
		return
	
	# Try to load sprite based on enemy type
	var sprite_path: String
	var fallback_color: Color
	var target_size: Vector2
	
	match enemy_type:
		"Basic":
			sprite_path = "res://examples/space_shooter/assets/sprites/enemies/ships/enemy_basic.png"
			fallback_color = Color(1.0, 0.3, 0.3) # Red
			target_size = Vector2(48, 48)
		"Fast":
			sprite_path = "res://examples/space_shooter/assets/sprites/enemies/ships/enemy_fast.png"
			fallback_color = Color(1.0, 0.8, 0.2) # Yellow
			target_size = Vector2(48, 48)
		"Tank":
			sprite_path = "res://examples/space_shooter/assets/sprites/enemies/ships/enemy_tank.png"
			fallback_color = Color(0.5, 0.2, 0.5) # Purple
			target_size = Vector2(96, 96) # Double size for Tank!
		_:
			sprite_path = ""
			fallback_color = Color(0.8, 0.8, 0.8) # Gray
			target_size = Vector2(48, 48)
	
	# Try to load sprite
	var sprite_texture = load(sprite_path) if sprite_path != "" and ResourceLoader.exists(sprite_path) else null
	
	if sprite_texture:
		# Use sprite
		var sprite = Sprite2D.new()
		sprite.texture = sprite_texture
		sprite.name = "EnemySprite"
		sprite.centered = true # Use Godot's built-in centering
		
		# Calculate scale to match target size
		var texture_size = sprite_texture.get_size()
		var scale_factor = target_size / texture_size
		sprite.scale = scale_factor
		
		physics_body.add_child(sprite)
		print("[Enemy] %s using sprite: %s (scale: %s, size: %s)" % [enemy_type, sprite_path, scale_factor, target_size])
	else:
		# Fallback to ColorRect
		if sprite_path != "":
			print("[Enemy] %s sprite not found (%s), using ColorRect fallback" % [enemy_type, sprite_path])
		
		var visual = ColorRect.new()
		visual.name = "Visual"
		visual.size = target_size
		visual.position = - target_size / 2.0
		visual.color = fallback_color
		
		physics_body.add_child(visual)
		print("[Enemy] %s visual created (color: %v, size: %s)" % [enemy_type, visual.color, target_size])

func _connect_signals() -> void:
	health_component.died.connect(_on_enemy_died)
	health_component.damage_taken.connect(_on_damage_taken)

	# NOTE: destroyed_by_boundary is already connected in _setup_components()
	# Don't connect again here to avoid duplicate signal emissions

func _process(delta: float) -> void:
	movement_time += delta
	_update_movement(delta)
	_update_shooting(delta)

func _update_movement(_delta: float) -> void:
	if not movement_component or not is_instance_valid(movement_component):
		return

	var direction = Vector2.ZERO

	match movement_pattern:
		MovementPattern.STRAIGHT_DOWN:
			direction = Vector2.DOWN

		MovementPattern.ZIGZAG:
			direction = Vector2.DOWN

			# Check if near boundaries and reverse direction
			if physics_body:
				var current_x = physics_body.global_position.x
				var left_bound = SpaceShooterConstants.ENEMY_LEFT_BOUND
				var right_bound = SpaceShooterConstants.ENEMY_RIGHT_BOUND

				# Reverse direction if near boundaries
				if current_x <= left_bound and zigzag_direction < 0:
					zigzag_direction = 1.0 # Change to right
				elif current_x >= right_bound and zigzag_direction > 0:
					zigzag_direction = -1.0 # Change to left

			# Apply zigzag movement with current direction
			direction.x = zigzag_direction

		MovementPattern.CIRCULAR:
			# Circular pattern with more emphasis on downward movement
			direction.x = cos(movement_time * 2.0) * 0.4 # Reduced lateral movement
			direction.y = 0.8 + sin(movement_time * 2.0) * 0.2 # More downward bias

		MovementPattern.SINE_WAVE:
			direction = Vector2.DOWN
			var offset_x = sin(movement_time * 2.0) * 100.0
			global_position.x = initial_x + offset_x

		MovementPattern.TRACKING:
			if player:
				direction = (player.global_position - global_position).normalized()
				direction = direction * 0.3 + Vector2.DOWN * 0.7 # Mix with downward

		MovementPattern.STOP_AND_SHOOT:
			# Descend until reaching stop position
			if not has_stopped:
				if physics_body.global_position.y < stop_position_y:
					direction = Vector2.DOWN
				else:
					has_stopped = true
					direction = Vector2.ZERO
					print("[Enemy] %s stopped at position %v" % [enemy_type, physics_body.global_position])
			else:
				# Stopped - do lateral movement
				lateral_movement_timer += _delta
				var lateral_speed = 0.3
				direction.x = sin(lateral_movement_timer * lateral_speed)
				direction.y = 0

	if movement_pattern != MovementPattern.SINE_WAVE:
		movement_component.set_direction(direction.normalized())

func _update_shooting(delta: float) -> void:
	if not can_shoot or not weapon or not player or not physics_body:
		return

	# Use timer-based shooting for more consistent fire rate
	shoot_timer += delta

	# Fire rate depends on movement pattern
	var current_fire_rate = fire_rate
	if movement_pattern == MovementPattern.STOP_AND_SHOOT and has_stopped:
		current_fire_rate = fire_rate * 0.5 # Shoot faster when stopped

	if shoot_timer >= current_fire_rate:
		shoot_timer = 0.0
		var shoot_position = physics_body.global_position
		var shoot_direction = (player.global_position - shoot_position).normalized()
		# Fire-and-forget pattern: call async method without await
		_fire_weapon_async(shoot_position, shoot_direction)

## Async helper to fire weapon without blocking _process()
func _fire_weapon_async(shoot_position: Vector2, shoot_direction: Vector2) -> void:
	await weapon.fire_at(shoot_position, shoot_direction)

func _on_damage_taken(amount: int, _attacker: Node) -> void:
	print("%s took %d damage! Health: %d/%d" % [_get_log_prefix(), amount, health_component.current_health, health_component.max_health])

	# Spawn damage number
	_spawn_damage_number(amount, false)

	# Visual feedback for taking damage
	# particles.play_effect() - Would trigger particle effect if configured

func _on_enemy_died() -> void:
	# Prevent multiple death notifications
	if _is_dying:
		return
	_is_dying = true

	print("%s DIED! Emitting enemy_died signal and destroying..." % _get_log_prefix())

	# Visual feedback for death - spawn explosion particles
	_spawn_explosion_particles()

	enemy_died.emit(self, score_value)

	# Chance to drop power-up
	if randf() < 0.15: # 15% chance
		_spawn_powerup()

	print("[Enemy] %s calling queue_free()" % enemy_type)
	_destroy_safely()

func _on_boundary_reached(_boundary: String) -> void:
	# Enemy left the screen, remove it
	# Prevent multiple death notifications
	if _is_dying:
		return
	_is_dying = true

	# Emit signal so WaveManager knows to decrement enemy count
	print("[Enemy] %s left screen, emitting enemy_died signal (no score)" % enemy_type)
	enemy_died.emit(self, 0) # 0 score since player didn't destroy it
	_destroy_safely()

func _on_destroyed_by_boundary(_edge) -> void:
	# Called by BoundedMovement when enemy is destroyed by leaving bounds
	# Prevent multiple death notifications
	if _is_dying:
		return
	_is_dying = true

	print("[Enemy] %s destroyed by boundary, emitting enemy_died signal (no score)" % enemy_type)
	enemy_died.emit(self, 0) # 0 score since player didn't destroy it
	_destroy_safely()

func _destroy_safely() -> void:
	# Prevent multiple queue_free calls
	if _is_destroyed:
		return
	_is_destroyed = true

	queue_free()

func _get_log_prefix() -> String:
	return "[Enemy #%d %s]" % [_enemy_id, enemy_type]

func _spawn_powerup() -> void:
	# This will be implemented when we create the powerup system
	print("%s Should spawn powerup at: %v" % [_get_log_prefix(), global_position])

func _spawn_damage_number(damage: int, is_critical: bool = false) -> void:
	# Load damage number script
	var DamageNumber = load("res://examples/space_shooter/effects/damage_number.gd")
	if not DamageNumber:
		return

	# Get position at enemy's physics body
	var spawn_position = physics_body.global_position if physics_body else global_position

	# Get the game world root (usually the main game scene)
	var game_root = get_tree().root

	# Create damage number using static method
	var damage_label = Label.new()
	damage_label.set_script(DamageNumber)
	damage_label.position = spawn_position

	# Add to root so it's not affected by enemy destruction
	game_root.add_child(damage_label)

	# Setup color based on enemy type (for variety)
	var damage_color: Color
	match enemy_type:
		"Tank":
			damage_color = Color(0.58, 0.0, 0.83) # NEON_PURPLE
		"Fast":
			damage_color = Color(1.0, 0.94, 0.0) # NEON_YELLOW
		_:
			damage_color = Color(1.0, 1.0, 1.0) # NEON_WHITE

	damage_label.setup(damage, is_critical, damage_color)

func _spawn_explosion_particles() -> void:
	# Load explosion particles script
	var ExplosionParticles = load("res://examples/space_shooter/effects/explosion_particles.gd")
	if not ExplosionParticles:
		return

	# Create instance
	var explosion = GPUParticles2D.new()
	explosion.set_script(ExplosionParticles)

	# Set color based on enemy type
	var explosion_color: Color
	match enemy_type:
		"Tank":
			explosion_color = Color(0.58, 0.0, 0.83) # NEON_PURPLE for tank
		"Fast":
			explosion_color = Color(1.0, 0.94, 0.0) # NEON_YELLOW for fast
		_:
			explosion_color = Color(1.0, 0.08, 0.58) # NEON_PINK for basic

	# Set size based on enemy type
	var explosion_size: float = 60.0 if enemy_type != "Tank" else 90.0

	# Position at enemy death location
	explosion.global_position = physics_body.global_position if physics_body else global_position

	# Add to game world (not as child of enemy since enemy is being destroyed)
	get_tree().root.add_child(explosion)

	# Configure explosion ANTES de iniciar
	explosion.set("explosion_color", explosion_color)
	explosion.set("explosion_radius", explosion_size)

	# Iniciar a explosão (isso chama _setup_particles com as cores corretas)
	explosion.call("start_explosion")

	# Play audio if AudioManager exists
	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("explosion", 0.6)
