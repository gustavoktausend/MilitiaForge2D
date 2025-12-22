## SceneTransition - Autoload Singleton
##
## Manages scene transitions with customizable effects.
## Follows SOLID principles for reusability across projects.
##
## Usage:
##   SceneTransition.change_scene("res://path/to/scene.tscn", "fade")
##   SceneTransition.change_scene("res://path/to/scene.tscn", "glitch", 1.5)

extends CanvasLayer

# Preload base class
const TransitionEffect = preload("res://addons/scene_transition/transition_effect.gd")

#region Signals
signal transition_started(effect_name: String)
signal transition_midpoint()  # Fired when screen is fully covered (perfect moment to change scene)
signal transition_finished()
#endregion

#region Exports
@export var default_duration: float = 1.0
@export var default_effect: String = "fade"
#endregion

#region Private Variables
var current_effect: Control = null  # Changed to Control to avoid typing issues
var is_transitioning: bool = false
var target_scene_path: String = ""
var effect_registry: Dictionary = {}
#endregion

func _ready() -> void:
	# Set high z-index to appear over everything
	layer = 100

	# Register built-in effects
	_register_built_in_effects()

	print("[SceneTransition] Autoload ready! Registered effects: %s" % effect_registry.keys())

## Register a custom transition effect
func register_effect(effect_name: String, effect_instance: Control) -> void:
	if effect_registry.has(effect_name):
		push_warning("[SceneTransition] Effect '%s' already registered, overwriting..." % effect_name)

	effect_registry[effect_name] = effect_instance
	effect_instance.name = effect_name
	add_child(effect_instance)
	effect_instance.hide()

	print("[SceneTransition] Registered effect: %s" % effect_name)

## Main method to change scenes with transition
func change_scene(scene_path: String, effect_name: String = "", duration: float = -1.0) -> void:
	if is_transitioning:
		push_warning("[SceneTransition] Transition already in progress, ignoring request...")
		return

	if not ResourceLoader.exists(scene_path):
		push_error("[SceneTransition] Scene path does not exist: %s" % scene_path)
		return

	# Use defaults if not specified
	var effect_to_use = effect_name if effect_name != "" else default_effect
	var duration_to_use = duration if duration > 0 else default_duration

	if not effect_registry.has(effect_to_use):
		push_error("[SceneTransition] Effect '%s' not found! Available: %s" % [effect_to_use, effect_registry.keys()])
		return

	target_scene_path = scene_path
	is_transitioning = true
	current_effect = effect_registry[effect_to_use]

	print("[SceneTransition] Starting transition to '%s' using '%s' effect (%.1fs)" % [scene_path, effect_to_use, duration_to_use])

	transition_started.emit(effect_to_use)

	# Connect to effect signals
	if not current_effect.transition_midpoint.is_connected(_on_transition_midpoint):
		current_effect.transition_midpoint.connect(_on_transition_midpoint)
		print("[SceneTransition] Connected to midpoint signal")
	if not current_effect.transition_finished.is_connected(_on_transition_finished):
		current_effect.transition_finished.connect(_on_transition_finished)
		print("[SceneTransition] Connected to finished signal")

	# Play transition
	print("[SceneTransition] Calling play_transition on effect...")
	current_effect.play_transition(duration_to_use)
	print("[SceneTransition] play_transition called successfully")

## Reload current scene with transition
func reload_scene(effect_name: String = "", duration: float = -1.0) -> void:
	var current_scene = get_tree().current_scene
	if current_scene:
		change_scene(current_scene.scene_file_path, effect_name, duration)
	else:
		push_error("[SceneTransition] Cannot reload scene - no current scene found!")

## Called when transition reaches midpoint (screen fully covered)
func _on_transition_midpoint() -> void:
	print("[SceneTransition] Midpoint reached, changing scene to: %s" % target_scene_path)
	transition_midpoint.emit()

	# Change the actual scene
	get_tree().call_deferred("change_scene_to_file", target_scene_path)

## Called when transition finishes
func _on_transition_finished() -> void:
	print("[SceneTransition] Transition finished!")
	is_transitioning = false
	current_effect = null
	target_scene_path = ""
	transition_finished.emit()

## Register all built-in transition effects
func _register_built_in_effects() -> void:
	# Lazy load to avoid circular dependencies
	var FadeTransition = load("res://addons/scene_transition/effects/fade_transition.gd")
	var GlitchTransition = load("res://addons/scene_transition/effects/glitch_transition.gd")
	var WipeTransition = load("res://addons/scene_transition/effects/wipe_transition.gd")

	register_effect("fade", FadeTransition.new())
	register_effect("glitch", GlitchTransition.new())
	# Register wipes with integer direction values (0=LEFT, 1=RIGHT, 2=UP, 3=DOWN)
	register_effect("wipe_left", WipeTransition.new(0))
	register_effect("wipe_right", WipeTransition.new(1))
	register_effect("wipe_up", WipeTransition.new(2))
	register_effect("wipe_down", WipeTransition.new(3))

## Get list of registered effects
func get_available_effects() -> Array[String]:
	var effects: Array[String] = []
	effects.assign(effect_registry.keys())
	return effects

## Check if currently transitioning
func is_busy() -> bool:
	return is_transitioning
