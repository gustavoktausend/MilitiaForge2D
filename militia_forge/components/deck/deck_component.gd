## Deck Component
##
## Generic component for managing card/chip deck systems.
## Provides functionality for deck, hand, draw pile, and discard pile management.
##
## Features:
## - Draw, shuffle, and discard mechanics
## - Hand management with size limits
## - Deck depletion handling
## - Deck manipulation (add, remove, search)
## - Auto-shuffle when draw pile empty
## - Signal-based communication
##
## @tutorial(Deck System): res://docs/components/deck_component.md

class_name DeckComponent extends Component

#region Signals
## Emitted when a card is drawn from the deck
signal card_drawn(card: Variant)

## Emitted when a card is added to hand
signal card_added_to_hand(card: Variant)

## Emitted when a card is removed from hand
signal card_removed_from_hand(card: Variant)

## Emitted when a card is discarded
signal card_discarded(card: Variant)

## Emitted when the deck is shuffled
signal deck_shuffled()

## Emitted when the draw pile is empty
signal draw_pile_empty()

## Emitted when hand is full
signal hand_full()

## Emitted when deck is depleted (no cards in draw pile or discard pile)
signal deck_depleted()
#endregion

#region Exports
@export_group("Deck Settings")
## Maximum hand size (-1 = unlimited)
@export var max_hand_size: int = 7

## Whether to auto-shuffle discard pile when draw pile is empty
@export var auto_shuffle_on_empty: bool = true

## Whether to start with a full hand
@export var start_with_full_hand: bool = true

## Initial number of cards to draw at start
@export var starting_hand_size: int = 5

@export_group("Advanced")
## Whether to print debug messages
@export var debug_deck: bool = false
#endregion

#region Private Variables
## Cards currently in hand
var _hand: Array = []

## Cards in draw pile (deck)
var _draw_pile: Array = []

## Cards in discard pile
var _discard_pile: Array = []

## All cards that were in the original deck (for reference)
var _original_deck: Array = []
#endregion

#region Component Lifecycle
func component_ready() -> void:
	if start_with_full_hand:
		draw_cards(starting_hand_size)

	if debug_deck:
		print("[DeckComponent] Ready. Hand: %d, Draw: %d, Discard: %d" % [
			_hand.size(), _draw_pile.size(), _discard_pile.size()
		])

func cleanup() -> void:
	_hand.clear()
	_draw_pile.clear()
	_discard_pile.clear()
	_original_deck.clear()
	super.cleanup()
#endregion

#region Public Methods - Deck Setup
## Initialize the deck with cards
## @param cards: Array of cards/chips to use
func initialize_deck(cards: Array) -> void:
	_original_deck = cards.duplicate()
	_draw_pile = cards.duplicate()
	_discard_pile.clear()
	_hand.clear()

	# Shuffle on init
	shuffle_deck()

	if debug_deck:
		print("[DeckComponent] Deck initialized with %d cards" % _draw_pile.size())

## Reset deck to original state
func reset_deck() -> void:
	_draw_pile = _original_deck.duplicate()
	_discard_pile.clear()
	_hand.clear()
	shuffle_deck()

	if debug_deck:
		print("[DeckComponent] Deck reset to original state")
#endregion

#region Public Methods - Draw/Discard
## Draw a single card from the deck
## @returns: The drawn card, or null if unable to draw
func draw_card() -> Variant:
	# Check if draw pile is empty
	if _draw_pile.is_empty():
		if auto_shuffle_on_empty and not _discard_pile.is_empty():
			_shuffle_discard_into_draw()
		else:
			draw_pile_empty.emit()

			if _discard_pile.is_empty():
				deck_depleted.emit()
				if debug_deck:
					print("[DeckComponent] Deck depleted!")
			return null

	# Check hand size limit
	if max_hand_size > 0 and _hand.size() >= max_hand_size:
		hand_full.emit()
		if debug_deck:
			print("[DeckComponent] Hand is full (%d/%d)" % [_hand.size(), max_hand_size])
		return null

	# Draw card
	var card = _draw_pile.pop_front()
	_hand.append(card)

	card_drawn.emit(card)
	card_added_to_hand.emit(card)

	if debug_deck:
		print("[DeckComponent] Drew card. Hand: %d, Draw: %d" % [_hand.size(), _draw_pile.size()])

	return card

## Draw multiple cards
## @param count: Number of cards to draw
## @returns: Array of drawn cards
func draw_cards(count: int) -> Array:
	var drawn: Array = []

	for i in count:
		var card = draw_card()
		if card != null:
			drawn.append(card)
		else:
			break  # Stop if unable to draw

	return drawn

## Discard a card from hand
## @param card: Card to discard
## @returns: true if card was discarded
func discard_card(card: Variant) -> bool:
	var index = _hand.find(card)
	if index == -1:
		push_warning("[DeckComponent] Card not in hand, cannot discard")
		return false

	_hand.remove_at(index)
	_discard_pile.append(card)

	card_removed_from_hand.emit(card)
	card_discarded.emit(card)

	if debug_deck:
		print("[DeckComponent] Discarded card. Hand: %d, Discard: %d" % [
			_hand.size(), _discard_pile.size()
		])

	return true

## Discard a card from hand by index
## @param index: Index in hand
## @returns: true if card was discarded
func discard_card_at(index: int) -> bool:
	if index < 0 or index >= _hand.size():
		push_warning("[DeckComponent] Invalid hand index: %d" % index)
		return false

	var card = _hand[index]
	return discard_card(card)

## Discard entire hand
func discard_hand() -> void:
	while not _hand.is_empty():
		var card = _hand.pop_front()
		_discard_pile.append(card)
		card_removed_from_hand.emit(card)
		card_discarded.emit(card)

	if debug_deck:
		print("[DeckComponent] Discarded entire hand. Discard: %d" % _discard_pile.size())

## Play a card from hand (removes from hand but doesn't discard)
## @param card: Card to play
## @returns: true if card was played
func play_card(card: Variant) -> bool:
	var index = _hand.find(card)
	if index == -1:
		push_warning("[DeckComponent] Card not in hand, cannot play")
		return false

	_hand.remove_at(index)
	card_removed_from_hand.emit(card)

	if debug_deck:
		print("[DeckComponent] Played card. Hand: %d" % _hand.size())

	return true

## Play a card by index
## @param index: Index in hand
## @returns: The played card, or null
func play_card_at(index: int) -> Variant:
	if index < 0 or index >= _hand.size():
		push_warning("[DeckComponent] Invalid hand index: %d" % index)
		return null

	var card = _hand[index]
	if play_card(card):
		return card
	return null
#endregion

#region Public Methods - Shuffle
## Shuffle the draw pile
func shuffle_deck() -> void:
	_draw_pile.shuffle()
	deck_shuffled.emit()

	if debug_deck:
		print("[DeckComponent] Shuffled draw pile (%d cards)" % _draw_pile.size())

## Shuffle discard pile back into draw pile
func shuffle_discard_into_draw() -> void:
	_shuffle_discard_into_draw()
#endregion

#region Public Methods - Deck Manipulation
## Add a card to the draw pile
## @param card: Card to add
## @param position: Where to add ("top", "bottom", "random")
func add_card_to_draw_pile(card: Variant, position: String = "bottom") -> void:
	match position:
		"top":
			_draw_pile.push_front(card)
		"bottom":
			_draw_pile.push_back(card)
		"random":
			var index = randi() % (_draw_pile.size() + 1)
			_draw_pile.insert(index, card)
		_:
			_draw_pile.push_back(card)

	if debug_deck:
		print("[DeckComponent] Added card to draw pile (%s). Total: %d" % [position, _draw_pile.size()])

## Add a card directly to hand
## @param card: Card to add
## @returns: true if added successfully
func add_card_to_hand(card: Variant) -> bool:
	# Check hand size limit
	if max_hand_size > 0 and _hand.size() >= max_hand_size:
		hand_full.emit()
		if debug_deck:
			print("[DeckComponent] Cannot add to hand - full")
		return false

	_hand.append(card)
	card_added_to_hand.emit(card)

	if debug_deck:
		print("[DeckComponent] Added card to hand. Total: %d" % _hand.size())

	return true

## Remove a specific card from draw pile
## @param card: Card to remove
## @returns: true if card was found and removed
func remove_card_from_draw_pile(card: Variant) -> bool:
	var index = _draw_pile.find(card)
	if index == -1:
		return false

	_draw_pile.remove_at(index)

	if debug_deck:
		print("[DeckComponent] Removed card from draw pile")

	return true

## Search for cards in draw pile
## @param predicate: Callable that returns true for matching cards
## @returns: Array of matching cards
func search_draw_pile(predicate: Callable) -> Array:
	var results: Array = []
	for card in _draw_pile:
		if predicate.call(card):
			results.append(card)
	return results

## Search for cards in hand
## @param predicate: Callable that returns true for matching cards
## @returns: Array of matching cards
func search_hand(predicate: Callable) -> Array:
	var results: Array = []
	for card in _hand:
		if predicate.call(card):
			results.append(card)
	return results
#endregion

#region Public Methods - Queries
## Get current hand
## @returns: Array of cards in hand
func get_hand() -> Array:
	return _hand.duplicate()

## Get card from hand by index
## @param index: Hand index
## @returns: Card or null
func get_card_at(index: int) -> Variant:
	if index < 0 or index >= _hand.size():
		return null
	return _hand[index]

## Get number of cards in hand
## @returns: Hand size
func get_hand_size() -> int:
	return _hand.size()

## Get number of cards in draw pile
## @returns: Draw pile size
func get_draw_pile_size() -> int:
	return _draw_pile.size()

## Get number of cards in discard pile
## @returns: Discard pile size
func get_discard_pile_size() -> int:
	return _discard_pile.size()

## Get total number of cards (hand + draw + discard)
## @returns: Total cards
func get_total_cards() -> int:
	return _hand.size() + _draw_pile.size() + _discard_pile.size()

## Check if hand is full
## @returns: true if at max hand size
func is_hand_full() -> bool:
	return max_hand_size > 0 and _hand.size() >= max_hand_size

## Check if hand is empty
## @returns: true if no cards in hand
func is_hand_empty() -> bool:
	return _hand.is_empty()

## Check if draw pile is empty
## @returns: true if no cards in draw pile
func is_draw_pile_empty() -> bool:
	return _draw_pile.is_empty()

## Check if deck is completely depleted
## @returns: true if no cards anywhere
func is_deck_depleted() -> bool:
	return _hand.is_empty() and _draw_pile.is_empty() and _discard_pile.is_empty()
#endregion

#region Private Methods
## Internal method to shuffle discard into draw
func _shuffle_discard_into_draw() -> void:
	_draw_pile.append_array(_discard_pile)
	_discard_pile.clear()
	shuffle_deck()

	if debug_deck:
		print("[DeckComponent] Shuffled discard into draw. Draw pile: %d" % _draw_pile.size())
#endregion

#region Debug Methods
## Print deck state
func debug_print_state() -> void:
	print("=== Deck Component State ===")
	print("Hand: %d / %d" % [_hand.size(), max_hand_size if max_hand_size > 0 else INF])
	print("Draw Pile: %d" % _draw_pile.size())
	print("Discard Pile: %d" % _discard_pile.size())
	print("Total Cards: %d" % get_total_cards())
	print("Is Depleted: %s" % is_deck_depleted())
	print("==========================")
#endregion
