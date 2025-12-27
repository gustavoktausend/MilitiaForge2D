# Weapon System Guide

## 📦 Sistema de Slots de Armas Múltiplas

O Space Shooter agora possui um sistema robusto de **3 slots de armas independentes**, seguindo princípios SOLID e design patterns.

---

## 🎯 Categorias de Armas

### **PRIMARY (Slot 0) - Tiro Padrão**
- ✅ Munição **infinita**
- ✅ Dispara junto com SECONDARY ao pressionar **SPACE**
- ✅ Sempre disponível
- 📌 Use para: DPS constante, arma principal

### **SECONDARY (Slot 1) - Tiro Auxiliar**
- ⚡ Munição **renovável** (recarrega entre fases)
- ✅ Dispara junto com PRIMARY ao pressionar **SPACE**
- ✅ Cooldown moderado ou munição limitada
- 📌 Use para: Burst damage, arma de suporte

### **SPECIAL (Slot 2) - Arma Pesada**
- 💥 Munição **finita e limitada** (ex: 2-5 cargas)
- 🔄 **Recarrega automaticamente** ao trocar de fase
- ✅ Disparo independente com **ALT**
- 📌 Use para: Situações de emergência, boss fights

---

## 🔫 Armas Disponíveis

### PRIMARY Weapons

| Nome | Tipo | Dano | Fire Rate | Descrição |
|------|------|------|-----------|-----------|
| **Basic Laser** | SINGLE | 10 | 0.2s (5/s) | Arma padrão balanceada |
| **Spread Shot** | SPREAD (3x) | 8/proj | 0.25s (4/s) | Boa cobertura de área |
| **Rapid Fire** | SINGLE | 6 | 0.1s (10/s) | Alto DPS, baixo dano |

### SECONDARY Weapons

| Nome | Tipo | Dano | Munição | Especial | Descrição |
|------|------|------|---------|----------|-----------|
| **Homing Missile** | SINGLE | 25 | 20 | 🎯 Homing | Mísseis teleguiados |
| **Shotgun Blast** | SPREAD (5x) | 12/proj | 15 | Wide spread | Devastador de perto |
| **Burst Cannon** | BURST (3x) | 15/shot | 30 (10 bursts) | Quick burst | Dano controlado |

### SPECIAL Weapons

| Nome | Tipo | Dano | Munição | Especial | Descrição |
|------|------|------|---------|----------|-----------|
| **Plasma Bomb** | SINGLE | 50 + 40 AoE | 3 | 💣 Explosive | Explosão massiva |
| **Railgun** | SINGLE | 80 | 5 | ⚡ Piercing | Perfura tudo |
| **EMP Pulse** | SINGLE | 30 + 20 AoE | 2 | 🔵 Large AoE | Desabilita inimigos |

---

## 🎮 Como Usar no Editor

### **1. Configurar Armas no PlayerController**

Abra a cena do player e configure no Inspector:

```
PlayerController
  ├── Weapons
  │   ├── Primary Weapon Name: "spread_shot"      # Escolha: basic_laser, spread_shot, rapid_fire
  │   ├── Secondary Weapon Name: "shotgun_blast"  # Escolha: homing_missile, shotgun_blast, burst_cannon
  │   └── Special Weapon Name: "plasma_bomb"      # Escolha: plasma_bomb, railgun, emp_pulse
```

**Dica:** Deixe Secondary ou Special **vazios** se não quiser equipar.

### **2. Testar no Jogo**

- **SPACE** - Dispara PRIMARY + SECONDARY simultaneamente
- **ALT** - Dispara SPECIAL (munição limitada)
- **Z** - Liga/Desliga SECONDARY weapon (economize munição!)
- **WASD/Setas** - Movimento

**💡 Dica:** Desabilite a SECONDARY com **Z** quando quiser economizar munição para momentos críticos!

---

## 💻 Como Usar em Código

### **Equipar Armas Programaticamente**

```gdscript
# Via WeaponDatabase (Factory Pattern)
var primary = WeaponDatabase.get_primary_weapon("rapid_fire")
var secondary = WeaponDatabase.get_secondary_weapon("homing_missile")
var special = WeaponDatabase.get_special_weapon("railgun")

weapon_manager.equip_weapon(WeaponData.Category.PRIMARY, primary)
weapon_manager.equip_weapon(WeaponData.Category.SECONDARY, secondary)
weapon_manager.equip_weapon(WeaponData.Category.SPECIAL, special)
```

### **Disparar Armas Manualmente**

```gdscript
# Disparar PRIMARY + SECONDARY juntos (SECONDARY só dispara se enabled)
weapon_manager.fire_primary_and_secondary()

# Disparar apenas PRIMARY
weapon_manager.fire_primary()

# Disparar apenas SECONDARY (se enabled)
weapon_manager.fire_secondary()

# Disparar SPECIAL
weapon_manager.fire_special()
```

### **Controlar SECONDARY Weapon (Toggle)**

```gdscript
# Toggle SECONDARY on/off (retorna novo estado)
var enabled = weapon_manager.toggle_secondary_weapon()
print("SECONDARY is now: %s" % ("ON" if enabled else "OFF"))

# Habilitar SECONDARY
weapon_manager.enable_secondary_weapon()

# Desabilitar SECONDARY (economizar munição)
weapon_manager.disable_secondary_weapon()

# Setar estado diretamente
weapon_manager.set_secondary_enabled(true)  # Liga
weapon_manager.set_secondary_enabled(false) # Desliga

# Verificar se está habilitado
if weapon_manager.is_secondary_enabled():
    print("SECONDARY is enabled!")
```

### **Gerenciar Munição**

```gdscript
# Adicionar munição ao SECONDARY
weapon_manager.add_ammo(WeaponData.Category.SECONDARY, 10)

# Recarregar SPECIAL
weapon_manager.refill_ammo(WeaponData.Category.SPECIAL)

# Recarregar todas as armas (chamado automaticamente ao trocar fase)
weapon_manager.refill_on_phase_change()

# Verificar munição
var ammo = weapon_manager.get_ammo(WeaponData.Category.SPECIAL)
var max_ammo = weapon_manager.get_max_ammo(WeaponData.Category.SPECIAL)
print("SPECIAL ammo: %d/%d" % [ammo, max_ammo])
```

### **Escutar Eventos**

```gdscript
# Conectar aos signals do WeaponSlotManager
weapon_manager.weapon_fired.connect(_on_weapon_fired)
weapon_manager.ammo_changed.connect(_on_ammo_changed)
weapon_manager.weapon_empty.connect(_on_weapon_empty)
weapon_manager.secondary_toggled.connect(_on_secondary_toggled)

func _on_weapon_fired(slot: int, weapon_name: String):
    print("Fired %s from slot %d" % [weapon_name, slot])

func _on_ammo_changed(slot: int, current: int, maximum: int):
    # Atualizar HUD
    update_ammo_ui(slot, current, maximum)

func _on_weapon_empty(slot: int):
    # Tocar som de "click"
    play_empty_sound()

func _on_secondary_toggled(enabled: bool):
    # Atualizar UI e tocar som
    if enabled:
        show_notification("SECONDARY ENABLED")
        play_sound("weapon_on")
    else:
        show_notification("SECONDARY DISABLED")
        play_sound("weapon_off")
```

---

## 🛠️ Como Criar Novas Armas

### **1. Adicionar ao WeaponDatabase**

Edite `weapon_database.gd` e adicione um método factory:

```gdscript
## Create Laser Beam weapon (continuous beam)
static func create_laser_beam() -> WeaponData:
    var weapon = WeaponData.new()

    weapon.weapon_name = "Laser Beam"
    weapon.description = "Continuous high-powered laser beam"
    weapon.category = WeaponData.Category.SECONDARY

    weapon.weapon_type = WeaponComponent.WeaponType.BEAM
    weapon.damage = 5  # DPS = 5 * 60 = 300 per second
    weapon.fire_rate = 0.1
    weapon.projectile_speed = 0  # Instant beam

    weapon.infinite_ammo = false
    weapon.max_ammo = 100
    weapon.refill_on_phase = true

    return weapon
```

### **2. Adicionar ao getter correspondente**

```gdscript
static func get_secondary_weapon(weapon_name: String) -> WeaponData:
    match weapon_name.to_lower():
        # ... existing weapons ...
        "laser_beam":
            return create_laser_beam()
        _:
            push_warning("[WeaponDatabase] Unknown SECONDARY weapon: %s" % weapon_name)
            return null
```

### **3. Atualizar lista de nomes**

```gdscript
static func get_secondary_weapon_names() -> Array[String]:
    return ["homing_missile", "shotgun_blast", "burst_cannon", "laser_beam"]
```

### **4. Atualizar export enum no PlayerController**

```gdscript
@export_enum("homing_missile", "shotgun_blast", "burst_cannon", "laser_beam") var secondary_weapon_name: String = ""
```

Pronto! Sua nova arma estará disponível no Inspector e via código.

---

## 🎨 Design Patterns Utilizados

- ✅ **Factory Pattern** - WeaponDatabase cria weapons
- ✅ **Strategy Pattern** - Diferentes modos de disparo
- ✅ **Observer Pattern** - Signals para eventos
- ✅ **Component Pattern** - Composição de funcionalidades
- ✅ **Dependency Injection** - Pool manager, projectiles container

## 📐 Princípios SOLID

- ✅ **Single Responsibility** - Cada classe tem uma função
- ✅ **Open/Closed** - Extensível sem modificação
- ✅ **Liskov Substitution** - WeaponData intercambiável
- ✅ **Interface Segregation** - APIs mínimas e focadas
- ✅ **Dependency Inversion** - Depende de abstrações

---

## 🚀 Próximos Passos

- [ ] Implementar projectiles especiais (homing, piercing, explosive)
- [ ] Criar sistema de drop/pickup de armas
- [ ] Adicionar HUD para mostrar munição
- [ ] Criar visual effects para cada arma
- [ ] Adicionar sons únicos por arma
- [ ] Sistema de upgrade de armas (níveis)

---

**Desenvolvido com ❤️ usando MilitiaForge2D Framework**
