# Guia de Criação da Cena spell_battle_hud.tscn

## Passo 1: Criar a Cena Base

1. Abra o Godot Editor
2. Clique em "Other Node" ou "New Scene"
3. Selecione **CanvasLayer** como root node
4. Renomeie para **SpellBattleHUD**
5. Anexe o script: `res://examples/spell_battle/ui/spell_battle_hud.gd`
6. No Inspector, configure:
   - **Layer**: 10 (para ficar acima do gameplay)

## Passo 2: Criar a Estrutura de Layout

### 2.1 MarginContainer (Root Layout)
1. Adicione **MarginContainer** como filho de SpellBattleHUD
2. Configure Anchors:
   - Anchor Preset: **Full Rect** (preencher tela toda)
3. Configure Margins no Inspector:
   - **Margin Left**: 20
   - **Margin Top**: 20
   - **Margin Right**: 20
   - **Margin Bottom**: 20

### 2.2 VBoxContainer (Main Layout)
1. Adicione **VBoxContainer** como filho de MarginContainer
2. Configure:
   - **Separation**: 15
   - Anchor Preset: **Full Rect**

## Passo 3: Criar TopBar (HP Bars)

### 3.1 TopBar HBoxContainer
1. Adicione **HBoxContainer** como filho de VBoxContainer
2. Renomeie para **TopBar**
3. Configure:
   - **Separation**: 40

### 3.2 PlayerHealthSection
1. Adicione **VBoxContainer** como filho de TopBar
2. Renomeie para **PlayerHealthSection**
3. Configure:
   - **Separation**: 8

#### 3.2.1 PlayerNameLabel
1. Adicione **Label** como filho de PlayerHealthSection
2. Renomeie para **PlayerNameLabel**
3. Configure:
   - **Text**: "MEGAMAN.EXE" (placeholder)
   - **Horizontal Alignment**: Center
   - **Theme Overrides** → **Colors** → **Font Color**: Cyan (RGB: 0, 240, 240)
   - **Theme Overrides** → **Colors** → **Font Outline Color**: Black
   - **Theme Overrides** → **Constants** → **Outline Size**: 2
   - **Theme Overrides** → **Font Sizes** → **Font Size**: 18

#### 3.2.2 PlayerHealthWidget
1. Adicione **Control** como filho de PlayerHealthSection
2. Renomeie para **PlayerHealthWidget**
3. Anexe o script: `res://examples/spell_battle/ui/widgets/navi_health_widget.gd`
4. Configure:
   - **Custom Minimum Size**: (200, 50) - para dar espaço para barra + label

### 3.3 CenterSpacer
1. Adicione **Control** como filho de TopBar
2. Renomeie para **CenterSpacer**
3. Configure:
   - **Size Flags** → **Horizontal**: **Fill, Expand** (marque ambas as checkboxes)

### 3.4 EnemyHealthSection
1. Adicione **VBoxContainer** como filho de TopBar
2. Renomeie para **EnemyHealthSection**
3. Configure:
   - **Separation**: 8

#### 3.4.1 EnemyNameLabel
1. Adicione **Label** como filho de EnemyHealthSection
2. Renomeie para **EnemyNameLabel**
3. Configure:
   - **Text**: "FIREMAN.EXE" (placeholder)
   - **Horizontal Alignment**: Center
   - **Theme Overrides** → **Colors** → **Font Color**: Red (RGB: 255, 20, 147)
   - **Theme Overrides** → **Colors** → **Font Outline Color**: Black
   - **Theme Overrides** → **Constants** → **Outline Size**: 2
   - **Theme Overrides** → **Font Sizes** → **Font Size**: 18

#### 3.4.2 EnemyHealthWidget
1. Adicione **Control** como filho de EnemyHealthSection
2. Renomeie para **EnemyHealthWidget**
3. Anexe o script: `res://examples/spell_battle/ui/widgets/navi_health_widget.gd`
4. Configure:
   - **Custom Minimum Size**: (200, 50)

## Passo 4: Criar MiddleSection (Gauge + Turn Counter)

### 4.1 MiddleSection HBoxContainer
1. Adicione **HBoxContainer** como filho de VBoxContainer
2. Renomeie para **MiddleSection**
3. Configure:
   - **Separation**: 30

### 4.2 SlotInSection
1. Adicione **VBoxContainer** como filho de MiddleSection
2. Renomeie para **SlotInSection**
3. Configure:
   - **Separation**: 8

#### 4.2.1 SlotInLabel
1. Adicione **Label** como filho de SlotInSection
2. Renomeie para **SlotInLabel**
3. Configure:
   - **Text**: "SLOT-IN GAUGE"
   - **Horizontal Alignment**: Center
   - **Theme Overrides** → **Colors** → **Font Color**: Cyan
   - **Theme Overrides** → **Colors** → **Font Outline Color**: Black
   - **Theme Overrides** → **Constants** → **Outline Size**: 2
   - **Theme Overrides** → **Font Sizes** → **Font Size**: 14

#### 4.2.2 SlotInGaugeWidget
1. Adicione **Control** como filho de SlotInSection
2. Renomeie para **SlotInGaugeWidget**
3. Anexe o script: `res://examples/spell_battle/ui/widgets/slot_in_gauge_widget.gd`
4. Configure:
   - **Custom Minimum Size**: (200, 50)

### 4.3 TurnCounterSpacer
1. Adicione **Control** como filho de MiddleSection
2. Renomeie para **TurnCounterSpacer**
3. Configure:
   - **Size Flags** → **Horizontal**: **Fill, Expand**

### 4.4 TurnCounterDisplay
1. Adicione **Label** como filho de MiddleSection
2. Renomeie para **TurnCounterDisplay**
3. Anexe o script: `res://examples/spell_battle/ui/components/turn_counter_display.gd`
4. Configure:
   - **Text**: "TURN 0 / 10" (placeholder)
   - **Horizontal Alignment**: Center
   - **Vertical Alignment**: Center
   - **Theme Overrides** → **Colors** → **Font Color**: Cyan
   - **Theme Overrides** → **Colors** → **Font Outline Color**: Black
   - **Theme Overrides** → **Constants** → **Outline Size**: 2
   - **Theme Overrides** → **Font Sizes** → **Font Size**: 20

## Passo 5: Criar BottomSpacer

1. Adicione **Control** como filho de VBoxContainer
2. Renomeie para **BottomSpacer**
3. Configure:
   - **Size Flags** → **Vertical**: **Fill, Expand**

## Passo 6: Conectar @export References

1. Selecione o node raiz **SpellBattleHUD**
2. No Inspector, vá até a seção **Script Variables**
3. Arraste os nodes para os campos correspondentes:
   - **Player Health Widget**: Arraste PlayerHealthWidget
   - **Enemy Health Widget**: Arraste EnemyHealthWidget
   - **Slot In Gauge Widget**: Arraste SlotInGaugeWidget
   - **Turn Counter Display**: Arraste TurnCounterDisplay
   - **Player Name Label**: Arraste PlayerNameLabel
   - **Enemy Name Label**: Arraste EnemyNameLabel

## Passo 7: Salvar a Cena

1. Pressione **Ctrl+S** ou **File → Save Scene**
2. Salve como: `res://examples/spell_battle/ui/spell_battle_hud.tscn`

## Passo 8: Testar a Cena

1. Abra `res://examples/spell_battle/test_standalone.tscn`
2. Instancie **spell_battle_hud.tscn** como filho do root node
3. Pressione **F6** para rodar a cena
4. Verifique se:
   - ✅ HP bars aparecem no topo (esquerda = player, direita = enemy)
   - ✅ Nomes dos Navis aparecem acima das barras
   - ✅ Slot-In Gauge aparece na esquerda do meio
   - ✅ Turn Counter aparece na direita do meio
   - ✅ Layout se adapta à tela

---

## Hierarquia Final (Referência)

```
SpellBattleHUD (CanvasLayer) [script: spell_battle_hud.gd]
└── MarginContainer
    └── VBoxContainer
        ├── TopBar (HBoxContainer)
        │   ├── PlayerHealthSection (VBoxContainer)
        │   │   ├── PlayerNameLabel (Label)
        │   │   └── PlayerHealthWidget (Control) [script: navi_health_widget.gd]
        │   ├── CenterSpacer (Control)
        │   └── EnemyHealthSection (VBoxContainer)
        │       ├── EnemyNameLabel (Label)
        │       └── EnemyHealthWidget (Control) [script: navi_health_widget.gd]
        ├── MiddleSection (HBoxContainer)
        │   ├── SlotInSection (VBoxContainer)
        │   │   ├── SlotInLabel (Label)
        │   │   └── SlotInGaugeWidget (Control) [script: slot_in_gauge_widget.gd]
        │   ├── TurnCounterSpacer (Control)
        │   └── TurnCounterDisplay (Label) [script: turn_counter_display.gd]
        └── BottomSpacer (Control)
```

---

## Troubleshooting

### HP Widgets não aparecem
- Verifique se os scripts estão corretamente anexados
- Verifique se os widgets têm **Custom Minimum Size** configurado

### Labels não visíveis
- Adicione **Font Outline** (black, size 2) para contraste
- Verifique se **Font Color** está configurado

### Layout quebrado
- Verifique **Size Flags** (Fill, Expand) nos spacers
- Verifique **Separation** nos containers

### HUD não conecta ao BattleManager
- Verifique se BattleManagerComponent foi adicionado ao grupo "battle_manager"
- Verifique console para warnings do SpellBattleHUD

---

**Próximo Passo**: Após criar a cena, instancie-a em `test_standalone.tscn` e teste!
