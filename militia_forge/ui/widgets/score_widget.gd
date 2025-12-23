## Score Widget
##
## A specialized UI widget that visualizes a ScoreComponent.
## Can handle formatting and combo displays.
##
## Features:
## - Auto-connection to ScoreComponent
## - Customizable string formatting
## - Combo display support (optional)
##
## @tutorial(UI System): res://docs/ui/components/score.md

class_name ScoreWidget extends BaseUIWidget

#region Node References
## The Label to update text on.
## If null, assumes 'self' is the Label.
@export var score_label: Label
#endregion

#region Exports
@export_group("Formatting")
## Format string for the score display.
## Use %d for the score value.
## Examples: "Score: %d", "%06d", "PTS: %s"
@export var format_string: String = "Score: %d"

@export_group("Combo")
## Whether to show combo info (if available)
@export var show_combo: bool = false
#endregion

#region Lifecycle
func _ready() -> void:
	super._ready()
	
	# Auto-find label
	# Auto-find label
	if not score_label:
		var found = find_child("Label", true, false)
		if found:
			score_label = found as Label
	
	if not score_label:
		push_warning("ScoreWidget: No Label found or assigned!")
#endregion

#region BaseUIWidget Overrides
func _connect_to_components() -> void:
	var score_comp = _host.get_component("ScoreComponent")
	if score_comp:
		safe_connect(score_comp, "score_changed", _on_score_changed)
		_update_text(score_comp.current_score)
	else:
		push_warning("ScoreWidget: Host has no ScoreComponent")

func _update_visuals() -> void:
	if _host:
		var score_comp = _host.get_component("ScoreComponent")
		if score_comp:
			_update_text(score_comp.current_score)

#endregion

#region Private Methods
func _on_score_changed(new_score: int, _delta: int) -> void:
	_update_text(new_score)

func _update_text(score: int) -> void:
	if not score_label:
		return
	
	# Simple format check
	if "%" in format_string:
		score_label.text = format_string % score
	else:
		score_label.text = format_string + str(score)
#endregion
