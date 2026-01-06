# Como Fixar os Autoloads para Permitir Testes CLI

## Problema

Os autoloads do `space_shooter` estão causando erros de parse porque dependem de classes que ainda não foram carregadas quando o Godot inicia. Isso impede testes CLI com `godot --headless`.

## Classes Faltantes vs Existentes

### ✅ Classes que EXISTEM mas não são encontradas:
- `ShipConfig` → existe em `examples/space_shooter/scripts/ship_config.gd`
- `PilotData` → existe em `examples/space_shooter/scripts/pilot_data.gd`
- `ObjectPool` → existe em `examples/space_shooter/scripts/object_pool.gd`
- `ShopDatabase` → existe em `examples/space_shooter/scripts/shop/shop_database.gd`
- `WeaponDatabase` → existe em `examples/space_shooter/scripts/weapon_database.gd`

### 🔍 Causa Raiz

O problema é **ordem de carregamento**. Os autoloads tentam usar classes antes delas serem registradas no Godot.

---

## Solução 1: Desabilitar Autoloads Temporariamente (MAIS RÁPIDO) ⚡

Comentar os autoloads problemáticos no `project.godot` para testes:

### Editar `project.godot`:

```ini
[autoload]

AudioManager="*res://examples/space_shooter/scripts/audio_manager.gd"
# PlayerData="*res://examples/space_shooter/scripts/player_data.gd"  # DESABILITADO
# EntityPoolManager="*res://examples/space_shooter/scripts/entity_pool_manager.gd"  # DESABILITADO
SceneManager="*res://addons/scene_manager/scene_manager.tscn"
Scenes="*res://addons/scene_manager/scenes.gd"
# UpgradeManager="*res://examples/space_shooter/scripts/upgrade_manager.gd"  # DESABILITADO
```

### ✅ Prós:
- Mudança mínima (3 linhas comentadas)
- Funciona imediatamente
- Não quebra spell_battle (que não usa esses autoloads)

### ❌ Contras:
- Quebra space_shooter temporariamente
- Precisa descomentar depois

---

## Solução 2: Adicionar Preload Explícito (RECOMENDADO) 🎯

Adicionar `preload()` no início de cada autoload problemático.

### 2.1 Fixar `player_data.gd`

**Arquivo**: `examples/space_shooter/scripts/player_data.gd`

```gdscript
# ADICIONAR NO TOPO (linha 2-3):
const ShipConfig = preload("res://examples/space_shooter/scripts/ship_config.gd")
const PilotData = preload("res://examples/space_shooter/scripts/pilot_data.gd")

extends Node

# ... resto do código
```

### 2.2 Fixar `entity_pool_manager.gd`

**Arquivo**: `examples/space_shooter/scripts/entity_pool_manager.gd`

```gdscript
# ADICIONAR NO TOPO (linha 2):
const ObjectPool = preload("res://examples/space_shooter/scripts/object_pool.gd")

extends Node

# ... resto do código
```

### 2.3 Fixar `upgrade_manager.gd`

**Arquivo**: `examples/space_shooter/scripts/upgrade_manager.gd`

```gdscript
# ADICIONAR NO TOPO (linha 2):
const ShopDatabase = preload("res://examples/space_shooter/scripts/shop/shop_database.gd")

extends Node

# ... resto do código
```

### 2.4 Fixar `loadout_selection_ui.gd`

**Arquivo**: `examples/space_shooter/scripts/loadout_selection_ui.gd`

```gdscript
# ADICIONAR NO TOPO (linha 2):
const WeaponDatabase = preload("res://examples/space_shooter/scripts/weapon_database.gd")

extends Control  # ou qualquer que seja a classe base

# ... resto do código
```

### ✅ Prós:
- Solução permanente
- Não quebra nada
- Segue boas práticas Godot
- `preload()` garante que classes sejam carregadas antes

### ❌ Contras:
- Precisa editar 4 arquivos
- Mais trabalhoso

---

## Solução 3: Verificar class_name nos Arquivos Base

Garantir que todas as classes têm `class_name` declarado.

### Verificar cada arquivo:

#### `ship_config.gd`
```gdscript
class_name ShipConfig  # DEVE ESTAR NA LINHA 1 ou 2
extends Resource
```

#### `pilot_data.gd`
```gdscript
class_name PilotData  # DEVE ESTAR NA LINHA 1 ou 2
extends Resource
```

#### `object_pool.gd`
```gdscript
class_name ObjectPool  # DEVE ESTAR NA LINHA 1 ou 2
extends Node
```

#### `shop_database.gd`
```gdscript
class_name ShopDatabase  # DEVE ESTAR NA LINHA 1 ou 2
extends Object
```

#### `weapon_database.gd`
```gdscript
class_name WeaponDatabase  # DEVE ESTAR NA LINHA 1 ou 2
extends Object
```

### ✅ Prós:
- Boa prática
- Permite que Godot registre classes globalmente

### ⚠️ Nota:
- Se já existirem `class_name`, esse não é o problema
- Problema real é ordem de carregamento

---

## Solução 4: Criar Projeto Minimal para Testes (ALTERNATIVA)

Criar um novo projeto Godot apenas para testar spell_battle.

### Passos:

1. Criar novo projeto Godot vazio
2. Copiar pastas:
   - `militia_forge/core/` → componentes base
   - `militia_forge/components/` → componentes genéricos
   - `examples/spell_battle/` → todo o spell_battle
3. Configurar `project.godot` sem autoloads
4. Executar testes

### ✅ Prós:
- Ambiente limpo
- Sem interferências
- Fácil de testar

### ❌ Contras:
- Projeto duplicado
- Precisa manter sincronizado

---

## Recomendação Final 🎯

### Para testes RÁPIDOS (agora):
**Usar Solução 1** - Comentar autoloads
```bash
# Editar project.godot manualmente ou via script:
# Comentar linhas 23, 24, 27
```

### Para solução PERMANENTE:
**Usar Solução 2** - Adicionar preload()

Sequência de edições:
1. `examples/space_shooter/scripts/player_data.gd` → adicionar 2 preloads
2. `examples/space_shooter/scripts/entity_pool_manager.gd` → adicionar 1 preload
3. `examples/space_shooter/scripts/upgrade_manager.gd` → adicionar 1 preload
4. `examples/space_shooter/scripts/loadout_selection_ui.gd` → adicionar 1 preload

---

## Como Testar Após Fix

### Teste 1: Validar projeto
```bash
cd C:\Users\Gustavo\.claude-worktrees\MilitiaForge2D\nervous-nightingale
godot --headless --check-only --quit
```

**Esperado**: Sem erros de parse

### Teste 2: Executar teste simples
```bash
godot --headless --script examples/spell_battle/test_simple.gd
```

**Esperado**:
```
=== SPELL BATTLE - SYNTAX VALIDATION ===

Testing Resources...
✓ ChipData loaded
✓ NaviData loaded
✓ DeckConfiguration loaded

Testing Databases...
✓ ChipDatabase working - created Fireball
✓ NaviDatabase working - created MegaMan

Testing Components...
✓ ChipComponent instantiated
✓ NaviComponent instantiated
...

=== ALL CLASSES LOADED SUCCESSFULLY! ===
```

### Teste 3: Executar teste completo
```bash
godot --headless --script examples/spell_battle/test_phase1.gd
```

**Esperado**: Todos os testes passando com prints de sucesso

---

## Script Automatizado para Solução 1

Criar arquivo `fix_autoloads.sh` (Git Bash) ou `fix_autoloads.ps1` (PowerShell):

### PowerShell Script:
```powershell
# fix_autoloads.ps1
$projectFile = "project.godot"
$content = Get-Content $projectFile

$content = $content -replace 'PlayerData=', '#PlayerData='
$content = $content -replace 'EntityPoolManager=', '#EntityPoolManager='
$content = $content -replace 'UpgradeManager=', '#UpgradeManager='

$content | Set-Content $projectFile
Write-Host "✓ Autoloads desabilitados para testes"
```

### Executar:
```bash
powershell -File fix_autoloads.ps1
```

### Para REVERTER:
```powershell
# restore_autoloads.ps1
$projectFile = "project.godot"
$content = Get-Content $projectFile

$content = $content -replace '#PlayerData=', 'PlayerData='
$content = $content -replace '#EntityPoolManager=', 'EntityPoolManager='
$content = $content -replace '#UpgradeManager=', 'UpgradeManager='

$content | Set-Content $projectFile
Write-Host "✓ Autoloads restaurados"
```

---

## Resumo de Edições Necessárias

### Opção Rápida (Solução 1):
- ✏️ Editar 1 arquivo: `project.godot`
- 📝 Comentar 3 linhas (23, 24, 27)
- ⏱️ Tempo: 1 minuto

### Opção Permanente (Solução 2):
- ✏️ Editar 4 arquivos:
  1. `player_data.gd` → adicionar 2 linhas
  2. `entity_pool_manager.gd` → adicionar 1 linha
  3. `upgrade_manager.gd` → adicionar 1 linha
  4. `loadout_selection_ui.gd` → adicionar 1 linha
- 📝 Total: 5 linhas adicionadas
- ⏱️ Tempo: 5 minutos

---

**Quer que eu aplique alguma dessas soluções agora?**
