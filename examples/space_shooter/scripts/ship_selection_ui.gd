## Ship Selection UI
##
## Allows player to select their ship before starting the game

extends Control

signal ship_selected(config: ShipConfig)

@onready var ship_name_label: Label = $VBoxContainer/ShipName
@onready var ship_sprite: TextureRect = $VBoxContainer/ShipSprite
@onready var ship_description: Label = $VBoxContainer/Description
@onready var stats_container: VBoxContainer = $VBoxContainer/StatsContainer
@onready var prev_button: Button = $VBoxContainer/NavigationContainer/PrevButton
@onready var next_button: Button = $VBoxContainer/NavigationContainer/NextButton
@onready var select_button: Button = $VBoxContainer/SelectButton

var current_index: int = 0
var available_ships: Array[ShipConfig] = []

func _ready() -> void:
	_load_ships()
	_connect_buttons()
	_update_display()

func _load_ships() -> void:
	# Load from PlayerData if available
	if has_node("/root/PlayerData"):
		var player_data = get_node("/root/PlayerData")
		available_ships = player_data.available_ships
	else:
		# Fallback: load directly
		available_ships = [
			load("res://examples/space_shooter/resources/ships/ship_balanced.tres"),
			load("res://examples/space_shooter/resources/ships/ship_speed.tres"),
			load("res://examples/space_shooter/resources/ships/ship_tank.tres")
		]

func _connect_buttons() -> void:
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	select_button.pressed.connect(_on_select_pressed)

func _update_display() -> void:
	if available_ships.is_empty():
		return

	var ship = available_ships[current_index]

	# Update ship info
	ship_name_label.text = ship.ship_name
	ship_description.text = ship.description

	# Update ship sprite
	if ship.ship_sprite:
		ship_sprite.texture = ship.ship_sprite
		ship_sprite.modulate = ship.ship_tint
	else:
		ship_sprite.texture = null

	# Update stats
	_update_stats(ship)

	# Update button states
	prev_button.disabled = current_index == 0
	next_button.disabled = current_index == available_ships.size() - 1

func _update_stats(ship: ShipConfig) -> void:
	# Clear existing stats
	for child in stats_container.get_children():
		child.queue_free()

	# Add stat labels
	_add_stat_label("Health: %d" % ship.max_health)
	_add_stat_label("Speed: %.0f" % ship.speed)
	_add_stat_label("Fire Rate: %.1f/s" % ship.fire_rate)
	_add_stat_label("Damage: %d" % ship.weapon_damage)

func _add_stat_label(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	stats_container.add_child(label)

func _on_prev_pressed() -> void:
	if current_index > 0:
		current_index -= 1
		_update_display()

func _on_next_pressed() -> void:
	if current_index < available_ships.size() - 1:
		current_index += 1
		_update_display()

func _on_select_pressed() -> void:
	var selected_ship = available_ships[current_index]

	# Save selection to PlayerData
	if has_node("/root/PlayerData"):
		var player_data = get_node("/root/PlayerData")
		player_data.select_ship(current_index)

	# Emit signal
	ship_selected.emit(selected_ship)

	# Transition to game scene
	get_tree().change_scene_to_file("res://examples/space_shooter/scenes/main_game.tscn")
