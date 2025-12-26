@echo off
REM Script para criar GitHub Issues usando GitHub CLI
REM Executar: create_github_issues.bat

echo ========================================
echo   GitHub Issues Creation Script
echo   MilitiaForge2D Refactoring Plan
echo ========================================
echo.

REM Verificar se gh está instalado
gh --version >nul 2>&1
if errorlevel 1 (
    echo ERRO: GitHub CLI nao encontrado!
    echo Instale em: https://cli.github.com/
    pause
    exit /b 1
)

echo [OK] GitHub CLI encontrado!
echo.

REM Verificar autenticação
echo Verificando autenticacao...
gh auth status >nul 2>&1
if errorlevel 1 (
    echo.
    echo Voce precisa autenticar primeiro:
    echo Execute: gh auth login
    echo.
    pause
    exit /b 1
)

echo [OK] Autenticado no GitHub!
echo.

REM Obter nome do repositório
echo Detectando repositorio...
cd /d "%~dp0"
for /f "tokens=*" %%i in ('gh repo view --json nameWithOwner -q .nameWithOwner 2^>nul') do set REPO=%%i

if "%REPO%"=="" (
    echo.
    echo ERRO: Nao foi possivel detectar o repositorio!
    echo Certifique-se de estar na pasta do projeto Git.
    echo.
    echo Ou especifique manualmente:
    set /p REPO="Digite o nome do repositorio (usuario/repo): "
)

echo [OK] Repositorio: %REPO%
echo.

REM Confirmar criação
echo.
echo Vou criar 8 issues no repositorio: %REPO%
echo.
set /p CONFIRM="Deseja continuar? (S/N): "
if /i not "%CONFIRM%"=="S" (
    echo Cancelado pelo usuario.
    pause
    exit /b 0
)

echo.
echo Criando issues...
echo.

REM ============================================
REM ISSUE #1: Enemy Pooling
REM ============================================
echo [1/8] Criando Issue #1: Enemy Pooling...

gh issue create ^
  --repo "%REPO%" ^
  --title "🔴 CRITICAL: Implement Enemy Object Pooling" ^
  --label "critical,performance,enhancement" ^
  --body "## 📋 Descrição%0A%0AEnemies são instanciados toda vez via `enemy_factory.gd`, causando:%0A- **50+ instantiate() calls** por wave%0A- **GC pressure** (garbage collection spikes)%0A- **Frame drops** quando spawning enemies%0A%0A## 🎯 Solução Proposta%0A%0AImplementar enemy pooling usando `ObjectPool` (já existe para projectiles):%0A%0A```gdscript%0A// EntityPoolManager registra enemy types:%0A\"enemy_basic\": initial=20, max=100%0A\"enemy_fast\": initial=15, max=80%0A\"enemy_tank\": initial=5, max=30%0A%0A// EnemyFactory tenta acquire do pool primeiro%0Avar enemy = pool.acquire(\"enemy_basic\")%0Aif not enemy:%0A    enemy = scene.instantiate()  // Fallback%0A```%0A%0A## ✅ Acceptance Criteria%0A%0A- [ ] Enemies usam `ObjectPool.acquire()` em vez de `instantiate()`%0A- [ ] Enemies emitem `despawned` signal ao morrer%0A- [ ] `EntityPoolManager` retorna enemies ao pool%0A- [ ] Spawning de 100 enemies < 5ms (vs ~50ms atual)%0A- [ ] 0 GC spikes durante gameplay%0A%0A## 📁 Arquivos Afetados%0A%0A- `examples/space_shooter/scripts/entity_pool_manager.gd` (criar/renomear)%0A- `examples/space_shooter/scripts/enemy_factory.gd` (modificar)%0A- `examples/space_shooter/scripts/enemy_base.gd` (adicionar `reset_for_pool()`)%0A%0A## 🔗 Referências%0A%0A- Refactoring Plan: Task 1.3%0A- Similar: Projectile pooling já implementado%0A%0A## 📊 Impacto%0A%0A**Performance**: ⭐⭐⭐⭐⭐ CRÍTICO%0A**Esforço**: ⭐⭐ BAIXO%0A**Prioridade**: 🔴 MUST HAVE"

if errorlevel 1 (
    echo [ERRO] Falha ao criar Issue #1
) else (
    echo [OK] Issue #1 criada!
)
echo.

REM ============================================
REM ISSUE #2: SimpleWeapon
REM ============================================
echo [2/8] Criando Issue #2: SimpleWeapon...

gh issue create ^
  --repo "%REPO%" ^
  --title "🔴 CRITICAL: SimpleWeapon Duplicates WeaponComponent" ^
  --label "critical,refactor,technical-debt" ^
  --body "## 📋 Descrição%0A%0A`SimpleWeapon` (137 linhas) reimplementa lógica de `WeaponComponent` do core:%0A- Duplica `fire()`, `can_fire()`, `execute_fire()` methods%0A- Framework tem `militia_forge/components/weapon_component.gd` (não usado!)%0A- **Inconsistência**: Exemplo não usa framework corretamente%0A%0A## 🎯 Solução Proposta%0A%0A```gdscript%0A// Antes:%0Aclass_name SimpleWeapon extends Node%0A// 137 linhas reimplementando weapon logic%0A%0A// Depois:%0Aclass_name SimpleWeapon extends WeaponComponent%0A// Herda tudo, apenas customiza pooling integration%0A```%0A%0A## ✅ Acceptance Criteria%0A%0A- [ ] `SimpleWeapon extends WeaponComponent`%0A- [ ] Remove duplicate methods%0A- [ ] Mantém pooling integration%0A- [ ] Player shooting funciona identicamente%0A- [ ] -100 linhas de código%0A%0A## 📁 Arquivos Afetados%0A%0A- `examples/space_shooter/scripts/simple_weapon.gd` (REWRITE)%0A- `examples/space_shooter/scripts/player_controller.gd` (simplificar)%0A%0A## 📊 Impacto%0A%0A**Consistência**: ⭐⭐⭐⭐⭐ CRÍTICO%0A**Esforço**: ⭐⭐⭐ MÉDIO%0A**Prioridade**: 🟡 SHOULD HAVE"

if errorlevel 1 (
    echo [ERRO] Falha ao criar Issue #2
) else (
    echo [OK] Issue #2 criada!
)
echo.

REM ============================================
REM ISSUE #3: Phase System
REM ============================================
echo [3/8] Criando Issue #3: Phase System...

gh issue create ^
  --repo "%REPO%" ^
  --title "🟡 HIGH: Move Phase/Wave System to Core Framework" ^
  --label "enhancement,architecture,refactor" ^
  --body "## 📋 Descrição%0A%0APhase/Wave system está em `examples/space_shooter/scripts/phase_system/` mas é **padrão fundamental**:%0A- Aplicável a: Tower Defense, Roguelikes, Story-driven games%0A- 295 linhas de lógica genérica presa no exemplo%0A- Outros projetos precisariam duplicar%0A%0A## 🎯 Solução Proposta%0A%0AMover para core framework:%0A%0A```%0Amilitia_forge/systems/progression/%0A├── base_phase_manager.gd (abstract)%0A├── phase_config.gd (resource)%0A├── wave_config.gd (resource)%0A└── wave_strategy.gd (abstract)%0A```%0A%0ASpace Shooter herda:%0A```gdscript%0Aclass SpaceShooterPhaseManager extends BasePhaseManager%0A```%0A%0A## ✅ Acceptance Criteria%0A%0A- [ ] `BasePhaseManager` no core%0A- [ ] Signals genéricos: `phase_started`, `phase_completed`%0A- [ ] Space Shooter usa `SpaceShooterPhaseManager`%0A- [ ] Documentation: Como usar em tower defense%0A%0A## 📊 Impacto%0A%0A**Reusabilidade**: ⭐⭐⭐⭐⭐ MUITO ALTO%0A**Esforço**: ⭐⭐⭐⭐ MÉDIO-ALTO%0A**Prioridade**: 🔴 MUST HAVE"

if errorlevel 1 (
    echo [ERRO] Falha ao criar Issue #3
) else (
    echo [OK] Issue #3 criada!
)
echo.

REM ============================================
REM ISSUE #4: Enemy Monolith
REM ============================================
echo [4/8] Criando Issue #4: Enemy Monolith...

gh issue create ^
  --repo "%REPO%" ^
  --title "🟡 HIGH: Decompose SpaceEnemy Monolith (505 Lines)" ^
  --label "refactor,technical-debt,SOLID-violation" ^
  --body "## 📋 Descrição%0A%0A`enemy_base.gd` tem **505 linhas** violando Single Responsibility Principle:%0A- Component setup (45 lines)%0A- Movement patterns inline (150 lines)%0A- Visual management (80 lines)%0A- Shooting logic (40 lines)%0A%0A## 🎯 Solução Proposta%0A%0ADecompor em componentes:%0A- EnemyMovementComponent%0A- EnemyVisualComponent%0A- TurretComponent (já existe!)%0A%0ASpaceEnemy: 505 → 150 linhas%0A%0A## ✅ Acceptance Criteria%0A%0A- [ ] EnemyMovementComponent criado%0A- [ ] EnemyVisualComponent criado%0A- [ ] SpaceEnemy usa TurretComponent%0A- [ ] enemy_base.gd: 505 → ~150 linhas%0A- [ ] Movement patterns reutilizáveis%0A%0A## 📊 Impacto%0A%0A**Arquitetura**: ⭐⭐⭐⭐⭐ MUITO ALTO%0A**Esforço**: ⭐⭐⭐⭐⭐ ALTO%0A**Prioridade**: 🔵 NICE TO HAVE"

if errorlevel 1 (
    echo [ERRO] Falha ao criar Issue #4
) else (
    echo [OK] Issue #4 criada!
)
echo.

REM ============================================
REM ISSUE #5: Wave Formats
REM ============================================
echo [5/8] Criando Issue #5: Wave Formats...

gh issue create ^
  --repo "%REPO%" ^
  --title "🟢 MEDIUM: Consolidate Wave Data Formats" ^
  --label "refactor,cleanup" ^
  --body "## 📋 Descrição%0A%0A`wave_manager.gd` tem **2 formatos de wave data**:%0A1. Dictionary hardcoded%0A2. WaveConfig resource%0A%0A44 linhas de código de conversão (_convert_wave_config_to_data)%0A%0A## 🎯 Solução Proposta%0A%0AUsar apenas WaveConfig resource:%0A- Migrar waves para resources (wave_01.tres, etc.)%0A- Eliminar _convert_wave_config_to_data()%0A%0A## ✅ Acceptance Criteria%0A%0A- [ ] Remover wave_definitions Dictionary%0A- [ ] Criar wave_01.tres a wave_05.tres%0A- [ ] Eliminar conversão (44 linhas)%0A- [ ] 1 único caminho de spawning%0A%0A## 📊 Impacto%0A%0A**Simplicidade**: ⭐⭐⭐⭐ ALTO%0A**Esforço**: ⭐⭐ BAIXO%0A**Prioridade**: 🔴 MUST HAVE"

if errorlevel 1 (
    echo [ERRO] Falha ao criar Issue #5
) else (
    echo [OK] Issue #5 criada!
)
echo.

REM ============================================
REM ISSUE #6: Hardcoded Paths
REM ============================================
echo [6/8] Criando Issue #6: Hardcoded Paths...

gh issue create ^
  --repo "%REPO%" ^
  --title "🟢 MEDIUM: Remove Hardcoded Dependency Paths" ^
  --label "refactor,SOLID-violation,testability" ^
  --body "## 📋 Descrição%0A%0ATight coupling via hardcoded node paths:%0A%0A```gdscript%0A// simple_weapon.gd:43%0A_pool_manager = get_node_or_null(\"/root/ProjectilePoolManager\")%0A%0A// game_controller.gd:72%0Aplayer.set_script(preload(\"res://examples/..\"))%0A```%0A%0A**Problemas**:%0A- Não testável%0A- Frágil%0A- Viola Dependency Inversion Principle%0A%0A## 🎯 Solução Proposta%0A%0ADependency Injection:%0A%0A```gdscript%0Afunc setup_pool_manager(pool: Node) -> void:%0A    _pool_manager = pool%0A```%0A%0A## ✅ Acceptance Criteria%0A%0A- [ ] Remover get_node(\"/root/...\") hardcoded%0A- [ ] Usar dependency injection%0A- [ ] Factories para criação%0A- [ ] Testável com mocks%0A%0A## 📊 Impacto%0A%0A**Testabilidade**: ⭐⭐⭐⭐ ALTO%0A**Esforço**: ⭐⭐⭐ MÉDIO%0A**Prioridade**: 🟡 SHOULD HAVE"

if errorlevel 1 (
    echo [ERRO] Falha ao criar Issue #6
) else (
    echo [OK] Issue #6 criada!
)
echo.

REM ============================================
REM ISSUE #7: Pooling Core
REM ============================================
echo [7/8] Criando Issue #7: Pooling Core...

gh issue create ^
  --repo "%REPO%" ^
  --title "🟢 LOW: Move Object Pooling to Core Framework" ^
  --label "enhancement,architecture" ^
  --body "## 📋 Descrição%0A%0A`object_pool.gd` e `projectile_pool_manager.gd` estão em examples/ mas são **100%% genéricos e reutilizáveis**.%0A%0AOutros projetos precisariam duplicar.%0A%0A## 🎯 Solução Proposta%0A%0AMover para core:%0A- object_pool.gd → militia_forge/systems/pooling/%0A- ProjectilePoolManager → EntityPoolManager (generalizar)%0A%0A## ✅ Acceptance Criteria%0A%0A- [ ] object_pool.gd em militia_forge/systems/pooling/%0A- [ ] EntityPoolManager (não apenas projectiles)%0A- [ ] Documentation%0A- [ ] Space Shooter continua funcionando%0A%0A## 📊 Impacto%0A%0A**Reusabilidade**: ⭐⭐⭐⭐ ALTO%0A**Esforço**: ⭐ MUITO BAIXO%0A**Prioridade**: 🔴 MUST HAVE"

if errorlevel 1 (
    echo [ERRO] Falha ao criar Issue #7
) else (
    echo [OK] Issue #7 criada!
)
echo.

REM ============================================
REM ISSUE #8: Setup Duplication
REM ============================================
echo [8/8] Criando Issue #8: Setup Duplication...

gh issue create ^
  --repo "%REPO%" ^
  --title "🟢 LOW: Remove Component Setup Duplication" ^
  --label "refactor,DRY" ^
  --body "## 📋 Descrição%0A%0APlayer e Enemy têm **~40 linhas duplicadas** de setup:%0A- CharacterBody2D + collision%0A- CollisionShape2D%0A- Hurtbox%0A%0A## 🎯 Solução Proposta%0A%0AHelper no core:%0A%0A```gdscript%0Amilitia_forge/helpers/entity_setup.gd%0A%0Astatic func create_physics_entity()%0A```%0A%0AUso:%0A```gdscript%0Avar setup = EntitySetup.create_physics_entity(self, 1, 2, Vector2(48, 72))%0A```%0A%0A## ✅ Acceptance Criteria%0A%0A- [ ] entity_setup.gd helper criado%0A- [ ] PlayerController usa helper (-30 linhas)%0A- [ ] SpaceEnemy usa helper (-30 linhas)%0A- [ ] Setup pattern padronizado%0A%0A## 📊 Impacto%0A%0A**Simplicidade**: ⭐⭐⭐ MÉDIO%0A**Esforço**: ⭐⭐ BAIXO%0A**Prioridade**: 🔵 NICE TO HAVE"

if errorlevel 1 (
    echo [ERRO] Falha ao criar Issue #8
) else (
    echo [OK] Issue #8 criada!
)
echo.

REM ============================================
REM Finalização
REM ============================================
echo.
echo ========================================
echo   Issues criadas com sucesso!
echo ========================================
echo.
echo Total: 8 issues criadas no repositorio %REPO%
echo.
echo Visualize em:
echo https://github.com/%REPO%/issues
echo.
echo Proximo passo: Atribuir issues e comecar a trabalhar!
echo.
pause
