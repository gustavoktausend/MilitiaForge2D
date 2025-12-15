# Space Shooter - Instruções de Setup 🚀

## Como Executar o Jogo

### Opção 1: Executar Diretamente a Cena do Menu

1. Abra o Godot 4
2. Abra o projeto **MilitiaForge2D**
3. No FileSystem, navegue até: `examples/space_shooter/scenes/main_menu.tscn`
4. Clique com botão direito na cena → **Run Current Scene** (ou pressione F6)

### Opção 2: Configurar como Cena Principal do Projeto

Se quiser que o Space Shooter seja a cena inicial ao pressionar F5:

1. Abra **Project → Project Settings**
2. Na aba **General**, encontre **Application → Run → Main Scene**
3. Clique no ícone de pasta
4. Selecione: `res://examples/space_shooter/scenes/main_menu.tscn`
5. Clique **Close**

Agora ao pressionar **F5**, o jogo iniciará automaticamente!

---

## Fluxo do Jogo

```
Main Menu (main_menu.tscn)
    ↓ [PLAY]
Main Game (main_game.tscn)
    ↓ [Player Dies]
Game Over Screen (HUD overlay)
    ├─ [RESTART] → Reinicia o jogo
    └─ [MENU] → Volta ao Main Menu
```

---

## Estrutura de Arquivos

```
examples/space_shooter/
├── scenes/
│   ├── main_menu.tscn          ← Tela inicial
│   ├── main_game.tscn          ← Jogo principal
│   ├── enemy_basic.tscn        ← Inimigo básico
│   ├── enemy_fast.tscn         ← Inimigo rápido
│   ├── enemy_tank.tscn         ← Inimigo tanque
│   └── projectile.tscn         ← Projétil
├── scripts/
│   ├── enemy_base.gd           ← Base para todos inimigos
│   ├── enemy_factory.gd        ← Factory de inimigos
│   ├── game_controller.gd      ← Controle do jogo
│   ├── player_controller.gd    ← Controle do player
│   ├── wave_manager.gd         ← Sistema de waves
│   ├── simple_weapon.gd        ← Sistema de arma
│   └── space_background.gd     ← Background animado
├── ui/
│   ├── main_menu.gd            ← Menu principal
│   └── game_hud.gd             ← HUD + Game Over
└── docs/
    ├── setup_instructions.md   ← Este arquivo
    └── enemy_factory_usage.md  ← Como usar o Factory
```

---

## Controles

### No Jogo:
- **W / ↑** - Mover para cima
- **S / ↓** - Mover para baixo
- **A / ←** - Mover para esquerda
- **D / →** - Mover para direita
- **SPACE** - Atirar
- **ESC** - Pausar (implementação futura)

### No Menu:
- **Mouse** - Clicar nos botões
- **PLAY** - Iniciar jogo
- **OPTIONS** - Opções (em desenvolvimento)
- **QUIT** - Sair do jogo

---

## Features Implementadas ✅

### Core Gameplay
- ✅ Movimento do player com boundaries
- ✅ Sistema de disparo
- ✅ 3 tipos de inimigos (Basic, Fast, Tank)
- ✅ Sistema de waves progressivas
- ✅ Sistema de vida do player
- ✅ Sistema de pontuação com high score
- ✅ Colisões e dano funcionais

### UI/UX
- ✅ Menu principal com animações
- ✅ HUD lateral com informações
- ✅ Tela de Game Over completa
- ✅ Sistema de restart/menu
- ✅ High score persistente

### Padrões e Arquitetura
- ✅ Component-based architecture (MilitiaForge2D)
- ✅ Factory pattern para inimigos
- ✅ Sistema de sinais bem estruturado
- ✅ Race condition prevention
- ✅ Logs de debug detalhados

---

## Features Planejadas 🚧

### Próximas Implementações
- 🔲 Sistema de power-ups
- 🔲 Efeitos visuais e partículas
- 🔲 Sistema de áudio (SFX + música)
- 🔲 Tela de opções (volume, controles)
- 🔲 Mais tipos de inimigos
- 🔲 Sistema de bosses

---

## Troubleshooting

### O menu não aparece
- Verifique se executou a cena correta: `main_menu.tscn`
- Confira o console para erros

### Player não toma dano
- Verifique os logs no console
- Procure por mensagens do Hurtbox
- Confirme que collision layers/masks estão corretas

### Inimigos não aparecem
- Verifique o WaveManager no console
- Confirme que as cenas de inimigos existem
- Verifique se EnemyFactory registrou os tipos

### High score não salva
- O arquivo é salvo em `user://highscore.save`
- No Windows: `%APPDATA%/Godot/app_userdata/MilitiaForge2D/`
- Verifique permissões de escrita

---

## Desenvolvimento

Para modificar ou adicionar features:

1. **Adicionar novo tipo de inimigo:**
   - Crie nova cena baseada em `enemy_base.gd`
   - Registre no `SpaceShooterEnemyFactory`
   - Adicione às waves no `wave_manager.gd`

2. **Modificar waves:**
   - Edite `wave_manager.gd`
   - Altere a função `_create_waves()`

3. **Adicionar power-ups:**
   - Use as funções `power_up_weapon()` e `power_up_shield()` em `player_controller.gd`
   - Crie cena de power-up coletável
   - Implemente spawn system

---

## Créditos

**Engine:** Godot 4.5
**Framework:** MilitiaForge2D
**Desenvolvido como:** Exemplo demo do framework

---

**Divirta-se jogando Space Shooter! 🚀✨**
