# 🎬 SceneTransition - Modular Scene Transition System

Sistema modular e reutilizável de transições de cena para Godot 4.x, seguindo princípios SOLID.

## 📋 Resumo

Sistema profissional de transição entre cenas com efeitos customizáveis, projetado para ser **reutilizado em qualquer projeto Godot**.

**Princípios SOLID Aplicados:**
- ✅ **Single Responsibility** - Cada classe tem uma única responsabilidade
- ✅ **Open/Closed** - Aberto para extensão (novos efeitos), fechado para modificação
- ✅ **Liskov Substitution** - Todos os efeitos são intercambiáveis via classe base
- ✅ **Interface Segregation** - API limpa e minimalista
- ✅ **Dependency Inversion** - Depende de abstrações, não de implementações concretas

---

## 🚀 Instalação

### 1. Copiar Arquivos

Copie a pasta `addons/scene_transition/` para seu projeto Godot.

### 2. Registrar Autoload

Adicione ao `project.godot`:

```ini
[autoload]

SceneTransition="*res://addons/scene_transition/scene_transition.gd"
```

### 3. Pronto!

O sistema está disponível globalmente via `SceneTransition`.

---

## 📖 Uso Básico

### Transição Simples

```gdscript
# Mudar de cena com fade (1 segundo)
SceneTransition.change_scene("res://scenes/level_2.tscn", "fade")

# Mudar de cena com glitch effect (1.5 segundos)
SceneTransition.change_scene("res://scenes/game_over.tscn", "glitch", 1.5)
```

### Recarregar Cena

```gdscript
# Reiniciar fase atual com wipe transition
SceneTransition.reload_scene("wipe_left", 0.8)
```

### Verificar se está Transitando

```gdscript
if not SceneTransition.is_busy():
    SceneTransition.change_scene("res://next_scene.tscn", "fade")
```

---

## 🎨 Efeitos Disponíveis

### 1. **Fade Transition** (`"fade"`)

Transição clássica de fade para preto.

```gdscript
SceneTransition.change_scene("res://menu.tscn", "fade", 1.0)
```

**Características:**
- Suave e profissional
- Customizável (cor do fade)
- Curva cubic ease in/out

---

### 2. **Glitch Transition** (`"glitch"`)

Efeito de glitch/distorção estilo Hotline Miami.

```gdscript
SceneTransition.change_scene("res://game.tscn", "glitch", 1.5)
```

**Características:**
- Separação RGB (aberração cromática)
- Linhas de "screen tear"
- Flashes de cores neon
- Static noise bursts
- Perfeito para jogos retro/cyberpunk

**Cores Neon:**
- NEON_PINK: `#FF1594`
- NEON_CYAN: `#00F0F0`
- NEON_YELLOW: `#FFF000`
- NEON_PURPLE: `#9400D4`

---

### 3. **Wipe Transitions** (`"wipe_left"`, `"wipe_right"`, `"wipe_up"`, `"wipe_down"`)

Transição de "cortina" em direções diferentes.

```gdscript
SceneTransition.change_scene("res://level.tscn", "wipe_left", 0.8)
SceneTransition.change_scene("res://menu.tscn", "wipe_up", 1.0)
```

**Características:**
- 4 direções disponíveis
- Movimento suave
- Customizável (cor da cortina)

---

## 🔧 Criando Efeitos Customizados

### Passo 1: Criar Classe que Estende `TransitionEffect`

```gdscript
# custom_flash_transition.gd
extends TransitionEffect

var _flash_rect: ColorRect = null

func _setup() -> void:
    _flash_rect = ColorRect.new()
    _flash_rect.color = Color.WHITE
    _flash_rect.anchor_right = 1.0
    _flash_rect.anchor_bottom = 1.0
    add_child(_flash_rect)

func _animate_in(tween: Tween, half_duration: float) -> void:
    # Flash branco
    _flash_rect.modulate.a = 0.0
    tween.tween_property(_flash_rect, "modulate:a", 1.0, half_duration)

    # IMPORTANTE: Emitir midpoint quando tela está coberta
    tween.tween_callback(emit_midpoint)

func _animate_out(tween: Tween, half_duration: float) -> void:
    # Fade out do branco
    tween.tween_property(_flash_rect, "modulate:a", 0.0, half_duration)
```

### Passo 2: Registrar no Autoload (opcional)

Se quiser que o efeito esteja disponível globalmente:

```gdscript
# Adicionar em scene_transition.gd na função _register_built_in_effects()
var CustomFlashTransition = load("res://path/to/custom_flash_transition.gd")
register_effect("flash", CustomFlashTransition.new())
```

### Passo 3: Usar

```gdscript
SceneTransition.change_scene("res://scene.tscn", "flash", 0.5)
```

---

## 📡 Signals

### `transition_started(effect_name: String)`

Emitido quando transição começa.

```gdscript
func _ready():
    SceneTransition.transition_started.connect(_on_transition_start)

func _on_transition_start(effect_name: String):
    print("Transição iniciada: ", effect_name)
    # Pause music, disable input, etc
```

### `transition_midpoint()`

Emitido quando a tela está **totalmente coberta** (momento exato da troca de cena).

```gdscript
SceneTransition.transition_midpoint.connect(_on_midpoint)

func _on_midpoint():
    print("Tela coberta - cena sendo trocada!")
    # Perfect momento para mudar música, resetar variáveis, etc
```

### `transition_finished()`

Emitido quando transição termina completamente.

```gdscript
SceneTransition.transition_finished.connect(_on_transition_end)

func _on_transition_end():
    print("Transição finalizada!")
    # Resume game, enable input, etc
```

---

## 🎯 Arquitetura (SOLID)

### Estrutura de Classes

```
TransitionEffect (Classe Base Abstrata)
    ├─ FadeTransition
    ├─ GlitchTransition
    └─ WipeTransition
        ├─ Direction.LEFT
        ├─ Direction.RIGHT
        ├─ Direction.UP
        └─ Direction.DOWN

SceneTransition (Autoload Singleton)
    └─ Gerencia registro e execução de efeitos
```

### Fluxo de Execução

```
1. SceneTransition.change_scene() chamado
   ↓
2. Validar cena existe
   ↓
3. Obter efeito do registry
   ↓
4. Conectar aos signals do efeito
   ↓
5. effect.play_transition(duration)
   ↓
6. effect._animate_in() → Cobre tela
   ↓
7. effect.emit_midpoint() → SceneTransition troca cena
   ↓
8. effect._animate_out() → Revela nova cena
   ↓
9. effect.emit_finished() → SceneTransition limpa estado
```

---

## 🛠️ API Reference

### SceneTransition (Singleton)

#### `change_scene(scene_path: String, effect_name: String = "", duration: float = -1.0) -> void`

Muda para outra cena com transição.

**Parâmetros:**
- `scene_path`: Caminho para cena (ex: `"res://scenes/level_1.tscn"`)
- `effect_name`: Nome do efeito (padrão: `"fade"`)
- `duration`: Duração total em segundos (padrão: `1.0`)

**Exemplo:**
```gdscript
SceneTransition.change_scene("res://menu.tscn", "glitch", 2.0)
```

---

#### `reload_scene(effect_name: String = "", duration: float = -1.0) -> void`

Recarrega a cena atual com transição.

**Exemplo:**
```gdscript
# Reiniciar nível com glitch
SceneTransition.reload_scene("glitch", 1.2)
```

---

#### `register_effect(effect_name: String, effect_instance: TransitionEffect) -> void`

Registra um efeito customizado.

**Exemplo:**
```gdscript
var my_effect = MyCustomTransition.new()
SceneTransition.register_effect("custom", my_effect)

# Usar
SceneTransition.change_scene("res://scene.tscn", "custom")
```

---

#### `get_available_effects() -> Array[String]`

Retorna lista de efeitos registrados.

**Exemplo:**
```gdscript
var effects = SceneTransition.get_available_effects()
print(effects)  # ["fade", "glitch", "wipe_left", "wipe_right", ...]
```

---

#### `is_busy() -> bool`

Verifica se uma transição está em andamento.

**Exemplo:**
```gdscript
if not SceneTransition.is_busy():
    SceneTransition.change_scene("res://next.tscn", "fade")
```

---

### TransitionEffect (Classe Base)

#### Métodos que DEVEM ser sobrescritos:

##### `_setup() -> void`

Cria elementos visuais do efeito (ColorRects, Sprites, etc).

**Exemplo:**
```gdscript
func _setup() -> void:
    _overlay = ColorRect.new()
    _overlay.anchor_right = 1.0
    _overlay.anchor_bottom = 1.0
    add_child(_overlay)
```

---

##### `_animate_in(tween: Tween, half_duration: float) -> void`

Anima o efeito COBRINDO a tela.

**IMPORTANTE:** DEVE chamar `emit_midpoint()` quando tela estiver totalmente coberta!

**Exemplo:**
```gdscript
func _animate_in(tween: Tween, half_duration: float) -> void:
    _overlay.modulate.a = 0.0
    tween.tween_property(_overlay, "modulate:a", 1.0, half_duration)
    tween.tween_callback(emit_midpoint)  # ← CRUCIAL!
```

---

##### `_animate_out(tween: Tween, half_duration: float) -> void`

Anima o efeito REVELANDO a nova cena.

**Exemplo:**
```gdscript
func _animate_out(tween: Tween, half_duration: float) -> void:
    tween.tween_property(_overlay, "modulate:a", 0.0, half_duration)
```

---

#### Métodos auxiliares:

##### `emit_midpoint() -> void`

Emite signal de midpoint. **DEVE** ser chamado em `_animate_in()`.

##### `emit_finished() -> void`

Emite signal de conclusão. Chamado automaticamente pelo sistema.

---

## 💡 Exemplos de Uso

### Exemplo 1: Menu Principal → Jogo

```gdscript
# main_menu.gd
extends Control

func _on_play_button_pressed():
    SceneTransition.change_scene("res://game.tscn", "glitch", 1.5)
```

### Exemplo 2: Game Over → Menu

```gdscript
# game_over.gd
extends Control

func _on_retry_pressed():
    SceneTransition.reload_scene("fade", 1.0)

func _on_menu_pressed():
    SceneTransition.change_scene("res://menu.tscn", "wipe_down", 1.2)
```

### Exemplo 3: Desabilitar Input Durante Transição

```gdscript
func _ready():
    SceneTransition.transition_started.connect(_on_transition_start)
    SceneTransition.transition_finished.connect(_on_transition_end)

func _on_transition_start(_effect_name: String):
    set_process_input(false)  # Desabilita input

func _on_transition_end():
    set_process_input(true)  # Re-habilita input
```

### Exemplo 4: Transição com Som

```gdscript
func _ready():
    SceneTransition.transition_started.connect(_on_transition_start)
    SceneTransition.transition_midpoint.connect(_on_midpoint)

func _on_transition_start(effect_name: String):
    if effect_name == "glitch":
        $GlitchSound.play()
    else:
        $WhooshSound.play()

func _on_midpoint():
    $MusicPlayer.stop()  # Para música antiga
```

---

## 🎨 Customização de Efeitos Existentes

### Fade com Cor Customizada

```gdscript
# Registrar fade vermelho
var red_fade = FadeTransition.new()
red_fade.set_fade_color(Color.RED)
SceneTransition.register_effect("fade_red", red_fade)

# Usar
SceneTransition.change_scene("res://death.tscn", "fade_red", 0.5)
```

### Wipe com Cor Customizada

```gdscript
var blue_wipe = WipeTransition.new(WipeTransition.Direction.LEFT)
blue_wipe.set_wipe_color(Color.BLUE)
SceneTransition.register_effect("blue_wipe", blue_wipe)
```

---

## 🔥 Integrando com Space Shooter (Exemplo)

### NeonFadeTransition (Extensão Customizada)

```gdscript
# examples/space_shooter/scripts/transitions/neon_fade_transition.gd
extends "res://addons/scene_transition/effects/fade_transition.gd"

const NEON_CYAN: Color = Color(0.0, 0.94, 0.94)

func _setup() -> void:
    super._setup()
    set_fade_color(Color(0.05, 0.0, 0.1))  # Roxo escuro neon

func _animate_in(tween: Tween, half_duration: float) -> void:
    super._animate_in(tween, half_duration)
    # Adicionar flash cyan neon
    var flash = ColorRect.new()
    flash.color = NEON_CYAN
    # ... adicionar animação de flash
```

---

## ⚙️ Configurações

### Valores Padrão

Você pode editar `scene_transition.gd` para mudar padrões:

```gdscript
@export var default_duration: float = 1.0  # Duração padrão
@export var default_effect: String = "fade"  # Efeito padrão
```

---

## 📚 Recursos Adicionais

### Arquivos do Sistema

```
addons/scene_transition/
├── scene_transition.gd          # Autoload singleton
├── transition_effect.gd         # Classe base abstrata
├── effects/
│   ├── fade_transition.gd       # Fade simples
│   ├── glitch_transition.gd     # Glitch Hotline Miami
│   └── wipe_transition.gd       # Wipe direcional
└── README.md                    # Esta documentação
```

---

## 🐛 Troubleshooting

### Transição não aparece

**Problema:** Chamei `change_scene()` mas não vejo efeito.

**Solução:**
1. Verifique se autoload foi registrado no `project.godot`
2. Confirme que o `scene_path` está correto
3. Verifique console para erros

---

### Efeito customizado não funciona

**Problema:** Criei efeito mas cena não muda.

**Solução:**
- Certifique-se de chamar `emit_midpoint()` em `_animate_in()`!
- A troca de cena só acontece quando midpoint é emitido.

---

### Tela preta após transição

**Problema:** Transição cobre tela mas não volta.

**Solução:**
- Verifique se `_animate_out()` está implementado
- Confirme que `half_duration` não é zero

---

## ✅ Checklist de Implementação

- [x] TransitionEffect base class
- [x] FadeTransition
- [x] GlitchTransition (Hotline Miami style)
- [x] WipeTransition (4 direções)
- [x] SceneTransition autoload
- [x] Sistema de signals
- [x] Registro dinâmico de efeitos
- [x] Documentação completa
- [x] Exemplo de extensão (NeonFadeTransition)
- [x] Integração com Space Shooter

---

## 📝 Licença

Este sistema é parte do **MilitiaForge2D Framework** e pode ser usado livremente em qualquer projeto.

---

**Sistema criado com ❤️ seguindo princípios SOLID para Godot 4.x**
