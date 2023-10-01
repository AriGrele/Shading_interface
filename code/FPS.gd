extends Label

func _process(delta):
	self.set_text(str('FPS: ',Engine.get_frames_per_second()))
