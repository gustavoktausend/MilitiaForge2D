## Player Controller for Space Shooter
##
## Controls the player's spaceship using MilitiaForge2D components.
## Demonstrates integration of multiple components working together.

extends Node2D

#region Signals
## Emitted when player is fully initialized and ready to use
signal player_ready(player_node: Node2D)

## Observer Pattern: Emitted when player picks up a powerup
signal powerup_collected(powerup_type: String, value)

## Observer Pattern: Emitted when weapon is upgraded
signal weapon_upgraded(new_damage: int, new_fire_rate: float)

## Observer Pattern: Emitted when shield/health is upgraded
signal shield_upgraded(health_restored: int)
#endregion

#region Configuration
## Ship configuration (optional - if null, uses default values)
@export var ship_config: ShipConfig

## Default values (used if ship_config is null)
@export var move_speed: float = 300.0
@export var max_health: int = 100
@export var fire_rate: float = 0.2
@export var projectile_damage: int = 10
@export var projectile_speed: float = 600.0
#endregion

#region Component References
var host: ComponentHost
var movement: BoundedMovement
var health: HealthComponent
var weapon: SimpleWeapon  # Changed from simple_weapon: Node to weapon: SimpleWeapon (now a Component!)
var input_component: InputComponent
var score: ScoreComponent
var particles: ParticleEffectComponent
var physics_body: CharacterBody2D  # Reference to the physics body
#endregion

func _ready() -> void:
	# Load ship config from PlayerData if not set
	if not ship_config and has_node("/root/PlayerData"):
		var player_data = get_node("/root/PlayerData")
		ship_config = player_data.get_selected_ship()
		if ship_config:
			print("[Player] Loaded ship config from PlayerData: %s" % ship_config.ship_name)
		else:
			print("[Player] No ship config found in PlayerData, using defaults")
	elif ship_config:
		print("[Player] Using pre-assigned ship config: %s" % ship_config.ship_name)
	else:
		print("[Player] No ship config available, using default values")

	_apply_ship_config()
	await _setup_components()
	_setup_visuals()
	_connect_signals()

## Apply ship configuration (if set)
func _apply_ship_config() -> void:
	if ship_config:
		move_speed = ship_config.speed
		max_health = ship_config.max_health
		fire_rate = ship_config.get_fire_cooldown()
		projectile_damage = ship_config.weapon_damage
		projectile_speed = ship_config.projectile_speed
		print("[Player] Applied ship config - Speed: %.0f, Health: %d, FireRate: %.2f, Damage: %d" %
			[move_speed, max_health, fire_rate, projectile_damage])
	else:
		print("[Player] Using default stats - Speed: %.0f, Health: %d, FireRate: %.2f, Damage: %d" %
			[move_speed, max_health, fire_rate, projectile_damage])

func _setup_components() -> void:
	print("╔═══════════════════════════════════════════════════════╗")
	print("║          🚀 PLAYER SETUP STARTING 🚀                  ║")
	print("╚═══════════════════════════════════════════════════════╝")

	# Create ComponentHost
	print("[Player] Creating ComponentHost...")
	host = ComponentHost.new()
	host.name = "PlayerHost"
	add_child(host)
	print("[Player] ComponentHost created and added to tree")

	# Add Physics Body FIRST (before movement component needs it)
	print("[Player] Creating CharacterBody2D...")
	physics_body = CharacterBody2D.new()
	physics_body.name = "Body"

	# Configure collision layers for physical collisions
	physics_body.collision_layer = 1  # Player layer
	physics_body.collision_mask = 2   # Collide with enemies

	host.add_child(physics_body)
	print("[Player] CharacterBody2D created with layer=%d, mask=%d" % [
		physics_body.collision_layer,
		physics_body.collision_mask
	])

	# Add collision shape to physics body for physical collisions
	var body_collision = CollisionShape2D.new()
	var body_shape = RectangleShape2D.new()
	body_shape.size = Vector2(48, 72)  # Match sprite size
	body_collision.shape = body_shape
	body_collision.name = "BodyCollisionShape"
	physics_body.add_child(body_collision)
	print("[Player] CharacterBody2D collision shape added")

	# Add Sprite placeholder
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	physics_body.add_child(sprite)

	# Add Hurtbox for taking damage (disabled during setup)
	print("[Player] Creating Hurtbox...")
	var hurtbox = Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.active = false  # Disable during setup
	hurtbox.monitoring = false
	hurtbox.monitorable = false
	hurtbox.debug_hurtbox = true  # Enable debug
	print("[Player] Hurtbox created (disabled)")

	# Create collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	# Updated for 1920x1080: increased 50% (32x48 -> 48x72)
	shape.size = Vector2(48, 72)
	collision.shape = shape
	hurtbox.add_child(collision)
	physics_body.add_child(hurtbox)

	# Setup Movement Component (now physics body exists)
	movement = BoundedMovement.new()
	movement.max_speed = move_speed
	movement.acceleration = 1500.0
	movement.friction = 1200.0
	movement.boundary_mode = BoundedMovement.BoundaryMode.CLAMP
	movement.use_viewport_bounds = false  # Use custom bounds for play area
	movement.debug_movement = true  # Enable debug for troubleshooting

	# Set custom bounds to match the play area (between HUD panels)
	# Wait for viewport to be ready, then set bounds
	await get_tree().process_frame
	var viewport_size = get_viewport().get_visible_rect().size
	# Use GameConstants for play area boundaries
	var play_area_bounds = Rect2(
		Vector2(SpaceShooterConstants.PLAY_AREA_LEFT, 0),
		Vector2(SpaceShooterConstants.PLAY_AREA_WIDTH, viewport_size.y)
	)
	movement.set_custom_bounds(play_area_bounds)
	movement.boundary_margin = Vector2(16, 16)  # Smaller margin since play area is narrow
	host.add_component(movement)

	# Setup Health Component
	print("[Player] Creating HealthComponent...")
	health = HealthComponent.new()
	health.max_health = max_health
	health.invincibility_enabled = true
	health.invincibility_duration = 0.5  # Reduced from 2.0 to 0.5 seconds
	health.debug_health = true
	host.add_component(health)
	print("[Player] HealthComponent created: %d/%d HP" % [health.current_health, health.max_health])

	# Wait for HealthComponent to be ready
	print("[Player] Waiting for HealthComponent to be ready...")
	await get_tree().process_frame
	print("[Player] HealthComponent ready! Current health: %d/%d" % [health.current_health, health.max_health])

	# NOW activate and configure Hurtbox (after HealthComponent is ready)
	# Similar to enemy setup, manually set health component reference
	print("[Player] Configuring Hurtbox with HealthComponent...")
	hurtbox.set("_health_component", health)
	hurtbox.set("_component_host", host)
	print("[Player] Hurtbox references set")
	hurtbox.collision_layer = 1  # Player layer
	hurtbox.collision_mask = 10  # Binary 1010 = Layer 2 (enemies) + Layer 8 (enemy projectiles)
	hurtbox.active = true
	hurtbox.monitoring = true
	hurtbox.monitorable = true
	hurtbox.hit_flash_enabled = true  # Enable visual feedback
	hurtbox.hit_flash_duration = 0.2

	print("╔════════════════════════════════════════════════════╗")
	print("║          🛡️  PLAYER HURTBOX ACTIVATED 🛡️          ║")
	print("╠════════════════════════════════════════════════════╣")
	print("║ Collision Layer: %d (Player)                      ║" % hurtbox.collision_layer)
	print("║ Collision Mask:  %d (Binary: %s)       ║" % [hurtbox.collision_mask, String.num_int64(hurtbox.collision_mask, 2).pad_zeros(4)])
	print("║   - Layer 2 (Enemies): %s                          ║" % ("YES" if hurtbox.collision_mask & 2 else "NO"))
	print("║   - Layer 8 (Enemy Projectiles): %s                ║" % ("YES" if hurtbox.collision_mask & 256 else "NO"))
	print("║ Active: %s                                         ║" % hurtbox.active)
	print("║ Monitoring: %s                                     ║" % hurtbox.monitoring)
	print("║ Monitorable: %s                                    ║" % hurtbox.monitorable)
	print("║ Debug: %s                                          ║" % hurtbox.debug_hurtbox)
	print("╚════════════════════════════════════════════════════╝")

	# Setup Collision Damage Component
	print("[Player] Creating CollisionDamageComponent...")
	var collision_damage = CollisionDamageComponent.new()
	collision_damage.damage_on_collision = 30  # Player deals 30 damage to enemies on collision
	collision_damage.can_take_collision_damage = true  # Player takes damage from collisions
	collision_damage.incoming_damage_multiplier = 1.0  # Take full damage
	collision_damage.apply_knockback = true
	collision_damage.knockback_force = 300.0  # Strong knockback to separate
	collision_damage.collision_cooldown = 0.5  # Match invincibility duration
	host.add_component(collision_damage)
	print("[Player] CollisionDamageComponent ready! Collision damage: 30")

	# Setup Input Component
	input_component = InputComponent.new()
	input_component.debug_input = true  # Enable debug for troubleshooting
	_setup_input_actions()
	host.add_component(input_component)

	# Setup Simple Weapon (now a Component!)
	weapon = SimpleWeapon.new()

	# Configure weapon BEFORE adding to host
	weapon.is_player_weapon = true
	weapon.use_object_pooling = true
	weapon.pooled_projectile_type = "player_laser"
	weapon.fire_rate = fire_rate
	weapon.damage = projectile_damage
	weapon.projectile_speed = projectile_speed
	weapon.auto_fire = false  # Disable auto_fire, we control firing manually
	weapon.firing_offset = Vector2(0, -30)  # Fire from nose of ship
	weapon.debug_weapon = true

	# Load projectile scene (fallback for when pooling is disabled)
	var player_projectile_scene = load("res://examples/space_shooter/scenes/projectile.tscn")
	if player_projectile_scene:
		weapon.projectile_scene = player_projectile_scene

	# Add weapon component to host (this calls initialize() and component_ready())
	host.add_component(weapon)

	# Dependency Injection: Inject projectiles container into weapon (AFTER adding to host)
	await get_tree().process_frame  # Wait for component_ready to complete
	var projectiles_container = get_tree().get_first_node_in_group("ProjectilesContainer")
	if projectiles_container:
		weapon.set_projectiles_container(projectiles_container)
		print("[Player] Injected ProjectilesContainer into weapon")
	else:
		print("[Player] ProjectilesContainer not found, weapon will use fallback")

	# Setup Score Component
	score = ScoreComponent.new()
	score.enable_combos = true
	score.combo_decay_time = 2.0
	host.add_component(score)

	# Setup Particle Effects
	particles = ParticleEffectComponent.new()
	host.add_component(particles)

	print("╔═══════════════════════════════════════════════════════╗")
	print("║        ✅ PLAYER SETUP COMPLETED ✅                   ║")
	print("╚═══════════════════════════════════════════════════════╝")

func _setup_input_actions() -> void:
	# Movement actions
	input_component.add_action("move_up", [KEY_W, KEY_UP])
	input_component.add_action("move_down", [KEY_S, KEY_DOWN])
	input_component.add_action("move_left", [KEY_A, KEY_LEFT])
	input_component.add_action("move_right", [KEY_D, KEY_RIGHT])
	input_component.add_action("fire", [KEY_SPACE])

func _setup_visuals() -> void:
	# Determine sprite to use (from config or default)
	var sprite_texture: Texture2D = null
	var ship_scale_mult: float = 1.0
	var ship_color: Color = Color.WHITE

	# Try to load from ship config first
	if ship_config and ship_config.ship_sprite:
		sprite_texture = ship_config.ship_sprite
		ship_scale_mult = ship_config.ship_scale
		ship_color = ship_config.ship_tint
	else:
		# Fallback to default sprite
		var sprite_path = "res://examples/space_shooter/assets/sprites/player/ship.png"
		if ResourceLoader.exists(sprite_path):
			sprite_texture = load(sprite_path)

	if sprite_texture:
		# Create sprite
		var sprite = Sprite2D.new()
		sprite.texture = sprite_texture
		sprite.centered = true
		sprite.modulate = ship_color

		# Scale to desired size
		var desired_height = 72.0 * ship_scale_mult
		var texture_height = sprite.texture.get_height()
		var scale_factor = desired_height / texture_height
		sprite.scale = Vector2(scale_factor, scale_factor)

		sprite.z_index = 1
		physics_body.add_child(sprite)
		var sprite_source = "ShipConfig" if ship_config else "default"
		print("[Player] Loaded sprite from %s (scale: %.2f)" % [sprite_source, scale_factor])
	else:
		# Fallback to ColorRect if sprite not found
		print("[Player] Sprite not available, using placeholder")
		var visual = ColorRect.new()
		# Updated for 1920x1080: increased 50% (32x48 -> 48x72)
		visual.size = Vector2(48, 72)
		visual.position = Vector2(-24, -36)
		visual.color = Color(0.2, 0.6, 1.0)  # Blue ship
		visual.z_index = 1
		physics_body.add_child(visual)

		# Add engine glow
		var glow = ColorRect.new()
		glow.size = Vector2(24, 12)  # 50% larger
		glow.position = Vector2(-12, 30)
		glow.color = Color(1.0, 0.5, 0.2, 0.7)  # Orange glow
		visual.add_child(glow)

func _connect_signals() -> void:
	print("╔═══════════════════════════════════════════════════════╗")
	print("║        🔌 CONNECTING PLAYER SIGNALS 🔌               ║")
	print("╚═══════════════════════════════════════════════════════╝")

	# Connect to important signals
	print("[Player] Connecting health.damage_taken...")
	health.damage_taken.connect(_on_damage_taken)
	print("[Player] Connecting health.died...")
	health.died.connect(_on_player_died)
	print("[Player] Connecting health.health_changed...")
	health.health_changed.connect(_on_health_changed)

	print("[Player] ✅ All signals connected!")

	# Notify that player is fully ready
	print("[Player] 📡 Emitting player_ready signal...")
	player_ready.emit(self)

func _process(_delta: float) -> void:
	_handle_movement()
	_handle_shooting()

func _handle_movement() -> void:
	if not input_component or not movement:
		return

	var direction = Vector2.ZERO

	if input_component.is_action_pressed("move_up"):
		direction.y -= 1
	if input_component.is_action_pressed("move_down"):
		direction.y += 1
	if input_component.is_action_pressed("move_left"):
		direction.x -= 1
	if input_component.is_action_pressed("move_right"):
		direction.x += 1

	movement.set_direction(direction)

func _handle_shooting() -> void:
	if not input_component or not weapon:
		return

	if input_component.is_action_pressed("fire"):
		# WeaponComponent handles position automatically (uses host + firing_offset)
		weapon.fire()
	else:
		weapon.stop_fire()

func _on_damage_taken(amount: int, _attacker: Node) -> void:
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("[Player] 💥 TOOK %d DAMAGE!" % amount)
	print("[Player] 💚 Health: %d/%d" % [health.current_health, health.max_health])
	print("[Player] 🛡️ Invincible: %s" % health.is_invincible())
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	# Visual feedback
	_flash_damage()

	# Lose combo on hit
	if score:
		score.reset_combo()

func _flash_damage() -> void:
	# Flash red when taking damage
	var visuals = get_children().filter(func(child): return child is ColorRect)
	if visuals.size() > 0:
		var visual = visuals[0]
		var original_color = visual.color
		visual.color = Color(1.0, 0.2, 0.2)
		await get_tree().create_timer(0.1).timeout
		visual.color = original_color

func _on_health_changed(new_health: int, old_health: int) -> void:
	print("[Player] Health changed: %d -> %d" % [old_health, new_health])

func _on_player_died() -> void:
	print("╔═══════════════════════════════════════╗")
	print("║   💀 PLAYER DIED! GAME OVER 💀        ║")
	print("╚═══════════════════════════════════════╝")

	# Hide player
	visible = false

	# Notify game controller
	var controllers = get_tree().get_nodes_in_group("game_controller")
	print("[Player] Found %d game controllers" % controllers.size())
	if controllers.size() > 0:
		print("[Player] Calling end_game() on controller...")
		controllers[0].end_game()
	else:
		push_error("[Player] NO GAME CONTROLLER FOUND! Cannot trigger Game Over!")

func add_score(points: int) -> void:
	if score:
		score.add_score(points)

func power_up_weapon() -> void:
	if weapon:
		# WeaponComponent has built-in upgrade system
		weapon.upgrade()
		print("[Player] Weapon upgraded! Damage: %d, Fire rate: %.2f" % [weapon.damage, weapon.fire_rate])

		# Observer Pattern: Emit signal for UI/audio/VFX systems to react
		weapon_upgraded.emit(weapon.damage, weapon.fire_rate)
		powerup_collected.emit("weapon", {"damage": weapon.damage, "fire_rate": weapon.fire_rate})

func power_up_shield() -> void:
	if health:
		var health_restored = 30
		health.heal(health_restored)
		print("[Player] Health restored!")

		# Observer Pattern: Emit signal for UI/audio/VFX systems to react
		shield_upgraded.emit(health_restored)
		powerup_collected.emit("shield", health_restored)
