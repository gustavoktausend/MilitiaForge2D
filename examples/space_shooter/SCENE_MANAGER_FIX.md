# Scene Manager - Correção de Erro "Scenes not declared"

## 🐛 Problema Encontrado

**Erro**: `Identifier "Scenes" not declared in the current scope` na linha 45 de `scene_manager.gd`

## ✅ Solução Implementada

O plugin Scene Manager requer **dois autoloads** para funcionar corretamente:

### 1. Autoload "Scenes" (obrigatório)

Adicionado ao `project.godot`:

```ini
[autoload]
Scenes="*res://addons/scene_manager/scenes.gd"
SceneManager="*res://addons/scene_manager/scene_manager.tscn"
```

⚠️ **Importante**: `Scenes` deve vir **antes** de `SceneManager` na lista de autoloads!

### 2. Configuração do scenes.gd

O arquivo `addons/scene_manager/scenes.gd` foi configurado com nossas cenas:

```gdscript
var scenes: Dictionary = {
    "_auto_refresh": true,
    "_auto_save": false,
    "_ignore_list": ["res://addons"],
    "_ignores_visible": true,
    "_sections": ["Menu", "Game"],

    # Menu scenes
    "main_menu": {
        "sections": ["Menu"],
        "value": "res://examples/space_shooter/scenes/main_menu.tscn"
    },
    "pilot_selection": {
        "sections": ["Menu"],
        "value": "res://examples/space_shooter/scenes/pilot_selection.tscn"
    },
    "ship_selection": {
        "sections": ["Menu"],
        "value": "res://examples/space_shooter/scenes/ship_selection.tscn"
    },

    # Game scenes
    "main_game": {
        "sections": ["Game"],
        "value": "res://examples/space_shooter/scenes/main_game.tscn"
    }
}
```

## 🧪 Como Verificar se Está Funcionando

1. **Abra o Godot**
2. **Vá em Project > Project Settings > Autoload**
3. **Verifique a ordem**:
   ```
   PlayerData
   EntityPoolManager
   SceneTransition
   Scenes          ← Deve aparecer AQUI
   SceneManager    ← Antes deste
   ```

4. **Execute o jogo** (F5)
5. **O erro não deve mais aparecer**

## 📊 Por que Aconteceu?

O Scene Manager usa um padrão de **configuração baseada em dicionário** onde:

- `scenes.gd` → Define quais cenas existem e podem ser gerenciadas
- `scene_manager.gd` → Usa essas definições para fazer transições

O arquivo `scene_manager.gd` na linha 45 faz:
```gdscript
for ignore_path in Scenes.scenes._ignore_list:
```

Isso **requer** que `Scenes` seja um singleton global (autoload).

## ✅ Status

- [x] Autoload `Scenes` adicionado
- [x] Autoload `SceneManager` configurado
- [x] Ordem correta dos autoloads
- [x] `scenes.gd` configurado com nossas cenas
- [x] Plugin habilitado

**Status**: ✅ **CORRIGIDO**

---

*Correção aplicada em: 2025-12-29*
*Versão do Plugin: Scene Manager Tool v3.X.X*
