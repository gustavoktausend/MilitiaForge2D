## Phase 2 Test Script
##
## Tests all battle system components created in Phase 2
## Run this script to validate battle mechanics

extends Node

## Test results tracking
var _tests_passed: int = 0
var _tests_failed: int = 0

func _ready() -> void:
	print("\n========================================")
	print("SPELL BATTLE - PHASE 2 VALIDATION TEST")
	print("========================================\n")

	await test_navi_component()
	await test_battle_manager()
	await test_spell_casting()
	await test_integration()

	print("\n========================================")
	print("TEST RESULTS")
	print("========================================")
	print("✓ Passed: %d" % _tests_passed)
	print("✗ Failed: %d" % _tests_failed)
	print("Total: %d" % (_tests_passed + _tests_failed))
	print("========================================\n")

	# Exit after tests
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()

## Test NaviComponent
func test_navi_component() -> void:
	print("--- Testing NaviComponent ---")

	# Create test Navi entity
	var navi_entity = Node2D.new()
	navi_entity.name = "TestNavi"
	add_child(navi_entity)

	# Add NaviComponent
	var navi_comp = NaviComponent.new()
	navi_comp.navi_data = NaviDatabase.get_navi("megaman")
	navi_comp.debug_navi = false
	navi_entity.add_child(navi_comp)

	await get_tree().process_frame

	# Test HP management
	assert_test(navi_comp.get_current_hp() == 150, "Initial HP should be 150")
	assert_test(navi_comp.get_max_hp() == 150, "Max HP should be 150")

	# Test damage
	var damage_dealt = navi_comp.take_damage(50, null, ChipData.ElementType.NONE)
	assert_test(damage_dealt == 50, "Should take 50 damage")
	assert_test(navi_comp.get_current_hp() == 100, "HP should be 100 after 50 damage")

	# Test elemental resistance (MegaMan is resistant to electric)
	damage_dealt = navi_comp.take_damage(100, null, ChipData.ElementType.ELECTRIC)
	assert_test(damage_dealt == 70, "Should take 70 electric damage (0.7x resistance)")
	assert_test(navi_comp.get_current_hp() == 30, "HP should be 30")

	# Test healing
	navi_comp.heal(50)
	assert_test(navi_comp.get_current_hp() == 80, "HP should be 80 after heal")

	# Test full heal
	navi_comp.restore_full_hp()
	assert_test(navi_comp.get_current_hp() == 150, "HP should be 150 after full restore")

	# Test chip counter
	navi_comp.register_chip_used()
	assert_test(navi_comp.get_chips_used() == 1, "Should have 1 chip used")

	navi_comp.register_chip_used()
	navi_comp.register_chip_used()
	assert_test(navi_comp.get_chips_used() == 0, "Should reset after 3 chips (default attack)")

	# Test defeat
	navi_comp.take_damage(200, null, ChipData.ElementType.NONE)
	assert_test(navi_comp.is_defeated(), "Navi should be defeated")
	assert_test(navi_comp.get_current_hp() == 0, "HP should be 0")

	# Cleanup
	navi_entity.queue_free()

	print("✓ NaviComponent: Tests completed\n")

## Test BattleManagerComponent
func test_battle_manager() -> void:
	print("--- Testing BattleManagerComponent ---")

	# Create battle manager entity
	var manager_entity = Node.new()
	manager_entity.name = "BattleManager"
	add_child(manager_entity)

	# Create player Navi
	var player_entity = Node2D.new()
	player_entity.name = "Player"
	add_child(player_entity)

	var player_navi = NaviComponent.new()
	player_navi.navi_data = NaviDatabase.get_navi("megaman")
	player_entity.add_child(player_navi)

	# Create enemy Navi
	var enemy_entity = Node2D.new()
	enemy_entity.name = "Enemy"
	add_child(enemy_entity)

	var enemy_navi = NaviComponent.new()
	enemy_navi.navi_data = NaviDatabase.get_navi("fireman")
	enemy_entity.add_child(enemy_navi)

	# Add BattleManagerComponent
	var battle_manager = BattleManagerComponent.new()
	battle_manager.player_navi = player_entity
	battle_manager.enemy_navi = enemy_entity
	battle_manager.max_turns = 10
	battle_manager.debug_battle = false
	manager_entity.add_child(battle_manager)

	await get_tree().process_frame

	# Test battle start
	battle_manager.start_battle()
	assert_test(battle_manager.is_battle_active(), "Battle should be active")
	assert_test(battle_manager.get_current_turn() >= 1, "Turn should be 1 or higher")

	# Test victory condition - player wins by HP
	enemy_navi.take_damage(200, null)
	await get_tree().process_frame

	assert_test(enemy_navi.is_defeated(), "Enemy should be defeated")
	assert_test(not battle_manager.is_battle_active(), "Battle should end")
	assert_test(battle_manager.get_battle_result() == BattleManagerComponent.BattleResult.PLAYER_WIN, "Player should win")

	# Cleanup
	manager_entity.queue_free()
	player_entity.queue_free()
	enemy_entity.queue_free()

	print("✓ BattleManagerComponent: Tests completed\n")

## Test SpellCastingComponent
func test_spell_casting() -> void:
	print("--- Testing SpellCastingComponent ---")

	# Create caster Navi
	var caster_entity = Node2D.new()
	caster_entity.name = "Caster"
	caster_entity.position = Vector2(100, 100)
	add_child(caster_entity)

	var caster_navi = NaviComponent.new()
	caster_navi.navi_data = NaviDatabase.get_navi("megaman")
	caster_entity.add_child(caster_navi)

	# Create target Navi
	var target_entity = Node2D.new()
	target_entity.name = "Target"
	target_entity.position = Vector2(300, 100)
	add_child(target_entity)

	var target_navi = NaviComponent.new()
	target_navi.navi_data = NaviDatabase.get_navi("fireman")
	target_entity.add_child(target_navi)

	# Add SpellCastingComponent
	var spell_casting = SpellCastingComponent.new()
	spell_casting.caster = caster_entity
	spell_casting.use_targeting = false  # Skip targeting for simplicity
	spell_casting.debug_casting = false
	caster_entity.add_child(spell_casting)

	await get_tree().process_frame

	# Test casting different chip types
	var fireball = ChipDatabase.get_chip("fireball")

	# Note: Without proper spell scenes, this will log warnings but shouldn't crash
	# In real implementation, we'd need actual spell scenes

	# Test melee attack (instant damage)
	var sword = ChipDatabase.get_chip("sword_slash")
	var target_hp_before = target_navi.get_current_hp()

	spell_casting.cast_spell(sword, target_entity)
	await get_tree().process_frame

	# Melee should deal instant damage
	assert_test(target_navi.get_current_hp() < target_hp_before, "Melee should deal damage")

	# Test buff casting
	var power_up = ChipDatabase.get_chip("power_up")

	# This will work if target has StatusEffectComponent
	# For this test, we'll just verify no crash
	spell_casting.cast_spell(power_up, caster_entity)
	await get_tree().process_frame

	# Verify chip usage registered
	assert_test(caster_navi.get_chips_used() == 2, "Should have 2 chips used")

	# Cleanup
	caster_entity.queue_free()
	target_entity.queue_free()

	print("✓ SpellCastingComponent: Tests completed\n")

## Test full integration scenario
func test_integration() -> void:
	print("--- Testing Full Integration ---")

	# Create complete battle scenario
	var battle_root = Node.new()
	battle_root.name = "BattleScene"
	add_child(battle_root)

	# Create player
	var player = Node2D.new()
	player.name = "Player"
	player.position = Vector2(200, 300)
	battle_root.add_child(player)

	var player_navi = NaviComponent.new()
	player_navi.navi_data = NaviDatabase.get_navi("megaman")
	player.add_child(player_navi)

	var player_deck = ProgramDeckComponent.new()
	var deck_config = DeckConfiguration.new()
	deck_config.column_1 = ["fireball", "ice_shard"]
	deck_config.column_2 = ["thunder_bolt", "wind_cutter", "sword_slash"]
	deck_config.column_3 = ["flame_punch", "meteor_storm", "blizzard", "power_up"]
	deck_config.slot_in_chips = ["barrier", "chip_breaker"]
	player_deck.deck_config = deck_config
	player.add_child(player_deck)

	var player_gauge = SlotInGaugeComponent.new()
	player.add_child(player_gauge)

	var player_casting = SpellCastingComponent.new()
	player_casting.caster = player
	player.add_child(player_casting)

	# Create enemy
	var enemy = Node2D.new()
	enemy.name = "Enemy"
	enemy.position = Vector2(600, 300)
	battle_root.add_child(enemy)

	var enemy_navi = NaviComponent.new()
	enemy_navi.navi_data = NaviDatabase.get_navi("fireman")
	enemy.add_child(enemy_navi)

	# Create battle manager
	var battle_manager = BattleManagerComponent.new()
	battle_manager.player_navi = player
	battle_manager.enemy_navi = enemy
	battle_manager.max_turns = 10
	battle_root.add_child(battle_manager)

	await get_tree().process_frame

	# Start battle
	battle_manager.start_battle()
	assert_test(battle_manager.is_battle_active(), "Integration: Battle should start")

	# Simulate turn 1 - chip selection
	var offered_chips = player_deck.offer_chips_for_turn()
	assert_test(offered_chips.size() == 3, "Integration: Should offer 3 chips")

	# Select first chip
	var selected_chip = player_deck.select_chip(0)
	assert_test(selected_chip != null, "Integration: Should select chip")

	# Cast selected chip at enemy
	player_casting.cast_spell(selected_chip, enemy)
	await get_tree().process_frame

	assert_test(player_navi.get_chips_used() == 1, "Integration: Should register chip usage")

	# Check Slot-In gauge incremented
	assert_test(player_gauge.get_gauge_percentage() > 0, "Integration: Slot-In gauge should fill")

	# Simulate damage to trigger victory
	enemy_navi.take_damage(200, null)
	await get_tree().process_frame

	assert_test(not battle_manager.is_battle_active(), "Integration: Battle should end")

	# Cleanup
	battle_root.queue_free()

	print("✓ Integration: Tests completed\n")

## Assert helper
func assert_test(condition: bool, message: String) -> void:
	if condition:
		_tests_passed += 1
		print("  ✓ %s" % message)
	else:
		_tests_failed += 1
		print("  ✗ FAILED: %s" % message)
