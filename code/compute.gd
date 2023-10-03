extends Node2D

var parse
var inputs={}

var functions = preload("res://code/load_script.gd").new()

func run_compute():
	var rd := RenderingServer.create_local_rendering_device()
	
	var shader_file := load("compute_script.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	var shader      := rd.shader_create_from_spirv(shader_spirv)
	
	# Prepare our data. We use floats in the shader, so we need 32 bit.
	var uniforms={}
	var buffers=[]
	for input in inputs:
		if not uniforms.has(inputs[input]['set']):uniforms[inputs[input]['set']]=[]
		
		var item   := PackedFloat32Array(inputs[input]['value'])
		var bytes  := item.to_byte_array()
		var buffer := rd.storage_buffer_create(bytes.size(),bytes)
		buffers.append(buffer)

		# Create a uniform to assign the buffer to the rendering device
		var uniform         := RDUniform.new()
		uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		uniform.binding      = inputs[input]['binding'] # this needs to match the "binding" in our shader file
		uniform.add_id(buffer)
		uniforms[inputs[input]['set']].append(uniform)
	
	# Create a compute pipeline
	var pipeline     := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	
	var uniform_sets={}
	for set in uniforms:
		uniform_sets[set] = rd.uniform_set_create(uniforms[set],shader,set) # the last parameter (the 0) needs to match the "set" in our shader file
		rd.compute_list_bind_uniform_set(compute_list,uniform_sets[set],set)
	
	
	rd.compute_list_dispatch(compute_list, 5, 1, 1)
	rd.compute_list_end()

	# Submit to GPU and wait for sync
	rd.submit()
	rd.sync()

	# Read back the data from the buffer
	for buffer in buffers:
		var output_bytes := rd.buffer_get_data(buffer)
		var output       := output_bytes.to_float32_array()
		print(output)

func parse_compute(text):
	var value          = Array(text.split('#[compute]'))
	var options        = value.pop_at(0)
	var compute_script = '#[compute]'+''.join(value)

	for option in options.split('\n'):
		var pair=Array(option.split(':'))

		if len(pair)>1:
			var types=pair.pop_at(0)
			var item=JSON.parse_string(':'.join(pair))
			
			if item:
				if item.has('set') and item.has('binding') and item.has('value'):
					inputs[types]=item
	
	functions.save(compute_script,'compute_script.glsl')
	
	run_compute()

func _ready():
	parse=get_node('../parse_script')
	parse.compute.connect(parse_compute)
	
	
