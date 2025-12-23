extends Node2D

@onready var host = $DummyPlayer
@onready var health_comp = $DummyPlayer/HealthComponent
@onready var damage_btn = $HUD/Controls/DamageButton
@onready var heal_btn = $HUD/Controls/HealButton
@onready var hud_widget = $HUD/HealthBarWidget

func _ready():
	# Connect buttons
	damage_btn.pressed.connect(_on_damage_pressed)
	heal_btn.pressed.connect(_on_heal_pressed)
	
	# Manually setup widget (Dependency Injection)
	hud_widget.setup(host)
	print("Test Scene Ready: Health Component linked to Widget")

func _on_damage_pressed():
	health_comp.take_damage(10)

func _on_heal_pressed():
	health_comp.heal(10)
