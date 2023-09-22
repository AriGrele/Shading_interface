extends ColorRect

func _process(_delta):
	var dim=DisplayServer.window_get_size()
	var x=dim.x/2
	var y=dim.y
	self.set_custom_minimum_size(Vector2(min(x,y),min(x,y)))
