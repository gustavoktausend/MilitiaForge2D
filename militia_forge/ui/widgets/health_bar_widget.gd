## Health Bar Widget
##
## A specialized UI widget that visualizes a HealthComponent.
## Extends a standard ProgressBar but manages its own logical state.
##
## Features:
## - Auto-connection to HealthComponent
## - Optional value smoothing/animation
## - Critical health visual states (optional hook)
##
## @tutorial(UI System): res://docs/ui/components/health_bar.md

class_name HealthBarWidget extends BaseUIWidget

#region Node References
## The ProgressBar to update.
## If null, assumes 'self' is the ProgressBar (if script attached directly)
## or tries to find a child ProgressBar.
@export var progress_bar: ProgressBar
#endregion

#region Exports
@export_group("Animation")
## Whether to animate value changes
@export var animate_changes: bool = true

## Duration of the fill animation
@export var animation_duration: float = 0.2

@export_group("Visuals")
## Color to flash when taking damage (Optional)
@export var damage_flash_color: Color = Color.RED
#endregion

#region Private Variables
var _tween: Tween
#endregion

#region Lifecycle
func _ready() -> void:
	super._ready()
	
	# Auto-find progress bar if not assigned
	# Auto-find progress bar if not assigned
	if not progress_bar:
		var found = find_child("ProgressBar", true, false)
		if found:
			progress_bar = found as ProgressBar
	
	if not progress_bar:
		push_warning("HealthBarWidget: No ProgressBar found or assigned!")
#endregion

#region BaseUIWidget Overrides
func _connect_to_components() -> void:
	var health_comp = _host.get_component("HealthComponent")
	if health_comp:
		safe_connect(health_comp, "health_changed", _on_health_changed)
		# Initial state
		_update_progress(health_comp.current_health, health_comp.max_health, false)
	else:
		push_warning("HealthBarWidget: Host has no HealthComponent")

func _update_visuals() -> void:
	# Triggered manually or by base class
	if _host:
		var health_comp = _host.get_component("HealthComponent")
		if health_comp:
			_update_progress(health_comp.current_health, health_comp.max_health, false)

func _disconnect_signals() -> void:
	# Base class handles host clearing, but we can kill tweens here
	if _tween:
		_tween.kill()
#endregion

#region Private Methods
func _on_health_changed(new_health: int, _old_health: int) -> void:
	var max_hp = 100
	var health_comp = _host.get_component("HealthComponent")
	if health_comp:
		max_hp = health_comp.max_health
	
	_update_progress(new_health, max_hp, animate_changes)

func _update_progress(current: int, max_hp: int, animate: bool) -> void:
	if not progress_bar:
		return
	
	progress_bar.max_value = max_hp
	
	if animate and is_inside_tree():
		if _tween:
			_tween.kill()
		_tween = create_tween()
		_tween.tween_property(progress_bar, "value", float(current), animation_duration) \
			.set_trans(Tween.TRANS_SINE) \
			.set_ease(Tween.EASE_OUT)
	else:
		progress_bar.value = current
#endregion
