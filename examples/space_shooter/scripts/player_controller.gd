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

## Pilot configuration (loaded from PlayerData)
var pilot_data: PilotData

## Default values (used if ship_config is null)
@export var move_speed: float = 300.0
@export var max_health: int = 100
@export var fire_rate: float = 0.2
@export var projectile_damage: int = 10
@export var projectile_speed: float = 600.0

## Weapon Configuration (uses WeaponDatabase)
@export_group("Weapons")
@export_enum("basic_laser", "spread_shot", "rapid_fire", "twin_laser", "pulse_cannon", "wave_beam") var primary_weapon_name: String = "basic_laser"
@export_enum("homing_missile", "shotgun_blast", "burst_cannon") var secondary_weapon_name: String = ""
@export_enum("plasma_bomb", "railgun", "emp_pulse") var special_weapon_name: String = ""
#endregion

#region Component References
var host: ComponentHost
var movement: BoundedMovement
var health: HealthComponent
var weapon_manager: WeaponSlotManager  # Manages multiple weapon slots (PRIMARY, SECONDARY, SPECIAL)
var input_component: InputComponent
var score: ScoreComponent
var particles: ParticleEffectComponent
var pilot_abilities: PilotAbilitySystem  # Handles pilot special abilities
var physics_body: CharacterBody2D  # Reference to the physics body
#endregion

func _ready() -> void:
	# Load ship config from PlayerData if not set
	if not ship_config and has_node("/root/PlayerData"):
		var player_data = get_node("/root/PlayerData")
		ship_config = player_data.get_selected_ship()

	# Load pilot data from PlayerData
	if has_node("/root/PlayerData"):
		var player_data = get_node("/root/PlayerData")
		pilot_data = player_data.get_selected_pilot()

	_apply_ship_config()
	_apply_pilot_modifiers()
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

## Apply pilot modifiers (if pilot selected)
## Modifies ship stats based on pilot bonuses
func _apply_pilot_modifiers() -> void:
	if not pilot_data:
		return

	# Store original values for comparison
	var original_health = max_health
	var original_speed = move_speed

	# Apply base stat modifiers
	max_health = int(max_health * pilot_data.health_modifier)
	move_speed = move_speed * pilot_data.speed_modifier

	# Global damage and fire rate modifiers (applied to weapons later)
	# These are stored and applied in _load_weapons_from_database()

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

	# Base invincibility duration (modified by pilot)
	var base_invincibility = 0.5  # Base: 0.5 seconds
	if pilot_data:
		health.invincibility_duration = base_invincibility * pilot_data.invincibility_duration_modifier
		print("[Player] Invincibility: %.2fs (%.0f%% modifier)" % [
			health.invincibility_duration,
			pilot_data.invincibility_duration_modifier * 100
		])
	else:
		health.invincibility_duration = base_invincibility

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

	# Setup Weapon Slot Manager (manages PRIMARY, SECONDARY, SPECIAL weapons)
	print("[Player] Creating WeaponSlotManager...")
	weapon_manager = WeaponSlotManager.new()
	weapon_manager.debug_slots = true
	weapon_manager.auto_handle_input = false  # We handle input manually via InputComponent

	# Configure input actions for weapon manager
	weapon_manager.primary_secondary_action = "fire"
	weapon_manager.special_action = "fire_special"

	# Load weapons from WeaponDatabase (Factory Pattern)
	# This follows Open/Closed Principle - add new weapons without modifying this code
	_load_weapons_from_database()

	# Add weapon manager component to host
	host.add_component(weapon_manager)
	print("[Player] WeaponSlotManager created and added to host")

	# Wait for weapon manager to initialize
	await get_tree().process_frame

	# Dependency Injection: Set projectiles container for all weapons
	var projectiles_container = get_tree().get_first_node_in_group("ProjectilesContainer")
	if projectiles_container:
		print("[Player] ProjectilesContainer found for weapons")
	else:
		print("[Player] ProjectilesContainer not found, weapons will use fallback")

	# Setup Score Component
	score = ScoreComponent.new()
	score.enable_combos = true
	score.combo_decay_time = 2.0
	host.add_component(score)

	# Setup Particle Effects
	particles = ParticleEffectComponent.new()
	host.add_component(particles)

	# Setup Pilot Ability System (if pilot selected)
	if pilot_data:
		print("[Player] Creating PilotAbilitySystem...")
		pilot_abilities = PilotAbilitySystem.new()
		pilot_abilities.pilot_data = pilot_data
		pilot_abilities.debug_abilities = true
		host.add_component(pilot_abilities)
		print("[Player] PilotAbilitySystem created with pilot: %s" % pilot_data.pilot_name)
	else:
		print("[Player] No pilot selected, PilotAbilitySystem not created")

	print("╔═══════════════════════════════════════════════════════╗")
	print("║        ✅ PLAYER SETUP COMPLETED ✅                   ║")
	print("╚═══════════════════════════════════════════════════════╝")

func _setup_input_actions() -> void:
	# Movement actions
	input_component.add_action("move_up", [KEY_W, KEY_UP])
	input_component.add_action("move_down", [KEY_S, KEY_DOWN])
	input_component.add_action("move_left", [KEY_A, KEY_LEFT])
	input_component.add_action("move_right", [KEY_D, KEY_RIGHT])

	# Weapon actions
	input_component.add_action("fire", [KEY_SPACE])  # PRIMARY + SECONDARY weapons
	input_component.add_action("fire_special", [KEY_ALT])  # SPECIAL weapon
	input_component.add_action("toggle_secondary", [KEY_Z])  # Toggle SECONDARY on/off

func _setup_visuals() -> void:
	# Determine sprite to use (from config or default)
	var sprite_texture: Texture2D = null
	var ship_scale_mult: float = 1.0
	var ship_color: Color = Color.WHITE

	# Try to load from ship config first
	if ship_config and ship_config.ship_sprite:
		sprite_texture = ship_config.ship_sprite
		ship_scale_mult = ship_config.ship_scale

		# Load custom color from PlayerData
		if has_node("/root/PlayerData"):
			var player_data = get_node("/root/PlayerData")
			if player_data.selected_ship_color:
				ship_color = player_data.selected_ship_color * player_data.selected_color_intensity
				print("[Player] Applied custom color - RGB: (%.2f, %.2f, %.2f), Intensity: %.2f" %
					[player_data.selected_ship_color.r, player_data.selected_ship_color.g,
					 player_data.selected_ship_color.b, player_data.selected_color_intensity])
			else:
				ship_color = ship_config.ship_tint  # Fallback to default ship tint
		else:
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

		# Add engine trail effect
		_add_engine_trail()
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

	# Connect to weapon manager signals (Observer Pattern)
	if weapon_manager:
		print("[Player] Connecting weapon_manager.secondary_toggled...")
		weapon_manager.secondary_toggled.connect(_on_secondary_toggled)
		print("[Player] Connecting weapon_manager.weapon_empty...")
		weapon_manager.weapon_empty.connect(_on_weapon_empty)

	print("[Player] ✅ All signals connected!")

	# Notify that player is fully ready
	print("[Player] 📡 Emitting player_ready signal...")
	player_ready.emit(self)

func _process(_delta: float) -> void:
	_handle_movement()
	_handle_shooting()
	_handle_weapon_toggle()

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
	if not input_component or not weapon_manager:
		return

	# PRIMARY + SECONDARY weapons (fire together with SPACE)
	if input_component.is_action_pressed("fire"):
		weapon_manager.fire_primary_and_secondary()

	# SPECIAL weapon (independent with ALT)
	if input_component.is_action_just_pressed("fire_special"):
		weapon_manager.fire_special()

func _handle_weapon_toggle() -> void:
	if not input_component or not weapon_manager:
		return

	# Toggle SECONDARY weapon on/off with Z
	# This follows Command Pattern - user action triggers state change
	if input_component.is_action_just_pressed("toggle_secondary"):
		var enabled = weapon_manager.toggle_secondary_weapon()

		# Visual/Audio feedback (Observer Pattern)
		print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		if enabled:
			print("[Player] 🟢 SECONDARY WEAPON ENABLED")
		else:
			print("[Player] 🔴 SECONDARY WEAPON DISABLED")
		print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

		# TODO: Play toggle sound effect
		# TODO: Show UI notification

func _on_damage_taken(amount: int, _attacker: Node) -> void:
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("[Player] 💥 TOOK %d DAMAGE!" % amount)
	print("[Player] 💚 Health: %d/%d" % [health.current_health, health.max_health])
	print("[Player] 🛡️ Invincible: %s" % health.is_invincible())
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	# Spawn damage number
	_spawn_damage_number(amount, false)

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

func _spawn_damage_number(damage: int, is_critical: bool = false) -> void:
	# Load damage number script
	var DamageNumber = load("res://examples/space_shooter/effects/damage_number.gd")
	if not DamageNumber:
		return

	# Get position at player's physics body
	var spawn_position = physics_body.global_position if physics_body else global_position

	# Get the game world root
	var game_root = get_tree().root

	# Create damage number
	var damage_label = Label.new()
	damage_label.set_script(DamageNumber)
	damage_label.position = spawn_position

	# Add to root so it's not affected by player movement
	game_root.add_child(damage_label)

	# Player damage numbers are always red
	var damage_color = Color(1.0, 0.08, 0.08) # NEON_RED

	damage_label.setup(damage, is_critical, damage_color)

func _on_health_changed(new_health: int, old_health: int) -> void:
	print("[Player] Health changed: %d -> %d" % [old_health, new_health])

func _on_secondary_toggled(enabled: bool) -> void:
	# Observer Pattern: React to SECONDARY weapon toggle
	# This is where you'd play sounds, show UI notifications, etc.
	if enabled:
		print("[Player] 🎯 SECONDARY weapon is now ACTIVE")
		# TODO: Play "weapon activated" sound
		# TODO: Show green indicator on HUD
	else:
		print("[Player] 💤 SECONDARY weapon is now INACTIVE")
		# TODO: Play "weapon deactivated" sound
		# TODO: Show red/gray indicator on HUD

func _on_weapon_empty(slot: int) -> void:
	# Observer Pattern: React to weapon running out of ammo
	var category_name = WeaponData.Category.keys()[slot]
	print("[Player] ⚠️ %s weapon is EMPTY!" % category_name)
	# TODO: Play "empty click" sound
	# TODO: Show low ammo warning on HUD

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
	if weapon_manager:
		# Upgrade PRIMARY weapon (slot 0)
		var primary_weapon_comp = weapon_manager.get_weapon_component(WeaponData.Category.PRIMARY)
		if primary_weapon_comp:
			# WeaponComponent has built-in upgrade system
			primary_weapon_comp.upgrade()
			print("[Player] PRIMARY weapon upgraded! Damage: %d, Fire rate: %.2f" % [
				primary_weapon_comp.damage,
				primary_weapon_comp.fire_rate
			])

			# Observer Pattern: Emit signal for UI/audio/VFX systems to react
			weapon_upgraded.emit(primary_weapon_comp.damage, primary_weapon_comp.fire_rate)
			powerup_collected.emit("weapon", {
				"damage": primary_weapon_comp.damage,
				"fire_rate": primary_weapon_comp.fire_rate
			})

func power_up_shield() -> void:
	if health:
		var health_restored = 30
		health.heal(health_restored)
		print("[Player] Health restored!")

		# Observer Pattern: Emit signal for UI/audio/VFX systems to react
		shield_upgraded.emit(health_restored)
		powerup_collected.emit("shield", health_restored)

#region Private Helper Methods
## Load weapons from WeaponDatabase based on configuration
## Follows Factory Pattern - delegates weapon creation to WeaponDatabase
## Follows Dependency Inversion - depends on WeaponDatabase abstraction
func _load_weapons_from_database() -> void:
	print("╔════════════════════════════════════════════════════╗")
	print("║          🔫 LOADING WEAPONS 🔫                    ║")
	print("╚════════════════════════════════════════════════════╝")

	# TEMPORARY: Override from PlayerData if available (for testing)
	if has_node("/root/PlayerData"):
		var player_data = get_node("/root/PlayerData")
		if "selected_primary_weapon" in player_data and not player_data.selected_primary_weapon.is_empty():
			primary_weapon_name = player_data.selected_primary_weapon
			print("[Player] Using primary weapon from PlayerData: %s" % primary_weapon_name)
		if "selected_secondary_weapon" in player_data and not player_data.selected_secondary_weapon.is_empty():
			secondary_weapon_name = player_data.selected_secondary_weapon
			print("[Player] Using secondary weapon from PlayerData: %s" % secondary_weapon_name)

	# Load PRIMARY weapon (always required)
	if not primary_weapon_name.is_empty():
		var primary = WeaponDatabase.get_primary_weapon(primary_weapon_name)
		if primary:
			# Override damage/stats with ship config if available
			if ship_config:
				primary.damage = projectile_damage
				primary.fire_rate = fire_rate
				primary.projectile_speed = projectile_speed

			# Apply pilot modifiers to PRIMARY weapon
			_apply_pilot_weapon_modifiers(primary, WeaponData.Category.PRIMARY)

			weapon_manager.primary_weapon = primary
			print("[Player] ✅ PRIMARY: %s (Damage: %d, FireRate: %.2f)" % [
				primary.weapon_name,
				primary.damage,
				primary.fire_rate
			])
		else:
			push_error("[Player] Failed to load PRIMARY weapon: %s" % primary_weapon_name)

	# Load SECONDARY weapon (optional)
	if not secondary_weapon_name.is_empty():
		var secondary = WeaponDatabase.get_secondary_weapon(secondary_weapon_name)
		if secondary:
			# Apply pilot modifiers to SECONDARY weapon
			_apply_pilot_weapon_modifiers(secondary, WeaponData.Category.SECONDARY)

			weapon_manager.secondary_weapon = secondary
			print("[Player] ✅ SECONDARY: %s (Damage: %d, Ammo: %d)" % [
				secondary.weapon_name,
				secondary.damage,
				secondary.max_ammo
			])
		else:
			push_warning("[Player] Failed to load SECONDARY weapon: %s" % secondary_weapon_name)

	# Load SPECIAL weapon (optional)
	if not special_weapon_name.is_empty():
		var special = WeaponDatabase.get_special_weapon(special_weapon_name)
		if special:
			# Apply pilot modifiers to SPECIAL weapon
			_apply_pilot_weapon_modifiers(special, WeaponData.Category.SPECIAL)

			weapon_manager.special_weapon = special
			print("[Player] ✅ SPECIAL: %s (Damage: %d, Ammo: %d)" % [
				special.weapon_name,
				special.damage,
				special.max_ammo
			])
		else:
			push_warning("[Player] Failed to load SPECIAL weapon: %s" % special_weapon_name)

	print("╚════════════════════════════════════════════════════╝")

## Apply pilot modifiers to weapon based on category
## Multiplies damage, fire rate, and ammo by pilot bonuses
func _apply_pilot_weapon_modifiers(weapon: WeaponData, category: int) -> void:
	if not pilot_data:
		return

	# Get total damage modifier for this category (global * category-specific)
	var damage_mod = pilot_data.get_damage_modifier_for_category(category)
	var fire_rate_mod = pilot_data.get_fire_rate_modifier_for_category(category)

	# Apply damage modifier
	var original_damage = weapon.damage
	weapon.damage = int(weapon.damage * damage_mod)

	# Apply fire rate modifier
	var original_fire_rate = weapon.fire_rate
	weapon.fire_rate = weapon.fire_rate / fire_rate_mod  # Lower cooldown = faster fire rate

	# Apply ammo modifiers (category-specific)
	match category:
		WeaponData.Category.SECONDARY:
			var original_ammo = weapon.max_ammo
			weapon.max_ammo = int(weapon.max_ammo * pilot_data.secondary_ammo_modifier)
			if weapon.max_ammo != original_ammo:
				print("[Player]   Ammo: %d -> %d" % [original_ammo, weapon.max_ammo])

		WeaponData.Category.SPECIAL:
			# SPECIAL ammo uses additive bonus
			if pilot_data.special_ammo_bonus != 0:
				var original_ammo = weapon.max_ammo
				weapon.max_ammo += pilot_data.special_ammo_bonus
				print("[Player]   Ammo: %d -> %d (%+d)" % [original_ammo, weapon.max_ammo, pilot_data.special_ammo_bonus])

	# Log modifications if changed
	if damage_mod != 1.0:
		print("[Player]   Damage: %d -> %d (%.0f%%)" % [original_damage, weapon.damage, damage_mod * 100])

	if fire_rate_mod != 1.0:
		print("[Player]   Fire Rate: %.2f -> %.2f (%.0f%%)" % [original_fire_rate, weapon.fire_rate, fire_rate_mod * 100])

func _add_engine_trail() -> void:
	if not physics_body:
		return

	# Load engine trail script
	var EngineTrail = load("res://examples/space_shooter/effects/engine_trail.gd")
	if not EngineTrail:
		return

	# Create trail instance
	var trail = GPUParticles2D.new()
	trail.set_script(EngineTrail)
	trail.name = "EngineTrail"

	# Position at back of ship (offset down)
	trail.position = Vector2(0, 36) # Offset below center

	# Add to physics body so it moves with ship
	physics_body.add_child(trail)

	# Configure trail colors based on ship config or pilot
	var trail_color_start = Color(0.0, 0.94, 0.94) # NEON_CYAN
	var trail_color_end = Color(0.2, 0.6, 1.0) # NEON_BLUE

	# Customize based on pilot if available
	if pilot_data:
		match pilot_data.pilot_name:
			"Ace":
				trail_color_start = Color(1.0, 0.94, 0.0) # Yellow for speed
				trail_color_end = Color(1.0, 0.5, 0.0) # Orange
			"Tank":
				trail_color_start = Color(1.0, 0.08, 0.58) # Pink
				trail_color_end = Color(0.58, 0.0, 0.83) # Purple
			"Gunner":
				trail_color_start = Color(1.0, 0.3, 0.0) # Red-orange
				trail_color_end = Color(1.0, 0.0, 0.0) # Red

	trail.set("trail_color_start", trail_color_start)
	trail.set("trail_color_end", trail_color_end)

	# Inicializar o trail com as cores configuradas
	trail.call("initialize")

	print("[Player] Engine trail added with colors: %v -> %v" % [trail_color_start, trail_color_end])
#endregion

#region Upgrade Methods (FASE 3: Shop System)
## Called by UpgradeManager to apply purchased upgrades

func modify_max_health(bonus: int) -> void:
	"""Increase max health and heal player by bonus amount"""
	if health:
		health.max_health += bonus
		health.current_health += bonus  # Also heal
		print("[Player] Max health increased by %d (now %d/%d)" % [bonus, health.current_health, health.max_health])
	else:
		push_warning("[Player] Health component not found")

func modify_damage_multiplier(multiplier: float) -> void:
	"""Apply damage multiplier to all weapons"""
	# TODO: Implement weapon damage modification
	# WeaponSlotManager doesn't have global multipliers - need to modify individual weapon data
	print("[Player] Damage multiplier: ×%.2f (TODO: not yet implemented)" % multiplier)

func modify_fire_rate_multiplier(multiplier: float) -> void:
	"""Apply fire rate multiplier to all weapons"""
	# TODO: Implement weapon fire rate modification
	# WeaponSlotManager doesn't have global multipliers - need to modify individual weapon data
	print("[Player] Fire rate multiplier: ×%.2f (TODO: not yet implemented)" % multiplier)

func modify_speed_multiplier(multiplier: float) -> void:
	"""Apply speed multiplier to movement"""
	if movement:
		movement.max_speed *= multiplier
		print("[Player] Speed multiplier: ×%.2f (speed: %.1f)" % [multiplier, movement.max_speed])
	else:
		push_warning("[Player] BoundedMovement not found")

func modify_pickup_range(multiplier: float) -> void:
	"""Increase pickup range (magnet effect)"""
	# TODO: Implement pickup range component
	print("[Player] Pickup range multiplier: ×%.2f (not yet implemented)" % multiplier)

func modify_piercing(pierce_count: int) -> void:
	"""Add piercing to projectiles"""
	# TODO: Implement piercing modification
	print("[Player] Piercing: +%d (TODO: not yet implemented)" % pierce_count)

func enable_homing(enabled: bool) -> void:
	"""Enable homing projectiles"""
	# TODO: Implement homing modification
	print("[Player] Homing enabled: %s (TODO: not yet implemented)" % enabled)

func modify_regeneration(regen_per_second: float) -> void:
	"""Add health regeneration"""
	if health:
		health.regeneration_rate += regen_per_second
		print("[Player] Regeneration: +%.1f HP/s (total: %.1f HP/s)" % [regen_per_second, health.regeneration_rate])
	else:
		push_warning("[Player] Health component not found")

func modify_drop_rate(multiplier: float) -> void:
	"""Increase drop rate (lucky charm)"""
	# TODO: Implement drop rate modifier (needs integration with PowerUpFactory)
	print("[Player] Drop rate multiplier: ×%.2f (not yet implemented)" % multiplier)

func modify_projectile_size(multiplier: float) -> void:
	"""Increase projectile size"""
	# TODO: Implement projectile size modification
	print("[Player] Projectile size: ×%.2f (TODO: not yet implemented)" % multiplier)

func modify_iframe_duration(bonus: float) -> void:
	"""Increase invincibility frame duration"""
	if health:
		health.invincibility_duration += bonus
		print("[Player] I-Frame duration: +%.1fs (total: %.1fs)" % [bonus, health.invincibility_duration])
	else:
		push_warning("[Player] Health component not found")

func add_temporary_shield(shield_amount: int) -> void:
	"""Add temporary shield (consumable buff)"""
	# TODO: Implement shield system (HealthComponent doesn't have add_shield method)
	print("[Player] Temporary shield: %d HP (TODO: not yet implemented)" % shield_amount)
#endregion
