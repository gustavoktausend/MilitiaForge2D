## Parallax Background System
##
## Sistema de background parametrizável com suporte a:
## - Múltiplas camadas de imagem com parallax scrolling
## - Estrelas procedurais em camadas
## - Configuração via BackgroundData resource
##
## Pode ser facilmente reutilizado em diferentes fases do jogo.

extends Node2D

#region Exports
## Configuração do background (use BackgroundData resource)
@export var background_data: BackgroundData

## Velocidade base de scroll (pixels/segundo)
@export var base_scroll_speed: float = 50.0

## Se true, usa configuração padrão caso background_data seja null
@export var use_default_if_null: bool = true
#endregion

#region Private Variables
## Camadas de imagem renderizadas
var _image_layers: Array[Dictionary] = []

## Estrelas procedurais
var _stars: Array[Dictionary] = []

## Tamanho da viewport
var _viewport_size: Vector2

## Sprites para as camadas de imagem
var _layer_sprites: Array[Sprite2D] = []
#endregion

#region Lifecycle
func _ready() -> void:
	_viewport_size = get_viewport_rect().size
	
	# Usar configuração padrão se necessário
	if not background_data and use_default_if_null:
		background_data = BackgroundData.create_default_nebula()
		print("[SpaceBackground] Usando configuração padrão de nebulosa")
	
	if not background_data:
		push_error("[SpaceBackground] Nenhum BackgroundData configurado!")
		return
	
	_setup_background()

func _setup_background() -> void:
	# Configurar cor de fundo
	RenderingServer.set_default_clear_color(background_data.background_color)
	
	# Configurar camadas de imagem
	if background_data.image_layers.size() > 0:
		_setup_image_layers()
	
	# Configurar estrelas procedurais
	if background_data.enable_stars and background_data.star_layers.size() > 0:
		_setup_star_layers()
	
	print("[SpaceBackground] Background '%s' configurado com sucesso!" % background_data.background_name)
	print("  - Camadas de imagem: %d" % background_data.image_layers.size())
	print("  - Camadas de estrelas: %d" % background_data.star_layers.size())

func _process(delta: float) -> void:
	_update_image_layers(delta)
	_update_stars(delta)
	queue_redraw()  # Redesenhar estrelas procedurais
#endregion

#region Image Layers
func _setup_image_layers() -> void:
	for i in range(background_data.image_layers.size()):
		var layer_config: Dictionary = background_data.image_layers[i]
		
		if not layer_config.has("texture") or not layer_config.texture:
			push_warning("[SpaceBackground] Camada %d não tem textura!" % i)
			continue
		
		# Criar sprite para esta camada
		var sprite = Sprite2D.new()
		sprite.texture = layer_config.texture
		sprite.scale = layer_config.get("scale", Vector2.ONE)
		sprite.modulate.a = layer_config.get("opacity", 1.0)
		sprite.centered = false
		sprite.position = layer_config.get("initial_offset", Vector2.ZERO)
		
		# Configurar blend mode
		var blend_mode = layer_config.get("blend_mode", "Mix")
		match blend_mode:
			"Add":
				sprite.material = CanvasItemMaterial.new()
				sprite.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			"Multiply":
				sprite.material = CanvasItemMaterial.new()
				sprite.material.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
		
		add_child(sprite)
		_layer_sprites.append(sprite)
		
		# Armazenar dados da camada para scrolling
		var texture_height = layer_config.texture.get_height() * layer_config.get("scale", Vector2.ONE).y
		var layer_data = {
			"sprite": sprite,
			"config": layer_config,
			"offset_y": layer_config.get("initial_offset", Vector2.ZERO).y,
			"texture_height": texture_height
		}
		_image_layers.append(layer_data)
		
		# Se tiling está habilitado, criar sprite duplicado para scroll contínuo
		if layer_config.get("tiling", true):
			var sprite_duplicate = Sprite2D.new()
			sprite_duplicate.texture = layer_config.texture
			sprite_duplicate.scale = layer_config.get("scale", Vector2.ONE)
			sprite_duplicate.modulate.a = layer_config.get("opacity", 1.0)
			sprite_duplicate.centered = false
			sprite_duplicate.position = Vector2(
				layer_config.get("initial_offset", Vector2.ZERO).x,
				layer_config.get("initial_offset", Vector2.ZERO).y - texture_height
			)
			
			# Copiar material se existir
			if sprite.material:
				sprite_duplicate.material = sprite.material.duplicate()
			
			add_child(sprite_duplicate)
			layer_data["sprite_duplicate"] = sprite_duplicate

func _update_image_layers(delta: float) -> void:
	for layer_data in _image_layers:
		var config: Dictionary = layer_data.config
		var scroll_speed = base_scroll_speed * config.get("scroll_speed_multiplier", 1.0)
		
		# Atualizar offset
		layer_data.offset_y += scroll_speed * delta
		
		# Aplicar posição aos sprites
		layer_data.sprite.position.y = layer_data.offset_y
		
		# Wrap around para tiling
		if config.get("tiling", true):
			var texture_height = layer_data.texture_height
			
			if layer_data.offset_y >= texture_height:
				layer_data.offset_y -= texture_height
			
			# Atualizar sprite duplicado
			if layer_data.has("sprite_duplicate"):
				layer_data.sprite_duplicate.position.y = layer_data.offset_y - texture_height
#endregion

#region Star Layers
func _setup_star_layers() -> void:
	for layer_config in background_data.star_layers:
		_create_star_layer(layer_config)

func _create_star_layer(config: Dictionary) -> void:
	var count = config.get("count", 30)
	var speed = config.get("speed", 50.0)
	var size = config.get("size", 2.0)
	var size_variance = config.get("size_variance", 0.5)
	var color = config.get("color", Color.WHITE)
	var enable_twinkle = config.get("enable_twinkle", true)
	var twinkle_speed = config.get("twinkle_speed", 2.0)
	
	for i in range(count):
		var star = {
			"position": Vector2(
				randf_range(0, _viewport_size.x),
				randf_range(0, _viewport_size.y)
			),
			"speed": speed,
			"size": size + randf_range(-size_variance, size_variance),
			"color": color,
			"enable_twinkle": enable_twinkle,
			"twinkle": randf_range(0, TAU),
			"twinkle_speed": twinkle_speed
		}
		_stars.append(star)

func _update_stars(delta: float) -> void:
	for star in _stars:
		# Mover estrela para baixo
		star.position.y += star.speed * delta
		
		# Wrap around quando sair da tela
		if star.position.y > _viewport_size.y + 10:
			star.position.y = -10
			star.position.x = randf_range(0, _viewport_size.x)
		
		# Atualizar tremulação
		if star.enable_twinkle:
			star.twinkle += delta * star.twinkle_speed

func _draw() -> void:
	# Desenhar apenas as estrelas procedurais
	# (as imagens são desenhadas via Sprite2D nodes)
	for star in _stars:
		var star_color = star.color
		
		# Aplicar efeito de tremulação
		if star.enable_twinkle:
			var twinkle_alpha = 0.7 + sin(star.twinkle) * 0.3
			star_color.a *= twinkle_alpha
		
		# Desenhar estrela
		draw_circle(star.position, star.size, star_color)
		
		# Adicionar brilho para estrelas maiores
		if star.size > 2.0:
			var glow_color = star_color
			glow_color.a *= 0.3
			draw_circle(star.position, star.size * 2.0, glow_color)
#endregion

#region Public Methods
## Trocar a configuração do background em runtime
func set_background_data(new_data: BackgroundData) -> void:
	# Limpar background atual
	_clear_background()
	
	# Aplicar nova configuração
	background_data = new_data
	_setup_background()

## Limpar todos os elementos do background
func _clear_background() -> void:
	# Remover sprites de camadas de imagem
	for sprite in _layer_sprites:
		sprite.queue_free()
	_layer_sprites.clear()
	_image_layers.clear()
	
	# Limpar estrelas
	_stars.clear()

## Ajustar velocidade base em runtime
func set_scroll_speed(speed: float) -> void:
	base_scroll_speed = speed
#endregion
