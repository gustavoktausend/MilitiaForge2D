## Ship Configuration Resource
##
## Defines the stats and properties for different ship types.
## Used for ship selection and customization.

class_name ShipConfig extends Resource

#region Ship Identity
@export_group("Identity")
## Ship display name
@export var ship_name: String = "Ship"

## Ship description
@export_multiline var description: String = "A space ship"

## Ship sprite
@export var ship_sprite: Texture2D
#endregion

#region Stats
@export_group("Stats")
## Maximum health
@export var max_health: int = 100

## Movement speed (pixels per second)
@export var speed: float = 300.0

## Fire rate (shots per second)
@export var fire_rate: float = 5.0

## Weapon damage per shot
@export var weapon_damage: int = 10

## Projectile speed
@export var projectile_speed: float = 600.0
#endregion

#region Visual
@export_group("Visual")
## Ship color tint (for variety)
@export var ship_tint: Color = Color.WHITE

## Ship scale multiplier
@export var ship_scale: float = 1.0
#endregion

## Get fire rate as cooldown time (for WeaponComponent compatibility)
func get_fire_cooldown() -> float:
	return 1.0 / fire_rate if fire_rate > 0 else 0.2
