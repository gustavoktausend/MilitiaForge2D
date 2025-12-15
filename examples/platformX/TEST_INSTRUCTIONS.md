# Test Scene - Quick Validation

## 🎮 How to Test

1. **Open Godot** → Open MilitiaForge2D project
2. **Navigate** to `examples/platformX/scenes/test_scene.tscn`
3. **Press F6** to run the scene

## 🕹️ Controls

- **Arrow Keys** or **A/D**: Move left/right
- **Space**: Jump (hold for higher jump, tap for short hop)
- **Enter**: Print debug info to console
- **ESC**: Quit

## ✅ What to Validate

### PlatformerMovement Component
- [ ] Player falls with gravity
- [ ] Horizontal movement (A/D or arrows)
- [ ] Jump works (Space)
- [ ] Variable jump height (hold vs tap Space)
- [ ] **Coyote time**: Run off platform edge, press jump within ~0.1s - should still jump!
- [ ] **Jump buffering**: Press jump right before landing - should auto-jump on landing
- [ ] Lands on platforms properly
- [ ] Ground detection accurate

### Expected Behavior

**Basic Movement**:
- Smooth acceleration when moving
- Friction when no input
- Max speed clamped to 200

**Jump Mechanics**:
- **Tap Space**: Short jump (~200 pixels)
- **Hold Space**: High jump (~300-400 pixels)
- Release space early → jump cuts short

**Coyote Time**:
1. Walk to platform edge
2. Walk off (don't jump)
3. Press Space within 0.1 seconds
4. ✅ Should still jump!

**Jump Buffer**:
1. Jump from high platform
2. Press Space while falling (before landing)
3. ✅ Should auto-jump when you land!

## 🐛 Troubleshooting

**Player falls through floor**:
- Check console for errors
- Verify PlatformerMovement component created

**Can't move**:
- Try arrow keys AND WASD
- Check console output

**Jump doesn't work**:
- Ground detection may be failing
- Check console for errors
- Print debug (Enter key) to see grounded state

**Script errors**:
- Make sure `PlatformerMovement` class exists
- Check `militia_forge/components/movement/platformer_movement.gd`

## 📊 Scene Contents

- **Ground**: Large platform at bottom
- **3 Floating Platforms**: Test jumping
- **2 Walls**: Test collision
- **Player**: Blue rectangle
  - Uses PlatformerMovement component
  - Camera follows player
- **Instructions**: On-screen controls

## 🎯 What's Being Tested

This scene validates:
1. ✅ Component instantiation (ComponentHost + PlatformerMovement)
2. ✅ Gravity system
3. ✅ Jump mechanics (variable height)
4. ✅ Ground detection (3 raycasts)
5. ✅ Coyote time (0.1s grace)
6. ✅ Jump buffering
7. ✅ Collision with StaticBody2D

## 💡 Debug Info

Press **Enter** to print:
- Current position
- Velocity (x, y)
- Grounded state

Watch console output for:
```
[TestPlayer] Ready! Controls: A/D = move, Space = jump
[PlatformerMovement] Ready - Gravity: 980.0, Jump: -400.0
```

## 🚀 Next Steps After Validation

If this works correctly:
1. ✅ PlatformerMovement is functional
2. Add WallSlideComponent test
3. Add DashComponent test
4. Add ChargeShot test
5. Build full example scenes

---

**Good luck testing!** 🎮 Report any bugs you find!
