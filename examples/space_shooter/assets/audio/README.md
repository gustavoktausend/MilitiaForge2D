# Sistema de Áudio - MilitiaForge2D Space Shooter

Sistema centralizado de gerenciamento de áudio usando o **AudioManager** (Autoload).

## 📁 Estrutura de Pastas

```
assets/audio/
├── music/                    # Músicas de fundo (.ogg recomendado)
│   ├── ship_select.ogg      ✓ Implementado
│   ├── main_menu.ogg        ⏳ A adicionar
│   ├── gameplay.ogg         ⏳ A adicionar
│   └── game_over.ogg        ⏳ A adicionar
│
└── sfx/                      # Efeitos sonoros
    ├── ui/                   # Sons de interface
    │   ├── button_hover.ogg  ⏳ A adicionar
    │   ├── button_click.ogg  ⏳ A adicionar
    │   ├── navigation.ogg    ⏳ A adicionar
    │   └── start_game.ogg    ⏳ A adicionar
    │
    ├── weapons/              # Sons de armas
    │   ├── laser_primary.ogg
    │   ├── laser_secondary.ogg
    │   ├── missile_launch.ogg
    │   └── special_weapon.ogg
    │
    ├── impacts/              # Sons de impacto
    │   ├── hit_enemy.ogg
    │   ├── hit_player.ogg
    │   └── explosion.ogg
    │
    └── pickups/              # Sons de pickup
        ├── health_pickup.ogg
        ├── ammo_pickup.ogg
        └── powerup.ogg
```

## 🎵 Formato de Arquivos

### Música de Fundo
- **Formato:** `.ogg` (Vorbis) - RECOMENDADO
- **Por quê:** Compressão eficiente, loop perfeito, sem gaps
- **Alternativa:** `.mp3` funciona, mas pode ter pequenos gaps no loop

### Efeitos Sonoros
- **Formato:** `.ogg` (Vorbis) - RECOMENDADO
- **Por quê:** Baixa latência, boa compressão
- **Alternativa:** `.wav` para sons muito curtos (< 0.5s)

## 🎮 Como Usar o AudioManager

### 1. Tocar Música de Fundo

```gdscript
# Tocar música com fade in de 1.5 segundos
AudioManager.play_music("ship_select", 1.5)

# Tocar música sem loop
AudioManager.play_music("game_over", 2.0, false)

# Parar música com fade out
await AudioManager.stop_music(1.0)

# Fade in/out manual
AudioManager.fade_in_music(2.0)
await AudioManager.fade_out_music(0.5)

# Pausar/Retomar
AudioManager.pause_music()
AudioManager.resume_music()
```

### 2. Tocar Efeitos Sonoros de UI

```gdscript
# Som de hover em botão (volume 70%)
AudioManager.play_ui_sound("button_hover", 0.7)

# Som de click
AudioManager.play_ui_sound("button_click")

# Som especial de start game (volume 120%)
AudioManager.play_ui_sound("start_game", 1.2)
```

### 3. Tocar Efeitos de Armas

```gdscript
# Som de tiro primário
AudioManager.play_weapon_sound("laser_primary")

# Som de míssil (mais alto)
AudioManager.play_weapon_sound("missile_launch", 1.3)
```

### 4. Tocar Efeitos de Impacto

```gdscript
# Som de acerto em inimigo
AudioManager.play_impact_sound("hit_enemy")

# Som de explosão (mais alto)
AudioManager.play_impact_sound("explosion", 1.5)
```

### 5. Tocar Efeitos de Pickup

```gdscript
# Som de pegar vida
AudioManager.play_pickup_sound("health_pickup")

# Som de power-up (mais alto)
AudioManager.play_pickup_sound("powerup", 1.2)
```

## 🎚️ Controle de Volume

```gdscript
# Volume master (0.0 a 1.0)
AudioManager.set_master_volume(0.8)

# Volume da música
AudioManager.set_music_volume(0.7)

# Volume dos efeitos sonoros
AudioManager.set_sfx_volume(1.0)

# Volume dos sons de UI
AudioManager.set_ui_volume(0.9)
```

## 🔊 Audio Buses

O sistema usa os seguintes buses de áudio:

```
Master (Volume master)
├── Music  (Músicas de fundo)
└── SFX    (Efeitos sonoros)
    ├── UI       (Sons de interface)
    └── Gameplay (Sons do jogo)
```

Para configurar no Godot:
1. Abra **Audio** tab (bottom panel)
2. Crie os buses: `Music`, `SFX`, `UI`, `Gameplay`
3. Configure `UI` e `Gameplay` como filhos de `SFX`

## 📝 Exemplo de Implementação

### Adicionar Sons em Botões

```gdscript
extends Control

@onready var my_button: Button = $MyButton

func _ready() -> void:
    # Hover sound
    my_button.mouse_entered.connect(func():
        AudioManager.play_ui_sound("button_hover", 0.7)
    )

    # Click sound
    my_button.pressed.connect(func():
        AudioManager.play_ui_sound("button_click")
    )
```

### Integrar com WeaponComponent

```gdscript
# Em weapon_component.gd, adicionar na função _fire():
func _fire() -> void:
    # ... código existente de disparo ...

    # Tocar som da arma
    AudioManager.play_weapon_sound(weapon_sound_name)
```

### Transição de Música entre Cenas

```gdscript
# Scene A → Scene B
func _on_start_game() -> void:
    # Fade out música atual
    await AudioManager.fade_out_music(0.8)

    # Trocar cena
    get_tree().change_scene_to_file("res://next_scene.tscn")

# Em Scene B _ready():
func _ready() -> void:
    # Tocar nova música
    AudioManager.play_music("gameplay", 2.0)
```

## ⚙️ Features do AudioManager

### Pool de AudioStreamPlayers
- **16 players simultâneos** para SFX
- Gerenciamento automático de players disponíveis
- Se pool estiver cheio, interrompe o som mais antigo

### Cache de Audio Streams
- Carrega arquivos uma vez e cacheia
- Reduz loading times
- Use `AudioManager.clear_audio_cache()` para liberar memória

### Fade Suave
- Fade in/out com curvas cúbicas
- Transições sem clipping ou pops
- Duração customizável

### Volume Multiplier
- Todos os métodos `play_*_sound()` aceitam multiplicador de volume
- Útil para variações (e.g., armas diferentes com volumes diferentes)

## 🎯 Próximos Passos

1. **Adicionar arquivos de áudio:**
   - Criar/baixar os arquivos .ogg necessários
   - Colocar nas pastas corretas

2. **Configurar Audio Buses no Godot:**
   - Abrir Audio tab
   - Criar estrutura de buses mencionada acima

3. **Integrar com componentes:**
   - Adicionar sons ao WeaponComponent
   - Adicionar sons de impacto ao HealthComponent
   - Adicionar sons de pickup aos power-ups

4. **Música para outras cenas:**
   - Main Menu: adicionar música
   - Game Over: adicionar música
   - Pausar música durante pause screen

## 🔧 Troubleshooting

### Sons não tocam
- Verifique se o arquivo existe no caminho correto
- Verifique se o nome do arquivo está sem extensão (AudioManager adiciona `.ogg`)
- Veja o console para warnings do AudioManager

### Música não faz loop
- Verifique se o arquivo é `.ogg` (Vorbis)
- O AudioManager configura loop automaticamente para OGG

### Volume muito baixo/alto
- Ajuste o multiplicador de volume nos métodos `play_*_sound()`
- Configure os volumes dos buses no Audio tab
- Use `set_*_volume()` para ajustar globalmente

### Pool de SFX cheio
- Aumente `SFX_POOL_SIZE` em `audio_manager.gd` se necessário
- Padrão: 16 sons simultâneos (suficiente para a maioria dos casos)

## 📚 Referências

- [Godot Audio Documentation](https://docs.godotengine.org/en/stable/tutorials/audio/index.html)
- [Audio Buses](https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html)
- [AudioStreamPlayer](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html)
