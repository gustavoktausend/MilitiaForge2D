## Script helper para criar BackgroundData resources
##
## Execute este script no Godot Editor para criar resources de background pré-configurados.
## Tool script - pode ser executado no editor.

@tool
extends EditorScript

func _run() -> void:
	print("=".repeat(60))
	print("Criando Background Resources...")
	print("=".repeat(60))
	
	# Criar diretório se não existir
	var dir = DirAccess.open("res://examples/space_shooter/resources/backgrounds")
	if not dir:
		DirAccess.make_dir_recursive_absolute("res://examples/space_shooter/resources/backgrounds")
	
	# Carregar a textura da nebulosa
	var nebula_texture = load("res://examples/space_shooter/assets/backgrounds/nebula_purple_blue.jpg") as Texture2D
	
	if not nebula_texture:
		push_error("Não foi possível carregar a textura da nebulosa!")
		print("ERRO: Textura não encontrada em res://examples/space_shooter/assets/backgrounds/nebula_purple_blue.jpg")
		return
	
	# Criar BackgroundData para Nebulosa Roxa e Azul
	var nebula_bg = create_nebula_background(nebula_texture)
	var save_path = "res://examples/space_shooter/resources/backgrounds/nebula_purple_blue.tres"
	var error = ResourceSaver.save(nebula_bg, save_path)
	
	if error == OK:
		print("✅ Background 'Nebulosa Roxa e Azul' criado com sucesso!")
		print("   Caminho: %s" % save_path)
	else:
		push_error("Erro ao salvar background: %d" % error)
	
	# Criar BackgroundData apenas com estrelas (para comparação/fallback)
	var starfield_bg = create_starfield_background()
	save_path = "res://examples/space_shooter/resources/backgrounds/starfield_classic.tres"
	error = ResourceSaver.save(starfield_bg, save_path)
	
	if error == OK:
		print("✅ Background 'Campo de Estrelas' criado com sucesso!")
		print("   Caminho: %s" % save_path)
	else:
		push_error("Erro ao salvar background: %d" % error)
	
	print("=".repeat(60))
	print("Resources de background criados! Você pode usá-los nas suas cenas.")
	print("=".repeat(60))

## Criar configuração de background com nebulosa
func create_nebula_background(nebula_texture: Texture2D) -> BackgroundData:
	var data = BackgroundData.new()
	data.background_name = "Nebulosa Roxa e Azul"
	data.background_color = Color(0.02, 0.02, 0.1, 1.0)
	data.enable_stars = true
	
	# Configurar camada de imagem da nebulosa (parallax lento para dar profundidade)
	data.add_image_layer(
		nebula_texture,    # texture
		0.3,               # scroll_speed_multiplier
		Vector2(1.0, 1.0), # scale
		true,              # tiling
		0.8,               # opacity
		"Mix"              # blend_mode
	)
	
	# Adicionar camada duplicada mais rápida para efeito de profundidade
	data.add_image_layer(
		nebula_texture,    # texture
		0.6,               # scroll_speed_multiplier
		Vector2(1.2, 1.2), # scale
		true,              # tiling
		0.3,               # opacity
		"Add"              # blend_mode - brilho aditivo
	)
	
	# Configurar estrelas em 3 camadas de parallax
	# Estrelas distantes
	data.add_star_layer(
		40,                           # count
		20.0,                         # speed
		1.0,                          # size
		0.3,                          # size_variance
		Color(0.6, 0.6, 0.8, 0.4),   # color
		true,                         # enable_twinkle
		1.5                           # twinkle_speed
	)
	
	# Estrelas médias
	data.add_star_layer(
		50,
		40.0,
		2.0,
		0.5,
		Color(0.8, 0.8, 1.0, 0.7),
		true,
		2.0
	)
	
	# Estrelas próximas
	data.add_star_layer(
		30,
		60.0,
		3.0,
		0.8,
		Color(1.0, 1.0, 1.0, 1.0),
		true,
		2.5
	)
	
	return data

## Criar configuração apenas com estrelas (sem imagem de fundo)
func create_starfield_background() -> BackgroundData:
	var data = BackgroundData.new()
	data.background_name = "Campo de Estrelas Clássico"
	data.background_color = Color.BLACK
	data.enable_stars = true
	
	# Mais estrelas para compensar a falta de imagem de fundo
	data.add_star_layer(60, 15.0, 1.0, 0.3, Color(0.7, 0.7, 0.8, 0.5), true, 1.0)
	data.add_star_layer(100, 35.0, 2.0, 0.5, Color(0.9, 0.9, 1.0, 0.8), true, 2.0)
	data.add_star_layer(60, 55.0, 3.0, 1.0, Color.WHITE, true, 3.0)
	
	return data
