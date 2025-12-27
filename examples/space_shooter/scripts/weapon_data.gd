## Weapon Data Resource
##
## Defines the stats and properties for different weapon types.
## Used by WeaponSlotManager to configure weapons in different slots.

class_name WeaponData extends Resource

#region Enums
## Weapon categories (determines which slot can equip this weapon)
enum Category {
	PRIMARY,      ## Tiro padrão - munição infinita, sempre ativo
	SECONDARY,    ## Tiro auxiliar - cooldown moderado ou munição renovável
	SPECIAL       ## Granada/Heavy - munição finita, reseta entre fases
}
#endregion

#region Weapon Identity
@export_group("Identity")
## Weapon display name
@export var weapon_name: String = "Weapon"

## Weapon description
@export_multiline var description: String = "A weapon"

## Weapon category (which slot it belongs to)
@export var category: Category = Category.PRIMARY

## Weapon icon/sprite for UI
@export var icon: Texture2D
#endregion

#region Weapon Stats
@export_group("Combat Stats")
## Weapon firing type (from WeaponComponent)
@export var weapon_type: WeaponComponent.WeaponType = WeaponComponent.WeaponType.SINGLE

## Damage per projectile
@export var damage: int = 10

## Fire rate (time between shots in seconds)
@export var fire_rate: float = 0.2

## Projectile speed (pixels per second)
@export var projectile_speed: float = 600.0

## Whether weapon fires automatically when held
@export var auto_fire: bool = true
#endregion

#region Spread Settings
@export_group("Spread Settings")
## Number of projectiles for SPREAD type
@export var spread_count: int = 3

## Angle between spread projectiles (degrees)
@export var spread_angle: float = 15.0
#endregion

#region Burst Settings
@export_group("Burst Settings")
## Number of projectiles for BURST type
@export var burst_count: int = 3

## Delay between burst shots (seconds)
@export var burst_delay: float = 0.05
#endregion

#region Ammo System
@export_group("Ammo")
## Maximum ammo capacity (-1 = infinite)
@export var max_ammo: int = -1

## Starting ammo (for new phase or pickup)
@export var starting_ammo: int = -1

## Whether ammo refills between phases (only for SECONDARY)
@export var refill_on_phase: bool = false

## Whether this weapon has infinite ammo
@export var infinite_ammo: bool = true
#endregion

#region Projectile Configuration
@export_group("Projectile")
## Projectile scene to spawn
@export var projectile_scene: PackedScene

## Pooled projectile type identifier (e.g., "player_laser")
@export var pooled_projectile_type: String = "player_laser"

## Whether to use object pooling for projectiles
@export var use_pooling: bool = true
#endregion

#region Special Properties
@export_group("Special Properties")
## Homing projectiles (track nearest enemy)
@export var is_homing: bool = false

## Piercing projectiles (go through enemies)
@export var is_piercing: bool = false

## Piercing count (how many enemies to pierce, -1 = infinite)
@export var pierce_count: int = 1

## Explosive projectiles (deal AoE damage on impact)
@export var is_explosive: bool = false

## Explosion radius (if explosive)
@export var explosion_radius: float = 50.0

## Explosion damage (if explosive, 0 = use weapon damage)
@export var explosion_damage: int = 0
#endregion

#region Visual/Audio
@export_group("Visual & Audio")
## Firing offset from weapon mount point
@export var firing_offset: Vector2 = Vector2(0, -20)

## Muzzle flash effect (optional)
@export var muzzle_flash: PackedScene

## Fire sound effect
@export var fire_sound: AudioStream

## Empty/click sound when out of ammo
@export var empty_sound: AudioStream
#endregion

#region Helper Methods
## Check if this weapon uses ammo
func uses_ammo() -> bool:
	return max_ammo > 0 and not infinite_ammo

## Get effective starting ammo
func get_starting_ammo() -> int:
	if infinite_ammo or max_ammo < 0:
		return -1
	return starting_ammo if starting_ammo >= 0 else max_ammo

## Check if weapon should refill on phase change
func should_refill_on_phase() -> bool:
	# SPECIAL weapons always refill, SECONDARY only if configured
	return category == Category.SPECIAL or (category == Category.SECONDARY and refill_on_phase)

## Get category name as string
func get_category_name() -> String:
	return Category.keys()[category]
#endregion
