# MilitiaForge2D

Um framework modular baseado em componentes para desenvolvimento rápido de jogos 2D no Godot 4.x

## 🎯 Visão Geral

MilitiaForge2D foi projetado para acelerar o desenvolvimento de jogos 2D através de um sistema robusto de componentes baseado nos princípios SOLID, permitindo que desenvolvedores construam jogos mais rapidamente com componentes reutilizáveis, parametrizáveis e modulares.

## 🏗️ Arquitetura

O framework segue os **princípios SOLID** e implementa uma arquitetura baseada em componentes onde:
- **Components** são peças de funcionalidade autocontidas e reutilizáveis
- **ComponentHost** gerencia o ciclo de vida e coordenação dos componentes anexados
- **Resources** permitem configuração parametrizada e reutilizável
- **Sandbox** fornece ambientes de teste isolados para componentes

## 📁 Estrutura do Projeto

```
MilitiaForge2D/
├── docs/                          # Documentação
│   ├── architecture/              # Decisões arquiteturais e padrões
│   ├── components/                # Documentação específica de componentes
│   └── guidelines/                # Diretrizes e melhores práticas
├── militia_forge/                 # Código central do framework
│   ├── core/                      # Classes fundamentais
│   │   ├── component.gd          # Classe base Component
│   │   ├── component_host.gd     # Gerenciador de componentes
│   │   └── event_bus.gd          # Sistema de eventos global
│   └── components/                # Componentes reutilizáveis
│       ├── state_machine/         # Máquina de estados
│       ├── movement/              # Componentes de movimento
│       ├── health/                # Sistema de vida
│       ├── combat/                # Sistema de combate
│       ├── input/                 # Sistema de input
│       ├── progression/           # Score, combo, powerups
│       ├── audio/                 # Sistema de áudio
│       ├── effects/               # Efeitos visuais
│       ├── environment/           # Scroll, background
│       └── pilot_ability_system.gd # Sistema de habilidades de piloto
├── examples/                      # Jogos exemplo e casos de uso
│   └── space_shooter/             # Exemplo: Space Shooter
│       ├── assets/                # Assets do jogo
│       │   ├── backgrounds/       # Imagens de fundo
│       │   └── sprites/           # Sprites de entidades
│       ├── resources/             # Configurações parametrizadas
│       │   ├── backgrounds/       # Resources de backgrounds
│       │   ├── pilots/            # Dados de pilotos (futuro)
│       │   └── ships/             # Dados de naves (futuro)
│       ├── scenes/                # Cenas do jogo
│       ├── scripts/               # Scripts do jogo
│       └── ui/                    # Interface de usuário
├── sandbox/                       # Ambiente de testes
│   ├── test_scenes/              # Cenas de teste para componentes
│   └── test_components/          # Componentes específicos de teste
└── project.godot                 # Configuração do projeto Godot
```

## ✨ Recursos Principais

### Sistema de Componentes
- **14+ componentes completos** prontos para uso
- Ciclo de vida padronizado (initialize → component_ready → process → cleanup)
- Comunicação via sinais (Observer Pattern)
- Fácil extensão e composição

### Sistemas Implementados

#### 🎮 Movimento
- `MovementComponent` - Movimento base
- `TopDownMovement` - Movimento top-down 8 direções
- `PlatformerMovement` - Movimento de plataforma com física
- `BoundedMovement` - Movimento com limites de área
- `DashComponent` - Sistema de dash com i-frames
- `PathFollowMovement` - Seguir caminhos predefinidos

#### ⚔️ Combate
- `HealthComponent` - Gerenciamento de vida, dano e cura
- `Hitbox/Hurtbox` - Sistema de colisão de dano
- `WeaponComponent` - Sistema de armas
- `WeaponSlotManager` - Gerenciamento de slots PRIMARY/SECONDARY/SPECIAL
- `ProjectileComponent` - Projéteis com pooling
- `CollisionDamageComponent` - Dano por colisão
- `ChargeShot` - Sistema de tiro carregado
- `TurretComponent` - Torres automáticas
- `SpawnerComponent` - Spawn de entidades

#### 🎯 Progressão
- `ScoreComponent` - Sistema de pontuação com combos
  - Sistema de combo com decay
  - Multiplicadores de pontuação
  - High scores persistentes
  - Sistema de ranks (F a SSS)
  - Milestones e conquistas
  - **Sinal `enemy_killed`** para rastreamento de kills
- `PowerupComponent` - Sistema de power-ups
- `PilotAbilitySystem` - Habilidades especiais de pilotos
  - Regeneração automática
  - Modo berserker (dano baseado em vida)
  - Boost de combo
  - Escavador de recursos
  - Gatilho de invencibilidade
  - Eficiência de munição
  - Recarga especial
  - Arma secundária sempre ativa

#### 🎨 Visual & Ambiente
- `ParticleEffectComponent` - Efeitos de partículas
- `ScrollComponent` - Scrolling parallax
- **`BackgroundData` Resource** - Sistema parametrizável de backgrounds
  - Múltiplas camadas de parallax scrolling
  - Suporte a imagens com tiling
  - Estrelas procedurais configuráveis
  - Blend modes (Mix, Add, Multiply)
  - Reutilizável entre fases
  - Troca dinâmica em runtime

#### 🔊 Áudio
- `AudioComponent` - Gerenciamento de sons e músicas

#### 🎛️ Input
- `InputComponent` - Gerenciamento centralizado de inputs

#### 🤖 IA & Comportamento
- `StateMachine` - Máquina de estados genérica
- Estados customizáveis

## 🚀 Começando

### Pré-requisitos
- Godot 4.5 ou superior
- Sistema operacional: Windows, Linux ou macOS

### Instalação

1. Clone o repositório:
```bash
git clone https://github.com/seu-usuario/MilitiaForge2D.git
cd MilitiaForge2D
```

2. Abra o projeto no Godot 4.x

3. Explore os exemplos:
   - `examples/space_shooter/scenes/main_game.tscn` - Jogo completo de space shooter
   - `sandbox/test_scenes/` - Demonstrações de componentes individuais

## 🎮 Exemplo: Space Shooter

O projeto inclui um exemplo completo de Space Shooter com:

### Funcionalidades Implementadas
- ✅ Sistema de naves com diferentes características
- ✅ Sistema de armas com 3 slots (PRIMARY, SECONDARY, SPECIAL)
- ✅ Sistema de habilidades de pilotos
- ✅ Sistema de pontuação com combos
- ✅ Background parametrizado com parallax scrolling
- ✅ Sistema de ondas de inimigos
- ✅ Pool de objetos para performance
- ✅ HUD completo com informações
- ✅ Menu principal e seleção de naves

### Como Usar Backgrounds Parametrizados

1. Gerar resources de background (executar uma vez):
```
File → Run → Selecionar create_background_resources.gd
```

2. Aplicar na cena:
```gdscript
# No Inspector do nó Background
Background Data: [Arraste nebula_purple_blue.tres]
```

3. Criar novos backgrounds para outras fases:
```gdscript
var data = BackgroundData.new()
data.background_name = "Minha Fase"
data.add_image_layer(texture, 0.5, Vector2.ONE, true, 1.0, "Mix")
data.add_star_layer(50, 30.0, 2.0, 0.5, Color.WHITE, true, 2.0)
```

Consulte [BACKGROUND_SYSTEM_GUIDE.md](examples/space_shooter/docs/BACKGROUND_SYSTEM_GUIDE.md) para detalhes.

## 📖 Documentação

### Arquitetura
- [Princípios SOLID](docs/architecture/SOLID_PRINCIPLES.md)
- [Sistema de Componentes](docs/components/)

### Guias
- [Criação de Componentes](docs/guidelines/COMPONENT_CREATION.md)
- [Sistema de Backgrounds](examples/space_shooter/docs/BACKGROUND_SYSTEM_GUIDE.md)

### Exemplos
- [Space Shooter README](examples/space_shooter/README.md)

## 🔧 Versão Atual

**v0.8.0** - Sistema de Habilidades e Backgrounds Parametrizados

### Novidades v0.8.0
- ✨ **PilotAbilitySystem** - Sistema completo de habilidades de pilotos
- ✨ **BackgroundData Resource** - Backgrounds parametrizados com parallax
- ✨ **ScoreComponent melhorado** - Sinal `enemy_killed` e método `register_enemy_kill()`
- 🐛 Correções de inicialização em componentes
- 📚 Documentação expandida

### Recursos Completos
- Core com 15+ componentes prontos
- Sistema de habilidades de pilotos com 8 tipos
- Sistema de backgrounds parametrizável
- Gerenciamento de slots de armas (3 slots)
- Sistema de pontuação com combos e ranks
- ComponentHost para gerenciamento de ciclo de vida
- StateMachine para gerenciamento de comportamento
- Sistema de movimento (TopDown, Platformer, Bounded, Dash)
- Sistema de vida (dano, cura, morte, i-frames)
- Sistema de combate (projéteis, armas, colisões)
- Sistema de progressão (score, powerups, habilidades)
- Sistema de ambiente (scroll, backgrounds)
- Sistema de efeitos (partículas)
- Sistema de áudio (sons, músicas)
- Sandbox de testes abrangente
- Exemplo completo de Space Shooter
- Documentação completa

## 🎯 Roadmap

### Curto Prazo
- [ ] Sistema de customização de naves (UI)
- [ ] Sistema de pilotos com seleção
- [ ] Mais tipos de inimigos e padrões de movimento
- [ ] Sistema de boss battles
- [ ] Backgrounds para diferentes fases
- [ ] Sistema de saves e progressão

### Médio Prazo
- [ ] Editor de fases in-game
- [ ] Sistema de achievements
- [ ] Suporte a gamepad completo
- [ ] Efeitos visuais avançados (shaders)
- [ ] Sistema de diálogos
- [ ] Tutorial integrado

### Longo Prazo
- [ ] Multiplayer local
- [ ] Sistema de mods
- [ ] Level editor
- [ ] Exportação para múltiplas plataformas

## 🤝 Contribuindo

Este é um framework em desenvolvimento ativo. Contribuições são bem-vindas!

### Como Contribuir
1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/NovaFuncionalidade`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/NovaFuncionalidade`)
5. Abra um Pull Request

### Diretrizes
- Siga os princípios SOLID
- Mantenha o padrão de componentes existente
- Documente novos componentes
- Adicione testes quando possível
- Use commits em português

## 📝 Licença

[A ser definido]

## 👥 Autores

- **Gustavo** - Desenvolvimento principal

## 🙏 Agradecimentos

- Godot Engine team pela excelente engine
- Comunidade Godot pelas contribuições e feedback

---

**Desenvolvido com ❤️ usando Godot 4.5**
