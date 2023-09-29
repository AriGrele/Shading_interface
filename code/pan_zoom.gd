extends Node2D

var selected
var panning
var image
var viewport
var shader

var start
var end

var center
var new
var zoom
var dimfull

func _ready():
	selected = false
	panning  = false
	
	center   = Vector2(0.5,0.5)
	new      = Vector2(0.5,0.5)
	zoom     = 1
	dimfull  = Vector2(1,1)
	
	image    = get_node('../screen/cols/himage/vimage/imagerect')
	viewport = image.get_node('viewport')
	shader   = image.material
	
	shader.set_shader_parameter('center',new)
	shader.set_shader_parameter('zoom',zoom)

func _on_imagerect_mouse_entered():
	selected=true

func _on_imagerect_mouse_exited():
	selected=false

func _process(delta):
	var dim=dimfull*zoom
	var borderx = Vector2(dim.x/2.,1-dim.x/2.)
	var bordery = Vector2(dim.y/2.,1-dim.y/2.)
	
	if selected:
		
		if Input.is_action_just_pressed('Mouse_left'):
			panning=true
			start=image.get_local_mouse_position()
		if Input.is_action_just_released("Mouse_left"):
			panning=false
			
			center=new
		
		if panning:
			end      = image.get_local_mouse_position()
			var disp = (start-end)/image.get_size()*zoom
			new      = center+disp
			
		new = Vector2(clamp(new.x,borderx.x,borderx.y),clamp(new.y,bordery.x,bordery.y))
		shader.set_shader_parameter('center',new)

func _input(event):
	if selected and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP  and event.pressed:
			zoom=clamp(zoom*1.1,0,1)
			shader.set_shader_parameter('zoom',zoom)
		
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN  and event.pressed:
			zoom=clamp(zoom*.9,0,1)
			shader.set_shader_parameter('zoom',zoom)
