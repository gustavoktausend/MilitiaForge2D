## Navi Database
##
## Central database for all Navi (pilot/character) configurations.
## Implements Factory Pattern to create NaviData resources programmatically.
##
## This follows SOLID principles:
## - Single Responsibility: Only creates and manages Navi data
## - Open/Closed: Add new Navis without modifying existing code
## - Dependency Inversion: Returns abstract NaviData, not specific implementations
##
## Usage:
##   var navi = NaviDatabase.get_navi("megaman")
##   var all_navis = NaviDatabase.get_all_navi_names()

class_name NaviDatabase extends Object

#region Starter Navis (Balanced)

## Create MegaMan.EXE navi
static func create_megaman() -> NaviData:
	var navi = NaviData.new()
	navi.navi_name = "MegaMan.EXE"
	navi.description = "Navi balanceado com boa versatilidade. Forte contra elétrico."
	navi.max_hp = 150
	navi.starting_hp = 150
	navi.element = ChipData.ElementType.NONE
	navi.color_theme = Color(0.2, 0.5, 1.0)

	# Default attack
	navi.default_attack_damage = 10
	navi.default_attack_type = ChipData.ChipType.PROJECTILE
	navi.default_attack_element = ChipData.ElementType.NONE
	navi.default_attack_range = ChipData.AttackRange.RANGED

	# Resistances (balanced)
	navi.fire_resistance = 1.0
	navi.water_resistance = 1.0
	navi.electric_resistance = 0.7  # Resistant to electric
	navi.wood_resistance = 1.0
	navi.wind_resistance = 1.0

	return navi

## Create FireMan.EXE navi
static func create_fireman() -> NaviData:
	var navi = NaviData.new()
	navi.navi_name = "FireMan.EXE"
	navi.description = "Navi ofensivo especializado em fogo. Forte contra madeira, fraco contra água."
	navi.max_hp = 130
	navi.starting_hp = 130
	navi.element = ChipData.ElementType.FIRE
	navi.color_theme = Color(1.0, 0.3, 0.0)

	# Default attack - Fire element
	navi.default_attack_damage = 12
	navi.default_attack_type = ChipData.ChipType.PROJECTILE
	navi.default_attack_element = ChipData.ElementType.FIRE
	navi.default_attack_range = ChipData.AttackRange.RANGED

	# Resistances (fire specialist)
	navi.fire_resistance = 0.5   # Resistant to fire
	navi.water_resistance = 1.5  # Weak to water
	navi.electric_resistance = 1.0
	navi.wood_resistance = 0.7   # Strong against wood
	navi.wind_resistance = 1.0

	# Special ability: Fire chips deal +20% damage
	navi.special_ability_name = "Fire Boost"
	navi.special_ability_description = "Fire chips deal +20% damage"
	navi.damage_multiplier = 1.2

	return navi

## Create AquaMan.EXE navi
static func create_aquaman() -> NaviData:
	var navi = NaviData.new()
	navi.navi_name = "AquaMan.EXE"
	navi.description = "Navi defensivo especializado em água. Forte contra fogo, fraco contra elétrico."
	navi.max_hp = 160
	navi.starting_hp = 160
	navi.element = ChipData.ElementType.WATER
	navi.color_theme = Color(0.2, 0.6, 1.0)

	# Default attack - Water element
	navi.default_attack_damage = 8
	navi.default_attack_type = ChipData.ChipType.PROJECTILE
	navi.default_attack_element = ChipData.ElementType.WATER
	navi.default_attack_range = ChipData.AttackRange.RANGED

	# Resistances (water specialist)
	navi.fire_resistance = 0.6   # Strong against fire
	navi.water_resistance = 0.5  # Resistant to water
	navi.electric_resistance = 1.5 # Weak to electric
	navi.wood_resistance = 1.0
	navi.wind_resistance = 1.0

	# Special ability: Higher HP pool
	navi.special_ability_name = "High HP"
	navi.special_ability_description = "Increased max HP pool"

	return navi

## Create ElecMan.EXE navi
static func create_elecman() -> NaviData:
	var navi = NaviData.new()
	navi.navi_name = "ElecMan.EXE"
	navi.description = "Navi rápido especializado em elétrico. Forte contra água, fraco contra madeira."
	navi.max_hp = 120
	navi.starting_hp = 120
	navi.element = ChipData.ElementType.ELECTRIC
	navi.color_theme = Color(1.0, 1.0, 0.2)

	# Default attack - Electric element, higher damage
	navi.default_attack_damage = 15
	navi.default_attack_type = ChipData.ChipType.PROJECTILE
	navi.default_attack_element = ChipData.ElementType.ELECTRIC
	navi.default_attack_range = ChipData.AttackRange.RANGED

	# Resistances (electric specialist)
	navi.fire_resistance = 1.0
	navi.water_resistance = 0.6  # Strong against water
	navi.electric_resistance = 0.5 # Resistant to electric
	navi.wood_resistance = 1.5   # Weak to wood
	navi.wind_resistance = 1.0

	# Special ability: Electric chips deal +20% damage
	navi.special_ability_name = "Electric Boost"
	navi.special_ability_description = "Electric chips deal +20% damage"
	navi.damage_multiplier = 1.2

	return navi

## Create WoodMan.EXE navi
static func create_woodman() -> NaviData:
	var navi = NaviData.new()
	navi.navi_name = "WoodMan.EXE"
	navi.description = "Navi tanque especializado em madeira. Forte contra elétrico, fraco contra fogo."
	navi.max_hp = 180
	navi.starting_hp = 180
	navi.element = ChipData.ElementType.WOOD
	navi.color_theme = Color(0.3, 0.8, 0.2)

	# Default attack - Wood element
	navi.default_attack_damage = 10
	navi.default_attack_type = ChipData.ChipType.PROJECTILE
	navi.default_attack_element = ChipData.ElementType.WOOD
	navi.default_attack_range = ChipData.AttackRange.RANGED

	# Resistances (wood specialist)
	navi.fire_resistance = 1.5   # Weak to fire
	navi.water_resistance = 1.0
	navi.electric_resistance = 0.6 # Strong against electric
	navi.wood_resistance = 0.5   # Resistant to wood
	navi.wind_resistance = 1.0

	# Special ability: Very high HP and regeneration
	navi.special_ability_name = "Tank & Regeneration"
	navi.special_ability_description = "High HP and slow health regeneration"
	navi.defense_modifier = 1.1

	return navi

## Create WindMan.EXE navi
static func create_windman() -> NaviData:
	var navi = NaviData.new()
	navi.navi_name = "WindMan.EXE"
	navi.description = "Navi ágil especializado em vento. Ataques rápidos e evasivos."
	navi.max_hp = 110
	navi.starting_hp = 110
	navi.element = ChipData.ElementType.WIND
	navi.color_theme = Color(0.7, 1.0, 0.7)

	# Default attack - Wind element, fast
	navi.default_attack_damage = 9
	navi.default_attack_type = ChipData.ChipType.PROJECTILE
	navi.default_attack_element = ChipData.ElementType.WIND
	navi.default_attack_range = ChipData.AttackRange.RANGED

	# Resistances (wind specialist)
	navi.fire_resistance = 1.2
	navi.water_resistance = 0.9
	navi.electric_resistance = 1.0
	navi.wood_resistance = 0.8
	navi.wind_resistance = 0.5   # Resistant to wind

	# Special ability: Speed boost and evasion
	navi.special_ability_name = "Speed & Evasion"
	navi.special_ability_description = "Increased speed and dodge chance"
	navi.speed_modifier = 1.3

	return navi

#endregion

#region Advanced Navis

## Create ProtoMan.EXE navi
static func create_protoman() -> NaviData:
	var navi = NaviData.new()
	navi.navi_name = "ProtoMan.EXE"
	navi.description = "Navi avançado com foco em ataques corpo a corpo. Alto dano mas baixo HP."
	navi.max_hp = 100
	navi.starting_hp = 100
	navi.element = ChipData.ElementType.NONE
	navi.color_theme = Color(0.9, 0.1, 0.1)

	# Default attack - MELEE, high damage
	navi.default_attack_damage = 20
	navi.default_attack_type = ChipData.ChipType.MELEE
	navi.default_attack_element = ChipData.ElementType.NONE
	navi.default_attack_range = ChipData.AttackRange.MELEE

	# Balanced resistances
	navi.fire_resistance = 0.9
	navi.water_resistance = 0.9
	navi.electric_resistance = 0.9
	navi.wood_resistance = 0.9
	navi.wind_resistance = 0.9

	# Special ability: MELEE damage boost
	navi.special_ability_name = "Sword Master"
	navi.special_ability_description = "MELEE attacks have critical hit chance"
	navi.damage_multiplier = 1.3

	return navi

## Create GutsMan.EXE navi
static func create_gutsman() -> NaviData:
	var navi = NaviData.new()
	navi.navi_name = "GutsMan.EXE"
	navi.description = "Navi tanque extremo. Muito HP mas ataque lento."
	navi.max_hp = 200
	navi.starting_hp = 200
	navi.element = ChipData.ElementType.NONE
	navi.color_theme = Color(0.6, 0.4, 0.2)

	# Default attack - MELEE, area damage
	navi.default_attack_damage = 15
	navi.default_attack_type = ChipData.ChipType.MELEE
	navi.default_attack_element = ChipData.ElementType.NONE
	navi.default_attack_range = ChipData.AttackRange.MELEE

	# High resistances
	navi.fire_resistance = 0.8
	navi.water_resistance = 0.8
	navi.electric_resistance = 0.8
	navi.wood_resistance = 0.8
	navi.wind_resistance = 0.8

	# Special ability: Super tanky
	navi.special_ability_name = "Super Armor"
	navi.special_ability_description = "Massive defense and area attacks"
	navi.defense_modifier = 1.3

	return navi

#endregion

#region Factory Methods

## Get a navi by name
## @param navi_name: Name identifier (lowercase)
## @returns: NaviData or null if not found
static func get_navi(navi_name: String) -> NaviData:
	match navi_name.to_lower():
		# Starter Navis
		"megaman":
			return create_megaman()
		"fireman":
			return create_fireman()
		"aquaman":
			return create_aquaman()
		"elecman":
			return create_elecman()
		"woodman":
			return create_woodman()
		"windman":
			return create_windman()

		# Advanced Navis
		"protoman":
			return create_protoman()
		"gutsman":
			return create_gutsman()

		_:
			push_warning("[NaviDatabase] Unknown navi: %s" % navi_name)
			return null

## Get all available navi names
## @returns: Array of navi identifiers
static func get_all_navi_names() -> Array[String]:
	return [
		# Starter Navis (6)
		"megaman",
		"fireman",
		"aquaman",
		"elecman",
		"woodman",
		"windman",

		# Advanced Navis (2)
		"protoman",
		"gutsman",
	]

## Get navis by element
## @param element: ChipData.ElementType enum value
## @returns: Array of navi names
static func get_navis_by_element(element: ChipData.ElementType) -> Array[String]:
	var navis: Array[String] = []

	for navi_name in get_all_navi_names():
		var navi = get_navi(navi_name)
		if navi and navi.element == element:
			navis.append(navi_name)

	return navis

## Get navis by rarity
## @param rarity: Rarity string (Common, Uncommon, Rare, Epic, Legendary)
## @returns: Array of navi names
static func get_navis_by_rarity(rarity: String) -> Array[String]:
	var navis: Array[String] = []

	for navi_name in get_all_navi_names():
		var navi = get_navi(navi_name)
		if navi and navi.rarity == rarity:
			navis.append(navi_name)

	return navis

## Get navis by default attack type
## @param attack_type: ChipData.ChipType enum value
## @returns: Array of navi names
static func get_navis_by_attack_type(attack_type: ChipData.ChipType) -> Array[String]:
	var navis: Array[String] = []

	for navi_name in get_all_navi_names():
		var navi = get_navi(navi_name)
		if navi and navi.default_attack_type == attack_type:
			navis.append(navi_name)

	return navis

## Get total number of navis
## @returns: Total navi count
static func get_navi_count() -> int:
	return get_all_navi_names().size()

#endregion
