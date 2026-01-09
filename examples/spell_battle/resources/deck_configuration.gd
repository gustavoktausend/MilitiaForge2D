## Deck Configuration Resource
##
## Defines the structure of a Program Deck for spell-battle.
## Manages the grid layout (2-3-4 column structure) and Slot-In chips.
##
## The deck follows the Battle Chip Challenge format:
## - 12 chips organized in 3 columns (2-3-4 chips per column)
## - 2 additional Slot-In backup chips
## - Each column represents a potential 3-chip selection pool
##
## @tutorial(Spell Battle): res://examples/spell_battle/README.md

class_name DeckConfiguration extends Resource

#region Column Structure
## Column 1: 2 chips (bottom row only)
@export var column_1: Array[String] = []

## Column 2: 3 chips (all rows)
@export var column_2: Array[String] = []

## Column 3: 4 chips (extended column)
@export var column_3: Array[String] = []

## Slot-In backup chips (2 chips)
@export var slot_in_chips: Array[String] = []
#endregion

#region Deck Metadata
## Deck name
@export var deck_name: String = "My Deck"

## Deck description
@export_multiline var description: String = "A custom deck configuration"

## Deck tags/categories
@export var tags: Array[String] = []
#endregion

#region Validation
## Maximum chips per column
const MAX_COLUMN_1_SIZE: int = 2
const MAX_COLUMN_2_SIZE: int = 3
const MAX_COLUMN_3_SIZE: int = 4
const MAX_SLOT_IN_SIZE: int = 2

## Total chips in main deck
const TOTAL_DECK_SIZE: int = 9  # 2 + 3 + 4

## Validate deck configuration
## @returns: Dictionary with "valid" bool and "errors" Array[String]
func validate() -> Dictionary:
	var errors: Array[String] = []

	# Check column sizes
	if column_1.size() != MAX_COLUMN_1_SIZE:
		errors.append("Column 1 must have exactly %d chips (has %d)" % [MAX_COLUMN_1_SIZE, column_1.size()])

	if column_2.size() != MAX_COLUMN_2_SIZE:
		errors.append("Column 2 must have exactly %d chips (has %d)" % [MAX_COLUMN_2_SIZE, column_2.size()])

	if column_3.size() != MAX_COLUMN_3_SIZE:
		errors.append("Column 3 must have exactly %d chips (has %d)" % [MAX_COLUMN_3_SIZE, column_3.size()])

	if slot_in_chips.size() != MAX_SLOT_IN_SIZE:
		errors.append("Slot-In must have exactly %d chips (has %d)" % [MAX_SLOT_IN_SIZE, slot_in_chips.size()])

	# Validate all chip names exist
	var all_chips = get_all_chip_names()
	for chip_name in all_chips:
		var chip = ChipDatabase.get_chip(chip_name)
		if chip == null:
			errors.append("Invalid chip name: %s" % chip_name)

	return {
		"valid": errors.is_empty(),
		"errors": errors
	}

## Check if deck is valid
## @returns: true if valid
func is_valid() -> bool:
	return validate()["valid"]
#endregion

#region Deck Access
## Get all chip names in the deck (including Slot-In)
## @returns: Array of chip names
func get_all_chip_names() -> Array[String]:
	var all_chips: Array[String] = []
	all_chips.append_array(column_1)
	all_chips.append_array(column_2)
	all_chips.append_array(column_3)
	all_chips.append_array(slot_in_chips)
	return all_chips

## Get main deck chip names (excluding Slot-In)
## @returns: Array of chip names
func get_main_deck_chip_names() -> Array[String]:
	var main_chips: Array[String] = []
	main_chips.append_array(column_1)
	main_chips.append_array(column_2)
	main_chips.append_array(column_3)
	return main_chips

## Get chip name at grid position
## @param column: Column index (0-2)
## @param row: Row index (0-3, varies per column)
## @returns: Chip name or empty string
func get_chip_at_grid(column: int, row: int) -> String:
	match column:
		0:
			if row >= 0 and row < column_1.size():
				return column_1[row]
		1:
			if row >= 0 and row < column_2.size():
				return column_2[row]
		2:
			if row >= 0 and row < column_3.size():
				return column_3[row]

	return ""

## Get column chips
## @param column: Column index (0-2)
## @returns: Array of chip names in column
func get_column(column: int) -> Array[String]:
	match column:
		0:
			return column_1.duplicate()
		1:
			return column_2.duplicate()
		2:
			return column_3.duplicate()
		_:
			return []

## Get total number of chips in deck
## @returns: Total chip count
func get_total_chip_count() -> int:
	return column_1.size() + column_2.size() + column_3.size() + slot_in_chips.size()

## Get main deck chip count
## @returns: Main deck size
func get_main_deck_count() -> int:
	return column_1.size() + column_2.size() + column_3.size()
#endregion

#region Deck Building
## Set column chips
## @param column: Column index (0-2)
## @param chip_names: Array of chip names
func set_column(column: int, chip_names: Array[String]) -> void:
	match column:
		0:
			column_1 = chip_names.duplicate()
		1:
			column_2 = chip_names.duplicate()
		2:
			column_3 = chip_names.duplicate()

## Set Slot-In chips
## @param chip_names: Array of chip names (must be 2)
func set_slot_in_chips(chip_names: Array[String]) -> void:
	slot_in_chips = chip_names.duplicate()

## Add chip to column
## @param column: Column index (0-2)
## @param chip_name: Chip name to add
## @returns: true if added successfully
func add_chip_to_column(column: int, chip_name: String) -> bool:
	match column:
		0:
			if column_1.size() >= MAX_COLUMN_1_SIZE:
				push_warning("[DeckConfiguration] Column 0 is full")
				return false
			column_1.append(chip_name)
			return true
		1:
			if column_2.size() >= MAX_COLUMN_2_SIZE:
				push_warning("[DeckConfiguration] Column 1 is full")
				return false
			column_2.append(chip_name)
			return true
		2:
			if column_3.size() >= MAX_COLUMN_3_SIZE:
				push_warning("[DeckConfiguration] Column 2 is full")
				return false
			column_3.append(chip_name)
			return true
		_:
			push_warning("[DeckConfiguration] Invalid column index: %d" % column)
			return false

## Remove chip from column
## @param column: Column index (0-2)
## @param row: Row index
## @returns: true if removed successfully
func remove_chip_from_column(column: int, row: int) -> bool:
	match column:
		0:
			if row < 0 or row >= column_1.size():
				return false
			column_1.remove_at(row)
			return true
		1:
			if row < 0 or row >= column_2.size():
				return false
			column_2.remove_at(row)
			return true
		2:
			if row < 0 or row >= column_3.size():
				return false
			column_3.remove_at(row)
			return true
		_:
			return false

## Clear all chips from deck
func clear_deck() -> void:
	column_1.clear()
	column_2.clear()
	column_3.clear()
	slot_in_chips.clear()
#endregion

#region Deck Statistics
## Get deck element distribution
## @returns: Dictionary of ElementType to count
func get_element_distribution() -> Dictionary:
	var distribution: Dictionary = {}

	for chip_name in get_all_chip_names():
		var chip = ChipDatabase.get_chip(chip_name)
		if chip:
			var element = ChipData.ElementType.keys()[chip.element]
			if not distribution.has(element):
				distribution[element] = 0
			distribution[element] += 1

	return distribution

## Get deck chip type distribution
## @returns: Dictionary of ChipType to count
func get_chip_type_distribution() -> Dictionary:
	var distribution: Dictionary = {}

	for chip_name in get_all_chip_names():
		var chip = ChipDatabase.get_chip(chip_name)
		if chip:
			var chip_type = ChipData.ChipType.keys()[chip.chip_type]
			if not distribution.has(chip_type):
				distribution[chip_type] = 0
			distribution[chip_type] += 1

	return distribution

## Get deck rarity distribution
## @returns: Dictionary of rarity to count
func get_rarity_distribution() -> Dictionary:
	var distribution: Dictionary = {}

	for chip_name in get_all_chip_names():
		var chip = ChipDatabase.get_chip(chip_name)
		if chip:
			if not distribution.has(chip.rarity):
				distribution[chip.rarity] = 0
			distribution[chip.rarity] += 1

	return distribution

## Get average deck damage
## @returns: Average damage value
func get_average_damage() -> float:
	var total_damage: float = 0.0
	var offensive_count: int = 0

	for chip_name in get_all_chip_names():
		var chip = ChipDatabase.get_chip(chip_name)
		if chip and chip.is_offensive():
			total_damage += chip.damage
			offensive_count += 1

	if offensive_count == 0:
		return 0.0

	return total_damage / offensive_count

## Get deck info summary
## @returns: Formatted string with deck statistics
func get_deck_info() -> String:
	var info = "[DECK] %s\n" % deck_name
	info += "%s\n\n" % description

	info += "Structure:\n"
	info += "  Column 1: %d chips\n" % column_1.size()
	info += "  Column 2: %d chips\n" % column_2.size()
	info += "  Column 3: %d chips\n" % column_3.size()
	info += "  Slot-In: %d chips\n\n" % slot_in_chips.size()

	info += "Elements:\n"
	var elements = get_element_distribution()
	for element in elements:
		info += "  %s: %d\n" % [element, elements[element]]

	info += "\nChip Types:\n"
	var types = get_chip_type_distribution()
	for chip_type in types:
		info += "  %s: %d\n" % [chip_type, types[chip_type]]

	info += "\nAverage Damage: %.1f\n" % get_average_damage()

	var validation = validate()
	info += "\nValid: %s" % ("YES" if validation["valid"] else "NO")
	if not validation["valid"]:
		info += "\nErrors:\n"
		for error in validation["errors"]:
			info += "  - %s\n" % error

	return info
#endregion
