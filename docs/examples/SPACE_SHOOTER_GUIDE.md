# Space Shooter - Guia de Implementação com MilitiaForge2D

**Status**: ✅ Complete
**Versão**: 1.0.0
**Última Atualização**: 2024-12-28

## 📋 Índice

1. [Visão Geral](#-visão-geral)
2. [Arquitetura do Space Shooter](#-arquitetura-do-space-shooter)
3. [Componentes Utilizados](#-componentes-utilizados)
4. [Implementação do Player](#-implementação-do-player)
5. [Implementação dos Inimigos](#-implementação-dos-inimigos)
6. [Sistema de Armas](#-sistema-de-armas)
7. [Game Controller](#-game-controller)
8. [Padrões de Design](#-padrões-de-design)
9. [Como Criar Seu Próprio Jogo](#-como-criar-seu-próprio-jogo)

---

## 🎮 Visão Geral

O **Space Shooter** é um exemplo completo de jogo criado com o framework **MilitiaForge2D**. Ele demonstra como utilizar o sistema de componentes para criar um jogo funcional de tiro vertical (shoot 'em up).

### Características Principais

- ✅ **Arquitetura baseada em componentes** - Totalmente modular e reutilizável
- ✅ **Sistema de armas múltiplas** - Primária, secundária e especial
- ✅ **Sistema de pilotos** - Modificadores de stats e habilidades
- ✅ **Gerenciamento de ondas** - Sistema progressivo de dificuldade
- ✅ **Object pooling** - Otimização para projéteis
- ✅ **Padrões de design** - Factory, Observer, Dependency Injection

### Localização

```
examples/space_shooter/
├── scenes/          # Cenas do Godot
├── scripts/         # Scripts de gameplay
├── ui/              # Interface do usuário
├── assets/          # Sprites, sons, etc.
└── docs/            # Documentação específica
```

---

## 🏗️ Arquitetura do Space Shooter

O Space Shooter segue a arquitetura de componentes do MilitiaForge2D, onde cada entidade (player, inimigos) é composta por múltiplos componentes que trabalham juntos.

### Fluxo de Execução

```
Main Menu
    ↓
Game Scene
    ├─ GameController (coordena o jogo)
    ├─ Player (ComponentHost + componentes)
    ├─ WaveManager (gerencia ondas de inimigos)
    ├─ EnemyFactory (cria inimigos)
    └─ HUD (interface)
```

### Estrutura de Entidades

Tanto o player quanto os inimigos seguem a mesma estrutura:

```
Node2D (raiz)
  └─ CharacterBody2D (física)
      ├─ ComponentHost (gerencia componentes)
      │   ├─ HealthComponent
      │   ├─ BoundedMovement
      │   ├─ InputComponent (só player)
      │   ├─ WeaponSlotManager
      │   ├─ ScoreComponent
      │   ├─ CollisionDamageComponent
      │   └─ ParticleEffectComponent
      ├─ Hurtbox (recebe dano)
      ├─ Hitbox (causa dano)
      ├─ Sprite2D (visual)
      └─ CollisionShape2D (colisão física)
```

---

## 🧩 Componentes Utilizados

O Space Shooter utiliza diversos componentes do MilitiaForge2D. Aqui está uma visão detalhada:

### ComponentHost

**Arquivo**: `militia_forge/core/component_host.gd`

O ComponentHost é o núcleo do sistema. Ele gerencia todos os componentes anexados a uma entidade.

```gdscript
# Exemplo de uso no player_controller.gd
host = ComponentHost.new()
host.name = "PlayerHost"
add_child(host)

# Adicionar componentes
host.add_component(movement)
host.add_component(health)
host.add_component(weapon_manager)
```

**Responsabilidades**:
- Inicializa componentes na ordem correta
- Roteia chamadas de lifecycle (_process, _physics_process)
- Fornece lookup de componentes
- Coordena cleanup quando a entidade é destruída

---

### HealthComponent

**Arquivo**: `militia_forge/components/health/health_component.gd`

Gerencia a vida da entidade, dano, cura e morte.

**Exemplo no Player** (`player_controller.gd:229-253`):

```gdscript
health = HealthComponent.new()
health.max_health = max_health  # Modificado por ship_config e pilot_data
health.invincibility_enabled = true
health.invincibility_duration = 0.5 * pilot_data.invincibility_duration_modifier
health.debug_health = true
host.add_component(health)

# Conectar sinais
health.damage_taken.connect(_on_damage_taken)
health.died.connect(_on_player_died)
health.health_changed.connect(_on_health_changed)
```

**Funcionalidades**:
- Vida máxima e atual
- Sistema de invencibilidade (i-frames)
- Regeneração de vida
- Sinais para dano, cura e morte
- Integração com Hurtbox

**Exemplo no Enemy** (`enemy_base.gd:134-141`):

```gdscript
health_component = HealthComponent.new()
health_component.max_health = health
health_component.can_die = true
health_component.debug_health = true
host.add_component(health_component)

# Conectar sinais
health_component.died.connect(_on_enemy_died)
health_component.damage_taken.connect(_on_damage_taken)
```

---

### BoundedMovement

**Arquivo**: `militia_forge/components/movement/bounded_movement.gd`

Extensão do MovementComponent que adiciona limites de movimento e diferentes comportamentos ao alcançar bordas.

**Exemplo no Player** (`player_controller.gd:207-226`):

```gdscript
movement = BoundedMovement.new()
movement.max_speed = move_speed  # Modificado por ship_config e pilot_data
movement.acceleration = 1500.0
movement.friction = 1200.0
movement.boundary_mode = BoundedMovement.BoundaryMode.CLAMP  # Player não sai da tela
movement.use_viewport_bounds = false

# Define limites customizados para área de jogo
var play_area_bounds = Rect2(
    Vector2(SpaceShooterConstants.PLAY_AREA_LEFT, 0),
    Vector2(SpaceShooterConstants.PLAY_AREA_WIDTH, viewport_size.y)
)
movement.set_custom_bounds(play_area_bounds)
movement.boundary_margin = Vector2(16, 16)
host.add_component(movement)

# Uso durante o jogo
func _handle_movement() -> void:
    var direction = Vector2.ZERO
    if input_component.is_action_pressed("move_up"):
        direction.y -= 1
    # ... outras direções
    movement.set_direction(direction)
```

**Modos de Boundary**:
- `CLAMP`: Limita a posição (usado no player)
- `DESTROY`: Destroi ao sair (usado nos inimigos)
- `WRAP`: Teleporta para o outro lado

**Exemplo no Enemy** (`enemy_base.gd:217-238`):

```gdscript
movement_component = BoundedMovement.new()
movement_component.max_speed = speed
movement_component.acceleration = 500.0
movement_component.boundary_mode = BoundedMovement.BoundaryMode.DESTROY  # Inimigo é destruído ao sair
movement_component.use_viewport_bounds = false

# Define área de jogo
var play_area_bounds = Rect2(
    Vector2(480, -100),  # Permite spawn acima da tela
    Vector2(960, viewport_size.y + 200)
)
movement_component.set_custom_bounds(play_area_bounds)

# Conectar sinal de destruição
movement_component.destroyed_by_boundary.connect(_on_destroyed_by_boundary)
host.add_component(movement_component)
```

---

### InputComponent

**Arquivo**: `militia_forge/components/input/input_component.gd`

Sistema de input baseado em ações, com suporte a buffering e rebinding.

**Exemplo no Player** (`player_controller.gd:293-362`):

```gdscript
input_component = InputComponent.new()
input_component.debug_input = true
_setup_input_actions()
host.add_component(input_component)

func _setup_input_actions() -> void:
    # Movimento
    input_component.add_action("move_up", [KEY_W, KEY_UP])
    input_component.add_action("move_down", [KEY_S, KEY_DOWN])
    input_component.add_action("move_left", [KEY_A, KEY_LEFT])
    input_component.add_action("move_right", [KEY_D, KEY_RIGHT])

    # Armas
    input_component.add_action("fire", [KEY_SPACE])
    input_component.add_action("fire_special", [KEY_ALT])
    input_component.add_action("toggle_secondary", [KEY_Z])

# Verificar inputs durante o jogo
func _handle_shooting() -> void:
    if input_component.is_action_pressed("fire"):
        weapon_manager.fire_primary_and_secondary()

    if input_component.is_action_just_pressed("fire_special"):
        weapon_manager.fire_special()
```

**Funcionalidades**:
- Mapeamento de ações para teclas
- `is_action_pressed()`, `is_action_just_pressed()`, `is_action_just_released()`
- Input buffering (captura inputs antes do frame estar pronto)
- Suporte a rebinding dinâmico
- Contextos de input (pausar/despausar)

---

### WeaponSlotManager

**Arquivo**: `militia_forge/components/combat/weapon_slot_manager.gd`

Gerencia múltiplas armas em slots diferentes (PRIMARY, SECONDARY, SPECIAL).

**Exemplo no Player** (`player_controller.gd:299-331`):

```gdscript
weapon_manager = WeaponSlotManager.new()
weapon_manager.debug_slots = true
weapon_manager.auto_handle_input = false  # Input manual via InputComponent

# Configurar ações de input
weapon_manager.primary_secondary_action = "fire"
weapon_manager.special_action = "fire_special"

# Carregar armas do WeaponDatabase (Factory Pattern)
_load_weapons_from_database()

host.add_component(weapon_manager)

# Disparar armas
func _handle_shooting() -> void:
    if input_component.is_action_pressed("fire"):
        weapon_manager.fire_primary_and_secondary()  # Dispara PRIMARY + SECONDARY juntas

    if input_component.is_action_just_pressed("fire_special"):
        weapon_manager.fire_special()  # Dispara SPECIAL

# Alternar SECONDARY on/off
func _handle_weapon_toggle() -> void:
    if input_component.is_action_just_pressed("toggle_secondary"):
        var enabled = weapon_manager.toggle_secondary_weapon()
        print("SECONDARY weapon: %s" % ("ON" if enabled else "OFF"))
```

**Carregando Armas** (`player_controller.gd:608-667`):

```gdscript
func _load_weapons_from_database() -> void:
    # PRIMARY weapon (sempre necessária)
    if not primary_weapon_name.is_empty():
        var primary = WeaponDatabase.get_primary_weapon(primary_weapon_name)
        if primary:
            # Sobrescrever com stats da nave
            if ship_config:
                primary.damage = projectile_damage
                primary.fire_rate = fire_rate
                primary.projectile_speed = projectile_speed

            # Aplicar modificadores do piloto
            _apply_pilot_weapon_modifiers(primary, WeaponData.Category.PRIMARY)
            weapon_manager.primary_weapon = primary

    # SECONDARY weapon (opcional)
    if not secondary_weapon_name.is_empty():
        var secondary = WeaponDatabase.get_secondary_weapon(secondary_weapon_name)
        if secondary:
            _apply_pilot_weapon_modifiers(secondary, WeaponData.Category.SECONDARY)
            weapon_manager.secondary_weapon = secondary

    # SPECIAL weapon (opcional)
    if not special_weapon_name.is_empty():
        var special = WeaponDatabase.get_special_weapon(special_weapon_name)
        if special:
            _apply_pilot_weapon_modifiers(special, WeaponData.Category.SPECIAL)
            weapon_manager.special_weapon = special
```

**Funcionalidades**:
- Gerencia 3 slots: PRIMARY, SECONDARY, SPECIAL
- PRIMARY sempre dispara quando chamado
- SECONDARY pode ser ativada/desativada
- SPECIAL usa munição limitada
- Sistema de ammo por slot
- Sinais para eventos (weapon_empty, secondary_toggled)

---

### CollisionDamageComponent

**Arquivo**: `militia_forge/components/collision_damage_component.gd`

Gerencia dano causado e recebido por colisões físicas (CharacterBody2D).

**Exemplo no Player** (`player_controller.gd:282-291`):

```gdscript
var collision_damage = CollisionDamageComponent.new()
collision_damage.damage_on_collision = 30  # Player causa 30 de dano ao colidir
collision_damage.can_take_collision_damage = true  # Player recebe dano de colisões
collision_damage.incoming_damage_multiplier = 1.0  # Dano completo
collision_damage.apply_knockback = true
collision_damage.knockback_force = 300.0
collision_damage.collision_cooldown = 0.5  # Cooldown entre colisões
host.add_component(collision_damage)
```

**Exemplo no Enemy** (`enemy_base.gd:205-214`):

```gdscript
var collision_damage = CollisionDamageComponent.new()
collision_damage.damage_on_collision = damage_to_player  # Inimigo causa dano configurável
collision_damage.can_take_collision_damage = true
collision_damage.incoming_damage_multiplier = 1.0
collision_damage.apply_knockback = true
collision_damage.knockback_force = 200.0
collision_damage.collision_cooldown = 0.5
host.add_component(collision_damage)
```

**Funcionalidades**:
- Dano automático em colisões físicas
- Knockback configurável
- Cooldown entre colisões
- Multiplicadores de dano
- Integração com HealthComponent

---

### Hurtbox e Hitbox

**Arquivos**:
- `militia_forge/components/health/hurtbox.gd`
- `militia_forge/components/health/hitbox.gd`

**Hurtbox**: Area2D que recebe dano
**Hitbox**: Area2D que causa dano

**Exemplo de Hurtbox no Player** (`player_controller.gd:188-279`):

```gdscript
# Criar Hurtbox
var hurtbox = Hurtbox.new()
hurtbox.name = "Hurtbox"
hurtbox.active = false  # Desabilitado durante setup
hurtbox.debug_hurtbox = true

# Adicionar collision shape
var collision = CollisionShape2D.new()
var shape = RectangleShape2D.new()
shape.size = Vector2(48, 72)
collision.shape = shape
hurtbox.add_child(collision)
physics_body.add_child(hurtbox)

# Aguardar HealthComponent ficar pronto
await get_tree().process_frame

# Configurar referências manualmente (workaround)
hurtbox.set("_health_component", health)
hurtbox.set("_component_host", host)

# Configurar layers de colisão
hurtbox.collision_layer = 1  # Player layer
hurtbox.collision_mask = 10  # Layer 2 (enemies) + Layer 8 (enemy projectiles)

# Ativar
hurtbox.active = true
hurtbox.monitoring = true
hurtbox.monitorable = true
hurtbox.hit_flash_enabled = true  # Feedback visual
hurtbox.hit_flash_duration = 0.2
```

**Exemplo de Hitbox no Enemy** (`enemy_base.gd:281-295`):

```gdscript
# Hitbox que causa dano ao player
var hitbox = Hitbox.new()
hitbox.name = "Hitbox"
hitbox.damage = damage_to_player
hitbox.hit_once_per_target = true

var hitbox_collision = CollisionShape2D.new()
var hitbox_shape = RectangleShape2D.new()
if enemy_type == "Tank":
    hitbox_shape.size = Vector2(56, 56)
else:
    hitbox_shape.size = Vector2(28, 28)
hitbox_collision.shape = hitbox_shape
hitbox.add_child(hitbox_collision)
physics_body.add_child(hitbox)
```

**Sistema de Layers de Colisão**:

```
Layer 1 (bit 0): Player
Layer 2 (bit 1): Enemies
Layer 4 (bit 2): Player Projectiles
Layer 8 (bit 3): Enemy Projectiles

Player Hurtbox:
  collision_layer = 1 (está na layer 1)
  collision_mask = 10 (detecta layer 2 + layer 8)

Enemy Hurtbox:
  collision_layer = 2 (está na layer 2)
  collision_mask = 4 (detecta layer 4 - player projectiles)
```

---

### ScoreComponent

**Arquivo**: `militia_forge/components/progression/score_component.gd`

Gerencia pontuação com sistema de combos.

**Exemplo no Player** (`player_controller.gd:328-331`):

```gdscript
score = ScoreComponent.new()
score.enable_combos = true
score.combo_decay_time = 2.0
host.add_component(score)

# Adicionar pontos (chamado quando inimigo morre)
func add_score(points: int) -> void:
    if score:
        score.add_score(points)
```

---

### PilotAbilitySystem

**Arquivo**: `militia_forge/components/pilot_ability_system.gd`

Sistema de habilidades especiais dos pilotos.

**Exemplo no Player** (`player_controller.gd:337-346`):

```gdscript
if pilot_data:
    pilot_abilities = PilotAbilitySystem.new()
    pilot_abilities.pilot_data = pilot_data
    pilot_abilities.debug_abilities = true
    host.add_component(pilot_abilities)
```

---

## 🚀 Implementação do Player

O player é implementado em `player_controller.gd` e demonstra o uso completo do sistema de componentes.

### Estrutura do Player

```gdscript
extends Node2D

# Sinais (Observer Pattern)
signal player_ready(player_node: Node2D)
signal powerup_collected(powerup_type: String, value)

# Configuração (Strategy Pattern via ShipConfig e PilotData)
@export var ship_config: ShipConfig
var pilot_data: PilotData

# Referências de componentes
var host: ComponentHost
var movement: BoundedMovement
var health: HealthComponent
var weapon_manager: WeaponSlotManager
var input_component: InputComponent
var score: ScoreComponent
var physics_body: CharacterBody2D
```

### Fluxo de Inicialização

```gdscript
func _ready() -> void:
    # 1. Carregar configurações (PlayerData singleton)
    _load_ship_and_pilot_config()

    # 2. Aplicar configurações
    _apply_ship_config()
    _apply_pilot_modifiers()

    # 3. Setup de componentes
    await _setup_components()

    # 4. Setup visual
    _setup_visuals()

    # 5. Conectar sinais
    _connect_signals()
```

### Aplicando Modificadores de Piloto

O sistema de pilotos permite modificar as características da nave:

```gdscript
func _apply_pilot_modifiers() -> void:
    if not pilot_data:
        return

    # Modificar stats base
    max_health = int(max_health * pilot_data.health_modifier)
    move_speed = move_speed * pilot_data.speed_modifier

    # Modificadores de arma são aplicados em _load_weapons_from_database()
```

### Modificadores de Arma por Piloto

```gdscript
func _apply_pilot_weapon_modifiers(weapon: WeaponData, category: int) -> void:
    if not pilot_data:
        return

    # Obter modificadores (global * específico da categoria)
    var damage_mod = pilot_data.get_damage_modifier_for_category(category)
    var fire_rate_mod = pilot_data.get_fire_rate_modifier_for_category(category)

    # Aplicar
    weapon.damage = int(weapon.damage * damage_mod)
    weapon.fire_rate = weapon.fire_rate / fire_rate_mod  # Menor = mais rápido

    # Modificadores de ammo
    match category:
        WeaponData.Category.SECONDARY:
            weapon.max_ammo = int(weapon.max_ammo * pilot_data.secondary_ammo_modifier)

        WeaponData.Category.SPECIAL:
            weapon.max_ammo += pilot_data.special_ammo_bonus
```

### Gerenciamento de Input e Movimento

```gdscript
func _process(_delta: float) -> void:
    _handle_movement()
    _handle_shooting()
    _handle_weapon_toggle()

func _handle_movement() -> void:
    var direction = Vector2.ZERO

    if input_component.is_action_pressed("move_up"):
        direction.y -= 1
    if input_component.is_action_pressed("move_down"):
        direction.y += 1
    if input_component.is_action_pressed("move_left"):
        direction.x -= 1
    if input_component.is_action_pressed("move_right"):
        direction.x += 1

    movement.set_direction(direction)
```

### Sistema de Power-ups

```gdscript
func power_up_weapon() -> void:
    if weapon_manager:
        var primary_weapon_comp = weapon_manager.get_weapon_component(WeaponData.Category.PRIMARY)
        if primary_weapon_comp:
            primary_weapon_comp.upgrade()
            weapon_upgraded.emit(primary_weapon_comp.damage, primary_weapon_comp.fire_rate)

func power_up_shield() -> void:
    if health:
        health.heal(30)
        shield_upgraded.emit(30)
```

---

## 👾 Implementação dos Inimigos

Os inimigos são implementados em `enemy_base.gd` usando a mesma arquitetura de componentes.

### Estrutura do Enemy

```gdscript
class_name SpaceEnemy extends Node2D

# Sinais
signal enemy_died(enemy: SpaceEnemy, score_value: int)

# Configuração
@export var enemy_type: String = "Basic"
@export var health: int = 20
@export var speed: float = 100.0
@export var score_value: int = 100
@export var movement_pattern: MovementPattern = MovementPattern.STRAIGHT_DOWN

# Componentes
var host: ComponentHost
var movement_component: BoundedMovement
var health_component: HealthComponent
var weapon: Node  # SimpleWeapon
var physics_body: CharacterBody2D
```

### Padrões de Movimento

O Space Shooter implementa diversos padrões de movimento:

```gdscript
enum MovementPattern {
    STRAIGHT_DOWN,    # Reto para baixo
    ZIGZAG,          # Zigue-zague
    CIRCULAR,        # Movimento circular
    SINE_WAVE,       # Onda senoidal
    TRACKING,        # Segue o player
    STOP_AND_SHOOT   # Para e atira
}

func _update_movement(_delta: float) -> void:
    var direction = Vector2.ZERO

    match movement_pattern:
        MovementPattern.STRAIGHT_DOWN:
            direction = Vector2.DOWN

        MovementPattern.ZIGZAG:
            direction = Vector2.DOWN
            # Verificar bordas e inverter
            if physics_body.global_position.x <= left_bound:
                zigzag_direction = 1.0
            elif physics_body.global_position.x >= right_bound:
                zigzag_direction = -1.0
            direction.x = zigzag_direction

        MovementPattern.TRACKING:
            if player:
                direction = (player.global_position - global_position).normalized()
                direction = direction * 0.3 + Vector2.DOWN * 0.7  # Mix com downward

        MovementPattern.STOP_AND_SHOOT:
            if not has_stopped:
                if physics_body.global_position.y < stop_position_y:
                    direction = Vector2.DOWN
                else:
                    has_stopped = true
            else:
                # Movimento lateral enquanto parado
                direction.x = sin(lateral_movement_timer * 0.3)

    movement_component.set_direction(direction.normalized())
```

### Sistema de Disparo do Inimigo

```gdscript
func _update_shooting(delta: float) -> void:
    if not can_shoot or not weapon or not player:
        return

    shoot_timer += delta

    # Ajustar fire rate baseado no padrão
    var current_fire_rate = fire_rate
    if movement_pattern == MovementPattern.STOP_AND_SHOOT and has_stopped:
        current_fire_rate = fire_rate * 0.5  # Atira mais rápido quando parado

    if shoot_timer >= current_fire_rate:
        shoot_timer = 0.0
        var shoot_position = physics_body.global_position
        var shoot_direction = (player.global_position - shoot_position).normalized()
        _fire_weapon_async(shoot_position, shoot_direction)

# Fire-and-forget pattern
func _fire_weapon_async(shoot_position: Vector2, shoot_direction: Vector2) -> void:
    await weapon.fire_at(shoot_position, shoot_direction)
```

### Dependency Injection do Player

```gdscript
# No enemy_base.gd
func set_target(target_player: Node2D) -> void:
    player = target_player

# No wave_manager.gd ao criar inimigos
var enemy_instance = enemy_factory.create_enemy(enemy_def)
if enemy_instance and player:
    enemy_instance.set_target(player)  # Injeta dependência
```

---

## 🔫 Sistema de Armas

O Space Shooter usa múltiplos sistemas de armas.

### WeaponData (Resource)

Define as características de uma arma:

```gdscript
class_name WeaponData extends Resource

enum Category { PRIMARY, SECONDARY, SPECIAL }

@export var weapon_name: String
@export var category: Category
@export var damage: int
@export var fire_rate: float
@export var projectile_speed: float
@export var projectile_scene: PackedScene
@export var max_ammo: int = -1  # -1 = infinito
@export var spread_count: int = 1
@export var spread_angle: float = 0.0
```

### WeaponDatabase (Factory Pattern)

Centraliza a criação de armas:

```gdscript
class_name WeaponDatabase

static func get_primary_weapon(weapon_name: String) -> WeaponData:
    match weapon_name:
        "basic_laser":
            return _create_basic_laser()
        "spread_shot":
            return _create_spread_shot()
        "rapid_fire":
            return _create_rapid_fire()
    return null

static func _create_basic_laser() -> WeaponData:
    var weapon = WeaponData.new()
    weapon.weapon_name = "Basic Laser"
    weapon.category = WeaponData.Category.PRIMARY
    weapon.damage = 10
    weapon.fire_rate = 0.2
    weapon.projectile_speed = 600.0
    weapon.projectile_scene = load("res://examples/space_shooter/scenes/projectile.tscn")
    weapon.max_ammo = -1  # Infinito
    return weapon
```

### ProjectileComponent

Gerencia comportamento dos projéteis:

```gdscript
class_name ProjectileComponent extends Component

enum Team { PLAYER, ENEMY }

var damage: int = 10
var speed: float = 500.0
var direction: Vector2 = Vector2.UP
var team: Team = Team.PLAYER
var pierce_count: int = 0  # Quantos inimigos pode atravessar
var homing: bool = false
var lifetime: float = 5.0

func component_process(delta: float) -> void:
    # Move o projétil
    var movement = direction * speed * delta
    get_parent().global_position += movement

    # Lifetime
    lifetime -= delta
    if lifetime <= 0:
        get_parent().queue_free()
```

### Object Pooling de Projéteis

Para otimização, o Space Shooter usa object pooling:

```gdscript
# entity_pool_manager.gd
class_name EntityPoolManager extends Node

var pools: Dictionary = {}  # { "pool_name": ObjectPool }

func get_entity(pool_name: String) -> Node:
    if not pools.has(pool_name):
        push_error("Pool '%s' not found!" % pool_name)
        return null

    return pools[pool_name].get_object()

func return_entity(pool_name: String, entity: Node) -> void:
    if pools.has(pool_name):
        pools[pool_name].return_object(entity)
```

---

## 🎮 Game Controller

O GameController coordena todo o jogo.

### Estrutura

```gdscript
extends Node

signal game_started()
signal game_over()
signal score_changed(new_score: int)

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }

var current_state: GameState = GameState.MENU
var current_score: int = 0
var high_score: int = 0

@onready var player: Node2D = null
@onready var wave_manager: Node2D = null
@onready var hud: Control = null
```

### Fluxo de Início do Jogo

```gdscript
func start_game() -> void:
    current_state = GameState.PLAYING
    current_score = 0

    game_started.emit()

    _setup_player()
    _setup_wave_manager()
    _setup_hud()

func _setup_player() -> void:
    var players = get_tree().get_nodes_in_group("player")
    if players.size() > 0:
        player = players[0]

        # Conectar sinais (Observer Pattern)
        if player.has_signal("score_changed"):
            player.score_changed.connect(_on_score_changed)
```

### Sistema de Pontuação

```gdscript
func add_score(points: int) -> void:
    current_score += points
    score_changed.emit(current_score)

    # Atualizar high score
    if current_score > high_score:
        high_score = current_score
        _save_high_score()

func _on_enemy_killed(score_value: int) -> void:
    # Observer Pattern: Reage à morte de inimigo
    add_score(score_value)
```

### Wave Manager Integration

```gdscript
func _setup_wave_manager() -> void:
    var managers = get_tree().get_nodes_in_group("wave_manager")
    if managers.size() > 0:
        wave_manager = managers[0]

    # Conectar sinais (Observer Pattern)
    wave_manager.wave_started.connect(_on_wave_started)
    wave_manager.wave_completed.connect(_on_wave_completed)
    wave_manager.enemy_killed.connect(_on_enemy_killed)

func _on_wave_completed(wave_number: int) -> void:
    # Bônus por completar wave
    add_score(500 * wave_number)
```

---

## 🎨 Padrões de Design

O Space Shooter implementa diversos padrões de design:

### 1. Component Pattern

**Onde**: Toda a arquitetura
**Por que**: Modularidade, reutilização, composição ao invés de herança

```gdscript
# Ao invés de:
class Player extends CharacterBody2D:
    var health: int
    var speed: float
    func take_damage(): ...
    func move(): ...

# Usamos:
class Player extends Node2D:
    var host: ComponentHost
    var health: HealthComponent
    var movement: MovementComponent
```

### 2. Observer Pattern (Signals)

**Onde**: Comunicação entre sistemas
**Por que**: Baixo acoplamento, sistemas independentes

```gdscript
# GameController não chama diretamente o WaveManager
# Ao invés disso, escuta sinais:

# No WaveManager
signal enemy_killed(score_value: int)

# No GameController
wave_manager.enemy_killed.connect(_on_enemy_killed)

func _on_enemy_killed(score_value: int) -> void:
    add_score(score_value)
```

### 3. Factory Pattern

**Onde**: Criação de inimigos, criação de armas
**Por que**: Centraliza lógica de criação, fácil de estender

```gdscript
# EnemyFactory
class_name SpaceShooterEnemyFactory

static func create_enemy(config: Dictionary) -> SpaceEnemy:
    var enemy_scene = _get_enemy_scene(config.type)
    var enemy = enemy_scene.instantiate()

    # Configurar baseado no config
    enemy.health = config.health
    enemy.speed = config.speed
    enemy.score_value = config.score

    return enemy

# WeaponDatabase
static func get_primary_weapon(weapon_name: String) -> WeaponData:
    match weapon_name:
        "basic_laser":
            return _create_basic_laser()
```

### 4. Dependency Injection

**Onde**: Player injetado em inimigos, containers injetados em armas
**Por que**: Testabilidade, flexibilidade, baixo acoplamento

```gdscript
# Ao invés de procurar na árvore:
func _ready():
    player = get_tree().get_nodes_in_group("player")[0]

# Usamos injeção:
func set_target(target_player: Node2D) -> void:
    player = target_player

# WaveManager injeta:
enemy.set_target(player)
```

### 5. Strategy Pattern

**Onde**: Padrões de movimento, configurações de nave/piloto
**Por que**: Comportamentos intercambiáveis

```gdscript
# Diferentes estratégias de movimento
enum MovementPattern {
    STRAIGHT_DOWN,
    ZIGZAG,
    TRACKING
}

@export var movement_pattern: MovementPattern

func _update_movement():
    match movement_pattern:
        MovementPattern.STRAIGHT_DOWN:
            # Estratégia A
        MovementPattern.ZIGZAG:
            # Estratégia B
```

### 6. Object Pool Pattern

**Onde**: Projéteis
**Por que**: Performance, evita criar/destruir objetos constantemente

```gdscript
# Ao invés de:
var projectile = projectile_scene.instantiate()
add_child(projectile)
# ... depois
projectile.queue_free()

# Usamos:
var projectile = pool_manager.get_entity("player_laser")
# ... depois
pool_manager.return_entity("player_laser", projectile)
```

### 7. Singleton Pattern

**Onde**: PlayerData, WeaponDatabase
**Por que**: Estado global, acesso fácil

```gdscript
# PlayerData como autoload
# Acesso de qualquer lugar:
var player_data = get_node("/root/PlayerData")
var selected_ship = player_data.get_selected_ship()
```

---

## 🛠️ Como Criar Seu Próprio Jogo

Aqui está um guia passo a passo para criar um jogo similar usando MilitiaForge2D.

### Passo 1: Criar o Player

```gdscript
# player.gd
extends Node2D

var host: ComponentHost
var movement: BoundedMovement
var health: HealthComponent
var input_component: InputComponent
var physics_body: CharacterBody2D

func _ready() -> void:
    await _setup_components()
    _setup_visuals()
    _connect_signals()

func _setup_components() -> void:
    # 1. Criar ComponentHost
    host = ComponentHost.new()
    host.name = "PlayerHost"
    add_child(host)

    # 2. Criar CharacterBody2D
    physics_body = CharacterBody2D.new()
    physics_body.name = "Body"
    physics_body.collision_layer = 1
    physics_body.collision_mask = 2
    host.add_child(physics_body)

    # 3. Adicionar collision shape
    var collision = CollisionShape2D.new()
    var shape = RectangleShape2D.new()
    shape.size = Vector2(48, 72)
    collision.shape = shape
    physics_body.add_child(collision)

    # 4. Adicionar componentes
    # Movement
    movement = BoundedMovement.new()
    movement.max_speed = 300.0
    movement.acceleration = 1500.0
    movement.boundary_mode = BoundedMovement.BoundaryMode.CLAMP
    host.add_component(movement)

    # Health
    health = HealthComponent.new()
    health.max_health = 100
    health.invincibility_enabled = true
    host.add_component(health)

    # Input
    input_component = InputComponent.new()
    input_component.add_action("move_up", [KEY_W, KEY_UP])
    input_component.add_action("move_down", [KEY_S, KEY_DOWN])
    input_component.add_action("move_left", [KEY_A, KEY_LEFT])
    input_component.add_action("move_right", [KEY_D, KEY_RIGHT])
    host.add_component(input_component)

    # 5. Adicionar Hurtbox
    var hurtbox = Hurtbox.new()
    hurtbox.name = "Hurtbox"
    var hurtbox_collision = CollisionShape2D.new()
    var hurtbox_shape = RectangleShape2D.new()
    hurtbox_shape.size = Vector2(48, 72)
    hurtbox_collision.shape = hurtbox_shape
    hurtbox.add_child(hurtbox_collision)
    physics_body.add_child(hurtbox)

    await get_tree().process_frame

    hurtbox.set("_health_component", health)
    hurtbox.set("_component_host", host)
    hurtbox.collision_layer = 1
    hurtbox.collision_mask = 6  # Enemies + enemy projectiles
    hurtbox.active = true
    hurtbox.monitoring = true
    hurtbox.monitorable = true

func _setup_visuals() -> void:
    var sprite = Sprite2D.new()
    sprite.texture = load("res://path/to/sprite.png")
    physics_body.add_child(sprite)

func _connect_signals() -> void:
    health.damage_taken.connect(_on_damage_taken)
    health.died.connect(_on_player_died)

func _process(_delta: float) -> void:
    _handle_movement()

func _handle_movement() -> void:
    var direction = Vector2.ZERO
    if input_component.is_action_pressed("move_up"):
        direction.y -= 1
    if input_component.is_action_pressed("move_down"):
        direction.y += 1
    if input_component.is_action_pressed("move_left"):
        direction.x -= 1
    if input_component.is_action_pressed("move_right"):
        direction.x += 1
    movement.set_direction(direction)

func _on_damage_taken(amount: int, _attacker: Node) -> void:
    print("Took %d damage! Health: %d/%d" % [amount, health.current_health, health.max_health])

func _on_player_died() -> void:
    print("Player died!")
    queue_free()
```

### Passo 2: Criar Inimigos

```gdscript
# enemy.gd
class_name Enemy extends Node2D

signal enemy_died(enemy: Enemy, score: int)

@export var health: int = 20
@export var speed: float = 100.0
@export var score_value: int = 100

var host: ComponentHost
var movement: BoundedMovement
var health_component: HealthComponent
var physics_body: CharacterBody2D

func _ready() -> void:
    await _setup_components()
    _setup_visuals()
    _connect_signals()

func _setup_components() -> void:
    # Similar ao player, mas com diferentes layers de colisão
    physics_body = CharacterBody2D.new()
    physics_body.name = "Body"
    physics_body.collision_layer = 2  # Enemy layer
    physics_body.collision_mask = 1   # Collide with player
    add_child(physics_body)

    host = ComponentHost.new()
    host.name = "EnemyHost"
    physics_body.add_child(host)

    # Movement com DESTROY mode
    movement = BoundedMovement.new()
    movement.max_speed = speed
    movement.boundary_mode = BoundedMovement.BoundaryMode.DESTROY
    movement.destroyed_by_boundary.connect(_on_destroyed_by_boundary)
    host.add_component(movement)

    # Health
    health_component = HealthComponent.new()
    health_component.max_health = health
    host.add_component(health_component)

    # Hurtbox (recebe dano de player projectiles)
    var hurtbox = Hurtbox.new()
    var collision = CollisionShape2D.new()
    var shape = RectangleShape2D.new()
    shape.size = Vector2(48, 48)
    collision.shape = shape
    hurtbox.add_child(collision)
    physics_body.add_child(hurtbox)

    await get_tree().process_frame

    hurtbox.set("_health_component", health_component)
    hurtbox.set("_component_host", host)
    hurtbox.collision_layer = 2  # Enemy layer
    hurtbox.collision_mask = 4   # Player projectiles
    hurtbox.active = true
    hurtbox.monitoring = true
    hurtbox.monitorable = true

func _setup_visuals() -> void:
    var sprite = Sprite2D.new()
    sprite.texture = load("res://path/to/enemy_sprite.png")
    physics_body.add_child(sprite)

func _connect_signals() -> void:
    health_component.died.connect(_on_enemy_died)

func _process(_delta: float) -> void:
    # Movimento simples para baixo
    movement.set_direction(Vector2.DOWN)

func _on_enemy_died() -> void:
    enemy_died.emit(self, score_value)
    queue_free()

func _on_destroyed_by_boundary(_edge) -> void:
    enemy_died.emit(self, 0)  # Sem score se sair da tela
    queue_free()
```

### Passo 3: Criar Sistema de Ondas

```gdscript
# wave_manager.gd
extends Node2D

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal enemy_killed(score: int)

var current_wave: int = 0
var enemies_remaining: int = 0

var wave_definitions: Array[Dictionary] = [
    {
        "enemies": [
            {"type": "basic", "count": 5, "health": 20, "speed": 100, "score": 100}
        ],
        "spawn_delay": 1.0
    },
    {
        "enemies": [
            {"type": "basic", "count": 10, "health": 25, "speed": 120, "score": 120}
        ],
        "spawn_delay": 0.8
    }
]

var enemy_scene: PackedScene = preload("res://path/to/enemy.tscn")

func _ready() -> void:
    await get_tree().create_timer(2.0).timeout
    start_next_wave()

func start_next_wave() -> void:
    if current_wave >= wave_definitions.size():
        print("All waves completed!")
        return

    var wave_def = wave_definitions[current_wave]
    wave_started.emit(current_wave + 1)

    # Spawnar inimigos
    for enemy_group in wave_def.enemies:
        for i in enemy_group.count:
            await get_tree().create_timer(wave_def.spawn_delay).timeout
            spawn_enemy(enemy_group)
            enemies_remaining += 1

func spawn_enemy(config: Dictionary) -> void:
    var enemy = enemy_scene.instantiate()
    enemy.health = config.health
    enemy.speed = config.speed
    enemy.score_value = config.score

    # Posição aleatória no topo
    var viewport_width = get_viewport().get_visible_rect().size.x
    enemy.global_position = Vector2(
        randf_range(100, viewport_width - 100),
        -50
    )

    # Conectar sinal
    enemy.enemy_died.connect(_on_enemy_died)

    get_tree().root.add_child(enemy)

func _on_enemy_died(enemy: Enemy, score: int) -> void:
    enemies_remaining -= 1
    enemy_killed.emit(score)

    if enemies_remaining <= 0:
        wave_completed.emit(current_wave + 1)
        current_wave += 1
        await get_tree().create_timer(3.0).timeout
        start_next_wave()
```

### Passo 4: Criar Game Controller

```gdscript
# game_controller.gd
extends Node

signal score_changed(new_score: int)

var current_score: int = 0
var player: Node2D
var wave_manager: Node2D

func _ready() -> void:
    _setup_player()
    _setup_wave_manager()

func _setup_player() -> void:
    # Criar ou encontrar player
    var player_scene = preload("res://path/to/player.tscn")
    player = player_scene.instantiate()
    player.global_position = Vector2(400, 500)
    get_tree().root.add_child(player)

func _setup_wave_manager() -> void:
    var wm_scene = preload("res://path/to/wave_manager.tscn")
    wave_manager = wm_scene.instantiate()
    wave_manager.enemy_killed.connect(_on_enemy_killed)
    wave_manager.wave_completed.connect(_on_wave_completed)
    get_tree().root.add_child(wave_manager)

func _on_enemy_killed(score: int) -> void:
    current_score += score
    score_changed.emit(current_score)
    print("Score: %d" % current_score)

func _on_wave_completed(wave: int) -> void:
    print("Wave %d completed!" % wave)
    current_score += 500
    score_changed.emit(current_score)
```

### Passo 5: Adicionar Sistema de Armas (Opcional)

```gdscript
# No player.gd, adicionar:

var weapon_manager: WeaponSlotManager

func _setup_components() -> void:
    # ... outros componentes ...

    # Weapon Manager
    weapon_manager = WeaponSlotManager.new()
    weapon_manager.auto_handle_input = false
    host.add_component(weapon_manager)

    # Criar arma básica
    var primary_weapon = WeaponData.new()
    primary_weapon.weapon_name = "Laser"
    primary_weapon.category = WeaponData.Category.PRIMARY
    primary_weapon.damage = 10
    primary_weapon.fire_rate = 0.2
    primary_weapon.projectile_speed = 600.0
    primary_weapon.projectile_scene = load("res://path/to/projectile.tscn")

    weapon_manager.primary_weapon = primary_weapon

    # Adicionar input de disparo
    input_component.add_action("fire", [KEY_SPACE])

func _process(_delta: float) -> void:
    _handle_movement()
    _handle_shooting()

func _handle_shooting() -> void:
    if input_component.is_action_pressed("fire"):
        weapon_manager.fire_primary_and_secondary()
```

---

## 📚 Recursos Adicionais

### Documentação do Framework

- [Component Foundation](../components/component_foundation.md) - Sistema base de componentes
- [Movement System](../components/movement.md) - Componentes de movimento
- [Health System](../components/health.md) - Sistema de vida e dano
- [Input System](../components/input.md) - Gerenciamento de input
- [Component Creation Guide](../guidelines/COMPONENT_CREATION.md) - Como criar componentes

### Arquivos do Space Shooter

**Principais Scripts**:
- `examples/space_shooter/scripts/player_controller.gd` - Implementação completa do player
- `examples/space_shooter/scripts/enemy_base.gd` - Base para todos os inimigos
- `examples/space_shooter/scripts/game_controller.gd` - Controlador principal do jogo
- `examples/space_shooter/scripts/wave_manager.gd` - Gerenciador de ondas

**Sistemas Especializados**:
- `examples/space_shooter/scripts/enemy_factory.gd` - Factory de inimigos
- `examples/space_shooter/scripts/weapon_database.gd` - Database de armas
- `examples/space_shooter/scripts/pilot_database.gd` - Database de pilotos
- `examples/space_shooter/scripts/entity_pool_manager.gd` - Object pooling

**Documentação Adicional**:
- `examples/space_shooter/docs/setup_instructions.md` - Como executar o jogo
- `examples/space_shooter/docs/enemy_factory_usage.md` - Como usar o Factory
- `examples/space_shooter/docs/PHASE_SYSTEM.md` - Sistema de fases

---

## 🎯 Conclusão

O Space Shooter demonstra como o **MilitiaForge2D** permite criar jogos complexos de forma modular e organizada. Os principais aprendizados são:

1. **Composição sobre Herança**: Use componentes ao invés de herança profunda
2. **Separação de Responsabilidades**: Cada componente tem uma função clara
3. **Baixo Acoplamento**: Sistemas se comunicam via sinais (Observer Pattern)
4. **Dependency Injection**: Injete dependências ao invés de buscar na árvore
5. **Factory Pattern**: Centralize criação de objetos complexos
6. **Object Pooling**: Otimize criação/destruição de objetos frequentes

Seguindo esses princípios, você pode criar jogos escaláveis, testáveis e fáceis de manter!

---

**Desenvolvido com** ❤️ **usando MilitiaForge2D**

*Última atualização: 2024-12-28*
