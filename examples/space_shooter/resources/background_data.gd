## Background Data Resource
##
## Configuração de fundo para fases de batalha.
## Suporta múltiplas camadas de parallax scrolling e efeitos procedurais.
##
## Permite reutilizar configurações de background entre diferentes fases
## seguindo o princípio DRY (Don't Repeat Yourself).

class_name BackgroundData extends Resource

#region Camadas de Imagem
## Camadas de background para parallax scrolling (ordenadas de trás para frente)
## Adicione via script usando add_image_layer()
var image_layers: Array = []
#endregion

#region Efeitos Procedurais
## Habilitar estrelas procedurais
@export var enable_stars: bool = true

## Configuração das camadas de estrelas
## Adicione via script usando add_star_layer()
var star_layers: Array = []
#endregion

#region Configurações Gerais
## Cor de fundo base (caso não tenha imagens)
@export var background_color: Color = Color(0.02, 0.02, 0.05, 1.0)

## Nome descritivo do background (ex: "Nebulosa Roxa", "Campo de Asteroides")
@export var background_name: String = "Space Background"
#endregion

## Adicionar uma camada de imagem
func add_image_layer(
	texture: Texture2D,
	scroll_speed_multiplier: float = 1.0,
	scale: Vector2 = Vector2.ONE,
	tiling: bool = true,
	opacity: float = 1.0,
	blend_mode: String = "Mix",
	initial_offset: Vector2 = Vector2.ZERO
) -> void:
	var layer = {
		"texture": texture,
		"scroll_speed_multiplier": scroll_speed_multiplier,
		"scale": scale,
		"tiling": tiling,
		"opacity": opacity,
		"blend_mode": blend_mode,
		"initial_offset": initial_offset
	}
	image_layers.append(layer)

## Adicionar uma camada de estrelas
func add_star_layer(
	count: int = 30,
	speed: float = 50.0,
	size: float = 2.0,
	size_variance: float = 0.5,
	color: Color = Color.WHITE,
	enable_twinkle: bool = true,
	twinkle_speed: float = 2.0
) -> void:
	var layer = {
		"count": count,
		"speed": speed,
		"size": size,
		"size_variance": size_variance,
		"color": color,
		"enable_twinkle": enable_twinkle,
		"twinkle_speed": twinkle_speed
	}
	star_layers.append(layer)

## Cria uma configuração padrão de background espacial com nebulosa
static func create_default_nebula() -> BackgroundData:
	var data = BackgroundData.new()
	data.background_name = "Nebulosa Roxa e Azul"
	data.background_color = Color(0.02, 0.02, 0.1, 1.0)
	data.enable_stars = true
	
	# Configurar estrelas em 3 camadas de parallax
	data.add_star_layer(30, 20.0, 1.0, 0.3, Color(0.5, 0.5, 0.6, 0.3))
	data.add_star_layer(40, 40.0, 2.0, 0.5, Color(0.8, 0.8, 1.0, 0.6))
	data.add_star_layer(30, 60.0, 3.0, 0.8, Color.WHITE)
	
	return data

## Cria uma configuração com apenas campo de estrelas (sem imagem)
static func create_starfield_only() -> BackgroundData:
	var data = BackgroundData.new()
	data.background_name = "Campo de Estrelas"
	data.background_color = Color.BLACK
	data.enable_stars = true
	
	# Mais estrelas para compensar a falta de imagem de fundo
	data.add_star_layer(50, 15.0, 1.0, 0.3, Color(0.7, 0.7, 0.8, 0.4))
	data.add_star_layer(80, 35.0, 2.0, 0.5, Color(0.9, 0.9, 1.0, 0.7))
	data.add_star_layer(50, 55.0, 3.0, 1.0, Color.WHITE)
	
	return data
