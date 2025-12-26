## Enemy Met
##
## Ground enemy that hides in shell and shoots projectiles.
## Classic Mega Man Met-style behavior.
##
## States: Patrol → Hide → Peek → Shoot → Hide (repeat)

class_name EnemyMet extends CharacterBody2D

#region Configuration
## Enemy type for factory
const enemy_type: int = 0 # EnemyFactory.EnemyType.MET

## Movement speed when patrolling
@export var patrol_speed: float = 50.0

## Detection range for player
@export var detection_range: float = 150.0

## Time hidden before peeking
@export var hide_duration: float = 1.0

## Time peeking before shooting
@export var peek_duration: float = 0.5

## Projectile scene to fire
@export var projectile_scene: PackedScene

## Fire rate (shots per second)
@export var fire_rate: float = 1.0
#endregion

#region Components
var host: ComponentHost
var health: HealthComponent
var weapon: WeaponComponent
var state_machine: StateMachine
#endregion

#region State
enum State {PATROL, HIDE, PEEK, SHOOT}
var current_state: State = State.PATROL
var state_timer: float = 0.0
var patrol_direction: int = 1
var player_ref: Node2D = null
var is_hiding: bool = false
#endregion

#region Lifecycle
func _ready() -> void:
	_setup_components()
	_find_player()
	
	# Face initial direction
	scale.x = patrol_direction

func _physics_process(delta: float) -> void:
	_update_state(delta)
	_apply_movement(delta)
	move_and_slide()

func configure(config: Dictionary) -> void:
	"""Called by EnemyFactory to configure enemy"""
	if config.has("health"):
		if health:
			health.max_health = config.health
			health.current_health = config.health
	
	if config.has("speed"):
		patrol_speed = config.speed
	
	if config.has("patrol_direction"):
		patrol_direction = config.patrol_direction
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
	health.max_health = 30
	health.invincibility_enabled = false
	host.add_component(health)
	
	# Connect death
	health.died.connect(_on_died)
	
	# Weapon (simple projectile)
	weapon = WeaponComponent.new()
	weapon.name = "WeaponComponent"
	weapon.projectile_scene = projectile_scene
	weapon.fire_rate = 1.0 / fire_rate
	weapon.projectile_team = ProjectileComponent.Team.ENEMY
	weapon.damage = 10
	weapon.projectile_speed = 200.0
	weapon.firing_offset = Vector2(16, -10)
	host.add_component(weapon)

func _find_player() -> void:
	# Find player in scene
	player_ref = get_tree().get_first_node_in_group("player")
#endregion

#region State Machine
func _update_state(delta: float) -> void:
	state_timer -= delta
	
	match current_state:
		State.PATROL:
			_state_patrol()
		State.HIDE:
			_state_hide()
		State.PEEK:
			_state_peek()
		State.SHOOT:
			_state_shoot()

func _state_patrol() -> void:
	# Check if player is close
	if _is_player_in_range():
		_change_state(State.HIDE)
		return
	
	# Simple patrol
	velocity.x = patrol_direction * patrol_speed
	
	# Turn at edges/walls
	if is_on_wall():
		patrol_direction *= -1
		scale.x = patrol_direction

func _state_hide() -> void:
	velocity.x = 0
	is_hiding = true
	
	if state_timer <= 0:
		_change_state(State.PEEK)

func _state_peek() -> void:
	velocity.x = 0
	is_hiding = false
	
	if state_timer <= 0:
		_change_state(State.SHOOT)

func _state_shoot() -> void:
	velocity.x = 0

	# Fire at player
	if weapon and player_ref:
		# Aim at player
		var direction_to_player = (player_ref.global_position - global_position).normalized()

		# Only shoot if player is roughly horizontal
		if abs(direction_to_player.y) < 0.5:
			weapon.fire()

	# Return to hiding
	_change_state(State.HIDE)

func _change_state(new_state: State) -> void:
	current_state = new_state
	
	match new_state:
		State.HIDE:
			state_timer = hide_duration
		State.PEEK:
			state_timer = peek_duration
		State.SHOOT:
			state_timer = 0.1 # Quick fire
		State.PATROL:
			state_timer = 0

func _is_player_in_range() -> bool:
	if not player_ref:
		return false
	
	var distance = global_position.distance_to(player_ref.global_position)
	return distance < detection_range
#endregion

#region Movement
func _apply_movement(delta: float) -> void:
	# Apply gravity if not on floor
	if not is_on_floor():
		velocity.y += 980.0 * delta
	else:
		velocity.y = 0
#endregion

#region Signals
func _on_died() -> void:
	# Play death effect
	# Drop pickup (random chance)
	if randf() < 0.2: # 20% chance
		_spawn_health_pickup()
	
	# Enemy will be destroyed by factory after delay
#endregion

#region Pickups
func _spawn_health_pickup() -> void:
	# TODO: Spawn health pickup
	# Would use PowerUpComponent here
	pass
#endregion
