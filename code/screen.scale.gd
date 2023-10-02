extends Control

func _process(_delta):
	var dim=DisplayServer.window_get_size()
	self.set_size(dim)
