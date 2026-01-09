## Battle Field Component
##
## Game-specific component that manages the battle field state for spell-battle.
## Handles field transformations (Fire, Ice, Electric, Poison, etc.) and their effects.
##
## Features:
## - Field type transformations
## - Continuous damage/effects on field
## - Field duration tracking
## - Visual field effects
## - Field-based damage modifiers
##
## @tutorial(Spell Battle): res://examples/spell_battle/README.md

class_name BattleFieldComponent extends Component

#region Enums
enum FieldType {
	NORMAL,    ## Default field (no effects)
	FIRE,      ## Fire field (continuous damage)
	ICE,       ## Ice field (slow movement)
	ELECTRIC,  ## Electric field (periodic stun)
	POISON,    ## Poison field (DOT)
	WOOD,      ## Wood field (HP regeneration)
	WIND       ## Wind field (increased movement speed)
}
#endregion

#region Signals
## Emitted when field type changes
signal field_changed(new_field: FieldType, old_field: FieldType)

## Emitted when field effect ticks (applies damage/effects)
signal field_tick(field_type: FieldType)

## Emitted when field duration expires
signal field_expired(field_type: FieldType)

## Emitted when entity enters field
signal entity_entered_field(entity: Node)

## Emitted when entity exits field
signal entity_exited_field(entity: Node)
#endregion

#region Exports
@export_group("Field Settings")
## Current field type
@export var current_field: FieldType = FieldType.NORMAL

## Default field (reverts to this when duration expires)
@export var default_field: FieldType = FieldType.NORMAL

@export_group("Field Effects")
## Damage per tick for damaging fields (Fire, Poison, Electric)
@export var field_damage_per_tick: float = 5.0

## Tick interval (how often effects apply)
@export var tick_interval: float = 1.0

## Movement speed modifier for Ice field
@export var ice_slow_multiplier: float = 0.5

## Movement speed modifier for Wind field
@export var wind_speed_multiplier: float = 1.5

@export_group("Duration")
## Whether field transformations have duration
@export var use_field_duration: bool = true

## Current field duration remaining
@export var current_duration: float = 0.0

@export_group("Visual")
## Visual field effect node (ParticleSystem, AnimatedSprite, etc.)
@export var visual_field_effect: Node2D

## Field color tints per type
@export var field_colors: Dictionary = {
	FieldType.NORMAL: Color(1.0, 1.0, 1.0, 0.0),
	FieldType.FIRE: Color(1.0, 0.3, 0.0, 0.5),
	FieldType.ICE: Color(0.5, 0.8, 1.0, 0.5),
	FieldType.ELECTRIC: Color(1.0, 1.0, 0.2, 0.5),
	FieldType.POISON: Color(0.5, 0.0, 0.8, 0.5),
	FieldType.WOOD: Color(0.2, 0.8, 0.2, 0.5),
	FieldType.WIND: Color(0.7, 1.0, 0.7, 0.3)
}

@export_group("Advanced")
## Whether to print debug messages
@export var debug_field: bool = false
#endregion

#region Private Variables
## Tick timer
var _tick_timer: float = 0.0

## Entities currently on the field
var _entities_on_field: Array[Node] = []
#endregion

#region Component Lifecycle
func component_ready() -> void:
	_tick_timer = tick_interval

	# Apply initial field visuals
	_update_field_visuals()

	if debug_field:
		print("[BattleFieldComponent] Ready. Field: %s" % FieldType.keys()[current_field])

func component_process(delta: float) -> void:
	# Update duration
	if use_field_duration and current_field != default_field:
		current_duration -= delta

		if current_duration <= 0.0:
			_expire_field()

	# Update tick timer
	_tick_timer -= delta

	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		_apply_field_tick()

func cleanup() -> void:
	_entities_on_field.clear()
	super.cleanup()
#endregion

#region Public Methods - Field Transformation
## Transform the field to a new type
## @param new_field: New FieldType
## @param duration: Duration in seconds (0 = infinite)
func transform_field(new_field: FieldType, duration: float = 10.0) -> void:
	var old_field = current_field
	current_field = new_field
	current_duration = duration

	field_changed.emit(new_field, old_field)

	# Update visuals
	_update_field_visuals()

	if debug_field:
		print("[BattleFieldComponent] Field transformed: %s -> %s (Duration: %.1fs)" % [
			FieldType.keys()[old_field], FieldType.keys()[new_field], duration
		])

## Reset field to default
func reset_field() -> void:
	transform_field(default_field, 0.0)

## Extend current field duration
## @param additional_time: Time to add (seconds)
func extend_field_duration(additional_time: float) -> void:
	if not use_field_duration:
		return

	current_duration += additional_time

	if debug_field:
		print("[BattleFieldComponent] Field duration extended by %.1fs (Total: %.1fs)" % [
			additional_time, current_duration
		])
#endregion

#region Public Methods - Entity Management
## Register an entity as being on the field
## @param entity: Entity node
func add_entity_to_field(entity: Node) -> void:
	if entity in _entities_on_field:
		return

	_entities_on_field.append(entity)
	entity_entered_field.emit(entity)

	# Apply immediate field effects
	_apply_field_effects_to_entity(entity)

	if debug_field:
		print("[BattleFieldComponent] Entity entered field: %s" % entity.name)

## Remove an entity from the field
## @param entity: Entity node
func remove_entity_from_field(entity: Node) -> void:
	var index = _entities_on_field.find(entity)
	if index == -1:
		return

	_entities_on_field.remove_at(index)
	entity_exited_field.emit(entity)

	# Remove field effects
	_remove_field_effects_from_entity(entity)

	if debug_field:
		print("[BattleFieldComponent] Entity exited field: %s" % entity.name)

## Get all entities on field
## @returns: Array of entities
func get_entities_on_field() -> Array[Node]:
	return _entities_on_field.duplicate()

## Clear all entities from field
func clear_entities() -> void:
	for entity in _entities_on_field:
		entity_exited_field.emit(entity)
		_remove_field_effects_from_entity(entity)

	_entities_on_field.clear()
#endregion

#region Public Methods - Field Effects
## Get damage modifier for element on current field
## @param element: ChipData.ElementType
## @returns: Damage multiplier
func get_element_damage_modifier(element: ChipData.ElementType) -> float:
	match current_field:
		FieldType.FIRE:
			if element == ChipData.ElementType.FIRE:
				return 1.5  # Fire chips boosted on fire field
			elif element == ChipData.ElementType.WATER:
				return 0.7  # Water chips weakened
		FieldType.ICE:
			if element == ChipData.ElementType.WATER:
				return 1.5
			elif element == ChipData.ElementType.FIRE:
				return 0.7
		FieldType.ELECTRIC:
			if element == ChipData.ElementType.ELECTRIC:
				return 1.5
		FieldType.WOOD:
			if element == ChipData.ElementType.WOOD:
				return 1.5

	return 1.0  # No modifier

## Get movement speed modifier for current field
## @returns: Speed multiplier
func get_movement_speed_modifier() -> float:
	match current_field:
		FieldType.ICE:
			return ice_slow_multiplier
		FieldType.WIND:
			return wind_speed_multiplier
		_:
			return 1.0
#endregion

#region Public Methods - Queries
## Get current field type
## @returns: FieldType enum value
func get_current_field() -> FieldType:
	return current_field

## Get remaining field duration
## @returns: Seconds remaining
func get_remaining_duration() -> float:
	return maxf(current_duration, 0.0)

## Check if field is active (not NORMAL)
## @returns: true if transformed field
func is_field_active() -> bool:
	return current_field != FieldType.NORMAL

## Get field name
## @returns: Field type as string
func get_field_name() -> String:
	return FieldType.keys()[current_field]
#endregion

#region Private Methods
## Apply field tick effects
func _apply_field_tick() -> void:
	if current_field == FieldType.NORMAL or _entities_on_field.is_empty():
		return

	field_tick.emit(current_field)

	# Apply effects to all entities on field
	for entity in _entities_on_field:
		_apply_tick_damage_to_entity(entity)

## Apply tick damage to entity
func _apply_tick_damage_to_entity(entity: Node) -> void:
	match current_field:
		FieldType.FIRE, FieldType.POISON, FieldType.ELECTRIC:
			# Apply damage
			if entity.has_method("take_damage"):
				entity.take_damage(int(field_damage_per_tick), host)

				if debug_field:
					print("[BattleFieldComponent] %s field damaged %s for %d" % [
						get_field_name(), entity.name, field_damage_per_tick
					])

		FieldType.WOOD:
			# Apply healing
			if entity.has_method("heal"):
				entity.heal(int(field_damage_per_tick))  # Reuse same value for heal

				if debug_field:
					print("[BattleFieldComponent] Wood field healed %s for %d" % [
						entity.name, field_damage_per_tick
					])

## Apply field effects when entity enters
func _apply_field_effects_to_entity(entity: Node) -> void:
	# Speed modifiers
	var speed_mod = get_movement_speed_modifier()

	if entity.has_method("modify_speed"):
		entity.modify_speed(speed_mod)

## Remove field effects when entity exits
func _remove_field_effects_from_entity(entity: Node) -> void:
	# Reset speed
	if entity.has_method("modify_speed"):
		entity.modify_speed(1.0)

## Handle field expiration
func _expire_field() -> void:
	var expired_field = current_field

	field_expired.emit(expired_field)

	# Revert to default
	current_field = default_field
	current_duration = 0.0

	_update_field_visuals()

	if debug_field:
		print("[BattleFieldComponent] Field expired: %s -> %s" % [
			FieldType.keys()[expired_field], FieldType.keys()[default_field]
		])

## Update visual field effects
func _update_field_visuals() -> void:
	if not visual_field_effect:
		return

	# Apply color tint
	if visual_field_effect is CanvasItem and field_colors.has(current_field):
		visual_field_effect.modulate = field_colors[current_field]

	# Show/hide based on field type
	if current_field == FieldType.NORMAL:
		visual_field_effect.visible = false
	else:
		visual_field_effect.visible = true
#endregion

#region Debug Methods
## Print field state
func debug_print_state() -> void:
	print("=== Battle Field State ===")
	print("Current Field: %s" % get_field_name())
	print("Duration Remaining: %.1fs" % get_remaining_duration())
	print("Entities on Field: %d" % _entities_on_field.size())
	print("Movement Speed Modifier: %.2fx" % get_movement_speed_modifier())
	print("Tick Interval: %.1fs" % tick_interval)
	print("Field Damage per Tick: %.1f" % field_damage_per_tick)
	print("========================")
#endregion
