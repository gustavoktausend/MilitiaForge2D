# 📋 Sistema de Economia e Progressão - Space Shooter
## Design Document & Roadmap de Implementação

**Data de Criação:** 2026-01-02
**Status:** 🟡 Planejamento Completo - Implementação Pendente
**Estimativa Total:** 19-23 horas

---

## 📑 Índice

1. [Visão Geral](#visão-geral)
2. [Sistema de Moeda](#sistema-de-moeda)
3. [Power-Ups Durante Gameplay](#power-ups-durante-gameplay)
4. [Sistema de Loja Entre Waves](#sistema-de-loja-entre-waves)
5. [Categorias de Items da Loja](#categorias-de-items-da-loja)
6. [Sistema de Upgrades](#sistema-de-upgrades)
7. [Balanceamento](#balanceamento)
8. [Estrutura de Arquivos](#estrutura-de-arquivos)
9. [Roadmap de Implementação](#roadmap-de-implementação)
10. [Decisões de Design](#decisões-de-design)

---

## 🎯 Visão Geral

### Objetivo

Criar um sistema de progressão roguelite com loja entre waves que permita ao jogador:
- ✅ Coletar power-ups durante o gameplay
- ✅ Acumular moeda (créditos) separada do score
- ✅ Comprar upgrades permanentes entre waves
- ✅ Tomar decisões estratégicas sobre build do personagem

### Pilares de Design

1. **Progressão Satisfatória** - Cada wave deixa o jogador mais forte
2. **Escolhas Significativas** - Budget limitado força priorização
3. **Risco vs Recompensa** - Power-ups perigosos valem mais créditos
4. **Variedade de Builds** - Múltiplos caminhos para vitória
5. **Integração com Pilotos** - Sinergia com habilidades de piloto existentes

### Estado Atual do Código

**O que já existe:**
- ✅ Sistema de Score completo (`score_component.gd`)
- ✅ Placeholder para power-ups em `enemy_base.gd` (linha 476-519)
- ✅ Métodos stub em `player_controller.gd` (`power_up_weapon()`, `power_up_shield()`)
- ✅ High score persistence (`user://highscore.save`)
- ✅ Sistema de pilotos com 15+ stat modifiers
- ✅ Wave manager com 5 waves

**O que falta:**
- ❌ Power-up entities (só placeholder)
- ❌ Sistema de créditos (moeda separada do score)
- ❌ Loja UI e lógica
- ❌ Upgrade manager
- ❌ Persistência de upgrades entre waves

---

## 💰 Sistema de Moeda

### Modelo: Sistema Dual (Score + Credits)

#### 1. SCORE (Pontuação)

**Propósito:** Ranking, conquistas, high score
**Status:** ✅ Já implementado completamente

**Características:**
- Não pode ser gasto
- Usado para:
  - High score tracking
  - Rank final (F a SSS)
  - Conquistas futuras
  - Leaderboards
- Combo system aumenta score
- Wave completion bonuses

#### 2. CREDITS (Créditos) ⭐ NOVO

**Propósito:** Moeda de compra na loja
**Status:** ❌ Precisa ser implementado

**Características:**
- Pode ser gasto em upgrades
- Persiste entre waves (não entre jogos)
- Resetado ao iniciar novo jogo
- Display na HUD ao lado do score

**Obtido por:**
- Matar inimigos (50% do score value)
- Coletar credit gem pickups
- Wave completion bonuses
- Combo milestones

### Fontes de Créditos

```
╔═══════════════════════════════════════════════════════╗
║                  INIMIGOS                             ║
╠═══════════════════════════════════════════════════════╣
║ Basic (100 score)     → 50 créditos                  ║
║ Fast (150 score)      → 75 créditos                  ║
║ Tank (300 score)      → 150 créditos                 ║
╠═══════════════════════════════════════════════════════╣
║              BÔNUS DE WAVE                            ║
╠═══════════════════════════════════════════════════════╣
║ Wave 1 completa       → 200 créditos                 ║
║ Wave 2 completa       → 300 créditos                 ║
║ Wave 3 completa       → 400 créditos                 ║
║ Wave 4 completa       → 500 créditos                 ║
║ Wave 5+ completa      → 600 créditos                 ║
╠═══════════════════════════════════════════════════════╣
║            PICKUPS ESPECIAIS                          ║
╠═══════════════════════════════════════════════════════╣
║ Credit Gem (Small)    → 25 créditos                  ║
║ Credit Gem (Medium)   → 50 créditos                  ║
║ Credit Gem (Large)    → 100 créditos                 ║
╠═══════════════════════════════════════════════════════╣
║            COMBO MILESTONES                           ║
╠═══════════════════════════════════════════════════════╣
║ Combo 10x             → 50 créditos                  ║
║ Combo 25x             → 100 créditos                 ║
║ Combo 50x             → 250 créditos                 ║
╚═══════════════════════════════════════════════════════╝
```

### Budget Estimado por Wave

```
Wave 1: ~500-700 créditos      (5 Basic)
Wave 2: ~900-1,200 créditos    (8 Basic + 2 Fast)
Wave 3: ~1,400-1,800 créditos  (mixed)
Wave 4: ~2,000-2,500 créditos  (challenging)
Wave 5: ~2,500-3,000 créditos  (final)

Total acumulado após Wave 5: ~8,000-10,000 créditos
Total estimado Wave 10: ~15,000-20,000 créditos
```

### Implementação Técnica

**Local:** `scripts/game_controller.gd` ou novo `scripts/shop/credit_manager.gd`

```gdscript
# Adicionar ao GameController ou criar CreditManager
var current_credits: int = 0

signal credits_changed(new_amount: int, delta: int)

func add_credits(amount: int) -> void:
    var old_credits = current_credits
    current_credits += amount
    credits_changed.emit(current_credits, amount)
    print("[Credits] +%d credits (total: %d)" % [amount, current_credits])

func spend_credits(amount: int) -> bool:
    if current_credits < amount:
        return false

    var old_credits = current_credits
    current_credits -= amount
    credits_changed.emit(current_credits, -amount)
    print("[Credits] -%d credits (total: %d)" % [amount, current_credits])
    return true

func can_afford(cost: int) -> bool:
    return current_credits >= cost
```

---

## 🎁 Power-Ups Durante Gameplay

### Tipos de Power-Ups (7 tipos)

#### 1. HEALTH PICKUP (Comum)
```yaml
Drop Chance: 40% (do total de 15% base)
Efeito: Restaura 30 HP
Visual: Cruz verde neon pulsando
Duração no chão: 15 segundos
Som: heal_pickup.ogg
Partículas: Green sparkle ao coletar
```

#### 2. SHIELD BOOSTER (Comum)
```yaml
Drop Chance: 25%
Efeito: +50 HP temporário (escudo azul)
Visual: Hexágono azul neon
Duração Buff: 30 segundos ou até quebrar
Som: shield_pickup.ogg
Partículas: Blue pulse ao coletar
UI: Indicador de escudo na HUD
```

#### 3. AMMO REFILL (Comum)
```yaml
Drop Chance: 20%
Efeito: SECONDARY +10, SPECIAL +2
Visual: Caixa de munição amarela
Duração no chão: 12 segundos
Som: ammo_pickup.ogg
Partículas: Yellow flash
UI: Flash na weapon HUD
```

#### 4. RAPID FIRE (Raro)
```yaml
Drop Chance: 8%
Efeito: +50% fire rate por 20 segundos
Visual: Relâmpago laranja pulsando
Duração Buff: 20 segundos
Som: powerup_rare.ogg
Partículas: Orange lightning
UI: Timer bar na HUD
```

#### 5. SCORE MULTIPLIER (Raro)
```yaml
Drop Chance: 5%
Efeito: 2x score por 30 segundos
Visual: Estrela dourada girando
Duração Buff: 30 segundos
Som: score_boost.ogg
Partículas: Gold stars
UI: "2X SCORE" indicator
```

#### 6. CREDIT GEM (Variado)
```yaml
Drop Chance Total: 40% dos power-ups
  - Small (76% dos gems): 25 créditos
  - Medium (19% dos gems): 50 créditos
  - Large (5% dos gems): 100 créditos
Visual: Diamante cyan (tamanho varia)
Duração no chão: 20 segundos
Som: credit_pickup.ogg (pitch varia)
Partículas: Cyan shimmer
Stackable: Sim
```

#### 7. SMART BOMB (Muito Raro)
```yaml
Drop Chance: 1%
Efeito: Destroi todos inimigos na tela
Visual: Bomba roxa pulsando
Uso: Ativação imediata ao coletar
Dano: 999 (kill instantâneo)
Som: explosion_massive.ogg
Partículas: Purple shockwave
Screen Shake: Heavy (30px)
```

### Sistema de Raridade

```
Total Drop Chance: 15% dos inimigos ao morrer

Distribuição de Power-Ups:
┌─────────────────────────────────────────────┐
│ COMUM (65%)                                 │
├─────────────────────────────────────────────┤
│ ■■■■■■■■■■■■■■■■■■■■ Health (40%)          │
│ ■■■■■■■■■■■■■ Shield (25%)                 │
├─────────────────────────────────────────────┤
│ INCOMUM (40%)                               │
├─────────────────────────────────────────────┤
│ ■■■■■■■■■■ Ammo Refill (20%)               │
│ ■■■■■■■■ Credit Gem Small (16%)            │
├─────────────────────────────────────────────┤
│ RARO (15%)                                  │
├─────────────────────────────────────────────┤
│ ■■■■ Rapid Fire (8%)                       │
│ ■■■ Score Multiplier (5%)                  │
│ ■■ Credit Gem Medium (4%)                  │
├─────────────────────────────────────────────┤
│ MUITO RARO (3%)                             │
├─────────────────────────────────────────────┤
│ ■ Smart Bomb (1%)                          │
│ ■ Credit Gem Large (0.8%)                  │
└─────────────────────────────────────────────┘
```

### Mecânica de Coleta

**Sistema de Detecção:**
- Area2D em cada power-up
- Detecta overlap com player Hurtbox
- Auto-coleta ao tocar

**Magnetismo (opcional):**
- Power-ups são atraídos quando player está próximo
- Raio de atração: 100px (base)
- Upgrade "Pickup Range" aumenta raio
- Pilot "Scavenger" tem +50% range

**Feedback ao Coletar:**
- Som específico por tipo
- Partículas de absorção
- UI popup mostrando item coletado
- Flash na HUD se for crédito
- Screen shake leve para raros

**Despawn:**
- Timer de 10-20 segundos (varia por tipo)
- Fade out nos últimos 3 segundos
- Partículas de desaparecimento

### Implementação de Drop

**Local:** `scripts/enemy_base.gd` (já tem placeholder na linha 517-519)

```gdscript
func _spawn_powerup() -> void:
    # Já existe 15% base chance
    var roll = randf() * 100.0
    var powerup_type: String

    # Determinar tipo por raridade
    if roll < 40:
        powerup_type = "health"
    elif roll < 65:
        powerup_type = "shield"
    elif roll < 85:
        powerup_type = "ammo"
    elif roll < 93:
        powerup_type = "rapid_fire"
    elif roll < 98:
        powerup_type = "score_mult"
    elif roll < 99:
        powerup_type = "smart_bomb"
    else:
        # Credit gems (weighted)
        var gem_roll = randf()
        if gem_roll < 0.76:
            powerup_type = "credit_small"
        elif gem_roll < 0.95:
            powerup_type = "credit_medium"
        else:
            powerup_type = "credit_large"

    # Criar power-up via factory
    var powerup = PowerUpFactory.create(powerup_type)
    powerup.global_position = physics_body.global_position

    # Adicionar ao container de pickups
    var container = get_tree().get_first_node_in_group("PickupsContainer")
    if container:
        container.add_child(powerup)
```

---

## 🏪 Sistema de Loja Entre Waves

### Quando Abre a Loja

**Opção Implementada:** Após cada wave (Waves 1-9)

```
Game Start → Wave 1 → SHOP → Wave 2 → SHOP → ... → Wave 10 (Boss)
```

**Alternativa Futura:** Apenas em waves específicas
```
Wave 2 → SHOP → Wave 4 → SHOP → Wave 6 → SHOP
```

### Flow da Loja

```
┌───────────────────────────────────────────┐
│  1. Wave Completion                       │
│     - Enemies cleared                     │
│     - Player alive                        │
└─────────────────┬─────────────────────────┘
                  ↓
┌───────────────────────────────────────────┐
│  2. Wave Summary Screen (2 segundos)      │
│     - Enemies killed this wave: XX        │
│     - Credits earned: +XXX                │
│     - Total credits: XXX                  │
│     - Accuracy: XX%                       │
└─────────────────┬─────────────────────────┘
                  ↓
┌───────────────────────────────────────────┐
│  3. Shop Opens (modal overlay)            │
│     - Pause game                          │
│     - Browse items by category            │
│     - Purchase upgrades                   │
│     - View current stats                  │
│     - Timer: 60 segundos (opcional)       │
└─────────────────┬─────────────────────────┘
                  ↓
┌───────────────────────────────────────────┐
│  4. Player Confirmation                   │
│     - Click "Ready" button                │
│     - OR timer expires (auto-close)       │
└─────────────────┬─────────────────────────┘
                  ↓
┌───────────────────────────────────────────┐
│  5. Next Wave Starts                      │
│     - Resume game                         │
│     - Spawn enemies                       │
│     - Apply purchased upgrades            │
└───────────────────────────────────────────┘
```

### UI Layout da Loja

```
┌──────────────────────────────────────────────────────────────────┐
│  🏪 WAVE SHOP                          Credits: 💎 1,250         │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  [ UPGRADES ]  [ WEAPONS ]  [ CONSUMABLES ]  [ SPECIALS ]       │
│                ────────────                                       │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ 💚 +10 HP    │  │ ⚔️ +5% DMG   │  │ ⚡ +10% SPD  │          │
│  │              │  │              │  │              │          │
│  │   100 💎     │  │   150 💎     │  │   100 💎     │          │
│  │  [BUY] 3/5   │  │  [BUY] 5/10  │  │  [BUY] 2/5   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ 🔥 FIRE +10% │  │ 🛡️ Shield    │  │ ⭐ 2x Score  │          │
│  │              │  │  (1 wave)    │  │  (1 wave)    │          │
│  │   200 💎     │  │   300 💎     │  │   150 💎     │          │
│  │  [BUY] 1/5   │  │   [BUY]      │  │   [BUY]      │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ 🔄 Reroll    │  │ 💊 Full Heal │  │ 🍀 Lucky +%  │          │
│  │  Shop        │  │              │  │              │          │
│  │   100 💎     │  │   200 💎     │  │   600 💎     │          │
│  │   [BUY]      │  │   [BUY]      │  │  [BUY] 0/3   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                   │
│  [◀ PREV PAGE]          Page 1/3          [NEXT PAGE ▶]        │
│                                                                   │
├──────────────────────────────────────────────────────────────────┤
│  📊 Current Stats:                                               │
│  ❤️ HP: 100 (+30)  ⚔️ DMG: 10 (+10)  ⚡ SPD: 300 (+20)         │
│  🔥 Fire Rate: 5.0 (+0.5)  🎯 Pickup Range: 100px (+20px)      │
├──────────────────────────────────────────────────────────────────┤
│                [ 🚀 READY - Start Next Wave ]                   │
│                        Time Remaining: 0:45                      │
└──────────────────────────────────────────────────────────────────┘
```

### Mecânicas da Loja

**Navegação:**
- 4 tabs (Upgrades, Weapons, Consumables, Specials)
- Grid 3x3 de items por página
- Scroll/pagination se necessário

**Compra:**
1. Click no botão [BUY]
2. Validação (credits suficientes + stackable)
3. Dedução de créditos
4. Aplicação imediata do upgrade
5. Feedback visual + som
6. Update do UI

**Validações:**
- `can_afford(cost)` - Tem créditos?
- `can_stack(item)` - Atingiu max stack?
- `is_purchased(item)` - Já comprou (se único)?

**Tooltips:**
- Hover mostra descrição detalhada
- Mostra efeito atual vs com upgrade
- Mostra quantas vezes comprado (X/Max)

---

## 📦 Categorias de Items da Loja

### Tab 1: UPGRADES PERMANENTES

#### Tier 1 - Stats Básicos

| Item | Custo | Max Stack | Efeito Total | Descrição |
|------|-------|-----------|--------------|-----------|
| **💚 Health Boost** | 100💎 | 5 | +50 HP | Aumenta vida máxima em 10 HP |
| **⚔️ Damage Boost** | 150💎 | 10 | +50% | Aumenta dano de TODAS armas em 5% |
| **🔥 Fire Rate** | 200💎 | 5 | +50% | Reduz cooldown entre tiros em 10% |
| **⚡ Movement Speed** | 100💎 | 5 | +25% | Aumenta velocidade de movimento em 5% |

#### Tier 2 - Stats Avançados

| Item | Custo | Max Stack | Efeito Total | Descrição |
|------|-------|-----------|--------------|-----------|
| **📏 Projectile Size** | 250💎 | 3 | +45% | Projéteis 15% maiores = mais fácil acertar |
| **🧲 Pickup Range** | 150💎 | 3 | +60% | Atrai power-ups de 20% mais longe |
| **🛡️ I-Frame Duration** | 200💎 | 3 | +0.6s | +0.2s invencibilidade após tomar dano |
| **💚 Regeneration** | 500💎 | 1 | 1 HP/s | Regenera vida constantemente (único) |

### Tab 2: WEAPONS & AMMO

| Item | Custo | Max Stack | Descrição |
|------|-------|-----------|-----------|
| **📦 Secondary Ammo** | 150💎 | ∞ | +5 munição SECONDARY |
| **🎯 Special Ammo** | 250💎 | ∞ | +2 munição SPECIAL |
| **🔋 Ammo Capacity** | 300💎 | 5 | +5 capacidade máxima de munição |
| **🎯 Piercing Shots** | 800💎 | 1 | Projéteis atravessam 1 inimigo (único) |
| **🔮 Homing Modifier** | 1000💎 | 1 | PRIMARY vira homing (único) |

### Tab 3: CONSUMABLES (1 wave)

| Item | Custo | Duração | Efeito |
|------|-------|---------|--------|
| **🛡️ Shield** | 300💎 | 1 wave | +50 HP escudo temporário |
| **⭐ 2x Score** | 200💎 | 1 wave | Dobra ganho de score |
| **💎 Credit Boost** | 400💎 | 1 wave | +50% créditos de inimigos |
| **🔥 Rapid Fire** | 250💎 | 1 wave | +50% fire rate |
| **⚔️ Damage Boost** | 350💎 | 1 wave | +30% damage |

### Tab 4: SPECIALS

| Item | Custo | Max Stack | Descrição |
|------|-------|-----------|-----------|
| **❤️ Extra Life** | 2000💎 | 3 | Revive com 50% HP ao morrer |
| **🔄 Reroll Shop** | 100💎 | ∞ | Gera novos items aleatórios na loja |
| **💊 Full Heal** | 200💎 | ∞ | Restaura 100% HP imediatamente |
| **🍀 Lucky Charm** | 600💎 | 3 | +10% drop rate de power-ups |

### Preços Balanceados

```
Budget após Wave 1: ~600 💎
Pode comprar:
  - 6× Health Boost (600💎)
  - 4× Damage Boost (600💎)
  - 2× Health + 2× Damage + Shield (500💎)

Budget após Wave 3: ~1,500 💎 acumulado
Pode comprar:
  - Full stats tier 1 (~1,000💎)
  - 1× tier 2 + consumíveis (~800💎)

Budget após Wave 5: ~3,000 💎 acumulado
Pode comprar:
  - Build completo tier 1+2
  - Começar a comprar specials

Budget após Wave 10: ~15,000 💎 acumulado
Pode comprar:
  - Todas upgrades máximas
  - 2-3 Extra Lives
  - Lucky Charms
```

---

## 🔧 Sistema de Upgrades

### UpgradeManager Component

**Novo arquivo:** `scripts/shop/upgrade_manager.gd`

```gdscript
class_name UpgradeManager extends Node

#region Signals
signal upgrade_purchased(upgrade_id: String, stack: int, cost: int)
signal upgrade_applied(upgrade_id: String, value: Variant)
signal buff_activated(buff_id: String, duration: float)
signal buff_expired(buff_id: String)
#endregion

#region Tracking de Upgrades
# Upgrades permanentes comprados
var purchased_upgrades: Dictionary = {
    "health_boost": 0,
    "damage_boost": 0,
    "fire_rate_boost": 0,
    "speed_boost": 0,
    "projectile_size": 0,
    "pickup_range": 0,
    "iframe_duration": 0,
    "regeneration": false,
    "ammo_capacity": 0,
    "piercing": false,
    "homing": false,
    "lucky_charm": 0,
}

# Buffs temporários ativos (1 wave)
var active_buffs: Dictionary = {
    # buff_id: {value: float, expires_wave: int}
}

# Extra lives
var extra_lives: int = 0
#endregion

#region Purchase Logic
func purchase_upgrade(upgrade_id: String, cost: int) -> bool:
    # Validações
    if not GameController.can_afford(cost):
        print("[UpgradeManager] Not enough credits for %s" % upgrade_id)
        return false

    if not can_stack_upgrade(upgrade_id):
        print("[UpgradeManager] Max stack reached for %s" % upgrade_id)
        return false

    # Deduzir créditos
    if not GameController.spend_credits(cost):
        return false

    # Incrementar stack ou ativar
    if upgrade_id in ["regeneration", "piercing", "homing"]:
        purchased_upgrades[upgrade_id] = true
    else:
        purchased_upgrades[upgrade_id] += 1

    # Aplicar upgrade ao jogador
    apply_upgrade_to_player(upgrade_id)

    # Emitir sinal
    upgrade_purchased.emit(upgrade_id, purchased_upgrades[upgrade_id], cost)

    print("[UpgradeManager] Purchased %s (stack: %s)" % [upgrade_id, purchased_upgrades[upgrade_id]])
    return true

func can_stack_upgrade(upgrade_id: String) -> bool:
    var max_stacks = {
        "health_boost": 5,
        "damage_boost": 10,
        "fire_rate_boost": 5,
        "speed_boost": 5,
        "projectile_size": 3,
        "pickup_range": 3,
        "iframe_duration": 3,
        "ammo_capacity": 5,
        "lucky_charm": 3,
    }

    # Únicos não stackam
    if upgrade_id in ["regeneration", "piercing", "homing"]:
        return not purchased_upgrades[upgrade_id]

    # Check stack limit
    if upgrade_id in max_stacks:
        return purchased_upgrades[upgrade_id] < max_stacks[upgrade_id]

    return true
#endregion

#region Apply Upgrades
func apply_upgrade_to_player(upgrade_id: String) -> void:
    var player = get_tree().get_first_node_in_group("player")
    if not player:
        push_warning("Player not found, cannot apply upgrade")
        return

    match upgrade_id:
        "health_boost":
            player.modify_max_health(10)

        "damage_boost":
            player.modify_damage_multiplier(1.05)  # +5%

        "fire_rate_boost":
            player.modify_fire_rate_multiplier(1.1)  # +10%

        "speed_boost":
            player.modify_speed_multiplier(1.05)  # +5%

        "projectile_size":
            player.modify_projectile_size(1.15)  # +15%

        "pickup_range":
            player.modify_pickup_range(1.2)  # +20%

        "iframe_duration":
            player.modify_iframe_duration(0.2)  # +0.2s

        "regeneration":
            player.enable_regeneration(1.0)  # 1 HP/s

        "ammo_capacity":
            player.modify_ammo_capacity(5)

        "piercing":
            player.enable_piercing(1)  # Pierce 1 enemy

        "homing":
            player.enable_homing_primary()

        "lucky_charm":
            # Aumenta drop rate globalmente
            var current_rate = 0.15
            var new_rate = current_rate * 1.1  # +10%
            GameController.set_drop_rate(new_rate)

    upgrade_applied.emit(upgrade_id, purchased_upgrades[upgrade_id])

func apply_all_upgrades_to_player() -> void:
    # Chamado ao iniciar wave com player novo
    for upgrade_id in purchased_upgrades.keys():
        var stack = purchased_upgrades[upgrade_id]
        if typeof(stack) == TYPE_INT and stack > 0:
            for i in range(stack):
                apply_upgrade_to_player(upgrade_id)
        elif typeof(stack) == TYPE_BOOL and stack:
            apply_upgrade_to_player(upgrade_id)
#endregion

#region Consumables & Buffs
func activate_consumable(buff_id: String, duration_waves: int = 1) -> void:
    var current_wave = GameController.current_wave
    active_buffs[buff_id] = {
        "value": get_buff_value(buff_id),
        "expires_wave": current_wave + duration_waves
    }

    apply_buff_to_player(buff_id)
    buff_activated.emit(buff_id, duration_waves)

func get_buff_value(buff_id: String) -> float:
    match buff_id:
        "shield": return 50.0  # +50 HP temp
        "score_mult": return 2.0  # 2x
        "credit_mult": return 1.5  # +50%
        "rapid_fire": return 1.5  # +50%
        "damage_temp": return 1.3  # +30%
    return 1.0

func apply_buff_to_player(buff_id: String) -> void:
    var player = get_tree().get_first_node_in_group("player")
    if not player:
        return

    var value = active_buffs[buff_id]["value"]

    match buff_id:
        "shield":
            player.add_temporary_health(int(value))
        "score_mult":
            player.score.set_temporary_multiplier(value)
        "credit_mult":
            GameController.set_credit_multiplier(value)
        "rapid_fire":
            player.modify_fire_rate_multiplier(value)
        "damage_temp":
            player.modify_damage_multiplier(value)

func check_expired_buffs(current_wave: int) -> void:
    for buff_id in active_buffs.keys():
        if active_buffs[buff_id]["expires_wave"] <= current_wave:
            remove_buff(buff_id)

func remove_buff(buff_id: String) -> void:
    if buff_id not in active_buffs:
        return

    # Remove efeito do player
    var player = get_tree().get_first_node_in_group("player")
    if player:
        match buff_id:
            "score_mult":
                player.score.remove_temporary_multiplier()
            "credit_mult":
                GameController.set_credit_multiplier(1.0)
            "rapid_fire":
                player.modify_fire_rate_multiplier(1.0 / active_buffs[buff_id]["value"])
            "damage_temp":
                player.modify_damage_multiplier(1.0 / active_buffs[buff_id]["value"])

    active_buffs.erase(buff_id)
    buff_expired.emit(buff_id)
#endregion

#region Reset
func reset_all_upgrades() -> void:
    # Chamado ao iniciar novo jogo (game over)
    purchased_upgrades.clear()
    active_buffs.clear()
    extra_lives = 0
    print("[UpgradeManager] All upgrades reset")
#endregion
```

### Integração com Player

**Adicionar ao `player_controller.gd`:**

```gdscript
# Métodos para aplicar upgrades
func modify_max_health(bonus: int) -> void:
    if health:
        health.max_health += bonus
        health.current_health += bonus  # Também cura
        print("[Player] Max health increased by %d (now %d)" % [bonus, health.max_health])

func modify_damage_multiplier(multiplier: float) -> void:
    # Aplicar a todas armas
    if weapon_manager:
        weapon_manager.damage_multiplier *= multiplier
        print("[Player] Damage multiplier: %.2f" % weapon_manager.damage_multiplier)

func modify_fire_rate_multiplier(multiplier: float) -> void:
    if weapon_manager:
        weapon_manager.fire_rate_multiplier *= multiplier
        print("[Player] Fire rate multiplier: %.2f" % weapon_manager.fire_rate_multiplier)

func modify_speed_multiplier(multiplier: float) -> void:
    if movement:
        movement.max_speed *= multiplier
        print("[Player] Speed multiplier: %.2f (speed: %.1f)" % [multiplier, movement.max_speed])

# ... outros métodos similares
```

---

## 📊 Balanceamento

### Curva de Progressão

```
┌─────────────────────────────────────────────────────────┐
│         PROGRESSÃO: PODER DO JOGADOR vs INIMIGOS       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  400% │                                          ╱      │
│       │                                      ╱╱╱        │
│  350% │                                  ╱╱╱  Enemy    │
│       │                              ╱╱╱      Power    │
│  300% │                          ╱╱╱                   │
│       │                      ╱╱╱                       │
│  250% │                  ╱╱╱            ╱──────        │
│       │              ╱╱╱            ╱╱╱  Player        │
│  200% │          ╱╱╱            ╱╱╱      Power         │
│       │      ╱╱╱            ╱╱╱                        │
│  150% │  ╱╱╱            ╱╱╱                            │
│       │╱            ╱╱╱                                │
│  100% ├────────╱╱╱─────────────────────────────────   │
│       │    ╱╱╱                                         │
│   50% │╱╱╱                                             │
│       │                                                 │
│    0% └─────┬─────┬─────┬─────┬─────┬─────┬─────┬──── │
│           W1    W2    W3    W5    W7    W9   W10      │
└─────────────────────────────────────────────────────────┘

KEY MILESTONES:
Wave 1: Player 100%, Enemy 100% - Learning phase
Wave 3: Player 130%, Enemy 150% - First challenge spike
Wave 5: Player 170%, Enemy 200% - Gatekeeper (needs upgrades)
Wave 10: Player 250%, Enemy 350% - Final boss (full build)
```

### Economy Loop

```
╔════════════════════════════════════════════════════════╗
║           POSITIVE FEEDBACK LOOP                       ║
╠════════════════════════════════════════════════════════╣
║                                                         ║
║   ┌──────────────┐                                     ║
║   │ Kill Enemies │                                     ║
║   └──────┬───────┘                                     ║
║          │                                             ║
║          ▼                                             ║
║   ┌──────────────┐      ┌──────────────┐             ║
║   │Earn Credits  │◄─────┤Drop Power-Ups│             ║
║   └──────┬───────┘      └──────┬───────┘             ║
║          │                     │                       ║
║          ▼                     ▼                       ║
║   ┌──────────────┐      ┌──────────────┐             ║
║   │  Open Shop   │      │Collect Buffs │             ║
║   └──────┬───────┘      └──────┬───────┘             ║
║          │                     │                       ║
║          ▼                     ▼                       ║
║   ┌──────────────┐      ┌──────────────┐             ║
║   │Buy Upgrades  │      │Become Stronger             ║
║   └──────┬───────┘      └──────┬───────┘             ║
║          │                     │                       ║
║          └─────────┬───────────┘                       ║
║                    │                                   ║
║                    ▼                                   ║
║            ┌──────────────┐                           ║
║            │Kill More/     │                           ║
║            │Faster Enemies │                           ║
║            └───────┬───────┘                           ║
║                    │                                   ║
║                    └──────► LOOP ◄────────┘           ║
║                                                         ║
╚════════════════════════════════════════════════════════╝
```

### Gatekeepers (Checkpoints de Dificuldade)

**Wave 1-2:** Tutorial Zone
- Pode completar sem upgrades
- Aprende mecânicas básicas

**Wave 3:** Primeiro Spike
- **Requer:** 2-3 upgrades tier 1
- Introduz inimigos Fast + shooting Tanks

**Wave 5:** Mid-Game Gatekeeper
- **Requer:** Full tier 1 OU tier 2 specialist build
- Muitos inimigos simultâneos
- Alta pressure

**Wave 7-8:** Late Game
- **Requer:** Mix tier 1 + tier 2
- Consumíveis recomendados

**Wave 10:** Boss Final
- **Requer:** Build completo
- Extra Life recomendado
- Consumíveis essenciais

### Build Archetypes

**1. Tank Build (Survivability)**
```yaml
Focus: Não morrer
Upgrades:
  - Health Boost (5×) = +50 HP
  - Regeneration (1×) = 1 HP/s
  - I-Frame Duration (3×) = +0.6s
  - Shield consumables
Pilot Synergy: Tank Commander (regen stacks)
Strength: Sobrevive waves longas
Weakness: DPS baixo, waves demoram
```

**2. Glass Cannon (DPS)**
```yaml
Focus: Matar rápido
Upgrades:
  - Damage Boost (10×) = +50% damage
  - Fire Rate (5×) = +50% fire rate
  - Piercing + Homing
Pilot Synergy: Dual Wielder, Berserker
Strength: Mata tudo instantaneamente
Weakness: Morre fácil se errar
```

**3. Speed Runner (Mobility)**
```yaml
Focus: Não ser atingido
Upgrades:
  - Movement Speed (5×) = +25% speed
  - Projectile Size (3×) = easier to hit
  - Fire Rate (3×)
Pilot Synergy: Speed Demon
Strength: Dodges everything
Weakness: Precisa de skill alto
```

**4. Economy Build (Farming)**
```yaml
Focus: Maximizar créditos
Upgrades:
  - Lucky Charm (3×) = +30% drops
  - Pickup Range (3×) = +60% range
  - Credit Boost consumables
Pilot Synergy: Scavenger
Strength: Fica rico, compra tudo
Weakness: Começo fraco
```

**5. Balanced Build (Recomendado)**
```yaml
Focus: Sem fraquezas
Upgrades:
  - Health (3×), Damage (5×), Fire Rate (3×)
  - Pickup Range (2×)
  - 1× Regeneration
Pilot Synergy: I.N.D.I.O
Strength: Funciona sempre
Weakness: Não excel em nada
```

### Custos vs Retorno

**Early Game (Wave 1-3):**
- Investir em: Health, Damage básico
- ROI: Sobreviver Wave 3

**Mid Game (Wave 4-6):**
- Investir em: Fire Rate, tier 2 specialist
- ROI: Farm credits mais rápido

**Late Game (Wave 7-10):**
- Investir em: Consumíveis, Extra Life
- ROI: Garantir vitória

---

## 📁 Estrutura de Arquivos

### Arquivos Novos a Criar

```
examples/space_shooter/
│
├── scripts/
│   │
│   ├── pickups/                         ⭐ NOVO DIRETÓRIO
│   │   ├── power_up_base.gd            ⭐ CRIAR
│   │   ├── health_pickup.gd            ⭐ CRIAR
│   │   ├── shield_pickup.gd            ⭐ CRIAR
│   │   ├── ammo_refill.gd              ⭐ CRIAR
│   │   ├── credit_gem.gd               ⭐ CRIAR
│   │   ├── rapid_fire_buff.gd          ⭐ CRIAR
│   │   ├── score_multiplier_buff.gd    ⭐ CRIAR
│   │   ├── smart_bomb.gd               ⭐ CRIAR
│   │   └── power_up_factory.gd         ⭐ CRIAR
│   │
│   ├── shop/                            ⭐ NOVO DIRETÓRIO
│   │   ├── shop_manager.gd             ⭐ CRIAR
│   │   ├── shop_item.gd                ⭐ CRIAR (data class)
│   │   ├── shop_database.gd            ⭐ CRIAR
│   │   ├── upgrade_manager.gd          ⭐ CRIAR
│   │   └── credit_manager.gd           ⭐ CRIAR (ou extend GameController)
│   │
│   ├── game_controller.gd              ✏️ MODIFICAR (add credits)
│   ├── wave_manager.gd                 ✏️ MODIFICAR (shop trigger)
│   ├── player_controller.gd            ✏️ MODIFICAR (upgrade methods)
│   └── enemy_base.gd                   ✏️ MODIFICAR (spawn power-ups)
│
├── scenes/
│   │
│   ├── pickups/                         ⭐ NOVO DIRETÓRIO
│   │   ├── power_up_base.tscn          ⭐ CRIAR (Area2D template)
│   │   ├── health_pickup.tscn          ⭐ CRIAR
│   │   ├── credit_gem.tscn             ⭐ CRIAR
│   │   └── ammo_refill.tscn            ⭐ CRIAR
│   │
│   └── ui/
│       ├── shop_menu.tscn               ⭐ CRIAR
│       ├── shop_item_card.tscn          ⭐ CRIAR (component)
│       └── wave_summary.tscn            ⭐ CRIAR
│
├── ui/
│   ├── shop_ui.gd                       ⭐ CRIAR
│   ├── shop_item_card.gd                ⭐ CRIAR
│   ├── credit_display.gd                ⭐ CRIAR (HUD component)
│   ├── buff_indicator.gd                ⭐ CRIAR (HUD component)
│   └── game_hud.gd                      ✏️ MODIFICAR (add credits display)
│
├── assets/
│   ├── sprites/
│   │   └── pickups/                     ⭐ NOVO DIRETÓRIO
│   │       ├── health.png               🎨 CRIAR
│   │       ├── shield.png               🎨 CRIAR
│   │       ├── ammo.png                 🎨 CRIAR
│   │       ├── credit_small.png         🎨 CRIAR
│   │       ├── credit_medium.png        🎨 CRIAR
│   │       └── credit_large.png         🎨 CRIAR
│   │
│   └── audio/
│       └── sfx/
│           ├── pickup_health.ogg        🔊 CRIAR
│           ├── pickup_credit.ogg        🔊 CRIAR
│           ├── shop_purchase.ogg        🔊 CRIAR
│           └── shop_open.ogg            🔊 CRIAR
│
└── ECONOMY_SYSTEM_DESIGN.md             📄 ESTE ARQUIVO
```

### Arquivos Existentes a Modificar

**`scripts/game_controller.gd`:**
```gdscript
# Adicionar sistema de créditos
var current_credits: int = 0

func add_credits(amount: int) -> void:
    # ...

func spend_credits(amount: int) -> bool:
    # ...
```

**`scripts/wave_manager.gd`:**
```gdscript
func _complete_wave() -> void:
    # Existing code...
    wave_completed.emit(current_wave)

    # NOVO: Abrir loja
    await get_tree().create_timer(2.0).timeout
    ShopManager.open_shop()
    await ShopManager.shop_closed

    _start_next_wave()
```

**`scripts/player_controller.gd`:**
```gdscript
# Adicionar métodos de upgrade
func modify_max_health(bonus: int) -> void: ...
func modify_damage_multiplier(mult: float) -> void: ...
func modify_fire_rate_multiplier(mult: float) -> void: ...
# ... etc
```

**`scripts/enemy_base.gd`:**
```gdscript
func _spawn_powerup() -> void:
    # Substituir placeholder por factory call
    var powerup = PowerUpFactory.create(type)
    # ...
```

**`ui/game_hud.gd`:**
```gdscript
# Adicionar display de créditos
var credit_display: CreditDisplay

func _ready():
    # ...
    GameController.credits_changed.connect(_on_credits_changed)

func _on_credits_changed(new_credits: int, delta: int):
    credit_display.update(new_credits, delta)
```

---

## 🗺️ Roadmap de Implementação

### FASE 1: Power-Ups Básicos (3-4 horas) 🔴 ALTA PRIORIDADE

**Objetivo:** Power-ups funcionais caindo de inimigos

**Tarefas:**

```
□ 1.1 Criar PowerUpBase.gd (Area2D com lógica de coleta)
      - Area2D com collision shape
      - Timer de despawn (15s)
      - Fade out nos últimos 3s
      - collect() method
      - Signals: collected, despawned

□ 1.2 Criar HealthPickup.gd extends PowerUpBase
      - Efeito: player.health.heal(30)
      - Visual: Sprite2D verde (cruz)
      - Partículas: Green sparkle ao coletar

□ 1.3 Criar CreditGem.gd extends PowerUpBase
      - 3 variantes: Small (25), Medium (50), Large (100)
      - Efeito: GameController.add_credits(value)
      - Visual: Diamante cyan (tamanhos variados)

□ 1.4 Criar AmmoRefill.gd extends PowerUpBase
      - Efeito: player refill_ammo(secondary: 10, special: 2)
      - Visual: Caixa amarela

□ 1.5 Criar PowerUpFactory.gd
      - create(type: String) -> PowerUpBase
      - Weighted random selection
      - Preload de todas scenes

□ 1.6 Modificar enemy_base.gd _spawn_powerup()
      - Substituir print() por PowerUpFactory.create()
      - Adicionar ao PickupsContainer group
      - Testar drop rates

□ 1.7 Criar PickupsContainer node no main_game.tscn
      - Node2D para organizar pickups
      - Add to group "PickupsContainer"

□ 1.8 Testar sistema completo
      - Drops aparecem?
      - Coleta funciona?
      - Efeitos aplicam?
      - Despawn funciona?
```

**Arquivos Criados:**
- `scripts/pickups/power_up_base.gd`
- `scripts/pickups/health_pickup.gd`
- `scripts/pickups/credit_gem.gd`
- `scripts/pickups/ammo_refill.gd`
- `scripts/pickups/power_up_factory.gd`

**Arquivos Modificados:**
- `scripts/enemy_base.gd`
- `scenes/main_game.tscn`

**Deliverable:** Power-ups básicos funcionando (Health, Credits, Ammo)

---

### FASE 2: Sistema de Créditos (2 horas) 🔴 ALTA PRIORIDADE

**Objetivo:** Moeda funcional acumulando e sendo exibida

**Tarefas:**

```
□ 2.1 Criar CreditManager.gd (ou extend GameController)
      - var current_credits: int = 0
      - signal credits_changed(new, delta)
      - add_credits(amount)
      - spend_credits(amount) -> bool
      - can_afford(cost) -> bool

□ 2.2 Modificar GameController para incluir credits
      - Integrar CreditManager
      - Save/load credits (reset on new game)

□ 2.3 Modificar enemy_base.gd para dar créditos
      - Ao morrer: drop credits = score_value * 0.5
      - Chamar GameController.add_credits()

□ 2.4 Adicionar wave completion bonuses
      - WaveManager: ao completar wave
      - Bonus: 200 + (wave_number * 100) credits

□ 2.5 Criar CreditDisplay.gd (HUD component)
      - Label mostrando: "💎 1,250"
      - Animação ao ganhar/gastar
      - Connect a credits_changed signal

□ 2.6 Adicionar CreditDisplay à game_hud.tscn
      - Posicionar no canto superior direito
      - Integrar com HUD existente

□ 2.7 Testar sistema de créditos
      - Matar inimigo → ganha credits?
      - Wave complete → bonus?
      - UI atualiza corretamente?
      - Animações funcionam?
```

**Arquivos Criados:**
- `scripts/shop/credit_manager.gd`
- `ui/credit_display.gd`

**Arquivos Modificados:**
- `scripts/game_controller.gd`
- `scripts/enemy_base.gd`
- `scripts/wave_manager.gd`
- `ui/game_hud.gd`
- `scenes/ui/game_hud.tscn`

**Deliverable:** Sistema de créditos funcional com UI

---

### FASE 3: Shop UI Básica (4-5 horas) 🔴 ALTA PRIORIDADE

**Objetivo:** Loja abrindo entre waves com items compráveis

**Tarefas:**

```
□ 3.1 Criar ShopItem.gd (data class)
      - class_name ShopItem
      - Properties: id, name, description, cost, icon, category
      - max_purchases, current_purchases
      - effect: Callable

□ 3.2 Criar ShopDatabase.gd
      - Hardcode 10-15 items iniciais
      - Tier 1: Health, Damage, Fire Rate, Speed
      - Tier 2: 2-3 specials
      - Consumables: Shield, Score 2x
      - get_items_by_category()

□ 3.3 Criar shop_menu.tscn (UI overlay)
      - CanvasLayer para overlay
      - Panel semi-transparent background
      - Title: "🏪 WAVE SHOP"
      - Credits display
      - Tab buttons (4 categories)
      - Grid container (3×3)
      - Ready button

□ 3.4 Criar ShopItemCard.tscn (component)
      - Panel container
      - Icon (TextureRect)
      - Name label
      - Cost label
      - Buy button
      - Stack indicator (X/Max)
      - Tooltip on hover

□ 3.5 Criar ShopUI.gd (controller)
      - Populate grid com items
      - Handle tab switching
      - Handle purchase clicks
      - Validate purchases
      - Update UI após compra

□ 3.6 Criar ShopManager.gd (singleton autoload)
      - open_shop()
      - close_shop()
      - signal shop_closed
      - Pausar jogo ao abrir
      - Resume ao fechar

□ 3.7 Modificar WaveManager.gd
      - Após wave complete:
      - await timer(2s)
      - ShopManager.open_shop()
      - await shop_closed
      - start_next_wave()

□ 3.8 Testar shop flow
      - Loja abre após wave?
      - Items aparecem?
      - Pode comprar?
      - Créditos deduziram?
      - Loja fecha corretamente?
```

**Arquivos Criados:**
- `scripts/shop/shop_item.gd`
- `scripts/shop/shop_database.gd`
- `scripts/shop/shop_manager.gd`
- `ui/shop_ui.gd`
- `ui/shop_item_card.gd`
- `scenes/ui/shop_menu.tscn`
- `scenes/ui/shop_item_card.tscn`

**Arquivos Modificados:**
- `scripts/wave_manager.gd`
- `project.godot` (autoload ShopManager)

**Deliverable:** Loja funcional com compra de items

---

### FASE 4: Upgrade Manager (3 horas) 🟡 MÉDIA PRIORIDADE

**Objetivo:** Upgrades aplicando ao player e persistindo

**Tarefas:**

```
□ 4.1 Criar upgrade_manager.gd
      - Ver código completo na seção "Sistema de Upgrades"
      - Tracking de purchased_upgrades
      - purchase_upgrade(id, cost)
      - apply_upgrade_to_player(id)
      - can_stack_upgrade(id)

□ 4.2 Adicionar métodos ao player_controller.gd
      - modify_max_health(bonus)
      - modify_damage_multiplier(mult)
      - modify_fire_rate_multiplier(mult)
      - modify_speed_multiplier(mult)
      - modify_projectile_size(mult)
      - modify_pickup_range(mult)
      - modify_iframe_duration(bonus)
      - enable_regeneration(rate)
      - enable_piercing(count)
      - enable_homing_primary()

□ 4.3 Integrar UpgradeManager com ShopUI
      - Ao clicar Buy:
      - UpgradeManager.purchase_upgrade(id, cost)
      - Update item card UI (stack count)

□ 4.4 Implementar consumíveis (buffs temporários)
      - activate_consumable(buff_id, duration)
      - active_buffs dictionary
      - check_expired_buffs() ao iniciar wave
      - Criar BuffIndicator UI component

□ 4.5 Criar BuffIndicator.gd (HUD component)
      - Mostra buffs ativos com timer
      - Icons + countdown
      - Fade out ao expirar

□ 4.6 Adicionar reset no game over
      - GameController._on_game_over():
      - UpgradeManager.reset_all_upgrades()

□ 4.7 Testar persistência
      - Comprar upgrade → aplicou?
      - Stats mudaram?
      - Persiste entre waves?
      - Reseta no game over?
      - Consumíveis expiram?
```

**Arquivos Criados:**
- `scripts/shop/upgrade_manager.gd`
- `ui/buff_indicator.gd`

**Arquivos Modificados:**
- `scripts/player_controller.gd`
- `scripts/game_controller.gd`
- `ui/shop_ui.gd`
- `ui/game_hud.gd`

**Deliverable:** Sistema de upgrades completo e funcional

---

### FASE 5: Power-Ups Avançados (3 horas) 🟡 MÉDIA PRIORIDADE

**Objetivo:** Todos os 7 tipos de power-ups funcionando

**Tarefas:**

```
□ 5.1 Criar ShieldPickup.gd
      - Efeito: player.add_temporary_health(50)
      - Visual: Hexágono azul
      - Duração: 30s ou até quebrar

□ 5.2 Criar RapidFireBuff.gd
      - Efeito: player.modify_fire_rate(1.5) por 20s
      - Visual: Relâmpago laranja
      - Timer countdown na HUD

□ 5.3 Criar ScoreMultiplierBuff.gd
      - Efeito: player.score.set_multiplier(2.0) por 30s
      - Visual: Estrela dourada
      - UI: "2X SCORE" banner

□ 5.4 Criar SmartBomb.gd
      - Efeito: kill_all_enemies_on_screen()
      - Visual: Bomba roxa
      - Ativação: Imediata ao coletar
      - Screen shake + particles

□ 5.5 Adicionar variants de CreditGem
      - Small, Medium, Large
      - Tamanhos e valores diferentes

□ 5.6 Implementar timed buffs system
      - BuffManager component
      - Track active buffs com timers
      - Apply/remove effects
      - UI indicators

□ 5.7 Ajustar PowerUpFactory.gd
      - Adicionar todos os novos tipos
      - Weighted random com raridades corretas
      - Testar drop rates

□ 5.8 Testar cada power-up
      - Visual correto?
      - Efeito funciona?
      - Timer funciona (se aplicável)?
      - Despawn correto?
```

**Arquivos Criados:**
- `scripts/pickups/shield_pickup.gd`
- `scripts/pickups/rapid_fire_buff.gd`
- `scripts/pickups/score_multiplier_buff.gd`
- `scripts/pickups/smart_bomb.gd`

**Arquivos Modificados:**
- `scripts/pickups/power_up_factory.gd`
- `scripts/pickups/credit_gem.gd`

**Deliverable:** 7 tipos de power-ups completos

---

### FASE 6: Polish & Balance (4 horas) ⚪ BAIXA PRIORIDADE

**Objetivo:** Sistema polido, balanceado e com feedback audiovisual

**Tarefas:**

```
□ 6.1 Criar sprites finais dos power-ups
      - Health: Cruz verde neon
      - Shield: Hexágono azul
      - Ammo: Caixa amarela
      - Credits: Diamantes cyan (3 tamanhos)
      - Rapid Fire: Relâmpago laranja
      - Score 2x: Estrela dourada
      - Smart Bomb: Bomba roxa

□ 6.2 Adicionar partículas de coleta
      - Cada tipo tem partículas únicas
      - Explosão de cor ao coletar
      - Trail magnético ao atrair

□ 6.3 Implementar magnetismo de pickups
      - Raio base: 100px
      - Lerp suave até player
      - Upgrade de "Pickup Range" aumenta raio

□ 6.4 Adicionar sons
      - pickup_health.ogg
      - pickup_credit.ogg (pitch varia por tamanho)
      - pickup_powerup.ogg
      - shop_purchase.ogg
      - shop_open.ogg
      - shop_error.ogg (sem créditos)

□ 6.5 Balancear custos dos items
      - Playtest 3-5 runs
      - Ajustar preços baseado em feedback
      - Garantir que builds diferentes são viáveis

□ 6.6 Balancear drop rates
      - Playtest drop frequency
      - Ajustar percentagens
      - Garantir economia balanceada

□ 6.7 Criar tooltips/help
      - Hover em item mostra tooltip
      - Primeira vez na loja: tutorial popup
      - Key hints (ESC para fechar, etc)

□ 6.8 Adicionar juice à loja
      - Animação de entrada (slide up)
      - Hover effects nos botões
      - Purchase animation (coin burst)
      - Tab switch animation

□ 6.9 Playtest completo
      - 5-10 runs completas
      - Testar todos builds
      - Encontrar bugs
      - Ajustar balance final

□ 6.10 Documentar para jogadores
      - Criar tutorial in-game
      - Tooltips explicativos
      - Atualizar IMPLEMENTATION_STATUS.md
```

**Arquivos Criados:**
- Sprites em `assets/sprites/pickups/`
- Sons em `assets/audio/sfx/`

**Arquivos Modificados:**
- Todos os pickup scripts (add particles)
- `ui/shop_ui.gd` (add animations)
- `scripts/pickups/power_up_base.gd` (add magnetism)

**Deliverable:** Sistema completo, polido e balanceado

---

## ⏱️ Estimativas Totais

```
┌─────────────────────────────────────────────────────┐
│              TEMPO DE IMPLEMENTAÇÃO                 │
├─────────────────────────────────────────────────────┤
│ FASE 1: Power-Ups Básicos          │ 3-4 horas     │
│ FASE 2: Sistema de Créditos         │ 2 horas       │
│ FASE 3: Shop UI Básica              │ 4-5 horas     │
│ FASE 4: Upgrade Manager             │ 3 horas       │
│ FASE 5: Power-Ups Avançados         │ 3 horas       │
│ FASE 6: Polish & Balance            │ 4 horas       │
├─────────────────────────────────────────────────────┤
│ TOTAL ESTIMADO:                     │ 19-23 horas   │
└─────────────────────────────────────────────────────┘

Prioridades:
🔴 ALTA (Fases 1-3):    9-11 horas → Core funcional
🟡 MÉDIA (Fases 4-5):   6 horas    → Features completas
⚪ BAIXA (Fase 6):      4 horas    → Polish final
```

---

## ✅ Decisões de Design Finalizadas

### 1. Modelo de Moeda
**Decisão:** Sistema Dual (Score + Credits)

**Justificativa:**
- Score preserva propósito competitivo (high score, rankings)
- Credits dá liberdade para gastar sem "perder pontos"
- Separação clara de propósitos
- Permite balancear economia independentemente

### 2. Frequência da Loja
**Decisão:** Após cada wave (Waves 1-9)

**Justificativa:**
- Progressão constante e satisfatória
- Mais oportunidades de escolha estratégica
- Evita frustrações (morrer logo antes de loja)
- Mais engajamento do jogador

**Alternativa rejeitada:** Só em waves pares
- Menos flexibilidade
- Maior gap entre upgrades

### 3. Persistência de Upgrades
**Decisão:** Persistem entre waves, resetam no game over

**Justificativa:**
- Roguelite clássico (cada run é única)
- Incentiva replay value
- Evita power creep entre jogos
- Builds diferentes cada vez

**Alternativa rejeitada:** Persistem para sempre
- Jogador ficaria OP demais
- Sem replay value

### 4. Starting Budget
**Decisão:** 0 créditos iniciais

**Justificativa:**
- Primeira loja após Wave 1 (~600 credits disponíveis)
- Força wave 1 com loadout puro (skill-based)
- Primeira compra é mais impactante

**Alternativa rejeitada:** 500 credits iniciais
- Muito fácil, sem desafio

### 5. Power-Up Drops
**Decisão:** Weighted by rarity (15% base chance)

**Distribuição:**
- Comum (65%): Health, Shield
- Incomum (20%): Ammo, Credits Small
- Raro (13%): Rapid Fire, Score 2x, Credits Medium
- Muito Raro (2%): Smart Bomb, Credits Large

**Justificativa:**
- Balance entre utilidade e excitement
- Raros são reward especial
- Credits são parte do core loop

### 6. Shop Timer
**Decisão:** Opcional (60s), pode desabilitar

**Justificativa:**
- Adiciona pressure (speed runners)
- Mas pode frustrar jogadores casuais
- Deixar como opção de dificuldade

### 7. Stacking Limits
**Decisão:** Variável por upgrade (3-10 stacks)

**Justificativa:**
- Previne single-stat domination
- Força diversificação de builds
- Balance matemático (+50% é cap razoável)

### 8. Consumable Duration
**Decisão:** 1 wave (até wave end)

**Justificativa:**
- Simples de entender
- Fácil de implementar
- Strategic timing importante

**Alternativa rejeitada:** Timer real (30s-60s)
- Complexo de balancear
- Pode expirar em bad timing

---

## 📝 Notas de Implementação

### Performance Considerations

**Object Pooling:**
- Power-ups devem usar pool (spawn/despawn frequente)
- Pool size: 50 pickups simultâneos
- Preload todas as scenes na inicialização

**UI Updates:**
- Shop UI só atualiza quando aberta
- Credits display usa signal (não poll)
- Buff indicators usam timer optimizado

### Save Data

**Não persistir entre jogos:**
- Current credits
- Purchased upgrades
- Active buffs

**Persistir entre jogos:**
- High score
- Unlocked pilots/ships (se implementar unlock system futuro)

### Debug Tools

**Recomendado criar:**
- Cheat menu (F12):
  - Add 1000 credits
  - Unlock all upgrades
  - Spawn specific power-up
  - Skip to wave X
- Balance spreadsheet tracker

### Extensibilidade Futura

Sistema foi projetado para fácil extensão:

**Novos Power-Ups:**
1. Criar script extends PowerUpBase
2. Adicionar ao PowerUpFactory
3. Ajustar weight no random

**Novos Upgrades:**
1. Adicionar entry no ShopDatabase
2. Adicionar case no UpgradeManager.apply_upgrade()
3. Implementar method no player

**Novos Pilots/Ships:**
- Já compatível com sistema existente
- Modifiers se aplicam sobre upgrades

---

## 🎮 Exemplo de Gameplay Loop

```
┌─────────────────────────────────────────────────────┐
│                  UMA RUN TÍPICA                     │
├─────────────────────────────────────────────────────┤
│ Pilot: I.N.D.I.O (+25% primary dmg, +15% fire rate)│
│ Ship: Falcon (balanced)                             │
│ Weapons: Spread Shot, Homing Missile, Railgun      │
└─────────────────────────────────────────────────────┘

Wave 1: 5 Basic enemies
  - Kill 5 → Earn ~250 score, ~125 credits
  - Drop 1 health pickup (didn't need)
  - Wave bonus: +200 credits
  - Total: 325 credits

  🏪 SHOP #1
  - Buy: Health Boost (+10 HP) - 100💎
  - Buy: Damage Boost (+5%) - 150💎
  - Remaining: 75💎
  - Stats: 110 HP, 10.5 dmg base

Wave 2: 8 Basic + 2 Fast
  - Kill all → Earn ~500 score, ~250 credits
  - Drop 2 credit gems (small) → +50💎
  - Wave bonus: +300💎
  - Total: 675💎

  🏪 SHOP #2
  - Buy: Health Boost x2 (+20 HP) - 200💎
  - Buy: Fire Rate (+10%) - 200💎
  - Buy: Shield (1 wave) - 300💎
  - Remaining: 0💎
  - Stats: 130 HP, 10.5 dmg, 1.1× fire, +50 shield

Wave 3: Mixed + Shooting Tanks
  - Shield absorbs 2 hits
  - Kill all → Earn ~800 score, ~400 credits
  - Combo 15x → +50💎
  - Drop rapid fire buff → Melts tank instantly!
  - Wave bonus: +400💎
  - Total: 850💎

  🏪 SHOP #3
  - Buy: Damage Boost x3 (+15% total) - 450💎
  - Buy: Pickup Range (+20%) - 150💎
  - Buy: Ammo Refill - 150💎
  - Remaining: 100💎
  - Stats: 130 HP, 12.1 dmg, 1.1× fire, 1.2× pickup

Wave 4-5: Continue building...
  - By Wave 5: Full tier 1 upgrades
  - Start buying consumables
  - Save for Extra Life

Wave 10 (Boss):
  - Stats: 170 HP, 15 dmg, 1.5× fire, 1.3× speed
  - Has 1 Extra Life
  - Multiple consumables active
  - Victory! 🎉
```

---

## 🔗 Referências & Inspirações

### Jogos Similares

- **Vampire Survivors:** Economy loop, upgrade variety
- **Binding of Isaac:** Item synergies, build diversity
- **Hades:** Shop between stages, permanent upgrades
- **Risk of Rain:** Stacking items, exponential power
- **Enter the Gungeon:** Shop system, currency vs items

### Design Patterns Usados

- **Factory Pattern:** PowerUpFactory
- **Observer Pattern:** Signals para credits_changed
- **Strategy Pattern:** ShopItem effect callbacks
- **Singleton Pattern:** ShopManager autoload
- **Component Pattern:** UpgradeManager, CreditManager

---

## 📞 Contato & Updates

**Documento criado:** 2026-01-02
**Última atualização:** 2026-01-02
**Autor:** Claude Code
**Status:** 📋 Planejamento Completo

**Para futuras sessões:**
1. Ler este documento completo
2. Verificar IMPLEMENTATION_STATUS.md para status atual
3. Escolher uma FASE do roadmap
4. Seguir checklist da fase
5. Marcar tarefas completas
6. Atualizar este documento com learnings

---

## ✨ Conclusão

Este sistema de economia e progressão foi projetado para:

✅ Integrar perfeitamente com arquitetura existente
✅ Criar loop de progressão satisfatório
✅ Dar escolhas significativas ao jogador
✅ Aumentar replay value
✅ Ser extensível para futuras features

**Próximo passo sugerido:** Começar pela **FASE 1** (Power-Ups Básicos)

Boa implementação! 🚀
