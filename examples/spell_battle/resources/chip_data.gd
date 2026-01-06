## Chip Data Resource
##
## Defines the stats and properties for a battle chip/spell.
## Used to create data-driven chip configurations.
##
## @tutorial(Spell Battle): res://examples/spell_battle/README.md

class_name ChipData extends Resource

#region Enums
## Chip type determines how the chip is cast
enum ChipType {
	MELEE,           ## Spell corpo a corpo (ataque instantâneo)
	PROJECTILE,      ## Spell projétil
	AREA_DAMAGE,     ## Spell de área
	BUFF,            ## Buff para o Navi
	DEBUFF,          ## Debuff no inimigo
	CHIP_DESTROYER,  ## Ataca chips inimigos
	SHIELD,          ## Defesa/intercepta ataques
	TRANSFORM_AREA   ## Altera campo de batalha
}

## Elemental properties
enum ElementType {
	NONE,      ## Sem elemento
	FIRE,      ## Fogo
	WATER,     ## Água
	ELECTRIC,  ## Elétrico
	WOOD,      ## Natureza
	WIND       ## Vento
}

## Attack range
enum AttackRange {
	MELEE,     ## Corpo a corpo
	RANGED     ## Distância
}

## Target type
enum TargetType {
	ENEMY_NAVI,  ## Ataca o Navi inimigo
	ENEMY_CHIP,  ## Ataca chips inimigos
	ALLY_NAVI,   ## Alvo aliado (buff/heal)
	SELF,        ## Auto-alvo
	FIELD        ## Campo de batalha
}
#endregion

#region Identity
@export_group("Identity")
## Chip display name
@export var chip_name: String = "Unnamed Chip"

## Chip description
@export_multiline var description: String = "A battle chip"

## Chip icon/sprite for UI
@export var icon: Texture2D

## Chip rarity (for visual/sorting purposes)
@export_enum("Common", "Uncommon", "Rare", "Epic", "Legendary") var rarity: String = "Common"
#endregion

#region Combat Stats
@export_group("Combat Stats")
## Chip type
@export var chip_type: ChipType = ChipType.PROJECTILE

## Damage dealt by the chip
@export var damage: int = 10

## HP do próprio chip (pode ser destruído)
@export var chip_hp: int = 50

## Maximum HP do chip
@export var max_chip_hp: int = 50

## Target type
@export var target_type: TargetType = TargetType.ENEMY_NAVI
#endregion

#region Elemental Properties
@export_group("Elemental Properties")
## Elemento do chip
@export var element: ElementType = ElementType.NONE

## Attack range (corpo a corpo vs distância)
@export var attack_range: AttackRange = AttackRange.RANGED
#endregion

#region Area/Effect Settings
@export_group("Area/Effect Settings")
## Radius for AREA_DAMAGE type
@export var area_radius: float = 100.0

## Duration for BUFF/DEBUFF effects (seconds)
@export var effect_duration: float = 5.0

## Stat modifiers for BUFF/DEBUFF (e.g., {"damage": 10, "speed": -20})
@export var stat_modifiers: Dictionary = {}

## Field effect type for TRANSFORM_AREA
@export_enum("Normal", "Fire", "Ice", "Electric", "Poison") var field_effect: String = "Normal"

## Field effect duration for TRANSFORM_AREA
@export var field_duration: float = 10.0
#endregion

#region Visual/Audio
@export_group("Visual & Audio")
## Spell scene to instantiate when chip is cast
@export var spell_scene: PackedScene

## Visual effect on cast
@export var cast_effect: PackedScene

## Visual effect on impact
@export var impact_effect: PackedScene

## Sound effect when chip is cast
@export var cast_sound: AudioStream

## Sound effect on impact
@export var impact_sound: AudioStream

## Chip color for visual customization
@export var chip_color: Color = Color.WHITE
#endregion

#region Helper Methods
## Get a display string for the chip type
func get_chip_type_name() -> String:
	return ChipType.keys()[chip_type]

## Get a display string for the element
func get_element_name() -> String:
	return ElementType.keys()[element]

## Get a display string for the attack range
func get_attack_range_name() -> String:
	return AttackRange.keys()[attack_range]

## Get a display string for the target type
func get_target_type_name() -> String:
	return TargetType.keys()[target_type]

## Check if chip is offensive (deals damage)
func is_offensive() -> bool:
	return chip_type in [ChipType.MELEE, ChipType.PROJECTILE, ChipType.AREA_DAMAGE, ChipType.CHIP_DESTROYER]

## Check if chip is support (buff/heal/shield)
func is_support() -> bool:
	return chip_type in [ChipType.BUFF, ChipType.SHIELD]

## Check if chip is debuff
func is_debuff() -> bool:
	return chip_type == ChipType.DEBUFF

## Check if chip has an element
func has_element() -> bool:
	return element != ElementType.NONE

## Get chip info as formatted string
func get_info_text() -> String:
	var info = "[%s] %s\n" % [rarity.to_upper(), chip_name]
	info += "Type: %s | Element: %s\n" % [get_chip_type_name(), get_element_name()]
	info += "Damage: %d | HP: %d/%d\n" % [damage, chip_hp, max_chip_hp]
	info += "Range: %s\n" % get_attack_range_name()
	info += "\n%s" % description
	return info
#endregion
