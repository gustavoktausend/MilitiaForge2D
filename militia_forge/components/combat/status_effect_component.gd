## Status Effect Component
##
## Generic component for managing buffs, debuffs, and status effects.
## Supports DOT/HOT, stat modifiers, stacking, and duration-based effects.
##
## Features:
## - Multiple simultaneous status effects
## - Duration-based effects with auto-removal
## - Stacking support (max stacks)
## - Stat modifiers (damage, speed, defense, etc.)
## - DOT (Damage Over Time) and HOT (Heal Over Time)
## - Effect immunity
## - Signal-based communication
##
## @tutorial(Status Effects): res://docs/components/status_effect_component.md

class_name StatusEffectComponent extends Component

#region Inner Classes
## Represents a single status effect
class StatusEffect:
	var effect_name: String
	var effect_type: EffectType
	var duration: float  ## -1 = infinite
	var tick_interval: float  ## For DOT/HOT
	var tick_damage: float  ## Damage/heal per tick
	var stat_modifiers: Dictionary  ## stat_name: modifier_value
	var stacks: int = 1
	var max_stacks: int = 1
	var source: Node  ## Who applied this effect
	var visual_effect: PackedScene  ## Optional visual effect

	var _time_elapsed: float = 0.0
	var _tick_timer: float = 0.0

	func is_expired() -> bool:
		return duration > 0.0 and _time_elapsed >= duration

	func update(delta: float) -> void:
		_time_elapsed += delta
		_tick_timer += delta
#endregion

#region Enums
enum EffectType {
	BUFF,        ## Positive effect
	DEBUFF,      ## Negative effect
	DOT,         ## Damage Over Time
	HOT,         ## Heal Over Time
	STUN,        ## Prevents actions
	SLOW,        ## Reduces speed
	ROOT,        ## Prevents movement
	SILENCE,     ## Prevents abilities
	CUSTOM       ## Custom effect type
}
#endregion

#region Signals
## Emitted when a status effect is applied
signal effect_applied(effect_name: String, effect_type: EffectType, stacks: int)

## Emitted when a status effect is removed
signal effect_removed(effect_name: String, effect_type: EffectType)

## Emitted when a status effect ticks (DOT/HOT)
signal effect_ticked(effect_name: String, damage: float)

## Emitted when a status effect is refreshed
signal effect_refreshed(effect_name: String, new_duration: float)

## Emitted when effect immunity prevents an effect
signal effect_immune(effect_name: String, effect_type: EffectType)
#endregion

#region Exports
@export_group("Settings")
## Whether to print debug messages
@export var debug_effects: bool = false

## Maximum number of different effects that can be active
@export var max_active_effects: int = 10
#endregion

#region Private Variables
## Active status effects by name
var _active_effects: Dictionary = {}

## Effects that this entity is immune to
var _immunities: Array[String] = []

## Reference to HealthComponent for DOT/HOT
var _health_component: HealthComponent = null
#endregion

#region Component Lifecycle
func component_ready() -> void:
	# Try to find HealthComponent for DOT/HOT
	_health_component = get_sibling_component("HealthComponent")

	if debug_effects:
		print("[StatusEffectComponent] Ready. Max effects: %d" % max_active_effects)

func component_process(delta: float) -> void:
	# Update all active effects
	var effects_to_remove: Array[String] = []

	for effect_name in _active_effects:
		var effect: StatusEffect = _active_effects[effect_name]
		effect.update(delta)

		# Handle DOT/HOT ticking
		if effect.effect_type in [EffectType.DOT, EffectType.HOT]:
			if effect.tick_interval > 0.0 and effect._tick_timer >= effect.tick_interval:
				effect._tick_timer = 0.0
				_apply_tick_damage(effect)

		# Check if effect expired
		if effect.is_expired():
			effects_to_remove.append(effect_name)

	# Remove expired effects
	for effect_name in effects_to_remove:
		remove_effect(effect_name)

func cleanup() -> void:
	clear_all_effects()
	super.cleanup()
#endregion

#region Public Methods
## Apply a status effect
## @param effect_name: Unique identifier for the effect
## @param effect_type: Type of effect
## @param duration: Duration in seconds (-1 for infinite)
## @param stat_modifiers: Dictionary of stat modifications
## @param tick_interval: Interval for DOT/HOT (0 = no ticking)
## @param tick_damage: Damage/heal per tick
## @param max_stacks: Maximum number of stacks
## @param source: Entity that applied the effect
## @returns: true if effect was applied, false if immune or at max effects
func apply_effect(
	effect_name: String,
	effect_type: EffectType,
	duration: float = 5.0,
	stat_modifiers: Dictionary = {},
	tick_interval: float = 0.0,
	tick_damage: float = 0.0,
	max_stacks: int = 1,
	source: Node = null
) -> bool:
	# Check immunity
	if _immunities.has(effect_name):
		effect_immune.emit(effect_name, effect_type)
		if debug_effects:
			print("[StatusEffectComponent] Immune to: %s" % effect_name)
		return false

	# Check if effect already exists (stacking)
	if _active_effects.has(effect_name):
		var existing: StatusEffect = _active_effects[effect_name]

		# Increase stacks if allowed
		if existing.stacks < existing.max_stacks:
			existing.stacks += 1
			existing._time_elapsed = 0.0  # Reset duration
			effect_refreshed.emit(effect_name, duration)

			if debug_effects:
				print("[StatusEffectComponent] Stacked %s: %d/%d" % [
					effect_name, existing.stacks, existing.max_stacks
				])
			return true
		else:
			# Refresh duration
			existing._time_elapsed = 0.0
			effect_refreshed.emit(effect_name, duration)

			if debug_effects:
				print("[StatusEffectComponent] Refreshed %s" % effect_name)
			return true

	# Check max effects limit
	if _active_effects.size() >= max_active_effects:
		push_warning("[StatusEffectComponent] Max effects reached (%d)" % max_active_effects)
		return false

	# Create new effect
	var effect = StatusEffect.new()
	effect.effect_name = effect_name
	effect.effect_type = effect_type
	effect.duration = duration
	effect.tick_interval = tick_interval
	effect.tick_damage = tick_damage
	effect.stat_modifiers = stat_modifiers
	effect.max_stacks = max_stacks
	effect.source = source

	_active_effects[effect_name] = effect
	effect_applied.emit(effect_name, effect_type, 1)

	if debug_effects:
		print("[StatusEffectComponent] Applied %s (type: %s, duration: %.1fs)" % [
			effect_name, EffectType.keys()[effect_type], duration
		])

	return true

## Remove a status effect
## @param effect_name: Name of the effect to remove
## @returns: true if effect was removed
func remove_effect(effect_name: String) -> bool:
	if not _active_effects.has(effect_name):
		return false

	var effect: StatusEffect = _active_effects[effect_name]
	_active_effects.erase(effect_name)
	effect_removed.emit(effect_name, effect.effect_type)

	if debug_effects:
		print("[StatusEffectComponent] Removed %s" % effect_name)

	return true

## Check if an effect is active
## @param effect_name: Name of the effect
## @returns: true if effect is active
func has_effect(effect_name: String) -> bool:
	return _active_effects.has(effect_name)

## Get an active effect
## @param effect_name: Name of the effect
## @returns: StatusEffect or null
func get_effect(effect_name: String) -> StatusEffect:
	return _active_effects.get(effect_name, null)

## Get all active effects of a specific type
## @param effect_type: Type of effect to filter
## @returns: Array of StatusEffect
func get_effects_by_type(effect_type: EffectType) -> Array[StatusEffect]:
	var result: Array[StatusEffect] = []
	for effect in _active_effects.values():
		if effect.effect_type == effect_type:
			result.append(effect)
	return result

## Get total modifier for a stat from all active effects
## @param stat_name: Name of the stat (e.g., "damage", "speed")
## @returns: Sum of all modifiers for this stat
func get_stat_modifier(stat_name: String) -> float:
	var total: float = 0.0

	for effect in _active_effects.values():
		if effect.stat_modifiers.has(stat_name):
			total += effect.stat_modifiers[stat_name] * effect.stacks

	return total

## Clear all status effects
func clear_all_effects() -> void:
	var effect_names = _active_effects.keys()
	for effect_name in effect_names:
		remove_effect(effect_name)

	if debug_effects:
		print("[StatusEffectComponent] Cleared all effects")

## Add immunity to a specific effect
## @param effect_name: Name of the effect to be immune to
func add_immunity(effect_name: String) -> void:
	if not _immunities.has(effect_name):
		_immunities.append(effect_name)

		if debug_effects:
			print("[StatusEffectComponent] Added immunity to: %s" % effect_name)

## Remove immunity
## @param effect_name: Name of the effect
func remove_immunity(effect_name: String) -> void:
	_immunities.erase(effect_name)

	if debug_effects:
		print("[StatusEffectComponent] Removed immunity to: %s" % effect_name)

## Check if immune to an effect
## @param effect_name: Name of the effect
## @returns: true if immune
func is_immune(effect_name: String) -> bool:
	return _immunities.has(effect_name)

## Get number of active effects
## @returns: Count of active effects
func get_active_effect_count() -> int:
	return _active_effects.size()

## Check if stunned (cannot act)
## @returns: true if any STUN effect is active
func is_stunned() -> bool:
	for effect in _active_effects.values():
		if effect.effect_type == EffectType.STUN:
			return true
	return false

## Check if silenced (cannot use abilities)
## @returns: true if any SILENCE effect is active
func is_silenced() -> bool:
	for effect in _active_effects.values():
		if effect.effect_type == EffectType.SILENCE:
			return true
	return false

## Check if rooted (cannot move)
## @returns: true if any ROOT effect is active
func is_rooted() -> bool:
	for effect in _active_effects.values():
		if effect.effect_type == EffectType.ROOT:
			return true
	return false
#endregion

#region Private Methods
## Apply tick damage/healing for DOT/HOT
func _apply_tick_damage(effect: StatusEffect) -> void:
	if not _health_component:
		return

	if effect.effect_type == EffectType.DOT:
		# Damage over time
		_health_component.take_damage(int(effect.tick_damage), effect.source)
		effect_ticked.emit(effect.effect_name, effect.tick_damage)

		if debug_effects:
			print("[StatusEffectComponent] %s ticked: -%d HP" % [effect.effect_name, effect.tick_damage])

	elif effect.effect_type == EffectType.HOT:
		# Heal over time
		_health_component.heal(int(effect.tick_damage))
		effect_ticked.emit(effect.effect_name, effect.tick_damage)

		if debug_effects:
			print("[StatusEffectComponent] %s ticked: +%d HP" % [effect.effect_name, effect.tick_damage])
#endregion

#region Debug Methods
## Print all active effects
func debug_print_effects() -> void:
	print("=== Active Status Effects ===")
	if _active_effects.is_empty():
		print("No active effects")
	else:
		for effect_name in _active_effects:
			var effect: StatusEffect = _active_effects[effect_name]
			print("%s [%s] - Stacks: %d, Remaining: %.1fs" % [
				effect_name,
				EffectType.keys()[effect.effect_type],
				effect.stacks,
				effect.duration - effect._time_elapsed if effect.duration > 0 else INF
			])
	print("===========================")
#endregion
