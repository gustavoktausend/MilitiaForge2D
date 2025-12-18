# 🎮 Phase System - Design Pattern Architecture

## 📋 Resumo

Sistema modular e escalável para gerenciar fases, waves e progressão do jogo usando **Design Patterns** profissionais.

**Principais Patterns:**
- ✅ **Strategy Pattern** - Diferentes estratégias de geração de waves
- ✅ **Factory Pattern** - Criação centralizada de inimigos
- ✅ **Resource Pattern** - Configuração data-driven
- ✅ **Observer Pattern** - Comunicação via signals

---

## 🏗️ Arquitetura

### **Componentes Principais:**

```
┌─────────────────────────────────────────────────────────────┐
│                      PHASE SYSTEM                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐      ┌──────────────┐                    │
│  │ PhaseConfig  │──┬──▶│ WaveConfig   │                    │
│  │  (Resource)  │  │   │  (Resource)  │                    │
│  └──────────────┘  │   └──────────────┘                    │
│                    │           │                            │
│                    │           ▼                            │
│                    │   ┌──────────────────┐                │
│                    └──▶│ EnemySpawnGroup  │                │
│                        │    (Resource)    │                │
│                        └──────────────────┘                │
│                                                             │
│  ┌──────────────────────────────────────────────┐          │
│  │          PhaseManager (Node)                 │          │
│  │  - Gerencia progressão entre fases           │          │
│  │  - Coordena WaveManager                      │          │
│  │  - Emite signals de progresso                │          │
│  └──────────────────────────────────────────────┘          │
│                         │                                   │
│                         ▼                                   │
│  ┌──────────────────────────────────────────────┐          │
│  │          WaveManager (Node2D)                │          │
│  │  - Spawna inimigos conforme config           │          │
│  │  - Gerencia spawn timing                     │          │
│  │  - Usa EnemyFactory                          │          │
│  └──────────────────────────────────────────────┘          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Classes Resource

### **1. EnemySpawnGroup**
```gdscript
# examples/space_shooter/scripts/phase_system/enemy_spawn_group.gd
class_name EnemySpawnGroup extends Resource

# Configuração de grupo de inimigos
@export var enemy_type: String = "Basic"
@export var count: int = 5
@export var health_override: int = 0
@export var speed_multiplier: float = 1.0
@export var spawn_pattern: String = "Random"
@export var movement_pattern: int = 0
@export var can_shoot: bool = false
```

**Uso:**
- Define um grupo de inimigos que spawnam juntos
- Permite overrides de stats (saúde, velocidade, etc)
- Configurável no Inspector do Godot

### **2. WaveConfig**
```gdscript
# examples/space_shooter/scripts/phase_system/wave_config.gd
class_name WaveConfig extends Resource

@export var wave_number: int = 1
@export var wave_name: String = "Wave 1"
@export var difficulty: String = "Normal"
@export var enemy_groups: Array[EnemySpawnGroup] = []
@export var max_duration: float = 60.0
@export var powerup_chance: float = 0.15
@export var completion_bonus: int = 500
```

**Uso:**
- Define uma wave completa com múltiplos grupos
- Configuração de timing e recompensas
- Pode ser salva como `.tres` file

### **3. PhaseConfig**
```gdscript
# examples/space_shooter/scripts/phase_system/phase_config.gd
class_name PhaseConfig extends Resource

@export var phase_number: int = 1
@export var phase_name: String = "Phase 1"
@export var waves: Array[WaveConfig] = []
@export var has_boss: bool = false
@export var boss_health: int = 1000
@export var background_theme: String = "Space"
@export var loop_waves: bool = false
```

**Uso:**
- Define uma fase completa com várias waves
- Configuração de boss e tema visual
- Suporte a modo endless (loop)

---

## 🎯 Strategy Pattern - WaveStrategy

### **Base Class:**
```gdscript
# examples/space_shooter/scripts/phase_system/wave_strategy.gd
class_name WaveStrategy extends Resource

func generate_wave(wave_number: int, difficulty_mult: float) -> WaveConfig:
    # Implementado pelas subclasses
    pass
```

### **Estratégias Implementadas:**

#### **1. ProgressiveWaveStrategy**
```gdscript
# Dificuldade progressiva linear
- Waves começam fáceis e vão ficando mais difíceis
- Introduz novos tipos de inimigos gradualmente
- Wave 1-3: Apenas Basic
- Wave 3+: Fast enemies
- Wave 5+: Tank enemies
- Wave 4+: Inimigos começam a atirar
```

**Ideal para:** Modo campanha normal, curva de aprendizado suave

#### **2. SwarmWaveStrategy**
```gdscript
# Enxames de inimigos fracos e rápidos
- Quantidade > Qualidade
- Muitos Fast enemies (70% do total)
- Inimigos com pouca vida
- Spawn rápido e intenso
- Mini-boss a cada 3 waves
```

**Ideal para:** Fases de ação intensa, teste de reflexos

#### **3. EliteWaveStrategy**
```gdscript
# Poucos inimigos muito fortes
- Qualidade > Quantidade
- Inimigos com 2x mais vida
- Todos atiram
- Padrões de movimento avançados
- Boss a cada 5 waves
```

**Ideal para:** Fases finais, desafio estratégico

---

## 🎮 PhaseManager - Gerenciador de Progressão

### **Responsabilidades:**

1. **Gerenciar Fases:**
   - Carregar PhaseConfigs
   - Transições entre fases
   - Validação de configurações

2. **Gerenciar Waves:**
   - Iniciar waves na ordem correta
   - Aplicar timing (preparation, rest)
   - Detectar conclusão

3. **Comunicação:**
   - Emitir signals de progresso
   - Coordenar com WaveManager
   - Notificar GameController

4. **Boss Battles:**
   - Detectar fase boss
   - Spawnar boss
   - Gerenciar derrota do boss

### **Signals:**
```gdscript
signal phase_started(phase_config: PhaseConfig)
signal phase_completed(phase_config: PhaseConfig, score: int)
signal wave_started(wave_config: WaveConfig, wave_index: int)
signal wave_completed(wave_config: WaveConfig, enemies: int, score: int)
signal boss_battle_started(boss_config: Dictionary)
signal boss_defeated(score: int)
signal all_phases_completed(total_score: int)
```

### **Métodos Principais:**
```gdscript
# Iniciar sistema de fases
phase_manager.start(phase_index: int = 0)

# Callback de conclusão de wave (chamado pelo WaveManager)
phase_manager.on_wave_completed(enemies_defeated: int, score: int)

# Callback de derrota do boss
phase_manager.on_boss_defeated()

# Obter progresso
var phase_progress = phase_manager.get_phase_progress()  # 0.0 - 1.0
var overall_progress = phase_manager.get_overall_progress()  # 0.0 - 1.0
```

---

## 🔄 Fluxo de Execução

### **Modo Normal (Fases Pré-configuradas):**

```
1. PhaseManager.start()
   ↓
2. Load PhaseConfig (from .tres file)
   ↓
3. PhaseManager emits phase_started
   ↓
4. Load first WaveConfig from phase.waves[0]
   ↓
5. PhaseManager emits wave_started
   ↓
6. PhaseManager calls WaveManager.start_wave_from_config()
   ↓
7. WaveManager converts WaveConfig → wave_data
   ↓
8. WaveManager spawns enemies using EnemyFactory
   ↓
9. WaveManager tracks enemy deaths
   ↓
10. When all enemies dead → WaveManager completes wave
   ↓
11. PhaseManager.on_wave_completed() called
   ↓
12. Wait rest_time → Start next wave (goto 4)
   ↓
13. When all waves done → Check for boss
   ↓
14. If has_boss → Spawn boss → on_boss_defeated()
   ↓
15. PhaseManager emits phase_completed
   ↓
16. Load next PhaseConfig (goto 2) or complete game
```

### **Modo Dinâmico (Strategy Pattern):**

```
1. PhaseManager.start() with use_dynamic_waves = true
   ↓
2. PhaseManager calls wave_strategy.generate_wave(wave_number)
   ↓
3. Strategy creates WaveConfig procedurally
   ↓
4. Continue from step 5 above (wave_started)
```

---

## 🛠️ Como Usar

### **Opção 1: Criar Fases Visualmente (Recomendado)**

1. **Criar EnemySpawnGroup:**
   ```
   - No Godot: Resource → New Resource → EnemySpawnGroup
   - Configure no Inspector:
     - enemy_type: "Basic"
     - count: 5
     - movement_pattern: Zigzag
     - can_shoot: true
   - Save As: data/waves/basic_group_1.tres
   ```

2. **Criar WaveConfig:**
   ```
   - Resource → New Resource → WaveConfig
   - Configure:
     - wave_number: 1
     - wave_name: "First Wave"
     - Adicionar enemy_groups (arrastar .tres files)
     - max_duration: 30.0
   - Save As: data/waves/wave_1.tres
   ```

3. **Criar PhaseConfig:**
   ```
   - Resource → New Resource → PhaseConfig
   - Configure:
     - phase_number: 1
     - phase_name: "Invasion Begins"
     - Adicionar waves (arrastar wave_*.tres files)
     - has_boss: false
   - Save As: data/phases/phase_1.tres
   ```

4. **Adicionar PhaseManager à cena:**
   ```gdscript
   # Em main_game.tscn, adicionar PhaseManager node
   # No Inspector:
   - phases: [arrastar phase_1.tres, phase_2.tres, etc]
   - use_dynamic_waves: false
   ```

### **Opção 2: Modo Dinâmico (Strategy)**

```gdscript
# Em main_game.tscn
var phase_manager = PhaseManager.new()
phase_manager.use_dynamic_waves = true
phase_manager.wave_strategy = ProgressiveWaveStrategy.new()
add_child(phase_manager)

# Criar uma PhaseConfig mínima (apenas para estrutura)
var phase = PhaseConfig.new()
phase.phase_number = 1
phase.phase_name = "Endless Mode"
phase.loop_waves = true
phase_manager.phases = [phase]

phase_manager.start()
```

### **Opção 3: Híbrido**

```gdscript
# Fases 1-3: Pré-configuradas (.tres files)
# Fases 4+: Geradas dinamicamente

# No PhaseManager:
if current_phase_index >= 3:
    use_dynamic_waves = true
    wave_strategy = EliteWaveStrategy.new()
```

---

## 📊 Exemplo Completo

### **Criar Fase 1 - Iniciante:**

```gdscript
# 1. Criar grupo de inimigos básicos
var basic_group = EnemySpawnGroup.new()
basic_group.enemy_type = "Basic"
basic_group.count = 5
basic_group.movement_pattern = 0  # Straight down
basic_group.can_shoot = false

# 2. Criar Wave 1
var wave1 = WaveConfig.new()
wave1.wave_number = 1
wave1.wave_name = "Tutorial Wave"
wave1.difficulty = "Easy"
wave1.enemy_groups = [basic_group]
wave1.max_duration = 30.0
wave1.powerup_chance = 0.2
wave1.completion_bonus = 500

# 3. Criar mais waves...
var wave2 = WaveConfig.new()
# ...

# 4. Criar Phase 1
var phase1 = PhaseConfig.new()
phase1.phase_number = 1
phase1.phase_name = "Invasion Begins"
phase1.description = "The alien fleet has arrived..."
phase1.background_theme = "Space"
phase1.waves = [wave1, wave2, wave3]
phase1.has_boss = false
phase1.phase_completion_bonus = 2000

# 5. Salvar como .tres
ResourceSaver.save(phase1, "res://examples/space_shooter/data/phases/phase_1.tres")
```

---

## 🎨 Benefícios do Sistema

### **1. Escalabilidade:**
- ✅ Adicionar fase = criar 1 arquivo .tres
- ✅ Não precisa modificar código
- ✅ Infinitas combinações possíveis

### **2. Flexibilidade:**
- ✅ Modo pré-configurado (designer-friendly)
- ✅ Modo dinâmico (procedural)
- ✅ Modo híbrido (melhor dos dois)

### **3. Manutenibilidade:**
- ✅ Configuração separada de lógica
- ✅ Balanceamento via Inspector
- ✅ Fácil testar waves específicas

### **4. Reutilização:**
- ✅ Mesmos grupos em múltiplas waves
- ✅ Strategies reutilizáveis
- ✅ Fases modulares

---

## 🧪 Testing

### **Testar Wave Específica:**
```gdscript
# Em main_game.gd
func _ready():
    var test_wave = load("res://examples/space_shooter/data/waves/wave_5.tres")
    wave_manager.start_wave_from_config(test_wave)
```

### **Testar Strategy:**
```gdscript
var strategy = SwarmWaveStrategy.new()
var wave = strategy.generate_wave(10, 1.5)  # Wave 10, difficulty 1.5x
print("Wave has %d enemies" % wave.total_enemy_count)
wave_manager.start_wave_from_config(wave)
```

### **Testar Fase Completa:**
```gdscript
var phase = load("res://examples/space_shooter/data/phases/phase_2.tres")
phase_manager.phases = [phase]
phase_manager.start()
```

---

## 🔮 Próximos Passos

### **Funcionalidades Futuras:**

1. **Boss Patterns:**
   - BossConfig resource
   - Padrões de ataque específicos
   - Múltiplas fases do boss

2. **Eventos Especiais:**
   - Meteor shower
   - Ally reinforcements
   - Power-up rain

3. **Difficulty Scaling:**
   - Player performance tracking
   - Adaptive difficulty
   - Dificuldade por skill

4. **Save System:**
   - Salvar progresso de fase
   - Unlock system
   - Leaderboards

---

## 📚 Referências

**Design Patterns Utilizados:**
- Strategy Pattern: Gang of Four
- Factory Pattern: Gang of Four
- Observer Pattern: Signals (Godot built-in)
- Data-Driven Design: Game Programming Patterns

**Godot Resources:**
- https://docs.godotengine.org/en/stable/classes/class_resource.html
- https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html

---

## ✅ Checklist de Implementação

- [x] EnemySpawnGroup Resource
- [x] WaveConfig Resource
- [x] PhaseConfig Resource
- [x] WaveStrategy base class
- [x] ProgressiveWaveStrategy
- [x] SwarmWaveStrategy
- [x] EliteWaveStrategy
- [x] PhaseManager
- [x] WaveManager integration (start_wave_from_config)
- [ ] Exemplo .tres files
- [ ] Boss system
- [ ] HUD integration (phase/wave display)
- [ ] Power-up system integration
- [ ] Save/Load system

---

**Sistema criado com ❤️ usando Godot 4.x e MilitiaForge2D**
