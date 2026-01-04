## Weapon Slot Manager Component
##
## Manages multiple weapon slots for a player/entity.
## Supports PRIMARY, SECONDARY, and SPECIAL weapon categories with independent firing.
##
## Features:
## - 3 independent weapon slots with different categories
## - Per-slot input handling (fire_primary, fire_secondary, fire_special)
## - Ammo management with phase-based refilling
## - Weapon swapping/upgrading via WeaponData resources
## - UI feedback via signals
##
## @tutorial(Combat System): res://docs/components/combat.md

class_name WeaponSlotManager extends Component

#region Signals
## Emitted when any weapon fires
signal weapon_fired(slot: int, weapon_name: String)

## Emitted when weapon ammo changes
signal ammo_changed(slot: int, current: int, maximum: int)

## Emitted when weapon is swapped
signal weapon_swapped(slot: int, weapon_data: WeaponData)

## Emitted when trying to fire empty weapon
signal weapon_empty(slot: int)

## Emitted when all weapons ready (for UI indicators)
signal weapons_ready_changed()

## Emitted when SECONDARY weapon is toggled on/off
signal secondary_toggled(enabled: bool)
#endregion

#region Exports
@export_group("Weapon Slots")
## PRIMARY weapon (Slot 0) - infinite ammo, always active
@export var primary_weapon: WeaponData

## SECONDARY weapon (Slot 1) - moderate cooldown/ammo
@export var secondary_weapon: WeaponData

## SPECIAL weapon (Slot 2) - limited ammo, refills on phase change
@export var special_weapon: WeaponData

@export_group("Input Actions")
## Input action for primary + secondary weapons (fires both simultaneously)
@export var primary_secondary_action: String = "fire"

## Input action for special weapon (independent)
@export var special_action: String = "fire_special"

@export_group("Weapon Components")
## Paths to WeaponComponent nodes (will be created if empty)
@export var primary_weapon_path: NodePath = NodePath()
@export var secondary_weapon_path: NodePath = NodePath()
@export var special_weapon_path: NodePath = NodePath()

@export_group("Advanced")
## Whether to handle input automatically (set false for AI control)
@export var auto_handle_input: bool = true

## Whether SECONDARY weapon is enabled (can be toggled on/off)
@export var secondary_enabled: bool = true

## Whether to print debug messages
@export var debug_slots: bool = false
#endregion

#region Private Variables
## Weapon component references [PRIMARY, SECONDARY, SPECIAL]
var _weapon_slots: Array[WeaponComponent] = [null, null, null]

## Weapon data references [PRIMARY, SECONDARY, SPECIAL]
var _weapon_data: Array[WeaponData] = [null, null, null]

## Current ammo per slot [PRIMARY, SECONDARY, SPECIAL]
var _current_ammo: Array[int] = [-1, -1, -1]

## Maximum ammo per slot
var _max_ammo: Array[int] = [-1, -1, -1]

## Whether each slot is ready to fire
var _ready_to_fire: Array[bool] = [true, true, true]

## Reference to EntityPoolManager
var _pool_manager: Node = null

## Container for projectiles
var _projectiles_container: Node = null
#endregion

#region Component Lifecycle
func initialize(host_node: ComponentHost) -> void:
	super.initialize(host_node)

	# Store initial weapon data
	_weapon_data[WeaponData.Category.PRIMARY] = primary_weapon
	_weapon_data[WeaponData.Category.SECONDARY] = secondary_weapon
	_weapon_data[WeaponData.Category.SPECIAL] = special_weapon

func component_ready() -> void:
	# Setup weapon components
	_setup_weapon_slots()

	# Find pool manager
	_pool_manager = get_node_or_null("/root/EntityPoolManager")

	# Find projectiles container
	_setup_projectiles_container()

	# Apply initial weapon configurations
	for slot in range(3):
		if _weapon_data[slot]:
			_apply_weapon_data(slot, _weapon_data[slot])

	# Connect to phase system for ammo refill
	_connect_to_phase_system()

	if debug_slots:
		print("[WeaponSlotManager] Ready - Slots configured:")
		for i in range(3):
			if _weapon_data[i]:
				print("  Slot %d (%s): %s" % [i, WeaponData.Category.keys()[i], _weapon_data[i].weapon_name])

func component_process(delta: float) -> void:
	# Handle input if auto mode is enabled
	if auto_handle_input:
		_handle_input()

	# Update ready states for UI
	_update_ready_states()

	# Note: WeaponComponents are added as components to the host,
	# so ComponentHost automatically calls their component_process()
	# We don't need to manually process them here

func cleanup() -> void:
	_weapon_slots.clear()
	_weapon_data.clear()
	_pool_manager = null
	_projectiles_container = null
	super.cleanup()
#endregion

#region Public Methods - Firing
## Fire weapon in specific slot
##
## @param slot: Slot index (0=PRIMARY, 1=SECONDARY, 2=SPECIAL)
## @returns: true if weapon fired successfully
func fire_weapon(slot: int) -> bool:
	if slot < 0 or slot >= 3:
		push_warning("[WeaponSlotManager] Invalid slot: %d" % slot)
		return false

	var weapon = _weapon_slots[slot]
	if not weapon:
		if debug_slots:
			print("[WeaponSlotManager] No weapon in slot %d" % slot)
		return false

	# Check ammo
	if _weapon_data[slot] and _weapon_data[slot].uses_ammo():
		if _current_ammo[slot] <= 0:
			weapon_empty.emit(slot)
			if debug_slots:
				print("[WeaponSlotManager] Slot %d empty!" % slot)
			return false

	# Try to fire
	var fired = await weapon.fire()

	if fired:
		# Consume ammo if applicable
		if _weapon_data[slot] and _weapon_data[slot].uses_ammo():
			_current_ammo[slot] -= 1
			ammo_changed.emit(slot, _current_ammo[slot], _max_ammo[slot])

			if debug_slots:
				print("[WeaponSlotManager] Slot %d fired - Ammo: %d/%d" % [
					slot, _current_ammo[slot], _max_ammo[slot]
				])

		# Emit signal
		var weapon_name = _weapon_data[slot].weapon_name if _weapon_data[slot] else "Unknown"
		weapon_fired.emit(slot, weapon_name)

	return fired

## Fire primary weapon (slot 0)
func fire_primary() -> bool:
	return await fire_weapon(WeaponData.Category.PRIMARY)

## Fire secondary weapon (slot 1)
func fire_secondary() -> bool:
	return await fire_weapon(WeaponData.Category.SECONDARY)

## Fire special weapon (slot 2)
func fire_special() -> bool:
	return await fire_weapon(WeaponData.Category.SPECIAL)

## Fire primary and secondary weapons simultaneously
## Uses Strategy Pattern for combined firing behavior
##
## @returns: Dictionary with results {primary: bool, secondary: bool}
func fire_primary_and_secondary() -> Dictionary:
	var results = {
		"primary": false,
		"secondary": false
	}

	# Fire both weapons using Combined Firing Strategy
	# This follows Single Responsibility - each weapon fires independently
	# but the combination is managed here
	#
	# Note: GDScript coroutines execute sequentially when awaited,
	# but firing is fast enough that this appears simultaneous to the player

	# Fire PRIMARY weapon (always fires)
	if _weapon_slots[WeaponData.Category.PRIMARY]:
		results.primary = await fire_weapon(WeaponData.Category.PRIMARY)

	# Fire SECONDARY weapon (only if enabled)
	# This implements Strategy Pattern - conditional firing based on state
	if _weapon_slots[WeaponData.Category.SECONDARY] and secondary_enabled:
		results.secondary = await fire_weapon(WeaponData.Category.SECONDARY)
	elif debug_slots and not secondary_enabled:
		print("[WeaponSlotManager] SECONDARY disabled - not firing")

	return results
#endregion

#region Public Methods - Weapon Management
## Equip weapon in specific slot
##
## @param slot: Slot index (0=PRIMARY, 1=SECONDARY, 2=SPECIAL)
## @param weapon_data: WeaponData resource to equip
## @returns: true if equipped successfully
func equip_weapon(slot: int, weapon_data: WeaponData) -> bool:
	if slot < 0 or slot >= 3:
		push_warning("[WeaponSlotManager] Invalid slot: %d" % slot)
		return false

	# Validate category
	if weapon_data and weapon_data.category != slot:
		push_warning("[WeaponSlotManager] Weapon category mismatch - Weapon is %s but slot is %s" % [
			WeaponData.Category.keys()[weapon_data.category],
			WeaponData.Category.keys()[slot]
		])
		return false

	# Store weapon data
	_weapon_data[slot] = weapon_data

	# Apply to component
	if weapon_data:
		_apply_weapon_data(slot, weapon_data)

	# Emit signal
	weapon_swapped.emit(slot, weapon_data)

	if debug_slots:
		print("[WeaponSlotManager] Equipped '%s' in slot %d" % [
			weapon_data.weapon_name if weapon_data else "None",
			slot
		])

	return true

## Get weapon data from slot
func get_weapon_data(slot: int) -> WeaponData:
	if slot < 0 or slot >= 3:
		return null
	return _weapon_data[slot]

## Get weapon component from slot
func get_weapon_component(slot: int) -> WeaponComponent:
	if slot < 0 or slot >= 3:
		return null
	return _weapon_slots[slot]
#endregion

#region Public Methods - Ammo Management
## Add ammo to specific slot
##
## @param slot: Slot index
## @param amount: Amount to add
## @returns: Actual amount added
func add_ammo(slot: int, amount: int) -> int:
	if slot < 0 or slot >= 3:
		return 0

	if not _weapon_data[slot] or not _weapon_data[slot].uses_ammo():
		return 0

	var old_ammo = _current_ammo[slot]
	_current_ammo[slot] = mini(_current_ammo[slot] + amount, _max_ammo[slot])
	var added = _current_ammo[slot] - old_ammo

	if added > 0:
		ammo_changed.emit(slot, _current_ammo[slot], _max_ammo[slot])

		if debug_slots:
			print("[WeaponSlotManager] Slot %d ammo +%d (now %d/%d)" % [
				slot, added, _current_ammo[slot], _max_ammo[slot]
			])

	return added

## Refill ammo for specific slot
func refill_ammo(slot: int) -> void:
	if slot < 0 or slot >= 3:
		return

	if _weapon_data[slot] and _weapon_data[slot].uses_ammo():
		_current_ammo[slot] = _max_ammo[slot]
		ammo_changed.emit(slot, _current_ammo[slot], _max_ammo[slot])

		if debug_slots:
			print("[WeaponSlotManager] Slot %d refilled to %d" % [slot, _max_ammo[slot]])

## Refill ammo for all slots that should refill on phase change
func refill_on_phase_change() -> void:
	for slot in range(3):
		if _weapon_data[slot] and _weapon_data[slot].should_refill_on_phase():
			refill_ammo(slot)

			if debug_slots:
				print("[WeaponSlotManager] Phase refill - Slot %d (%s)" % [
					slot, _weapon_data[slot].weapon_name
				])

## Get current ammo for slot
func get_ammo(slot: int) -> int:
	if slot < 0 or slot >= 3:
		return -1
	return _current_ammo[slot]

## Get max ammo for slot
func get_max_ammo(slot: int) -> int:
	if slot < 0 or slot >= 3:
		return -1
	return _max_ammo[slot]
#endregion

#region Public Methods - Queries
## Check if weapon in slot is ready to fire
func is_weapon_ready(slot: int) -> bool:
	if slot < 0 or slot >= 3:
		return false
	return _ready_to_fire[slot]

## Get all weapons ready state as array
func get_all_weapons_ready() -> Array[bool]:
	return _ready_to_fire.duplicate()

## Check if SECONDARY weapon is enabled
func is_secondary_enabled() -> bool:
	return secondary_enabled
#endregion

#region Public Methods - Weapon Toggle
## Toggle SECONDARY weapon on/off
## This allows player to conserve ammo by disabling SECONDARY
## Follows Command Pattern - encapsulates toggle action
##
## @returns: New enabled state
func toggle_secondary_weapon() -> bool:
	secondary_enabled = not secondary_enabled

	# Observer Pattern: Notify listeners of state change
	secondary_toggled.emit(secondary_enabled)

	if debug_slots:
		print("[WeaponSlotManager] SECONDARY weapon %s" % ("ENABLED" if secondary_enabled else "DISABLED"))

	return secondary_enabled

## Enable SECONDARY weapon
func enable_secondary_weapon() -> void:
	if not secondary_enabled:
		toggle_secondary_weapon()

## Disable SECONDARY weapon
func disable_secondary_weapon() -> void:
	if secondary_enabled:
		toggle_secondary_weapon()

## Set SECONDARY enabled state directly
func set_secondary_enabled(enabled: bool) -> void:
	if secondary_enabled != enabled:
		secondary_enabled = enabled
		secondary_toggled.emit(secondary_enabled)

		if debug_slots:
			print("[WeaponSlotManager] SECONDARY weapon set to %s" % ("ENABLED" if enabled else "DISABLED"))

#region Private Methods - Setup
## Setup weapon slot components
func _setup_weapon_slots() -> void:
	var paths = [primary_weapon_path, secondary_weapon_path, special_weapon_path]

	for i in range(3):
		# Try to find existing weapon component
		if not paths[i].is_empty():
			_weapon_slots[i] = get_node_or_null(paths[i])

		# If not found, create new WeaponComponent
		if not _weapon_slots[i]:
			_weapon_slots[i] = _create_weapon_component(i)

		# Connect signals
		if _weapon_slots[i]:
			_weapon_slots[i].weapon_fired.connect(_on_weapon_fired.bind(i))
			_weapon_slots[i].out_of_ammo.connect(_on_weapon_out_of_ammo.bind(i))

## Create weapon component for slot
func _create_weapon_component(slot: int) -> WeaponComponent:
	var weapon = WeaponComponent.new()
	weapon.name = "WeaponSlot%d" % slot
	weapon.debug_weapon = debug_slots

	# Add as component to host (this ensures component_process is called)
	# Using add_component instead of add_child ensures proper Component lifecycle
	if host:
		host.add_component(weapon)
		if debug_slots:
			print("[WeaponSlotManager] Added WeaponComponent for slot %d to host" % slot)

	return weapon

## Setup projectiles container
func _setup_projectiles_container() -> void:
	var containers = get_tree().get_nodes_in_group("ProjectilesContainer")
	if containers.size() > 0:
		_projectiles_container = containers[0]
	else:
		_projectiles_container = get_tree().root

	# Set container for all weapon slots
	for weapon in _weapon_slots:
		if weapon:
			weapon.set_projectiles_container(_projectiles_container)

## Connect to phase system for ammo refill
func _connect_to_phase_system() -> void:
	# Try to find PhaseManager
	var phase_manager = get_node_or_null("/root/PhaseManager")
	if not phase_manager:
		# Try to find in scene tree
		phase_manager = get_tree().get_first_node_in_group("phase_manager")

	if phase_manager:
		# Connect to phase changed signal
		if phase_manager.has_signal("phase_changed"):
			phase_manager.phase_changed.connect(_on_phase_changed)

			if debug_slots:
				print("[WeaponSlotManager] Connected to PhaseManager for ammo refill")
	else:
		if debug_slots:
			print("[WeaponSlotManager] PhaseManager not found - auto refill disabled")
#endregion

#region Private Methods - Weapon Configuration
## Apply weapon data to weapon component
func _apply_weapon_data(slot: int, data: WeaponData) -> void:
	var weapon = _weapon_slots[slot]
	if not weapon or not data:
		return

	# Apply basic stats
	weapon.weapon_type = data.weapon_type
	weapon.damage = data.damage
	weapon.fire_rate = data.fire_rate
	weapon.projectile_speed = data.projectile_speed
	weapon.auto_fire = data.auto_fire

	# Apply spread settings
	weapon.spread_count = data.spread_count
	weapon.spread_angle = data.spread_angle

	# Apply burst settings
	weapon.burst_count = data.burst_count
	weapon.burst_delay = data.burst_delay

	# Apply ammo settings
	weapon.use_ammo = data.uses_ammo()
	weapon.infinite_ammo = data.infinite_ammo

	if data.uses_ammo():
		_max_ammo[slot] = data.max_ammo
		_current_ammo[slot] = data.get_starting_ammo()
		weapon.current_ammo = _current_ammo[slot]
		weapon.max_ammo = _max_ammo[slot]
	else:
		_max_ammo[slot] = -1
		_current_ammo[slot] = -1

	# Apply projectile settings
	weapon.projectile_scene = data.projectile_scene
	weapon.pooled_projectile_type = data.pooled_projectile_type
	weapon.use_object_pooling = data.use_pooling
	weapon.firing_offset = data.firing_offset

	# Apply projectile scale (for Bigger Bullets upgrade)
	if "projectile_scale" in data:
		weapon.projectile_scale = data.projectile_scale

	# Set pool manager
	if _pool_manager:
		weapon.set_pool_manager(_pool_manager)

	if debug_slots:
		print("[WeaponSlotManager] Applied weapon data '%s' to slot %d" % [data.weapon_name, slot])
		print("  Type: %s, Damage: %d, Fire Rate: %.2f, Ammo: %d/%d" % [
			WeaponComponent.WeaponType.keys()[data.weapon_type],
			data.damage,
			data.fire_rate,
			_current_ammo[slot],
			_max_ammo[slot]
		])
#endregion

#region Private Methods - Input Handling
## Handle input for all weapon slots
## Implements Strategy Pattern for different firing modes
func _handle_input() -> void:
	# Primary + Secondary weapons fire together (combined strategy)
	# Uses same input action for both weapons
	if Input.is_action_pressed(primary_secondary_action):
		await fire_primary_and_secondary()

	# Special weapon fires independently (independent strategy)
	if Input.is_action_just_pressed(special_action):
		await fire_special()

## Update ready states for all weapons
func _update_ready_states() -> void:
	var changed = false

	for i in range(3):
		var weapon = _weapon_slots[i]
		if not weapon:
			continue

		var was_ready = _ready_to_fire[i]
		var is_ready = weapon.can_fire() and (_current_ammo[i] > 0 or _current_ammo[i] == -1)

		if was_ready != is_ready:
			_ready_to_fire[i] = is_ready
			changed = true

	if changed:
		weapons_ready_changed.emit()
#endregion

#region Signal Handlers
## Handle weapon fired from component
func _on_weapon_fired(projectile_count: int, slot: int) -> void:
	if debug_slots:
		print("[WeaponSlotManager] Slot %d fired %d projectiles" % [slot, projectile_count])

## Handle weapon out of ammo
func _on_weapon_out_of_ammo(slot: int) -> void:
	weapon_empty.emit(slot)

	if debug_slots:
		print("[WeaponSlotManager] Slot %d out of ammo!" % slot)

## Handle phase change (refill ammo)
func _on_phase_changed(phase_index: int, phase_config) -> void:
	refill_on_phase_change()

	if debug_slots:
		print("[WeaponSlotManager] Phase changed to %d - refilling ammo" % phase_index)
#endregion

#region Debug
## Get debug information
func get_debug_info() -> Dictionary:
	var slots_info = []
	for i in range(3):
		var slot_data = {
			"category": WeaponData.Category.keys()[i],
			"weapon": _weapon_data[i].weapon_name if _weapon_data[i] else "None",
			"ammo": "%d/%d" % [_current_ammo[i], _max_ammo[i]] if _current_ammo[i] >= 0 else "infinite",
			"ready": _ready_to_fire[i],
			"component": _weapon_slots[i] != null
		}
		slots_info.append(slot_data)

	return {
		"slots": slots_info,
		"auto_input": auto_handle_input,
		"pool_manager": _pool_manager != null,
		"projectiles_container": _projectiles_container.name if _projectiles_container else "null"
	}
#endregion
