## Simple Syntax Test
## Just checks if all classes load correctly

extends Node

func _ready() -> void:
	print("\n=== SPELL BATTLE - SYNTAX VALIDATION ===\n")

	# Test Resources
	print("Testing Resources...")
	var chip = ChipData.new()
	print("✓ ChipData loaded")

	var navi = NaviData.new()
	print("✓ NaviData loaded")

	var deck_config = DeckConfiguration.new()
	print("✓ DeckConfiguration loaded")

	# Test Databases
	print("\nTesting Databases...")
	var fireball = ChipDatabase.get_chip("fireball")
	if fireball:
		print("✓ ChipDatabase working - created Fireball")

	var megaman = NaviDatabase.get_navi("megaman")
	if megaman:
		print("✓ NaviDatabase working - created MegaMan")

	# Test Components
	print("\nTesting Components...")
	var chip_comp = ChipComponent.new()
	print("✓ ChipComponent instantiated")
	chip_comp.free()

	var navi_comp = NaviComponent.new()
	print("✓ NaviComponent instantiated")
	navi_comp.free()

	var deck_comp = ProgramDeckComponent.new()
	print("✓ ProgramDeckComponent instantiated")
	deck_comp.free()

	var gauge_comp = SlotInGaugeComponent.new()
	print("✓ SlotInGaugeComponent instantiated")
	gauge_comp.free()

	var field_comp = BattleFieldComponent.new()
	print("✓ BattleFieldComponent instantiated")
	field_comp.free()

	var battle_mgr = BattleManagerComponent.new()
	print("✓ BattleManagerComponent instantiated")
	battle_mgr.free()

	var casting_comp = SpellCastingComponent.new()
	print("✓ SpellCastingComponent instantiated")
	casting_comp.free()

	print("\n=== ALL CLASSES LOADED SUCCESSFULLY! ===\n")

	# Quit
	get_tree().quit()
