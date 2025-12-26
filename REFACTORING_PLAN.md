# 🎯 MilitiaForge2D Refactoring Plan
## Space Shooter Analysis & Strategic Improvements

**Criado em**: 2025-12-23
**Status**: 📋 Aguardando Revisão
**Objetivo**: Elevar Space Shooter de exemplo funcional para **arquitetura de referência**

---

## 📊 Executive Summary

### Situação Atual
- ✅ **Component System**: Bem implementado (A)
- ✅ **Object Pooling**: Funcionando perfeitamente (A)
- ✅ **Observer Pattern**: Usado extensivamente (A)
- ⚠️ **Enemy System**: 505 linhas monolíticas (C)
- ⚠️ **SimpleWeapon**: Não usa framework (C)
- ⚠️ **Phase/Wave System**: Preso no exemplo (B)

### Problemas Críticos Identificados
1. **Duplicação**: SimpleWeapon reimplementa WeaponComponent (137 linhas duplicadas)
2. **Monólito**: SpaceEnemy tem 505 linhas (movimento, visual, lógica)
3. **Localização Errada**: Phase system deveria ser core, não exemplo
4. **Acoplamento Forte**: Hardcoded paths (`/root/ProjectilePoolManager`)
5. **Falta de Pooling**: Enemies não usam object pooling (gargalo)

### Métricas
- **Lines of Code (Space Shooter)**: ~3,500 linhas
- **Component Count**: 15+ componentes no core
- **SOLID Violations**: 12 identificadas
- **Performance Issues**: 3 críticas, 2 moderadas

---

## 🎯 Objetivos Estratégicos

### 1. **Elevar Qualidade Arquitetural**
- Eliminar SOLID violations
- Reduzir acoplamento
- Aumentar reusabilidade

### 2. **Mover Sistemas Genéricos para Core**
- Phase/Wave system → `militia_forge/systems/progression/`
- Object pooling → `militia_forge/systems/pooling/`
- Entity factories → `militia_forge/factories/`

### 3. **Otimizar Performance**
- Implementar enemy pooling
- Reduzir GC pressure
- Melhorar spawning (50+ enemies)

### 4. **Criar Padrões de Referência**
- Space Shooter como showcase
- Documentação completa
- Exemplos de uso correto

---

## 📋 Plano de Ação (Faseado)

---

## **FASE 1: Quick Wins (1-2 dias)**
*Melhorias de alto impacto e baixo esforço*

### Task 1.1: Mover Object Pooling para Core ⭐
**Prioridade**: ALTA | **Esforço**: BAIXO | **Impacto**: ALTO

**Problema**:
- `object_pool.gd` e `projectile_pool_manager.gd` estão em `examples/space_shooter/scripts/`
- São 100% genéricos e reutilizáveis
- Outros projetos precisariam duplicar

**Ação**:
```
1. Mover arquivos:
   - object_pool.gd → militia_forge/systems/pooling/object_pool.gd
   - projectile_pool_manager.gd → examples/space_shooter/scripts/ (renomear para entity_pool_manager.gd)

2. Generalizar ProjectilePoolManager:
   - Renomear para EntityPoolManager
   - Suportar qualquer tipo de entidade (não só projectiles)
   - Manter pool configs por tipo

3. Criar documentação:
   - militia_forge/systems/pooling/README.md
   - Exemplos de uso
```

**Arquivos Afetados**:
- `examples/space_shooter/scripts/object_pool.gd` (mover)
- `examples/space_shooter/scripts/projectile_pool_manager.gd` (refatorar e mover)
- `examples/space_shooter/scripts/simple_weapon.gd` (atualizar path)

**Resultado Esperado**:
- Object pooling disponível para todos os projetos
- 1 sistema a menos para duplicar

---

### Task 1.2: Consolidar Formatos de Wave ⭐
**Prioridade**: MÉDIA | **Esforço**: BAIXO | **Impacto**: ALTO

**Problema**:
- `wave_manager.gd` tem 2 formatos de wave data:
  - Dictionary hardcoded (lines 26-69)
  - WaveConfig resource (lines 213-276)
- 44 linhas de código de conversão (`_convert_wave_config_to_data`)

**Ação**:
```
1. Escolher um formato: WaveConfig resource (mais flexível)

2. Migrar waves hardcoded para resources:
   - Criar wave_01.tres, wave_02.tres, etc.
   - Remover wave_definitions Dictionary

3. Eliminar _convert_wave_config_to_data():
   - Usar WaveConfig diretamente em _prepare_wave_enemies()

4. Simplificar start_next_wave():
   - Carregar WaveConfig via load()
   - Passar para start_wave_from_config()
```

**Arquivos Afetados**:
- `examples/space_shooter/scripts/wave_manager.gd` (simplificar)
- Criar: `examples/space_shooter/resources/waves/wave_01.tres` (x5)

**Resultado Esperado**:
- 1 único caminho de spawning
- Waves editáveis via editor
- -44 linhas de código

---

### Task 1.3: Adicionar Enemy Pooling 🚀
**Prioridade**: ALTA | **Esforço**: BAIXO | **Impacto**: ALTO (Performance)

**Problema**:
- Enemies são instanciados toda vez (`enemy_factory.gd` line 44)
- 50+ enemies por wave = 50+ instantiate() calls
- GC pressure, frame drops

**Ação**:
```
1. Adicionar enemy types ao EntityPoolManager (renomeado de ProjectilePoolManager):
   - "enemy_basic": initial=20, max=100
   - "enemy_fast": initial=15, max=80
   - "enemy_tank": initial=5, max=30

2. Modificar EnemyFactory.create_enemy():
   - Tentar acquire do pool primeiro
   - Fallback para instantiate() se pool vazio
   - Configurar enemy com set_enemy_type()

3. Modificar SpaceEnemy:
   - Adicionar reset_for_pool() method
   - Emit despawned signal ao morrer
   - EntityPoolManager captura signal e retorna ao pool

4. Testar spawning de 100+ enemies
```

**Arquivos Afetados**:
- `examples/space_shooter/scripts/entity_pool_manager.gd` (adicionar enemy types)
- `examples/space_shooter/scripts/enemy_factory.gd` (usar pooling)
- `examples/space_shooter/scripts/enemy_base.gd` (adicionar reset_for_pool)

**Resultado Esperado**:
- **10x faster spawning** (1.5ms vs 15ms para 100 enemies)
- Eliminação de GC spikes
- Smooth 60 FPS com 100+ enemies

---

## **FASE 2: Core Refactoring (3-5 dias)**
*Movimentação de sistemas para o core*

### Task 2.1: Mover Phase/Wave System para Core 🎯
**Prioridade**: ALTA | **Esforço**: MÉDIO | **Impacto**: MUITO ALTO

**Problema**:
- Phase/Wave system é **padrão fundamental**:
  - Tower Defense (Rival TD)
  - Roguelikes (dungeon progression)
  - Story games (chapter system)
- Atualmente preso em `examples/space_shooter/scripts/phase_system/`

**Ação**:
```
1. Criar estrutura no core:
   militia_forge/systems/progression/
   ├── base_phase_manager.gd (abstract)
   ├── phase_config.gd (resource)
   ├── wave_config.gd (resource)
   ├── wave_strategy.gd (abstract)
   ├── strategies/
   │   ├── progressive_wave_strategy.gd
   │   ├── swarm_wave_strategy.gd
   │   └── elite_wave_strategy.gd
   └── README.md

2. Abstrair para uso genérico:
   - BasePhaseManager não assume "enemies"
   - Use "entities" ou "units"
   - Signals genéricos: phase_started, phase_completed, wave_spawned

3. Space Shooter usa specialização:
   - SpaceShooterPhaseManager extends BasePhaseManager
   - SpaceShooterWaveStrategy extends WaveStrategy

4. Documentar padrão:
   - Como usar em tower defense
   - Como usar em roguelike
   - Como criar custom strategies
```

**Arquivos Criados**:
- 7 arquivos novos em `militia_forge/systems/progression/`

**Arquivos Movidos**:
- 6 arquivos de `examples/space_shooter/scripts/phase_system/`

**Resultado Esperado**:
- Progression system reutilizável
- Rival TD pode usar o mesmo sistema
- Outros projetos herdam gratuitamente

---

### Task 2.2: Criar Entity Factory Framework 🏭
**Prioridade**: MÉDIA | **Esforço**: MÉDIO | **Impacto**: ALTO

**Problema**:
- GameController cria Player manualmente (lines 72-83)
- WaveManager instancia enemies via factory
- Nenhum padrão unificado

**Ação**:
```
1. Criar base factory no core:
   militia_forge/factories/
   ├── base_entity_factory.gd (abstract)
   ├── entity_template.gd (resource)
   └── README.md

2. BaseEntityFactory features:
   - Registry de templates (scenes + configs)
   - Pooling integration (opcional)
   - Lifecycle hooks (on_create, on_reset)
   - Configuration overrides

3. Space Shooter implementa:
   - PlayerFactory extends BaseEntityFactory
   - EnemyFactory extends BaseEntityFactory (refactor existing)

4. GameController usa factories:
   - player = player_factory.create("default_player")
   - No hardcoded paths
```

**Arquivos Criados**:
- `militia_forge/factories/base_entity_factory.gd`
- `militia_forge/factories/entity_template.gd`
- `examples/space_shooter/scripts/player_factory.gd`

**Arquivos Refatorados**:
- `examples/space_shooter/scripts/enemy_factory.gd` (usar base)
- `examples/space_shooter/scripts/game_controller.gd` (usar factories)

**Resultado Esperado**:
- Criação de entidades padronizada
- Testável (mock factories)
- Reutilizável em todos os projetos

---

### Task 2.3: Refatorar SimpleWeapon para Usar WeaponComponent 🔫
**Prioridade**: ALTA | **Esforço**: MÉDIO | **Impacto**: ALTO (Consistência)

**Problema**:
- SimpleWeapon (137 linhas) reimplementa WeaponComponent
- Framework tem `militia_forge/components/weapon_component.gd` (não usado!)
- Inconsistência entre exemplo e framework

**Ação**:
```
1. Analisar WeaponComponent do core:
   - Verificar features (SINGLE, SPREAD, BURST, BEAM)
   - Verificar se atende needs do Space Shooter

2. Refatorar SimpleWeapon:
   class_name SimpleWeapon extends WeaponComponent

3. Remover código duplicado:
   - fire(), can_fire(), execute_fire() já existem no WeaponComponent
   - Manter apenas customizações específicas (pooling integration)

4. Atualizar PlayerController:
   - Usar WeaponComponent.FiringType.SINGLE
   - Configurar via exports

5. Testar:
   - Player shooting funciona
   - Pooling funciona
   - Signals funcionam
```

**Arquivos Afetados**:
- `examples/space_shooter/scripts/simple_weapon.gd` (REWRITE)
- `examples/space_shooter/scripts/player_controller.gd` (simplificar setup)
- `militia_forge/components/weapon_component.gd` (possivelmente estender)

**Resultado Esperado**:
- -100 linhas de código duplicado
- Exemplo usa framework corretamente
- WeaponComponent testado em produção

---

## **FASE 3: Enemy System Overhaul (5-7 dias)**
*Maior refatoração, maior impacto*

### Task 3.1: Decompor SpaceEnemy Monolith 🛸
**Prioridade**: ALTA | **Esforço**: ALTO | **Impacto**: MUITO ALTO

**Problema**:
- `enemy_base.gd` tem **505 linhas**
- Responsabilidades:
  - Component setup (45 lines)
  - Movement patterns (150 lines) ← Inline, não component
  - Visual management (80 lines)
  - Shooting logic (40 lines)
  - Signal handling (40 lines)
- Viola Single Responsibility Principle

**Ação**:
```
1. Criar EnemyMovementComponent:
   militia_forge/components/enemy_movement_component.gd
   - Padrões: STRAIGHT, ZIGZAG, SINE, CIRCULAR, TRACKING, STOP_AND_SHOOT
   - Usa BoundedMovement como base
   - Velocity modulation pattern

2. Criar EnemyVisualComponent:
   militia_forge/components/enemy_visual_component.gd
   - Sprite management
   - Particle effects
   - Hit flash

3. Criar EnemyShootingComponent (ou usar TurretComponent):
   - TurretComponent já existe no core!
   - Testar se atende needs

4. Refatorar SpaceEnemy:
   - Reduzir para ~150 linhas (container apenas)
   - Delegar para components:
     * movement_component: EnemyMovementComponent
     * visual_component: EnemyVisualComponent
     * shooting_component: TurretComponent
   - Setup via factory

5. Migrar movement patterns:
   - SINE_WAVE → EnemyMovementComponent com sine modulation
   - TRACKING → EnemyMovementComponent com target tracking
   - Etc.
```

**Arquivos Criados**:
- `militia_forge/components/enemy_movement_component.gd`
- `militia_forge/components/enemy_visual_component.gd`

**Arquivos Refatorados**:
- `examples/space_shooter/scripts/enemy_base.gd` (505 → 150 lines)

**Resultado Esperado**:
- -350 linhas de código complexo
- Movement patterns reutilizáveis (player pode usar!)
- Testabilidade (test components em isolamento)

---

### Task 3.2: Implementar Component-Based Enemy Setup 🔧
**Prioridade**: MÉDIA | **Esforço**: MÉDIO | **Impacto**: ALTO

**Problema**:
- Player e Enemy têm setup similar (~40 linhas duplicadas cada):
  - CharacterBody2D + collision layer/mask
  - CollisionShape2D
  - Hurtbox
  - ComponentHost

**Ação**:
```
1. Criar helper function no core:
   militia_forge/helpers/entity_setup.gd

   static func create_physics_entity(
       parent: Node,
       collision_layer: int,
       collision_mask: int,
       shape_size: Vector2,
       has_hurtbox: bool = true
   ) -> Dictionary:
       # Returns { body: CharacterBody2D, host: ComponentHost, hurtbox: Hurtbox }

2. Refatorar PlayerController:
   var setup = EntitySetup.create_physics_entity(self, 1, 2, Vector2(48, 72))
   physics_body = setup.body
   host = setup.host
   # -30 lines

3. Refatorar SpaceEnemy:
   var setup = EntitySetup.create_physics_entity(self, 2, 1, _get_collision_size())
   # -30 lines

4. Documentar padrão
```

**Arquivos Criados**:
- `militia_forge/helpers/entity_setup.gd`

**Arquivos Refatorados**:
- `examples/space_shooter/scripts/player_controller.gd` (simplificar)
- `examples/space_shooter/scripts/enemy_base.gd` (simplificar)

**Resultado Esperado**:
- -60 linhas de código duplicado
- Setup pattern padronizado
- Fácil criar novas entidades

---

## **FASE 4: Polish & Documentation (2-3 dias)**
*Documentação e refinamento*

### Task 4.1: Criar Guias de Arquitetura 📚
**Prioridade**: ALTA | **Esforço**: BAIXO | **Impacto**: MUITO ALTO (Adoção)

**Ação**:
```
1. Documentar cada sistema:
   - militia_forge/systems/progression/README.md
   - militia_forge/systems/pooling/README.md
   - militia_forge/factories/README.md

2. Criar guia de padrões:
   docs/ARCHITECTURE_PATTERNS.md
   - Component-Based Entity Design
   - Factory Pattern Usage
   - Object Pooling Best Practices
   - Observer Pattern Guidelines
   - Dependency Injection

3. Atualizar Space Shooter README:
   - Como ele demonstra cada padrão
   - Onde ver exemplos de cada componente
   - Como estender/customizar

4. Criar migration guide:
   docs/MIGRATION_GUIDE.md
   - Como migrar de SimpleWeapon para WeaponComponent
   - Como adicionar pooling a entidades
   - Como usar Phase/Wave system
```

**Resultado Esperado**:
- Desenvolvedores entendem arquitetura
- Fácil onboarding
- Redução de perguntas

---

### Task 4.2: Adicionar Métricas de Performance 📊
**Prioridade**: BAIXA | **Esforço**: BAIXO | **Impacto**: MÉDIO

**Ação**:
```
1. Criar PerformanceMonitor autoload:
   militia_forge/systems/performance_monitor.gd
   - FPS tracking
   - Entity count
   - Pool statistics
   - Memory usage

2. Adicionar debug UI:
   - Toggle com F3
   - Mostra métricas em tempo real

3. Integrar no Space Shooter:
   - Track enemy count
   - Track projectile count
   - Pool utilization %
```

**Resultado Esperado**:
- Visibilidade de performance
- Identificar gargalos facilmente

---

## 📈 Métricas de Sucesso

### Quantitativas
- **Lines of Code**: Reduzir 500+ linhas de duplicação
- **Component Coverage**: 100% dos enemies usam componentes
- **Pool Utilization**: 80%+ dos enemies/projectiles do pool
- **Frame Time**: <16ms para 100+ enemies on screen
- **Code Reusability**: 60%+ do Space Shooter usa core framework

### Qualitativas
- ✅ Space Shooter é referência de "como fazer certo"
- ✅ SOLID principles respeitados (0 violations críticas)
- ✅ Novos desenvolvedores conseguem estender facilmente
- ✅ Outros exemplos (Rival TD) usam mesmos patterns
- ✅ Documentação completa e clara

---

## 🎯 Priorização por Impacto

### Must Have (Fase 1 + 2.1)
1. **Enemy Pooling** - Performance crítica
2. **Phase System no Core** - Fundamental pattern
3. **Consolidar Wave Formats** - Elimina confusão

### Should Have (Fase 2.2 + 2.3)
4. **Entity Factory Framework** - Padronização
5. **SimpleWeapon → WeaponComponent** - Consistência

### Nice to Have (Fase 3)
6. **Enemy Decomposition** - Melhor arquitetura
7. **Component Setup Helpers** - DRY

### Polish (Fase 4)
8. **Documentation** - Adoção
9. **Performance Metrics** - Debugging

---

## 🚧 Riscos e Mitigações

### Risco 1: Breaking Changes
**Problema**: Refatorações podem quebrar Space Shooter existente

**Mitigação**:
- Git branches para cada fase
- Testes manuais após cada task
- Manter versão anterior funcionando

### Risco 2: Scope Creep
**Problema**: Refatoração pode crescer infinitamente

**Mitigação**:
- Fases bem definidas
- Priorização clara (Must/Should/Nice)
- Timeboxing (1 semana por fase max)

### Risco 3: Framework Abstraction
**Problema**: Core muito genérico pode ficar difícil de usar

**Mitigação**:
- Space Shooter como teste de usabilidade
- Se ficar complicado, simplificar
- Documentação com exemplos concretos

---

## 📅 Timeline Estimado

```
Fase 1 (Quick Wins):        1-2 dias  ████░░░░░░
Fase 2 (Core Refactoring):  3-5 dias  ████████░░
Fase 3 (Enemy Overhaul):    5-7 dias  ██████████
Fase 4 (Polish):            2-3 dias  ████░░░░░░

Total: 11-17 dias (~2.5 semanas)
```

### Milestones
- ✅ **Milestone 1**: Object pooling completo (Fase 1)
- ✅ **Milestone 2**: Phase system no core (Fase 2.1)
- ✅ **Milestone 3**: Enemy decomposition (Fase 3.1)
- ✅ **Milestone 4**: Documentação completa (Fase 4.1)

---

## 🎓 Lições Aprendidas (Para Incluir em Docs)

1. **Component First**: Sempre use componentes, não lógica inline
2. **Inject Dependencies**: Não use hardcoded paths
3. **Pool Early**: Object pooling é free performance
4. **Signal Everything**: Observer pattern reduz coupling
5. **Factory Pattern**: Centraliza criação de entidades
6. **Test with Framework**: Exemplos devem usar core, não reimplementar

---

## 📝 Próximos Passos

### Imediato (Hoje)
1. ✅ Revisar este plano
2. ⏳ Decidir quais fases implementar
3. ⏳ Criar branches no Git

### Curto Prazo (Esta Semana)
1. ⏳ Implementar Fase 1 (Quick Wins)
2. ⏳ Testar enemy pooling

### Médio Prazo (Próximas 2 Semanas)
1. ⏳ Implementar Fase 2 (Core Refactoring)
2. ⏳ Começar Fase 3 (Enemy Overhaul)

### Longo Prazo (Próximo Mês)
1. ⏳ Completar Fase 3 e 4
2. ⏳ Aplicar patterns a Rival TD
3. ⏳ Criar mais exemplos

---

## 🤔 Perguntas para Revisar

1. **Priorização**: Concorda com Must/Should/Nice to Have?
2. **Timeline**: 2.5 semanas é realista? Muito agressivo?
3. **Escopo Fase 3**: Enemy decomposition é worth it ou overkill?
4. **Documentation**: Quanta doc é suficiente?
5. **Performance**: Alvos de 100+ enemies é realista para o jogo?

---

## 📞 Aprovação

**Revisor**: [Seu Nome]
**Data**: ___________
**Status**: [ ] Aprovado [ ] Aprovado com mudanças [ ] Rejeitado

**Comentários**:
```
[Espaço para feedback]
```

---

**Última Atualização**: 2025-12-23
**Versão**: 1.0
**Autor**: Claude Sonnet 4.5 (Agent Analysis)
