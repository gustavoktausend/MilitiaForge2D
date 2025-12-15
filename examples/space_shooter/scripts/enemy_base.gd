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
	TRACKING  # Follows player
}
#endregion

#region Component References
var host: ComponentHost
var movement_component: BoundedMovement
var health_component: HealthComponent
var weapon: Node  # SimpleWeapon instance
var particles: ParticleEffectComponent
var physics_body: CharacterBody2D  # Reference to the physics body
#endregion

#region Private Variables
var player: Node2D = null
var movement_time: float = 0.0
var initial_x: float = 0.0
#endregion

func _ready() -> void:
	print("[Enemy] Creating %s enemy at position %v" % [enemy_type, global_position])
	await _setup_components()
	_setup_visuals()
	_connect_signals()
	initial_x = global_position.x
	print("[Enemy] %s enemy ready! Physics body at: %v" % [enemy_type, physics_body.global_position if physics_body else Vector2.ZERO])

	# Find player
	call_deferred("_find_player")

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _setup_components() -> void:
	# Add Physics Body FIRST (at root level)
	physics_body = CharacterBody2D.new()
	physics_body.name = "Body"
	add_child(physics_body)

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
	health_component.debug_health = true  # Enable debug to see health changes

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
	hurtbox.debug_hurtbox = true  # Enable debug to see if it's working

	# IMPORTANT: Disable Hurtbox during setup to prevent projectiles hitting before ready
	hurtbox.active = false
	hurtbox.monitoring = false
	hurtbox.monitorable = false

	# Create and add collision shape FIRST
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 32)
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
	hurtbox.collision_layer = 2  # Enemy layer
	hurtbox.collision_mask = 4   # Player projectile layer
	hurtbox.active = true  # Enable Hurtbox now that setup is complete
	hurtbox.monitoring = true
	hurtbox.monitorable = true

	print("[Enemy] %s Hurtbox ACTIVATED with layer=%d, mask=%d, active=%s, monitoring=%s, monitorable=%s" % [
		enemy_type, hurtbox.collision_layer, hurtbox.collision_mask, hurtbox.active, hurtbox.monitoring, hurtbox.monitorable
	])

	# Connect to area_entered signal directly to debug
	hurtbox.area_entered.connect(func(area):
		print("[Enemy] %s Hurtbox.area_entered SIGNAL called! Area: %s (is Hitbox: %s)" % [
			enemy_type, area.name, area is Hitbox
		])
		print("[Enemy] %s Hurtbox active: %s, _health_component: %s" % [
			enemy_type, hurtbox.active, hurtbox.get("_health_component") != null
		])
		if hurtbox.get("_health_component"):
			var hc = hurtbox.get("_health_component")
			print("[Enemy] %s HealthComponent is_alive: %s, current_health: %d/%d" % [
				enemy_type, hc.is_alive(), hc.current_health, hc.max_health
			])
		if area is Hitbox:
			print("[Enemy] %s Hitbox.active: %s, damage: %d" % [
				enemy_type, area.active, area.damage
			])
	)

	# Connect to hit_received signal to see if damage is processed
	hurtbox.hit_received.connect(func(hitbox, damage):
		print("[Enemy] %s HIT_RECEIVED! Damage: %d from %s" % [
			enemy_type, damage, hitbox.name
		])
	)

	# Verify HealthComponent can be found after Hurtbox is added
	await get_tree().process_frame
	var found_health = host.get_component("HealthComponent")
	print("[Enemy] %s HealthComponent lookup test: %s" % [enemy_type, "Found" if found_health else "NOT FOUND"])

	# Setup Movement Component (now physics body exists)
	movement_component = BoundedMovement.new()
	movement_component.max_speed = speed
	movement_component.acceleration = 500.0
	movement_component.boundary_mode = BoundedMovement.BoundaryMode.DESTROY
	movement_component.use_viewport_bounds = false  # Use custom bounds for play area

	# Set custom bounds to match the play area (between HUD panels)
	await get_tree().process_frame
	var viewport_size = get_viewport().get_visible_rect().size
	var play_area_bounds = Rect2(
		Vector2(320, -100),  # Start after left panel, allow spawning above screen
		Vector2(640, viewport_size.y + 200)  # Play area width x extended height
	)
	movement_component.set_custom_bounds(play_area_bounds)
	movement_component.boundary_margin = Vector2(0, 0)  # No margin, destroy at exact boundaries
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
		weapon.projectile_damage = projectile_damage
		weapon.projectile_speed = 400.0
		weapon.auto_fire = false
		weapon.is_player_weapon = false  # Enemy weapon, projectiles should target player

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
	hitbox_shape.size = Vector2(28, 28)
	hitbox_collision.shape = hitbox_shape
	hitbox.add_child(hitbox_collision)
	physics_body.add_child(hitbox)

func _setup_visuals() -> void:
	# Simple colored rectangle based on enemy type
	# IMPORTANT: Add visual to physics_body so it moves with the entity
	if not physics_body:
		push_error("[Enemy] Cannot setup visuals - physics_body is null!")
		return

	var visual = ColorRect.new()
	visual.name = "Visual"
	visual.size = Vector2(32, 32)
	visual.position = Vector2(-16, -16)

	match enemy_type:
		"Basic":
			visual.color = Color(1.0, 0.3, 0.3)  # Red
		"Fast":
			visual.color = Color(1.0, 0.8, 0.2)  # Yellow
		"Tank":
			visual.color = Color(0.5, 0.2, 0.5)  # Purple
		_:
			visual.color = Color(0.8, 0.8, 0.8)  # Gray

	physics_body.add_child(visual)
	print("[Enemy] %s visual created (color: %v)" % [enemy_type, visual.color])

func _connect_signals() -> void:
	health_component.died.connect(_on_enemy_died)
	health_component.damage_taken.connect(_on_damage_taken)

	if movement_component:
		movement_component.destroyed_by_boundary.connect(_on_boundary_reached)

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
			direction.x = sin(movement_time * 3.0)

		MovementPattern.CIRCULAR:
			direction.x = cos(movement_time * 2.0)
			direction.y = 0.5 + sin(movement_time * 2.0) * 0.5

		MovementPattern.SINE_WAVE:
			direction = Vector2.DOWN
			var offset_x = sin(movement_time * 2.0) * 100.0
			global_position.x = initial_x + offset_x

		MovementPattern.TRACKING:
			if player:
				direction = (player.global_position - global_position).normalized()
				direction = direction * 0.3 + Vector2.DOWN * 0.7  # Mix with downward

	if movement_pattern != MovementPattern.SINE_WAVE:
		movement_component.set_direction(direction.normalized())

func _update_shooting(_delta: float) -> void:
	if can_shoot and weapon and player and physics_body:
		# Shoot towards player occasionally
		if randf() < 0.02:  # 2% chance per frame
			var shoot_position = physics_body.global_position
			var shoot_direction = (player.global_position - shoot_position).normalized()
			var did_fire = weapon.fire(shoot_position, shoot_direction)
			if did_fire:
				print("[Enemy] %s fired! Position: %v, Direction: %v" % [enemy_type, shoot_position, shoot_direction])

func _on_damage_taken(amount: int, _attacker: Node) -> void:
	print("[Enemy] %s took %d damage! Health: %d/%d" % [enemy_type, amount, health_component.current_health, health_component.max_health])
	# Visual feedback for taking damage
	# particles.play_effect() - Would trigger particle effect if configured
	pass

func _on_enemy_died() -> void:
	print("[Enemy] %s DIED! Emitting enemy_died signal and destroying..." % enemy_type)

	# Visual feedback for death
	# particles.play_effect() - Would trigger particle effect if configured
	enemy_died.emit(self, score_value)

	# Chance to drop power-up
	if randf() < 0.15:  # 15% chance
		_spawn_powerup()

	print("[Enemy] %s calling queue_free()" % enemy_type)
	queue_free()

func _on_boundary_reached(_boundary: String) -> void:
	# Enemy left the screen, remove it
	queue_free()

func _spawn_powerup() -> void:
	# This will be implemented when we create the powerup system
	print("[Enemy] Should spawn powerup at: ", global_position)
