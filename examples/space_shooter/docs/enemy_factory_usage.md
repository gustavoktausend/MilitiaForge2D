# Enemy Factory - Guia de Uso 🏭

O `EnemyFactory` é um padrão de design Factory para criar instâncias de inimigos de forma centralizada e configurável.

## Benefícios

- ✅ **Centralizado**: Um único local para gerenciar criação de inimigos
- ✅ **Extensível**: Fácil adicionar novos tipos de inimigos
- ✅ **Configurável**: Sobrescrever propriedades na criação
- ✅ **Performance**: Cache de cenas para melhor desempenho
- ✅ **Type-safe**: Validação de tipos registrados

---

## Uso Básico

### 1. Criar inimigo por tipo

```gdscript
# Criar um inimigo Basic com configuração padrão
var enemy = EnemyFactory.create_enemy("Basic")

# Criar com configuração customizada
var config = {
    "health": 50,
    "speed": 150.0,
    "score_value": 200
}
var custom_enemy = EnemyFactory.create_enemy("Tank", config)
```

### 2. Usar métodos de conveniência

```gdscript
# Criar Basic com vida customizada
var tough_basic = EnemyFactory.create_basic(40)

# Criar Fast com velocidade customizada
var super_fast = EnemyFactory.create_fast(300.0)

# Criar Tank com fire rate customizado
var rapid_tank = EnemyFactory.create_tank(0.5)
```

### 3. Criar a partir de dados de wave

```gdscript
var wave_data = {
    "type": "Tank",
    "health": 60,
    "speed": 90.0,
    "score": 350
}
var enemy = EnemyFactory.create_from_wave_data(wave_data)
```

---

## Registrar Novos Tipos

### Registrar um novo tipo de inimigo

```gdscript
# Registrar novo tipo "Elite"
EnemyFactory.register_enemy_type(
    "Elite",
    "res://enemies/enemy_elite.tscn"
)

# Agora pode criar
var elite = EnemyFactory.create_enemy("Elite")
```

### Verificar se tipo existe

```gdscript
if EnemyFactory.has_enemy_type("Boss"):
    var boss = EnemyFactory.create_enemy("Boss")
else:
    print("Boss type not registered!")
```

### Listar tipos disponíveis

```gdscript
var types = EnemyFactory.get_registered_types()
print("Available enemy types: ", types)
# Output: ["Basic", "Fast", "Tank"]
```

---

## Tipos Pré-Registrados

| Tipo | Cena | Características |
|------|------|----------------|
| **Basic** | `enemy_basic.tscn` | Inimigo básico que desce direto |
| **Fast** | `enemy_fast.tscn` | Inimigo rápido com movimento zigzag |
| **Tank** | `enemy_tank.tscn` | Inimigo resistente que para e atira |

---

## Propriedades Configuráveis

Todas as propriedades exportadas do `enemy_base.gd` podem ser sobrescritas:

```gdscript
var config = {
    # Stats
    "health": 30,
    "speed": 120.0,
    "score_value": 150,
    "damage_to_player": 25,

    # Behavior
    "movement_pattern": 2,  # 0=Straight, 1=Zigzag, 2=Circular, etc.
    "can_shoot": true,
    "fire_rate": 2.0,
    "projectile_damage": 15
}

var enemy = EnemyFactory.create_enemy("Basic", config)
```

---

## Cache de Cenas

O factory automaticamente faz cache das cenas carregadas para melhor performance:

```gdscript
# Primeira vez: carrega do disco
var enemy1 = EnemyFactory.create_enemy("Basic")

# Segunda vez: usa cache (muito mais rápido!)
var enemy2 = EnemyFactory.create_enemy("Basic")

# Limpar cache (útil para hot-reload durante desenvolvimento)
EnemyFactory.clear_cache()
```

---

## Exemplo Completo: Wave Manager

```gdscript
func _spawn_enemy(enemy_data: Dictionary) -> void:
    # Criar inimigo usando factory
    var enemy = EnemyFactory.create_from_wave_data(enemy_data)

    if not enemy:
        push_error("Failed to create enemy!")
        return

    # Configurar posição
    enemy.global_position = _get_spawn_position()

    # Conectar sinais
    enemy.enemy_died.connect(_on_enemy_died)

    # Adicionar à cena
    add_child(enemy)
```

---

## Exemplo Completo: Boss Customizado

```gdscript
# Registrar boss
EnemyFactory.register_enemy_type(
    "MegaBoss",
    "res://bosses/mega_boss.tscn"
)

# Criar boss com configuração especial
var boss_config = {
    "health": 1000,
    "speed": 50.0,
    "score_value": 5000,
    "can_shoot": true,
    "fire_rate": 0.3,  # Muito rápido!
    "movement_pattern": 4,  # Pattern especial
}

var boss = EnemyFactory.create_enemy("MegaBoss", boss_config)
boss.global_position = Vector2(640, 100)
add_child(boss)
```

---

## Dicas e Melhores Práticas

### ✅ DO

- Use o factory para **toda** criação de inimigos
- Registre novos tipos no `_ready()` do GameController
- Use `create_from_wave_data()` para waves
- Cache seja limpo apenas durante desenvolvimento

### ❌ DON'T

- Não instancie cenas diretamente com `load().instantiate()`
- Não bypass o factory para "casos especiais"
- Não registre tipos múltiplas vezes sem necessidade

---

## Troubleshooting

### Erro: "Unknown enemy type"

```gdscript
# Problema
var enemy = EnemyFactory.create_enemy("SuperEnemy")
# [ERROR] Unknown enemy type: SuperEnemy

# Solução: Registrar o tipo primeiro
EnemyFactory.register_enemy_type(
    "SuperEnemy",
    "res://enemies/super_enemy.tscn"
)
```

### Erro: "Failed to load scene"

```gdscript
# Problema: Caminho da cena incorreto
EnemyFactory.register_enemy_type("Boss", "res://wrong/path.tscn")

# Solução: Verificar o caminho
EnemyFactory.register_enemy_type("Boss", "res://bosses/boss.tscn")
```

---

## Próximos Passos

1. Adicionar variantes de inimigos (Basic Red, Basic Blue, etc.)
2. Implementar enemy pools para reuso
3. Adicionar validação de configuração
4. Criar editor visual para enemy configuration
