## Game HUD for Space Shooter
##
## Displays health, score, wave information, and other game stats.
## Uses vertical shooter layout with side panels.

extends CanvasLayer

#region Constants
const PLAY_AREA_WIDTH: float = 640.0  # Narrower play area
const SIDE_PANEL_WIDTH: float = 320.0  # Width of each side panel
#endregion

#region Node References
@onready var health_bar: ProgressBar
@onready var score_label: Label
@onready var wave_label: Label
@onready var combo_label: Label
@onready var high_score_label: Label
@onready var lives_label: Label
@onready var left_panel: Panel
@onready var right_panel: Panel
#endregion

#region Private Variables
var game_controller: Node = null
var player: Node2D = null
var wave_manager: Node2D = null
#endregion

func _ready() -> void:
	_create_hud_elements()
	call_deferred("_connect_to_game")

func _create_hud_elements() -> void:
	var viewport_size = get_viewport().get_visible_rect().size

	# Create left panel for game info
	left_panel = Panel.new()
	left_panel.custom_minimum_size = Vector2(SIDE_PANEL_WIDTH, viewport_size.y)
	left_panel.position = Vector2(0, 0)

	# Style left panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.3, 0.3, 0.4)
	left_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(left_panel)

	# Create right panel (for future use - instructions, etc)
	right_panel = Panel.new()
	right_panel.custom_minimum_size = Vector2(SIDE_PANEL_WIDTH, viewport_size.y)
	right_panel.position = Vector2(viewport_size.x - SIDE_PANEL_WIDTH, 0)
	right_panel.add_theme_stylebox_override("panel", panel_style.duplicate())
	add_child(right_panel)

	# Left panel content
	var left_margin = MarginContainer.new()
	left_margin.anchor_right = 1.0
	left_margin.anchor_bottom = 1.0
	left_margin.add_theme_constant_override("margin_left", 20)
	left_margin.add_theme_constant_override("margin_top", 20)
	left_margin.add_theme_constant_override("margin_right", 20)
	left_margin.add_theme_constant_override("margin_bottom", 20)
	left_panel.add_child(left_margin)

	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 30)
	left_margin.add_child(info_vbox)

	# Title
	var title = Label.new()
	title.text = "SPACE SHOOTER"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_vbox.add_child(title)

	# Separator
	var separator1 = HSeparator.new()
	info_vbox.add_child(separator1)

	# Score Section
	var score_container = VBoxContainer.new()
	score_container.add_theme_constant_override("separation", 10)
	info_vbox.add_child(score_container)

	var score_title = Label.new()
	score_title.text = "SCORE"
	score_title.add_theme_font_size_override("font_size", 18)
	score_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	score_container.add_child(score_title)

	score_label = Label.new()
	score_label.text = "0"
	score_label.add_theme_font_size_override("font_size", 36)
	score_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	score_container.add_child(score_label)

	high_score_label = Label.new()
	high_score_label.text = "HI: 0"
	high_score_label.add_theme_font_size_override("font_size", 16)
	high_score_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	score_container.add_child(high_score_label)

	# Separator
	var separator2 = HSeparator.new()
	info_vbox.add_child(separator2)

	# Wave Section
	var wave_container = VBoxContainer.new()
	wave_container.add_theme_constant_override("separation", 10)
	info_vbox.add_child(wave_container)

	var wave_title = Label.new()
	wave_title.text = "WAVE"
	wave_title.add_theme_font_size_override("font_size", 18)
	wave_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	wave_container.add_child(wave_title)

	wave_label = Label.new()
	wave_label.text = "1 / 5"
	wave_label.add_theme_font_size_override("font_size", 28)
	wave_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	wave_container.add_child(wave_label)

	# Separator
	var separator3 = HSeparator.new()
	info_vbox.add_child(separator3)

	# Health Section
	var health_container = VBoxContainer.new()
	health_container.add_theme_constant_override("separation", 10)
	info_vbox.add_child(health_container)

	var health_title = Label.new()
	health_title.text = "HEALTH"
	health_title.add_theme_font_size_override("font_size", 18)
	health_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	health_container.add_child(health_title)

	health_bar = ProgressBar.new()
	health_bar.min_value = 0
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.custom_minimum_size = Vector2(0, 30)
	health_bar.show_percentage = false

	# Style the health bar
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 0.8, 0.2)
	fill_style.set_border_width_all(2)
	fill_style.border_color = Color(0.2, 0.6, 0.2)
	health_bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.3, 0.1, 0.1)
	bg_style.set_border_width_all(2)
	bg_style.border_color = Color(0.6, 0.2, 0.2)
	health_bar.add_theme_stylebox_override("background", bg_style)

	health_container.add_child(health_bar)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(spacer)

	# Combo label (centered in play area)
	combo_label = Label.new()
	combo_label.text = ""
	combo_label.add_theme_font_size_override("font_size", 48)
	combo_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	combo_label.anchor_left = SIDE_PANEL_WIDTH / viewport_size.x
	combo_label.anchor_right = (viewport_size.x - SIDE_PANEL_WIDTH) / viewport_size.x
	combo_label.anchor_top = 0.3
	combo_label.anchor_bottom = 0.4
	combo_label.visible = false
	add_child(combo_label)

func _connect_to_game() -> void:
	# Find game controller
	var controllers = get_tree().get_nodes_in_group("game_controller")
	if controllers.size() > 0:
		game_controller = controllers[0]
		if game_controller.has_signal("score_changed"):
			game_controller.score_changed.connect(_on_score_changed)

	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		_connect_to_player()

	# Find wave manager
	var managers = get_tree().get_nodes_in_group("wave_manager")
	if managers.size() > 0:
		wave_manager = managers[0]
		_connect_to_wave_manager()

	_update_display()

func _connect_to_player() -> void:
	if not player:
		return

	# Try to get health component
	await get_tree().process_frame
	if player.has_node("PlayerHost"):
		var host = player.get_node("PlayerHost")
		var health_component = host.get_component("HealthComponent")
		if health_component:
			health_component.health_changed.connect(_on_health_changed)
			_on_health_changed(health_component.current_health, health_component.current_health)

		var score_component = host.get_component("ScoreComponent")
		if score_component:
			score_component.score_changed.connect(_on_player_score_changed)
			score_component.combo_changed.connect(_on_combo_changed)

func _connect_to_wave_manager() -> void:
	if not wave_manager:
		return

	if wave_manager.has_signal("wave_started"):
		wave_manager.wave_started.connect(_on_wave_started)

func _on_score_changed(new_score: int) -> void:
	score_label.text = "%d" % new_score

	if game_controller:
		high_score_label.text = "HI: %d" % game_controller.get_high_score()

func _on_player_score_changed(new_score: int, _old_score: int) -> void:
	# This comes from player's ScoreComponent
	if game_controller:
		game_controller.add_score(new_score)

func _on_health_changed(new_health: int, _old_health: int) -> void:
	if health_bar:
		health_bar.value = new_health

		# Change color based on health
		var style_box: StyleBoxFlat = health_bar.get_theme_stylebox("fill")
		if new_health < 30:
			style_box.bg_color = Color(0.8, 0.2, 0.2)  # Red
		elif new_health < 60:
			style_box.bg_color = Color(0.8, 0.6, 0.2)  # Orange
		else:
			style_box.bg_color = Color(0.2, 0.8, 0.2)  # Green

func _on_wave_started(wave_number: int) -> void:
	if wave_manager:
		var total = wave_manager.get_total_waves()
		wave_label.text = "%d / %d" % [wave_number, total]

func _on_combo_changed(combo: int, _multiplier: float) -> void:
	if combo > 1:
		combo_label.text = "COMBO x%d!" % combo
		combo_label.visible = true

		# Fade out after 1 second
		var tween = create_tween()
		tween.tween_property(combo_label, "modulate:a", 0.0, 1.0).set_delay(1.0)
		tween.tween_callback(func(): combo_label.visible = false)
		tween.tween_property(combo_label, "modulate:a", 1.0, 0.0)
	else:
		combo_label.visible = false

func _update_display() -> void:
	if game_controller:
		_on_score_changed(game_controller.get_current_score())

## Get the play area rectangle (for movement bounds)
static func get_play_area() -> Rect2:
	var viewport_size = DisplayServer.window_get_size()
	return Rect2(
		Vector2(SIDE_PANEL_WIDTH, 0),
		Vector2(viewport_size.x - SIDE_PANEL_WIDTH * 2, viewport_size.y)
	)
