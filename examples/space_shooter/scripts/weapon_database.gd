## Weapon Database
##
## Central database for all weapon configurations in the game.
## Implements Factory Pattern to create WeaponData resources programmatically.
##
## This follows SOLID principles:
## - Single Responsibility: Only creates and manages weapon data
## - Open/Closed: Add new weapons without modifying existing code
## - Dependency Inversion: Returns abstract WeaponData, not specific implementations
##
## Usage:
##   var primary = WeaponDatabase.get_primary_weapon("spread_shot")
##   var secondary = WeaponDatabase.get_secondary_weapon("homing_missile")
##   var special = WeaponDatabase.get_special_weapon("plasma_bomb")

class_name WeaponDatabase extends Object

#region PRIMARY Weapons (Infinite Ammo)

## Create Basic Laser weapon (SINGLE shot, balanced)
static func create_basic_laser() -> WeaponData:
	var weapon = WeaponData.new()

	# Identity
	weapon.weapon_name = "Basic Laser"
	weapon.description = "Standard issue energy weapon. Reliable and efficient."
	weapon.category = WeaponData.Category.PRIMARY

	# Combat Stats
	weapon.weapon_type = WeaponComponent.WeaponType.SINGLE
	weapon.damage = 10
	weapon.fire_rate = 0.2  # 5 shots per second
	weapon.projectile_speed = 600.0
	weapon.auto_fire = false

	# Ammo (infinite for PRIMARY)
	weapon.infinite_ammo = true
	weapon.max_ammo = -1

	# Projectile
	weapon.pooled_projectile_type = "player_laser"
	weapon.use_pooling = true
	weapon.firing_offset = Vector2(0, -30)

	return weapon

## Create Spread Shot weapon (SPREAD, 3 projectiles)
static func create_spread_shot() -> WeaponData:
	var weapon = WeaponData.new()

	# Identity
	weapon.weapon_name = "Spread Shot"
	weapon.description = "Fires 3 projectiles in a spread pattern. Great for covering area."
	weapon.category = WeaponData.Category.PRIMARY

	# Combat Stats
	weapon.weapon_type = WeaponComponent.WeaponType.SPREAD
	weapon.damage = 8  # Lower damage per projectile, but 3 projectiles
	weapon.fire_rate = 0.25  # 4 shots per second
	weapon.projectile_speed = 550.0
	weapon.auto_fire = false

	# Spread settings
	weapon.spread_count = 3
	weapon.spread_angle = 20.0  # 20 degrees between shots

	# Ammo (infinite for PRIMARY)
	weapon.infinite_ammo = true
	weapon.max_ammo = -1

	# Projectile
	weapon.pooled_projectile_type = "player_laser"
	weapon.use_pooling = true
	weapon.firing_offset = Vector2(0, -30)

	return weapon

## Create Rapid Fire weapon (SINGLE, very fast)
static func create_rapid_fire() -> WeaponData:
	var weapon = WeaponData.new()

	# Identity
	weapon.weapon_name = "Rapid Fire"
	weapon.description = "High rate of fire with lower damage. Spray and pray!"
	weapon.category = WeaponData.Category.PRIMARY

	# Combat Stats
	weapon.weapon_type = WeaponComponent.WeaponType.SINGLE
	weapon.damage = 6  # Lower damage
	weapon.fire_rate = 0.1  # 10 shots per second - very fast!
	weapon.projectile_speed = 700.0
	weapon.auto_fire = false

	# Ammo (infinite for PRIMARY)
	weapon.infinite_ammo = true
	weapon.max_ammo = -1

	# Projectile
	weapon.pooled_projectile_type = "player_laser"
	weapon.use_pooling = true
	weapon.firing_offset = Vector2(0, -30)

	return weapon

#endregion

#region SECONDARY Weapons (Moderate Cooldown/Renewable Ammo)

## Create Homing Missile weapon (SINGLE, seeks enemies)
static func create_homing_missile() -> WeaponData:
	var weapon = WeaponData.new()

	# Identity
	weapon.weapon_name = "Homing Missile"
	weapon.description = "Smart missiles that track the nearest enemy. High damage."
	weapon.category = WeaponData.Category.SECONDARY

	# Combat Stats
	weapon.weapon_type = WeaponComponent.WeaponType.SINGLE
	weapon.damage = 25  # High damage
	weapon.fire_rate = 0.8  # Slower fire rate
	weapon.projectile_speed = 400.0  # Slower, but tracks
	weapon.auto_fire = false

	# Special Properties
	weapon.is_homing = true

	# Ammo (renewable - refills on phase)
	weapon.infinite_ammo = false
	weapon.max_ammo = 20
	weapon.starting_ammo = 20
	weapon.refill_on_phase = true  # Refills between phases

	# Projectile
	weapon.pooled_projectile_type = "player_laser"  # TODO: create missile projectile
	weapon.use_pooling = true
	weapon.firing_offset = Vector2(0, -30)

	return weapon

## Create Shotgun Blast weapon (SPREAD, 5 projectiles, wide angle)
static func create_shotgun_blast() -> WeaponData:
	var weapon = WeaponData.new()

	# Identity
	weapon.weapon_name = "Shotgun Blast"
	weapon.description = "Devastating close-range spread. 5 projectiles in wide cone."
	weapon.category = WeaponData.Category.SECONDARY

	# Combat Stats
	weapon.weapon_type = WeaponComponent.WeaponType.SPREAD
	weapon.damage = 12  # High damage per pellet
	weapon.fire_rate = 0.6  # Slower fire rate
	weapon.projectile_speed = 500.0
	weapon.auto_fire = false

	# Spread settings
	weapon.spread_count = 5
	weapon.spread_angle = 30.0  # Wide spread

	# Ammo (renewable)
	weapon.infinite_ammo = false
	weapon.max_ammo = 15
	weapon.starting_ammo = 15
	weapon.refill_on_phase = true

	# Projectile
	weapon.pooled_projectile_type = "player_laser"
	weapon.use_pooling = true
	weapon.firing_offset = Vector2(0, -30)

	return weapon

## Create Burst Cannon weapon (BURST, 3 quick shots)
static func create_burst_cannon() -> WeaponData:
	var weapon = WeaponData.new()

	# Identity
	weapon.weapon_name = "Burst Cannon"
	weapon.description = "Fires 3 quick shots in succession. Controlled burst damage."
	weapon.category = WeaponData.Category.SECONDARY

	# Combat Stats
	weapon.weapon_type = WeaponComponent.WeaponType.BURST
	weapon.damage = 15
	weapon.fire_rate = 0.5  # Time between bursts
	weapon.projectile_speed = 650.0
	weapon.auto_fire = false

	# Burst settings
	weapon.burst_count = 3
	weapon.burst_delay = 0.08  # Fast burst

	# Ammo (renewable)
	weapon.infinite_ammo = false
	weapon.max_ammo = 30  # 10 bursts
	weapon.starting_ammo = 30
	weapon.refill_on_phase = true

	# Projectile
	weapon.pooled_projectile_type = "player_laser"
	weapon.use_pooling = true
	weapon.firing_offset = Vector2(0, -30)

	return weapon

#endregion

#region SPECIAL Weapons (Limited Ammo, Refills on Phase)

## Create Plasma Bomb weapon (SINGLE, explosive AoE)
static func create_plasma_bomb() -> WeaponData:
	var weapon = WeaponData.new()

	# Identity
	weapon.weapon_name = "Plasma Bomb"
	weapon.description = "Explosive projectile that deals massive AoE damage. Limited ammo!"
	weapon.category = WeaponData.Category.SPECIAL

	# Combat Stats
	weapon.weapon_type = WeaponComponent.WeaponType.SINGLE
	weapon.damage = 50  # Direct hit damage
	weapon.fire_rate = 1.0  # 1 second cooldown
	weapon.projectile_speed = 400.0  # Slower projectile
	weapon.auto_fire = false

	# Special Properties - Explosive
	weapon.is_explosive = true
	weapon.explosion_radius = 100.0  # Large explosion
	weapon.explosion_damage = 40  # AoE damage

	# Ammo (limited, refills on phase)
	weapon.infinite_ammo = false
	weapon.max_ammo = 3
	weapon.starting_ammo = 3
	weapon.refill_on_phase = true  # Always refills for SPECIAL

	# Projectile
	weapon.pooled_projectile_type = "player_laser"  # TODO: create bomb projectile
	weapon.use_pooling = true
	weapon.firing_offset = Vector2(0, -30)

	return weapon

## Create Railgun weapon (SINGLE, piercing)
static func create_railgun() -> WeaponData:
	var weapon = WeaponData.new()

	# Identity
	weapon.weapon_name = "Railgun"
	weapon.description = "High-powered beam that pierces through all enemies. Devastating!"
	weapon.category = WeaponData.Category.SPECIAL

	# Combat Stats
	weapon.weapon_type = WeaponComponent.WeaponType.SINGLE
	weapon.damage = 80  # Very high damage
	weapon.fire_rate = 1.2  # Slow cooldown
	weapon.projectile_speed = 1200.0  # Very fast
	weapon.auto_fire = false

	# Special Properties - Piercing
	weapon.is_piercing = true
	weapon.pierce_count = -1  # Infinite piercing

	# Ammo (limited)
	weapon.infinite_ammo = false
	weapon.max_ammo = 5
	weapon.starting_ammo = 5
	weapon.refill_on_phase = true

	# Projectile
	weapon.pooled_projectile_type = "player_laser"  # TODO: create railgun projectile
	weapon.use_pooling = true
	weapon.firing_offset = Vector2(0, -30)

	return weapon

## Create EMP Pulse weapon (SINGLE, slows/freezes enemies)
static func create_emp_pulse() -> WeaponData:
	var weapon = WeaponData.new()

	# Identity
	weapon.weapon_name = "EMP Pulse"
	weapon.description = "Electromagnetic pulse that disables enemies in a large area."
	weapon.category = WeaponData.Category.SPECIAL

	# Combat Stats
	weapon.weapon_type = WeaponComponent.WeaponType.SINGLE
	weapon.damage = 30
	weapon.fire_rate = 2.0  # Long cooldown
	weapon.projectile_speed = 500.0
	weapon.auto_fire = false

	# Special Properties - Explosive (repurposed as AoE slow/freeze)
	weapon.is_explosive = true
	weapon.explosion_radius = 150.0  # Very large area
	weapon.explosion_damage = 20  # Lower damage, but disables

	# Ammo (very limited)
	weapon.infinite_ammo = false
	weapon.max_ammo = 2
	weapon.starting_ammo = 2
	weapon.refill_on_phase = true

	# Projectile
	weapon.pooled_projectile_type = "player_laser"  # TODO: create EMP projectile
	weapon.use_pooling = true
	weapon.firing_offset = Vector2(0, -30)

	return weapon

#endregion

#region Getters by Name (Factory Pattern)

## Get PRIMARY weapon by name
## @param weapon_name: Name identifier (e.g., "basic_laser", "spread_shot", "rapid_fire")
## @returns: WeaponData or null if not found
static func get_primary_weapon(weapon_name: String) -> WeaponData:
	match weapon_name.to_lower():
		"basic_laser":
			return create_basic_laser()
		"spread_shot":
			return create_spread_shot()
		"rapid_fire":
			return create_rapid_fire()
		_:
			push_warning("[WeaponDatabase] Unknown PRIMARY weapon: %s" % weapon_name)
			return null

## Get SECONDARY weapon by name
static func get_secondary_weapon(weapon_name: String) -> WeaponData:
	match weapon_name.to_lower():
		"homing_missile":
			return create_homing_missile()
		"shotgun_blast":
			return create_shotgun_blast()
		"burst_cannon":
			return create_burst_cannon()
		_:
			push_warning("[WeaponDatabase] Unknown SECONDARY weapon: %s" % weapon_name)
			return null

## Get SPECIAL weapon by name
static func get_special_weapon(weapon_name: String) -> WeaponData:
	match weapon_name.to_lower():
		"plasma_bomb":
			return create_plasma_bomb()
		"railgun":
			return create_railgun()
		"emp_pulse":
			return create_emp_pulse()
		_:
			push_warning("[WeaponDatabase] Unknown SPECIAL weapon: %s" % weapon_name)
			return null

## Get all available PRIMARY weapon names
static func get_primary_weapon_names() -> Array[String]:
	return ["basic_laser", "spread_shot", "rapid_fire"]

## Get all available SECONDARY weapon names
static func get_secondary_weapon_names() -> Array[String]:
	return ["homing_missile", "shotgun_blast", "burst_cannon"]

## Get all available SPECIAL weapon names
static func get_special_weapon_names() -> Array[String]:
	return ["plasma_bomb", "railgun", "emp_pulse"]

#endregion
