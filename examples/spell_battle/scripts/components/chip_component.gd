## Chip Component
##
## Game-specific component that represents a battle chip/spell entity in the battlefield.
## Manages chip HP, interactions with other chips, and chip-specific behavior.
##
## This component:
## - Tracks individual chip HP (chips can be destroyed)
## - Handles chip-to-chip collisions
## - Manages chip lifetime and destruction
## - Provides targeting for CHIP_DESTROYER type attacks
##
## @tutorial(Spell Battle): res://examples/spell_battle/README.md

class_name ChipComponent extends Component

#region Signals
## Emitted when chip HP changes
signal chip_hp_changed(current_hp: int, max_hp: int)

## Emitted when chip is destroyed
signal chip_destroyed()

## Emitted when chip damages another chip
signal chip_damaged_chip(target_chip: Node, damage: int)

## Emitted when chip damages a Navi
signal chip_damaged_navi(target_navi: Node, damage: int)

## Emitted when chip collides with another chip
signal chip_collision(other_chip: Node)
#endregion

#region Exports
@export_group("Chip Data")
## The chip data resource
@export var chip_data: ChipData

## Owner Navi (who cast this chip)
@export var owner_navi: Node

@export_group("Behavior")
## Whether this chip can be destroyed by taking damage
@export var can_be_destroyed: bool = true

## Whether this chip can damage other chips
@export var can_damage_chips: bool = true

## Whether this chip collides with other chips
@export var collides_with_chips: bool = true

@export_group("Visuals")
## Visual representation (Sprite2D, AnimatedSprite2D, etc.)
@export var visual_node: Node2D

@export_group("Advanced")
## Whether to print debug messages
@export var debug_chip: bool = false
#endregion

#region Private Variables
## Current chip HP
var _current_chip_hp: int = 0

## Whether chip is active
var _is_active: bool = false

## Whether chip has been destroyed
var _is_destroyed: bool = false

## Chips this chip has already hit (to prevent multi-hit)
var _hit_chips: Array[Node] = []

## Navis this chip has already hit
var _hit_navis: Array[Node] = []
#endregion

#region Component Lifecycle
func component_ready() -> void:
	if chip_data:
		_current_chip_hp = chip_data.chip_hp
		_is_active = true

		# Apply chip color if visual node exists
		if visual_node and visual_node is CanvasItem:
			visual_node.modulate = chip_data.chip_color

		if debug_chip:
			print("[ChipComponent] Ready: %s (HP: %d/%d)" % [
				chip_data.chip_name, _current_chip_hp, chip_data.max_chip_hp
			])
	else:
		push_warning("[ChipComponent] No chip_data assigned!")

func cleanup() -> void:
	_is_active = false
	super.cleanup()
#endregion

#region Public Methods - HP Management
## Damage this chip
## @param damage: Amount of damage to deal
## @param source: Source of damage (optional)
## @returns: true if chip was destroyed
func take_damage(damage: int, source: Node = null) -> bool:
	if not can_be_destroyed or _is_destroyed:
		return false

	_current_chip_hp -= damage

	if _current_chip_hp < 0:
		_current_chip_hp = 0

	chip_hp_changed.emit(_current_chip_hp, chip_data.max_chip_hp)

	if debug_chip:
		var source_name = source.name if source else "Unknown"
		print("[ChipComponent] %s took %d damage from %s (HP: %d/%d)" % [
			chip_data.chip_name, damage, source_name, _current_chip_hp, chip_data.max_chip_hp
		])

	# Check if destroyed
	if _current_chip_hp <= 0:
		destroy_chip()
		return true

	return false

## Heal this chip
## @param heal_amount: Amount to heal
func heal(heal_amount: int) -> void:
	if _is_destroyed:
		return

	_current_chip_hp += heal_amount

	if _current_chip_hp > chip_data.max_chip_hp:
		_current_chip_hp = chip_data.max_chip_hp

	chip_hp_changed.emit(_current_chip_hp, chip_data.max_chip_hp)

	if debug_chip:
		print("[ChipComponent] %s healed %d HP (HP: %d/%d)" % [
			chip_data.chip_name, heal_amount, _current_chip_hp, chip_data.max_chip_hp
		])

## Destroy this chip
func destroy_chip() -> void:
	if _is_destroyed:
		return

	_is_destroyed = true
	_is_active = false

	chip_destroyed.emit()

	if debug_chip:
		print("[ChipComponent] %s destroyed!" % chip_data.chip_name)

	# Queue free the host entity
	if host:
		host.queue_free()

## Get current chip HP
## @returns: Current HP
func get_current_hp() -> int:
	return _current_chip_hp

## Get max chip HP
## @returns: Max HP
func get_max_hp() -> int:
	if chip_data:
		return chip_data.max_chip_hp
	return 0

## Get HP percentage
## @returns: HP percentage (0.0 to 1.0)
func get_hp_percentage() -> float:
	if chip_data.max_chip_hp <= 0:
		return 0.0
	return float(_current_chip_hp) / float(chip_data.max_chip_hp)

## Check if chip is destroyed
## @returns: true if destroyed
func is_destroyed() -> bool:
	return _is_destroyed
#endregion

#region Public Methods - Combat
## Deal damage to another chip
## @param target_chip: Target ChipComponent
## @returns: true if target was destroyed
func damage_chip(target_chip: ChipComponent) -> bool:
	if not can_damage_chips or not chip_data:
		return false

	# Prevent hitting same chip multiple times
	if target_chip.host in _hit_chips:
		return false

	_hit_chips.append(target_chip.host)

	var damage = chip_data.damage

	# Apply bonus damage if this is a CHIP_DESTROYER type
	if chip_data.chip_type == ChipData.ChipType.CHIP_DESTROYER:
		damage = int(damage * 1.5)  # 50% bonus vs chips

	var destroyed = target_chip.take_damage(damage, host)

	chip_damaged_chip.emit(target_chip.host, damage)

	if debug_chip:
		print("[ChipComponent] %s damaged %s for %d (Destroyed: %s)" % [
			chip_data.chip_name, target_chip.chip_data.chip_name, damage, destroyed
		])

	return destroyed

## Deal damage to a Navi
## @param target_navi: Target node (should have NaviComponent or similar)
## @param apply_element_modifier: Whether to apply elemental damage modifiers
## @returns: Actual damage dealt
func damage_navi(target_navi: Node, apply_element_modifier: bool = true) -> int:
	if not chip_data:
		return 0

	# Prevent hitting same navi multiple times
	if target_navi in _hit_navis:
		return 0

	_hit_navis.append(target_navi)

	var damage = chip_data.damage

	# Apply elemental modifiers if target has NaviData
	if apply_element_modifier and target_navi.has_method("get_navi_data"):
		var navi_data: NaviData = target_navi.get_navi_data()
		if navi_data:
			damage = navi_data.get_modified_damage(damage, chip_data.element)

	# Apply damage to target
	if target_navi.has_method("take_damage"):
		target_navi.take_damage(damage, host)

	chip_damaged_navi.emit(target_navi, damage)

	if debug_chip:
		print("[ChipComponent] %s damaged Navi %s for %d" % [
			chip_data.chip_name, target_navi.name, damage
		])

	return damage

## Handle collision with another chip
## @param other_chip: Other ChipComponent
func on_chip_collision(other_chip: ChipComponent) -> void:
	if not collides_with_chips:
		return

	chip_collision.emit(other_chip.host)

	# Melee chips destroy on collision
	if chip_data.chip_type == ChipData.ChipType.MELEE:
		damage_chip(other_chip)
		destroy_chip()

	# Projectiles damage each other
	elif chip_data.chip_type == ChipData.ChipType.PROJECTILE:
		damage_chip(other_chip)
		other_chip.damage_chip(self)

	if debug_chip:
		print("[ChipComponent] %s collided with %s" % [
			chip_data.chip_name, other_chip.chip_data.chip_name
		])

## Reset hit tracking (for chips that can hit multiple times)
func reset_hit_tracking() -> void:
	_hit_chips.clear()
	_hit_navis.clear()
#endregion

#region Public Methods - Queries
## Check if chip is active
## @returns: true if active
func is_active() -> bool:
	return _is_active

## Get chip data
## @returns: ChipData resource
func get_chip_data() -> ChipData:
	return chip_data

## Get owner Navi
## @returns: Owner Navi node
func get_owner_navi() -> Node:
	return owner_navi

## Check if chip has hit a specific target
## @param target: Target node
## @returns: true if already hit
func has_hit_target(target: Node) -> bool:
	return target in _hit_chips or target in _hit_navis

## Get chip type
## @returns: ChipType enum value
func get_chip_type() -> ChipData.ChipType:
	if chip_data:
		return chip_data.chip_type
	return ChipData.ChipType.PROJECTILE

## Get chip element
## @returns: ElementType enum value
func get_element() -> ChipData.ElementType:
	if chip_data:
		return chip_data.element
	return ChipData.ElementType.NONE

## Get chip attack range
## @returns: AttackRange enum value
func get_attack_range() -> ChipData.AttackRange:
	if chip_data:
		return chip_data.attack_range
	return ChipData.AttackRange.RANGED
#endregion

#region Debug Methods
## Print chip state
func debug_print_state() -> void:
	if not chip_data:
		print("=== Chip Component (NO DATA) ===")
		return

	print("=== Chip Component State ===")
	print("Name: %s" % chip_data.chip_name)
	print("Type: %s" % chip_data.get_chip_type_name())
	print("Element: %s" % chip_data.get_element_name())
	print("HP: %d / %d (%.1f%%)" % [_current_chip_hp, chip_data.max_chip_hp, get_hp_percentage() * 100])
	print("Damage: %d" % chip_data.damage)
	print("Active: %s" % _is_active)
	print("Destroyed: %s" % _is_destroyed)
	print("Hits Tracked: %d chips, %d navis" % [_hit_chips.size(), _hit_navis.size()])
	print("==========================")
#endregion
