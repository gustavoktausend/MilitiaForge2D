## Turn System Component
##
## Generic component for managing turn-based game logic.
## Handles turn order, turn timers, and turn transitions.
##
## Features:
## - Turn counter and turn limit
## - Turn order management (sequential or custom)
## - Turn timer (optional)
## - Automatic turn progression
## - Turn history tracking
## - Signal-based communication
##
## @tutorial(Turn System): res://docs/components/turn_system_component.md

class_name TurnSystemComponent extends Component

#region Signals
## Emitted when a turn starts
signal turn_started(turn_number: int, current_entity: Node)

## Emitted when a turn ends
signal turn_ended(turn_number: int, current_entity: Node)

## Emitted when all turns are complete (turn limit reached)
signal turns_completed(final_turn: int)

## Emitted when turn order changes
signal turn_order_changed(new_order: Array)

## Emitted when turn timer ticks
signal turn_timer_tick(remaining_time: float)
#endregion

#region Exports
@export_group("Turn Settings")
## Maximum number of turns (-1 = infinite)
@export var max_turns: int = 10

## Current turn number (starts at 1)
@export var current_turn: int = 0

## Whether to start automatically on ready
@export var auto_start: bool = false

@export_group("Turn Timer")
## Whether to use a turn timer
@export var use_turn_timer: bool = false

## Time limit per turn in seconds (0 = no limit)
@export var turn_time_limit: float = 30.0

## Whether to auto-advance when timer expires
@export var auto_advance_on_timeout: bool = true

@export_group("Turn Order")
## Whether to track turn history
@export var track_history: bool = true

## Maximum history size
@export var max_history_size: int = 50

@export_group("Advanced")
## Whether to print debug messages
@export var debug_turns: bool = false
#endregion

#region Private Variables
## Entities participating in turns
var _turn_entities: Array[Node] = []

## Current entity index in turn order
var _current_entity_index: int = 0

## Current turn timer
var _turn_timer: float = 0.0

## Turn history (array of turn numbers)
var _turn_history: Array[int] = []

## Whether the turn system is active
var _is_active: bool = false

## Whether a turn is currently in progress
var _is_turn_in_progress: bool = false
#endregion

#region Component Lifecycle
func component_ready() -> void:
	if auto_start:
		start_turn_system()

	if debug_turns:
		print("[TurnSystemComponent] Ready. Max turns: %d" % max_turns)

func component_process(delta: float) -> void:
	if not _is_active or not _is_turn_in_progress:
		return

	# Update turn timer
	if use_turn_timer and turn_time_limit > 0.0:
		_turn_timer -= delta

		# Emit tick signal every second
		if int(_turn_timer) != int(_turn_timer + delta):
			turn_timer_tick.emit(_turn_timer)

		# Check timeout
		if _turn_timer <= 0.0:
			if debug_turns:
				print("[TurnSystemComponent] Turn %d timed out!" % current_turn)

			if auto_advance_on_timeout:
				end_turn()

func cleanup() -> void:
	stop_turn_system()
	super.cleanup()
#endregion

#region Public Methods - System Control
## Start the turn system
func start_turn_system() -> void:
	if _is_active:
		push_warning("[TurnSystemComponent] Turn system already active")
		return

	_is_active = true
	current_turn = 0
	_current_entity_index = 0
	_turn_history.clear()

	if debug_turns:
		print("[TurnSystemComponent] Turn system started")

	# Start first turn
	next_turn()

## Stop the turn system
func stop_turn_system() -> void:
	if not _is_active:
		return

	_is_active = false
	_is_turn_in_progress = false

	if debug_turns:
		print("[TurnSystemComponent] Turn system stopped at turn %d" % current_turn)

## Pause the turn system
func pause_turn_system() -> void:
	_is_active = false

	if debug_turns:
		print("[TurnSystemComponent] Turn system paused")

## Resume the turn system
func resume_turn_system() -> void:
	_is_active = true

	if debug_turns:
		print("[TurnSystemComponent] Turn system resumed")
#endregion

#region Public Methods - Turn Management
## Advance to the next turn
func next_turn() -> void:
	if not _is_active:
		push_warning("[TurnSystemComponent] Cannot advance turn - system not active")
		return

	# Check turn limit
	if max_turns > 0 and current_turn >= max_turns:
		_complete_all_turns()
		return

	# Increment turn
	current_turn += 1

	# Add to history
	if track_history:
		_add_to_history(current_turn)

	# Reset turn timer
	if use_turn_timer:
		_turn_timer = turn_time_limit

	# Get current entity
	var current_entity = get_current_entity()

	_is_turn_in_progress = true
	turn_started.emit(current_turn, current_entity)

	if debug_turns:
		var entity_name = current_entity.name if current_entity else "None"
		print("[TurnSystemComponent] Turn %d started (Entity: %s)" % [current_turn, entity_name])

## End the current turn
func end_turn() -> void:
	if not _is_turn_in_progress:
		push_warning("[TurnSystemComponent] No turn in progress to end")
		return

	var current_entity = get_current_entity()
	turn_ended.emit(current_turn, current_entity)

	_is_turn_in_progress = false

	# Advance entity index
	_current_entity_index += 1
	if _current_entity_index >= _turn_entities.size():
		_current_entity_index = 0

	if debug_turns:
		var entity_name = current_entity.name if current_entity else "None"
		print("[TurnSystemComponent] Turn %d ended (Entity: %s)" % [current_turn, entity_name])

	# Automatically start next turn
	call_deferred("next_turn")

## Skip to a specific turn
## @param turn_number: Turn to skip to
func skip_to_turn(turn_number: int) -> void:
	if turn_number < 1:
		push_warning("[TurnSystemComponent] Invalid turn number: %d" % turn_number)
		return

	if _is_turn_in_progress:
		end_turn()

	current_turn = turn_number - 1
	next_turn()

	if debug_turns:
		print("[TurnSystemComponent] Skipped to turn %d" % turn_number)
#endregion

#region Public Methods - Entity Management
## Set the entities that will take turns
## @param entities: Array of Node entities
func set_turn_entities(entities: Array[Node]) -> void:
	_turn_entities = entities.duplicate()
	_current_entity_index = 0
	turn_order_changed.emit(_turn_entities)

	if debug_turns:
		print("[TurnSystemComponent] Turn order set: %d entities" % _turn_entities.size())

## Add an entity to turn order
## @param entity: Entity to add
func add_entity(entity: Node) -> void:
	if entity in _turn_entities:
		push_warning("[TurnSystemComponent] Entity already in turn order: %s" % entity.name)
		return

	_turn_entities.append(entity)
	turn_order_changed.emit(_turn_entities)

	if debug_turns:
		print("[TurnSystemComponent] Added entity: %s" % entity.name)

## Remove an entity from turn order
## @param entity: Entity to remove
func remove_entity(entity: Node) -> void:
	var index = _turn_entities.find(entity)
	if index == -1:
		push_warning("[TurnSystemComponent] Entity not in turn order: %s" % entity.name)
		return

	_turn_entities.erase(entity)

	# Adjust current index if needed
	if _current_entity_index >= _turn_entities.size():
		_current_entity_index = 0

	turn_order_changed.emit(_turn_entities)

	if debug_turns:
		print("[TurnSystemComponent] Removed entity: %s" % entity.name)

## Get the current entity whose turn it is
## @returns: Current entity or null
func get_current_entity() -> Node:
	if _turn_entities.is_empty() or _current_entity_index >= _turn_entities.size():
		return null

	return _turn_entities[_current_entity_index]

## Get all entities in turn order
## @returns: Array of entities
func get_all_entities() -> Array[Node]:
	return _turn_entities.duplicate()
#endregion

#region Public Methods - Queries
## Check if turn system is active
## @returns: true if active
func is_active() -> bool:
	return _is_active

## Check if a turn is in progress
## @returns: true if turn in progress
func is_turn_in_progress() -> bool:
	return _is_turn_in_progress

## Check if turn limit has been reached
## @returns: true if at or past limit
func is_at_turn_limit() -> bool:
	return max_turns > 0 and current_turn >= max_turns

## Get remaining turns
## @returns: Number of remaining turns (-1 if infinite)
func get_remaining_turns() -> int:
	if max_turns <= 0:
		return -1
	return max_turns - current_turn

## Get turn history
## @returns: Array of turn numbers
func get_turn_history() -> Array[int]:
	return _turn_history.duplicate()

## Get remaining time for current turn
## @returns: Remaining seconds (0 if no timer)
func get_remaining_time() -> float:
	if not use_turn_timer:
		return 0.0
	return maxf(_turn_timer, 0.0)

## Get turn progress percentage
## @returns: Progress from 0.0 to 1.0 (-1 if infinite)
func get_turn_progress() -> float:
	if max_turns <= 0:
		return -1.0
	return float(current_turn) / float(max_turns)
#endregion

#region Private Methods
## Complete all turns (reached limit)
func _complete_all_turns() -> void:
	_is_active = false
	_is_turn_in_progress = false
	turns_completed.emit(current_turn)

	if debug_turns:
		print("[TurnSystemComponent] All turns completed! Final turn: %d" % current_turn)

## Add turn to history
func _add_to_history(turn: int) -> void:
	_turn_history.append(turn)

	# Limit history size
	if _turn_history.size() > max_history_size:
		_turn_history.pop_front()
#endregion

#region Debug Methods
## Print current state
func debug_print_state() -> void:
	print("=== Turn System State ===")
	print("Active: %s" % _is_active)
	print("Current Turn: %d / %d" % [current_turn, max_turns if max_turns > 0 else INF])
	print("Turn in Progress: %s" % _is_turn_in_progress)

	var current_entity = get_current_entity()
	if current_entity:
		print("Current Entity: %s" % current_entity.name)

	if use_turn_timer:
		print("Time Remaining: %.1fs / %.1fs" % [_turn_timer, turn_time_limit])

	print("Entities: %d" % _turn_entities.size())
	print("=======================")
#endregion
