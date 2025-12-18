# 🎨 Guia de Importação de Sprites

## Problema: Fundo Aparecendo na Tela

Se você está vendo um fundo colorido (xadrez, branco, etc.) ao redor da nave, é porque o PNG não está com transparência configurada corretamente no Godot.

---

## ✅ SOLUÇÃO: Configurar Importação PNG

### **Passo 1: Selecionar o Arquivo**
1. Abra o Godot Editor
2. No painel **FileSystem** (canto inferior esquerdo)
3. Navegue até: `res://examples/space_shooter/assets/sprites/player/`
4. **Clique uma vez** no arquivo `ship.png` para selecioná-lo

### **Passo 2: Configurar Import**
1. No painel **Import** (canto superior direito, ao lado de Scene/Import)
2. Configure as seguintes opções:

```
┌─ Compress ─────────────────────┐
│ Mode: VRAM Compressed          │  ← Para economizar memória
│ OU                             │
│ Mode: Lossless                 │  ← Para qualidade máxima
└────────────────────────────────┘

┌─ Mipmaps ──────────────────────┐
│ Generate: ☑ (checked)          │
└────────────────────────────────┘

┌─ Process ──────────────────────┐
│ Fix Alpha Border: ☑ (checked)  │  ← IMPORTANTE para remover borda
└────────────────────────────────┘

┌─ Detect 3D ────────────────────┐
│ Compress To: VRAM Compressed   │
└────────────────────────────────┘
```

### **Passo 3: Pixel Art (Se aplicável)**
Se a nave parecer **borrada** ou **desfocada**:

```
┌─ Filter ───────────────────────┐
│ ☑ Nearest                      │  ← Para pixel art nítido
│ ☐ Linear (padrão)              │
└────────────────────────────────┘
```

### **Passo 4: Reimportar**
1. Depois de configurar, clique no botão **"Reimport"** no fundo do painel Import
2. Aguarde o Godot processar
3. Execute o jogo novamente (F6)

---

## 🖼️ ALTERNATIVA: Exportar PNG Corretamente

Se o fundo ainda aparecer, o problema pode estar no arquivo PNG original:

### **Verificar Transparência:**
1. Abra `ship.png` em um editor de imagem (Photoshop, GIMP, Aseprite, etc.)
2. Verifique se a imagem tem **canal alpha** (transparência)
3. Certifique-se de que o fundo está **transparente** (não branco/preto)

### **GIMP:**
1. Layer → Transparency → Add Alpha Channel
2. Use a ferramenta de borracha no fundo
3. File → Export As → ship.png
4. Salvar com opções: **Save background color: ☐** (desmarcado)

### **Aseprite:**
1. File → Export → Export as PNG
2. Certifique-se de que "Transparent Color" está marcado

### **Photoshop:**
1. Delete o layer de background
2. File → Export → Export As
3. Formato: PNG
4. Transparency: ☑ (marcado)

---

## 🔧 Ajustes de Escala

O código já está configurado para **escalar automaticamente** o sprite para 48 pixels de altura.

### **Para Ajustar o Tamanho:**

Edite `player_controller.gd` linha 193:

```gdscript
# Mudar este valor:
var desired_height = 48.0  // ← Altura em pixels

# Exemplos:
var desired_height = 64.0  // Nave maior
var desired_height = 32.0  // Nave menor
```

### **Para Escala Manual:**

Se preferir controlar a escala manualmente:

```gdscript
# Substituir o cálculo automático por:
sprite.scale = Vector2(0.5, 0.5)  // 50% do tamanho original
sprite.scale = Vector2(0.25, 0.25)  // 25% do tamanho original
sprite.scale = Vector2(1.0, 1.0)  // Tamanho original
```

---

## 📐 Ajustar Collision Shape (Hurtbox)

Se após ajustar o sprite o Hurtbox estiver desalinhado:

1. Abra `player_controller.gd`
2. Encontre linha ~67 (em `_setup_components()`)
3. Ajuste o tamanho:

```gdscript
var shape = RectangleShape2D.new()
shape.size = Vector2(32, 48)  // ← Ajuste para tamanho do sprite

// Exemplos:
shape.size = Vector2(40, 56)  // Nave maior
shape.size = Vector2(24, 36)  // Nave menor
```

---

## ✅ Checklist de Verificação

```
☐ PNG tem transparência (canal alpha)
☐ Fundo do PNG está transparente (não branco/preto)
☐ Godot Import configurado corretamente
☐ Reimportou após configurar
☐ Escala ajustada (se necessário)
☐ Collision shape ajustado (se necessário)
☐ Sprite centralizado (centered = true)
```

---

## 🎮 Resultado Esperado

Após seguir esses passos:
- ✅ Nave aparece com tamanho correto (~48px altura)
- ✅ Sem fundo/borda ao redor da nave
- ✅ Sprite nítido (se pixel art)
- ✅ Centralizado no player
- ✅ Colisões alinhadas com o visual

---

## 🐛 Troubleshooting

### **Problema: Sprite ainda muito grande**
→ Aumente o `desired_height` ou use `sprite.scale = Vector2(0.3, 0.3)`

### **Problema: Sprite borrado**
→ Configure Filter para "Nearest" na importação

### **Problema: Fundo ainda aparece**
→ Verifique se o PNG tem canal alpha e fundo transparente

### **Problema: Sprite não centralizado**
→ Verifique se `sprite.centered = true` está no código

### **Problema: Colisões erradas**
→ Ajuste `shape.size` para match com o sprite visual

---

**Qualquer dúvida, execute o jogo e verifique os logs no console! O código imprime a escala calculada.**
