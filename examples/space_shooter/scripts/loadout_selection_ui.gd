## Loadout Selection UI
##
## Unified interface for selecting pilot + ship + colors

extends Control

# Pilot references
@onready var license_card: TextureRect = $HSplitContainer/PilotPanel/PilotVBox/LicenseCard
@onready var pilot_name_label: Label = $HSplitContainer/PilotPanel/PilotVBox/PilotName
@onready var archetype_label: Label = $HSplitContainer/PilotPanel/PilotVBox/Archetype
@onready var difficulty_label: Label = $HSplitContainer/PilotPanel/PilotVBox/Difficulty
@onready var pilot_description: Label = $HSplitContainer/PilotPanel/PilotVBox/PilotDescription
@onready var bonuses_container: VBoxContainer = $HSplitContainer/PilotPanel/PilotVBox/BonusesContainer
@onready var ability_description: Label = $HSplitContainer/PilotPanel/PilotVBox/AbilityDescription
@onready var prev_pilot_button: Button = $HSplitContainer/PilotPanel/PilotVBox/PilotNavigation/PrevPilot
@onready var next_pilot_button: Button = $HSplitContainer/PilotPanel/PilotVBox/PilotNavigation/NextPilot

# Ship references
@onready var ship_name_label: Label = $HSplitContainer/ShipPanel/ShipVBox/ShipName
@onready var ship_sprite: TextureRect = $HSplitContainer/ShipPanel/ShipVBox/ShipSprite
@onready var ship_description: Label = $HSplitContainer/ShipPanel/ShipVBox/ShipDescription
@onready var stats_container: VBoxContainer = $HSplitContainer/ShipPanel/ShipVBox/StatsContainer
@onready var color_grid: GridContainer = $HSplitContainer/ShipPanel/ShipVBox/ColorGridContainer
@onready var intensity_label: Label = $HSplitContainer/ShipPanel/ShipVBox/IntensityLabel
@onready var intensity_slider: HSlider = $HSplitContainer/ShipPanel/ShipVBox/IntensitySlider
@onready var prev_ship_button: Button = $HSplitContainer/ShipPanel/ShipVBox/ShipNavigation/PrevShip
@onready var next_ship_button: Button = $HSplitContainer/ShipPanel/ShipVBox/ShipNavigation/NextShip

# Bottom bar
@onready var start_button: Button = $BottomBar/StartButton

# Weapon selection
@onready var primary_weapon_option: OptionButton = $WeaponPanel/WeaponHBox/PrimaryWeapon
@onready var secondary_weapon_option: OptionButton = $WeaponPanel/WeaponHBox/SecondaryWeapon

# Music
@onready var music_player: AudioStreamPlayer = $MusicPlayer

# Data
var current_pilot_index: int = 0
var current_ship_index: int = 0
var available_pilots: Array = []
var available_ships: Array = []

# Weapon selection (temporary for testing)
var selected_primary_weapon: String = "basic_laser"
var selected_secondary_weapon: String = "homing_missile"

# Color customization
var color_buttons: Array[Button] = []
var selected_color: Color = Color.WHITE
var color_intensity: float = 1.0

const COLOR_PRESETS = [
	Color(1.0, 1.0, 1.0),      # Branco
	Color(1.0, 0.3, 0.3),      # Vermelho
	Color(0.3, 1.0, 0.3),      # Verde
	Color(0.3, 0.3, 1.0),      # Azul
	Color(1.0, 1.0, 0.3),      # Amarelo
	Color(1.0, 0.3, 1.0),      # Magenta
	Color(0.3, 1.0, 1.0),      # Ciano
	Color(1.0, 0.6, 0.2),      # Laranja
	Color(0.6, 0.3, 1.0),      # Roxo
	Color(1.0, 0.8, 0.5),      # Dourado
]

func _ready() -> void:
	_load_data()
	_create_color_buttons()
	_populate_weapon_selectors()  # Add weapon dropdowns
	_connect_buttons()
	_load_saved_color()
	_load_saved_weapons()  # Load saved weapon selection
	_update_pilot_display()
	_update_ship_display()
	_setup_music()

func _load_data() -> void:
	if has_node("/root/PlayerData"):
		var player_data = get_node("/root/PlayerData")
		available_pilots = player_data.available_pilots
		available_ships = player_data.available_ships

		# Set current indices from saved selection
		current_pilot_index = player_data.get_selected_pilot_index()
		if current_pilot_index < 0:
			current_pilot_index = 0

		# Find ship index
		if player_data.selected_ship_config:
			for i in range(available_ships.size()):
				if available_ships[i] == player_data.selected_ship_config:
					current_ship_index = i
					break

func _create_color_buttons() -> void:
	for i in range(COLOR_PRESETS.size()):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(40, 40)

		# Create style with color
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = COLOR_PRESETS[i]
		normal_style.set_corner_radius_all(5)
		normal_style.set_border_width_all(2)
		normal_style.border_color = Color(0.3, 0.3, 0.3)
		btn.add_theme_stylebox_override("normal", normal_style)

		# Hover style
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = COLOR_PRESETS[i].lightened(0.2)
		hover_style.set_corner_radius_all(5)
		hover_style.set_border_width_all(3)
		hover_style.border_color = Color(1.0, 1.0, 1.0)
		btn.add_theme_stylebox_override("hover", hover_style)

		# Pressed style
		var pressed_style = StyleBoxFlat.new()
		pressed_style.bg_color = COLOR_PRESETS[i]
		pressed_style.set_corner_radius_all(5)
		pressed_style.set_border_width_all(4)
		pressed_style.border_color = Color(1.0, 1.0, 0.3)
		btn.add_theme_stylebox_override("pressed", pressed_style)

		btn.pressed.connect(_on_color_selected.bind(i))
		color_grid.add_child(btn)
		color_buttons.append(btn)

func _load_saved_color() -> void:
	if has_node("/root/PlayerData"):
		var player_data = get_node("/root/PlayerData")
		selected_color = player_data.selected_ship_color
		color_intensity = player_data.selected_color_intensity
		intensity_slider.value = color_intensity
		_update_intensity_label()

func _connect_buttons() -> void:
	# Pilot buttons
	prev_pilot_button.pressed.connect(_on_prev_pilot)
	next_pilot_button.pressed.connect(_on_next_pilot)

	# Ship buttons
	prev_ship_button.pressed.connect(_on_prev_ship)
	next_ship_button.pressed.connect(_on_next_ship)

	# Color
	intensity_slider.value_changed.connect(_on_intensity_changed)

	# Weapon selection
	primary_weapon_option.item_selected.connect(_on_primary_weapon_selected)
	secondary_weapon_option.item_selected.connect(_on_secondary_weapon_selected)

	# Start button
	start_button.pressed.connect(_on_start_pressed)

#region Pilot Display
func _update_pilot_display() -> void:
	if available_pilots.is_empty():
		return

	var pilot = available_pilots[current_pilot_index]

	# Update portrait/license card image (with fallback)
	if pilot.portrait:
		license_card.texture = pilot.portrait
	elif pilot.license_card:
		license_card.texture = pilot.license_card
	else:
		license_card.texture = null

	# Update info
	pilot_name_label.text = pilot.pilot_name
	archetype_label.text = "[ %s ]" % pilot.archetype

	# Difficulty with color
	var diff_text = _get_difficulty_name(pilot.difficulty)
	difficulty_label.text = "Difficulty: %s" % diff_text
	difficulty_label.add_theme_color_override("font_color", _get_difficulty_color(pilot.difficulty))

	pilot_description.text = pilot.description

	# Update bonuses
	_update_bonuses(pilot)

	# Update ability
	var ability_text = _get_ability_description(pilot.primary_ability)
	ability_description.text = ability_text

	# Button states
	prev_pilot_button.disabled = current_pilot_index == 0
	next_pilot_button.disabled = current_pilot_index == available_pilots.size() - 1

func _update_bonuses(pilot) -> void:
	# Clear existing
	for child in bonuses_container.get_children():
		child.queue_free()

	var bonuses = []

	# Collect bonuses (same logic as pilot_selection_ui.gd)
	if pilot.health_modifier != 1.0:
		bonuses.append("Health: %+d%%" % int((pilot.health_modifier - 1.0) * 100))
	if pilot.speed_modifier != 1.0:
		bonuses.append("Speed: %+d%%" % int((pilot.speed_modifier - 1.0) * 100))
	if pilot.primary_damage_modifier != 1.0:
		bonuses.append("Primary Dmg: %+d%%" % int((pilot.primary_damage_modifier - 1.0) * 100))
	if pilot.secondary_damage_modifier != 1.0:
		bonuses.append("Secondary Dmg: %+d%%" % int((pilot.secondary_damage_modifier - 1.0) * 100))
	if pilot.special_damage_modifier != 1.0:
		bonuses.append("Special Dmg: %+d%%" % int((pilot.special_damage_modifier - 1.0) * 100))
	if pilot.primary_fire_rate_modifier != 1.0:
		bonuses.append("Primary FR: %+d%%" % int((pilot.primary_fire_rate_modifier - 1.0) * 100))
	if pilot.secondary_fire_rate_modifier != 1.0:
		bonuses.append("Secondary FR: %+d%%" % int((pilot.secondary_fire_rate_modifier - 1.0) * 100))

	# Display
	if bonuses.is_empty():
		_add_bonus_label("No stat bonuses", Color(0.7, 0.7, 0.7))
	else:
		for bonus in bonuses:
			var color = Color(0.3, 1.0, 0.3) if bonus.contains("+") else Color(1.0, 0.3, 0.3)
			_add_bonus_label(bonus, color)

func _add_bonus_label(text: String, color: Color = Color.WHITE) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonuses_container.add_child(label)

func _get_difficulty_name(difficulty: int) -> String:
	match difficulty:
		1: return "EASY"
		2: return "MEDIUM"
		3: return "HARD"
		4: return "EXPERT"
		5: return "MASTER"
		_: return "UNKNOWN"

func _get_difficulty_color(difficulty: int) -> Color:
	match difficulty:
		1: return Color(0.3, 1.0, 0.3)
		2: return Color(1.0, 1.0, 0.3)
		3: return Color(1.0, 0.6, 0.2)
		4: return Color(1.0, 0.3, 0.3)
		5: return Color(1.0, 0.3, 1.0)
		_: return Color.WHITE

func _get_ability_description(ability: int) -> String:
	const REGENERATION = 1
	const COMBO_BOOST = 2
	const RESOURCE_SCAVENGER = 3
	const BERSERKER_MODE = 4
	const INVINCIBILITY_TRIGGER = 5
	const AMMO_EFFICIENCY = 6
	const SPECIAL_RECHARGE = 7
	const ALWAYS_SECONDARY = 8

	match ability:
		REGENERATION: return "HP Regen below 50%"
		COMBO_BOOST: return "Damage scales with combo"
		RESOURCE_SCAVENGER: return "Better drops & range"
		BERSERKER_MODE: return "Damage scales with missing HP"
		INVINCIBILITY_TRIGGER: return "Auto-invincibility < 25% HP"
		AMMO_EFFICIENCY: return "Chance to save ammo"
		SPECIAL_RECHARGE: return "Refund special on kills"
		ALWAYS_SECONDARY: return "Secondary always active"
		_: return "No ability"
#endregion

#region Ship Display
func _update_ship_display() -> void:
	if available_ships.is_empty():
		return

	var ship = available_ships[current_ship_index]

	# Update info
	ship_name_label.text = ship.ship_name
	ship_description.text = ship.description

	# Update sprite with color
	if ship.ship_sprite:
		ship_sprite.texture = ship.ship_sprite
		_update_ship_color()
	else:
		ship_sprite.texture = null

	# Update stats
	_update_ship_stats(ship)

	# Button states
	prev_ship_button.disabled = current_ship_index == 0
	next_ship_button.disabled = current_ship_index == available_ships.size() - 1

func _update_ship_stats(ship) -> void:
	# Clear existing
	for child in stats_container.get_children():
		child.queue_free()

	# Add stats
	_add_stat_label("Health: %d" % ship.max_health)
	_add_stat_label("Speed: %.0f" % ship.speed)
	_add_stat_label("Fire Rate: %.1f/s" % ship.fire_rate)
	_add_stat_label("Damage: %d" % ship.weapon_damage)

func _add_stat_label(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_container.add_child(label)
#endregion

#region Color System
func _on_color_selected(index: int) -> void:
	selected_color = COLOR_PRESETS[index]
	_update_ship_color()
	_save_to_player_data()

func _on_intensity_changed(value: float) -> void:
	color_intensity = value
	_update_intensity_label()
	_update_ship_color()
	_save_to_player_data()

func _update_ship_color() -> void:
	var final_color = selected_color * color_intensity
	ship_sprite.modulate = final_color

func _update_intensity_label() -> void:
	intensity_label.text = "Intensity: %.2fx" % color_intensity
#endregion

#region Navigation
func _on_prev_pilot() -> void:
	if current_pilot_index > 0:
		current_pilot_index -= 1
		_update_pilot_display()
		_save_to_player_data()

func _on_next_pilot() -> void:
	if current_pilot_index < available_pilots.size() - 1:
		current_pilot_index += 1
		_update_pilot_display()
		_save_to_player_data()

func _on_prev_ship() -> void:
	if current_ship_index > 0:
		current_ship_index -= 1
		_update_ship_display()
		_save_to_player_data()

func _on_next_ship() -> void:
	if current_ship_index < available_ships.size() - 1:
		current_ship_index += 1
		_update_ship_display()
		_save_to_player_data()

func _on_start_pressed() -> void:
	AudioManager.play_ui_sound("start_game", 1.2)
	_save_to_player_data()
	print("[LoadoutSelection] Starting game with pilot: %s, ship: %s" %
		[available_pilots[current_pilot_index].pilot_name,
		 available_ships[current_ship_index].ship_name])

	# Fade out music before transitioning (using AudioManager)
	await AudioManager.fade_out_music(0.8)

	# Transition to main game with squares effect (pixel blocks)
	var fade_out_options = SceneManager.create_options(0.6, "squares")  # 0.6s squares out
	var fade_in_options = SceneManager.create_options(0.4, "squares")   # 0.4s squares in
	var general_options = SceneManager.create_general_options()

	SceneManager.change_scene("main_game", fade_out_options, fade_in_options, general_options)
#endregion

#region Save/Load
func _save_to_player_data() -> void:
	if has_node("/root/PlayerData"):
		var player_data = get_node("/root/PlayerData")
		player_data.select_pilot(current_pilot_index)
		player_data.select_ship(current_ship_index)
		player_data.selected_ship_color = selected_color
		player_data.selected_color_intensity = color_intensity
		# Save weapon selection (temporary for testing)
		player_data.selected_primary_weapon = selected_primary_weapon
		player_data.selected_secondary_weapon = selected_secondary_weapon
#endregion

#region Weapon Selection (Temporary for Testing)
func _populate_weapon_selectors() -> void:
	"""Populate weapon dropdowns"""
	# Primary weapons
	var primary_weapons = WeaponDatabase.get_primary_weapon_names()
	for i in range(primary_weapons.size()):
		var weapon_name = primary_weapons[i]
		var weapon_data = WeaponDatabase.get_primary_weapon(weapon_name)
		if weapon_data:
			primary_weapon_option.add_item(weapon_data.weapon_name, i)
			primary_weapon_option.set_item_metadata(i, weapon_name)

	# Secondary weapons
	var secondary_weapons = WeaponDatabase.get_secondary_weapon_names()
	for i in range(secondary_weapons.size()):
		var weapon_name = secondary_weapons[i]
		var weapon_data = WeaponDatabase.get_secondary_weapon(weapon_name)
		if weapon_data:
			secondary_weapon_option.add_item(weapon_data.weapon_name, i)
			secondary_weapon_option.set_item_metadata(i, weapon_name)

	print("[LoadoutSelection] Weapon selectors populated")

func _load_saved_weapons() -> void:
	"""Load saved weapon selection from PlayerData"""
	if has_node("/root/PlayerData"):
		var player_data = get_node("/root/PlayerData")
		if "selected_primary_weapon" in player_data:
			selected_primary_weapon = player_data.selected_primary_weapon
			# Select in dropdown
			for i in range(primary_weapon_option.item_count):
				if primary_weapon_option.get_item_metadata(i) == selected_primary_weapon:
					primary_weapon_option.selected = i
					break

		if "selected_secondary_weapon" in player_data:
			selected_secondary_weapon = player_data.selected_secondary_weapon
			# Select in dropdown
			for i in range(secondary_weapon_option.item_count):
				if secondary_weapon_option.get_item_metadata(i) == selected_secondary_weapon:
					secondary_weapon_option.selected = i
					break

func _on_primary_weapon_selected(index: int) -> void:
	"""Handle primary weapon selection"""
	selected_primary_weapon = primary_weapon_option.get_item_metadata(index)
	_save_to_player_data()
	print("[LoadoutSelection] Primary weapon selected: %s" % selected_primary_weapon)

func _on_secondary_weapon_selected(index: int) -> void:
	"""Handle secondary weapon selection"""
	selected_secondary_weapon = secondary_weapon_option.get_item_metadata(index)
	_save_to_player_data()
	print("[LoadoutSelection] Secondary weapon selected: %s" % selected_secondary_weapon)
#endregion

#region Music Control
func _setup_music() -> void:
	if not music_player:
		return

	# Configure music player
	music_player.volume_db = -80.0  # Start silent for fade in
	music_player.bus = "Music"  # Use Music bus (can be adjusted in audio settings)

	# Enable looping if the stream supports it
	if music_player.stream:
		if music_player.stream is AudioStreamOggVorbis:
			music_player.stream.loop = true

	# Start playing if not already
	if not music_player.playing:
		music_player.play()

	# Fade in
	_fade_in_music()

func _fade_in_music(duration: float = 1.0) -> void:
	if not music_player:
		return

	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -10.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _fade_out_music(duration: float = 0.5) -> void:
	if not music_player:
		return

	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80.0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
#endregion
