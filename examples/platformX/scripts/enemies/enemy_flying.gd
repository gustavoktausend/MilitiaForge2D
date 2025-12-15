## Enemy Flying
##
## Flying enemy that chases player with sine wave movement.
## Hovers and approaches when player is detected.

class_name EnemyFlying extends CharacterBody2D

#region Configuration
## Enemy type for factory
const enemy_type: int = 1 # EnemyFactory.EnemyType.FLYING

## Base movement speed
@export var move_speed: float = 80.0

## Chase speed when pursuing player
@export var chase_speed: float = 120.0

## Detection range
@export var detection_range: float = 200.0

## Sine wave amplitude (vertical movement)
@export var sine_amplitude: float = 30.0

## Sine wave frequency
@export var sine_frequency: float = 2.0

## How close to get to player before backing off
@export var min_distance_to_player: float = 80.0
#endregion

#region Components
var host: ComponentHost
var health: HealthComponent
#endregion

#region State
enum State {PATROL, CHASE, RETREAT}
var current_state: State = State.PATROL
var player_ref: Node2D = null
var movement_time: float = 0.0
var patrol_direction: Vector2 = Vector2.RIGHT
var home_position: Vector2
#endregion

#region Lifecycle
func _ready() -> void:
	_setup_components()
	_find_player()
	home_position = global_position

func _physics_process(delta: float) -> void:
	movement_time += delta
	_update_state(delta)
	_apply_movement(delta)
	move_and_slide()

func configure(config: Dictionary) -> void:
	"""Called by EnemyFactory"""
	if config.has("health"):
		if health:
			health.max_health = config.health
			health.current_health = config.health
	
	if config.has("speed"):
		move_speed = config.speed
		chase_speed = config.speed * 1.5
#endregion

#region Setup
func _setup_components() -> void:
	# Create ComponentHost
	host = ComponentHost.new()
	host.name = "ComponentHost"
	add_child(host)
	
	# Health
	health = HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 20
	health.invincibility_enabled = false
	host.add_component(health)
	
	# Connect death
	health.died.connect(_on_died)

func _find_player() -> void:
	player_ref = get_tree().get_first_node_in_group("player")
#endregion

#region State Machine
func _update_state(delta: float) -> void:
	if not player_ref:
		current_state = State.PATROL
		return
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	# State transitions
	if distance_to_player < min_distance_to_player:
		current_state = State.RETREAT
	elif distance_to_player < detection_range:
		current_state = State.CHASE
	else:
		current_state = State.PATROL
	
	# Execute state
	match current_state:
		State.PATROL:
			_state_patrol(delta)
		State.CHASE:
			_state_chase(delta)
		State.RETREAT:
			_state_retreat(delta)

func _state_patrol(delta: float) -> void:
	# Patrol in sine wave pattern
	var base_velocity = patrol_direction * move_speed
	var sine_offset = Vector2(0, sin(movement_time * sine_frequency) * sine_amplitude)
	
	velocity = base_velocity
	velocity.y = sine_offset.y * 2 # Vertical sine wave
	
	# Return toward home if too far
	var distance_from_home = global_position.distance_to(home_position)
	if distance_from_home > 300:
		var direction_home = (home_position - global_position).normalized()
		velocity = direction_home * move_speed

func _state_chase(delta: float) -> void:
	# Move toward player with sine wave
	var direction_to_player = (player_ref.global_position - global_position).normalized()
	
	# Add sine wave to movement
	var perpendicular = Vector2(-direction_to_player.y, direction_to_player.x)
	var sine_offset = perpendicular * sin(movement_time * sine_frequency * 2) * sine_amplitude * 0.5
	
	velocity = direction_to_player * chase_speed + sine_offset * 2

func _state_retreat(delta: float) -> void:
	# Back away from player
	var direction_from_player = (global_position - player_ref.global_position).normalized()
	velocity = direction_from_player * chase_speed
#endregion

#region Movement
func _apply_movement(delta: float) -> void:
	# Flying enemies ignore gravity
	pass
#endregion

#region Signals
func _on_died() -> void:
	# Death effect
	if randf() < 0.15: # 15% chance
		_spawn_pickup()

func _spawn_pickup() -> void:
	# TODO: Spawn pickup
	pass
#endregion
