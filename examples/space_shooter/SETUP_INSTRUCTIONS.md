# Ship Selection System - Setup Instructions

## Autoload Configuration

Para configurar o sistema de seleção de naves, você precisa registrar o PlayerData como autoload:

1. No Godot, vá em **Project > Project Settings > Autoload**
2. Clique no botão de pasta e navegue até: `res://examples/space_shooter/scripts/player_data.gd`
3. Nome do Node: `PlayerData`
4. Clique em "Add"

## Usando as Configurações de Naves

### Opção 1: Carregar config do PlayerData (recomendado)

O `player_controller.gd` já está configurado para carregar automaticamente do PlayerData:

```gdscript
func _ready() -> void:
	# Load ship config from PlayerData if not set
	if not ship_config and has_node("/root/PlayerData"):
		var player_data = get_node("/root/PlayerData")
		ship_config = player_data.get_selected_ship()

	_apply_ship_config()
	await _setup_components()
	_setup_visuals()
	_connect_signals()
```

### Opção 2: Testar configs manualmente

No editor do Godot, você pode arrastar um dos arquivos `.tres` para o campo `ship_config` do Player:
- `res://examples/space_shooter/resources/ships/ship_balanced.tres`
- `res://examples/space_shooter/resources/ships/ship_speed.tres`
- `res://examples/space_shooter/resources/ships/ship_tank.tres`

## Fluxo do Jogo

O fluxo completo do jogo agora está implementado:

1. **Main Menu** (`main_menu.tscn`)
   - Botão "PLAY" leva para Ship Selection
   - Botão "OPTIONS" (coming soon)
   - Botão "QUIT"

2. **Ship Selection** (`ship_selection.tscn`)
   - Escolha entre 3 naves: Falcon, Interceptor, Fortress
   - Visualize sprites, stats e descrições
   - Botão "START GAME" salva a seleção no PlayerData e inicia o jogo

3. **Main Game** (`main_game.tscn`)
   - Player spawna com a nave selecionada
   - Stats e sprite carregados do ShipConfig

## Status de Implementação

1. ✅ Registrar PlayerData como autoload
2. ✅ UI de seleção de naves criada
3. ✅ Transição Main Menu → Ship Selection → Game
4. ✅ Sistema completo funcionando
