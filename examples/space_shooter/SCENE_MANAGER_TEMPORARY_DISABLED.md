# Scene Manager Temporariamente Desabilitado

## Status: Revertido para Transições Nativas

Por questões de estabilidade e para garantir que o jogo funcione imediatamente, **removemos temporariamente o uso do Scene Manager** e voltamos a usar o método nativo do Godot `change_scene_to_file()`.

## O que isso significa?

### ✅ Vantagens
- **100% estável** - Sem erros de compilação
- **Funcionamento garantido** - Método nativo do Godot sempre funciona
- **Menos dependências** - Não depende de plugins third-party
- **Código mais simples** - Fácil de entender e manter

### ⚠️ Trade-offs
- **Sem transições suaves** - Mudanças de cena são instantâneas
- **Sem animações de fade** - Não há efeito visual entre cenas
- **Menos polimento** - Experiência menos profissional

## Código Atual

### Main Menu
```gdscript
func _on_play_pressed() -> void:
    print("[MainMenu] PLAY pressed - Loading pilot selection...")
    get_tree().change_scene_to_file(PILOT_SELECTION_PATH)
```

### Pilot Selection
```gdscript
func _on_select_pressed() -> void:
    # ... código de seleção ...
    get_tree().change_scene_to_file("res://examples/space_shooter/scenes/ship_selection.tscn")
```

### Ship Selection
```gdscript
func _on_select_pressed() -> void:
    # ... código de seleção ...
    get_tree().change_scene_to_file("res://examples/space_shooter/scenes/main_game.tscn")
```

## Como Reativar Transições Futuramente

Quando quiser adicionar transições novamente, você tem duas opções:

### Opção 1: Scene Manager (Plugin)
1. Garantir que o plugin está corretamente instalado
2. Verificar autoloads no project.godot
3. Adicionar código de transição nos botões

### Opção 2: Transição Customizada Simples
Criar uma transição fade simples sem plugin:

```gdscript
func _transition_to_scene(path: String) -> void:
    # Fade out
    var fade = ColorRect.new()
    fade.color = Color.BLACK
    fade.anchor_right = 1.0
    fade.anchor_bottom = 1.0
    fade.modulate.a = 0.0
    get_tree().root.add_child(fade)
    
    var tween = create_tween()
    tween.tween_property(fade, "modulate:a", 1.0, 0.5)
    await tween.finished
    
    # Change scene
    get_tree().change_scene_to_file(path)
```

## Status dos Sistemas Implementados

| Sistema | Status | Funcionando? |
|---------|--------|--------------|
| Portraits de Pilotos | ✅ Completo | Sim |
| Seleção de Pilotos | ✅ Completo | Sim |
| Seleção de Naves | ✅ Completo | Sim |
| Customização de Cores | ✅ Completo | Sim |
| Animações de Fade (portraits) | ✅ Completo | Sim |
| Transições entre cenas | ⚠️ Removido | Sim (sem fade) |

## Recomendação

Para **produção**, recomendo:

1. **Agora**: Use transições nativas (atual) - 100% estável
2. **Depois**: Quando tudo estiver funcionando perfeitamente, adicione transições customizadas simples
3. **Polimento final**: Considere adicionar o Scene Manager novamente ou criar transições mais elaboradas

## Arquivos Modificados

- `ui/main_menu.gd` - Voltou para change_scene_to_file()
- `scripts/pilot_selection_ui.gd` - Voltou para change_scene_to_file()
- `scripts/ship_selection_ui.gd` - Voltou para change_scene_to_file()

---

*Mudança aplicada em: 2025-12-29*
*Razão: Garantir estabilidade e funcionamento imediato*
*Status: ✅ ESTÁVEL E FUNCIONAL*
