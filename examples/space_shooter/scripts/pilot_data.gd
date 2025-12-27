## Pilot Data Resource
##
## Defines stats, modifiers, and special abilities for different pilot types.
## Pilots provide unique bonuses that synergize with ships and weapons.
##
## Design Patterns:
## - Data Transfer Object: Only holds data, no logic
## - Strategy Pattern: Different pilots = different strategies
## - Open/Closed: Add new pilots without modifying code

class_name PilotData extends Resource

#region Enums
## Difficulty levels (how hard to play effectively)
enum Difficulty {
	EASY = 1,      ## Simple, forgiving gameplay
	MEDIUM = 2,    ## Balanced risk/reward
	HARD = 3,      ## Requires skill to maximize
	EXPERT = 4,    ## High risk/reward
	MASTER = 5     ## For experienced players only
}

## Special ability types
enum AbilityType {
	NONE,
	REGENERATION,        ## Health regen over time
	COMBO_BOOST,         ## Enhanced combo system
	RESOURCE_SCAVENGER,  ## Better drops
	BERSERKER_MODE,      ## Stronger when damaged
	INVINCIBILITY_TRIGGER, ## Auto-invincibility at low HP
	AMMO_EFFICIENCY,     ## Better ammo usage
	SPECIAL_RECHARGE,    ## Extra SPECIAL ammo
	ALWAYS_SECONDARY     ## SECONDARY can't be disabled
}
#endregion

#region Pilot Identity
@export_group("Identity")
## Pilot display name
@export var pilot_name: String = "Pilot"

## Pilot description/backstory
@export_multiline var description: String = "A skilled pilot"

## Pilot portrait/avatar
@export var portrait: Texture2D

## Difficulty rating (1-5 stars)
@export var difficulty: Difficulty = Difficulty.MEDIUM

## Archetype (for categorization)
@export var archetype: String = "Balanced"  # "Tank", "DPS", "Support", etc.
#endregion

#region Base Stat Modifiers
@export_group("Base Stats Modifiers")
## Health multiplier (1.0 = 100%, 1.3 = +30%, 0.9 = -10%)
@export_range(0.5, 2.0, 0.05) var health_modifier: float = 1.0

## Speed multiplier
@export_range(0.5, 2.0, 0.05) var speed_modifier: float = 1.0

## Global damage multiplier (affects ALL weapons)
@export_range(0.5, 2.0, 0.05) var global_damage_modifier: float = 1.0

## Global fire rate multiplier (affects ALL weapons)
@export_range(0.5, 2.0, 0.05) var global_fire_rate_modifier: float = 1.0
#endregion

#region Weapon-Specific Modifiers
@export_group("Weapon Category Modifiers")
## PRIMARY weapon damage multiplier
@export_range(0.5, 2.0, 0.05) var primary_damage_modifier: float = 1.0

## PRIMARY weapon fire rate multiplier
@export_range(0.5, 2.0, 0.05) var primary_fire_rate_modifier: float = 1.0

## SECONDARY weapon damage multiplier
@export_range(0.5, 2.0, 0.05) var secondary_damage_modifier: float = 1.0

## SECONDARY weapon fire rate multiplier
@export_range(0.5, 2.0, 0.05) var secondary_fire_rate_modifier: float = 1.0

## SECONDARY weapon ammo capacity multiplier
@export_range(0.5, 2.0, 0.05) var secondary_ammo_modifier: float = 1.0

## SPECIAL weapon damage multiplier
@export_range(0.5, 2.0, 0.05) var special_damage_modifier: float = 1.0

## SPECIAL weapon cooldown multiplier (0.8 = 20% faster)
@export_range(0.5, 2.0, 0.05) var special_cooldown_modifier: float = 1.0

## SPECIAL weapon ammo capacity modifier (additive, not multiplicative)
@export_range(-5, 10, 1) var special_ammo_bonus: int = 0
#endregion

#region Invincibility Modifiers
@export_group("Invincibility")
## Invincibility duration multiplier after taking damage
@export_range(0.5, 3.0, 0.1) var invincibility_duration_modifier: float = 1.0

## Invincibility cooldown multiplier (not commonly used, but available)
@export_range(0.5, 2.0, 0.1) var invincibility_cooldown_modifier: float = 1.0
#endregion

#region Special Abilities
@export_group("Special Abilities")
## Primary special ability
@export var primary_ability: AbilityType = AbilityType.NONE

## Secondary special ability (optional)
@export var secondary_ability: AbilityType = AbilityType.NONE

## Ability configuration values (key-value pairs)
## Examples:
##   {"regen_rate": 1.0, "regen_threshold": 0.5}
##   {"combo_decay_multiplier": 0.5, "combo_damage_bonus": 0.1}
@export var ability_config: Dictionary = {}
#endregion

#region Combo System Modifiers
@export_group("Combo System")
## Combo decay time multiplier (2.0 = lasts twice as long)
@export_range(0.5, 3.0, 0.1) var combo_decay_modifier: float = 1.0

## Combo multiplier gain rate (1.5 = builds 50% faster)
@export_range(0.5, 3.0, 0.1) var combo_gain_modifier: float = 1.0
#endregion

#region Explosion Modifiers (for explosive weapons)
@export_group("Explosives")
## Explosion radius multiplier
@export_range(0.5, 2.0, 0.1) var explosion_radius_modifier: float = 1.0

## Explosion damage multiplier
@export_range(0.5, 2.0, 0.1) var explosion_damage_modifier: float = 1.0
#endregion

#region Helper Methods
## Get total damage modifier for a specific weapon category
func get_damage_modifier_for_category(category: int) -> float:
	var base = global_damage_modifier

	match category:
		0:  # PRIMARY
			return base * primary_damage_modifier
		1:  # SECONDARY
			return base * secondary_damage_modifier
		2:  # SPECIAL
			return base * special_damage_modifier
		_:
			return base

## Get total fire rate modifier for a specific weapon category
func get_fire_rate_modifier_for_category(category: int) -> float:
	var base = global_fire_rate_modifier

	match category:
		0:  # PRIMARY
			return base * primary_fire_rate_modifier
		1:  # SECONDARY
			return base * secondary_fire_rate_modifier
		2:  # SPECIAL (affects cooldown)
			return base * special_cooldown_modifier
		_:
			return base

## Check if pilot has a specific ability
func has_ability(ability: AbilityType) -> bool:
	return primary_ability == ability or secondary_ability == ability

## Get ability config value
func get_ability_value(key: String, default: float = 0.0) -> float:
	if key in ability_config:
		return float(ability_config[key])
	return default

## Get difficulty as string
func get_difficulty_string() -> String:
	return Difficulty.keys()[difficulty]

## Get difficulty stars (for UI)
func get_difficulty_stars() -> String:
	return "⭐".repeat(difficulty)
#endregion

#region Summary
## Get human-readable summary of modifiers
func get_modifiers_summary() -> Dictionary:
	return {
		"health": "%+d%%" % int((health_modifier - 1.0) * 100),
		"speed": "%+d%%" % int((speed_modifier - 1.0) * 100),
		"damage": "%+d%%" % int((global_damage_modifier - 1.0) * 100),
		"fire_rate": "%+d%%" % int((global_fire_rate_modifier - 1.0) * 100),
		"primary_damage": "%+d%%" % int((primary_damage_modifier - 1.0) * 100),
		"secondary_damage": "%+d%%" % int((secondary_damage_modifier - 1.0) * 100),
		"special_damage": "%+d%%" % int((special_damage_modifier - 1.0) * 100),
	}
#endregion
