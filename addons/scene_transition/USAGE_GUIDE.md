# 🎬 SceneTransition - Guia de Uso Rápido

O sistema de transições está **instalado e pronto**, mas **não está ativo** no Space Shooter.

## ✅ Status Atual

- ✅ Sistema instalado em `addons/scene_transition/`
- ✅ Autoload registrado no `project.godot`
- ✅ 6 efeitos disponíveis: fade, glitch, wipe_left, wipe_right, wipe_up, wipe_down
- ⚠️ **Desativado** no Space Shooter (usando troca de cena padrão)

---

## 🚀 Como Ativar as Transições

### Opção 1: Menu Principal → Jogo

**Arquivo:** `examples/space_shooter/ui/main_menu.gd`

**Linha 223 - Substituir:**
```gdscript
# ATUAL (sem transição)
get_tree().change_scene_to_file(GAME_SCENE_PATH)

# ATIVAR TRANSIÇÃO
SceneTransition.change_scene(GAME_SCENE_PATH, "fade", 1.0)
# ou
SceneTransition.change_scene(GAME_SCENE_PATH, "glitch", 1.5)
```

### Opção 2: Restart do Jogo

**Arquivo:** `examples/space_shooter/scripts/game_controller.gd`

**Linha 158 - Substituir:**
```gdscript
# ATUAL (sem transição)
get_tree().reload_current_scene()

# ATIVAR TRANSIÇÃO
SceneTransition.reload_scene("fade", 1.0)
# ou
SceneTransition.reload_scene("glitch", 1.2)
```

---

## 🎨 Efeitos Disponíveis

### 1. **Fade** (Recomendado para começar)
```gdscript
SceneTransition.change_scene("res://scene.tscn", "fade", 1.0)
```
- Transição suave e profissional
- Baixo risco de bugs
- Fade para preto

### 2. **Glitch** (Hotline Miami style)
```gdscript
SceneTransition.change_scene("res://scene.tscn", "glitch", 1.5)
```
- Efeito mais complexo
- Aberração cromática, flashes neon
- Pode precisar de ajustes

### 3. **Wipes** (4 direções)
```gdscript
SceneTransition.change_scene("res://scene.tscn", "wipe_left", 0.8)
SceneTransition.change_scene("res://scene.tscn", "wipe_right", 0.8)
SceneTransition.change_scene("res://scene.tscn", "wipe_up", 0.8)
SceneTransition.change_scene("res://scene.tscn", "wipe_down", 0.8)
```
- Cortina deslizante
- Limpo e simples

---

## 🔧 Troubleshooting

### Se a transição não funcionar:

1. **Verificar Console:**
   - Procure por `[SceneTransition]` nos logs
   - Deve mostrar: "Autoload ready! Registered effects: [...]"

2. **Verificar Autoload:**
   - Abrir `Project → Project Settings → Autoload`
   - Confirmar que `SceneTransition` está registrado

3. **Testar com Fade primeiro:**
   ```gdscript
   SceneTransition.change_scene("res://path.tscn", "fade", 1.0)
   ```
   - Fade é o mais simples e estável

4. **Aumentar duração:**
   ```gdscript
   # Se transição parecer bugada, aumente o tempo
   SceneTransition.change_scene("res://path.tscn", "fade", 2.0)
   ```

---

## 📚 Documentação Completa

Para detalhes completos, veja:
- `addons/scene_transition/README.md` - Documentação técnica completa
- `addons/scene_transition/transition_effect.gd` - Classe base para criar efeitos customizados

---

## 💡 Recomendação

**Para ativar agora:**
1. Use `"fade"` com duração `1.0` - é o mais estável
2. Teste primeiro no menu principal
3. Se funcionar bem, adicione no restart do jogo

**Exemplo seguro:**
```gdscript
# Em main_menu.gd linha 223:
SceneTransition.change_scene(GAME_SCENE_PATH, "fade", 1.0)
```

---

## 🎯 Próximos Passos (Futuro)

Quando quiser melhorar as transições:

1. **Instalar addon profissional:**
   - [Scene Manager](https://github.com/maktoobgar/scene_manager)
   - [Godot Scene Transitions](https://godotengine.org/asset-library/asset)

2. **Ou customizar o sistema atual:**
   - Criar novos efeitos em `addons/scene_transition/effects/`
   - Ajustar timing e cores
   - Integrar com HUD neon

---

**Sistema criado e pronto para uso quando precisar! 🚀**
