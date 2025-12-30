# Fluxo Correto do Space Shooter

## 🎮 Fluxo Atual (CORRETO)

```
Main Menu
   ↓
   [PLAY Button]
   ↓
Loadout Selection (TELA UNIFICADA)
   ├─ Painel Esquerdo: Seleção de Piloto
   │  ├─ Portrait/License Card
   │  ├─ Nome, Arquétipo, Dificuldade
   │  ├─ Descrição
   │  ├─ Bônus
   │  ├─ Habilidade Especial
   │  └─ Navegação (PREV/NEXT)
   │
   └─ Painel Direito: Seleção de Nave + Cores
      ├─ Sprite da Nave
      ├─ Nome, Descrição, Stats
      ├─ Grid de Cores (10 opções)
      ├─ Slider de Intensidade
      ├─ Navegação (PREV/NEXT)
      └─ Botão START GAME
   ↓
Main Game
```

## ✅ Vantagens da Tela Unificada

1. **Uma única tela** para todas as customizações
2. **Comparação direta** - Ver piloto e nave lado a lado
3. **Menos cliques** - Menos transições entre telas
4. **Mais eficiente** - Configurar tudo de uma vez
5. **Melhor UX** - Tudo visível ao mesmo tempo

## 📂 Arquivos Envolvidos

### Main Menu
- `scenes/main_menu.tscn`
- `ui/main_menu.gd`
- Botão PLAY → `LOADOUT_SELECTION_PATH`

### Loadout Selection (Tela Unificada)
- `scenes/loadout_selection.tscn`
- `scripts/loadout_selection_ui.gd`
- Combina piloto + nave + cores
- Botão START GAME → `main_game.tscn`

### Telas Separadas (OPCIONAIS - Não usadas no fluxo principal)
- `scenes/pilot_selection.tscn` - Standalone pilot selection
- `scenes/ship_selection.tscn` - Standalone ship selection
- Podem ser usadas em outros contextos (ex: menu de opções)

## 🎨 Recursos Implementados na Tela Unificada

### Painel de Piloto
- ✅ 8 pilotos únicos
- ✅ Portraits/License cards exibidos
- ✅ Sistema de dificuldade com cores
- ✅ Bônus detalhados
- ✅ Habilidades especiais
- ✅ Navegação PREV/NEXT

### Painel de Nave
- ✅ 3 naves customizáveis
- ✅ Sprite preview
- ✅ Stats completos
- ✅ 10 cores pré-definidas
- ✅ Slider de intensidade (0.5x - 1.5x)
- ✅ Preview em tempo real
- ✅ Navegação PREV/NEXT

## 🔧 Código Principal

### Main Menu (ui/main_menu.gd)
```gdscript
const LOADOUT_SELECTION_PATH = "res://examples/space_shooter/scenes/loadout_selection.tscn"

func _on_play_pressed() -> void:
    print("[MainMenu] PLAY pressed - Loading loadout selection...")
    get_tree().change_scene_to_file(LOADOUT_SELECTION_PATH)
```

### Loadout Selection (scripts/loadout_selection_ui.gd)
```gdscript
# Update pilot portrait
if pilot.portrait:
    license_card.texture = pilot.portrait
elif pilot.license_card:
    license_card.texture = pilot.license_card
else:
    license_card.texture = null
```

## ❓ Por que Existem Telas Separadas?

As telas `pilot_selection.tscn` e `ship_selection.tscn` são **opcionais** e podem ser usadas para:

1. **Menus de configuração** - Mudar piloto/nave depois de iniciar
2. **Tutorial separado** - Ensinar cada sistema individualmente
3. **Testes/Debug** - Testar cada sistema isoladamente
4. **Flexibilidade futura** - Opção de ter fluxo separado se quiser

## 🧪 Como Testar

1. **Execute o jogo** (F5)
2. **Clique em PLAY** no Main Menu
3. **Deve abrir a tela unificada** com:
   - Piloto à esquerda (com portrait)
   - Nave à direita (com cores)
4. **Navegue com PREV/NEXT** em ambos os painéis
5. **Customize a cor** da nave
6. **Clique em START GAME** → Vai para o jogo

---

**Status**: ✅ Fluxo correto restaurado
**Data**: 2025-12-29
**Tela Principal**: loadout_selection.tscn (unificado)
