## Enemy Spawn Group Configuration
##
## Defines a group of enemies to spawn together in a wave.
## This is a Resource so it can be configured visually in the Godot Inspector.

class_name EnemySpawnGroup extends Resource

#region Enemy Configuration
@export_group("Enemy Type")
## The type of enemy to spawn (Basic, Fast, Tank, etc.)
@export var enemy_type: String = "Basic"

## Number of enemies of this type to spawn
@export_range(1, 50, 1) var count: int = 5

## Health override (0 = use enemy default)
@export_range(0, 500, 10) var health_override: int = 0

## Speed multiplier (1.0 = normal speed)
@export_range(0.1, 3.0, 0.1) var speed_multiplier: float = 1.0
#endregion

#region Spawn Behavior
@export_group("Spawn Pattern")
## How enemies should be spawned
@export_enum("Random", "Line", "Formation", "Wave") var spawn_pattern: String = "Random"

## Movement pattern for spawned enemies
@export_enum("StraightDown:0", "Zigzag:1", "Circular:2", "SineWave:3", "Tracking:4", "StopAndShoot:5")
var movement_pattern: int = 0

## Whether this group can shoot
@export var can_shoot: bool = false

## Fire rate override (0 = use enemy default)
@export_range(0.0, 5.0, 0.1) var fire_rate_override: float = 0.0
#endregion

#region Spawn Timing
@export_group("Timing")
## Delay before spawning this group (in seconds)
@export_range(0.0, 30.0, 0.5) var spawn_delay: float = 0.0

## Interval between spawning each enemy in this group
@export_range(0.1, 5.0, 0.1) var spawn_interval: float = 0.5
#endregion

#region Score Configuration
@export_group("Rewards")
## Score value override (0 = use enemy default)
@export_range(0, 1000, 10) var score_override: int = 0

## Damage to player override (0 = use enemy default)
@export_range(0, 100, 5) var damage_override: int = 0
#endregion

## Returns the effective health value (override or default)
func get_health() -> int:
	if health_override > 0:
		return health_override
	# Default values based on type
	match enemy_type:
		"Basic": return 20
		"Fast": return 10
		"Tank": return 50
		_: return 20

## Returns the effective speed value
func get_speed() -> float:
	var base_speed: float
	match enemy_type:
		"Basic": base_speed = 100.0
		"Fast": base_speed = 200.0
		"Tank": base_speed = 50.0
		_: base_speed = 100.0
	return base_speed * speed_multiplier

## Returns the effective score value
func get_score_value() -> int:
	if score_override > 0:
		return score_override
	match enemy_type:
		"Basic": return 100
		"Fast": return 150
		"Tank": return 300
		_: return 100

## Returns the effective fire rate
func get_fire_rate() -> float:
	if fire_rate_override > 0.0:
		return fire_rate_override
	return 1.5  # Default

## Returns the effective damage to player
func get_damage_to_player() -> int:
	if damage_override > 0:
		return damage_override
	match enemy_type:
		"Basic": return 20
		"Fast": return 15
		"Tank": return 30
		_: return 20

## Creates a configuration dictionary for spawning
func to_spawn_config() -> Dictionary:
	return {
		"enemy_type": enemy_type,
		"count": count,
		"health": get_health(),
		"speed": get_speed(),
		"score_value": get_score_value(),
		"damage_to_player": get_damage_to_player(),
		"movement_pattern": movement_pattern,
		"can_shoot": can_shoot,
		"fire_rate": get_fire_rate(),
		"spawn_pattern": spawn_pattern,
		"spawn_delay": spawn_delay,
		"spawn_interval": spawn_interval
	}
