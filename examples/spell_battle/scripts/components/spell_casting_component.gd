## Spell Casting Component
##
## Game-specific component that handles spell/chip casting mechanics.
## Manages chip instantiation, targeting, and spell lifecycle.
##
## Features:
## - Cast chips from ChipData
## - Targeting system integration
## - Spell projectile spawning
## - Area of effect handling
## - Melee attack execution
## - Spell pooling/cleanup
##
## @tutorial(Spell Battle): res://examples/spell_battle/README.md

class_name SpellCastingComponent extends Component

#region Signals
## Emitted when a spell is cast
signal spell_cast(chip_data: ChipData, target: Variant)

## Emitted when spell hits target
signal spell_hit(chip_entity: Node, target: Node, damage: int)

## Emitted when spell misses
signal spell_missed(chip_entity: Node)

## Emitted when area spell activates
signal area_spell_activated(chip_data: ChipData, position: Vector2, radius: float)

## Emitted when casting fails
signal cast_failed(reason: String)
#endregion

#region Exports
@export_group("Casting Settings")
## Reference to caster Navi
@export var caster: Node

## Default spawn offset from caster
@export var spawn_offset: Vector2 = Vector2(50, 0)

## Whether to use targeting component
@export var use_targeting: bool = true

@export_group("Spell Scenes")
## Default projectile scene (if chip has no spell_scene)
@export var default_projectile_scene: PackedScene

## Default melee attack scene
@export var default_melee_scene: PackedScene

## Default area effect scene
@export var default_area_scene: PackedScene

@export_group("World")
## Parent node for spawning spells (battlefield, etc.)
@export var spell_container: Node

@export_group("Advanced")
## Whether to print debug messages
@export var debug_casting: bool = false
#endregion

#region Private Variables
## Reference to TargetingComponent
var _targeting: TargetingComponent = null

## Active spells spawned by this caster
var _active_spells: Array[Node] = []

## Reference to caster NaviComponent
var _caster_navi: NaviComponent = null
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
	# Find targeting component
	if use_targeting and host:
		for child in host.get_children():
			if child is TargetingComponent:
				_targeting = child
				break

	# Find caster NaviComponent
	if caster:
		_caster_navi = _get_navi_component(caster)

	# Set default spell container to current scene root
	if not spell_container:
		spell_container = get_tree().current_scene

	if debug_casting:
		print("[SpellCasting] Ready. Caster: %s" % (caster.name if caster else "None"))
		print("  Has Targeting: %s" % (_targeting != null))

func cleanup() -> void:
	# Clean up active spells
	for spell in _active_spells:
		if is_instance_valid(spell):
			spell.queue_free()
	_active_spells.clear()

	super.cleanup()
#endregion

#region Public Methods - Casting
## Cast a chip/spell
## @param chip_data: ChipData to cast
## @param target: Target (Node, Vector2, or null for self-target)
## @returns: Spawned spell entity or null
func cast_spell(chip_data: ChipData, target: Variant = null) -> Node:
	if not chip_data:
		cast_failed.emit("No chip data provided")
		return null

	if not caster:
		cast_failed.emit("No caster assigned")
		return null

	# Validate target based on chip type
	if not _validate_target(chip_data, target):
		cast_failed.emit("Invalid target for chip type")
		return null

	# Cast based on chip type
	var spell_entity: Node = null

	match chip_data.chip_type:
		ChipData.ChipType.PROJECTILE:
			spell_entity = _cast_projectile(chip_data, target)

		ChipData.ChipType.MELEE:
			spell_entity = await _cast_melee(chip_data, target)

		ChipData.ChipType.AREA_DAMAGE:
			spell_entity = await _cast_area_damage(chip_data, target)

		ChipData.ChipType.BUFF:
			_apply_buff(chip_data, target)

		ChipData.ChipType.SHIELD:
			_apply_shield(chip_data, target)

		ChipData.ChipType.TRANSFORM_AREA:
			_transform_area(chip_data, target)

		ChipData.ChipType.CHIP_DESTROYER:
			spell_entity = _cast_chip_destroyer(chip_data, target)

		_:
			cast_failed.emit("Unknown chip type")
			return null

	# Register chip usage with Navi
	if _caster_navi:
		_caster_navi.register_chip_used()

	spell_cast.emit(chip_data, target)

	if debug_casting:
		print("[SpellCasting] %s cast %s (Type: %s)" % [
			caster.name,
			chip_data.chip_name,
			chip_data.get_chip_type_name()
		])

	return spell_entity

## Cast default attack (when 3 chips used)
## @param target: Target node
## @returns: Spawned attack entity
func cast_default_attack(target: Node) -> Node:
	if not _caster_navi or not _caster_navi.navi_data:
		return null

	# Create temporary ChipData for default attack
	var default_chip = ChipData.new()
	default_chip.chip_name = "Default Attack"
	default_chip.chip_type = _caster_navi.navi_data.default_attack_type
	default_chip.damage = _caster_navi.navi_data.default_attack_damage
	default_chip.element = _caster_navi.navi_data.default_attack_element
	default_chip.attack_range = _caster_navi.navi_data.default_attack_range
	default_chip.chip_hp = 50  # Default HP
	default_chip.max_chip_hp = 50

	return await cast_spell(default_chip, target)
#endregion

#region Private Methods - Spell Types
## Cast projectile spell
func _cast_projectile(chip_data: ChipData, target: Variant) -> Node:
	var spell_scene = chip_data.spell_scene if chip_data.spell_scene else default_projectile_scene

	if not spell_scene:
		push_warning("[SpellCasting] No projectile scene for %s" % chip_data.chip_name)
		return null

	var spell = spell_scene.instantiate()
	spell_container.add_child(spell)

	# Position spell
	if caster is Node2D:
		spell.global_position = caster.global_position + spawn_offset

	# Setup ChipComponent
	var chip_comp = _get_chip_component(spell)
	if chip_comp:
		chip_comp.chip_data = chip_data
		chip_comp.owner_navi = caster

	# Set target/direction if spell has target property
	if target and spell.has_method("set_target"):
		spell.set_target(target)
	elif target is Vector2 and spell.has_method("set_direction"):
		var direction = (target - spell.global_position).normalized()
		spell.set_direction(direction)

	_active_spells.append(spell)
	return spell

## Cast melee attack
func _cast_melee(chip_data: ChipData, target: Variant) -> Node:
	# Melee is instant - deal damage directly to target
	if target is Node:
		_deal_damage_to_target(target, chip_data)

	# Optionally spawn visual effect
	var spell_scene = chip_data.spell_scene if chip_data.spell_scene else default_melee_scene

	if spell_scene:
		var effect = spell_scene.instantiate()
		spell_container.add_child(effect)

		# Position at target
		if target is Node and target is Node2D:
			effect.global_position = target.global_position
		elif caster is Node2D:
			effect.global_position = caster.global_position + spawn_offset

		# Auto-cleanup after animation
		if effect.has_signal("animation_finished"):
			effect.animation_finished.connect(func(): effect.queue_free())
		else:
			# Cleanup after 1 second
			await get_tree().create_timer(1.0).timeout
			effect.queue_free()

		return effect

	return null

## Cast area damage spell
func _cast_area_damage(chip_data: ChipData, target: Variant) -> Node:
	var position = Vector2.ZERO

	if target is Vector2:
		position = target
	elif target is Node and target is Node2D:
		position = target.global_position
	elif caster is Node2D:
		position = caster.global_position + spawn_offset

	# Get targets in area
	var radius = chip_data.area_radius if chip_data.area_radius > 0 else 100.0
	var targets_in_area: Array[Node] = []

	if _targeting:
		targets_in_area = _targeting.get_targets_in_area(position, radius)

	# Deal damage to all targets
	for t in targets_in_area:
		_deal_damage_to_target(t, chip_data)

	area_spell_activated.emit(chip_data, position, radius)

	# Spawn visual effect
	var spell_scene = chip_data.spell_scene if chip_data.spell_scene else default_area_scene

	if spell_scene:
		var effect = spell_scene.instantiate()
		spell_container.add_child(effect)
		effect.global_position = position

		# Auto-cleanup
		await get_tree().create_timer(2.0).timeout
		if is_instance_valid(effect):
			effect.queue_free()

		return effect

	return null

## Apply buff
func _apply_buff(chip_data: ChipData, target: Variant) -> void:
	var buff_target = target if target is Node else caster

	# Look for StatusEffectComponent on target
	var status_comp = _get_status_effect_component(buff_target)

	if status_comp:
		status_comp.apply_effect(
			chip_data.chip_name,
			StatusEffectComponent.EffectType.BUFF,
			chip_data.effect_duration,
			chip_data.stat_modifiers,
			0.0, 0.0, 1,
			caster
		)

		if debug_casting:
			print("[SpellCasting] Applied buff: %s to %s" % [chip_data.chip_name, buff_target.name])

## Apply shield
func _apply_shield(chip_data: ChipData, target: Variant) -> void:
	# Shield is implemented as a BUFF with defense stat modifier
	var shield_target = target if target is Node else caster

	var status_comp = _get_status_effect_component(shield_target)

	if status_comp:
		# Shield adds defense modifier based on chip HP
		var shield_defense = {"defense": chip_data.chip_hp}

		status_comp.apply_effect(
			chip_data.chip_name,
			StatusEffectComponent.EffectType.BUFF,
			chip_data.effect_duration,
			shield_defense,
			0.0, 0.0, 1,
			caster
		)

		if debug_casting:
			print("[SpellCasting] Applied shield: %s to %s (Defense: +%d)" % [
				chip_data.chip_name, shield_target.name, chip_data.chip_hp
			])

## Transform battlefield area
func _transform_area(chip_data: ChipData, target: Variant) -> void:
	# Find BattleFieldComponent
	var battlefield = _find_battle_field_component()

	if battlefield:
		# Map chip field_effect string to FieldType enum
		var field_type = _get_field_type_from_string(chip_data.field_effect)

		battlefield.transform_field(field_type, chip_data.field_duration)

		if debug_casting:
			print("[SpellCasting] Transformed field to %s for %.1fs" % [
				chip_data.field_effect, chip_data.field_duration
			])

## Cast chip destroyer
func _cast_chip_destroyer(chip_data: ChipData, target: Variant) -> Node:
	# Similar to projectile but targets enemy chips
	return _cast_projectile(chip_data, target)
#endregion

#region Private Methods - Helpers
## Validate target for chip type
func _validate_target(chip_data: ChipData, target: Variant) -> bool:
	match chip_data.target_type:
		ChipData.TargetType.SELF:
			return target == null or target == caster
		ChipData.TargetType.ENEMY_NAVI, ChipData.TargetType.ENEMY_CHIP:
			return target is Node or target is Vector2
		ChipData.TargetType.FIELD:
			return true
		_:
			return true

## Deal damage to target
func _deal_damage_to_target(target: Node, chip_data: ChipData) -> void:
	# Check if target has NaviComponent
	var navi_comp = _get_navi_component(target)
	if navi_comp:
		var damage = navi_comp.take_damage(chip_data.damage, caster, chip_data.element)
		spell_hit.emit(null, target, damage)
		return

	# Check if target has ChipComponent
	var chip_comp = _get_chip_component(target)
	if chip_comp:
		chip_comp.take_damage(chip_data.damage, caster)
		spell_hit.emit(null, target, chip_data.damage)
		return

	# Fallback: call take_damage method directly
	if target.has_method("take_damage"):
		target.take_damage(chip_data.damage, caster)

## Get NaviComponent from entity
func _get_navi_component(entity: Node) -> NaviComponent:
	if not entity:
		return null

	for child in entity.get_children():
		if child is NaviComponent:
			return child
	return null

## Get ChipComponent from entity
func _get_chip_component(entity: Node) -> ChipComponent:
	if not entity:
		return null

	for child in entity.get_children():
		if child is ChipComponent:
			return child
	return null

## Get StatusEffectComponent from entity
func _get_status_effect_component(entity: Node) -> StatusEffectComponent:
	if not entity:
		return null

	for child in entity.get_children():
		if child is StatusEffectComponent:
			return child
	return null

## Find BattleFieldComponent in scene
func _find_battle_field_component() -> BattleFieldComponent:
	# Look in scene root children
	var root = get_tree().current_scene
	if not root:
		return null

	for child in root.get_children():
		if child is BattleFieldComponent:
			return child

		# Also check nested children
		for nested in child.get_children():
			if nested is BattleFieldComponent:
				return nested

	return null

## Map field effect string to FieldType enum
func _get_field_type_from_string(field_effect: String) -> BattleFieldComponent.FieldType:
	match field_effect.to_lower():
		"fire":
			return BattleFieldComponent.FieldType.FIRE
		"ice":
			return BattleFieldComponent.FieldType.ICE
		"electric":
			return BattleFieldComponent.FieldType.ELECTRIC
		"poison":
			return BattleFieldComponent.FieldType.POISON
		"wood":
			return BattleFieldComponent.FieldType.WOOD
		"wind":
			return BattleFieldComponent.FieldType.WIND
		_:
			return BattleFieldComponent.FieldType.NORMAL
#endregion

#region Debug Methods
## Print casting state
func debug_print_state() -> void:
	print("=== Spell Casting State ===")
	print("Caster: %s" % (caster.name if caster else "None"))
	print("Has Targeting: %s" % (_targeting != null))
	print("Active Spells: %d" % _active_spells.size())
	print("Spell Container: %s" % (spell_container.name if spell_container else "None"))
	print("=========================")
#endregion
