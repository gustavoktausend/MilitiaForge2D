## Player Controller for Space Shooter
##
## Controls the player's spaceship using MilitiaForge2D components.
## Demonstrates integration of multiple components working together.

extends Node2D

#region Signals
## Emitted when player is fully initialized and ready to use
signal player_ready(player_node: Node2D)
#endregion

#region Configuration
@export var move_speed: float = 300.0
@export var max_health: int = 100
@export var fire_rate: float = 0.2
@export var projectile_damage: int = 10
#endregion

#region Component References
var host: ComponentHost
var movement: BoundedMovement
var health: HealthComponent
var simple_weapon: Node
var input_component: InputComponent
var score: ScoreComponent
var particles: ParticleEffectComponent
var physics_body: CharacterBody2D  # Reference to the physics body
#endregion

func _ready() -> void:
	await _setup_components()
	_setup_visuals()
	_connect_signals()

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
	host.add_child(physics_body)
	print("[Player] CharacterBody2D created")

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
	# Updated for 1920x1080: side panels = 480px, play area = 960px
	var play_area_bounds = Rect2(
		Vector2(480, 0),  # Start after left panel (480px)
		Vector2(960, viewport_size.y)  # Play area width (960px) x full height
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

	# Setup Input Component
	input_component = InputComponent.new()
	input_component.debug_input = true  # Enable debug for troubleshooting
	_setup_input_actions()
	host.add_component(input_component)

	# Setup Simple Weapon
	simple_weapon = Node.new()
	simple_weapon.set_script(preload("res://examples/space_shooter/scripts/simple_weapon.gd"))
	simple_weapon.name = "SimpleWeapon"
	add_child(simple_weapon)
	# Configure weapon after adding to tree
	await get_tree().process_frame
	simple_weapon.fire_rate = fire_rate
	simple_weapon.projectile_damage = projectile_damage
	simple_weapon.projectile_speed = 600.0
	simple_weapon.auto_fire = false  # Disable auto_fire, we control firing manually

	# Dependency Injection: Inject projectiles container into weapon
	var projectiles_container = get_tree().get_first_node_in_group("ProjectilesContainer")
	if projectiles_container and simple_weapon.has_method("setup_weapon"):
		simple_weapon.setup_weapon(projectiles_container)
		print("[Player] Injected ProjectilesContainer into weapon")
	else:
		print("[Player] ProjectilesContainer not found, weapon will use fallback")

	# Load projectile scene
	var projectile_scene_instance = load("res://examples/space_shooter/scenes/projectile.tscn")
	if projectile_scene_instance:
		simple_weapon.projectile_scene = projectile_scene_instance

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
	# Try to load player sprite
	var sprite_path = "res://examples/space_shooter/assets/sprites/player/ship.png"

	if ResourceLoader.exists(sprite_path):
		# Use sprite if available
		var sprite = Sprite2D.new()
		sprite.texture = load(sprite_path)
		sprite.centered = true  # Center the sprite on the pivot

		# Scale down to reasonable size (adjust as needed)
		# Updated for 1920x1080: increased 50% for better visibility
		# Original: 48px, New: 72px (48 * 1.5)
		var desired_height = 72.0
		var texture_height = sprite.texture.get_height()
		var scale_factor = desired_height / texture_height
		sprite.scale = Vector2(scale_factor, scale_factor)

		sprite.z_index = 1
		physics_body.add_child(sprite)
		print("[Player] Loaded sprite from: %s (scale: %.2f)" % [sprite_path, scale_factor])
	else:
		# Fallback to ColorRect if sprite not found
		print("[Player] Sprite not found at %s, using placeholder" % sprite_path)
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
	if not input_component or not simple_weapon:
		return

	if input_component.is_action_pressed("fire"):
		var projectile_position = physics_body.global_position + Vector2(0, -30)
		simple_weapon.fire(projectile_position, Vector2.UP)
	else:
		simple_weapon.stop_fire()

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
	if simple_weapon:
		simple_weapon.projectile_damage += 5
		simple_weapon.fire_rate = max(simple_weapon.fire_rate - 0.05, 0.1)
		print("[Player] Weapon upgraded! Damage: %d, Fire rate: %.2f" % [simple_weapon.projectile_damage, simple_weapon.fire_rate])

func power_up_shield() -> void:
	if health:
		health.heal(30)
		print("[Player] Health restored!")
