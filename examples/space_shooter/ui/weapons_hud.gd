## Weapons HUD
##
## Manages and displays all 3 weapon slots (PRIMARY, SECONDARY, SPECIAL).
## Connects to WeaponSlotManager and updates displays in real-time.
##
## Design Pattern:
## - Observer Pattern: Listens to WeaponSlotManager signals
## - Facade Pattern: Provides simple interface to complex weapon display system
## - Composition: Uses 3 WeaponSlotDisplay components

extends VBoxContainer
class_name WeaponsHUD

#region Constants
const NEON_PINK: Color = Color(1.0, 0.08, 0.58)
const NEON_CYAN: Color = Color(0.0, 0.94, 0.94)
const NEON_YELLOW: Color = Color(1.0, 0.94, 0.0)
const DARK_BG: Color = Color(0.05, 0.0, 0.1, 0.9)
#endregion

#region Node References
var title_label: Label
var primary_display: WeaponSlotDisplay
var secondary_display: WeaponSlotDisplay
var special_display: WeaponSlotDisplay
#endregion

#region Private Variables
var weapon_manager: WeaponSlotManager = null
var player: Node2D = null
#endregion

#region Lifecycle
func _ready() -> void:
	_create_ui()
	call_deferred("_connect_to_player")

func _process(delta: float) -> void:
	# Update cooldown displays each frame
	if weapon_manager:
		_update_cooldown_displays()
#endregion

#region Public Methods
## Manually set player reference
func set_player(player_node: Node2D) -> void:
	player = player_node
	_connect_to_weapon_manager()
#endregion

#region Private Methods - UI Creation
func _create_ui() -> void:
	add_theme_constant_override("separation", 15)

	# Title
	title_label = Label.new()
	title_label.text = "▼ WEAPON LOADOUT ▼"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", NEON_CYAN)
	title_label.add_theme_color_override("font_outline_color", NEON_CYAN)
	title_label.add_theme_constant_override("outline_size", 3)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title_label)

	# Separator
	var sep_top = ColorRect.new()
	sep_top.custom_minimum_size = Vector2(0, 3)
	sep_top.color = NEON_CYAN
	add_child(sep_top)

	# PRIMARY Weapon Slot
	primary_display = WeaponSlotDisplay.new()
	primary_display.slot_category = WeaponData.Category.PRIMARY
	add_child(primary_display)

	# Separator
	var sep1 = ColorRect.new()
	sep1.custom_minimum_size = Vector2(0, 2)
	sep1.color = NEON_YELLOW
	add_child(sep1)

	# SECONDARY Weapon Slot
	secondary_display = WeaponSlotDisplay.new()
	secondary_display.slot_category = WeaponData.Category.SECONDARY
	secondary_display.show_toggle_hint(true)  # Show Z hint
	add_child(secondary_display)

	# Separator
	var sep2 = ColorRect.new()
	sep2.custom_minimum_size = Vector2(0, 2)
	sep2.color = NEON_PINK
	add_child(sep2)

	# SPECIAL Weapon Slot
	special_display = WeaponSlotDisplay.new()
	special_display.slot_category = WeaponData.Category.SPECIAL
	add_child(special_display)

	print("[WeaponsHUD] UI created - 3 weapon slots ready")
#endregion

#region Private Methods - Connection
func _connect_to_player() -> void:
	# Try to find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		print("[WeaponsHUD] Found player, waiting for player_ready signal...")

		if player.has_signal("player_ready"):
			player.player_ready.connect(_on_player_ready)
		else:
			# Fallback: try to connect immediately
			_connect_to_weapon_manager()
	else:
		print("[WeaponsHUD] ⚠️ No player found in scene!")

func _on_player_ready(player_node: Node2D) -> void:
	print("╔═══════════════════════════════════════════════════════╗")
	print("║     🎯 WeaponsHUD: PLAYER READY SIGNAL RECEIVED 🎯    ║")
	print("╚═══════════════════════════════════════════════════════╝")
	player = player_node
	_connect_to_weapon_manager()

func _connect_to_weapon_manager() -> void:
	if not player:
		push_error("[WeaponsHUD] ERROR: player is null!")
		return

	# Get WeaponSlotManager from player
	if not player.has_node("PlayerHost"):
		push_error("[WeaponsHUD] ❌ PlayerHost not found on player!")
		return

	var host = player.get_node("PlayerHost")
	weapon_manager = host.get_component("WeaponSlotManager")

	if weapon_manager:
		print("[WeaponsHUD] ✅ Found WeaponSlotManager!")

		# Connect to signals (Observer Pattern)
		weapon_manager.weapon_fired.connect(_on_weapon_fired)
		weapon_manager.ammo_changed.connect(_on_ammo_changed)
		weapon_manager.weapon_empty.connect(_on_weapon_empty)
		weapon_manager.secondary_toggled.connect(_on_secondary_toggled)
		weapon_manager.weapon_swapped.connect(_on_weapon_swapped)

		print("[WeaponsHUD] ✅ Connected to all WeaponSlotManager signals")

		# Initial display update
		_update_all_displays()
	else:
		push_error("[WeaponsHUD] ❌ WeaponSlotManager not found on PlayerHost!")

func _update_all_displays() -> void:
	if not weapon_manager:
		return

	print("[WeaponsHUD] Updating all weapon displays...")

	# Update each slot with weapon data
	for slot in range(3):
		var weapon_data = weapon_manager.get_weapon_data(slot)
		var weapon_comp = weapon_manager.get_weapon_component(slot)
		var display = _get_display_for_slot(slot)

		if weapon_data and display:
			display.set_weapon(weapon_data)

			# Update ammo
			var current_ammo = weapon_manager.get_ammo(slot)
			var max_ammo = weapon_manager.get_max_ammo(slot)
			display.update_ammo(current_ammo, max_ammo)

			print("  Slot %d: %s (%d/%d ammo)" % [slot, weapon_data.weapon_name, current_ammo, max_ammo])
		elif display:
			display.set_empty_slot()
			print("  Slot %d: EMPTY" % slot)

	# Update SECONDARY enabled state
	if secondary_display:
		secondary_display.set_toggle_enabled(weapon_manager.is_secondary_enabled())
#endregion

#region Private Methods - Signal Handlers
func _on_weapon_fired(slot: int, weapon_name: String) -> void:
	var display = _get_display_for_slot(slot)
	if display:
		display.flash_fired()

	if weapon_manager.debug_slots:
		print("[WeaponsHUD] Slot %d fired: %s" % [slot, weapon_name])

func _on_ammo_changed(slot: int, current: int, maximum: int) -> void:
	var display = _get_display_for_slot(slot)
	if display:
		display.update_ammo(current, maximum)

		# Check if empty
		if current <= 0:
			display.set_status_empty()
		else:
			display.set_status_ready()

func _on_weapon_empty(slot: int) -> void:
	var display = _get_display_for_slot(slot)
	if display:
		display.set_status_empty()
		display.flash_fired()  # Flash feedback

	print("[WeaponsHUD] Slot %d is EMPTY!" % slot)

func _on_secondary_toggled(enabled: bool) -> void:
	if secondary_display:
		secondary_display.set_toggle_enabled(enabled)

	print("[WeaponsHUD] SECONDARY %s" % ("ENABLED" if enabled else "DISABLED"))

func _on_weapon_swapped(slot: int, weapon_data: WeaponData) -> void:
	var display = _get_display_for_slot(slot)
	if display:
		if weapon_data:
			display.set_weapon(weapon_data)
		else:
			display.set_empty_slot()

	print("[WeaponsHUD] Slot %d swapped to: %s" % [slot, weapon_data.weapon_name if weapon_data else "EMPTY"])
#endregion

#region Private Methods - Cooldown Update
func _update_cooldown_displays() -> void:
	if not weapon_manager:
		return

	# Update cooldown for each slot
	for slot in range(3):
		var weapon_comp = weapon_manager.get_weapon_component(slot)
		var display = _get_display_for_slot(slot)

		if weapon_comp and display:
			var cooldown_percentage = weapon_comp.get_cooldown_percentage()
			display.update_cooldown(cooldown_percentage)
#endregion

#region Private Methods - Helpers
func _get_display_for_slot(slot: int) -> WeaponSlotDisplay:
	match slot:
		WeaponData.Category.PRIMARY:
			return primary_display
		WeaponData.Category.SECONDARY:
			return secondary_display
		WeaponData.Category.SPECIAL:
			return special_display
		_:
			return null
#endregion
