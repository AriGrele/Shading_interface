extends Node2D

var parse_script
var viewport
var shaderrect
var imagerect
var compute

var input

var functions = preload("res://code/load_script.gd").new()

func ifelse(check,a,b):
	if check:return(a)
	return(b)

func parse(parms):
	var default={
		'mode':'save',
		'x':'1000',
		'y':'1000',
		'crop_left':'0',
		'crop_right':'1',
		'crop_bottom':'0',
		'crop_top':'1',
		'load':'.',
		'save':'.',
		'save_image':'image.png',
		'binding':'1',
		'execute':'1',
		'display':'-1'}
	
	for parm in default:
		if parm in parms:pass
		else:parms[parm]=default[parm]
		
	var x           = float(parms['x'])
	var y           = float(parms['y'])
	var crop_left   = float(parms['crop_left'])
	var crop_right  = float(parms['crop_right'])-float(parms['crop_left'])
	var crop_top    = float(parms['crop_top'])
	var crop_bottom = float(parms['crop_bottom'])
	
	compute.execute = int(parms['execute'])
	compute.binding = int(parms['binding'])
	compute.display = int(parms['display'])
	
	print(parms)
	
	viewport.set_size(Vector2(x,y))
	shaderrect.set_size(Vector2(x,y))
	
	shaderrect.set_size(Vector2(x/crop_right,y/(crop_top-crop_bottom)))
	shaderrect.set_position(Vector2(-crop_left,-(1.-crop_top))*shaderrect.get_size())
	
	if '.txt' in parms['load']:
		var new_text=functions.load_txt(parms['load'])
		if new_text!='':
			input.set_text(new_text)
			parse_script._on_script_text_changed()
	
	if '.txt' in parms['save']:
		functions.save(input.get_text(),parms['save'])
		
	if parms['mode']=='save':
		
		viewport.set_update_mode(1) #render once
		
		if '.png' in parms['save_image'] or '.jpg' in parms['save_image']:
			await RenderingServer.frame_post_draw
			
			var texture=viewport.get_texture().get_image()
			
			if '.jpg' in parms['save_image']:
				texture.save_jpg(parms['save_image'])
				
			if '.png' in parms['save_image']:
				texture.save_png(parms['save_image'])
			
		parse_script.mode='save'
	else:
		parse_script.mode=parms['mode']
	
func _ready():
	compute=get_node('../compute')
	input        = get_node('../screen/cols/text/script')
	parse_script = get_node('../parse_script')
	imagerect    = get_node('../screen/cols/himage/vimage/imagerect')
	viewport     = imagerect.get_node('viewport')
	shaderrect   = viewport.get_node('shaderrect')
	
	parse_script.parameters.connect(parse)


