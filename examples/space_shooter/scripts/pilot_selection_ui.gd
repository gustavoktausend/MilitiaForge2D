## Pilot Selection UI
##
## Allows player to select their pilot before starting the game

extends Control

signal pilot_selected(pilot)

@onready var pilot_name_label: Label = $VBoxContainer/PilotName
@onready var archetype_label: Label = $VBoxContainer/Archetype
@onready var difficulty_label: Label = $VBoxContainer/Difficulty
@onready var description_label: Label = $VBoxContainer/Description
@onready var bonuses_container: VBoxContainer = $VBoxContainer/BonusesContainer
@onready var ability_description: Label = $VBoxContainer/AbilityDescription
@onready var prev_button: Button = $VBoxContainer/NavigationContainer/PrevButton
@onready var next_button: Button = $VBoxContainer/NavigationContainer/NextButton
@onready var select_button: Button = $VBoxContainer/SelectButton

var current_index: int = 0
var available_pilots: Array = []

func _ready() -> void:
	_load_pilots()
	_connect_buttons()
	_update_display()

func _load_pilots() -> void:
	# Load from PlayerData if available
	if has_node("/root/PlayerData"):
		var player_data = get_node("/root/PlayerData")
		available_pilots = player_data.available_pilots

		# Set current index based on saved selection
		var saved_index = player_data.get_selected_pilot_index()
		if saved_index >= 0:
			current_index = saved_index
	else:
		# Fallback: load directly from database
		available_pilots = PilotDatabase.get_all_pilots()

	print("[PilotSelection] Loaded %d pilots" % available_pilots.size())

func _connect_buttons() -> void:
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	select_button.pressed.connect(_on_select_pressed)

func _update_display() -> void:
	if available_pilots.is_empty():
		return

	var pilot = available_pilots[current_index]

	# Update pilot info
	pilot_name_label.text = pilot.pilot_name
	archetype_label.text = "[ %s ]" % pilot.archetype

	# Update difficulty with color
	var diff_text = _get_difficulty_name(pilot.difficulty)
	difficulty_label.text = "Difficulty: %s" % diff_text
	difficulty_label.add_theme_color_override("font_color", _get_difficulty_color(pilot.difficulty))

	description_label.text = pilot.description

	# Update bonuses
	_update_bonuses(pilot)

	# Update ability
	_update_ability(pilot)

	# Update button states
	prev_button.disabled = current_index == 0
	next_button.disabled = current_index == available_pilots.size() - 1

func _update_bonuses(pilot) -> void:
	# Clear existing bonuses
	for child in bonuses_container.get_children():
		child.queue_free()

	# Add bonus labels
	var bonuses = []

	# Health modifier
	if pilot.health_modifier != 1.0:
		var percent = (pilot.health_modifier - 1.0) * 100
		bonuses.append("Health: %+d%%" % int(percent))

	# Speed modifier
	if pilot.speed_modifier != 1.0:
		var percent = (pilot.speed_modifier - 1.0) * 100
		bonuses.append("Speed: %+d%%" % int(percent))

	# Damage modifiers
	if pilot.primary_damage_modifier != 1.0:
		var percent = (pilot.primary_damage_modifier - 1.0) * 100
		bonuses.append("Primary Damage: %+d%%" % int(percent))

	if pilot.secondary_damage_modifier != 1.0:
		var percent = (pilot.secondary_damage_modifier - 1.0) * 100
		bonuses.append("Secondary Damage: %+d%%" % int(percent))

	if pilot.special_damage_modifier != 1.0:
		var percent = (pilot.special_damage_modifier - 1.0) * 100
		bonuses.append("Special Damage: %+d%%" % int(percent))

	# Fire rate modifiers
	if pilot.primary_fire_rate_modifier != 1.0:
		var percent = (pilot.primary_fire_rate_modifier - 1.0) * 100
		bonuses.append("Primary Fire Rate: %+d%%" % int(percent))

	if pilot.secondary_fire_rate_modifier != 1.0:
		var percent = (pilot.secondary_fire_rate_modifier - 1.0) * 100
		bonuses.append("Secondary Fire Rate: %+d%%" % int(percent))

	# Ammo bonuses
	if pilot.special_ammo_bonus > 0:
		bonuses.append("Special Ammo: +%d" % pilot.special_ammo_bonus)

	if pilot.secondary_ammo_modifier != 1.0:
		var percent = (pilot.secondary_ammo_modifier - 1.0) * 100
		bonuses.append("Secondary Ammo Capacity: %+d%%" % int(percent))

	# Explosive modifiers
	if pilot.explosion_radius_modifier != 1.0:
		var percent = (pilot.explosion_radius_modifier - 1.0) * 100
		bonuses.append("Blast Radius: %+d%%" % int(percent))

	if pilot.explosion_damage_modifier != 1.0:
		var percent = (pilot.explosion_damage_modifier - 1.0) * 100
		bonuses.append("Blast Damage: %+d%%" % int(percent))

	# Display bonuses
	if bonuses.is_empty():
		_add_bonus_label("No stat bonuses", Color(0.7, 0.7, 0.7))
	else:
		for bonus in bonuses:
			var color = Color.WHITE
			if bonus.contains("+"):
				color = Color(0.3, 1.0, 0.3)  # Green for positive
			elif bonus.contains("-"):
				color = Color(1.0, 0.3, 0.3)  # Red for negative
			_add_bonus_label(bonus, color)

func _add_bonus_label(text: String, color: Color = Color.WHITE) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonuses_container.add_child(label)

func _update_ability(pilot) -> void:
	var ability_text = _get_ability_description(pilot.primary_ability)
	ability_description.text = ability_text

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
		1: return Color(0.3, 1.0, 0.3)      # Verde - EASY
		2: return Color(1.0, 1.0, 0.3)      # Amarelo - MEDIUM
		3: return Color(1.0, 0.6, 0.2)      # Laranja - HARD
		4: return Color(1.0, 0.3, 0.3)      # Vermelho - EXPERT
		5: return Color(1.0, 0.3, 1.0)      # Magenta - MASTER
		_: return Color.WHITE

func _get_ability_description(ability: int) -> String:
	# AbilityType enum values
	const NONE = 0
	const REGENERATION = 1
	const COMBO_BOOST = 2
	const RESOURCE_SCAVENGER = 3
	const BERSERKER_MODE = 4
	const INVINCIBILITY_TRIGGER = 5
	const AMMO_EFFICIENCY = 6
	const SPECIAL_RECHARGE = 7
	const ALWAYS_SECONDARY = 8

	match ability:
		REGENERATION:
			return "Regenerates health over time when below 50% HP"
		COMBO_BOOST:
			return "Deals more damage as combo count increases"
		RESOURCE_SCAVENGER:
			return "Increased pickup range and better drop rates"
		BERSERKER_MODE:
			return "Damage increases as health decreases"
		INVINCIBILITY_TRIGGER:
			return "Auto-invincibility when health drops below 25%"
		AMMO_EFFICIENCY:
			return "Chance to not consume ammo when firing"
		SPECIAL_RECHARGE:
			return "Chance to refund special ammo on kills"
		ALWAYS_SECONDARY:
			return "Secondary weapon always enabled"
		_:
			return "No special ability"

func _on_prev_pressed() -> void:
	if current_index > 0:
		current_index -= 1
		_update_display()

func _on_next_pressed() -> void:
	if current_index < available_pilots.size() - 1:
		current_index += 1
		_update_display()

func _on_select_pressed() -> void:
	var selected_pilot = available_pilots[current_index]

	# Save selection to PlayerData
	if has_node("/root/PlayerData"):
		var player_data = get_node("/root/PlayerData")
		player_data.select_pilot(current_index)
		print("[PilotSelection] Selected pilot: %s" % selected_pilot.pilot_name)

	# Emit signal
	pilot_selected.emit(selected_pilot)

	# Transition to ship selection scene
	get_tree().change_scene_to_file("res://examples/space_shooter/scenes/ship_selection.tscn")
