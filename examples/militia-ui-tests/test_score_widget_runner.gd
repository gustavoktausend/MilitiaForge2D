extends Node2D

@onready var host = $DummyPlayer
@onready var score_comp = $DummyPlayer/ScoreComponent
@onready var add_btn = $HUD/Controls/AddScoreBtn
@onready var combo_btn = $HUD/Controls/ComboBtn
@onready var score_widget = $HUD/ScoreWidget

func _ready():
	add_btn.pressed.connect(_on_add_score)
	combo_btn.pressed.connect(_on_combo)
	
	score_widget.setup(host)
	print("Test Scene Ready: Score Component linked to Widget")

func _on_add_score():
	score_comp.add_score(100)

func _on_combo():
	score_comp.increment_combo()
