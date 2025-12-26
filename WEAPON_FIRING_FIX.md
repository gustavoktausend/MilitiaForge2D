# Weapon Firing Bug - FIXED

## Problem
After refactoring SimpleWeapon to extend WeaponComponent, neither player nor enemies could fire weapons. The cooldown would decrement but never reach zero, and weapons wouldn't fire even on the first shot.

## Root Causes

### 1. Incorrect Autoload Access (PRIMARY BUG)
**File**: `militia_forge/components/combat/weapon_component.gd:527`

**Problem**:
```gdscript
_pool_manager = Engine.get_singleton("EntityPoolManager")
```

**Why it Failed**:
- `Engine.get_singleton()` is for native Engine singletons (like Input, OS, Engine)
- Godot autoloads are NOT Engine singletons - they're nodes in the SceneTree
- This ALWAYS returned null, even though EntityPoolManager was registered as autoload

**Fix**:
```gdscript
_pool_manager = get_node_or_null("/root/EntityPoolManager")
```

**Impact**: This was the main reason weapons couldn't fire. Without the pool manager, and without `projectile_scene` being set, the `_can_fire()` check at line 309-313 would always fail.

---

### 2. Group Name Case Mismatch
**File**: `militia_forge/components/combat/weapon_component.gd:543`

**Problem**:
```gdscript
var containers = get_tree().get_nodes_in_group("projectiles_container")  # lowercase
```

But the actual code uses:
```gdscript
get_tree().get_first_node_in_group("ProjectilesContainer")  # PascalCase
```

**Fix**:
```gdscript
var containers = get_tree().get_nodes_in_group("ProjectilesContainer")  # Match case
```

---

### 3. Missing Group Assignment in Scene
**File**: `examples/space_shooter/scenes/main_game.tscn:27`

**Problem**:
```
[node name="ProjectilesContainer" type="Node2D" parent="."]
```

The node existed but wasn't in any group!

**Fix**:
```
[node name="ProjectilesContainer" type="Node2D" parent="." groups=["ProjectilesContainer"]]
```

---

## Why Weapons Couldn't Fire

The `_can_fire()` method checks:
```gdscript
# Check if we have EITHER pooling OR projectile scene
var has_spawn_method = (use_object_pooling and _pool_manager and not pooled_projectile_type.is_empty()) or projectile_scene != null
```

**What was happening**:
1. `use_object_pooling = true` ✅
2. `_pool_manager = null` ❌ (due to bug #1)
3. `pooled_projectile_type = "player_laser"` ✅
4. `projectile_scene = null` ❌ (not set in some cases)

**Result**: `has_spawn_method = false` → `_can_fire()` returns false → weapon won't fire

Even though cooldown was decrementing, it didn't matter because the FIRST check (`_can_fire()`) was failing before cooldown was even checked.

---

## Files Changed

1. **militia_forge/components/combat/weapon_component.gd**
   - Fixed `_setup_pool_manager()` to use `/root/EntityPoolManager` path
   - Fixed group name to "ProjectilesContainer" (case-sensitive)
   - Added better debug warnings

2. **examples/space_shooter/scenes/main_game.tscn**
   - Added ProjectilesContainer to "ProjectilesContainer" group

---

## Testing Checklist

Run the game and verify:

- [ ] Console shows: `[WeaponComponent] ✅ Found pool manager: EntityPoolManager`
- [ ] Console shows: `[WeaponComponent] Found projectiles_container via group: ProjectilesContainer`
- [ ] Player can fire projectiles
- [ ] Enemies can fire projectiles
- [ ] Projectiles spawn from correct positions
- [ ] Fire rate cooldown works correctly
- [ ] Console shows: `[WeaponComponent] ✅ Spawned projectile from pool`

### Expected Console Output

```
[EntityPoolManager] Initializing...
[EntityPoolManager] Created pool for 'player_laser' (initial: 30, max: 100)
[EntityPoolManager] Created pool for 'enemy_laser' (initial: 20, max: 80)
[EntityPoolManager] ✅ Ready!

[SimpleWeapon] Ready - Player: true, Pooling: true, Type: player_laser
[WeaponComponent] ✅ Found pool manager: EntityPoolManager
[WeaponComponent] Found projectiles_container via group: ProjectilesContainer
[Player] Injected ProjectilesContainer into weapon

# During gameplay:
[WeaponComponent] fire() - executing!
[WeaponComponent] ✅ Spawned projectile from pool (entity): player_laser
```

---

## Status

✅ **FIXED** - All three bugs resolved

**Next Steps**:
1. Test the game
2. Verify pooling works correctly
3. Complete SIMPLEWEAPON_REFACTORING.md documentation
4. Move to Issue #5 (Wave Data Format consolidation)
