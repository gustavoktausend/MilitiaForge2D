# Debug Print Cleanup Plan

## Objetivo
Remover prints de debug que poluem o console, mantendo apenas logs críticos.

## Critérios

### ✅ MANTER (Logs Críticos)
- Erros (push_error, [ERROR])
- Warnings (push_warning, [WARNING])
- Eventos críticos (morte do player, game over)
- Mensagens de erro de carregamento de recursos

### ❌ REMOVER (Debug Logs)
- Prints com box drawing (╔ ═ ║ ╚ ━)
- Logs de inicialização ("Creating...", "Loading...", "Setup...")
- Logs de eventos normais (damage taken, weapon fired, etc)
- Status updates verbosos

## Progresso

### player_controller.gd
- **Status:** Em andamento (19/105 removidos)
- **Restantes:** ~85 prints
- **Prioridade:** ALTA (arquivo mais verboso)

**Principais blocos a remover:**
- [ ] Blocos decorativos de setup (linhas 98-113, 115-125, etc)
- [ ] Logs de componentes (Creating HealthComponent, etc)
- [ ] Logs de hurtbox activation (268-279)
- [ ] Weapon loading logs (609-667)
- [ ] Damage taken logs (509-513)
- [ ] Secondary weapon toggle logs (498-503)

**Manter apenas:**
- Death event log (linha ~556: "PLAYER DIED! GAME OVER")

---

### enemy_base.gd
- **Status:** Pendente
- **Prints:** ~29
- **Prioridade:** MÉDIA

---

### game_hud.gd
- **Status:** Pendente
- **Prints:** ~34
- **Prioridade:** MÉDIA

---

### game_controller.gd
- **Status:** Pendente
- **Prints:** ~22
- **Prioridade:** MÉDIA

---

### wave_manager.gd
- **Status:** Pendente
- **Prints:** ~11
- **Prioridade:** BAIXA

---

### UI Files (main_menu, loadout, pilot_selection)
- **Status:** Pendente
- **Prints:** ~10 combined
- **Prioridade:** BAIXA

---

## Abordagem Recomendada

### Opção 1: Manual Block-by-Block (Atual)
- Pro: Controle total
- Con: Muito lento (105 prints no player_controller sozinho)

### Opção 2: Script Automatizado
- Pro: Rápido, consistente
- Con: Pode remover prints importantes acidentalmente

### Opção 3: Híbrida (Recomendado)
1. Identificar seções grandes com padrões claros (box drawing, setup logs)
2. Remover em blocos via Edit tool
3. Review manual para logs críticos

## Próximos Passos

1. **player_controller.gd** - Remover em 3 grandes blocos:
   - Bloco 1: Todos os prints com box drawing (╔═║╚━)
   - Bloco 2: Todos os prints "[Player] Creating..."
   - Bloco 3: Todos os prints de weapon loading
   - Manter: Death event

2. **enemy_base.gd** - Padrão similar

3. **UI files** - Menos críticos, podem ser mais agressivos

## Estimate
- Manual completo: ~2-3 horas
- Script automatizado: ~15 minutos + review
- Híbrida: ~45 minutos

## Decisão
Aguardando input do usuário sobre qual abordagem preferir.
