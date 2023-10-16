extends Node2D

var binding
var execute
var display

var parse
var texture
var right
var imagerect

var inputs={}
var textures={}
var types={}

var functions = preload("res://code/load_script.gd").new()

func run_compute(compute_script):
	var rd := RenderingServer.create_local_rendering_device()
	
	var shader_src := RDShaderSource.new() 
	shader_src.set_stage_source(RenderingDevice.SHADER_STAGE_COMPUTE,compute_script.replace('#[compute]','')) #setting compute shader specifically, so need to remove compute header

	var shader_spirv := rd.shader_compile_spirv_from_source(shader_src)
	var shader       := rd.shader_create_from_spirv(shader_spirv)

	# Prepare our data. We use floats in the shader, so we need 32 bit.
	var uniforms={}
	var buffers=[]
	var dataarr=[]
	
	print('inputs: ',inputs)
	for input in inputs:
		types[str(inputs[input]['binding'])]=inputs[input]['type']
		
		if not uniforms.has(inputs[input]['set']):uniforms[inputs[input]['set']]=[]
		
		var item
		match inputs[input]['type']:
			'string':    item = PackedStringArray(inputs[input]['value'])
			'int32':     item = PackedInt32Array(inputs[input]['value'])
			'float32':   item = PackedFloat32Array(inputs[input]['value'])
			'int64':     item = PackedInt64Array(inputs[input]['value'])
			'float64':   item = PackedFloat64Array(inputs[input]['value'])
			'vec2':      
				item=[]
				for value in inputs[input]['value']:
					item.append(Vector2(value[0],value[1]))
				item = PackedVector2Array(item)
			'sampler2D':
				print('sampler2d?')
				if not textures.has(item):
					textures[inputs[input]['value']] = parse.load_image(inputs[input]['value'])
				item = textures[inputs[input]['value']]
			_:
				print('Type not supported')
				item = PackedInt32Array([])

		
		if inputs[input]['type']=='sampler2D':
			
			var img     = item.get_image()
			var img_pba = img.get_data()
			#print(img_pba)
			var width   = item.get_width()
			var height  = item.get_height()

			var fmt        = RDTextureFormat.new()
			fmt.width      = width
			fmt.height     = height
			fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
			fmt.format     = RenderingDevice.DATA_FORMAT_R8G8B8A8_SRGB

			var read_data = PackedByteArray(img_pba)
			#print('r: ',read_data)

			var v_tex      = rd.texture_create(fmt, RDTextureView.new(), [img_pba])
			var samp_state = RDSamplerState.new()
			samp_state.unnormalized_uvw = true
			var samp       = rd.sampler_create(samp_state)

			var tex_uniform          = RDUniform.new()
			tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
			tex_uniform.binding      = inputs[input]['binding'][0]
			tex_uniform.add_id(samp)
			tex_uniform.add_id(v_tex)
			uniforms[inputs[input]['set']].append(tex_uniform)

			# Create storage buffer for the input array.

			# Initialise the byte array the shader will write to.
			var write_data = PackedByteArray()
			write_data.resize(read_data.size())

			# Create storage buffer for the output array.
			var write_buffer = rd.storage_buffer_create(read_data.size(),read_data)
			buffers.append(write_buffer)
			dataarr.append(read_data)
			
			var write_uniform         := RDUniform.new()
			write_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
			write_uniform.binding      = inputs[input]['binding'][1]
			write_uniform.add_id(write_buffer)
			uniforms[inputs[input]['set']].append(write_uniform)

			# Create buffer for sending grid size data to array.
			var size_data_bytes := PackedByteArray(PackedInt32Array([width, height]).to_byte_array())
			var size_buffer = rd.storage_buffer_create(8, size_data_bytes)
			buffers.append(size_buffer)
			dataarr.append(size_data_bytes)
				
			var size_uniform         := RDUniform.new()
			size_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
			size_uniform.binding      = inputs[input]['binding'][2]
			size_uniform.add_id(size_buffer)
			uniforms[inputs[input]['set']].append(size_uniform)

		else:
			var bytes   = item.to_byte_array()
			var buffer := rd.storage_buffer_create(bytes.size(),bytes)
			buffers.append(buffer)
			dataarr.append(bytes)

			# Create a uniform to assign the buffer to the rendering device
			var uniform         := RDUniform.new()
			uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
			uniform.binding      = inputs[input]['binding'] 
			uniform.add_id(buffer)
			uniforms[inputs[input]['set']].append(uniform)
	
	# Create a compute pipeline
	for iteration in range(execute):
		
		for i in range(len(buffers)):
			rd.buffer_update(buffers[i],0,dataarr[i].size(),dataarr[i])
		
		var pipeline     := rd.compute_pipeline_create(shader)
		var compute_list := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
		
		var uniform_sets={}
		
		for set in uniforms:
			uniform_sets[set] = rd.uniform_set_create(uniforms[set],shader,set) 
			rd.compute_list_bind_uniform_set(compute_list,uniform_sets[set],set)
		
		rd.compute_list_dispatch(compute_list, 25, 25, 1)
		rd.compute_list_end()

		# Submit to GPU and wait for sync
		rd.submit()
		rd.sync()

		for i in range(len(buffers)):
			dataarr[i] = rd.buffer_get_data(buffers[i])

		if display>-1 and display<(len(buffers)-1):
			print(rd.buffer_get_data(buffers[display]).size())
			var dim=rd.buffer_get_data(buffers[display+1])
			dim=Vector2(dim[0]+dim[1]*256+dim[2]*256*256+dim[3]*256*256*256,dim[4]+dim[5]*256+dim[6]*256*256+dim[7]*256*256*256)
			
			print('dim: ',dim)
			var image = Image.create_from_data(dim.x,dim.y,false,Image.FORMAT_RGBA8,rd.buffer_get_data(buffers[display]))
			var image_texture = ImageTexture.new()
			image_texture.set_image(image)
			texture.set_texture(image_texture)
			await RenderingServer.frame_post_draw
			
			#print('t: ',rd.buffer_get_data(buffers[display]))
			var imgshader=Shader.new()
			imgshader.set_code('shader_type canvas_item;\nuniform sampler2D img;\nvoid fragment(){COLOR=texture(img,UV);}')
			imagerect.material.set_shader(imgshader)
			imagerect.material.set_shader_parameter('img',image_texture)
			#print('data: ',rd.buffer_get_data(buffers[display]))
			
			#texture.show()
			right.show()
			#imagerect.hide()
		
		else:
			#texture.hide()
			right.hide()
			#imagerect.show()

		# Read back the data from the buffer
		if binding<len(buffers):
			var output_bytes := rd.buffer_get_data(buffers[binding])
			var output       := output_bytes.to_float32_array()
			
			var save_txt      = []
			if types.has(str(binding)) and types[str(binding)] == 'vec2':
				for i in range(len(output)/2):
					save_txt.append(str(output[(i*2)],' ',output[(i*2)+1]))
			else:
				for out in output:save_txt.append(str(out))
			
			print('Saving ')
			functions.save('\n'.join(save_txt),'compute_output.txt')
			
		

func parse_compute(text):
	print('compute')
	var value          = Array(text.split('#[compute]'))
	var options        = value.pop_at(0)
	var compute_script = '#[compute]'+''.join(value)

	for option in options.split('\n'):
		var pair=Array(option.split(':'))

		if len(pair)>1:
			var types=pair.pop_at(0)
			var item=JSON.parse_string(':'.join(pair))
			if item and typeof(item)==TYPE_DICTIONARY:
				if item.has('set') and item.has('binding') and item.has('value') and item.has('type'):
					inputs[types]=item
	
	run_compute(compute_script)

func _ready():
	right     = get_node('../screen/cols/himage')
	imagerect = right.get_node('vimage/imagerect/viewport/shaderrect')
	texture   = get_node('../screen/cols/himage/vimage/texture')
	parse     = get_node('../parse_script')
	
	texture.hide()
	parse.compute.connect(parse_compute)
	
	
	
