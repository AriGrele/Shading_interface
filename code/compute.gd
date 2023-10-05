extends Node2D

var parse
var inputs={}
var textures={}

var functions = preload("res://code/load_script.gd").new()

func run_compute(compute_script):
	var rd := RenderingServer.create_local_rendering_device()
	
	var shader_src := RDShaderSource.new() 
	shader_src.set_stage_source(RenderingDevice.SHADER_STAGE_COMPUTE,compute_script.replace('#[compute]','')) #setting compute shader specifically, so need to remove compute header
	print(shader_src)
	print(shader_src.get_stage_source(RenderingDevice.SHADER_STAGE_COMPUTE))
	var shader_spirv := rd.shader_compile_spirv_from_source(shader_src)
	var shader       := rd.shader_create_from_spirv(shader_spirv)
	print(shader_spirv)
	print(shader)

	
	# Prepare our data. We use floats in the shader, so we need 32 bit.
	var uniforms={}
	var buffers=[]
	for input in inputs:
		
		if not uniforms.has(inputs[input]['set']):uniforms[inputs[input]['set']]=[]
		
		var item
		match inputs[input]['type']:
			'string':    item = PackedStringArray(inputs[input]['value'])
			'int32':     item = PackedInt32Array(inputs[input]['value'])
			'float32':   item = PackedFloat32Array(inputs[input]['value'])
			'int64':     item = PackedInt64Array(inputs[input]['value'])
			'float64':   item = PackedFloat64Array(inputs[input]['value'])
			'sampler2D':
				if not textures.has(item):
					textures[inputs[input]['value']] = parse.load_image(inputs[input]['value'])
				item = textures[inputs[input]['value']]
			_:
				print('Type not supported')
				item = PackedInt32Array([])
		
		if inputs[input]['type']=='sampler2D':
			print(item)
			var img     = item.get_image()
			var img_pba = img.get_data()
			var width   = item.get_width()
			var height  = item.get_height()

			print(width,' ',height)
			var fmt        = RDTextureFormat.new()
			fmt.width      = width
			fmt.height     = height
			fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
			fmt.format     = RenderingDevice.DATA_FORMAT_R8G8B8A8_SRGB

			var read_data = PackedByteArray(img_pba)

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
			var write_buffer = rd.storage_buffer_create(write_data.size(), write_data)
			buffers.append(write_buffer)
			
			var write_uniform         := RDUniform.new()
			write_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
			write_uniform.binding      = inputs[input]['binding'][1]
			write_uniform.add_id(write_buffer)
			uniforms[inputs[input]['set']].append(write_uniform)

			# Create buffer for sending grid size data to array.
			var size_data_bytes := PackedByteArray(PackedInt32Array([width, height]).to_byte_array())
			var size_buffer = rd.storage_buffer_create(8, size_data_bytes)
			buffers.append(size_buffer)
			
			var size_uniform         := RDUniform.new()
			size_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
			size_uniform.binding      = inputs[input]['binding'][2]
			size_uniform.add_id(size_buffer)
			uniforms[inputs[input]['set']].append(size_uniform)

		else:
			var bytes   = item.to_byte_array()
			var buffer := rd.storage_buffer_create(bytes.size(),bytes)
			buffers.append(buffer)

			# Create a uniform to assign the buffer to the rendering device
			var uniform         := RDUniform.new()
			uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
			uniform.binding      = inputs[input]['binding'] 
			uniform.add_id(buffer)
			uniforms[inputs[input]['set']].append(uniform)
	
	# Create a compute pipeline
	var pipeline     := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	
	var uniform_sets={}
	print('uniforms: ',uniforms)
	for set in uniforms:
		uniform_sets[set] = rd.uniform_set_create(uniforms[set],shader,set) 
		rd.compute_list_bind_uniform_set(compute_list,uniform_sets[set],set)
	
	rd.compute_list_dispatch(compute_list, 5, 1, 1)
	rd.compute_list_end()

	# Submit to GPU and wait for sync
	rd.submit()
	rd.sync()

	# Read back the data from the buffer
	var output_bytes := rd.buffer_get_data(buffers[2])
	var output       := output_bytes.to_float32_array()
	print(output)

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
			if item:
				if item.has('set') and item.has('binding') and item.has('value') and item.has('type'):
					inputs[types]=item
	
	run_compute(compute_script)

func _ready():
	parse=get_node('../parse_script')
	parse.compute.connect(parse_compute)
	
	
