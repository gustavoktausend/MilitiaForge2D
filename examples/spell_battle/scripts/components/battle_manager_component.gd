## Battle Manager Component
##
## Game-specific component that manages the entire spell-battle flow.
## Coordinates turn system, victory conditions, and battle state.
##
## Features:
## - Turn-based battle flow (10 turn limit)
## - Victory condition checking (HP = 0 OR most HP after 10 turns)
## - Phase management (chip selection, chip usage, default attack)
## - Player vs AI coordination
## - Battle statistics tracking
##
## @tutorial(Spell Battle): res://examples/spell_battle/README.md

class_name BattleManagerComponent extends Component

#region Enums
enum BattlePhase {
	SETUP,           ## Battle initialization
	CHIP_SELECTION,  ## Player selecting chips
	CHIP_USAGE,      ## Using selected chips
	DEFAULT_ATTACK,  ## Executing default attack
	TURN_END,        ## End of turn cleanup
	BATTLE_END       ## Battle finished
}

enum BattleResult {
	NONE,            ## Battle ongoing
	PLAYER_WIN,      ## Player won
	ENEMY_WIN,       ## Enemy won
	DRAW             ## Draw (same HP after 10 turns)
}
#endregion

#region Signals
## Emitted when battle starts
signal battle_started()

## Emitted when battle phase changes
signal phase_changed(new_phase: BattlePhase, old_phase: BattlePhase)

## Emitted when battle ends
signal battle_ended(result: BattleResult, winner: Node)

## Emitted when turn changes
signal turn_changed(turn_number: int, max_turns: int)

## Emitted when victory condition is met
signal victory_condition_met(condition: String, winner: Node)
#endregion

#region Exports
@export_group("Battle Settings")
## Maximum number of turns
@export var max_turns: int = 10

## Whether battle has started
@export var battle_active: bool = false

@export_group("Participants")
## Player Navi entity
@export var player_navi: Node

## Enemy Navi entity
@export var enemy_navi: Node

@export_group("Advanced")
## Whether to print debug messages
@export var debug_battle: bool = false
#endregion

#region Private Variables
## Current battle phase
var _current_phase: BattlePhase = BattlePhase.SETUP

## Current turn number
var _current_turn: int = 0

## Battle result
var _battle_result: BattleResult = BattleResult.NONE

## Turn system component reference
var _turn_system: TurnSystemComponent = null

## Player NaviComponent
var _player_navi_component: NaviComponent = null

## Enemy NaviComponent
var _enemy_navi_component: NaviComponent = null

## Battle start time (for statistics)
var _battle_start_time: float = 0.0

## Total damage dealt by player
var _player_total_damage: int = 0

## Total damage dealt by enemy
var _enemy_total_damage: int = 0
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
	# Find or create TurnSystemComponent
	_turn_system = _find_or_create_turn_system()

	# Find Navi components
	if player_navi:
		_player_navi_component = _get_navi_component(player_navi)

	if enemy_navi:
		_enemy_navi_component = _get_navi_component(enemy_navi)

	# Connect signals
	if _turn_system:
		_turn_system.turn_started.connect(_on_turn_started)
		_turn_system.turn_ended.connect(_on_turn_ended)
		_turn_system.turns_completed.connect(_on_turns_completed)

	if _player_navi_component:
		_player_navi_component.navi_defeated.connect(_on_player_defeated)

	if _enemy_navi_component:
		_enemy_navi_component.navi_defeated.connect(_on_enemy_defeated)

	if debug_battle:
		print("[BattleManager] Ready. Max turns: %d" % max_turns)

func cleanup() -> void:
	if battle_active:
		end_battle(BattleResult.DRAW, null)
	super.cleanup()
#endregion

#region Public Methods - Battle Control
## Start the battle
func start_battle() -> void:
	if battle_active:
		push_warning("[BattleManager] Battle already active")
		return

	if not _validate_battle_setup():
		push_error("[BattleManager] Invalid battle setup!")
		return

	battle_active = true
	_current_turn = 0
	_battle_result = BattleResult.NONE
	_battle_start_time = Time.get_ticks_msec() / 1000.0
	_player_total_damage = 0
	_enemy_total_damage = 0

	# Setup turn system
	if _turn_system:
		_turn_system.max_turns = max_turns
		_turn_system.set_turn_entities([player_navi, enemy_navi])

	battle_started.emit()

	if debug_battle:
		print("[BattleManager] Battle STARTED!")
		print("  Player: %s" % _player_navi_component.get_navi_name())
		print("  Enemy: %s" % _enemy_navi_component.get_navi_name())

	# Start turn system
	if _turn_system:
		_turn_system.start_turn_system()

	# Begin first phase
	_change_phase(BattlePhase.CHIP_SELECTION)

## End the battle
## @param result: Battle result
## @param winner: Winning Navi (optional)
func end_battle(result: BattleResult, winner: Node) -> void:
	if not battle_active:
		return

	battle_active = false
	_battle_result = result

	# Stop turn system
	if _turn_system:
		_turn_system.stop_turn_system()

	_change_phase(BattlePhase.BATTLE_END)

	battle_ended.emit(result, winner)

	if debug_battle:
		var result_name = BattleResult.keys()[result]
		var winner_name = winner.name if winner else "None"
		var duration = (Time.get_ticks_msec() / 1000.0) - _battle_start_time
		print("[BattleManager] Battle ENDED!")
		print("  Result: %s" % result_name)
		print("  Winner: %s" % winner_name)
		print("  Duration: %.1fs" % duration)
		print("  Turns: %d / %d" % [_current_turn, max_turns])

## Advance to next phase
func advance_phase() -> void:
	match _current_phase:
		BattlePhase.CHIP_SELECTION:
			_change_phase(BattlePhase.CHIP_USAGE)
		BattlePhase.CHIP_USAGE:
			_change_phase(BattlePhase.DEFAULT_ATTACK)
		BattlePhase.DEFAULT_ATTACK:
			_change_phase(BattlePhase.TURN_END)
		BattlePhase.TURN_END:
			# End turn via TurnSystemComponent
			if _turn_system:
				_turn_system.end_turn()
		_:
			if debug_battle:
				print("[BattleManager] Cannot advance from phase: %s" % BattlePhase.keys()[_current_phase])
#endregion

#region Public Methods - Victory Conditions
## Check all victory conditions
## @returns: true if any condition met
func check_victory_conditions() -> bool:
	# Condition 1: Player HP = 0
	if _player_navi_component and _player_navi_component.is_defeated():
		victory_condition_met.emit("Player HP = 0", enemy_navi)
		end_battle(BattleResult.ENEMY_WIN, enemy_navi)
		return true

	# Condition 2: Enemy HP = 0
	if _enemy_navi_component and _enemy_navi_component.is_defeated():
		victory_condition_met.emit("Enemy HP = 0", player_navi)
		end_battle(BattleResult.PLAYER_WIN, player_navi)
		return true

	# Condition 3: 10 turns completed - compare HP
	if _current_turn >= max_turns:
		var player_hp = _player_navi_component.get_current_hp() if _player_navi_component else 0
		var enemy_hp = _enemy_navi_component.get_current_hp() if _enemy_navi_component else 0

		if player_hp > enemy_hp:
			victory_condition_met.emit("Most HP after 10 turns", player_navi)
			end_battle(BattleResult.PLAYER_WIN, player_navi)
		elif enemy_hp > player_hp:
			victory_condition_met.emit("Most HP after 10 turns", enemy_navi)
			end_battle(BattleResult.ENEMY_WIN, enemy_navi)
		else:
			victory_condition_met.emit("Draw - Equal HP", null)
			end_battle(BattleResult.DRAW, null)

		return true

	return false

## Force check victory conditions (can be called manually)
func force_check_victory() -> bool:
	return check_victory_conditions()
#endregion

#region Public Methods - Queries
## Get current battle phase
## @returns: BattlePhase enum
func get_current_phase() -> BattlePhase:
	return _current_phase

## Get battle result
## @returns: BattleResult enum
func get_battle_result() -> BattleResult:
	return _battle_result

## Get current turn number
## @returns: Turn number
func get_current_turn() -> int:
	return _current_turn

## Get remaining turns
## @returns: Turns remaining
func get_remaining_turns() -> int:
	return max(max_turns - _current_turn, 0)

## Check if battle is active
## @returns: true if active
func is_battle_active() -> bool:
	return battle_active

## Get player Navi component
## @returns: NaviComponent
func get_player_navi() -> NaviComponent:
	return _player_navi_component

## Get enemy Navi component
## @returns: NaviComponent
func get_enemy_navi() -> NaviComponent:
	return _enemy_navi_component

## Get battle statistics
## @returns: Dictionary with stats
func get_battle_stats() -> Dictionary:
	var duration = 0.0
	if battle_active:
		duration = (Time.get_ticks_msec() / 1000.0) - _battle_start_time

	return {
		"turn": _current_turn,
		"max_turns": max_turns,
		"duration": duration,
		"player_hp": _player_navi_component.get_current_hp() if _player_navi_component else 0,
		"player_max_hp": _player_navi_component.get_max_hp() if _player_navi_component else 0,
		"enemy_hp": _enemy_navi_component.get_current_hp() if _enemy_navi_component else 0,
		"enemy_max_hp": _enemy_navi_component.get_max_hp() if _enemy_navi_component else 0,
		"player_damage_dealt": _player_total_damage,
		"enemy_damage_dealt": _enemy_total_damage,
		"phase": BattlePhase.keys()[_current_phase],
		"result": BattleResult.keys()[_battle_result]
	}
#endregion

#region Private Methods
## Validate battle setup
func _validate_battle_setup() -> bool:
	if not player_navi or not enemy_navi:
		push_error("[BattleManager] Missing player or enemy navi")
		return false

	if not _player_navi_component or not _enemy_navi_component:
		push_error("[BattleManager] Navi entities missing NaviComponent")
		return false

	return true

## Find or create turn system
func _find_or_create_turn_system() -> TurnSystemComponent:
	# Look for existing TurnSystemComponent
	if host:
		for child in host.get_children():
			if child is TurnSystemComponent:
				if debug_battle:
					print("[BattleManager] Found existing TurnSystemComponent")
				return child

	# Create new one
	var turn_sys = TurnSystemComponent.new()
	turn_sys.auto_start = false
	turn_sys.debug_turns = debug_battle
	host.add_child(turn_sys)

	if debug_battle:
		print("[BattleManager] Created new TurnSystemComponent")

	return turn_sys

## Get NaviComponent from entity
func _get_navi_component(entity: Node) -> NaviComponent:
	for child in entity.get_children():
		if child is NaviComponent:
			return child
	return null

## Change battle phase
func _change_phase(new_phase: BattlePhase) -> void:
	var old_phase = _current_phase
	_current_phase = new_phase

	phase_changed.emit(new_phase, old_phase)

	if debug_battle:
		print("[BattleManager] Phase: %s -> %s" % [
			BattlePhase.keys()[old_phase],
			BattlePhase.keys()[new_phase]
		])

## Handle turn start
func _on_turn_started(turn_number: int, current_entity: Node) -> void:
	_current_turn = turn_number

	turn_changed.emit(turn_number, max_turns)

	if debug_battle:
		var entity_name = current_entity.name if current_entity else "None"
		print("[BattleManager] Turn %d/%d started (Entity: %s)" % [
			turn_number, max_turns, entity_name
		])

	# Start chip selection phase
	_change_phase(BattlePhase.CHIP_SELECTION)

## Handle turn end
func _on_turn_ended(turn_number: int, current_entity: Node) -> void:
	if debug_battle:
		print("[BattleManager] Turn %d ended" % turn_number)

	# Check victory conditions at turn end
	check_victory_conditions()

## Handle turns completed (10 turn limit)
func _on_turns_completed(final_turn: int) -> void:
	if debug_battle:
		print("[BattleManager] All %d turns completed!" % final_turn)

	# Force victory check based on HP
	check_victory_conditions()

## Handle player defeat
func _on_player_defeated() -> void:
	if debug_battle:
		print("[BattleManager] Player defeated!")

	check_victory_conditions()

## Handle enemy defeat
func _on_enemy_defeated() -> void:
	if debug_battle:
		print("[BattleManager] Enemy defeated!")

	check_victory_conditions()
#endregion

#region Debug Methods
## Print battle state
func debug_print_state() -> void:
	print("=== Battle Manager State ===")
	print("Active: %s" % battle_active)
	print("Phase: %s" % BattlePhase.keys()[_current_phase])
	print("Turn: %d / %d" % [_current_turn, max_turns])
	print("Result: %s" % BattleResult.keys()[_battle_result])

	if _player_navi_component:
		print("Player HP: %d / %d" % [
			_player_navi_component.get_current_hp(),
			_player_navi_component.get_max_hp()
		])

	if _enemy_navi_component:
		print("Enemy HP: %d / %d" % [
			_enemy_navi_component.get_current_hp(),
			_enemy_navi_component.get_max_hp()
		])

	print("==========================")
#endregion
