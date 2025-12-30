## Pilot Database - Factory Pattern
##
## Centralized database for creating pre-configured pilot data.
## Provides 8 unique pilots with distinct playstyles and bonuses.
##
## Design Patterns:
## - Factory Pattern: Creates pilots without exposing instantiation logic
## - Strategy Pattern: Each pilot represents a different strategy
## - Data Transfer Object: Returns PilotData resources
##
## Usage:
##   var pilot = PilotDatabase.get_pilot("ace_gunner")
##   var all_pilots = PilotDatabase.get_all_pilots()

class_name PilotDatabase extends RefCounted

#region Public API
## Get pilot by name (case-insensitive)
static func get_pilot(pilot_name: String) -> PilotData:
	match pilot_name.to_lower().replace(" ", "_"):
		"ace_gunner":
			return create_ace_gunner()
		"tank_commander":
			return create_tank_commander()
		"speed_demon":
			return create_speed_demon()
		"engineer":
			return create_engineer()
		"dual_wielder":
			return create_dual_wielder()
		"combo_master":
			return create_combo_master()
		"scavenger":
			return create_scavenger()
		"berserker":
			return create_berserker()
		_:
			push_error("[PilotDatabase] Unknown pilot: %s" % pilot_name)
			return null

## Get all available pilots
static func get_all_pilots() -> Array[PilotData]:
	return [
		create_ace_gunner(),
		create_tank_commander(),
		create_speed_demon(),
		create_engineer(),
		create_dual_wielder(),
		create_combo_master(),
		create_scavenger(),
		create_berserker()
	]

## Get pilot names (for UI dropdowns)
static func get_pilot_names() -> Array[String]:
	return [
		"Ace Gunner",
		"Tank Commander",
		"Speed Demon",
		"Engineer",
		"Dual Wielder",
		"Combo Master",
		"Scavenger",
		"Berserker"
	]
#endregion

#region Factory Methods - DPS Archetype
## ACE GUNNER - PRIMARY weapon specialist
## Difficulty: ⭐⭐ (MEDIUM)
## Playstyle: Focus on PRIMARY weapon mastery
static func create_ace_gunner() -> PilotData:
	var pilot = PilotData.new()

	# Identity
	pilot.pilot_name = "I.N.D.I.O"
	pilot.description = "\"Every shot counts, every target falls.\"\n\nA precision shooter who has mastered the art of PRIMARY weapons. Sacrifices durability for devastating firepower."
	pilot.difficulty = PilotData.Difficulty.MEDIUM
	pilot.archetype = "DPS"

	# Portrait and License card
	pilot.portrait = load("res://examples/space_shooter/assets/sprites/pilot_licenses/indio_pilot.png")
	pilot.license_card = load("res://examples/space_shooter/assets/sprites/pilot_licenses/indio_pilot.png")

	# Base stats
	pilot.health_modifier = 0.90  # -10% health
	pilot.speed_modifier = 1.0    # Normal speed
	pilot.global_damage_modifier = 1.0
	pilot.global_fire_rate_modifier = 1.0

	# PRIMARY weapon specialization
	pilot.primary_damage_modifier = 1.25      # +25% PRIMARY damage
	pilot.primary_fire_rate_modifier = 1.15   # +15% PRIMARY fire rate

	# Normal SECONDARY and SPECIAL
	pilot.secondary_damage_modifier = 1.0
	pilot.secondary_fire_rate_modifier = 1.0
	pilot.special_damage_modifier = 1.0
	pilot.special_cooldown_modifier = 1.0

	# No special abilities - pure stat bonuses
	pilot.primary_ability = PilotData.AbilityType.NONE
	pilot.secondary_ability = PilotData.AbilityType.NONE

	return pilot
#endregion

#region Factory Methods - Tank Archetype
## TANK COMMANDER - Survivability specialist
## Difficulty: ⭐ (EASY)
## Playstyle: Absorb damage and outlast enemies
static func create_tank_commander() -> PilotData:
	var pilot = PilotData.new()

	# Identity
	pilot.pilot_name = "Tank Commander"
	pilot.description = "\"I am the wall that never breaks.\"\n\nA defensive juggernaut with enhanced shields and regeneration. Slow but nearly indestructible."
	pilot.difficulty = PilotData.Difficulty.EASY
	pilot.archetype = "Tank"

	# Portrait and License card
	pilot.portrait = load("res://examples/space_shooter/assets/sprites/pilot_licenses/tank_commander_pilot.png")
	pilot.license_card = load("res://examples/space_shooter/assets/sprites/pilot_licenses/tank_commander_pilot.png")

	# Base stats - tanky!
	pilot.health_modifier = 1.30  # +30% health
	pilot.speed_modifier = 0.85   # -15% speed
	pilot.global_damage_modifier = 1.0
	pilot.global_fire_rate_modifier = 1.0

	# Normal weapon stats
	pilot.primary_damage_modifier = 1.0
	pilot.secondary_damage_modifier = 1.0
	pilot.special_damage_modifier = 1.0

	# Enhanced survivability
	pilot.invincibility_duration_modifier = 1.5  # +50% invincibility time (0.5s bonus)

	# Special ability: Health regeneration
	pilot.primary_ability = PilotData.AbilityType.REGENERATION
	pilot.ability_config = {
		"regen_rate": 1.0,        # 1 HP per second
		"regen_threshold": 1.0    # Always regenerating (even at full HP)
	}

	return pilot
#endregion

#region Factory Methods - Speed Archetype
## SPEED DEMON - Mobility specialist
## Difficulty: ⭐⭐⭐ (HARD)
## Playstyle: Hit and run tactics, dodge everything
static func create_speed_demon() -> PilotData:
	var pilot = PilotData.new()

	# Identity
	pilot.pilot_name = "Speed Demon"
	pilot.description = "\"Can't hit what you can't catch.\"\n\nBlinding speed and rapid-fire SECONDARY weapons. Fragile but untouchable in skilled hands."
	pilot.difficulty = PilotData.Difficulty.HARD
	pilot.archetype = "Speed"

	# Portrait and License card
	pilot.portrait = load("res://examples/space_shooter/assets/sprites/pilot_licenses/speed_demon_pilot.png")
	pilot.license_card = load("res://examples/space_shooter/assets/sprites/pilot_licenses/speed_demon_pilot.png")

	# Base stats - fast and fragile
	pilot.health_modifier = 1.0
	pilot.speed_modifier = 1.40      # +40% speed
	pilot.global_damage_modifier = 0.80  # -20% damage (tradeoff)
	pilot.global_fire_rate_modifier = 1.0

	# SECONDARY weapon specialization
	pilot.primary_damage_modifier = 1.0
	pilot.secondary_damage_modifier = 1.0  # Normal damage (global penalty applies)
	pilot.secondary_fire_rate_modifier = 1.20  # +20% SECONDARY fire rate
	pilot.special_damage_modifier = 1.0

	# Combo system bonuses (synergizes with speed)
	pilot.combo_decay_modifier = 1.2   # +20% longer combo time
	pilot.combo_gain_modifier = 1.3    # +30% faster combo buildup

	# No special abilities
	pilot.primary_ability = PilotData.AbilityType.NONE

	return pilot
#endregion

#region Factory Methods - Support/Tech Archetype
## ENGINEER - SPECIAL weapon and explosive specialist
## Difficulty: ⭐⭐⭐ (HARD)
## Playstyle: Strategic use of limited resources
static func create_engineer() -> PilotData:
	var pilot = PilotData.new()

	# Identity
	pilot.pilot_name = "Engineer"
	pilot.description = "\"Precision engineering meets explosive results.\"\n\nExpert in SPECIAL weapons and explosives. Starts with extra ammo and enhanced blast radius."
	pilot.difficulty = PilotData.Difficulty.HARD
	pilot.archetype = "Support"

	# Portrait and License card
	pilot.portrait = load("res://examples/space_shooter/assets/sprites/pilot_licenses/engineer_pilot.png")
	pilot.license_card = load("res://examples/space_shooter/assets/sprites/pilot_licenses/engineer_pilot.png")

	# Base stats - normal
	pilot.health_modifier = 1.0
	pilot.speed_modifier = 1.0
	pilot.global_damage_modifier = 1.0
	pilot.global_fire_rate_modifier = 1.0

	# Weapon modifiers
	pilot.primary_damage_modifier = 1.0
	pilot.secondary_damage_modifier = 1.0
	pilot.special_damage_modifier = 1.15  # +15% SPECIAL damage
	pilot.special_cooldown_modifier = 0.85  # -15% cooldown (faster)
	pilot.special_ammo_bonus = 2  # +2 SPECIAL ammo

	# Explosive bonuses
	pilot.explosion_radius_modifier = 1.50  # +50% explosion radius
	pilot.explosion_damage_modifier = 1.20  # +20% explosion damage

	# Special ability: SPECIAL ammo recharge
	pilot.primary_ability = PilotData.AbilityType.SPECIAL_RECHARGE
	pilot.ability_config = {
		"recharge_chance": 0.15,  # 15% chance to refund SPECIAL ammo on kill
	}

	return pilot
#endregion

#region Factory Methods - Dual Wield Archetype
## DUAL WIELDER - PRIMARY + SECONDARY combo specialist
## Difficulty: ⭐⭐⭐⭐ (EXPERT)
## Playstyle: Maximize PRIMARY + SECONDARY synergy
static func create_dual_wielder() -> PilotData:
	var pilot = PilotData.new()

	# Identity
	pilot.pilot_name = "Dual Wielder"
	pilot.description = "\"Two guns, twice the carnage.\"\n\nMaster of dual-wielding. SECONDARY is always active and deals massive damage, but PRIMARY is weakened."
	pilot.difficulty = PilotData.Difficulty.EXPERT
	pilot.archetype = "DPS"

	# Portrait and License card
	pilot.portrait = load("res://examples/space_shooter/assets/sprites/pilot_licenses/dual_wielder_pilot.png")
	pilot.license_card = load("res://examples/space_shooter/assets/sprites/pilot_licenses/dual_wielder_pilot.png")

	# Base stats
	pilot.health_modifier = 1.0
	pilot.speed_modifier = 0.95  # -5% speed (dual guns are heavy)
	pilot.global_damage_modifier = 1.0
	pilot.global_fire_rate_modifier = 1.0

	# Weapon modifiers - SECONDARY focus
	pilot.primary_damage_modifier = 0.75    # -25% PRIMARY damage (penalty)
	pilot.secondary_damage_modifier = 1.40  # +40% SECONDARY damage
	pilot.secondary_fire_rate_modifier = 1.10  # +10% SECONDARY fire rate
	pilot.secondary_ammo_modifier = 1.30    # +30% SECONDARY ammo
	pilot.special_damage_modifier = 1.0

	# Special ability: SECONDARY always enabled
	pilot.primary_ability = PilotData.AbilityType.ALWAYS_SECONDARY
	pilot.secondary_ability = PilotData.AbilityType.AMMO_EFFICIENCY
	pilot.ability_config = {
		"ammo_save_chance": 0.20  # 20% chance to not consume SECONDARY ammo
	}

	return pilot
#endregion

#region Factory Methods - Combo Archetype
## COMBO MASTER - Combo system specialist
## Difficulty: ⭐⭐⭐⭐ (EXPERT)
## Playstyle: Build and maintain combos for scaling damage
static func create_combo_master() -> PilotData:
	var pilot = PilotData.new()

	# Identity
	pilot.pilot_name = "Combo Master"
	pilot.description = "\"Every kill feeds the next.\"\n\nThrives on consecutive kills. Combo decays slower and builds faster, with scaling damage bonuses."
	pilot.difficulty = PilotData.Difficulty.EXPERT
	pilot.archetype = "DPS"

	# Portrait and License card
	pilot.portrait = load("res://examples/space_shooter/assets/sprites/pilot_licenses/combo_master_pilot.png")
	pilot.license_card = load("res://examples/space_shooter/assets/sprites/pilot_licenses/combo_master_pilot.png")

	# Base stats - normal
	pilot.health_modifier = 1.0
	pilot.speed_modifier = 1.0
	pilot.global_damage_modifier = 0.90  # -10% base damage (compensated by combo)
	pilot.global_fire_rate_modifier = 1.0

	# Normal weapon modifiers
	pilot.primary_damage_modifier = 1.0
	pilot.secondary_damage_modifier = 1.0
	pilot.special_damage_modifier = 1.0

	# Combo system bonuses
	pilot.combo_decay_modifier = 2.0   # Combo lasts 2x longer
	pilot.combo_gain_modifier = 2.0    # Combo builds 2x faster

	# Special ability: Enhanced combo system
	pilot.primary_ability = PilotData.AbilityType.COMBO_BOOST
	pilot.ability_config = {
		"combo_damage_bonus_per_kill": 0.05,  # +5% damage per combo kill
		"max_combo_bonus": 0.50,               # Max +50% damage at 10 combo
	}

	return pilot
#endregion

#region Factory Methods - Scavenger Archetype
## SCAVENGER - Resource gathering specialist
## Difficulty: ⭐⭐ (MEDIUM)
## Playstyle: Maximize pickups and ammo efficiency
static func create_scavenger() -> PilotData:
	var pilot = PilotData.new()

	# Identity
	pilot.pilot_name = "Scavenger"
	pilot.description = "\"One pilot's trash is my treasure.\"\n\nExpert at finding and utilizing resources. Better drops, more ammo, wider pickup range."
	pilot.difficulty = PilotData.Difficulty.MEDIUM
	pilot.archetype = "Support"

	# Portrait and License card
	pilot.portrait = load("res://examples/space_shooter/assets/sprites/pilot_licenses/scavenger_pilot.png")
	pilot.license_card = load("res://examples/space_shooter/assets/sprites/pilot_licenses/scavenger_pilot.png")

	# Base stats - normal
	pilot.health_modifier = 1.0
	pilot.speed_modifier = 1.05  # +5% speed (to collect drops)
	pilot.global_damage_modifier = 0.95  # -5% damage
	pilot.global_fire_rate_modifier = 1.0

	# Ammo efficiency
	pilot.primary_damage_modifier = 1.0
	pilot.secondary_damage_modifier = 1.0
	pilot.secondary_ammo_modifier = 1.25  # +25% SECONDARY ammo capacity
	pilot.special_damage_modifier = 1.0
	pilot.special_ammo_bonus = 1  # +1 SPECIAL ammo

	# Special ability: Resource scavenger
	pilot.primary_ability = PilotData.AbilityType.RESOURCE_SCAVENGER
	pilot.secondary_ability = PilotData.AbilityType.AMMO_EFFICIENCY
	pilot.ability_config = {
		"drop_rate_multiplier": 1.25,  # +25% drop chance
		"ammo_pickup_multiplier": 1.50,  # +50% ammo from pickups
		"magnetic_range_multiplier": 2.0,  # 2x pickup range
		"ammo_save_chance": 0.10  # 10% chance to not consume ammo
	}

	return pilot
#endregion

#region Factory Methods - Berserker Archetype
## BERSERKER - High risk/high reward specialist
## Difficulty: ⭐⭐⭐⭐⭐ (MASTER)
## Playstyle: Get stronger as health decreases
static func create_berserker() -> PilotData:
	var pilot = PilotData.new()

	# Identity
	pilot.pilot_name = "Berserker"
	pilot.description = "\"Pain is power. Death is weakness.\"\n\nGrows stronger as health decreases. Gains massive damage at low HP but starts with reduced health. For masters only."
	pilot.difficulty = PilotData.Difficulty.MASTER
	pilot.archetype = "DPS"

	# Portrait and License card
	pilot.portrait = load("res://examples/space_shooter/assets/sprites/pilot_licenses/berserker_pilot.png")
	pilot.license_card = load("res://examples/space_shooter/assets/sprites/pilot_licenses/berserker_pilot.png")

	# Base stats - risky
	pilot.health_modifier = 0.85  # -15% max health (risky!)
	pilot.speed_modifier = 1.10   # +10% speed
	pilot.global_damage_modifier = 1.0
	pilot.global_fire_rate_modifier = 1.0

	# Normal weapon modifiers (bonuses come from ability)
	pilot.primary_damage_modifier = 1.0
	pilot.secondary_damage_modifier = 1.0
	pilot.special_damage_modifier = 1.0

	# Invincibility bonus (to survive at low HP)
	pilot.invincibility_duration_modifier = 1.3  # +30% invincibility time

	# Special ability: Berserker mode
	pilot.primary_ability = PilotData.AbilityType.BERSERKER_MODE
	pilot.secondary_ability = PilotData.AbilityType.INVINCIBILITY_TRIGGER
	pilot.ability_config = {
		# Berserker scaling
		"damage_bonus_at_full": 0.0,    # No bonus at 100% HP
		"damage_bonus_at_half": 0.25,   # +25% damage at 50% HP
		"damage_bonus_at_quarter": 0.50,  # +50% damage at 25% HP
		"damage_bonus_at_critical": 0.75,  # +75% damage at 10% HP
		# Auto-invincibility trigger
		"invincibility_threshold": 0.15,  # Auto-trigger at 15% HP
		"invincibility_cooldown": 30.0,   # 30 second cooldown
	}

	return pilot
#endregion

#region Debug
## Print all pilots to console
static func debug_print_all_pilots() -> void:
	print("╔════════════════════════════════════════════════════════════╗")
	print("║              PILOT DATABASE - 8 PILOTS                     ║")
	print("╚════════════════════════════════════════════════════════════╝")

	for pilot in get_all_pilots():
		print("\n┌─ %s (%s) %s" % [pilot.pilot_name, pilot.archetype, pilot.get_difficulty_stars()])
		print("│  %s" % pilot.description.split("\n")[0].strip_edges())
		print("│")

		var mods = pilot.get_modifiers_summary()
		for key in mods:
			if mods[key] != "+0%":
				print("│  • %s: %s" % [key, mods[key]])

		if pilot.primary_ability != PilotData.AbilityType.NONE:
			print("│  • Ability: %s" % PilotData.AbilityType.keys()[pilot.primary_ability])

		print("└─────────────────────────────────────────────────────────")
#endregion
