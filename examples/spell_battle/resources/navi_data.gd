## Navi Data Resource
##
## Defines the stats and properties for a Navi (battle character).
## Used to create data-driven Navi configurations.
##
## @tutorial(Spell Battle): res://examples/spell_battle/README.md

class_name NaviData extends Resource

#region Identity
@export_group("Identity")
## Navi display name
@export var navi_name: String = "Unnamed Navi"

## Navi description/lore
@export_multiline var description: String = "A battle Navi"

## Navi sprite
@export var sprite: Texture2D

## Navi portrait for UI
@export var portrait: Texture2D

## Navi color theme
@export var color_theme: Color = Color.WHITE

## Navi primary element
@export var element: ChipData.ElementType = ChipData.ElementType.NONE
#endregion

#region Base Stats
@export_group("Base Stats")
## Maximum HP
@export var max_hp: int = 100

## Starting HP (if different from max)
@export var starting_hp: int = 100
#endregion

#region Default Attack
@export_group("Default Attack")
## Default attack damage (executado após os 3 chips)
@export var default_attack_damage: int = 10

## Default attack type
@export var default_attack_type: ChipData.ChipType = ChipData.ChipType.PROJECTILE

## Default attack element
@export var default_attack_element: ChipData.ElementType = ChipData.ElementType.NONE

## Default attack range
@export var default_attack_range: ChipData.AttackRange = ChipData.AttackRange.RANGED

## Default attack projectile scene (if PROJECTILE type)
@export var default_attack_projectile: PackedScene

## Default attack visual effect
@export var default_attack_effect: PackedScene

## Default attack sound
@export var default_attack_sound: AudioStream
#endregion

#region Stats Modifiers
@export_group("Stats Modifiers")
## Global damage multiplier
@export var damage_multiplier: float = 1.0

## Global chip HP multiplier
@export var chip_hp_multiplier: float = 1.0

## Speed modifier (for animations/effects)
@export var speed_modifier: float = 1.0

## Defense modifier (reduces incoming damage)
@export var defense_modifier: float = 1.0
#endregion

#region Special Abilities
@export_group("Special Abilities")
## Special ability name (optional)
@export var special_ability_name: String = ""

## Special ability description
@export_multiline var special_ability_description: String = ""

## Ability trigger type
@export_enum("None", "OnBattleStart", "OnTurnStart", "OnLowHP", "OnChipDestroyed") var ability_trigger: String = "None"

## Ability effect (script or resource)
@export var ability_effect: Resource
#endregion

#region Elemental Affinities
@export_group("Elemental Affinities")
## Resistances/weaknesses to elements (1.0 = normal, 0.5 = resistant, 1.5 = weak)
@export var fire_resistance: float = 1.0
@export var water_resistance: float = 1.0
@export var electric_resistance: float = 1.0
@export var wood_resistance: float = 1.0
@export var wind_resistance: float = 1.0
#endregion

#region Helper Methods
## Get resistance multiplier for an element
## @param element: ElementType to check
## @returns: Resistance multiplier (1.0 = normal damage)
func get_element_resistance(element: ChipData.ElementType) -> float:
	match element:
		ChipData.ElementType.FIRE:
			return fire_resistance
		ChipData.ElementType.WATER:
			return water_resistance
		ChipData.ElementType.ELECTRIC:
			return electric_resistance
		ChipData.ElementType.WOOD:
			return wood_resistance
		ChipData.ElementType.WIND:
			return wind_resistance
		_:
			return 1.0

## Check if Navi is weak to an element
## @param element: ElementType to check
## @returns: true if weak (>1.0 resistance)
func is_weak_to(element: ChipData.ElementType) -> bool:
	return get_element_resistance(element) > 1.0

## Check if Navi is resistant to an element
## @param element: ElementType to check
## @returns: true if resistant (<1.0 resistance)
func is_resistant_to(element: ChipData.ElementType) -> bool:
	return get_element_resistance(element) < 1.0

## Get modified damage based on element
## @param base_damage: Base damage value
## @param element: Element of the attack
## @returns: Modified damage
func get_modified_damage(base_damage: int, element: ChipData.ElementType) -> int:
	var resistance = get_element_resistance(element)
	var modified = float(base_damage) * resistance * defense_modifier
	return int(modified)

## Check if Navi has a special ability
## @returns: true if ability is configured
func has_special_ability() -> bool:
	return not special_ability_name.is_empty() and ability_trigger != "None"

## Get Navi info as formatted string
func get_info_text() -> String:
	var info = "[NAVI] %s\n" % navi_name
	info += "HP: %d/%d\n" % [starting_hp, max_hp]
	info += "Default Attack: %s (%d DMG)\n" % [
		ChipData.ChipType.keys()[default_attack_type],
		default_attack_damage
	]

	if has_special_ability():
		info += "\nAbility: %s\n" % special_ability_name
		info += "%s\n" % special_ability_description

	info += "\n%s" % description
	return info

## Get color-coded element resistance display
func get_resistances_text() -> String:
	var text = "Elemental Resistances:\n"

	if fire_resistance != 1.0:
		text += "  Fire: %.0f%%\n" % (fire_resistance * 100.0)
	if water_resistance != 1.0:
		text += "  Water: %.0f%%\n" % (water_resistance * 100.0)
	if electric_resistance != 1.0:
		text += "  Electric: %.0f%%\n" % (electric_resistance * 100.0)
	if wood_resistance != 1.0:
		text += "  Wood: %.0f%%\n" % (wood_resistance * 100.0)
	if wind_resistance != 1.0:
		text += "  Wind: %.0f%%\n" % (wind_resistance * 100.0)

	return text if text != "Elemental Resistances:\n" else "No elemental affinities"
#endregion
