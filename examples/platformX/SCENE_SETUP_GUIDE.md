# Scene Setup Guide - PlatformX

This guide walks you through creating all required .tscn scene files in Godot Editor.

## 📋 Overview

You need to create **7 scene files** total:
1. Player scene
2. 3 Enemy scenes (Met, Flying, Turret)
3. 1 Projectile scene
4. HUD scene
5. Main Level scene

---

## 1. Player Scene (player.tscn)

### Scene Structure
```
Player (CharacterBody2D) - root, attach player_x_controller.gd
├── CollisionShape2D (body collision)
├── Sprite2D (visual - placeholder ColorRect works)
└── Camera2D (follow player)
```

### Step-by-Step

1. **Create New Scene**: Scene → New Scene
2. **Add Root Node**: CharacterBody2D, name it "Player"
3. **Attach Script**: Attach `scripts/player_x_controller.gd`
4. **Add CollisionShape2D**:
   - Add child: CollisionShape2D
   - In Inspector → Shape: New RectangleShape2D
   - Size: 32x48 (width x height)
   - Position offset Y: -24 (so feet are at origin)

5. **Add Sprite** (Placeholder):
   - Add child: ColorRect
   - Name: "Sprite2D"
   - Size: 32x48
   - Position: (-16, -48) to center on body
   - Color: Blue (0.2, 0.5, 1.0)

6. **Add Camera2D**:
   - Add child: Camera2D
   - Enable "Enabled" in Inspector
   - Zoom: (2, 2) for closer view (optional)
   - Position Smoothing: Enabled
   - Position Smoothing Speed: 5.0

7. **Configure Player**:
   - In root Player node inspector:
   - Script Variables:
     - Max Health: 100
     - Move Speed: 200
     - Jump Power: -400

8. **Add to Group**:
   - Select Player root node
   - Node tab → Groups
   - Add group: "player"

9. **Save**: Scene → Save Scene As → `scenes/player.tscn`

---

## 2. Enemy Met Scene (met.tscn)

### Scene Structure
```
Met (CharacterBody2D) - root, attach enemy_met.gd
├── CollisionShape2D
├── Sprite2D (ColorRect placeholder)
└── Hurtbox (Area2D - for taking damage)
    └── CollisionShape2D
```

### Steps

1. **Root**: CharacterBody2D named "Met"
2. **Attach Script**: `scripts/enemies/enemy_met.gd`
3. **CollisionShape2D**: RectangleShape2D, size 24x24
4. **Sprite**: ColorRect, size 24x24, Color: Red (0.8, 0.2, 0.2)
5. **Hurtbox** (Area2D):
   - Add child Area2D, name "Hurtbox"
   - Attach `militia_forge/components/health/hurtbox.gd`
   - Add CollisionShape2D child: RectangleShape2D 24x24
   - Collision Layer: 3 (enemies)
   - Collision Mask: 4 (player projectiles)

6. **Configure**:
   - Patrol Speed: 50
   - Detection Range: 150

7. **Save**: `scenes/enemies/met.tscn`

---

## 3. Enemy Flying Scene (flying_enemy.tscn)

### Scene Structure
```
FlyingEnemy (CharacterBody2D) - attach enemy_flying.gd
├── CollisionShape2D
├── Sprite2D
└── Hurtbox (Area2D)
    └── CollisionShape2D
```

### Steps

1. **Root**: CharacterBody2D named "FlyingEnemy"
2. **Attach Script**: `scripts/enemies/enemy_flying.gd`
3. **CollisionShape2D**: CircleShape2D, radius 12
4. **Sprite**: ColorRect, size 24x24, Color: Yellow (0.9, 0.9, 0.2)
5. **Hurtbox**: Same as Met
6. **Configure**:
   - Move Speed: 80
   - Chase Speed: 120
   - Detection Range: 200

7. **Save**: `scenes/enemies/flying_enemy.tscn`

---

## 4. Enemy Turret Scene (turret.tscn)

### Scene Structure
```
Turret (Node2D) - attach enemy_turret.gd
├── Sprite2D (turret base)
├── BarrelSprite (Sprite2D - rotates)
└── Hurtbox (Area2D)
    └── CollisionShape2D
```

### Steps

1. **Root**: Node2D named "Turret"
2. **Attach Script**: `scripts/enemies/enemy_turret.gd`
3. **Base Sprite**: ColorRect 32x32, Color: Gray (0.5, 0.5, 0.5)
4. **Barrel Sprite**: 
   - Add ColorRect as child
   - Name: "BarrelSprite"
   - Size: 24x8
   - Color: Dark Gray (0.3, 0.3, 0.3)
   - Position: (12, 0) to extend from center
5. **Hurtbox**: Area2D with collision shape
6. **Configure**:
   - Detection Range: 250
   - Fire Cooldown: 2.0

7. **Save**: `scenes/enemies/turret.tscn`

---

## 5. Projectile Scene (projectile.tscn)

### Scene Structure
```
Projectile (Area2D)
├── CollisionShape2D
├── Sprite2D
└── (ProjectileComponent auto-added by ChargeShot)
```

### Steps

1. **Root**: Area2D named "Projectile"
2. **No script** (ProjectileComponent handles logic)
3. **CollisionShape2D**: CircleShape2D, radius 4
4. **Sprite**: ColorRect 8x8, Color: Cyan (0.2, 0.8, 1.0)
5. **Collision Settings**:
   - Layer: 4 (player projectiles) OR 5 (enemy projectiles)
   - Mask: 3 (enemies) OR 2 (player)

Note: Create TWO projectile scenes:
- `projectile_player.tscn` - Layer 4, Mask 3
- `projectile_enemy.tscn` - Layer 5, Mask 2

6. **Save**: `scenes/projectile_player.tscn` and `scenes/projectile_enemy.tscn`

---

## 6. HUD Scene (game_hud.tscn)

### Scene Structure
```
HUD (CanvasLayer) - attach ui/game_hud.gd
└── MarginContainer
    └── VBoxContainer
        ├── HealthLabel (Label)
        ├── HealthBar (ProgressBar)
        ├── WeaponEnergyBar (ProgressBar)
        ├── LivesLabel (Label)
        └── ScoreLabel (Label)
```

### Steps

1. **Root**: CanvasLayer named "HUD"
2. **Attach Script**: `ui/game_hud.gd`
3. **MarginContainer**:
   - Add child: MarginContainer
   - Anchors: Top-Left
   - Margins: 10 on all sides

4. **VBoxContainer**:
   - Add as child of MarginContainer
   - Separation: 5

5. **Add UI Elements** (as children of VBoxContainer):
   - **HealthLabel**: Label, Text: "HP: 100/100"
   - **HealthBar**: ProgressBar
     - Min: 0, Max: 100, Value: 100
     - Show Percentage: false
     - Custom Colors: Green fill
   - **WeaponEnergyBar**: ProgressBar (same settings)
   - **LivesLabel**: Label, Text: "Lives: 3"
   - **ScoreLabel**: Label, Text: "Score: 0"

6. **Style** (optional):
   - Select labels: Font Size: 14
   - Theme Overrides → Colors → Font Color: White

7. **Save**: `ui/game_hud.tscn`

---

## 7. Main Level Scene (main_level.tscn)

### Scene Structure
```
MainLevel (Node2D)
├── TileMap (platforms and walls)
├── Player (instance of player.tscn)
├── EnemyFactory (Node - attach enemy_factory.gd)
├── Enemies (Node2D - container, manually place enemies)
│   ├── Met01 (instance)
│   ├── FlyingEnemy01 (instance)
│   └── Turret01 (instance)
├── Camera2D (if not using player camera)
└── HUD (instance of game_hud.tscn)
```

### Steps

1. **Root**: Node2D named "MainLevel"

2. **TileMap** (Platforms):
   - Add child: TileMap
   - Create TileSet:
     - TileSet → + → New TileSet
     - Add tiles: Click + to add texture (or use ColorRect placeholders)
     - Physics Layer: Enable, set collision shapes
   - Paint platforms:
     - Create floor at bottom (Y: 500)
     - Add platforms at various heights
     - Add walls on sides

3. **Player**:
   - Add child: Instantiate Child Scene
   - Select `scenes/player.tscn`
   - Position: (100, 400) - on ground

4. **EnemyFactory**:
   - Add child: Node named "EnemyFactory"
   - Attach script: `scripts/enemy_factory.gd`
   - In Inspector, set Enemy Scenes:
     - Met Scene: load met.tscn
     - Flying Scene: load flying_enemy.tscn
     - Turret Scene: load turret.tscn

5. **Place Enemies** (or use factory in code):
   - Add Node2D named "Enemies"
   - Manually place enemy instances:
     - Instantiate met.tscn → position (300, 480)
     - Instantiate flying_enemy.tscn → position (500, 300)
     - Instantiate turret.tscn → position (700, 460)

6. **HUD**:
   - Instantiate Child Scene: `ui/game_hud.tscn`

7. **Configure**:
   - Set project collision layers in Project Settings
   - Test play (F6)

8. **Save**: `scenes/main_level.tscn`

---

## 🎮 Collision Layers Setup

Before testing, configure collision layers:

**Project Settings → Layer Names → 2D Physics**:
- Layer 1: `world` (platforms, walls)
- Layer 2: `player`
- Layer 3: `enemies`
- Layer 4: `player_projectiles`
- Layer 5: `enemy_projectiles`
- Layer 6: `hazards`
- Layer 7: `pickups`

---

## ✅ Final Checklist

Before testing:
- [ ] All 7 scenes created
- [ ] Scripts attached correctly
- [ ] Collision shapes configured
- [ ] Collision layers/masks set
- [ ] Player in "player" group
- [ ] HUD connected to player
- [ ] TileMap has platforms
- [ ] ProjectileComponent scenes configured in ChargeShot and Weapon components

---

## 🚀 Testing

1. **Open main_level.tscn**
2. **Press F6** to run scene
3. **Test Controls**:
   - WASD to move
   - Space to jump
   - Shift to dash
   - X to shoot (hold to charge)

4. **Expected Behavior**:
   - Player moves, jumps, wall slides
   - Enemies patrol, chase, shoot
   - Health bar updates on damage
   - Charge shot has 3 levels

---

## 🐛 Common Issues

**Player falls through floor**:
- Check TileMap collision shapes
- Verify collision layers (World: 1, Player mask: 1)

**Enemies don't appear**:
- Check they're visible in scene
- Verify scripts attached
- Check console for errors

**No damage**:
- Verify Hurtbox/Hitbox collision layers/masks
- Player projectiles (layer 4) vs Enemies (mask 3)

**Camera not following**:
- Ensure Camera2D is child of Player
- Enable "Enabled" on Camera2D

---

## 💡 Quick Placeholders

For rapid prototyping, use **ColorRect** for all sprites:
- Player: Blue (0.2, 0.5, 1.0)
- Met: Red (0.8, 0.2, 0.2)
- Flying: Yellow (0.9, 0.9, 0.2)
- Turret: Gray (0.5, 0.5, 0.5)
- Projectiles: Cyan (0.2, 0.8, 1.0)
- Platforms: Brown (0.4, 0.3, 0.2)

Replace with proper sprites later!

---

**Happy scene building!** When all scenes are created, the example will be fully playable! 🎮
