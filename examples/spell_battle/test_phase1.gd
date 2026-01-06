## Phase 1 Test Script
##
## Tests all resources and components created in Phase 1
## Run this script to validate implementation

extends Node

func _ready() -> void:
	print("\n========================================")
	print("SPELL BATTLE - PHASE 1 VALIDATION TEST")
	print("========================================\n")

	test_chip_database()
	test_navi_database()
	test_deck_configuration()
	test_chip_data()
	test_navi_data()

	print("\n========================================")
	print("ALL TESTS COMPLETED")
	print("========================================\n")

## Test ChipDatabase
func test_chip_database() -> void:
	print("--- Testing ChipDatabase ---")

	# Test getting all chip names
	var all_chips = ChipDatabase.get_all_chip_names()
	print("✓ Total chips available: %d" % all_chips.size())
	assert(all_chips.size() == 14, "Expected 14 chips")

	# Test creating chips
	var fireball = ChipDatabase.get_chip("fireball")
	assert(fireball != null, "Fireball should exist")
	assert(fireball.chip_name == "Fireball", "Fireball name mismatch")
	assert(fireball.chip_type == ChipData.ChipType.PROJECTILE, "Fireball should be PROJECTILE")
	assert(fireball.element == ChipData.ElementType.FIRE, "Fireball should be FIRE element")
	print("✓ Fireball chip created successfully")

	var sword = ChipDatabase.get_chip("sword_slash")
	assert(sword != null, "Sword Slash should exist")
	assert(sword.chip_type == ChipData.ChipType.MELEE, "Sword should be MELEE")
	assert(sword.attack_range == ChipData.AttackRange.MELEE, "Sword should have MELEE range")
	print("✓ Sword Slash chip created successfully")

	var barrier = ChipDatabase.get_chip("barrier")
	assert(barrier != null, "Barrier should exist")
	assert(barrier.chip_type == ChipData.ChipType.SHIELD, "Barrier should be SHIELD")
	assert(barrier.damage == 0, "Barrier should have 0 damage")
	print("✓ Barrier chip created successfully")

	# Test filtering
	var projectiles = ChipDatabase.get_chips_by_type(ChipData.ChipType.PROJECTILE)
	print("✓ Projectile chips: %d" % projectiles.size())
	assert(projectiles.size() == 4, "Expected 4 projectile chips")

	var fire_chips = ChipDatabase.get_chips_by_element(ChipData.ElementType.FIRE)
	print("✓ Fire chips: %d" % fire_chips.size())

	var rare_chips = ChipDatabase.get_chips_by_rarity("Rare")
	print("✓ Rare chips: %d" % rare_chips.size())

	# Test invalid chip
	var invalid = ChipDatabase.get_chip("nonexistent")
	assert(invalid == null, "Invalid chip should return null")
	print("✓ Invalid chip handling works")

	print("✓ ChipDatabase: ALL TESTS PASSED\n")

## Test NaviDatabase
func test_navi_database() -> void:
	print("--- Testing NaviDatabase ---")

	# Test getting all navis
	var all_navis = NaviDatabase.get_all_navi_names()
	print("✓ Total navis available: %d" % all_navis.size())
	assert(all_navis.size() == 8, "Expected 8 navis")

	# Test creating navis
	var megaman = NaviDatabase.get_navi("megaman")
	assert(megaman != null, "MegaMan should exist")
	assert(megaman.navi_name == "MegaMan.EXE", "MegaMan name mismatch")
	assert(megaman.max_hp == 150, "MegaMan should have 150 HP")
	assert(megaman.element == ChipData.ElementType.NONE, "MegaMan should be NONE element")
	assert(megaman.default_attack_damage == 10, "MegaMan default attack should be 10")
	print("✓ MegaMan navi created successfully")

	var fireman = NaviDatabase.get_navi("fireman")
	assert(fireman != null, "FireMan should exist")
	assert(fireman.element == ChipData.ElementType.FIRE, "FireMan should be FIRE element")
	assert(fireman.default_attack_element == ChipData.ElementType.FIRE, "FireMan default attack should be FIRE")
	print("✓ FireMan navi created successfully")

	var protoman = NaviDatabase.get_navi("protoman")
	assert(protoman != null, "ProtoMan should exist")
	assert(protoman.default_attack_type == ChipData.ChipType.MELEE, "ProtoMan should have MELEE default attack")
	assert(protoman.default_attack_damage == 20, "ProtoMan should have high damage")
	print("✓ ProtoMan navi created successfully")

	# Test resistances
	var aquaman = NaviDatabase.get_navi("aquaman")
	var fire_damage = aquaman.get_modified_damage(100, ChipData.ElementType.FIRE)
	assert(fire_damage < 100, "AquaMan should resist fire")
	print("✓ AquaMan fire resistance: %d damage (from 100)" % fire_damage)

	var electric_damage = aquaman.get_modified_damage(100, ChipData.ElementType.ELECTRIC)
	assert(electric_damage > 100, "AquaMan should be weak to electric")
	print("✓ AquaMan electric weakness: %d damage (from 100)" % electric_damage)

	# Test filtering
	var fire_navis = NaviDatabase.get_navis_by_element(ChipData.ElementType.FIRE)
	print("✓ Fire navis: %d" % fire_navis.size())

	var epic_navis = NaviDatabase.get_navis_by_rarity("Epic")
	print("✓ Epic navis: %d" % epic_navis.size())

	var melee_navis = NaviDatabase.get_navis_by_attack_type(ChipData.ChipType.MELEE)
	print("✓ MELEE default attack navis: %d" % melee_navis.size())
	assert(melee_navis.size() == 2, "Expected 2 melee navis (ProtoMan, GutsMan)")

	print("✓ NaviDatabase: ALL TESTS PASSED\n")

## Test DeckConfiguration
func test_deck_configuration() -> void:
	print("--- Testing DeckConfiguration ---")

	var deck = DeckConfiguration.new()
	deck.deck_name = "Test Deck"

	# Build a valid deck (2-3-4 structure)
	deck.column_1 = ["fireball", "ice_shard"]
	deck.column_2 = ["thunder_bolt", "wind_cutter", "sword_slash"]
	deck.column_3 = ["flame_punch", "thunder_fist", "meteor_storm", "blizzard"]
	deck.slot_in_chips = ["power_up", "barrier"]

	# Validate deck
	var validation = deck.validate()
	if validation["valid"]:
		print("✓ Deck validation: PASSED")
	else:
		print("✗ Deck validation: FAILED")
		for error in validation["errors"]:
			print("  Error: %s" % error)
		assert(false, "Deck should be valid")

	# Test deck queries
	var all_chips = deck.get_all_chip_names()
	assert(all_chips.size() == 11, "Expected 11 chips total (9 main + 2 slot-in)")
	print("✓ Total chips in deck: %d" % all_chips.size())

	var main_chips = deck.get_main_deck_chip_names()
	assert(main_chips.size() == 9, "Expected 9 main deck chips")
	print("✓ Main deck chips: %d" % main_chips.size())

	# Test grid access
	var chip_0_0 = deck.get_chip_at_grid(0, 0)
	assert(chip_0_0 == "fireball", "Column 0 Row 0 should be fireball")
	print("✓ Grid access works: [0,0] = %s" % chip_0_0)

	# Test statistics
	var element_dist = deck.get_element_distribution()
	print("✓ Element distribution: %s" % element_dist)

	var type_dist = deck.get_chip_type_distribution()
	print("✓ Chip type distribution: %s" % type_dist)

	var avg_damage = deck.get_average_damage()
	print("✓ Average deck damage: %.1f" % avg_damage)

	# Test invalid deck
	var invalid_deck = DeckConfiguration.new()
	invalid_deck.column_1 = ["fireball"]  # Too few chips
	invalid_deck.column_2 = ["ice_shard"]
	invalid_deck.column_3 = ["thunder_bolt"]
	invalid_deck.slot_in_chips = ["barrier"]

	var invalid_validation = invalid_deck.validate()
	assert(not invalid_validation["valid"], "Invalid deck should fail validation")
	print("✓ Invalid deck detection works")

	print("✓ DeckConfiguration: ALL TESTS PASSED\n")

## Test ChipData helpers
func test_chip_data() -> void:
	print("--- Testing ChipData Helpers ---")

	var fireball = ChipDatabase.get_chip("fireball")

	# Test helper methods
	assert(fireball.is_offensive(), "Fireball should be offensive")
	assert(not fireball.is_support(), "Fireball should not be support")
	assert(fireball.has_element(), "Fireball should have element")
	print("✓ ChipData helper methods work")

	var barrier = ChipDatabase.get_chip("barrier")
	assert(barrier.is_support(), "Barrier should be support")
	assert(not barrier.is_offensive(), "Barrier should not be offensive")
	print("✓ Support chip detection works")

	# Test info text
	var info = fireball.get_info_text()
	assert(info.length() > 0, "Info text should not be empty")
	print("✓ Chip info text generation works")

	print("✓ ChipData: ALL TESTS PASSED\n")

## Test NaviData helpers
func test_navi_data() -> void:
	print("--- Testing NaviData Helpers ---")

	var fireman = NaviDatabase.get_navi("fireman")

	# Test elemental resistance
	var fire_res = fireman.get_element_resistance(ChipData.ElementType.FIRE)
	assert(fire_res == 0.5, "FireMan should have 0.5 fire resistance")
	print("✓ Fire resistance: %.1fx" % fire_res)

	var water_res = fireman.get_element_resistance(ChipData.ElementType.WATER)
	assert(water_res == 1.5, "FireMan should have 1.5 water vulnerability")
	print("✓ Water vulnerability: %.1fx" % water_res)

	# Test damage modification
	var base_damage = 100
	var fire_damage = fireman.get_modified_damage(base_damage, ChipData.ElementType.FIRE)
	assert(fire_damage == 50, "100 fire damage should become 50")
	print("✓ Fire damage modification: %d -> %d" % [base_damage, fire_damage])

	var water_damage = fireman.get_modified_damage(base_damage, ChipData.ElementType.WATER)
	assert(water_damage == 150, "100 water damage should become 150")
	print("✓ Water damage modification: %d -> %d" % [base_damage, water_damage])

	# Test info text
	var info = fireman.get_info_text()
	assert(info.length() > 0, "Info text should not be empty")
	print("✓ Navi info text generation works")

	print("✓ NaviData: ALL TESTS PASSED\n")
