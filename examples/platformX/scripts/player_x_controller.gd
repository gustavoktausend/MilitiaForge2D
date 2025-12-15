## Player X Controller
##
## Main player controller for PlatformX example.
## Integrates multiple components for complete platformer character.
##
## Components Used:
## - PlatformerMovement - Jump, gravity, ground detection
## - WallSlideComponent - Wall slide and wall jump
## - DashComponent - Quick dash ability
## - HealthComponent - Player health system
## - Input Component - Centralized input handling
## - ChargeShotComponent - Charge shot weapon
## - StateMachine - Player state management

class_name PlayerXController extends ComponentHost

#region Signals
signal player_died()
signal player_respawned()
#endregion

#region Exports
@export_group("Player Stats")
## Player max health
@export var max_health: int = 100

## Default move speed
@export var move_speed: float = 200.0

## Jump strength
@export var jump_power: float = -400.0

@export_group("References")
## Sprite node (optional)
@export var sprite_node_path: NodePath = NodePath("Sprite2D")

## Animation player (optional)
@export var animation_player_path: NodePath = NodePath("AnimationPlayer")

@export_group("Debug")
## Show debug info
@export var show_debug: bool = false
#endregion

#region Components
var platformer_movement: PlatformerMovement
var wall_slide: WallSlideComponent
var dash: DashComponent
var health: HealthComponent
var input_comp: InputComponent
var charge_shot: ChargeShotComponent
var state_machine: StateMachine
#endregion

#region Private Variables
var _sprite: Node2D = null
var _animation_player: AnimationPlayer = null
var _facing_right: bool = true
#endregion

#region Lifecycle
func _ready() -> void:
	_setup_components()
	_setup_input()
	_setup_visuals()
	_connect_signals()
	
	super._ready()
	
	if show_debug:
		print("[PlayerXController] Player ready")

func _physics_process(delta: float) -> void:
	_handle_input(delta)
	_update_facing_direction()
	_update_animation()
	
	if show_debug and Input.is_action_just_pressed("ui_select"):
		_print_debug_info()
#endregion

#region Setup
func _setup_components() -> void:
	# Create PlatformerMovement
	platformer_movement = PlatformerMovement.new()
	platformer_movement.name = "PlatformerMovement"
	platformer_movement.max_speed = move_speed
	platformer_movement.jump_velocity = jump_power
	platformer_movement.allow_double_jump = false
	add_component(platformer_movement)
	
	# Create WallSlide
	wall_slide = WallSlideComponent.new()
	wall_slide.name = "WallSlideComponent"
	add_component(wall_slide)
	
	# Create Dash
	dash = DashComponent.new()
	dash.name = "DashComponent"
	dash.can_dash_in_air = true
	dash.max_air_dashes = 1
	add_component(dash)
	
	# Create Health
	health = HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = max_health
	health.invincibility_enabled = true
	health.invincibility_duration = 2.0
	add_component(health)
	
	# Create Input
	input_comp = InputComponent.new()
	input_comp.name = "InputComponent"
	add_component(input_comp)
	
	# Create ChargeShot
	charge_shot = ChargeShotComponent.new()
	charge_shot.name = "ChargeShotComponent"
	charge_shot.firing_offset = Vector2(20, 0)
	add_component(charge_shot)
	
	# NOTE: State machine would be added here in full implementation
	# For now, we're doing stateless control

func _setup_input() -> void:
	# Setup input actions
	input_comp.add_action("move_left", [KEY_A, KEY_LEFT])
	input_comp.add_action("move_right", [KEY_D, KEY_RIGHT])
	input_comp.add_action("jump", [KEY_SPACE, KEY_W, KEY_UP])
	input_comp.add_action("dash", [KEY_SHIFT])
	input_comp.add_action("shoot", [KEY_X, MOUSE_BUTTON_LEFT])

func _setup_visuals() -> void:
	# Get sprite if specified
	if sprite_node_path and not sprite_node_path.is_empty():
		_sprite = get_node_or_null(sprite_node_path)
	
	# Get animation player if specified
	if animation_player_path and not animation_player_path.is_empty():
		_animation_player = get_node_or_null(animation_player_path)
	
	# If no sprite exists, create basic placeholder
	if not _sprite:
		_create_placeholder_sprite()

func _create_placeholder_sprite() -> void:
	# Create simple colored rectangle as player
	var color_rect = ColorRect.new()
	color_rect.name = "Sprite2D"
	color_rect.size = Vector2(32, 48)
	color_rect.position = Vector2(-16, -48) # Center at feet
	color_rect.color = Color(0.2, 0.5, 1.0) # Blue
	add_child(color_rect)
	_sprite = color_rect

func _connect_signals() -> void:
	# Health signals
	health.died.connect(_on_player_died)
	health.health_changed.connect(_on_health_changed)
	
	# Movement signals
	platformer_movement.jumped.connect(_on_jumped)
	platformer_movement.landed.connect(_on_landed)
	
	# Wall slide signals
	wall_slide.wall_jumped.connect(_on_wall_jumped)
	
	# Dash signals
	dash.dash_started.connect(_on_dash_started)
	dash.dash_ended.connect(_on_dash_ended)
#endregion

#region Input Handling
func _handle_input(delta: float) -> void:
	if not input_comp.input_enabled:
		return
	
	# Horizontal movement
	var move_direction = Vector2.ZERO
	if input_comp.is_action_pressed("move_left"):
		move_direction.x -= 1
	if input_comp.is_action_pressed("move_right"):
		move_direction.x += 1
	
	# Set movement direction
	platformer_movement.set_direction(move_direction)
	
	# Jump
	if input_comp.is_action_just_pressed("jump"):
		_handle_jump()
	
	# Track jump hold for variable jump height
	platformer_movement.set_jump_held(input_comp.is_action_pressed("jump"))
	
	# Dash
	if input_comp.is_action_just_pressed("dash"):
		_handle_dash(move_direction)
	
	# Shooting
	if input_comp.is_action_pressed("shoot"):
		if not charge_shot.is_charging():
			charge_shot.start_charge()
	else:
		if charge_shot.is_charging():
			charge_shot.release_charge()

func _handle_jump() -> void:
	# Try wall jump first
	if wall_slide.can_wall_jump_now():
		wall_slide.wall_jump()
	# Normal jump
	elif platformer_movement.can_jump():
		platformer_movement.jump()

func _handle_dash(direction: Vector2) -> void:
	if not dash.can_dash():
		return
	
	var dash_dir = direction
	
	# If no input, dash in facing direction
	if dash_dir.length() == 0:
		dash_dir = Vector2.RIGHT if _facing_right else Vector2.LEFT
	
	dash.dash(dash_dir)
#endregion

#region Visual Updates
func _update_facing_direction() -> void:
	# Update facing based on movement direction
	if platformer_movement.direction.x > 0:
		_facing_right = true
	elif platformer_movement.direction.x < 0:
		_facing_right = false
	
	# Flip sprite
	if _sprite:
		_sprite.scale.x = 1 if _facing_right else -1

func _update_animation() -> void:
	if not _animation_player:
		return
	
	# Simple animation logic (would be expanded with state machine)
	if not platformer_movement.is_grounded():
		if platformer_movement.velocity.y < 0:
			_animation_player.play("jump")
		else:
			_animation_player.play("fall")
	elif platformer_movement.direction.x != 0:
		_animation_player.play("run")
	else:
		_animation_player.play("idle")
#endregion

#region Signal Handlers
func _on_player_died() -> void:
	print("[PlayerXController] Player died!")
	player_died.emit()
	
	# Disable input
	input_comp.input_enabled = false
	
	# Play death animation/effect
	# TODO: Death sequence
	
	# Respawn after delay
	await get_tree().create_timer(2.0).timeout
	respawn()

func _on_health_changed(new_health: int, old_health: int) -> void:
	if show_debug:
		print("[PlayerXController] Health: %d -> %d" % [old_health, new_health])

func _on_jumped() -> void:
	if show_debug:
		print("[PlayerXController] Jumped!")

func _on_landed() -> void:
	if show_debug:
		print("[PlayerXController] Landed")

func _on_wall_jumped(direction: Vector2) -> void:
	if show_debug:
		print("[PlayerXController] Wall jumped: %s" % direction)

func _on_dash_started(direction: Vector2) -> void:
	if show_debug:
		print("[PlayerXController] Dashing: %s" % direction)

func _on_dash_ended() -> void:
	if show_debug:
		print("[PlayerXController] Dash ended")
#endregion

#region Public Methods
func respawn() -> void:
	# Reset position (would come from checkpoint system)
	position = Vector2(100, 100)
	
	# Reset health
	health.revive(max_health)
	
	# Reset velocity
	platformer_movement.velocity = Vector2.ZERO
	
	# Re-enable input
	input_comp.input_enabled = true
	
	player_respawned.emit()
	
	if show_debug:
		print("[PlayerXController] Player respawned")

func take_damage(amount: int, attacker: Node = null) -> void:
	health.take_damage(amount, attacker)

func heal(amount: int) -> void:
	health.heal(amount)
#endregion

#region Debug
func _print_debug_info() -> void:
	print("=== Player Debug Info ===")
	print("Position: %s" % position)
	print("Velocity: %s" % platformer_movement.velocity)
	print("Grounded: %s" % platformer_movement.is_grounded())
	print("Wall Sliding: %s" % wall_slide.is_wall_sliding())
	print("Can Dash: %s" % dash.can_dash())
	print("Health: %d/%d" % [health.current_health, health.max_health])
	print("Charging: %s" % charge_shot.is_charging())
	if charge_shot.is_charging():
		print("  Charge Level: %s" % ChargeShotComponent.ChargeLevel.keys()[charge_shot.get_charge_level()])
	print("========================")
#endregion
