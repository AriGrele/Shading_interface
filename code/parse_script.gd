extends Node2D

var shader
var input
var image
var textures={}

func load_image(path):
	var image=Image.load_from_file(path)
	var texture=ImageTexture.create_from_image(image)
	return(texture)

func _ready():
	input=get_node('../screen/cols/text/script')
	image=get_node('../screen/cols/himage/vimage/imagerect').material
	
	shader=Shader.new()

func _on_script_text_changed():
	
	var value         = Array(input.get_text().split('shader_type'))
	var options       = value.pop_at(0)
	var shader_script = 'shader_type'+''.join(value)
	var parms         = {}
	
	shader.set_code(shader_script)
	image.set_shader(shader)
	
	for option in options.split('\n'):
		var pair=Array(option.split(':'))

		if len(pair)>1:
			var types=pair.pop_at(0)
			var item=':'.join(pair)
			
			if ' ' in types:
				pair=Array(types.split(' '))
				
				var type=pair.pop_at(0)
				var Name=' '.join(pair[1])
				if type=='sampler2D':
					if not textures.has(item):
						textures[item]=load_image(item)
					item=textures[item]

				image.set_shader_parameter(Name,item)
			else:
				parms[types]=item
				
	var image_texture=image.get_shader_parameter('COLOR')
	print(image_texture)

