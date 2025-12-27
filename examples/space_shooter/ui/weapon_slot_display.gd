## Weapon Slot Display
##
## Displays information about a single weapon slot (PRIMARY, SECONDARY, or SPECIAL).
## Shows weapon name, category, ammo (segmented Megaman X style), cooldown, and status.
##
## Design Pattern:
## - Single Responsibility: Only displays ONE weapon slot
## - Observer Pattern: Reacts to weapon state changes
## - Composition: Uses AmmoSegmentedBar for ammo display

extends PanelContainer
class_name WeaponSlotDisplay

#region Constants
# Neon colors (match game_hud.gd)
const NEON_PINK: Color = Color(1.0, 0.08, 0.58)
const NEON_CYAN: Color = Color(0.0, 0.94, 0.94)
const NEON_YELLOW: Color = Color(1.0, 0.94, 0.0)
const NEON_PURPLE: Color = Color(0.58, 0.0, 0.83)
const NEON_ORANGE: Color = Color(1.0, 0.41, 0.0)
const NEON_GREEN: Color = Color(0.0, 1.0, 0.5)
const DARK_BG: Color = Color(0.05, 0.0, 0.1, 0.9)

# Weapon category colors
const CATEGORY_COLORS = {
	0: NEON_CYAN,    # PRIMARY
	1: NEON_YELLOW,  # SECONDARY
	2: NEON_PINK     # SPECIAL
}

# Unicode icons for weapons (simple but effective)
const WEAPON_ICONS = {
	"basic_laser": "▶",
	"spread_shot": "⋮",
	"rapid_fire": "≡",
	"homing_missile": "🎯",
	"shotgun_blast": "◆",
	"burst_cannon": "⋯",
	"plasma_bomb": "💣",
	"railgun": "━",
	"emp_pulse": "◉"
}
#endregion

#region Exports
@export_group("Slot Configuration")
## Slot category (0=PRIMARY, 1=SECONDARY, 2=SPECIAL)
@export_enum("PRIMARY:0", "SECONDARY:1", "SPECIAL:2") var slot_category: int = 0:
	set(value):
		slot_category = value
		_update_styling()

## Whether this slot is enabled (for SECONDARY toggle)
@export var is_enabled: bool = true:
	set(value):
		is_enabled = value
		_update_enabled_state()
#endregion

#region Node References
var weapon_icon_label: Label
var weapon_name_label: Label
var category_label: Label
var ammo_bar: AmmoSegmentedBar
var cooldown_bar: ProgressBar
var status_label: Label
var toggle_hint_label: Label  # "Press Z" for SECONDARY
#endregion

#region Private Variables
var _current_weapon_name: String = ""
var _is_ready: bool = true
var _cooldown_tween: Tween
#endregion

#region Lifecycle
func _ready() -> void:
	_create_ui()
	_update_styling()

	# Default state: empty slot
	set_empty_slot()
#endregion

#region Public Methods - Weapon Data
## Set weapon data from WeaponData resource
func set_weapon(weapon_data: WeaponData) -> void:
	if not weapon_data:
		set_empty_slot()
		return

	_current_weapon_name = weapon_data.weapon_name

	# Update weapon name
	weapon_name_label.text = weapon_data.weapon_name.to_upper()

	# Update icon
	var icon_key = weapon_data.weapon_name.to_lower().replace(" ", "_")
	if icon_key in WEAPON_ICONS:
		weapon_icon_label.text = WEAPON_ICONS[icon_key]
	else:
		weapon_icon_label.text = "◉"  # Default icon

	# Update ammo display
	if weapon_data.infinite_ammo or weapon_data.max_ammo < 0:
		ammo_bar.set_infinite(true)
	else:
		ammo_bar.set_infinite(false)
		ammo_bar.max_ammo = weapon_data.max_ammo
		ammo_bar.current_ammo = weapon_data.get_starting_ammo()

	# Update category
	category_label.text = WeaponData.Category.keys()[slot_category]

	# Show as ready
	set_status_ready()

	# Show slot
	show()

## Set empty slot (no weapon equipped)
func set_empty_slot() -> void:
	_current_weapon_name = ""
	weapon_name_label.text = "[ EMPTY ]"
	weapon_icon_label.text = "─"
	ammo_bar.set_infinite(true)
	set_status_empty()

	# Hide toggle hint
	if toggle_hint_label:
		toggle_hint_label.visible = false
#endregion

#region Public Methods - State Updates
## Update ammo display
func update_ammo(current: int, maximum: int) -> void:
	if ammo_bar:
		ammo_bar.set_ammo(current, maximum)

		# Flash if ammo changed
		if current < ammo_bar.current_ammo:
			ammo_bar.flash(NEON_CYAN, 0.1)

## Update cooldown display (0.0 = ready, 1.0 = just fired)
func update_cooldown(percentage: float) -> void:
	if not cooldown_bar:
		return

	# Kill existing tween
	if _cooldown_tween:
		_cooldown_tween.kill()

	# Animate cooldown bar
	_cooldown_tween = create_tween()
	_cooldown_tween.tween_property(cooldown_bar, "value", (1.0 - percentage) * 100.0, 0.05)

	# Update status
	if percentage > 0.0:
		set_status_cooling()
	else:
		set_status_ready()

## Set weapon as ready to fire
func set_status_ready() -> void:
	_is_ready = true
	status_label.text = "✓ READY"
	status_label.add_theme_color_override("font_color", NEON_GREEN)

## Set weapon as cooling down
func set_status_cooling() -> void:
	_is_ready = false
	status_label.text = "⏳ COOLING"
	status_label.add_theme_color_override("font_color", NEON_CYAN)

## Set weapon as empty (out of ammo)
func set_status_empty() -> void:
	_is_ready = false
	status_label.text = "✕ EMPTY"
	status_label.add_theme_color_override("font_color", NEON_PINK)

	# Pulse empty status
	var tween = create_tween().set_loops()
	tween.tween_property(status_label, "modulate:a", 0.3, 0.5)
	tween.tween_property(status_label, "modulate:a", 1.0, 0.5)

## Flash weapon slot (feedback when fired)
func flash_fired() -> void:
	# Flash icon
	var icon_tween = create_tween()
	icon_tween.tween_property(weapon_icon_label, "scale", Vector2(1.3, 1.3), 0.1)
	icon_tween.tween_property(weapon_icon_label, "scale", Vector2(1.0, 1.0), 0.1)

	# Flash panel border
	var panel_style: StyleBoxFlat = get_theme_stylebox("panel")
	if panel_style:
		var original_color = panel_style.border_color
		panel_style.border_color = Color.WHITE

		var border_tween = create_tween()
		border_tween.tween_property(panel_style, "border_color", original_color, 0.2)
#endregion

#region Public Methods - Toggle State (SECONDARY only)
## Set toggle state (for SECONDARY weapon)
func set_toggle_enabled(enabled: bool) -> void:
	is_enabled = enabled

## Show toggle hint (for SECONDARY weapon)
func show_toggle_hint(show: bool = true) -> void:
	if toggle_hint_label:
		toggle_hint_label.visible = show and slot_category == 1  # Only for SECONDARY
#endregion

#region Private Methods - UI Creation
func _create_ui() -> void:
	# Panel styling
	custom_minimum_size = Vector2(380, 160)

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = DARK_BG
	panel_style.set_border_width_all(3)
	panel_style.border_color = CATEGORY_COLORS[slot_category]
	panel_style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", panel_style)

	# Main container
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# TOP ROW: Icon + Weapon Name
	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	vbox.add_child(top_row)

	# Weapon Icon
	weapon_icon_label = Label.new()
	weapon_icon_label.text = "◉"
	weapon_icon_label.add_theme_font_size_override("font_size", 40)
	weapon_icon_label.add_theme_color_override("font_color", CATEGORY_COLORS[slot_category])
	weapon_icon_label.custom_minimum_size = Vector2(50, 50)
	weapon_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	weapon_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_row.add_child(weapon_icon_label)

	# Name + Category
	var name_vbox = VBoxContainer.new()
	name_vbox.add_theme_constant_override("separation", 2)
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(name_vbox)

	weapon_name_label = Label.new()
	weapon_name_label.text = "WEAPON NAME"
	weapon_name_label.add_theme_font_size_override("font_size", 18)
	weapon_name_label.add_theme_color_override("font_color", Color.WHITE)
	name_vbox.add_child(weapon_name_label)

	category_label = Label.new()
	category_label.text = "PRIMARY"
	category_label.add_theme_font_size_override("font_size", 14)
	category_label.add_theme_color_override("font_color", CATEGORY_COLORS[slot_category])
	name_vbox.add_child(category_label)

	# Separator
	var sep1 = ColorRect.new()
	sep1.custom_minimum_size = Vector2(0, 2)
	sep1.color = CATEGORY_COLORS[slot_category]
	vbox.add_child(sep1)

	# MIDDLE ROW: Ammo Bar
	var ammo_container = HBoxContainer.new()
	ammo_container.add_theme_constant_override("separation", 10)
	vbox.add_child(ammo_container)

	var ammo_label = Label.new()
	ammo_label.text = "AMMO:"
	ammo_label.add_theme_font_size_override("font_size", 12)
	ammo_label.add_theme_color_override("font_color", NEON_CYAN)
	ammo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ammo_container.add_child(ammo_label)

	# Segmented Ammo Bar (Megaman X style)
	ammo_bar = AmmoSegmentedBar.new()
	ammo_bar.max_ammo = 20
	ammo_bar.current_ammo = 20
	ammo_bar.fill_bottom_to_top = true
	ammo_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ammo_container.add_child(ammo_bar)

	# BOTTOM ROW: Cooldown + Status
	var bottom_row = HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 10)
	vbox.add_child(bottom_row)

	# Cooldown bar
	var cooldown_vbox = VBoxContainer.new()
	cooldown_vbox.add_theme_constant_override("separation", 4)
	cooldown_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(cooldown_vbox)

	var cooldown_label = Label.new()
	cooldown_label.text = "COOLDOWN"
	cooldown_label.add_theme_font_size_override("font_size", 10)
	cooldown_label.add_theme_color_override("font_color", NEON_PURPLE)
	cooldown_vbox.add_child(cooldown_label)

	cooldown_bar = ProgressBar.new()
	cooldown_bar.min_value = 0
	cooldown_bar.max_value = 100
	cooldown_bar.value = 100
	cooldown_bar.custom_minimum_size = Vector2(0, 12)
	cooldown_bar.show_percentage = false

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = NEON_CYAN
	fill_style.set_border_width_all(1)
	fill_style.border_color = NEON_CYAN
	cooldown_bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.15)
	bg_style.set_border_width_all(1)
	bg_style.border_color = NEON_PURPLE
	cooldown_bar.add_theme_stylebox_override("background", bg_style)

	cooldown_vbox.add_child(cooldown_bar)

	# Status label
	status_label = Label.new()
	status_label.text = "✓ READY"
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", NEON_GREEN)
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom_row.add_child(status_label)

	# Toggle hint (only visible for SECONDARY)
	toggle_hint_label = Label.new()
	toggle_hint_label.text = "⌨ Z"
	toggle_hint_label.add_theme_font_size_override("font_size", 12)
	toggle_hint_label.add_theme_color_override("font_color", NEON_YELLOW)
	toggle_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toggle_hint_label.visible = false
	vbox.add_child(toggle_hint_label)
#endregion

#region Private Methods - Styling
func _update_styling() -> void:
	if not is_node_ready():
		return

	# Update category color
	var category_color = CATEGORY_COLORS.get(slot_category, NEON_CYAN)

	var panel_style: StyleBoxFlat = get_theme_stylebox("panel")
	if panel_style:
		panel_style.border_color = category_color

	if weapon_icon_label:
		weapon_icon_label.add_theme_color_override("font_color", category_color)

	if category_label:
		category_label.add_theme_color_override("font_color", category_color)
		category_label.text = WeaponData.Category.keys()[slot_category]

func _update_enabled_state() -> void:
	if not is_node_ready():
		return

	if slot_category != 1:  # Only SECONDARY can be toggled
		return

	# Visual feedback for enabled/disabled
	if is_enabled:
		modulate = Color.WHITE
		if toggle_hint_label:
			toggle_hint_label.text = "🟢 ACTIVE (Z)"
			toggle_hint_label.add_theme_color_override("font_color", NEON_GREEN)
	else:
		modulate = Color(0.5, 0.5, 0.5)  # Gray out
		if toggle_hint_label:
			toggle_hint_label.text = "🔴 DISABLED (Z)"
			toggle_hint_label.add_theme_color_override("font_color", NEON_PINK)

	# Show toggle hint
	if toggle_hint_label:
		toggle_hint_label.visible = true
#endregion
