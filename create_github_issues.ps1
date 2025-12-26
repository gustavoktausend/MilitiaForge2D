# PowerShell script para criar GitHub Issues
# Executar: .\create_github_issues.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GitHub Issues Creation Script" -ForegroundColor Cyan
Write-Host "  MilitiaForge2D Refactoring Plan" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se gh está instalado
try {
    $ghVersion = gh --version 2>&1
    Write-Host "[OK] GitHub CLI encontrado!" -ForegroundColor Green
} catch {
    Write-Host "[ERRO] GitHub CLI nao encontrado!" -ForegroundColor Red
    Write-Host "Instale em: https://cli.github.com/" -ForegroundColor Yellow
    Read-Host "Pressione Enter para sair"
    exit 1
}

Write-Host ""

# Verificar autenticação
Write-Host "Verificando autenticacao..." -ForegroundColor Yellow
try {
    gh auth status 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Not authenticated"
    }
    Write-Host "[OK] Autenticado no GitHub!" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "Voce precisa autenticar primeiro:" -ForegroundColor Yellow
    Write-Host "Execute: gh auth login" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Pressione Enter para sair"
    exit 1
}

Write-Host ""

# Obter nome do repositório
Write-Host "Detectando repositorio..." -ForegroundColor Yellow
try {
    $repo = gh repo view --json nameWithOwner -q .nameWithOwner 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Repository not found"
    }
    Write-Host "[OK] Repositorio: $repo" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "[ERRO] Nao foi possivel detectar o repositorio!" -ForegroundColor Red
    Write-Host "Certifique-se de estar na pasta do projeto Git." -ForegroundColor Yellow
    Write-Host ""
    $repo = Read-Host "Digite o nome do repositorio (usuario/repo)"
    if ([string]::IsNullOrEmpty($repo)) {
        Write-Host "Cancelado." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""

# Confirmar criação
Write-Host "Vou criar 8 issues no repositorio: $repo" -ForegroundColor Cyan
Write-Host ""
$confirm = Read-Host "Deseja continuar? (S/N)"
if ($confirm -ne "S" -and $confirm -ne "s") {
    Write-Host "Cancelado pelo usuario." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Criando issues..." -ForegroundColor Cyan
Write-Host ""

$issuesCreated = 0
$issuesFailed = 0

# Issue #1: Enemy Pooling
Write-Host "[1/8] Criando Issue #1: Enemy Pooling..." -ForegroundColor Yellow
try {
    gh issue create `
        --repo $repo `
        --title "🔴 CRITICAL: Implement Enemy Object Pooling" `
        --label "critical,performance,enhancement" `
        --body @"
## 📋 Descrição

Enemies são instanciados toda vez via ``enemy_factory.gd``, causando:
- **50+ instantiate() calls** por wave
- **GC pressure** (garbage collection spikes)
- **Frame drops** quando spawning enemies

## 🎯 Solução Proposta

Implementar enemy pooling usando ``ObjectPool`` (já existe para projectiles):

``````gdscript
// EntityPoolManager registra enemy types:
"enemy_basic": initial=20, max=100
"enemy_fast": initial=15, max=80
"enemy_tank": initial=5, max=30

// EnemyFactory tenta acquire do pool primeiro
var enemy = pool.acquire("enemy_basic")
if not enemy:
    enemy = scene.instantiate()  // Fallback
``````

## ✅ Acceptance Criteria

- [ ] Enemies usam ``ObjectPool.acquire()`` em vez de ``instantiate()``
- [ ] Enemies emitem ``despawned`` signal ao morrer
- [ ] ``EntityPoolManager`` retorna enemies ao pool
- [ ] Spawning de 100 enemies < 5ms (vs ~50ms atual)
- [ ] 0 GC spikes durante gameplay

## 📁 Arquivos Afetados

- ``examples/space_shooter/scripts/entity_pool_manager.gd`` (criar/renomear)
- ``examples/space_shooter/scripts/enemy_factory.gd`` (modificar)
- ``examples/space_shooter/scripts/enemy_base.gd`` (adicionar ``reset_for_pool()``)

## 🔗 Referências

- Refactoring Plan: Task 1.3
- Similar: Projectile pooling já implementado

## 📊 Impacto

**Performance**: ⭐⭐⭐⭐⭐ CRÍTICO
**Esforço**: ⭐⭐ BAIXO
**Prioridade**: 🔴 MUST HAVE
"@
    Write-Host "[OK] Issue #1 criada!" -ForegroundColor Green
    $issuesCreated++
} catch {
    Write-Host "[ERRO] Falha ao criar Issue #1: $_" -ForegroundColor Red
    $issuesFailed++
}
Write-Host ""

# Issue #2: SimpleWeapon
Write-Host "[2/8] Criando Issue #2: SimpleWeapon..." -ForegroundColor Yellow
try {
    gh issue create `
        --repo $repo `
        --title "🔴 CRITICAL: SimpleWeapon Duplicates WeaponComponent" `
        --label "critical,refactor,technical-debt" `
        --body @"
## 📋 Descrição

``SimpleWeapon`` (137 linhas) reimplementa lógica de ``WeaponComponent`` do core:
- Duplica ``fire()``, ``can_fire()``, ``execute_fire()`` methods
- Framework tem ``militia_forge/components/weapon_component.gd`` (não usado!)
- **Inconsistência**: Exemplo não usa framework corretamente

## 🎯 Solução Proposta

``````gdscript
// Antes:
class_name SimpleWeapon extends Node
// 137 linhas reimplementando weapon logic

// Depois:
class_name SimpleWeapon extends WeaponComponent
// Herda tudo, apenas customiza pooling integration
``````

## ✅ Acceptance Criteria

- [ ] ``SimpleWeapon extends WeaponComponent``
- [ ] Remove duplicate methods
- [ ] Mantém pooling integration
- [ ] Player shooting funciona identicamente
- [ ] -100 linhas de código

## 📁 Arquivos Afetados

- ``examples/space_shooter/scripts/simple_weapon.gd`` (REWRITE)
- ``examples/space_shooter/scripts/player_controller.gd`` (simplificar)

## 📊 Impacto

**Consistência**: ⭐⭐⭐⭐⭐ CRÍTICO
**Esforço**: ⭐⭐⭐ MÉDIO
**Prioridade**: 🟡 SHOULD HAVE
"@
    Write-Host "[OK] Issue #2 criada!" -ForegroundColor Green
    $issuesCreated++
} catch {
    Write-Host "[ERRO] Falha ao criar Issue #2: $_" -ForegroundColor Red
    $issuesFailed++
}
Write-Host ""

# Issue #3: Phase System
Write-Host "[3/8] Criando Issue #3: Phase System..." -ForegroundColor Yellow
try {
    gh issue create `
        --repo $repo `
        --title "🟡 HIGH: Move Phase/Wave System to Core Framework" `
        --label "enhancement,architecture,refactor" `
        --body @"
## 📋 Descrição

Phase/Wave system está em ``examples/space_shooter/scripts/phase_system/`` mas é **padrão fundamental**:
- Aplicável a: Tower Defense, Roguelikes, Story-driven games
- 295 linhas de lógica genérica presa no exemplo
- Outros projetos precisariam duplicar

## 🎯 Solução Proposta

Mover para core framework:

``````
militia_forge/systems/progression/
├── base_phase_manager.gd (abstract)
├── phase_config.gd (resource)
├── wave_config.gd (resource)
└── wave_strategy.gd (abstract)
``````

Space Shooter herda:
``````gdscript
class SpaceShooterPhaseManager extends BasePhaseManager
``````

## ✅ Acceptance Criteria

- [ ] ``BasePhaseManager`` no core
- [ ] Signals genéricos: ``phase_started``, ``phase_completed``
- [ ] Space Shooter usa ``SpaceShooterPhaseManager``
- [ ] Documentation: Como usar em tower defense

## 📊 Impacto

**Reusabilidade**: ⭐⭐⭐⭐⭐ MUITO ALTO
**Esforço**: ⭐⭐⭐⭐ MÉDIO-ALTO
**Prioridade**: 🔴 MUST HAVE
"@
    Write-Host "[OK] Issue #3 criada!" -ForegroundColor Green
    $issuesCreated++
} catch {
    Write-Host "[ERRO] Falha ao criar Issue #3: $_" -ForegroundColor Red
    $issuesFailed++
}
Write-Host ""

# Issue #4: Enemy Monolith
Write-Host "[4/8] Criando Issue #4: Enemy Monolith..." -ForegroundColor Yellow
try {
    gh issue create `
        --repo $repo `
        --title "🟡 HIGH: Decompose SpaceEnemy Monolith (505 Lines)" `
        --label "refactor,technical-debt,SOLID-violation" `
        --body @"
## 📋 Descrição

``enemy_base.gd`` tem **505 linhas** violando Single Responsibility Principle:
- Component setup (45 lines)
- Movement patterns inline (150 lines)
- Visual management (80 lines)
- Shooting logic (40 lines)

## 🎯 Solução Proposta

Decompor em componentes:
- EnemyMovementComponent
- EnemyVisualComponent
- TurretComponent (já existe!)

SpaceEnemy: 505 → 150 linhas

## ✅ Acceptance Criteria

- [ ] EnemyMovementComponent criado
- [ ] EnemyVisualComponent criado
- [ ] SpaceEnemy usa TurretComponent
- [ ] enemy_base.gd: 505 → ~150 linhas
- [ ] Movement patterns reutilizáveis

## 📊 Impacto

**Arquitetura**: ⭐⭐⭐⭐⭐ MUITO ALTO
**Esforço**: ⭐⭐⭐⭐⭐ ALTO
**Prioridade**: 🔵 NICE TO HAVE
"@
    Write-Host "[OK] Issue #4 criada!" -ForegroundColor Green
    $issuesCreated++
} catch {
    Write-Host "[ERRO] Falha ao criar Issue #4: $_" -ForegroundColor Red
    $issuesFailed++
}
Write-Host ""

# Issue #5: Wave Formats
Write-Host "[5/8] Criando Issue #5: Wave Formats..." -ForegroundColor Yellow
try {
    gh issue create `
        --repo $repo `
        --title "🟢 MEDIUM: Consolidate Wave Data Formats" `
        --label "refactor,cleanup" `
        --body @"
## 📋 Descrição

``wave_manager.gd`` tem **2 formatos de wave data**:
1. Dictionary hardcoded
2. WaveConfig resource

44 linhas de código de conversão (_convert_wave_config_to_data)

## 🎯 Solução Proposta

Usar apenas WaveConfig resource:
- Migrar waves para resources (wave_01.tres, etc.)
- Eliminar _convert_wave_config_to_data()

## ✅ Acceptance Criteria

- [ ] Remover wave_definitions Dictionary
- [ ] Criar wave_01.tres a wave_05.tres
- [ ] Eliminar conversão (44 linhas)
- [ ] 1 único caminho de spawning

## 📊 Impacto

**Simplicidade**: ⭐⭐⭐⭐ ALTO
**Esforço**: ⭐⭐ BAIXO
**Prioridade**: 🔴 MUST HAVE
"@
    Write-Host "[OK] Issue #5 criada!" -ForegroundColor Green
    $issuesCreated++
} catch {
    Write-Host "[ERRO] Falha ao criar Issue #5: $_" -ForegroundColor Red
    $issuesFailed++
}
Write-Host ""

# Issue #6: Hardcoded Paths
Write-Host "[6/8] Criando Issue #6: Hardcoded Paths..." -ForegroundColor Yellow
try {
    gh issue create `
        --repo $repo `
        --title "🟢 MEDIUM: Remove Hardcoded Dependency Paths" `
        --label "refactor,SOLID-violation,testability" `
        --body @"
## 📋 Descrição

Tight coupling via hardcoded node paths.

**Problemas**:
- Não testável
- Frágil
- Viola Dependency Inversion Principle

## 🎯 Solução Proposta

Dependency Injection via setup methods.

## ✅ Acceptance Criteria

- [ ] Remover get_node("/root/...") hardcoded
- [ ] Usar dependency injection
- [ ] Factories para criação
- [ ] Testável com mocks

## 📊 Impacto

**Testabilidade**: ⭐⭐⭐⭐ ALTO
**Esforço**: ⭐⭐⭐ MÉDIO
**Prioridade**: 🟡 SHOULD HAVE
"@
    Write-Host "[OK] Issue #6 criada!" -ForegroundColor Green
    $issuesCreated++
} catch {
    Write-Host "[ERRO] Falha ao criar Issue #6: $_" -ForegroundColor Red
    $issuesFailed++
}
Write-Host ""

# Issue #7: Pooling Core
Write-Host "[7/8] Criando Issue #7: Pooling Core..." -ForegroundColor Yellow
try {
    gh issue create `
        --repo $repo `
        --title "🟢 LOW: Move Object Pooling to Core Framework" `
        --label "enhancement,architecture" `
        --body @"
## 📋 Descrição

``object_pool.gd`` e ``projectile_pool_manager.gd`` estão em examples/ mas são **100% genéricos e reutilizáveis**.

Outros projetos precisariam duplicar.

## 🎯 Solução Proposta

Mover para core:
- object_pool.gd → militia_forge/systems/pooling/
- ProjectilePoolManager → EntityPoolManager (generalizar)

## ✅ Acceptance Criteria

- [ ] object_pool.gd em militia_forge/systems/pooling/
- [ ] EntityPoolManager (não apenas projectiles)
- [ ] Documentation
- [ ] Space Shooter continua funcionando

## 📊 Impacto

**Reusabilidade**: ⭐⭐⭐⭐ ALTO
**Esforço**: ⭐ MUITO BAIXO
**Prioridade**: 🔴 MUST HAVE
"@
    Write-Host "[OK] Issue #7 criada!" -ForegroundColor Green
    $issuesCreated++
} catch {
    Write-Host "[ERRO] Falha ao criar Issue #7: $_" -ForegroundColor Red
    $issuesFailed++
}
Write-Host ""

# Issue #8: Setup Duplication
Write-Host "[8/8] Criando Issue #8: Setup Duplication..." -ForegroundColor Yellow
try {
    gh issue create `
        --repo $repo `
        --title "🟢 LOW: Remove Component Setup Duplication" `
        --label "refactor,DRY" `
        --body @"
## 📋 Descrição

Player e Enemy têm **~40 linhas duplicadas** de setup:
- CharacterBody2D + collision
- CollisionShape2D
- Hurtbox

## 🎯 Solução Proposta

Helper no core para criar physics entities.

## ✅ Acceptance Criteria

- [ ] entity_setup.gd helper criado
- [ ] PlayerController usa helper (-30 linhas)
- [ ] SpaceEnemy usa helper (-30 linhas)
- [ ] Setup pattern padronizado

## 📊 Impacto

**Simplicidade**: ⭐⭐⭐ MÉDIO
**Esforço**: ⭐⭐ BAIXO
**Prioridade**: 🔵 NICE TO HAVE
"@
    Write-Host "[OK] Issue #8 criada!" -ForegroundColor Green
    $issuesCreated++
} catch {
    Write-Host "[ERRO] Falha ao criar Issue #8: $_" -ForegroundColor Red
    $issuesFailed++
}
Write-Host ""

# Finalização
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Issues criadas com sucesso!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total: $issuesCreated issues criadas" -ForegroundColor Green
if ($issuesFailed -gt 0) {
    Write-Host "Falhas: $issuesFailed issues" -ForegroundColor Red
}
Write-Host ""
Write-Host "Visualize em:" -ForegroundColor Cyan
Write-Host "https://github.com/$repo/issues" -ForegroundColor Yellow
Write-Host ""
Write-Host "Proximo passo: Atribuir issues e comecar a trabalhar!" -ForegroundColor Cyan
Write-Host ""
Read-Host "Pressione Enter para sair"
