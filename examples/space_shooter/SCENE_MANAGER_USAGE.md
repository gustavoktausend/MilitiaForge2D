# Scene Manager - Guia de Uso

Sistema de transição de cenas com efeitos visuais configurável.

## ✅ Status da Configuração

- [x] Plugin habilitado em `project.godot`
- [x] Autoload `Scenes` registrado (contém dicionário de cenas)
- [x] Autoload `SceneManager` registrado (gerencia transições)
- [x] Cenas configuradas em `scenes.gd`:
  - `main_menu`
  - `loadout_selection`
  - `pilot_selection`
  - `ship_selection`
  - `main_game`

## 🎬 Como Usar

### Método 1: Transição Simples (Recomendado)

```gdscript
# Trocar de cena com efeito fade padrão
SceneManager.change_scene("loadout_selection")
```

### Método 2: Transição com Opções Customizadas

```gdscript
# Criar opções de fade out
var fade_out_options = SceneManager.create_options(1.0)  # 1 segundo

# Criar opções de fade in
var fade_in_options = SceneManager.create_options(0.5)   # 0.5 segundos

# Criar opções gerais
var general_options = SceneManager.create_general_options()
general_options.color = Color(0, 0, 0)  # Cor preta
general_options.timeout = 0.0
general_options.clickable = true
general_options.add_to_back = true

# Trocar cena com opções customizadas
SceneManager.change_scene("main_game", fade_out_options, fade_in_options, general_options)
```

### Método 3: Sem Efeito (Instantâneo)

```gdscript
# Trocar cena sem transição visual
SceneManager.no_effect_change_scene("main_menu")
```

### Método 4: Com Padrão de Transição

```gdscript
var fade_out_options = SceneManager.create_options(1.0, "scribbles")  # Usar padrão "scribbles"
var fade_in_options = SceneManager.create_options(0.5)
var general_options = SceneManager.create_general_options()

SceneManager.change_scene("loadout_selection", fade_out_options, fade_in_options, general_options)
```

## 📋 Padrões de Transição Disponíveis

Os padrões estão em `addons/scene_manager/shader_patterns/`:
- `fade` (padrão)
- `scribbles`
- `squares`
- `curtains`
- `diagonal`
- `radial`
- E outros...

## 🔄 Funções Especiais

### Voltar para Cena Anterior

```gdscript
SceneManager.change_scene("back")  # Volta para a última cena
```

### Recarregar Cena Atual

```gdscript
SceneManager.change_scene("reload")  # Recarrega a cena atual
```

### Sair do Jogo

```gdscript
SceneManager.change_scene("exit")  # Fecha o jogo
```

## 🎯 Exemplo Prático: Loadout Selection → Main Game

```gdscript
# Em loadout_selection_ui.gd
func _on_start_pressed() -> void:
    AudioManager.play_ui_sound("start_game", 1.2)
    _save_to_player_data()

    # Fade out da música
    await AudioManager.fade_out_music(0.8)

    # Transição com efeito fade
    var fade_out_options = SceneManager.create_options(0.8)
    var fade_in_options = SceneManager.create_options(0.5)
    var general_options = SceneManager.create_general_options()

    SceneManager.change_scene("main_game", fade_out_options, fade_in_options, general_options)
```

## 🎯 Exemplo Prático: Main Menu → Loadout Selection

```gdscript
# Em main_menu.gd
func _on_play_pressed() -> void:
    print("[MainMenu] PLAY pressed - Loading loadout selection...")

    # Versão simples (fade padrão de 1 segundo)
    SceneManager.change_scene("loadout_selection")

    # OU versão customizada:
    # var fade_out = SceneManager.create_options(0.5, "diagonal")
    # var fade_in = SceneManager.create_options(0.5)
    # var general = SceneManager.create_general_options()
    # SceneManager.change_scene("loadout_selection", fade_out, fade_in, general)
```

## 📊 Sinais (Signals) Disponíveis

Você pode conectar aos sinais do SceneManager para executar código em momentos específicos:

```gdscript
func _ready() -> void:
    SceneManager.scene_changed.connect(_on_scene_changed)
    SceneManager.fade_in_started.connect(_on_fade_in_started)
    SceneManager.fade_in_finished.connect(_on_fade_in_finished)
    SceneManager.fade_out_started.connect(_on_fade_out_started)
    SceneManager.fade_out_finished.connect(_on_fade_out_finished)

func _on_scene_changed() -> void:
    print("Scene changed!")

func _on_fade_in_started() -> void:
    print("Fade in started")
```

## 🔧 Funções Auxiliares

### Criar Opções de Fade

```gdscript
# create_options(speed, pattern, smoothness, inverted)
var options = SceneManager.create_options(
    1.0,           # velocidade (segundos)
    "fade",        # padrão de transição
    0.1,           # suavidade
    false          # invertido?
)
```

### Criar Opções Gerais

```gdscript
# create_general_options(color, timeout, clickable, add_to_back)
var general = SceneManager.create_general_options(
    Color.BLACK,   # cor da transição
    0.0,           # tempo de espera extra
    true,          # permite clique durante transição?
    true           # adiciona à pilha de "back"?
)
```

## 🎨 Integração com AudioManager

Para sincronizar música com transições:

```gdscript
func change_to_game() -> void:
    # Fade out música atual
    await AudioManager.fade_out_music(0.5)

    # Transição de cena
    SceneManager.change_scene("main_game")

    # Aguardar cena carregar (usar signal)
    await SceneManager.scene_changed

    # Fade in nova música
    AudioManager.play_music("gameplay", 1.5)
```

## ⚠️ Importante

1. **Use as chaves definidas em `scenes.gd`:**
   - ✓ `SceneManager.change_scene("main_menu")`
   - ✗ `SceneManager.change_scene("res://path/to/scene.tscn")`  # Funciona, mas perde features

2. **A ordem dos autoloads importa:**
   - `Scenes` deve vir ANTES de `SceneManager`
   - Já configurado corretamente no `project.godot`

3. **Adicionar novas cenas:**
   - Abra a aba "Scene Manager" no painel inferior do Godot
   - Clique em "Refresh" para detectar novas cenas
   - Clique em "Save" para salvar
   - OU edite manualmente `addons/scene_manager/scenes.gd`

## 📚 Referências

- Plugin oficial: [Scene Manager Tool](https://github.com/maktoobgar/scene_manager)
- Versão instalada: v3.10.0
- Documentação do plugin: `addons/scene_manager/`

## 🎯 Migração Rápida

Para migrar do código atual para Scene Manager:

**Antes:**
```gdscript
get_tree().change_scene_to_file("res://examples/space_shooter/scenes/main_game.tscn")
```

**Depois:**
```gdscript
SceneManager.change_scene("main_game")
```

**OU com opções:**
```gdscript
var fade_out = SceneManager.create_options(0.8)
var fade_in = SceneManager.create_options(0.5)
var general = SceneManager.create_general_options()
SceneManager.change_scene("main_game", fade_out, fade_in, general)
```
