## Chip Database
##
## Central database for all battle chip configurations.
## Implements Factory Pattern to create ChipData resources programmatically.
##
## This follows SOLID principles:
## - Single Responsibility: Only creates and manages chip data
## - Open/Closed: Add new chips without modifying existing code
## - Dependency Inversion: Returns abstract ChipData, not specific implementations
##
## Usage:
##   var chip = ChipDatabase.get_chip("fireball")
##   var all_chips = ChipDatabase.get_all_chip_names()

class_name ChipDatabase extends Object

#region PROJECTILE Chips (Ranged Attacks)

## Create Fireball chip
static func create_fireball() -> ChipData:
	var chip = ChipData.new()
	chip.chip_name = "Fireball"
	chip.description = "Lança uma bola de fogo que causa dano em área ao impactar."
	chip.chip_type = ChipData.ChipType.PROJECTILE
	chip.damage = 25
	chip.chip_hp = 30
	chip.max_chip_hp = 30
	chip.element = ChipData.ElementType.FIRE
	chip.attack_range = ChipData.AttackRange.RANGED
	chip.target_type = ChipData.TargetType.ENEMY_NAVI
	chip.rarity = "Common"
	chip.chip_color = Color(1.0, 0.4, 0.0)
	return chip

## Create Ice Shard chip
static func create_ice_shard() -> ChipData:
	var chip = ChipData.new()
	chip.chip_name = "Ice Shard"
	chip.description = "Dispara um fragmento de gelo perfurante."
	chip.chip_type = ChipData.ChipType.PROJECTILE
	chip.damage = 20
	chip.chip_hp = 35
	chip.max_chip_hp = 35
	chip.element = ChipData.ElementType.WATER
	chip.attack_range = ChipData.AttackRange.RANGED
	chip.target_type = ChipData.TargetType.ENEMY_NAVI
	chip.rarity = "Common"
	chip.chip_color = Color(0.3, 0.7, 1.0)
	return chip

## Create Thunder Bolt chip
static func create_thunder_bolt() -> ChipData:
	var chip = ChipData.new()
	chip.chip_name = "Thunder Bolt"
	chip.description = "Raio elétrico de alta velocidade."
	chip.chip_type = ChipData.ChipType.PROJECTILE
	chip.damage = 30
	chip.chip_hp = 25
	chip.max_chip_hp = 25
	chip.element = ChipData.ElementType.ELECTRIC
	chip.attack_range = ChipData.AttackRange.RANGED
	chip.target_type = ChipData.TargetType.ENEMY_NAVI
	chip.rarity = "Uncommon"
	chip.chip_color = Color(1.0, 1.0, 0.2)
	return chip

## Create Wind Cutter chip
static func create_wind_cutter() -> ChipData:
	var chip = ChipData.new()
	chip.chip_name = "Wind Cutter"
	chip.description = "Lâmina de vento que corta o inimigo."
	chip.chip_type = ChipData.ChipType.PROJECTILE
	chip.damage = 22
	chip.chip_hp = 32
	chip.max_chip_hp = 32
	chip.element = ChipData.ElementType.WIND
	chip.attack_range = ChipData.AttackRange.RANGED
	chip.target_type = ChipData.TargetType.ENEMY_NAVI
	chip.rarity = "Common"
	chip.chip_color = Color(0.7, 1.0, 0.7)
	return chip

#endregion

#region MELEE Chips (Close Combat)

## Create Sword Slash chip
static func create_sword_slash() -> ChipData:
	var chip = ChipData.new()
	chip.chip_name = "Sword Slash"
	chip.description = "Golpe de espada corpo a corpo. Alto dano mas chip frágil."
	chip.chip_type = ChipData.ChipType.MELEE
	chip.damage = 40
	chip.chip_hp = 25
	chip.max_chip_hp = 25
	chip.element = ChipData.ElementType.NONE
	chip.attack_range = ChipData.AttackRange.MELEE
	chip.target_type = ChipData.TargetType.ENEMY_NAVI
	chip.rarity = "Common"
	chip.chip_color = Color(0.8, 0.8, 0.8)
	return chip

## Create Flame Punch chip
static func create_flame_punch() -> ChipData:
	var chip = ChipData.new()
	chip.chip_name = "Flame Punch"
	chip.description = "Soco flamejante devastador."
	chip.chip_type = ChipData.ChipType.MELEE
	chip.damage = 45
	chip.chip_hp = 22
	chip.max_chip_hp = 22
	chip.element = ChipData.ElementType.FIRE
	chip.attack_range = ChipData.AttackRange.MELEE
	chip.target_type = ChipData.TargetType.ENEMY_NAVI
	chip.rarity = "Uncommon"
	chip.chip_color = Color(1.0, 0.3, 0.0)
	return chip

## Create Thunder Fist chip
static func create_thunder_fist() -> ChipData:
	var chip = ChipData.new()
	chip.chip_name = "Thunder Fist"
	chip.description = "Punho eletrificado com chance de atordoar."
	chip.chip_type = ChipData.ChipType.MELEE
	chip.damage = 38
	chip.chip_hp = 28
	chip.max_chip_hp = 28
	chip.element = ChipData.ElementType.ELECTRIC
	chip.attack_range = ChipData.AttackRange.MELEE
	chip.target_type = ChipData.TargetType.ENEMY_NAVI
	chip.rarity = "Uncommon"
	chip.chip_color = Color(1.0, 1.0, 0.0)
	return chip

#endregion

#region AREA_DAMAGE Chips

## Create Meteor Storm chip
static func create_meteor_storm() -> ChipData:
	var chip = ChipData.new()
	chip.chip_name = "Meteor Storm"
	chip.description = "Chuva de meteoros que atinge uma área."
	chip.chip_type = ChipData.ChipType.AREA_DAMAGE
	chip.damage = 35
	chip.chip_hp = 40
	chip.max_chip_hp = 40
	chip.element = ChipData.ElementType.FIRE
	chip.attack_range = ChipData.AttackRange.RANGED
	chip.target_type = ChipData.TargetType.ENEMY_NAVI
	chip.area_radius = 150.0
	chip.rarity = "Rare"
	chip.chip_color = Color(0.9, 0.3, 0.1)
	return chip

## Create Blizzard chip
static func create_blizzard() -> ChipData:
	var chip = ChipData.new()
	chip.chip_name = "Blizzard"
	chip.description = "Tempestade de gelo em área."
	chip.chip_type = ChipData.ChipType.AREA_DAMAGE
	chip.damage = 30
	chip.chip_hp = 38
	chip.max_chip_hp = 38
	chip.element = ChipData.ElementType.WATER
	chip.attack_range = ChipData.AttackRange.RANGED
	chip.target_type = ChipData.TargetType.ENEMY_NAVI
	chip.area_radius = 120.0
	chip.rarity = "Rare"
	chip.chip_color = Color(0.5, 0.8, 1.0)
	return chip

#endregion

#region BUFF Chips

## Create Power Up chip
static func create_power_up() -> ChipData:
	var chip = ChipData.new()
	chip.chip_name = "Power Up"
	chip.description = "Aumenta o dano do próximo ataque."
	chip.chip_type = ChipData.ChipType.BUFF
	chip.damage = 0
	chip.chip_hp = 50
	chip.max_chip_hp = 50
	chip.element = ChipData.ElementType.NONE
	chip.attack_range = ChipData.AttackRange.RANGED
	chip.target_type = ChipData.TargetType.SELF
	chip.effect_duration = 6.0
	chip.stat_modifiers = {"damage": 15}
	chip.rarity = "Uncommon"
	chip.chip_color = Color(1.0, 0.8, 0.0)
	return chip

#endregion

#region SHIELD Chips

## Create Barrier chip
static func create_barrier() -> ChipData:
	var chip = ChipData.new()
	chip.chip_name = "Barrier"
	chip.description = "Cria uma barreira protetora. HP muito alto."
	chip.chip_type = ChipData.ChipType.SHIELD
	chip.damage = 0
	chip.chip_hp = 80
	chip.max_chip_hp = 80
	chip.element = ChipData.ElementType.NONE
	chip.attack_range = ChipData.AttackRange.RANGED
	chip.target_type = ChipData.TargetType.SELF
	chip.effect_duration = 8.0
	chip.rarity = "Rare"
	chip.chip_color = Color(0.2, 0.6, 1.0)
	return chip

#endregion

#region TRANSFORM_AREA Chips

## Create Lava Field chip
static func create_lava_field() -> ChipData:
	var chip = ChipData.new()
	chip.chip_name = "Lava Field"
	chip.description = "Transforma o campo em lava. Causa dano contínuo."
	chip.chip_type = ChipData.ChipType.TRANSFORM_AREA
	chip.damage = 10  # Dano por tick
	chip.chip_hp = 45
	chip.max_chip_hp = 45
	chip.element = ChipData.ElementType.FIRE
	chip.attack_range = ChipData.AttackRange.RANGED
	chip.target_type = ChipData.TargetType.FIELD
	chip.field_effect = "Fire"
	chip.field_duration = 12.0
	chip.rarity = "Epic"
	chip.chip_color = Color(1.0, 0.2, 0.0)
	return chip

## Create Ice Field chip
static func create_ice_field() -> ChipData:
	var chip = ChipData.new()
	chip.chip_name = "Ice Field"
	chip.description = "Transforma o campo em gelo. Reduz velocidade."
	chip.chip_type = ChipData.ChipType.TRANSFORM_AREA
	chip.damage = 5
	chip.chip_hp = 48
	chip.max_chip_hp = 48
	chip.element = ChipData.ElementType.WATER
	chip.attack_range = ChipData.AttackRange.RANGED
	chip.target_type = ChipData.TargetType.FIELD
	chip.field_effect = "Ice"
	chip.field_duration = 10.0
	chip.rarity = "Epic"
	chip.chip_color = Color(0.6, 0.9, 1.0)
	return chip

#endregion

#region CHIP_DESTROYER Chips

## Create Chip Breaker chip
static func create_chip_breaker() -> ChipData:
	var chip = ChipData.new()
	chip.chip_name = "Chip Breaker"
	chip.description = "Ataque que visa destruir chips inimigos."
	chip.chip_type = ChipData.ChipType.CHIP_DESTROYER
	chip.damage = 50  # Alto dano contra chips
	chip.chip_hp = 35
	chip.max_chip_hp = 35
	chip.element = ChipData.ElementType.NONE
	chip.attack_range = ChipData.AttackRange.RANGED
	chip.target_type = ChipData.TargetType.ENEMY_CHIP
	chip.rarity = "Rare"
	chip.chip_color = Color(0.7, 0.3, 0.7)
	return chip

#endregion

#region Factory Methods

## Get a chip by name
## @param chip_name: Name identifier (lowercase)
## @returns: ChipData or null if not found
static func get_chip(chip_name: String) -> ChipData:
	match chip_name.to_lower():
		# PROJECTILE
		"fireball":
			return create_fireball()
		"ice_shard":
			return create_ice_shard()
		"thunder_bolt":
			return create_thunder_bolt()
		"wind_cutter":
			return create_wind_cutter()

		# MELEE
		"sword_slash":
			return create_sword_slash()
		"flame_punch":
			return create_flame_punch()
		"thunder_fist":
			return create_thunder_fist()

		# AREA_DAMAGE
		"meteor_storm":
			return create_meteor_storm()
		"blizzard":
			return create_blizzard()

		# BUFF
		"power_up":
			return create_power_up()

		# SHIELD
		"barrier":
			return create_barrier()

		# TRANSFORM_AREA
		"lava_field":
			return create_lava_field()
		"ice_field":
			return create_ice_field()

		# CHIP_DESTROYER
		"chip_breaker":
			return create_chip_breaker()

		_:
			push_warning("[ChipDatabase] Unknown chip: %s" % chip_name)
			return null

## Get all available chip names
## @returns: Array of chip identifiers
static func get_all_chip_names() -> Array[String]:
	return [
		# PROJECTILE (4)
		"fireball",
		"ice_shard",
		"thunder_bolt",
		"wind_cutter",

		# MELEE (3)
		"sword_slash",
		"flame_punch",
		"thunder_fist",

		# AREA_DAMAGE (2)
		"meteor_storm",
		"blizzard",

		# BUFF (1)
		"power_up",

		# SHIELD (1)
		"barrier",

		# TRANSFORM_AREA (2)
		"lava_field",
		"ice_field",

		# CHIP_DESTROYER (1)
		"chip_breaker",
	]

## Get chips by type
## @param chip_type: ChipData.ChipType enum value
## @returns: Array of chip names
static func get_chips_by_type(chip_type: ChipData.ChipType) -> Array[String]:
	var chips: Array[String] = []

	for chip_name in get_all_chip_names():
		var chip = get_chip(chip_name)
		if chip and chip.chip_type == chip_type:
			chips.append(chip_name)

	return chips

## Get chips by element
## @param element: ChipData.ElementType enum value
## @returns: Array of chip names
static func get_chips_by_element(element: ChipData.ElementType) -> Array[String]:
	var chips: Array[String] = []

	for chip_name in get_all_chip_names():
		var chip = get_chip(chip_name)
		if chip and chip.element == element:
			chips.append(chip_name)

	return chips

## Get chips by rarity
## @param rarity: Rarity string (Common, Uncommon, Rare, Epic, Legendary)
## @returns: Array of chip names
static func get_chips_by_rarity(rarity: String) -> Array[String]:
	var chips: Array[String] = []

	for chip_name in get_all_chip_names():
		var chip = get_chip(chip_name)
		if chip and chip.rarity == rarity:
			chips.append(chip_name)

	return chips

## Get total number of chips
## @returns: Total chip count
static func get_chip_count() -> int:
	return get_all_chip_names().size()

#endregion
