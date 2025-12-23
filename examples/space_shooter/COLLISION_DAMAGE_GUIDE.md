# Collision Damage System Guide

## O Que Foi Implementado

Agora quando o jogador colide com inimigos, **ambos tomam dano**! Isso adiciona uma camada estratégica ao jogo:

### Mecânica de Colisão

**Quando Player colide com Enemy:**
- ✅ **Player toma dano**: Baseado no `damage_to_player` do inimigo (geralmente 20)
- ✅ **Enemy toma dano**: Player causa 30 de dano ao inimigo
- ✅ **Knockback**: Ambos são empurrados para trás (300 força player, 200 força enemy)
- ✅ **Cooldown**: 0.5s de invencibilidade após colisão (previne spam)
- ✅ **Visual Feedback**: Flash vermelho no sprite ao tomar dano

## Estratégias de Gameplay

### 1. **Ramming (Aríete)**
- **Quando usar**: Contra inimigos fracos (Basic: 20 HP)
- **Cálculo**: Player causa 30 dano → mata Basic em 1 colisão
- **Custo**: Perde 20 HP
- **Vantagem**: Elimina inimigo rapidamente sem gastar munição

### 2. **Evasão**
- **Quando usar**: Com pouca vida ou contra inimigos fortes (Tank: 50+ HP)
- **Cálculo**: Tank tem 50 HP → precisa de 2 colisões (toma 40 dano total)
- **Risco**: Não compensa o dano recebido

### 3. **Controle de Espaço**
- **Knockback**: Use colisão estratégica para empurrar inimigos para fora de formações
- **Separação**: Knockback cria espaço para fugir quando cercado

## Configuração do Sistema

### Player (player_controller.gd:152-162)

```gdscript
var collision_damage = CollisionDamageComponent.new()
collision_damage.damage_on_collision = 30          # Dano ao inimigo
collision_damage.can_take_collision_damage = true  # Pode receber dano
collision_damage.incoming_damage_multiplier = 1.0  # 100% do dano
collision_damage.apply_knockback = true
collision_damage.knockback_force = 300.0           # Knockback forte
collision_damage.collision_cooldown = 0.5          # Match invencibilidade
```

### Enemy (enemy_base.gd:181-191)

```gdscript
var collision_damage = CollisionDamageComponent.new()
collision_damage.damage_on_collision = damage_to_player  # 20 normalmente
collision_damage.can_take_collision_damage = true
collision_damage.incoming_damage_multiplier = 1.0
collision_damage.apply_knockback = true
collision_damage.knockback_force = 200.0                 # Knockback menor
collision_damage.collision_cooldown = 0.5
```

## Matemática da Colisão

### Exemplo: Player (100 HP) vs Basic Enemy (20 HP)

**Cenário 1: Colisão**
```
Player HP: 100 → 80 (-20)
Enemy HP: 20 → -10 (morreu)
Resultado: Player venceu, perdeu 20 HP
```

**Cenário 2: Projectile (10 dano)**
```
Player HP: 100 (sem dano)
Enemy HP: 20 → 10 → 0 (2 tiros)
Resultado: Player venceu, sem dano
```

**Conclusão**: Projectiles são mais seguros, mas colisão é mais rápida.

### Exemplo: Player (100 HP) vs Tank Enemy (50 HP)

**Cenário 1: 2 Colisões**
```
Colisão 1:
  Player HP: 100 → 80 (-20)
  Tank HP: 50 → 20 (-30)

Colisão 2:
  Player HP: 80 → 60 (-20)
  Tank HP: 20 → -10 (morreu)

Resultado: Player venceu, perdeu 40 HP (40% da vida!)
```

**Cenário 2: Projectiles (10 dano)**
```
5 tiros = 50 dano
Player HP: 100 (sem dano)
Tank HP: 50 → 0
Resultado: Player venceu, sem dano
```

**Conclusão**: Nunca faça ram em Tanks! Use projectiles.

## Arquitetura (SOLID Principles)

### Component Design

O `CollisionDamageComponent` segue os princípios SOLID:

**Single Responsibility**: Apenas gerencia dano por colisão
```gdscript
class_name CollisionDamageComponent extends Component
```

**Open/Closed**: Extensível via herança, fechado para modificação
```gdscript
@export var damage_on_collision: int = 20
@export var can_take_collision_damage: bool = true
```

**Dependency Inversion**: Depende de abstrações (ComponentHost, HealthComponent)
```gdscript
var _health_component: Node = null
_health_component = component_host.get_component("HealthComponent")
```

### Sistema de Detecção

**Física do Godot**:
```gdscript
func _check_collisions() -> void:
    var collision_count = _physics_body.get_slide_collision_count()
    for i in range(collision_count):
        var collision = _physics_body.get_slide_collision(i)
        _process_collision(collision.get_collider(), collision)
```

**Prevenção de Spam**:
```gdscript
var _last_collision_targets: Array[Node] = []
var _collision_timer: float = 0.0

# Só aplica dano se não estiver em cooldown
if _last_collision_targets.has(collider_entity) and _collision_timer > 0:
    return
```

**Knockback Physics**:
```gdscript
var normal = collision.get_normal()  # Direção oposta à colisão
var knockback_velocity = normal * knockback_force
_physics_body.velocity += knockback_velocity
```

## Signals (Observer Pattern)

O componente emite signals para outros sistemas reagirem:

```gdscript
signal collision_damage_dealt(target: Node, damage: int)
signal collision_damage_taken(source: Node, damage: int)
signal body_collided(other_body: Node)
```

**Exemplo de Uso**:
```gdscript
# Na HUD
player_collision_damage.collision_damage_taken.connect(_on_collision_hit)

func _on_collision_hit(source: Node, damage: int):
    _screen_shake()
    _play_impact_sound()
```

## Customização

### Mudar Dano de Colisão

**Player mais forte contra colisões**:
```gdscript
collision_damage.damage_on_collision = 50  # Mata Basic em 1 hit
```

**Player mais frágil**:
```gdscript
collision_damage.incoming_damage_multiplier = 1.5  # Toma 50% mais dano
```

### Remover Knockback

```gdscript
collision_damage.apply_knockback = false
```

### Aumentar Cooldown

```gdscript
collision_damage.collision_cooldown = 1.0  # 1 segundo entre colisões
```

### Tornar Inimigo Invulnerável a Colisões

```gdscript
collision_damage.can_take_collision_damage = false  # Só causa dano, não recebe
```

## Balanceamento Sugerido

### Tipos de Enemy

**Basic** (20 HP):
- Dano colisão: 10 (baixo)
- Jogador pode fazer ram sem muito risco

**Fast** (10 HP):
- Dano colisão: 15 (médio)
- Morre fácil, mas machuca

**Tank** (50 HP):
- Dano colisão: 30 (alto!)
- Nunca faça ram, use projectiles

### Wave Balancing

**Wave 1-2**: Muitos Basic → Ram é viável
**Wave 3-4**: Mix de Fast/Tank → Ram seletivo
**Wave 5**: Mostly Tank → Evitar ram totalmente

## Debug

Para ver colisões no console:

```
[CollisionDamageComponent] Dealt 30 collision damage to Enemy
[CollisionDamageComponent] Took 20 collision damage from Enemy
[CollisionDamageComponent] Applied knockback: (150, -50)
```

## Próximos Passos

Possíveis melhorias futuras:

- [ ] **Efeitos visuais**: Partículas na colisão
- [ ] **Som**: Impact sound effect
- [ ] **Combo system**: Múltiplas colisões em sequência
- [ ] **Power-up**: "Ram Shield" que aumenta dano de colisão
- [ ] **Achievements**: "Ramming Speed" - matar 10 inimigos por colisão

## Arquivo Criado

- ✅ `militia_forge/components/collision_damage_component.gd` - Componente genérico reutilizável
- ✅ Integrado em `player_controller.gd` (linha 152-162)
- ✅ Integrado em `enemy_base.gd` (linha 181-191)
