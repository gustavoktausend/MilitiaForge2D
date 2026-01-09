# Guia de Teste do HUD

## ✅ Implementação Completa

Todos os componentes do HUD foram implementados e estão prontos para teste!

### Arquivos Criados

- ✅ `navi_health_widget.gd` - Widget de HP com animação
- ✅ `slot_in_gauge_widget.gd` - Widget de gauge Slot-In
- ✅ `turn_counter_display.gd` - Display de contador de turnos
- ✅ `spell_battle_hud.gd` - Controller principal
- ✅ `spell_battle_hud.tscn` - Cena visual do HUD
- ✅ BattleManager adicionado ao grupo "battle_manager"
- ✅ HUD instanciado em `test_standalone.tscn`

## 🎮 Como Testar

### Método 1: Godot Editor (Recomendado)

1. Abra o Godot Editor
2. Navegue até `res://examples/spell_battle/test_standalone.tscn`
3. Pressione **F6** ou clique em "Run Current Scene"
4. Observe:
   - **Top-Left**: HP bar do player (MEGAMAN.EXE) em cyan
   - **Top-Right**: HP bar do enemy (FIREMAN.EXE) em vermelho
   - **Middle-Left**: Gauge de Slot-In (0%)
   - **Middle-Right**: Turn Counter (TURN 0/10) em cyan

### Método 2: CLI (Headless)

```bash
cd C:\Users\Gustavo\.claude-worktrees\MilitiaForge2D\nervous-nightingale
godot --headless examples/spell_battle/test_standalone.tscn --quit
```

**Observação**: No modo headless, o HUD não será renderizado visualmente, mas os logs de debug aparecerão no console.

## 📊 O Que Esperar

### Console Output (com debug_hud = true)

```
[SpellBattleHUD] Found BattleManager: BattleManagerComponent
[SpellBattleHUD] Connected to BattleManager signals
[SpellBattleHUD] Connected to Navi signals (Player: MegaMan.EXE, Enemy: FireMan.EXE)
[SpellBattleHUD] Battle started, initializing HUD
[SpellBattleHUD] Player HP: 150 / 150
[SpellBattleHUD] Enemy HP: 130 / 130
[SpellBattleHUD] Turn changed: 1 / 10
...
```

### Visual

- **HP Bars**: Devem aparecer com barras verdes (HP alto)
- **Nomes**: MegaMan.EXE (cyan) vs FireMan.EXE (vermelho)
- **Gauge**: Barra vazia em cyan/green
- **Turn Counter**: "TURN 0 / 10" em cyan
- **Layout**: Responsivo, margens de 20px

### Animações

Durante a batalha (se você simular dano):
- HP bars animam suavemente (0.3s) ao mudar
- Gauge preenche linearmente (0.2s)
- Turn counter muda de cor (cyan → yellow → red) conforme progresso
- Turn counter pulsa nos turnos finais (80%+)

## 🐛 Troubleshooting

### HUD não aparece

**Problema**: HUD invisível ou vazio

**Soluções**:
1. Verifique se `spell_battle_hud.tscn` foi salvo corretamente
2. Verifique se o HUD está instanciado em `test_standalone.tscn`
3. Abra `spell_battle_hud.tscn` diretamente e pressione F6 para testar isoladamente

### Console mostra "No BattleManager found"

**Problema**: `[SpellBattleHUD] No BattleManager found in 'battle_manager' group`

**Solução**:
1. Verifique se `battle_manager_component.gd` contém `add_to_group("battle_manager")`
2. Linha deve estar em `component_ready()` após linha 112
3. Rode o teste novamente

### HP bars não aparecem

**Problema**: Widgets não criam nodes visuais

**Solução**:
1. Os widgets criam ProgressBar e Label automaticamente em `_ready()`
2. Verifique console para erros de script
3. Teste widgets isoladamente:

```gdscript
# Console test
var widget = NaviHealthWidget.new()
add_child(widget)
widget.initialize(150, 150)
```

### Gauge não preenche

**Problema**: Gauge não responde aos eventos

**Solução**:
1. Verifique se `SlotInGaugeComponent` está anexado ao player entity
2. Verifique se o signal `gauge_changed` está sendo emitido
3. Ative `debug_hud = true` para ver logs de conexão

### Animações não funcionam

**Problema**: HP muda instantaneamente

**Solução**:
1. Verifique se `animate_changes = true` nos widgets
2. Verifique se `animation_duration > 0`
3. Tweens requerem que o node esteja na árvore de cena

## 🔍 Debug Mode

Para ativar logs detalhados, em `spell_battle_hud.tscn`:

1. Selecione o node raiz `SpellBattleHUD`
2. No Inspector, encontre **Script Variables**
3. Marque `debug_hud = true`

Isso imprimirá:
- Descoberta de componentes
- Conexão de signals
- HP changes
- Gauge updates
- Turn changes

## ✨ Features Implementadas

- ✅ HP Bars com gradiente de cor (verde → amarelo → vermelho)
- ✅ Animação suave (Tween 0.3s SINE EASE_OUT)
- ✅ Slot-In Gauge com animação linear
- ✅ Flash effect quando gauge atinge 100%
- ✅ Turn Counter com cores dinâmicas
- ✅ Pulse animation em turnos críticos
- ✅ Nomes dos Navis com cores temáticas
- ✅ Font outline para legibilidade
- ✅ Layout responsivo com margins
- ✅ Auto-discovery de componentes via groups
- ✅ Safe signal connections

## 📝 Próximas Melhorias (Futuro)

- [ ] Phase Indicator (CHIP SELECTION, ATTACK, etc.)
- [ ] Victory/Defeat overlay
- [ ] Damage numbers flutuantes
- [ ] Navi portraits
- [ ] Status effect icons
- [ ] Chip counter visual (3 chips)
- [ ] Screen shake on damage
- [ ] Sound effects

---

**Status**: ✅ Pronto para testar!

Abra o Godot Editor e pressione F6 em `test_standalone.tscn` para ver o HUD em ação! 🎮
