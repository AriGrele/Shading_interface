extends ColorRect

func _process(_delta):
	var dim=self.get_parent().get_size()
	self.set_custom_minimum_size(Vector2(min(dim.x,dim.y),min(dim.x,dim.y)))

	print(dim)
