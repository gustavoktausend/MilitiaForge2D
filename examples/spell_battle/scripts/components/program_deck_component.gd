## Program Deck Component
##
## Game-specific component that manages the Program Deck for spell-battle.
## Extends the generic DeckComponent with spell-battle specific logic.
##
## Features:
## - Grid-based deck structure (2-3-4 columns)
## - Slot-In chip management
## - Column selection for drawing
## - Chip selection from 3 random chips
## - Turn-based draw mechanics
##
## @tutorial(Spell Battle): res://examples/spell_battle/README.md

class_name ProgramDeckComponent extends Component

#region Signals
## Emitted when chips are offered for selection
signal chips_offered(available_chips: Array)

## Emitted when a chip is selected by player
signal chip_selected(chip_data: ChipData)

## Emitted when all chips are used (deck depleted)
signal deck_depleted()

## Emitted when Slot-In chip is activated
signal slot_in_activated(chip_data: ChipData)

## Emitted when deck is refreshed
signal deck_refreshed()
#endregion

#region Exports
@export_group("Deck Configuration")
## The deck configuration resource
@export var deck_config: DeckConfiguration

@export_group("Draw Settings")
## Number of chips to offer per turn
@export var chips_per_turn: int = 3

## Whether to allow chip selection (false = auto-use first chip)
@export var allow_chip_selection: bool = true

## Time limit for chip selection (0 = no limit)
@export var selection_time_limit: float = 10.0

@export_group("Slot-In Settings")
## Whether Slot-In is available
@export var slot_in_enabled: bool = true

## Current Slot-In gauge index (0 or 1)
@export var current_slot_in_index: int = 0

@export_group("Advanced")
## Whether to print debug messages
@export var debug_deck: bool = false
#endregion

#region Private Variables
## Internal generic DeckComponent for deck management
var _deck_component: DeckComponent

## Current chips offered for selection
var _offered_chips: Array = []

## Current selection timer
var _selection_timer: float = 0.0

## Whether waiting for chip selection
var _waiting_for_selection: bool = false

## Chips used this turn
var _chips_used_this_turn: int = 0
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
	# Create internal DeckComponent
	_deck_component = DeckComponent.new()
	_deck_component.max_hand_size = -1  # Unlimited hand
	_deck_component.auto_shuffle_on_empty = true
	_deck_component.start_with_full_hand = false
	_deck_component.debug_deck = debug_deck

	add_child(_deck_component)
	# DeckComponent's _ready() will be called automatically after add_child()

	# Initialize deck from configuration
	if deck_config:
		_initialize_from_config()
	else:
		push_warning("[ProgramDeckComponent] No deck_config assigned!")

	# Connect signals
	_deck_component.deck_depleted.connect(_on_deck_depleted)

	if debug_deck:
		print("[ProgramDeckComponent] Ready. Chips in deck: %d" % _deck_component.get_draw_pile_size())

func component_process(delta: float) -> void:
	if _waiting_for_selection and selection_time_limit > 0.0:
		_selection_timer -= delta

		if _selection_timer <= 0.0:
			# Auto-select first chip on timeout
			if not _offered_chips.is_empty():
				select_chip(0)

func cleanup() -> void:
	if _deck_component:
		_deck_component.queue_free()
	super.cleanup()
#endregion

#region Public Methods - Deck Initialization
## Initialize deck from DeckConfiguration
func _initialize_from_config() -> void:
	if not deck_config:
		return

	# Validate deck
	var validation = deck_config.validate()
	if not validation["valid"]:
		push_error("[ProgramDeckComponent] Invalid deck configuration:")
		for error in validation["errors"]:
			push_error("  - %s" % error)
		return

	# Get all main deck chips (excluding Slot-In)
	var chip_names = deck_config.get_main_deck_chip_names()
	var chips: Array = []

	for chip_name in chip_names:
		var chip_data = ChipDatabase.get_chip(chip_name)
		if chip_data:
			chips.append(chip_data)

	# Initialize deck
	_deck_component.initialize_deck(chips)

	if debug_deck:
		print("[ProgramDeckComponent] Initialized deck: %s" % deck_config.deck_name)
		print("  Main deck: %d chips" % chips.size())
		print("  Slot-In: %d chips" % deck_config.slot_in_chips.size())

## Reload deck configuration
## @param new_config: New DeckConfiguration
func reload_deck(new_config: DeckConfiguration) -> void:
	deck_config = new_config
	_initialize_from_config()
	deck_refreshed.emit()

	if debug_deck:
		print("[ProgramDeckComponent] Deck reloaded: %s" % deck_config.deck_name)
#endregion

#region Public Methods - Turn Management
## Offer chips for selection at turn start
## @returns: Array of offered ChipData
func offer_chips_for_turn() -> Array:
	_chips_used_this_turn = 0

	# Draw chips
	var drawn = _deck_component.draw_cards(chips_per_turn)

	_offered_chips = drawn.duplicate()
	_waiting_for_selection = allow_chip_selection
	_selection_timer = selection_time_limit

	chips_offered.emit(_offered_chips)

	if debug_deck:
		print("[ProgramDeckComponent] Offered %d chips for selection" % _offered_chips.size())
		for i in _offered_chips.size():
			var chip: ChipData = _offered_chips[i]
			print("  [%d] %s" % [i, chip.chip_name])

	return _offered_chips.duplicate()

## Select a chip from offered chips
## @param index: Index in offered chips array
## @returns: Selected ChipData or null
func select_chip(index: int) -> ChipData:
	if not _waiting_for_selection:
		push_warning("[ProgramDeckComponent] Not waiting for chip selection")
		return null

	if index < 0 or index >= _offered_chips.size():
		push_warning("[ProgramDeckComponent] Invalid chip index: %d" % index)
		return null

	var selected_chip: ChipData = _offered_chips[index]

	# Remove selected chip from offered chips
	_offered_chips.remove_at(index)

	# Return non-selected chips to hand
	for chip in _offered_chips:
		_deck_component.add_card_to_hand(chip)

	_offered_chips.clear()
	_waiting_for_selection = false

	chip_selected.emit(selected_chip)

	if debug_deck:
		print("[ProgramDeckComponent] Selected chip: %s" % selected_chip.chip_name)

	return selected_chip

## Get currently offered chips
## @returns: Array of offered ChipData
func get_offered_chips() -> Array:
	return _offered_chips.duplicate()

## Check if waiting for chip selection
## @returns: true if waiting
func is_waiting_for_selection() -> bool:
	return _waiting_for_selection

## Get remaining selection time
## @returns: Seconds remaining
func get_selection_time_remaining() -> float:
	return maxf(_selection_timer, 0.0)
#endregion

#region Public Methods - Slot-In System
## Activate Slot-In chip
## @returns: ChipData of activated Slot-In chip, or null if unavailable
func activate_slot_in() -> ChipData:
	if not slot_in_enabled:
		if debug_deck:
			print("[ProgramDeckComponent] Slot-In not enabled")
		return null

	if not deck_config or deck_config.slot_in_chips.is_empty():
		if debug_deck:
			print("[ProgramDeckComponent] No Slot-In chips available")
		return null

	# Get current Slot-In chip
	var slot_in_chip_name = deck_config.slot_in_chips[current_slot_in_index]
	var slot_in_chip = ChipDatabase.get_chip(slot_in_chip_name)

	if not slot_in_chip:
		push_warning("[ProgramDeckComponent] Invalid Slot-In chip: %s" % slot_in_chip_name)
		return null

	slot_in_activated.emit(slot_in_chip)

	# Cycle to next Slot-In chip
	current_slot_in_index = (current_slot_in_index + 1) % deck_config.slot_in_chips.size()

	if debug_deck:
		print("[ProgramDeckComponent] Activated Slot-In: %s" % slot_in_chip.chip_name)

	return slot_in_chip

## Get current Slot-In chip without activating
## @returns: ChipData of current Slot-In chip
func peek_slot_in() -> ChipData:
	if not deck_config or deck_config.slot_in_chips.is_empty():
		return null

	var slot_in_chip_name = deck_config.slot_in_chips[current_slot_in_index]
	return ChipDatabase.get_chip(slot_in_chip_name)

## Check if Slot-In is available
## @returns: true if Slot-In can be activated
func is_slot_in_available() -> bool:
	return slot_in_enabled and deck_config != null and not deck_config.slot_in_chips.is_empty()
#endregion

#region Public Methods - Deck Queries
## Get number of chips remaining in draw pile
## @returns: Draw pile size
func get_remaining_chips() -> int:
	return _deck_component.get_draw_pile_size()

## Get number of chips in discard pile
## @returns: Discard pile size
func get_discarded_chips() -> int:
	return _deck_component.get_discard_pile_size()

## Get total chips in deck
## @returns: Total chip count
func get_total_chips() -> int:
	return _deck_component.get_total_cards()

## Check if deck is depleted
## @returns: true if no chips available
func is_deck_depleted() -> bool:
	return _deck_component.is_deck_depleted()

## Get deck configuration
## @returns: DeckConfiguration resource
func get_deck_config() -> DeckConfiguration:
	return deck_config

## Get chips used this turn
## @returns: Number of chips used
func get_chips_used_this_turn() -> int:
	return _chips_used_this_turn

## Increment chips used counter
func increment_chips_used() -> void:
	_chips_used_this_turn += 1

## Reset turn counters
func reset_turn_counters() -> void:
	_chips_used_this_turn = 0
#endregion

#region Private Methods
## Handle deck depletion
func _on_deck_depleted() -> void:
	deck_depleted.emit()

	if debug_deck:
		print("[ProgramDeckComponent] Deck depleted!")
#endregion

#region Debug Methods
## Print deck state
func debug_print_state() -> void:
	print("=== Program Deck State ===")

	if deck_config:
		print("Deck Name: %s" % deck_config.deck_name)

	print("Draw Pile: %d" % get_remaining_chips())
	print("Discard Pile: %d" % get_discarded_chips())
	print("Offered Chips: %d" % _offered_chips.size())
	print("Waiting for Selection: %s" % _waiting_for_selection)
	print("Chips Used This Turn: %d" % _chips_used_this_turn)

	if is_slot_in_available():
		var slot_in = peek_slot_in()
		if slot_in:
			print("Current Slot-In: %s" % slot_in.chip_name)

	print("========================")
#endregion
