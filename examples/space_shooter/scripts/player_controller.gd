## Player Controller for Space Shooter
##
## Controls the player's spaceship using MilitiaForge2D components.
## Demonstrates integration of multiple components working together.

extends Node2D

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
	# Create ComponentHost
	host = ComponentHost.new()
	host.name = "PlayerHost"
	add_child(host)

	# Add Physics Body FIRST (before movement component needs it)
	physics_body = CharacterBody2D.new()
	physics_body.name = "Body"
	host.add_child(physics_body)

	# Add Sprite placeholder
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	physics_body.add_child(sprite)

	# Add Hurtbox for taking damage
	var hurtbox = Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 1  # Player layer
	hurtbox.collision_mask = 8   # Enemy projectile layer
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 48)
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
	var play_area_bounds = Rect2(
		Vector2(320, 0),  # Start after left panel (320px)
		Vector2(640, viewport_size.y)  # Play area width (640px) x full height
	)
	movement.set_custom_bounds(play_area_bounds)
	movement.boundary_margin = Vector2(16, 16)  # Smaller margin since play area is narrow
	host.add_component(movement)

	# Setup Health Component
	health = HealthComponent.new()
	health.max_health = max_health
	health.invincibility_enabled = true
	health.invincibility_duration = 2.0
	health.debug_health = true
	host.add_component(health)

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

func _setup_input_actions() -> void:
	# Movement actions
	input_component.add_action("move_up", [KEY_W, KEY_UP])
	input_component.add_action("move_down", [KEY_S, KEY_DOWN])
	input_component.add_action("move_left", [KEY_A, KEY_LEFT])
	input_component.add_action("move_right", [KEY_D, KEY_RIGHT])
	input_component.add_action("fire", [KEY_SPACE])

func _setup_visuals() -> void:
	# Add a simple visual representation to the physics body
	var visual = ColorRect.new()
	visual.size = Vector2(32, 48)
	visual.position = Vector2(-16, -24)
	visual.color = Color(0.2, 0.6, 1.0)  # Blue ship
	visual.z_index = 1
	physics_body.add_child(visual)

	# Add engine glow
	var glow = ColorRect.new()
	glow.size = Vector2(16, 8)
	glow.position = Vector2(-8, 20)
	glow.color = Color(1.0, 0.5, 0.2, 0.7)  # Orange glow
	visual.add_child(glow)

func _connect_signals() -> void:
	# Connect to important signals
	health.damage_taken.connect(_on_damage_taken)
	health.died.connect(_on_player_died)
	health.health_changed.connect(_on_health_changed)

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
	print("[Player] Took %d damage! Health: %d/%d" % [amount, health.current_health, health.max_health])

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
	print("[Player] Player died!")

	# Hide player
	visible = false

	# Notify game controller
	var controllers = get_tree().get_nodes_in_group("game_controller")
	if controllers.size() > 0:
		controllers[0].end_game()

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
