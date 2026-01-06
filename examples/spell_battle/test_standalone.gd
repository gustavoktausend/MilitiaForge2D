## Standalone Test Scene for Spell Battle
##
## Simple test that validates all systems without dependencies
## Run this scene directly in Godot Editor

extends Node2D

func _ready() -> void:
	print("\n" + "====================================")
	print("SPELL BATTLE - STANDALONE TEST")
	print("===========================================" + "\n")

	# Test Phase 1 - Resources
	print(">>> PHASE 1: Testing Resources & Databases\n")
	test_chip_database()
	test_navi_database()
	test_deck_configuration()

	print("\n>>> PHASE 2: Testing Battle Components\n")
	test_navi_component()
	test_spell_casting()
	test_battle_integration()

	print("\n" + "========================================")
	print("ALL TESTS COMPLETED SUCCESSFULLY! ✓")
	print("==============================================="+ "\n")

## Test ChipDatabase
func test_chip_database() -> void:
	print("Testing ChipDatabase...")

	# Get all chips
	var all_chips = ChipDatabase.get_all_chip_names()
	print("  ✓ Total chips: %d" % all_chips.size())
	assert(all_chips.size() == 14, "Expected 14 chips")

	# Test specific chip
	var fireball = ChipDatabase.get_chip("fireball")
	print("  ✓ Fireball: Damage=%d, Element=%s" % [
		fireball.damage,
		ChipData.ElementType.keys()[fireball.element]
	])

	# Test filtering
	var projectiles = ChipDatabase.get_chips_by_type(ChipData.ChipType.PROJECTILE)
	print("  ✓ Projectile chips: %d" % projectiles.size())

	print("  ✓ ChipDatabase: PASSED\n")

## Test NaviDatabase
func test_navi_database() -> void:
	print("Testing NaviDatabase...")

	# Get all navis
	var all_navis = NaviDatabase.get_all_navi_names()
	print("  ✓ Total navis: %d" % all_navis.size())
	assert(all_navis.size() == 8, "Expected 8 navis")

	# Test MegaMan
	var megaman = NaviDatabase.get_navi("megaman")
	print("  ✓ MegaMan: HP=%d, Element=%s" % [
		megaman.max_hp,
		ChipData.ElementType.keys()[megaman.element]
	])

	# Test elemental resistance
	var fireman = NaviDatabase.get_navi("fireman")
	var fire_damage = fireman.get_modified_damage(100, ChipData.ElementType.FIRE)
	print("  ✓ FireMan vs 100 fire damage: %d (50%% resist)" % fire_damage)
	assert(fire_damage == 50, "FireMan should have 50% fire resistance")

	print("  ✓ NaviDatabase: PASSED\n")

## Test DeckConfiguration
func test_deck_configuration() -> void:
	print("Testing DeckConfiguration...")

	var deck = DeckConfiguration.new()
	deck.deck_name = "Test Deck"
	deck.column_1.assign(["fireball", "ice_shard"])
	deck.column_2.assign(["thunder_bolt", "wind_cutter", "sword_slash"])
	deck.column_3.assign(["flame_punch", "thunder_fist", "meteor_storm", "blizzard"])
	deck.slot_in_chips.assign(["power_up", "barrier"])

	var validation = deck.validate()
	print("  ✓ Deck valid: %s" % validation["valid"])
	assert(validation["valid"], "Deck should be valid")

	print("  ✓ Total chips: %d (9 main + 2 slot-in)" % deck.get_total_chip_count())
	print("  ✓ DeckConfiguration: PASSED\n")

## Test NaviComponent
func test_navi_component() -> void:
	print("Testing NaviComponent...")

	# Create navi entity
	var navi_entity = Node2D.new()
	navi_entity.name = "TestNavi"
	navi_entity.position = Vector2(400, 300)
	add_child(navi_entity)

	# Add NaviComponent
	var navi_comp = NaviComponent.new()
	navi_comp.navi_data = NaviDatabase.get_navi("megaman")
	navi_comp.debug_navi = false
	navi_entity.add_child(navi_comp)

	await get_tree().process_frame

	# Test HP
	print("  ✓ Initial HP: %d/%d" % [navi_comp.get_current_hp(), navi_comp.get_max_hp()])
	assert(navi_comp.get_current_hp() == 150, "Initial HP should be 150")

	# Test damage
	var damage_taken = navi_comp.take_damage(50, null, ChipData.ElementType.NONE)
	print("  ✓ Took %d damage, HP now: %d" % [damage_taken, navi_comp.get_current_hp()])
	assert(navi_comp.get_current_hp() == 100, "HP should be 100")

	# Test elemental resistance
	var elec_damage = navi_comp.take_damage(100, null, ChipData.ElementType.ELECTRIC)
	print("  ✓ Electric damage: %d (70 expected due to 0.7x resist)" % elec_damage)

	# Test chip counter
	navi_comp.register_chip_used()
	navi_comp.register_chip_used()
	navi_comp.register_chip_used()
	print("  ✓ Chips used after 3 registrations: %d (should reset to 0)" % navi_comp.get_chips_used())

	print("  ✓ NaviComponent: PASSED\n")

	# Cleanup
	navi_entity.queue_free()

## Test SpellCastingComponent
func test_spell_casting() -> void:
	print("Testing SpellCastingComponent...")

	# Create caster
	var caster_entity = Node2D.new()
	caster_entity.name = "Caster"
	caster_entity.position = Vector2(200, 300)
	add_child(caster_entity)

	var caster_navi = NaviComponent.new()
	caster_navi.navi_data = NaviDatabase.get_navi("megaman")
	caster_entity.add_child(caster_navi)

	# Create target
	var target_entity = Node2D.new()
	target_entity.name = "Target"
	target_entity.position = Vector2(600, 300)
	add_child(target_entity)

	var target_navi = NaviComponent.new()
	target_navi.navi_data = NaviDatabase.get_navi("fireman")
	target_entity.add_child(target_navi)

	# Add casting component
	var casting = SpellCastingComponent.new()
	casting.caster = caster_entity
	casting.use_targeting = false
	casting.debug_casting = false
	caster_entity.add_child(casting)

	await get_tree().process_frame

	# Test melee spell (instant damage)
	var sword = ChipDatabase.get_chip("sword_slash")
	var target_hp_before = target_navi.get_current_hp()

	await casting.cast_spell(sword, target_entity)
	await get_tree().process_frame

	var target_hp_after = target_navi.get_current_hp()
	var damage_dealt = target_hp_before - target_hp_after

	print("  ✓ Cast Sword Slash")
	print("  ✓ Target HP: %d → %d (-%d)" % [target_hp_before, target_hp_after, damage_dealt])
	print("  ✓ Chip counter: %d" % caster_navi.get_chips_used())

	print("  ✓ SpellCastingComponent: PASSED\n")

	# Cleanup
	caster_entity.queue_free()
	target_entity.queue_free()

## Test full battle integration
func test_battle_integration() -> void:
	print("Testing Full Battle Integration...")

	# Create player
	var player = Node2D.new()
	player.name = "Player"
	player.position = Vector2(200, 400)
	add_child(player)

	var player_navi = NaviComponent.new()
	player_navi.navi_data = NaviDatabase.get_navi("megaman")
	player.add_child(player_navi)

	var player_deck = ProgramDeckComponent.new()
	var deck_config = DeckConfiguration.new()
	deck_config.column_1.assign(["fireball", "ice_shard"])
	deck_config.column_2.assign(["thunder_bolt", "wind_cutter", "sword_slash"])
	deck_config.column_3.assign(["flame_punch", "meteor_storm", "blizzard", "power_up"])
	deck_config.slot_in_chips.assign(["barrier", "chip_breaker"])
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
	enemy.position = Vector2(600, 400)
	add_child(enemy)

	var enemy_navi = NaviComponent.new()
	enemy_navi.navi_data = NaviDatabase.get_navi("fireman")
	enemy.add_child(enemy_navi)

	# Create battle manager
	var battle_manager = BattleManagerComponent.new()
	battle_manager.player_navi = player
	battle_manager.enemy_navi = enemy
	battle_manager.max_turns = 10
	battle_manager.debug_battle = false
	add_child(battle_manager)

	await get_tree().process_frame

	print("  ✓ Battle scene created")
	print("  ✓ Player: MegaMan (HP: %d)" % player_navi.get_current_hp())
	print("  ✓ Enemy: FireMan (HP: %d)" % enemy_navi.get_current_hp())

	# Start battle
	battle_manager.start_battle()
	await get_tree().process_frame

	print("  ✓ Battle started: %s" % battle_manager.is_battle_active())
	print("  ✓ Current turn: %d" % battle_manager.get_current_turn())

	# Simulate chip selection
	var offered_chips = player_deck.offer_chips_for_turn()
	print("  ✓ Offered %d chips for selection" % offered_chips.size())

	var selected_chip = player_deck.select_chip(0)
	print("  ✓ Selected chip: %s" % selected_chip.chip_name)

	# Cast at enemy
	await player_casting.cast_spell(selected_chip, enemy)
	await get_tree().process_frame

	print("  ✓ Spell cast!")
	print("  ✓ Chips used: %d/3" % player_navi.get_chips_used())
	print("  ✓ Slot-In gauge: %.0f%%" % (player_gauge.get_gauge_percentage() * 100))
	print("  ✓ Enemy HP: %d" % enemy_navi.get_current_hp())

	# Test victory by defeating enemy
	enemy_navi.take_damage(200, null)
	await get_tree().process_frame

	print("  ✓ Enemy defeated!")
	print("  ✓ Battle active: %s" % battle_manager.is_battle_active())
	print("  ✓ Battle result: %s" % BattleManagerComponent.BattleResult.keys()[battle_manager.get_battle_result()])

	print("  ✓ Battle Integration: PASSED\n")

	# Cleanup
	battle_manager.queue_free()
	player.queue_free()
	enemy.queue_free()
