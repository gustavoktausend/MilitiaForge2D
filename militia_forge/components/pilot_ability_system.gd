## Pilot Ability System Component
##
## Handles special pilot abilities and their effects.
## Integrates with other components to apply bonuses and trigger effects.
##
## Design Patterns:
## - Strategy Pattern: Different abilities = different behaviors
## - Observer Pattern: Listens to component signals (kills, damage, etc.)
## - Component Pattern: Modular functionality
##
## Supported Abilities:
## - REGENERATION: Heal over time when below threshold
## - COMBO_BOOST: Enhanced damage from combo system
## - RESOURCE_SCAVENGER: Better drops and pickup range
## - BERSERKER_MODE: Damage scales with missing health
## - INVINCIBILITY_TRIGGER: Auto-invincibility at low HP
## - AMMO_EFFICIENCY: Chance to not consume ammo
## - SPECIAL_RECHARGE: Chance to refund SPECIAL ammo on kill
## - ALWAYS_SECONDARY: Keep SECONDARY weapon always enabled

class_name PilotAbilitySystem extends Component

#region Configuration
## Pilot data with ability configuration
var pilot_data: PilotData

## Debug logging
@export var debug_abilities: bool = false
#endregion

#region Component References
var health_component: HealthComponent
var score_component: ScoreComponent
var weapon_manager: WeaponSlotManager
#endregion

#region Private Variables
var _regen_timer: float = 0.0
var _berserker_current_bonus: float = 0.0
var _invincibility_trigger_cooldown: float = 0.0
var _invincibility_trigger_used: bool = false
#endregion

#region Component Lifecycle
func initialize(host_node: ComponentHost) -> void:
	super.initialize(host_node)
	
	if not pilot_data:
		push_error("[PilotAbilitySystem] No pilot data set!")
		return

	# Get component references
	health_component = get_sibling_component("HealthComponent")
	score_component = get_sibling_component("ScoreComponent")
	weapon_manager = get_sibling_component("WeaponSlotManager")

	if debug_abilities:
		print("╔════════════════════════════════════════════════════════╗")
		print("║     🌟 PILOT ABILITY SYSTEM INITIALIZED 🌟           ║")
		print("╠════════════════════════════════════════════════════════╣")
		print("║ Pilot: %s" % pilot_data.pilot_name)

		if pilot_data.primary_ability != PilotData.AbilityType.NONE:
			print("║ Primary Ability: %s" % PilotData.AbilityType.keys()[pilot_data.primary_ability])

		if pilot_data.secondary_ability != PilotData.AbilityType.NONE:
			print("║ Secondary Ability: %s" % PilotData.AbilityType.keys()[pilot_data.secondary_ability])

		print("╚════════════════════════════════════════════════════════╝")

	# Connect to signals
	_connect_signals()

	# Apply passive abilities
	_apply_passive_abilities()

func component_process(delta: float) -> void:
	if not pilot_data:
		return

	# Process regeneration ability
	if _has_ability(PilotData.AbilityType.REGENERATION):
		_process_regeneration(delta)

	# Process berserker mode
	if _has_ability(PilotData.AbilityType.BERSERKER_MODE):
		_process_berserker_mode()

	# Process invincibility trigger cooldown
	if _invincibility_trigger_cooldown > 0.0:
		_invincibility_trigger_cooldown -= delta

	# Check for invincibility trigger
	if _has_ability(PilotData.AbilityType.INVINCIBILITY_TRIGGER):
		_check_invincibility_trigger()
#endregion

#region Signal Connections
func _connect_signals() -> void:
	# Connect to score component for kill tracking
	if score_component:
		score_component.enemy_killed.connect(_on_enemy_killed)

	# Connect to weapon manager for ammo efficiency
	if weapon_manager:
		# Note: We'll need to add a signal to WeaponSlotManager for ammo consumption
		pass

	if debug_abilities:
		print("[PilotAbilitySystem] Signals connected")
#endregion

#region Passive Abilities
func _apply_passive_abilities() -> void:
	# ALWAYS_SECONDARY - Force SECONDARY weapon to stay enabled
	if _has_ability(PilotData.AbilityType.ALWAYS_SECONDARY):
		if weapon_manager:
			weapon_manager.set_secondary_enabled(true)
			# TODO: Add lock so it can't be toggled off
			if debug_abilities:
				print("[PilotAbilitySystem] ALWAYS_SECONDARY active - SECONDARY weapon locked ON")

	# COMBO_BOOST - Apply combo system modifiers
	if _has_ability(PilotData.AbilityType.COMBO_BOOST):
		if score_component:
			# Enhanced combo damage is applied in _get_combo_damage_multiplier()
			if debug_abilities:
				print("[PilotAbilitySystem] COMBO_BOOST active")
#endregion

#region Ability Implementations - REGENERATION
func _process_regeneration(delta: float) -> void:
	if not health_component:
		return

	var regen_rate = pilot_data.get_ability_value("regen_rate", 1.0)
	var regen_threshold = pilot_data.get_ability_value("regen_threshold", 1.0)

	# Check if below threshold (1.0 = always regenerate)
	var health_percentage = float(health_component.current_health) / float(health_component.max_health)
	if health_percentage >= regen_threshold:
		return

	# Regenerate health
	_regen_timer += delta
	if _regen_timer >= 1.0:  # Tick every second
		_regen_timer = 0.0
		health_component.heal(int(regen_rate))

		if debug_abilities:
			print("[PilotAbilitySystem] ❤️ Regenerated %d HP" % int(regen_rate))
#endregion

#region Ability Implementations - BERSERKER_MODE
func _process_berserker_mode() -> void:
	if not health_component:
		return

	# Calculate current health percentage
	var health_percentage = float(health_component.current_health) / float(health_component.max_health)

	# Get damage bonuses from config
	var bonus_at_full = pilot_data.get_ability_value("damage_bonus_at_full", 0.0)
	var bonus_at_half = pilot_data.get_ability_value("damage_bonus_at_half", 0.25)
	var bonus_at_quarter = pilot_data.get_ability_value("damage_bonus_at_quarter", 0.50)
	var bonus_at_critical = pilot_data.get_ability_value("damage_bonus_at_critical", 0.75)

	# Interpolate bonus based on health
	var new_bonus: float
	if health_percentage >= 1.0:
		new_bonus = bonus_at_full
	elif health_percentage >= 0.5:
		# Interpolate between full and half
		var t = (1.0 - health_percentage) / 0.5
		new_bonus = lerp(bonus_at_full, bonus_at_half, t)
	elif health_percentage >= 0.25:
		# Interpolate between half and quarter
		var t = (0.5 - health_percentage) / 0.25
		new_bonus = lerp(bonus_at_half, bonus_at_quarter, t)
	elif health_percentage >= 0.1:
		# Interpolate between quarter and critical
		var t = (0.25 - health_percentage) / 0.15
		new_bonus = lerp(bonus_at_quarter, bonus_at_critical, t)
	else:
		# Below 10% HP = max bonus
		new_bonus = bonus_at_critical

	# Log changes
	if abs(new_bonus - _berserker_current_bonus) > 0.01:
		_berserker_current_bonus = new_bonus
		if debug_abilities:
			print("[PilotAbilitySystem] 🔥 BERSERKER MODE: +%.0f%% damage (%.0f%% HP)" % [
				_berserker_current_bonus * 100,
				health_percentage * 100
			])

## Get current berserker damage multiplier (called by weapons)
func get_berserker_damage_multiplier() -> float:
	if not _has_ability(PilotData.AbilityType.BERSERKER_MODE):
		return 1.0
	return 1.0 + _berserker_current_bonus
#endregion

#region Ability Implementations - INVINCIBILITY_TRIGGER
func _check_invincibility_trigger() -> void:
	if not health_component:
		return

	# Don't trigger if on cooldown
	if _invincibility_trigger_cooldown > 0.0:
		return

	var health_percentage = float(health_component.current_health) / float(health_component.max_health)
	var threshold = pilot_data.get_ability_value("invincibility_threshold", 0.15)

	# Trigger invincibility if below threshold
	if health_percentage <= threshold and not health_component.is_invincible():
		health_component.make_invincible(2.0)  # 2 seconds of invincibility

		# Set cooldown
		var cooldown = pilot_data.get_ability_value("invincibility_cooldown", 30.0)
		_invincibility_trigger_cooldown = cooldown

		if debug_abilities:
			print("[PilotAbilitySystem] 🛡️ AUTO-INVINCIBILITY TRIGGERED! (%.0fs cooldown)" % cooldown)
#endregion

#region Ability Implementations - COMBO_BOOST
## Get combo damage multiplier (called by combo system)
func get_combo_damage_multiplier(base_combo: int) -> float:
	if not _has_ability(PilotData.AbilityType.COMBO_BOOST):
		return 1.0

	var bonus_per_kill = pilot_data.get_ability_value("combo_damage_bonus_per_kill", 0.05)
	var max_bonus = pilot_data.get_ability_value("max_combo_bonus", 0.50)

	var bonus = min(base_combo * bonus_per_kill, max_bonus)
	return 1.0 + bonus
#endregion

#region Ability Implementations - Event-Based
func _on_enemy_killed(enemy: Node2D, points: int) -> void:
	# SPECIAL_RECHARGE - Chance to refund SPECIAL ammo on kill
	if _has_ability(PilotData.AbilityType.SPECIAL_RECHARGE):
		_try_special_recharge()

	# RESOURCE_SCAVENGER - Enhanced drops handled by drop system
	# (drop rate multiplier is read directly from pilot_data)

func _try_special_recharge() -> void:
	if not weapon_manager:
		return

	var recharge_chance = pilot_data.get_ability_value("recharge_chance", 0.15)

	# Roll for recharge
	if randf() < recharge_chance:
		# Refund 1 SPECIAL ammo
		var current_ammo = weapon_manager.get_ammo(WeaponData.Category.SPECIAL)
		var max_ammo = weapon_manager.get_max_ammo(WeaponData.Category.SPECIAL)

		if current_ammo < max_ammo:
			weapon_manager._weapon_ammo[WeaponData.Category.SPECIAL] += 1
			weapon_manager.ammo_changed.emit(
				WeaponData.Category.SPECIAL,
				current_ammo + 1,
				max_ammo
			)

			if debug_abilities:
				print("[PilotAbilitySystem] 🔋 SPECIAL ammo recharged! (%d/%d)" % [current_ammo + 1, max_ammo])
#endregion

#region Helpers
## Check if pilot has a specific ability
func _has_ability(ability: PilotData.AbilityType) -> bool:
	if not pilot_data:
		return false
	return pilot_data.has_ability(ability)

## Get ability config value
func _get_ability_value(key: String, default: float = 0.0) -> float:
	if not pilot_data:
		return default
	return pilot_data.get_ability_value(key, default)
#endregion

#region Debug
func get_debug_info() -> Dictionary:
	return {
		"pilot": pilot_data.pilot_name if pilot_data else "None",
		"primary_ability": PilotData.AbilityType.keys()[pilot_data.primary_ability] if pilot_data else "NONE",
		"berserker_bonus": _berserker_current_bonus,
		"invincibility_cooldown": _invincibility_trigger_cooldown,
	}
#endregion
