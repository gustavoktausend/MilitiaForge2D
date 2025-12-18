# Player Ship Sprite

## Instruções para adicionar o sprite:

1. Salve a imagem da nave do player como: `ship.png`
2. Coloque neste diretório: `examples/space_shooter/assets/sprites/player/`
3. O caminho completo deve ser: `C:\Users\Gustavo\Documents\MilitiaForge2D\examples\space_shooter\assets\sprites\player\ship.png`

## Especificações Recomendadas:

- **Formato:** PNG com transparência (alpha channel)
- **Tamanho:** Aproximadamente 64x64 pixels (ou similar, o Godot escala automaticamente)
- **Orientação:** Nave apontando para CIMA (↑)
- **Centro:** A nave deve estar centralizada na imagem para rotacionar corretamente

## Após adicionar o sprite:

1. Abra o Godot
2. Espere o editor importar a imagem automaticamente
3. Execute o jogo (F6 na cena main_game.tscn)
4. A nave deve aparecer com o sprite ao invés do retângulo azul

## Verificação:

Se você vir no console:
- ✅ `[Player] Loaded sprite from: res://examples/space_shooter/assets/sprites/player/ship.png`
  → Sprite carregado com sucesso!

- ❌ `[Player] Sprite not found at ..., using placeholder`
  → Sprite não foi encontrado, verifique o caminho do arquivo

## Ajustes Futuros:

Depois que o sprite estiver funcionando, podemos adicionar:
- Animação de engine trail (rastro)
- Animação de banking (inclinação ao mover lateralmente)
- Sprite de dano (visual quando toma hit)
- Diferentes skins/naves para escolher
