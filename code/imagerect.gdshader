shader_type canvas_item;

uniform sampler2D viewport:filter_nearest;
uniform vec2 center;
uniform float zoom;

void fragment(){
	
	vec2 uv=UV-vec2(.5);
	uv=(uv*zoom+center);
	
	COLOR=texture(viewport,uv);}
