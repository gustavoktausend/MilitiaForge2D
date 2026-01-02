# Sistema de Partículas - Space Shooter

## ✅ Implementação Completa

Sistema completo de efeitos de partículas com estilo neon para o jogo Space Shooter.

## 🎨 Efeitos Criados

### 1. Explosão de Inimigos (`explosion_particles.gd`)

**Localização:** `effects/explosion_particles.gd`

**Funcionalidade:**
- Explosão neon RADIAL 360° quando inimigos são destruídos
- Partículas explodem em todas as direções (não apenas vertical)
- Flash branco inicial seguido da cor do inimigo
- Auto-destruição após animação completa

**Características Técnicas:**
- **50 partículas** por explosão
- **Lifetime:** 1.0 segundo
- **Explosiveness:** 0.9 (leve variação para naturalidade)
- **Randomness:** 0.7 (alta variação de direção e velocidade)
- **Spread:** 180° (cobertura completa em 2D)
- **Radial Acceleration:** Empurra partículas para fora do centro
- **Velocity Range:** 1.5x a 4.0x o raio (grande variação)

**Efeitos Visuais:**
- Flash branco inicial (0-10% do lifetime)
- Transição para cor do inimigo
- Partículas crescem levemente e depois encolhem
- Textura circular com gradiente suave
- Cores personalizadas por tipo de inimigo:
  - **Basic:** Rosa neon (NEON_PINK)
  - **Fast:** Amarelo neon (NEON_YELLOW)
  - **Tank:** Roxo neon (NEON_PURPLE) - explosão 50% maior
- Tamanho: 100px para Basic/Fast, 150px para Tank

**Integração:**
- Chamado automaticamente em `enemy_base.gd::_on_enemy_died()`
- Som de explosão tocado via AudioManager (se disponível)

---

### 2. Trilha de Propulsão (`engine_trail.gd`)

**Localização:** `effects/engine_trail.gd`

**Funcionalidade:**
- Efeito contínuo de propulsão da nave do jogador
- Trail de partículas que segue a nave
- Gradiente cyan/blue para efeito espacial

**Características:**
- 30 partículas (ajustável por intensidade)
- Lifetime: 0.5 segundos
- Emission contínua (not one-shot)
- Direção: para baixo (nave movendo para cima)
- Cores personalizadas por piloto:
  - **Default:** Cyan → Blue
  - **Ace:** Yellow → Orange (velocidade)
  - **Tank:** Pink → Purple (resistência)
  - **Gunner:** Red-Orange → Red (poder de fogo)

**Integração:**
- Adicionado em `player_controller.gd::_add_engine_trail()`
- Posicionado na parte traseira da nave (offset Y +36px)
- Segue automaticamente o movimento da nave

**Métodos Públicos:**
```gdscript
func set_trail_intensity(intensity: float) -> void
func set_trail_colors(start: Color, end: Color) -> void
func start_trail() -> void
func stop_trail() -> void
```

---

### 3. Impacto de Projéteis (`impact_particles.gd`)

**Localização:** `effects/impact_particles.gd`

**Funcionalidade:**
- Burst MUITO RÁPIDO quando projéteis atingem alvos
- Flash amarelo/branco para projéteis do jogador
- Flash rosa para projéteis inimigos
- Efeito quase instantâneo para feedback tátil

**Características Técnicas:**
- **20 partículas** por impacto
- **Lifetime:** 0.15 segundos (ultra rápido!)
- **Velocity Range:** 6.0x a 10.0x o tamanho do impacto
- **Radial Acceleration:** 2.0x a 4.0x (dispersão radial 360°)
- **Damping:** 250-350 (desaceleração instantânea)
- **Randomness:** 0.8 (alta dispersão)
- **Scale:** 0.8-1.8 (partículas FINAS)
- **Textura:** 2x6px (linha fina tipo "faísca")

**Efeitos Visuais:**
- Flash branco intenso inicial
- Partículas em forma de faísca fina
- Dispersão radial 360° (não apenas vertical!)
- Efeito de "spray" de fagulhas
- Encolhe instantaneamente (15% do tempo → 30% do tamanho)
- Cores:
  - **Jogador:** Amarelo neon (NEON_YELLOW)
  - **Inimigo:** Rosa neon (NEON_PINK)

**Integração:**
- Chamado em `projectile.gd::_on_hitbox_hit()`
- Som de impacto tocado via AudioManager (se disponível)

---

## 📁 Estrutura de Arquivos

```
examples/space_shooter/
├── effects/
│   ├── explosion_particles.gd   # Explosões de inimigos
│   ├── engine_trail.gd           # Trilha da nave
│   └── impact_particles.gd       # Impacto de projéteis
├── scripts/
│   ├── enemy_base.gd             # ✅ Integrado (explosões)
│   ├── player_controller.gd      # ✅ Integrado (engine trail)
│   └── projectile.gd             # ✅ Integrado (impactos)
└── PARTICLE_EFFECTS_DOCS.md      # Esta documentação
```

## 🔧 Como Funciona

### Padrão de Implementação

Todos os efeitos seguem o mesmo padrão:

1. **Criação Dinâmica:**
   ```gdscript
   var ExplosionParticles = load("res://...path.../explosion_particles.gd")
   var explosion = GPUParticles2D.new()
   explosion.set_script(ExplosionParticles)
   ```

2. **Configuração:**
   ```gdscript
   explosion.set("explosion_color", Color(1.0, 0.08, 0.58))
   explosion.set("explosion_radius", 100.0)
   ```

3. **Posicionamento:**
   ```gdscript
   explosion.global_position = impact_location
   get_tree().root.add_child(explosion)
   ```

4. **Auto-destruição:**
   - Partículas one-shot se destroem automaticamente
   - Timer aguarda `lifetime` antes de `queue_free()`

### Integração com AudioManager

Todos os efeitos tentam tocar sons se AudioManager existir:

```gdscript
if AudioManager and AudioManager.has_method("play_sfx"):
    AudioManager.play_sfx("explosion", 0.6)
```

**Sons utilizados:**
- `explosion` - Explosões de inimigos (volume 0.6)
- `impact` - Impacto de projéteis (volume 0.3)

---

## 🎯 Customização

### Mudar Cores de Explosão

Edite `enemy_base.gd::_spawn_explosion_particles()`:

```gdscript
match enemy_type:
    "NewType":
        explosion_color = Color(r, g, b)
```

### Mudar Cores de Engine Trail

Edite `player_controller.gd::_add_engine_trail()`:

```gdscript
match pilot_data.pilot_name:
    "NewPilot":
        trail_color_start = Color(r1, g1, b1)
        trail_color_end = Color(r2, g2, b2)
```

### Ajustar Intensidade de Partículas

**Explosões:**
```gdscript
explosion.set("particle_count", 100) # Mais partículas
explosion.set("explosion_radius", 200.0) # Área maior
```

**Engine Trail:**
```gdscript
trail.set("trail_intensity", 2.0) # 2x partículas
trail.set("trail_length", 100.0) # Trail mais longo
```

**Impactos:**
```gdscript
impact.set("particle_count", 40) # Mais partículas
impact.set("impact_size", 50.0) # Burst maior
```

---

## 🧪 Como Testar

### 1. Testar Explosões

1. Rode o jogo (F5)
2. Destrua inimigos
3. Observe explosões coloridas:
   - Rosa para Basic
   - Amarelo para Fast
   - Roxo para Tank

### 2. Testar Engine Trail

1. Rode o jogo (F5)
2. Observe a trilha atrás da nave do jogador
3. Trail muda de cor dependendo do piloto selecionado

### 3. Testar Impactos

1. Rode o jogo (F5)
2. Atire nos inimigos
3. Observe flash amarelo ao atingir
4. Projéteis inimigos criam flash rosa

---

## ⚙️ Configuração Avançada

### Criar Novo Efeito de Partículas

1. **Criar arquivo base:**
```gdscript
extends GPUParticles2D

func _ready() -> void:
    _setup_particles()
    one_shot = true
    emitting = true
    await get_tree().create_timer(lifetime).timeout
    queue_free()

func _setup_particles() -> void:
    # Configure ParticleProcessMaterial aqui
    var material = ParticleProcessMaterial.new()
    # ... configurações ...
    process_material = material
```

2. **Integrar no jogo:**
```gdscript
func _spawn_custom_effect() -> void:
    var CustomEffect = load("res://path/to/custom_effect.gd")
    var effect = GPUParticles2D.new()
    effect.set_script(CustomEffect)
    effect.global_position = spawn_position
    get_tree().root.add_child(effect)
```

### Paleta de Cores Neon

Use estas cores para manter consistência visual:

```gdscript
const NEON_PINK: Color = Color(1.0, 0.08, 0.58)
const NEON_CYAN: Color = Color(0.0, 0.94, 0.94)
const NEON_YELLOW: Color = Color(1.0, 0.94, 0.0)
const NEON_PURPLE: Color = Color(0.58, 0.0, 0.83)
const NEON_GREEN: Color = Color(0.0, 1.0, 0.5)
const NEON_ORANGE: Color = Color(1.0, 0.5, 0.0)
const NEON_BLUE: Color = Color(0.2, 0.6, 1.0)
const NEON_WHITE: Color = Color(1.0, 1.0, 1.0)
```

---

## 🐛 Troubleshooting

### Partículas não aparecem

**Problema:** Efeitos não visíveis no jogo

**Soluções:**
- Verifique se o script foi carregado corretamente
- Confirme que `emitting = true`
- Verifique z-index (partículas devem estar acima de outros elementos)
- Confirme que position está dentro da viewport

### Partículas aparecem no lugar errado

**Problema:** Efeitos aparecem em posição incorreta

**Soluções:**
- Use `global_position` em vez de `position`
- Adicione partículas à `get_tree().root` para evitar hierarquia
- Verifique se o objeto pai não está em movimento

### Partículas não se destroem

**Problema:** Muitas partículas ficam na memória

**Soluções:**
- Confirme que `one_shot = true`
- Verifique timer de auto-destruição
- Use `await get_tree().create_timer(lifetime).timeout` antes de `queue_free()`

### Performance ruim

**Problema:** FPS baixo com muitas partículas

**Soluções:**
- Reduza `particle_count`
- Diminua `lifetime`
- Use `fixed_fps` menor
- Considere object pooling para efeitos frequentes

---

## 📊 Comparação de Efeitos

| Efeito | Partículas | Lifetime | Velocidade | Textura | One-Shot | Auto-Free | Som |
|--------|-----------|----------|------------|---------|----------|-----------|-----|
| Explosion | 50 | 1.0s | 1.5x-4.0x raio (RADIAL 360°) | Círculo 8x8 | ✅ | ✅ | explosion (0.6) |
| Engine Trail | 30 | 0.5s | Trail contínuo | Círculo 8x8 | ❌ | ❌ | - |
| Impact | 20 | 0.15s | 6.0x-10.0x tamanho (RADIAL 360°) | Linha 2x6 (faísca) | ✅ | ✅ | impact (0.3) |

---

## 📝 Notas Técnicas

### GPUParticles2D vs CPUParticles2D

Este sistema usa **GPUParticles2D** porque:
- ✅ Melhor performance com muitas partículas
- ✅ Hardware acceleration
- ✅ Ideal para efeitos explosivos

Use **CPUParticles2D** se:
- Precisar de controle granular por partícula
- Tiver problemas de compatibilidade de GPU
- Quiser efeitos determinísticos

### Process Material

Todos os efeitos usam `ParticleProcessMaterial` para configuração:
- `emission_shape` - Forma de emissão
- `direction` / `spread` - Direção inicial
- `initial_velocity` - Velocidade das partículas
- `gravity` - Efeito de gravidade
- `damping` - Desaceleração
- `scale_curve` - Mudança de tamanho ao longo do tempo
- `color_ramp` - Gradient de cores

### Textures

Partículas usam texturas simples criadas dinamicamente:
- **Explosion:** Quadrado 4x4 branco
- **Engine Trail:** Círculo 8x8 com gradiente
- **Impact:** Círculo suave 6x6

Para melhor qualidade, substitua por sprites PNG.

---

## 🚀 Próximos Passos

Efeitos que podem ser adicionados:

1. **Power-up Collection:**
   - Burst de estrelas douradas
   - Ring effect expandindo

2. **Shield Hit:**
   - Ripple effect no escudo
   - Partículas azuis elétricas

3. **Critical Hit:**
   - Explosão maior e mais brilhante
   - Screen shake combinado

4. **Damage Sparks:**
   - Pequenas fagulhas quando inimigo toma dano
   - Não apenas na morte

5. **Warp In/Out:**
   - Efeito de teletransporte
   - Partículas convergindo/divergindo

---

**Status:** ✅ Implementado e Funcionando
**Data:** 2026-01-01
**Versão:** 1.0.0
**Compatibilidade:** Godot 4.5+
