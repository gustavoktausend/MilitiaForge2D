# Plano de Customização - Sistema de Seleção de Naves

## Visão Geral

Este documento detalha o plano para expandir o sistema de seleção de naves, adicionando:
1. Sistema de Seleção de Pilotos com bônus
2. Sistema de Customização de Cores das Naves

---

## 1. Sistema de Seleção de Pilotos

### 1.1 Conceito

Adicionar uma tela/seção onde o jogador escolhe um piloto que traz bônus passivos para a nave. Isso adiciona uma camada extra de estratégia e personalização.

### 1.2 Estrutura de Dados

**PilotConfig.gd** (novo Resource)
```gdscript
class_name PilotConfig extends Resource

@export_group("Identity")
@export var pilot_name: String = "Pilot"
@export_multiline var description: String = "A skilled pilot"
@export var pilot_portrait: Texture2D  # Avatar/foto do piloto

@export_group("Bonuses")
# Bônus percentuais (multiplicadores)
@export_range(0.0, 2.0, 0.05) var speed_multiplier: float = 1.0
@export_range(0.0, 2.0, 0.05) var fire_rate_multiplier: float = 1.0
@export_range(0.0, 2.0, 0.05) var damage_multiplier: float = 1.0
@export_range(0.0, 2.0, 0.05) var health_multiplier: float = 1.0

# Habilidades especiais (para implementação futura)
@export var special_ability: String = ""  # Ex: "shield_regen", "double_shot", etc.
```

### 1.3 Exemplos de Pilotos

#### Piloto 1: "Ace" (Balanceado)
- Speed: 1.0x
- Fire Rate: 1.0x
- Damage: 1.0x
- Health: 1.0x
- Descrição: "Um piloto equilibrado, bom em todas as situações"

#### Piloto 2: "Gunner" (Foco em Ataque)
- Speed: 0.9x
- Fire Rate: 1.3x
- Damage: 1.2x
- Health: 0.95x
- Descrição: "Especialista em armamento pesado, sacrifica mobilidade por poder de fogo"

#### Piloto 3: "Scout" (Foco em Velocidade)
- Speed: 1.4x
- Fire Rate: 0.9x
- Damage: 0.85x
- Health: 0.9x
- Descrição: "Rápido e ágil, mas com menor poder de fogo"

#### Piloto 4: "Tank Commander" (Foco em Resistência)
- Speed: 0.85x
- Fire Rate: 0.95x
- Damage: 1.1x
- Health: 1.4x
- Descrição: "Duro de matar, aguenta muito dano"

### 1.4 Integração com PlayerData

```gdscript
# Adicionar ao PlayerData.gd
var selected_pilot_config: PilotConfig
var available_pilots: Array[PilotConfig] = []

func _ready() -> void:
    _load_available_ships()
    _load_available_pilots()  # NOVO

func _load_available_pilots() -> void:
    available_pilots = [
        load("res://examples/space_shooter/resources/pilots/pilot_ace.tres"),
        load("res://examples/space_shooter/resources/pilots/pilot_gunner.tres"),
        load("res://examples/space_shooter/resources/pilots/pilot_scout.tres"),
        load("res://examples/space_shooter/resources/pilots/pilot_tank.tres")
    ]
    # Selecionar piloto padrão se não houver seleção
    if not selected_pilot_config:
        selected_pilot_config = available_pilots[0]
```

### 1.5 Aplicação dos Bônus

**Modificar player_controller.gd:**
```gdscript
func _apply_ship_config() -> void:
    if ship_config:
        var pilot_multipliers = _get_pilot_multipliers()

        move_speed = ship_config.speed * pilot_multipliers.speed
        max_health = int(ship_config.max_health * pilot_multipliers.health)
        fire_rate = ship_config.get_fire_cooldown() / pilot_multipliers.fire_rate
        projectile_damage = int(ship_config.weapon_damage * pilot_multipliers.damage)
        projectile_speed = ship_config.projectile_speed

func _get_pilot_multipliers() -> Dictionary:
    var multipliers = {
        "speed": 1.0,
        "health": 1.0,
        "fire_rate": 1.0,
        "damage": 1.0
    }

    if has_node("/root/PlayerData"):
        var player_data = get_node("/root/PlayerData")
        var pilot = player_data.selected_pilot_config
        if pilot:
            multipliers.speed = pilot.speed_multiplier
            multipliers.health = pilot.health_multiplier
            multipliers.fire_rate = pilot.fire_rate_multiplier
            multipliers.damage = pilot.damage_multiplier

    return multipliers
```

### 1.6 Interface de Seleção de Piloto

**Opção A: Tela Separada (Recomendado)**
- Main Menu → **Pilot Selection** → Ship Selection → Game
- Permite escolher piloto antes da nave
- Mostra como os bônus do piloto afetarão cada nave

**Opção B: Mesma Tela (Mais Compacto)**
- Split screen: Esquerda = Pilot, Direita = Ship
- Escolhe ambos na mesma tela
- Mostra stats finais (nave + piloto)

**Opção C: Abas (Tab-based)**
- Tab 1: Escolher Piloto
- Tab 2: Escolher Nave
- Tab 3: Review (resumo final)

### 1.7 UI Mockup (Opção A)

```
┌─────────────────────────────────────────┐
│        SELECT YOUR PILOT                │
├─────────────────────────────────────────┤
│                                         │
│         [PILOT PORTRAIT]                │
│                                         │
│            Ace                          │
│   "A balanced pilot, good in all       │
│         situations"                     │
│                                         │
│  Bonuses:                               │
│  • Speed: +0%                           │
│  • Fire Rate: +0%                       │
│  • Damage: +0%                          │
│  • Health: +0%                          │
│                                         │
│      [< PREV]     [NEXT >]             │
│                                         │
│         [CONTINUE]                      │
└─────────────────────────────────────────┘
```

---

## 2. Sistema de Customização de Cores

### 2.1 Conceito

Permitir que o jogador altere a cor (tint) da nave selecionada em tempo real na interface de seleção. Isso torna cada jogador único mesmo usando a mesma nave.

### 2.2 Abordagens Possíveis

#### Abordagem A: Color Picker Completo
- **Prós**: Liberdade total de customização
- **Contras**: Pode gerar combinações feias, UI mais complexa
- **Implementação**: ColorPickerButton do Godot

#### Abordagem B: Paleta Pré-definida (Recomendado)
- **Prós**: Cores sempre harmônicas, UI mais limpa e clara
- **Contras**: Menos liberdade
- **Implementação**: Botões com cores pré-definidas

#### Abordagem C: Sliders HSV
- **Prós**: Controle preciso, menos caótico que color picker
- **Contras**: Pode ser complexo para usuários casuais
- **Implementação**: 3 sliders (Hue, Saturation, Value)

### 2.3 Recomendação: Paleta Pré-definida + Slider de Intensidade

**Cores Base Disponíveis:**
```gdscript
const COLOR_PRESETS = [
    Color(1.0, 1.0, 1.0),      # Branco (Original)
    Color(1.0, 0.3, 0.3),      # Vermelho
    Color(0.3, 1.0, 0.3),      # Verde
    Color(0.3, 0.3, 1.0),      # Azul
    Color(1.0, 1.0, 0.3),      # Amarelo
    Color(1.0, 0.3, 1.0),      # Magenta
    Color(0.3, 1.0, 1.0),      # Ciano
    Color(1.0, 0.6, 0.2),      # Laranja
    Color(0.6, 0.3, 1.0),      # Roxo
    Color(1.0, 0.8, 0.5),      # Dourado
]
```

**Slider de Intensidade:**
- Range: 0.5 a 1.5
- Multiplica o RGB da cor selecionada
- Permite tons mais claros ou mais escuros

### 2.4 Estrutura de Dados

**Adicionar ao ShipConfig.gd:**
```gdscript
# Remover ship_tint do ShipConfig (será escolhido pelo jogador)
# OU manter como "tint padrão sugerido"
```

**Adicionar ao PlayerData.gd:**
```gdscript
# Armazenar a escolha de cor do jogador
var selected_ship_color: Color = Color.WHITE
var selected_color_intensity: float = 1.0
```

### 2.5 UI Mockup para Seleção de Cor

```
┌─────────────────────────────────────────┐
│        SELECT YOUR SHIP                 │
├─────────────────────────────────────────┤
│                                         │
│         [SHIP SPRITE]                   │
│        (com cor aplicada)               │
│                                         │
│           Interceptor                   │
│   "Fast and agile..."                   │
│                                         │
│  Stats: Health: 70, Speed: 450...      │
│                                         │
│  ┌─── Ship Color ───┐                  │
│  │ [⚪][🔴][🟢][🔵] │                  │
│  │ [🟡][🟣][🔶][⚫] │                  │
│  └──────────────────┘                  │
│                                         │
│  Intensity: [====|====] 1.0x           │
│                                         │
│      [< PREV]     [NEXT >]             │
│         [START GAME]                    │
└─────────────────────────────────────────┘
```

### 2.6 Implementação da UI de Cores

**ship_selection_ui.gd - Adicionar:**
```gdscript
# Color selection
var color_buttons: Array[Button] = []
var selected_color: Color = Color.WHITE
var color_intensity: float = 1.0

@onready var color_container: GridContainer = $VBoxContainer/ColorContainer
@onready var intensity_slider: HSlider = $VBoxContainer/IntensitySlider

const COLOR_PRESETS = [
    Color(1.0, 1.0, 1.0),
    Color(1.0, 0.3, 0.3),
    Color(0.3, 1.0, 0.3),
    Color(0.3, 0.3, 1.0),
    Color(1.0, 1.0, 0.3),
    Color(1.0, 0.3, 1.0),
    Color(0.3, 1.0, 1.0),
    Color(1.0, 0.6, 0.2),
]

func _create_color_buttons() -> void:
    for i in range(COLOR_PRESETS.size()):
        var btn = Button.new()
        btn.custom_minimum_size = Vector2(40, 40)

        # Style with color
        var style = StyleBoxFlat.new()
        style.bg_color = COLOR_PRESETS[i]
        style.set_corner_radius_all(5)
        btn.add_theme_stylebox_override("normal", style)

        btn.pressed.connect(_on_color_selected.bind(i))
        color_container.add_child(btn)
        color_buttons.append(btn)

func _on_color_selected(index: int) -> void:
    selected_color = COLOR_PRESETS[index]
    _update_ship_color()

func _on_intensity_changed(value: float) -> void:
    color_intensity = value
    _update_ship_color()

func _update_ship_color() -> void:
    var final_color = selected_color * color_intensity
    ship_sprite.modulate = final_color

    # Save to PlayerData
    if has_node("/root/PlayerData"):
        var player_data = get_node("/root/PlayerData")
        player_data.selected_ship_color = selected_color
        player_data.selected_color_intensity = color_intensity
```

### 2.7 Aplicar Cor no Jogo

**player_controller.gd - Modificar _setup_visuals():**
```gdscript
func _setup_visuals() -> void:
    var sprite_texture: Texture2D = null
    var ship_scale_mult: float = 1.0
    var ship_color: Color = Color.WHITE

    if ship_config and ship_config.ship_sprite:
        sprite_texture = ship_config.ship_sprite
        ship_scale_mult = ship_config.ship_scale

        # Carregar cor customizada do PlayerData
        if has_node("/root/PlayerData"):
            var player_data = get_node("/root/PlayerData")
            if player_data.selected_ship_color:
                ship_color = player_data.selected_ship_color * player_data.selected_color_intensity
            else:
                ship_color = ship_config.ship_tint  # Fallback para cor padrão
        else:
            ship_color = ship_config.ship_tint

    # ... resto do código
```

---

## 3. Fluxo Atualizado

### Opção A: Separado (Recomendado para primeira iteração)
```
Main Menu
    ↓
Pilot Selection (nova tela)
    ↓
Ship Selection (já existe, adicionar cores)
    ↓
Game
```

### Opção B: Unificado (Mais complexo, mas melhor UX)
```
Main Menu
    ↓
Loadout Selection (tela combinada)
    - Tab 1: Pilot
    - Tab 2: Ship
    - Tab 3: Colors
    - Review Panel (mostra stats finais)
    ↓
Game
```

---

## 4. Ordem de Implementação Sugerida

### Fase 1: Sistema de Cores (Mais Simples)
1. ✅ Adicionar campo `selected_ship_color` ao PlayerData
2. ✅ Criar paleta de cores pré-definidas
3. ✅ Adicionar GridContainer de cores na ship_selection.tscn
4. ✅ Implementar seleção de cor na UI
5. ✅ Adicionar slider de intensidade (opcional)
6. ✅ Aplicar cor customizada no player_controller
7. ✅ Testar com todas as naves

### Fase 2: Sistema de Pilotos
1. ✅ Criar PilotConfig.gd (Resource)
2. ✅ Criar 3-4 pilotos exemplo (.tres)
3. ✅ Adicionar suporte no PlayerData
4. ✅ Criar pilot_selection_ui.gd
5. ✅ Criar pilot_selection.tscn
6. ✅ Integrar na sequência de telas
7. ✅ Modificar player_controller para aplicar multiplicadores
8. ✅ Testar combinações nave + piloto
9. ⏳ (Futuro) Adicionar habilidades especiais

---

## 5. Considerações Técnicas

### 5.1 Performance
- Aplicar cores via `modulate` é muito eficiente (shader nativo)
- Multiplicadores de piloto são calculados apenas no _ready()
- Sem impacto significativo no desempenho

### 5.2 Balanceamento
- Pilotos devem ser sidegrades, não upgrades
- Cada piloto deve ter trade-offs claros
- Total de multiplicadores deve somar ~4.0 (média 1.0 por stat)

### 5.3 Extensibilidade
- Sistema de pilotos preparado para habilidades especiais futuras
- Sistema de cores pode evoluir para skins/padrões
- PlayerData centralizado facilita save/load

### 5.4 UX
- Preview em tempo real é essencial
- Mostrar stats finais (base + bônus) ajuda na decisão
- Permitir voltar e mudar escolhas antes de iniciar

---

## 6. Questões para Decisão

### 6.1 Sistema de Pilotos
- [ ] Quantos pilotos inicialmente? (Sugestão: 4)
- [ ] Pilotos devem ter portraits? (Opcional mas recomendado)
- [ ] Implementar habilidades especiais agora ou depois? (Depois)
- [ ] Tela separada ou integrada com ship selection? (Separada primeiro)

### 6.2 Sistema de Cores
- [ ] Paleta pré-definida ou color picker livre? (Paleta pré-definida)
- [ ] Quantas cores oferecer? (Sugestão: 8-10)
- [ ] Adicionar slider de intensidade? (Sim, range 0.5-1.5)
- [ ] Permitir salvar cores favoritas? (Futuro)

### 6.3 Ordem de Implementação
- [ ] Começar por qual sistema? (Cores é mais simples)
- [ ] Implementar os dois antes de outras features? (Sim)
- [ ] Manter sistema de tint padrão das naves? (Sim, como sugestão)

---

## 7. Estimativa de Esforço

### Sistema de Cores
- **Complexidade**: Baixa
- **Tempo estimado**: ~2-3 horas
- **Arquivos novos**: 0 (apenas modificações)
- **Dependências**: Nenhuma

### Sistema de Pilotos
- **Complexidade**: Média
- **Tempo estimado**: ~4-6 horas
- **Arquivos novos**: ~6 (PilotConfig.gd, 4 .tres, pilot_selection_ui.gd, pilot_selection.tscn)
- **Dependências**: Nenhuma

### Total
- **Tempo total**: ~6-9 horas
- **Prioridade**: Média-Alta (melhora muito a rejogabilidade)

---

## 8. Próximos Passos

1. **Revisar este plano** e decidir sobre as questões abertas
2. **Escolher por onde começar** (Recomendação: Cores primeiro)
3. **Implementar fase 1** (Sistema de Cores)
4. **Testar e refinar**
5. **Implementar fase 2** (Sistema de Pilotos)
6. **Testar combinações**
7. **Balancear** (ajustar multiplicadores se necessário)
8. **Documentar** para usuários finais

---

**Autor**: Claude (MilitiaForge2D Assistant)
**Data**: 2025-12-26
**Versão**: 1.0
