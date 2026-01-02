## Main Menu for Space Shooter
##
## Displays title, buttons for Play/Options/Quit, and animated background.

extends Control

#region Node References
var play_button: Button
var options_button: Button
var quit_button: Button
var title_label: Label
var high_score_label: Label
var version_label: Label
var background: ColorRect
#endregion

#region Constants
# Using SceneManager key names instead of paths
const LOADOUT_SELECTION_KEY = "loadout_selection"
#endregion

func _ready() -> void:
	print("[MainMenu] Initializing...")
	_create_menu()
	_load_high_score()
	_animate_entrance()

func _create_menu() -> void:
	var viewport_size = get_viewport().get_visible_rect().size

	# Background
	background = ColorRect.new()
	background.color = Color(0.05, 0.05, 0.1)
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	add_child(background)

	# Animated stars background (simple version)
	_create_star_field()

	# Center container
	var center = CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	# Main VBox
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 40)
	center.add_child(vbox)

	# Title
	title_label = Label.new()
	title_label.text = "SPACE SHOOTER"
	title_label.add_theme_font_size_override("font_size", 72)
	title_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "⚡ MILITIA FORGE 2D ⚡"
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer1)

	# High Score display
	high_score_label = Label.new()
	high_score_label.text = "HIGH SCORE: 0"
	high_score_label.add_theme_font_size_override("font_size", 28)
	high_score_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	high_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(high_score_label)

	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(spacer2)

	# Buttons container
	var buttons_vbox = VBoxContainer.new()
	buttons_vbox.add_theme_constant_override("separation", 20)
	vbox.add_child(buttons_vbox)

	# Play button
	play_button = _create_menu_button("PLAY", Color(0.2, 0.7, 0.3))
	play_button.pressed.connect(_on_play_pressed)
	buttons_vbox.add_child(play_button)

	# Options button
	options_button = _create_menu_button("OPTIONS", Color(0.5, 0.5, 0.6))
	options_button.pressed.connect(_on_options_pressed)
	buttons_vbox.add_child(options_button)

	# Quit button
	quit_button = _create_menu_button("QUIT", Color(0.7, 0.3, 0.3))
	quit_button.pressed.connect(_on_quit_pressed)
	buttons_vbox.add_child(quit_button)

	# Spacer
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(spacer3)

	# Version/Credits
	version_label = Label.new()
	version_label.text = "v1.0.0 | Made with Godot 4"
	version_label.add_theme_font_size_override("font_size", 16)
	version_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(version_label)

	print("[MainMenu] Menu created")

func _create_menu_button(text: String, base_color: Color) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(300, 70)
	button.add_theme_font_size_override("font_size", 32)

	# Normal state
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = base_color
	normal_style.set_corner_radius_all(10)
	normal_style.set_border_width_all(3)
	normal_style.border_color = base_color.lightened(0.2)
	button.add_theme_stylebox_override("normal", normal_style)

	# Hover state
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = base_color.lightened(0.3)
	hover_style.set_corner_radius_all(10)
	hover_style.set_border_width_all(3)
	hover_style.border_color = base_color.lightened(0.5)
	button.add_theme_stylebox_override("hover", hover_style)

	# Pressed state
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = base_color.darkened(0.3)
	pressed_style.set_corner_radius_all(10)
	pressed_style.set_border_width_all(3)
	pressed_style.border_color = base_color
	button.add_theme_stylebox_override("pressed", pressed_style)

	return button

func _create_star_field() -> void:
	# Create simple animated stars in background
	var stars_container = Node2D.new()
	stars_container.name = "Stars"
	background.add_child(stars_container)

	var viewport_size = get_viewport().get_visible_rect().size

	# Create 100 stars
	for i in range(100):
		var star = ColorRect.new()
		star.color = Color(1, 1, 1, randf_range(0.3, 1.0))
		var star_size = randi_range(1, 3)
		star.custom_minimum_size = Vector2(star_size, star_size)
		star.position = Vector2(
			randf_range(0, viewport_size.x),
			randf_range(0, viewport_size.y)
		)

		stars_container.add_child(star)

		# Animate with tween (slow movement downward)
		var tween = create_tween().set_loops()
		var duration = randf_range(3.0, 8.0)
		tween.tween_property(star, "position:y", viewport_size.y + 10, duration)
		tween.tween_callback(func():
			star.position.y = -10
			star.position.x = randf_range(0, viewport_size.x)
		)

func _animate_entrance() -> void:
	# Animate title entrance
	if title_label:
		title_label.modulate.a = 0.0
		title_label.position.y = -50

		var tween = create_tween().set_parallel(true)
		tween.tween_property(title_label, "modulate:a", 1.0, 0.8)
		tween.tween_property(title_label, "position:y", 0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Animate buttons with stagger
	await get_tree().create_timer(0.3).timeout

	var buttons = [play_button, options_button, quit_button]
	for i in range(buttons.size()):
		if buttons[i]:
			buttons[i].modulate.a = 0.0
			buttons[i].scale = Vector2(0.8, 0.8)

			await get_tree().create_timer(0.1).timeout

			var tween = create_tween().set_parallel(true)
			tween.tween_property(buttons[i], "modulate:a", 1.0, 0.5)
			tween.tween_property(buttons[i], "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _load_high_score() -> void:
	if FileAccess.file_exists("user://highscore.save"):
		var file = FileAccess.open("user://highscore.save", FileAccess.READ)
		var high_score = file.get_32()
		file.close()

		if high_score_label:
			high_score_label.text = "HIGH SCORE: %d" % high_score
			print("[MainMenu] Loaded high score: %d" % high_score)
	else:
		print("[MainMenu] No high score file found")

func _on_play_pressed() -> void:
	print("[MainMenu] PLAY pressed - Loading loadout selection...")

	# Play UI sound
	AudioManager.play_ui_sound("button_click", 1.0)

	# Transition to loadout selection with squares effect (retro blocks)
	var fade_out_options = SceneManager.create_options(0.5, "squares")  # 0.5s squares out
	var fade_in_options = SceneManager.create_options(0.3, "squares")   # 0.3s squares in
	var general_options = SceneManager.create_general_options()

	SceneManager.change_scene(LOADOUT_SELECTION_KEY, fade_out_options, fade_in_options, general_options)

func _on_options_pressed() -> void:
	print("[MainMenu] OPTIONS pressed")
	# TODO: Create options menu
	# For now, just show a message
	_show_coming_soon("Options menu coming soon!")

func _on_quit_pressed() -> void:
	print("[MainMenu] QUIT pressed - Exiting game...")

	# Play UI sound
	AudioManager.play_ui_sound("button_click", 0.8)

	# Use SceneManager to quit with squares effect
	var fade_out_options = SceneManager.create_options(0.5, "squares")
	var fade_in_options = SceneManager.create_options(0.3, "squares")
	var general_options = SceneManager.create_general_options()

	SceneManager.change_scene("exit", fade_out_options, fade_in_options, general_options)

func _show_coming_soon(message: String) -> void:
	# Show temporary message
	var popup = Label.new()
	popup.text = message
	popup.add_theme_font_size_override("font_size", 28)
	popup.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.anchor_right = 1.0
	popup.anchor_bottom = 1.0
	popup.modulate.a = 0.0
	add_child(popup)

	# Fade in, wait, fade out
	var tween = create_tween()
	tween.tween_property(popup, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.0)
	tween.tween_property(popup, "modulate:a", 0.0, 0.3)
	tween.tween_callback(popup.queue_free)
