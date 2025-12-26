# 🐛 GitHub Issues - MilitiaForge2D Refactoring

**Para criar estas issues no GitHub**:
1. Vá para: https://github.com/[seu-usuario]/MilitiaForge2D/issues/new
2. Copie e cole cada issue abaixo
3. Ou use o script no final deste arquivo

---

## 🔴 CRÍTICO - Issue #1: Enemy Pooling Not Implemented

**Labels**: `critical`, `performance`, `enhancement`
**Milestone**: Phase 1 - Quick Wins
**Assignee**: @gustavo

### 📋 Descrição

Enemies são instanciados toda vez via `enemy_factory.gd`, causando:
- **50+ instantiate() calls** por wave
- **GC pressure** (garbage collection spikes)
- **Frame drops** quando spawning enemies

### 🎯 Solução Proposta

Implementar enemy pooling usando `ObjectPool` (já existe para projectiles):

```gdscript
// EntityPoolManager registra enemy types:
"enemy_basic": initial=20, max=100
"enemy_fast": initial=15, max=80
"enemy_tank": initial=5, max=30

// EnemyFactory tenta acquire do pool primeiro
var enemy = pool.acquire("enemy_basic")
if not enemy:
    enemy = scene.instantiate()  // Fallback
```

### ✅ Acceptance Criteria

- [ ] Enemies usam `ObjectPool.acquire()` em vez de `instantiate()`
- [ ] Enemies emitem `despawned` signal ao morrer
- [ ] `EntityPoolManager` retorna enemies ao pool
- [ ] Spawning de 100 enemies < 5ms (vs ~50ms atual)
- [ ] 0 GC spikes durante gameplay

### 📁 Arquivos Afetados

- `examples/space_shooter/scripts/entity_pool_manager.gd` (criar/renomear)
- `examples/space_shooter/scripts/enemy_factory.gd` (modificar)
- `examples/space_shooter/scripts/enemy_base.gd` (adicionar `reset_for_pool()`)

### 🔗 Referências

- Refactoring Plan: Task 1.3
- Similar: Projectile pooling já implementado
- Performance target: 100+ enemies @ 60 FPS

### 📊 Impacto

**Performance**: ⭐⭐⭐⭐⭐ (CRÍTICO)
**Esforço**: ⭐⭐ (BAIXO)
**Prioridade**: 🔴 **MUST HAVE**

---

## 🔴 CRÍTICO - Issue #2: SimpleWeapon Duplicates WeaponComponent

**Labels**: `critical`, `refactor`, `technical-debt`
**Milestone**: Phase 2 - Core Refactoring
**Assignee**: @gustavo

### 📋 Descrição

`SimpleWeapon` (137 linhas) reimplementa lógica de `WeaponComponent` do core:
- Duplica `fire()`, `can_fire()`, `execute_fire()` methods
- Framework tem `militia_forge/components/weapon_component.gd` (não usado!)
- **Inconsistência**: Exemplo não usa framework corretamente

### 🎯 Solução Proposta

Refatorar SimpleWeapon para estender WeaponComponent:

```gdscript
// Antes:
class_name SimpleWeapon extends Node
// 137 linhas reimplementando weapon logic

// Depois:
class_name SimpleWeapon extends WeaponComponent
// Herda tudo, apenas customiza pooling integration
```

### ✅ Acceptance Criteria

- [ ] `SimpleWeapon extends WeaponComponent`
- [ ] Remove duplicate methods (`fire()`, `can_fire()`, etc.)
- [ ] Mantém pooling integration (única customização)
- [ ] PlayerController usa `WeaponComponent.FiringType.SINGLE`
- [ ] Player shooting funciona identicamente
- [ ] -100 linhas de código

### 📁 Arquivos Afetados

- `examples/space_shooter/scripts/simple_weapon.gd` (REWRITE)
- `examples/space_shooter/scripts/player_controller.gd` (simplificar)
- `militia_forge/components/weapon_component.gd` (possivelmente extend)

### 🔗 Referências

- Refactoring Plan: Task 2.3
- SOLID Violation: DRY (Don't Repeat Yourself)

### 📊 Impacto

**Consistência**: ⭐⭐⭐⭐⭐ (CRÍTICO)
**Esforço**: ⭐⭐⭐ (MÉDIO)
**Prioridade**: 🟡 **SHOULD HAVE**

---

## 🟡 HIGH - Issue #3: Phase/Wave System Trapped in Example

**Labels**: `enhancement`, `architecture`, `refactor`
**Milestone**: Phase 2 - Core Refactoring
**Assignee**: @gustavo

### 📋 Descrição

Phase/Wave system está em `examples/space_shooter/scripts/phase_system/` mas é **padrão fundamental**:
- Aplicável a: Tower Defense, Roguelikes, Story-driven games
- 295 linhas de lógica genérica presa no exemplo
- Outros projetos precisariam duplicar

### 🎯 Solução Proposta

Mover para core framework:

```
militia_forge/systems/progression/
├── base_phase_manager.gd (abstract)
├── phase_config.gd (resource)
├── wave_config.gd (resource)
├── wave_strategy.gd (abstract)
└── strategies/
    ├── progressive_wave_strategy.gd
    ├── swarm_wave_strategy.gd
    └── elite_wave_strategy.gd
```

Space Shooter herda:
```gdscript
class SpaceShooterPhaseManager extends BasePhaseManager
```

### ✅ Acceptance Criteria

- [ ] `BasePhaseManager` no core (genérico, não assume "enemies")
- [ ] Signals genéricos: `phase_started`, `phase_completed`, `wave_spawned`
- [ ] Space Shooter usa `SpaceShooterPhaseManager extends BasePhaseManager`
- [ ] Documentation: Como usar em tower defense, roguelike
- [ ] Rival TD exemplo pode usar o mesmo sistema

### 📁 Arquivos Criados

- 7 arquivos em `militia_forge/systems/progression/`

### 📁 Arquivos Movidos

- 6 arquivos de `examples/space_shooter/scripts/phase_system/`

### 🔗 Referências

- Refactoring Plan: Task 2.1
- Similar systems: Unity's Wave Spawner, Unreal's Level Streaming

### 📊 Impacto

**Reusabilidade**: ⭐⭐⭐⭐⭐ (MUITO ALTO)
**Esforço**: ⭐⭐⭐⭐ (MÉDIO-ALTO)
**Prioridade**: 🔴 **MUST HAVE**

---

## 🟡 HIGH - Issue #4: SpaceEnemy Monolith (505 Lines)

**Labels**: `refactor`, `technical-debt`, `SOLID-violation`
**Milestone**: Phase 3 - Enemy Overhaul
**Assignee**: @gustavo

### 📋 Descrição

`enemy_base.gd` tem **505 linhas** violando Single Responsibility Principle:
- Component setup (45 lines)
- **Movement patterns inline** (150 lines) ← Não usa componente!
- Visual management (80 lines)
- Shooting logic (40 lines)
- Signal handling (40 lines)

### 🎯 Solução Proposta

Decompor em componentes:

```gdscript
// Criar componentes:
EnemyMovementComponent (patterns: SINE, ZIGZAG, TRACKING, etc.)
EnemyVisualComponent (sprite, particles, hit flash)
TurretComponent (já existe no core!)

// SpaceEnemy: 505 → 150 linhas (container apenas)
class SpaceEnemy:
    var movement: EnemyMovementComponent
    var visual: EnemyVisualComponent
    var shooting: TurretComponent
```

### ✅ Acceptance Criteria

- [ ] `EnemyMovementComponent` criado no core
- [ ] `EnemyVisualComponent` criado no core
- [ ] SpaceEnemy usa `TurretComponent` (já existe)
- [ ] `enemy_base.gd`: 505 → ~150 linhas
- [ ] Movement patterns reutilizáveis (player pode usar!)
- [ ] Testes: Enemies funcionam identicamente

### 📁 Arquivos Criados

- `militia_forge/components/enemy_movement_component.gd`
- `militia_forge/components/enemy_visual_component.gd`

### 📁 Arquivos Refatorados

- `examples/space_shooter/scripts/enemy_base.gd` (505 → 150 lines)

### 🔗 Referências

- Refactoring Plan: Task 3.1
- SOLID Violation: SRP (Single Responsibility Principle)

### 📊 Impacto

**Arquitetura**: ⭐⭐⭐⭐⭐ (MUITO ALTO)
**Esforço**: ⭐⭐⭐⭐⭐ (ALTO)
**Prioridade**: 🔵 **NICE TO HAVE**

---

## 🟢 MEDIUM - Issue #5: Consolidate Wave Data Formats

**Labels**: `refactor`, `cleanup`
**Milestone**: Phase 1 - Quick Wins
**Assignee**: @gustavo

### 📋 Descrição

`wave_manager.gd` tem **2 formatos de wave data**:
1. Dictionary hardcoded (lines 26-69)
2. WaveConfig resource (lines 213-276)

44 linhas de código de conversão (`_convert_wave_config_to_data()`)

### 🎯 Solução Proposta

Usar apenas WaveConfig resource:

```gdscript
// Migrar waves para resources:
wave_01.tres, wave_02.tres, etc.

// Eliminar _convert_wave_config_to_data()
// Usar WaveConfig diretamente em _prepare_wave_enemies()
```

### ✅ Acceptance Criteria

- [ ] Remover `wave_definitions` Dictionary
- [ ] Criar `wave_01.tres` a `wave_05.tres` resources
- [ ] Eliminar `_convert_wave_config_to_data()` (44 linhas)
- [ ] 1 único caminho de spawning
- [ ] Waves editáveis via Godot Editor

### 📁 Arquivos Afetados

- `examples/space_shooter/scripts/wave_manager.gd` (-44 linhas)
- Criar: `examples/space_shooter/resources/waves/*.tres` (x5)

### 🔗 Referências

- Refactoring Plan: Task 1.2

### 📊 Impacto

**Simplicidade**: ⭐⭐⭐⭐ (ALTO)
**Esforço**: ⭐⭐ (BAIXO)
**Prioridade**: 🔴 **MUST HAVE**

---

## 🟢 MEDIUM - Issue #6: Hardcoded Dependency Paths

**Labels**: `refactor`, `SOLID-violation`, `testability`
**Milestone**: Phase 2 - Core Refactoring
**Assignee**: @gustavo

### 📋 Descrição

Tight coupling via hardcoded node paths:

```gdscript
// simple_weapon.gd:43
_pool_manager = get_node_or_null("/root/ProjectilePoolManager")

// game_controller.gd:72
player.set_script(preload("res://examples/space_shooter/scripts/player_controller.gd"))
```

**Problemas**:
- Não testável (mock impossible)
- Frágil (breaks if structure changes)
- Viola Dependency Inversion Principle

### 🎯 Solução Proposta

Dependency Injection via setup methods:

```gdscript
// SimpleWeapon
func setup_pool_manager(pool: Node) -> void:
    _pool_manager = pool

// GameController
var player_factory: PlayerFactory
player = player_factory.create_player(game_bounds)
```

### ✅ Acceptance Criteria

- [ ] Remover todos `get_node("/root/...")` hardcoded
- [ ] Usar dependency injection via setup methods
- [ ] Factories para criação de entidades
- [ ] Testável (pode passar mocks)

### 📁 Arquivos Afetados

- `examples/space_shooter/scripts/simple_weapon.gd`
- `examples/space_shooter/scripts/game_controller.gd`

### 🔗 Referências

- Refactoring Plan: Issue #5 (DIP Violations)
- SOLID: Dependency Inversion Principle

### 📊 Impacto

**Testabilidade**: ⭐⭐⭐⭐ (ALTO)
**Esforço**: ⭐⭐⭐ (MÉDIO)
**Prioridade**: 🟡 **SHOULD HAVE**

---

## 🟢 LOW - Issue #7: Object Pooling Not in Core

**Labels**: `enhancement`, `architecture`
**Milestone**: Phase 1 - Quick Wins
**Assignee**: @gustavo

### 📋 Descrição

`object_pool.gd` e `projectile_pool_manager.gd` estão em `examples/space_shooter/scripts/` mas são **100% genéricos e reutilizáveis**.

Outros projetos precisariam duplicar.

### 🎯 Solução Proposta

```
Mover para core:
object_pool.gd → militia_forge/systems/pooling/

Generalizar:
ProjectilePoolManager → EntityPoolManager
(suporta qualquer tipo de entidade)
```

### ✅ Acceptance Criteria

- [ ] `object_pool.gd` em `militia_forge/systems/pooling/`
- [ ] `EntityPoolManager` (não apenas projectiles)
- [ ] Documentation: Como usar em qualquer projeto
- [ ] Space Shooter continua funcionando

### 📁 Arquivos Movidos

- `object_pool.gd` → `militia_forge/systems/pooling/`
- `projectile_pool_manager.gd` → `entity_pool_manager.gd`

### 🔗 Referências

- Refactoring Plan: Task 1.1

### 📊 Impacto

**Reusabilidade**: ⭐⭐⭐⭐ (ALTO)
**Esforço**: ⭐ (MUITO BAIXO)
**Prioridade**: 🔴 **MUST HAVE**

---

## 🟢 LOW - Issue #8: Component Setup Duplication

**Labels**: `refactor`, `DRY`
**Milestone**: Phase 3 - Enemy Overhaul
**Assignee**: @gustavo

### 📋 Descrição

Player e Enemy têm **~40 linhas duplicadas** de setup:
- CharacterBody2D + collision layer/mask
- CollisionShape2D
- Hurtbox

### 🎯 Solução Proposta

```gdscript
// Criar helper no core:
militia_forge/helpers/entity_setup.gd

static func create_physics_entity(
    parent: Node,
    collision_layer: int,
    collision_mask: int,
    shape_size: Vector2,
    has_hurtbox: bool = true
) -> Dictionary

// Uso:
var setup = EntitySetup.create_physics_entity(self, 1, 2, Vector2(48, 72))
physics_body = setup.body
host = setup.host
```

### ✅ Acceptance Criteria

- [ ] `entity_setup.gd` helper criado
- [ ] PlayerController usa helper (-30 linhas)
- [ ] SpaceEnemy usa helper (-30 linhas)
- [ ] Setup pattern padronizado

### 📁 Arquivos Criados

- `militia_forge/helpers/entity_setup.gd`

### 📁 Arquivos Refatorados

- `player_controller.gd` (-30 linhas)
- `enemy_base.gd` (-30 linhas)

### 🔗 Referências

- Refactoring Plan: Task 3.2
- DRY: Don't Repeat Yourself

### 📊 Impacto

**Simplicidade**: ⭐⭐⭐ (MÉDIO)
**Esforço**: ⭐⭐ (BAIXO)
**Prioridade**: 🔵 **NICE TO HAVE**

---

## 📊 Summary

| Issue | Prioridade | Esforço | Impacto | Milestone |
|-------|-----------|---------|---------|-----------|
| #1 Enemy Pooling | 🔴 MUST | ⭐⭐ BAIXO | ⭐⭐⭐⭐⭐ | Phase 1 |
| #2 SimpleWeapon | 🟡 SHOULD | ⭐⭐⭐ MÉDIO | ⭐⭐⭐⭐⭐ | Phase 2 |
| #3 Phase System | 🔴 MUST | ⭐⭐⭐⭐ MÉDIO-ALTO | ⭐⭐⭐⭐⭐ | Phase 2 |
| #4 Enemy Monolith | 🔵 NICE | ⭐⭐⭐⭐⭐ ALTO | ⭐⭐⭐⭐⭐ | Phase 3 |
| #5 Wave Formats | 🔴 MUST | ⭐⭐ BAIXO | ⭐⭐⭐⭐ | Phase 1 |
| #6 Hardcoded Paths | 🟡 SHOULD | ⭐⭐⭐ MÉDIO | ⭐⭐⭐⭐ | Phase 2 |
| #7 Pooling Core | 🔴 MUST | ⭐ MUITO BAIXO | ⭐⭐⭐⭐ | Phase 1 |
| #8 Setup Duplication | 🔵 NICE | ⭐⭐ BAIXO | ⭐⭐⭐ | Phase 3 |

---

## 🚀 Script para Criar Issues (GitHub CLI)

Se você instalar GitHub CLI (`gh`), use este script:

```bash
#!/bin/bash
# create_issues.sh

REPO="seu-usuario/MilitiaForge2D"

# Issue #1
gh issue create \
  --repo $REPO \
  --title "🔴 CRITICAL: Implement Enemy Object Pooling" \
  --label "critical,performance,enhancement" \
  --milestone "Phase 1 - Quick Wins" \
  --body-file issue_1_enemy_pooling.md

# Issue #2
gh issue create \
  --repo $REPO \
  --title "🔴 CRITICAL: SimpleWeapon Duplicates WeaponComponent" \
  --label "critical,refactor,technical-debt" \
  --milestone "Phase 2 - Core Refactoring" \
  --body-file issue_2_simple_weapon.md

# Issue #3
gh issue create \
  --repo $REPO \
  --title "🟡 HIGH: Move Phase/Wave System to Core" \
  --label "enhancement,architecture,refactor" \
  --milestone "Phase 2 - Core Refactoring" \
  --body-file issue_3_phase_system.md

# Issue #4
gh issue create \
  --repo $REPO \
  --title "🟡 HIGH: Decompose SpaceEnemy Monolith (505 Lines)" \
  --label "refactor,technical-debt,SOLID-violation" \
  --milestone "Phase 3 - Enemy Overhaul" \
  --body-file issue_4_enemy_monolith.md

# Issue #5
gh issue create \
  --repo $REPO \
  --title "🟢 MEDIUM: Consolidate Wave Data Formats" \
  --label "refactor,cleanup" \
  --milestone "Phase 1 - Quick Wins" \
  --body-file issue_5_wave_formats.md

# Issue #6
gh issue create \
  --repo $REPO \
  --title "🟢 MEDIUM: Remove Hardcoded Dependency Paths" \
  --label "refactor,SOLID-violation,testability" \
  --milestone "Phase 2 - Core Refactoring" \
  --body-file issue_6_hardcoded_paths.md

# Issue #7
gh issue create \
  --repo $REPO \
  --title "🟢 LOW: Move Object Pooling to Core Framework" \
  --label "enhancement,architecture" \
  --milestone "Phase 1 - Quick Wins" \
  --body-file issue_7_pooling_core.md

# Issue #8
gh issue create \
  --repo $REPO \
  --title "🟢 LOW: Remove Component Setup Duplication" \
  --label "refactor,DRY" \
  --milestone "Phase 3 - Enemy Overhaul" \
  --body-file issue_8_setup_duplication.md

echo "✅ 8 issues created!"
```

---

## 📝 Manual Creation Steps

1. Vá para: https://github.com/[seu-usuario]/MilitiaForge2D/issues
2. Click **New Issue**
3. Copie/cole cada issue acima
4. Adicione labels, milestone, assignee
5. Click **Submit new issue**

---

**Total**: 8 Issues Críticas Criadas
**Estimate**: 11-17 dias (~2.5 semanas)
**ROI**: -500+ linhas código, 10x performance, SOLID compliance
