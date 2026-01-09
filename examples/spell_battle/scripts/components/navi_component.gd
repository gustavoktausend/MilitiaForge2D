## Navi Component
##
## Game-specific component that represents a Navi (pilot/character) in battle.
## Manages Navi HP, default attacks, and Navi-specific behaviors.
##
## Features:
## - Navi HP management (separate from chip HP)
## - Default attack system (triggers after 3 chips)
## - Elemental resistance application
## - Death/defeat handling
## - Integration with NaviData
##
## @tutorial(Spell Battle): res://examples/spell_battle/README.md

class_name NaviComponent extends Component

#region Signals
## Emitted when Navi HP changes
signal navi_hp_changed(current_hp: int, max_hp: int)

## Emitted when Navi takes damage
signal navi_damaged(damage: int, source: Node)

## Emitted when Navi is healed
signal navi_healed(heal_amount: int)

## Emitted when Navi is defeated (HP reaches 0)
signal navi_defeated()

## Emitted when Navi performs default attack
signal default_attack_triggered(attack_data: Dictionary)

## Emitted when chip usage count changes
signal chip_count_changed(chips_used: int, max_before_default: int)
#endregion

#region Exports
@export_group("Navi Data")
## The Navi data resource
@export var navi_data: NaviData:
	set(value):
		navi_data = value
		if navi_data and not _is_initialized:
			_current_hp = navi_data.starting_hp

@export_group("Battle Settings")
## Number of chips before default attack
@export var chips_before_default_attack: int = 3

## Whether default attacks are enabled
@export var enable_default_attacks: bool = true

## Whether Navi can be defeated
@export var can_be_defeated: bool = true

@export_group("Visual")
## Visual representation (Sprite2D, AnimatedSprite2D, etc.)
@export var visual_node: Node2D

@export_group("Advanced")
## Whether to print debug messages
@export var debug_navi: bool = false
#endregion

#region Private Variables
## Current HP
var _current_hp: int = 0

## Number of chips used this turn
var _chips_used_this_turn: int = 0

## Whether Navi is defeated
var _is_defeated: bool = false

## Reference to ProgramDeckComponent (if attached)
var _program_deck: ProgramDeckComponent = null

## Reference to SlotInGaugeComponent (if attached)
var _slot_in_gauge: SlotInGaugeComponent = null
#endregion

#region Component Lifecycle
func _ready() -> void:
	# Initialize component if not using ComponentHost
	if not _is_initialized:
		# Only set host if parent is a ComponentHost
		var parent = get_parent()
		if parent is ComponentHost:
			host = parent
		_is_initialized = true
	component_ready()

func component_ready() -> void:
	if navi_data:
		_current_hp = navi_data.starting_hp

		# Apply navi color if visual node exists
		if visual_node and visual_node is CanvasItem:
			visual_node.modulate = navi_data.color_theme

		if debug_navi:
			print("[NaviComponent] Ready: %s (HP: %d/%d)" % [
				navi_data.navi_name, _current_hp, navi_data.max_hp
			])
	else:
		push_warning("[NaviComponent] No navi_data assigned!")

	# Find sibling components
	_find_sibling_components()

func cleanup() -> void:
	_is_defeated = true
	super.cleanup()
#endregion

#region Public Methods - HP Management
## Take damage
## @param damage: Amount of damage
## @param source: Source of damage (optional)
## @param element: Elemental type of damage (optional)
## @returns: Actual damage taken after resistances
func take_damage(damage: int, source: Node = null, element: ChipData.ElementType = ChipData.ElementType.NONE) -> int:
	if _is_defeated or not can_be_defeated:
		return 0

	# Apply elemental resistance
	var actual_damage = damage
	if navi_data and element != ChipData.ElementType.NONE:
		actual_damage = navi_data.get_modified_damage(damage, element)

	_current_hp -= actual_damage

	if _current_hp < 0:
		_current_hp = 0

	navi_hp_changed.emit(_current_hp, navi_data.max_hp if navi_data else 0)
	navi_damaged.emit(actual_damage, source)

	if debug_navi:
		var source_name = source.name if source else "Unknown"
		var element_name = ChipData.ElementType.keys()[element] if element != ChipData.ElementType.NONE else "NONE"
		print("[NaviComponent] %s took %d damage (%d base, %s element) from %s (HP: %d/%d)" % [
			navi_data.navi_name if navi_data else "Navi",
			actual_damage, damage, element_name, source_name,
			_current_hp, navi_data.max_hp if navi_data else 0
		])

	# Check defeat
	if _current_hp <= 0:
		_on_defeated()

	return actual_damage

## Heal Navi
## @param heal_amount: Amount to heal
func heal(heal_amount: int) -> void:
	if _is_defeated or not navi_data:
		return

	_current_hp += heal_amount

	if _current_hp > navi_data.max_hp:
		_current_hp = navi_data.max_hp

	navi_hp_changed.emit(_current_hp, navi_data.max_hp)
	navi_healed.emit(heal_amount)

	if debug_navi:
		print("[NaviComponent] %s healed %d HP (HP: %d/%d)" % [
			navi_data.navi_name, heal_amount, _current_hp, navi_data.max_hp
		])

## Set HP to specific value
## @param hp: New HP value
func set_hp(hp: int) -> void:
	if not navi_data:
		return

	_current_hp = clampi(hp, 0, navi_data.max_hp)
	navi_hp_changed.emit(_current_hp, navi_data.max_hp)

	if _current_hp <= 0 and not _is_defeated:
		_on_defeated()

## Restore to full HP
func restore_full_hp() -> void:
	if not navi_data:
		return

	_current_hp = navi_data.max_hp
	_is_defeated = false
	navi_hp_changed.emit(_current_hp, navi_data.max_hp)

	if debug_navi:
		print("[NaviComponent] %s fully restored (HP: %d)" % [navi_data.navi_name, _current_hp])

## Get current HP
## @returns: Current HP
func get_current_hp() -> int:
	return _current_hp

## Get max HP
## @returns: Max HP
func get_max_hp() -> int:
	if navi_data:
		return navi_data.max_hp
	return 0

## Get HP percentage
## @returns: HP percentage (0.0 to 1.0)
func get_hp_percentage() -> float:
	if not navi_data or navi_data.max_hp <= 0:
		return 0.0
	return float(_current_hp) / float(navi_data.max_hp)

## Check if defeated
## @returns: true if defeated
func is_defeated() -> bool:
	return _is_defeated
#endregion

#region Public Methods - Chip Usage & Default Attack
## Register chip usage (increments counter)
func register_chip_used() -> void:
	_chips_used_this_turn += 1
	chip_count_changed.emit(_chips_used_this_turn, chips_before_default_attack)

	# Increment Slot-In gauge if available
	if _slot_in_gauge:
		_slot_in_gauge.increment()

	if debug_navi:
		print("[NaviComponent] %s used chip %d/%d" % [
			navi_data.navi_name if navi_data else "Navi",
			_chips_used_this_turn, chips_before_default_attack
		])

	# Check if should trigger default attack
	if enable_default_attacks and _chips_used_this_turn >= chips_before_default_attack:
		trigger_default_attack()

## Trigger default attack
## @returns: Attack data dictionary
func trigger_default_attack() -> Dictionary:
	if not navi_data:
		return {}

	var attack_data = {
		"damage": navi_data.default_attack_damage,
		"attack_type": navi_data.default_attack_type,
		"element": navi_data.default_attack_element,
		"attack_range": navi_data.default_attack_range,
		"navi": host
	}

	default_attack_triggered.emit(attack_data)

	# Reset chip counter
	_chips_used_this_turn = 0
	chip_count_changed.emit(_chips_used_this_turn, chips_before_default_attack)

	if debug_navi:
		print("[NaviComponent] %s triggered DEFAULT ATTACK! (Damage: %d, Element: %s)" % [
			navi_data.navi_name,
			attack_data["damage"],
			ChipData.ElementType.keys()[attack_data["element"]]
		])

	return attack_data

## Reset chip usage counter
func reset_chip_counter() -> void:
	_chips_used_this_turn = 0
	chip_count_changed.emit(_chips_used_this_turn, chips_before_default_attack)

## Get current chip usage count
## @returns: Number of chips used
func get_chips_used() -> int:
	return _chips_used_this_turn

## Check if ready for default attack
## @returns: true if at threshold
func is_ready_for_default_attack() -> bool:
	return _chips_used_this_turn >= chips_before_default_attack
#endregion

#region Public Methods - Queries
## Get Navi data
## @returns: NaviData resource
func get_navi_data() -> NaviData:
	return navi_data

## Get Navi name
## @returns: Navi name string
func get_navi_name() -> String:
	if navi_data:
		return navi_data.navi_name
	return "Unknown Navi"

## Get Navi element
## @returns: ElementType enum
func get_element() -> ChipData.ElementType:
	if navi_data:
		return navi_data.element
	return ChipData.ElementType.NONE

## Get elemental resistance
## @param element: Element to check
## @returns: Resistance multiplier
func get_element_resistance(element: ChipData.ElementType) -> float:
	if navi_data:
		return navi_data.get_element_resistance(element)
	return 1.0

## Check if Navi has special ability
## @param ability_name: Ability name to check
## @returns: true if has ability
func has_special_ability(ability_name: String) -> bool:
	if navi_data:
		return ability_name in navi_data.special_abilities
	return false

## Get Program Deck component
## @returns: ProgramDeckComponent or null
func get_program_deck() -> ProgramDeckComponent:
	return _program_deck

## Get Slot-In Gauge component
## @returns: SlotInGaugeComponent or null
func get_slot_in_gauge() -> SlotInGaugeComponent:
	return _slot_in_gauge
#endregion

#region Private Methods
## Find sibling components
func _find_sibling_components() -> void:
	if not host:
		return

	# Look for ProgramDeckComponent
	for child in host.get_children():
		if child is ProgramDeckComponent:
			_program_deck = child
			if debug_navi:
				print("[NaviComponent] Found ProgramDeckComponent")

		if child is SlotInGaugeComponent:
			_slot_in_gauge = child
			if debug_navi:
				print("[NaviComponent] Found SlotInGaugeComponent")

## Handle defeat
func _on_defeated() -> void:
	if _is_defeated:
		return

	_is_defeated = true
	navi_defeated.emit()

	if debug_navi:
		print("[NaviComponent] %s DEFEATED!" % (navi_data.navi_name if navi_data else "Navi"))
#endregion

#region Debug Methods
## Print Navi state
func debug_print_state() -> void:
	if not navi_data:
		print("=== Navi Component (NO DATA) ===")
		return

	print("=== Navi Component State ===")
	print("Name: %s" % navi_data.navi_name)
	print("Element: %s" % ChipData.ElementType.keys()[navi_data.element])
	print("HP: %d / %d (%.1f%%)" % [_current_hp, navi_data.max_hp, get_hp_percentage() * 100])
	print("Defeated: %s" % _is_defeated)
	print("Chips Used: %d / %d" % [_chips_used_this_turn, chips_before_default_attack])
	print("Ready for Default Attack: %s" % is_ready_for_default_attack())
	print("Has Program Deck: %s" % (_program_deck != null))
	print("Has Slot-In Gauge: %s" % (_slot_in_gauge != null))
	print("==========================")
#endregion
