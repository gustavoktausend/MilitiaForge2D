## Spell Battle HUD
##
## Main HUD controller for Spell Battle system.
## Manages all UI widgets and connects to battle components via signals.
##
## @tutorial(Spell Battle): res://examples/spell_battle/README.md

class_name SpellBattleHUD extends CanvasLayer

#region Exports
@export_group("Widget References")
## Player health widget
@export var player_health_widget: NaviHealthWidget

## Enemy health widget
@export var enemy_health_widget: NaviHealthWidget

## Slot-In gauge widget (player)
@export var slot_in_gauge_widget: SlotInGaugeWidget

## Turn counter display
@export var turn_counter_display: TurnCounterDisplay

@export_group("Label References")
## Player name label
@export var player_name_label: Label

## Enemy name label
@export var enemy_name_label: Label

@export_group("Settings")
## Auto-discover battle manager on ready
@export var auto_discover: bool = true

## Debug HUD connections
@export var debug_hud: bool = false
#endregion

#region Private Variables
## Reference to BattleManagerComponent
var _battle_manager: BattleManagerComponent = null

## Reference to player NaviComponent
var _player_navi: NaviComponent = null

## Reference to enemy NaviComponent
var _enemy_navi: NaviComponent = null

## Reference to player SlotInGaugeComponent
var _player_gauge: SlotInGaugeComponent = null

## Is HUD initialized
var _is_initialized: bool = false
#endregion

#region Lifecycle
func _ready() -> void:
	# Defer connection to ensure scene tree is ready
	if auto_discover:
		call_deferred("_connect_to_battle")

func _exit_tree() -> void:
	_disconnect_all_signals()
#endregion

#region Public API
## Manually connect to battle manager
## @param battle_manager: BattleManagerComponent reference
func connect_to_battle_manager(battle_manager: BattleManagerComponent) -> void:
	_battle_manager = battle_manager
	_connect_battle_signals()
	_connect_to_navis()

## Force refresh connections
func refresh_connections() -> void:
	_disconnect_all_signals()
	_connect_to_battle()
#endregion

#region Private Methods - Discovery & Connection
## Discover and connect to battle components
func _connect_to_battle() -> void:
	# Find BattleManager via scene group
	var managers = get_tree().get_nodes_in_group("battle_manager")

	if managers.size() == 0:
		push_warning("[SpellBattleHUD] No BattleManager found in 'battle_manager' group")
		return

	if managers.size() > 1:
		push_warning("[SpellBattleHUD] Multiple BattleManagers found, using first one")

	_battle_manager = managers[0] as BattleManagerComponent

	if not _battle_manager:
		push_error("[SpellBattleHUD] Found node in 'battle_manager' group is not BattleManagerComponent")
		return

	if debug_hud:
		print("[SpellBattleHUD] Found BattleManager: %s" % _battle_manager.name)

	# Connect to battle manager signals
	_connect_battle_signals()

	# Connect to Navis
	_connect_to_navis()

## Connect BattleManager signals
func _connect_battle_signals() -> void:
	if not _battle_manager:
		return

	# Connect signals safely
	if _battle_manager.has_signal("battle_started"):
		if not _battle_manager.battle_started.is_connected(_on_battle_started):
			_battle_manager.battle_started.connect(_on_battle_started)

	if _battle_manager.has_signal("turn_changed"):
		if not _battle_manager.turn_changed.is_connected(_on_turn_changed):
			_battle_manager.turn_changed.connect(_on_turn_changed)

	if _battle_manager.has_signal("phase_changed"):
		if not _battle_manager.phase_changed.is_connected(_on_phase_changed):
			_battle_manager.phase_changed.connect(_on_phase_changed)

	if _battle_manager.has_signal("battle_ended"):
		if not _battle_manager.battle_ended.is_connected(_on_battle_ended):
			_battle_manager.battle_ended.connect(_on_battle_ended)

	if debug_hud:
		print("[SpellBattleHUD] Connected to BattleManager signals")

## Connect to player and enemy Navis
func _connect_to_navis() -> void:
	if not _battle_manager:
		return

	# Get Navi entities from BattleManager
	var player_entity = _battle_manager.player_navi
	var enemy_entity = _battle_manager.enemy_navi

	if not player_entity or not enemy_entity:
		push_warning("[SpellBattleHUD] Player or enemy entity not found in BattleManager")
		return

	# Find NaviComponents
	_player_navi = _get_navi_component(player_entity)
	_enemy_navi = _get_navi_component(enemy_entity)

	if not _player_navi or not _enemy_navi:
		push_warning("[SpellBattleHUD] NaviComponents not found on player or enemy entities")
		return

	# Connect player Navi signals
	if _player_navi.has_signal("navi_hp_changed"):
		if not _player_navi.navi_hp_changed.is_connected(_on_player_hp_changed):
			_player_navi.navi_hp_changed.connect(_on_player_hp_changed)

	# Connect enemy Navi signals
	if _enemy_navi.has_signal("navi_hp_changed"):
		if not _enemy_navi.navi_hp_changed.is_connected(_on_enemy_hp_changed):
			_enemy_navi.navi_hp_changed.connect(_on_enemy_hp_changed)

	# Find player SlotInGaugeComponent
	_player_gauge = _get_gauge_component(player_entity)

	if _player_gauge:
		if _player_gauge.has_signal("gauge_changed"):
			if not _player_gauge.gauge_changed.is_connected(_on_gauge_changed):
				_player_gauge.gauge_changed.connect(_on_gauge_changed)

		if _player_gauge.has_signal("gauge_full"):
			if not _player_gauge.gauge_full.is_connected(_on_gauge_full):
				_player_gauge.gauge_full.connect(_on_gauge_full)

	if debug_hud:
		print("[SpellBattleHUD] Connected to Navi signals (Player: %s, Enemy: %s)" % [
			_player_navi.get_navi_name() if _player_navi else "None",
			_enemy_navi.get_navi_name() if _enemy_navi else "None"
		])

## Get NaviComponent from entity
func _get_navi_component(entity: Node) -> NaviComponent:
	for child in entity.get_children():
		if child is NaviComponent:
			return child
	return null

## Get SlotInGaugeComponent from entity
func _get_gauge_component(entity: Node) -> SlotInGaugeComponent:
	for child in entity.get_children():
		if child is SlotInGaugeComponent:
			return child
	return null

## Disconnect all signals
func _disconnect_all_signals() -> void:
	if _battle_manager:
		if _battle_manager.battle_started.is_connected(_on_battle_started):
			_battle_manager.battle_started.disconnect(_on_battle_started)
		if _battle_manager.turn_changed.is_connected(_on_turn_changed):
			_battle_manager.turn_changed.disconnect(_on_turn_changed)
		if _battle_manager.phase_changed.is_connected(_on_phase_changed):
			_battle_manager.phase_changed.disconnect(_on_phase_changed)
		if _battle_manager.battle_ended.is_connected(_on_battle_ended):
			_battle_manager.battle_ended.disconnect(_on_battle_ended)

	if _player_navi:
		if _player_navi.navi_hp_changed.is_connected(_on_player_hp_changed):
			_player_navi.navi_hp_changed.disconnect(_on_player_hp_changed)

	if _enemy_navi:
		if _enemy_navi.navi_hp_changed.is_connected(_on_enemy_hp_changed):
			_enemy_navi.navi_hp_changed.disconnect(_on_enemy_hp_changed)

	if _player_gauge:
		if _player_gauge.gauge_changed.is_connected(_on_gauge_changed):
			_player_gauge.gauge_changed.disconnect(_on_gauge_changed)
		if _player_gauge.gauge_full.is_connected(_on_gauge_full):
			_player_gauge.gauge_full.disconnect(_on_gauge_full)
#endregion

#region Signal Handlers
## Called when battle starts
func _on_battle_started() -> void:
	if debug_hud:
		print("[SpellBattleHUD] Battle started, initializing HUD")

	_initialize_hud()
	_is_initialized = true

## Initialize HUD with current battle state
func _initialize_hud() -> void:
	# Initialize player HP widget
	if player_health_widget and _player_navi:
		var navi_data = _player_navi.navi_data
		if navi_data:
			player_health_widget.initialize(_player_navi.get_max_hp(), _player_navi.get_current_hp())
			player_health_widget.set_navi_color(navi_data.color_theme)

			if player_name_label:
				player_name_label.text = navi_data.navi_name.to_upper()
				player_name_label.add_theme_color_override("font_color", navi_data.color_theme)

	# Initialize enemy HP widget
	if enemy_health_widget and _enemy_navi:
		var navi_data = _enemy_navi.navi_data
		if navi_data:
			enemy_health_widget.initialize(_enemy_navi.get_max_hp(), _enemy_navi.get_current_hp())
			enemy_health_widget.set_navi_color(navi_data.color_theme)

			if enemy_name_label:
				enemy_name_label.text = navi_data.navi_name.to_upper()
				enemy_name_label.add_theme_color_override("font_color", navi_data.color_theme)

	# Initialize Slot-In gauge
	if slot_in_gauge_widget and _player_gauge:
		slot_in_gauge_widget.initialize()

	# Initialize turn counter
	if turn_counter_display and _battle_manager:
		turn_counter_display.update_turn(_battle_manager.get_current_turn(), _battle_manager.max_turns)

## Called when turn changes
func _on_turn_changed(turn_number: int, max_turns: int) -> void:
	if debug_hud:
		print("[SpellBattleHUD] Turn changed: %d / %d" % [turn_number, max_turns])

	if turn_counter_display:
		turn_counter_display.update_turn(turn_number, max_turns)

## Called when phase changes
func _on_phase_changed(new_phase: int, old_phase: int) -> void:
	if debug_hud:
		print("[SpellBattleHUD] Phase changed: %d → %d" % [old_phase, new_phase])

	# Future: Update phase indicator UI

## Called when player HP changes
func _on_player_hp_changed(current_hp: int, max_hp: int) -> void:
	if debug_hud:
		print("[SpellBattleHUD] Player HP: %d / %d" % [current_hp, max_hp])

	if player_health_widget:
		player_health_widget.update_hp(current_hp, max_hp, true)

## Called when enemy HP changes
func _on_enemy_hp_changed(current_hp: int, max_hp: int) -> void:
	if debug_hud:
		print("[SpellBattleHUD] Enemy HP: %d / %d" % [current_hp, max_hp])

	if enemy_health_widget:
		enemy_health_widget.update_hp(current_hp, max_hp, true)

## Called when gauge changes
func _on_gauge_changed(current_value: float, max_value: float) -> void:
	if debug_hud:
		print("[SpellBattleHUD] Gauge: %.1f / %.1f (%.1f%%)" % [
			current_value, max_value, (current_value / max_value) * 100.0
		])

	if slot_in_gauge_widget:
		var percentage = current_value / max_value if max_value > 0 else 0.0
		slot_in_gauge_widget.set_gauge_percentage(percentage, true)

## Called when gauge is full
func _on_gauge_full() -> void:
	if debug_hud:
		print("[SpellBattleHUD] Slot-In Gauge is FULL!")

	# Gauge widget handles its own flash effect

## Called when battle ends
func _on_battle_ended(result: int, winner: Node) -> void:
	if debug_hud:
		var result_text = ["NONE", "PLAYER_WIN", "ENEMY_WIN", "DRAW"][result]
		print("[SpellBattleHUD] Battle ended: %s" % result_text)

	# Future: Show victory/defeat overlay
#endregion
