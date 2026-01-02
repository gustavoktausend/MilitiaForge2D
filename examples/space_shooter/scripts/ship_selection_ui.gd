## Ship Selection UI
##
## Allows player to select their ship before starting the game

extends Control

signal ship_selected(config: ShipConfig)

@onready var ship_name_label: Label = $VBoxContainer/ShipName
@onready var ship_sprite: TextureRect = $VBoxContainer/ShipSprite
@onready var ship_description: Label = $VBoxContainer/Description
@onready var stats_container: VBoxContainer = $VBoxContainer/StatsContainer
@onready var color_grid: GridContainer = $VBoxContainer/ColorGridContainer
@onready var intensity_label: Label = $VBoxContainer/IntensityLabel
@onready var intensity_slider: HSlider = $VBoxContainer/IntensitySlider
@onready var prev_button: Button = $VBoxContainer/NavigationContainer/PrevButton
@onready var next_button: Button = $VBoxContainer/NavigationContainer/NextButton
@onready var select_button: Button = $VBoxContainer/SelectButton

var current_index: int = 0
var available_ships: Array[ShipConfig] = []

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
	_load_ships()
	_create_color_buttons()
	_connect_buttons()
	_load_saved_color()
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

		# Pressed style (selected)
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
	# Load saved color from PlayerData
	if has_node("/root/PlayerData"):
		var player_data = get_node("/root/PlayerData")
		selected_color = player_data.selected_ship_color
		color_intensity = player_data.selected_color_intensity
		intensity_slider.value = color_intensity
		_update_intensity_label()

func _connect_buttons() -> void:
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	select_button.pressed.connect(_on_select_pressed)
	intensity_slider.value_changed.connect(_on_intensity_changed)

func _update_display() -> void:
	if available_ships.is_empty():
		return

	var ship = available_ships[current_index]

	# Update ship info
	ship_name_label.text = ship.ship_name
	ship_description.text = ship.description

	# Update ship sprite with custom color
	if ship.ship_sprite:
		ship_sprite.texture = ship.ship_sprite
		_update_ship_color()
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
		player_data.selected_ship_color = selected_color
		player_data.selected_color_intensity = color_intensity

	# Play UI sound
	AudioManager.play_ui_sound("start_game", 1.2)

	# Emit signal
	ship_selected.emit(selected_ship)

	# Transition to game scene with squares effect (pixel blocks)
	var fade_out_options = SceneManager.create_options(0.6, "squares")  # 0.6s squares out
	var fade_in_options = SceneManager.create_options(0.4, "squares")   # 0.4s squares in
	var general_options = SceneManager.create_general_options()

	SceneManager.change_scene("main_game", fade_out_options, fade_in_options, general_options)

func _on_color_selected(index: int) -> void:
	selected_color = COLOR_PRESETS[index]
	_update_ship_color()
	_save_color_to_player_data()

func _on_intensity_changed(value: float) -> void:
	color_intensity = value
	_update_intensity_label()
	_update_ship_color()
	_save_color_to_player_data()

func _update_ship_color() -> void:
	var final_color = selected_color * color_intensity
	ship_sprite.modulate = final_color

func _update_intensity_label() -> void:
	intensity_label.text = "Intensity: %.2fx" % color_intensity

func _save_color_to_player_data() -> void:
	if has_node("/root/PlayerData"):
		var player_data = get_node("/root/PlayerData")
		player_data.selected_ship_color = selected_color
		player_data.selected_color_intensity = color_intensity
