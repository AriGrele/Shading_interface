extends TextEdit



func _ready():
	var keywords = {'#d76274':[
		'void',
		'bool',
		'bvec2',
		'bvec3',
		'bvec4',
		'int',
		'ivec2',
		'ivec3',
		'ivec4',
		'uint',
		'uvec2',
		'uvec3',
		'uvec4',
		'float',
		'vec2',
		'vec3',
		'vec4',
		'mat2',
		'mat3',
		'mat4',
		'sampler2D',
		'isampler2D',
		'usampler2D',
		'sampler2DArray',
		'isampler2DArray',
		'usampler2DArray',
		'sampler3D',
		'isampler3D',
		'usampler3D',
		'samplerCube',
		'samplerCubeArray',
		'const',
		'lowp',
		'struct',
		'return',
		'if',
		'else',
		'switch',
		'case',
		'break',
		'while',
		'do',
		'discard',
		'inout',
		'varying',
		'uniform',
		'flat',
		'smooth',
		'shader_type',
		'canvas_item',
		'spatial',
		'particles',
		'sky',
		'fog',
		'UV',
		'COLOR',
		'VERTEX',
		'TIME']}
		
	var regions={'#808080':['//']}
		
	for color in keywords:
		for keyword in keywords[color]:
			self.get_syntax_highlighter().add_keyword_color(keyword, Color(color))

	for color in regions:
		for region in regions[color]:
			self.get_syntax_highlighter().add_color_region(region,'',Color(color),true)
