## Enemy Turret
##
## Fixed position turret that aims and shoots at player.
## Simple but effective enemy type.

class_name EnemyTurret extends Node2D

#region Configuration
## Enemy type for factory
const enemy_type: int = 2 # EnemyFactory.EnemyType.TURRET

## Detection range for player
@export var detection_range: float = 250.0

## Projectile scene
@export var projectile_scene: PackedScene

## Time between shots
@export var fire_cooldown: float = 2.0

## Rotation speed (degrees per second)
@export var rotation_speed: float = 180.0

## Whether turret can rotate to aim
@export var can_rotate: bool = true
#endregion

#region Components
var host: ComponentHost
var health: HealthComponent
var weapon: WeaponComponent
#endregion

#region State
var player_ref: Node2D = null
var fire_timer: float = 0.0
var target_rotation: float = 0.0
#endregion

#region Lifecycle
func _ready() -> void:
	_setup_components()
	_find_player()

func _process(delta: float) -> void:
	_update_targeting(delta)
	_update_firing(delta)

func configure(config: Dictionary) -> void:
	"""Called by EnemyFactory"""
	if config.has("health"):
		if health:
			health.max_health = config.health
			health.current_health = config.health
	
	if config.has("fire_rate"):
		fire_cooldown = 1.0 / config.fire_rate
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
	health.max_health = 40
	health.invincibility_enabled = false
	host.add_component(health)
	
	# Connect death
	health.died.connect(_on_died)
	
	# Weapon
	weapon = WeaponComponent.new()
	weapon.name = "WeaponComponent"
	weapon.projectile_scene = projectile_scene
	weapon.fire_rate = fire_cooldown
	weapon.projectile_team = ProjectileComponent.Team.ENEMY
	weapon.damage = 15
	weapon.projectile_speed = 300.0
	weapon.firing_offset = Vector2(24, 0)
	host.add_component(weapon)

func _find_player() -> void:
	player_ref = get_tree().get_first_node_in_group("player")
#endregion

#region Targeting
func _update_targeting(delta: float) -> void:
	if not player_ref or not can_rotate:
		return
	
	# Check if player in range
	var distance = global_position.distance_to(player_ref.global_position)
	if distance > detection_range:
		return
	
	# Calculate angle to player
	var direction_to_player = player_ref.global_position - global_position
	target_rotation = direction_to_player.angle()
	
	# Rotate toward target
	var current_angle = rotation
	var angle_diff = wrapf(target_rotation - current_angle, -PI, PI)
	
	var rotation_step = deg_to_rad(rotation_speed) * delta
	if abs(angle_diff) < rotation_step:
		rotation = target_rotation
	else:
		rotation += sign(angle_diff) * rotation_step
#endregion

#region Firing
func _update_firing(delta: float) -> void:
	fire_timer -= delta
	
	if fire_timer > 0:
		return
	
	if not player_ref:
		return
	
	# Check if player in range
	var distance = global_position.distance_to(player_ref.global_position)
	if distance > detection_range:
		return
	
	# Check if aimed at player (within tolerance)
	if can_rotate:
		var angle_to_player = (player_ref.global_position - global_position).angle()
		var angle_diff = abs(wrapf(angle_to_player - rotation, -PI, PI))
		
		if angle_diff > deg_to_rad(10): # 10 degree tolerance
			return
	
	# Fire!
	if weapon:
		weapon.fire()
		fire_timer = fire_cooldown
#endregion

#region Signals
func _on_died() -> void:
	# Turrets don't drop pickups (they're stationary)
	pass
#endregion
