extends Node2D

func load_txt(path):
	var file=FileAccess.open(path,FileAccess.READ)
	var content=file.get_as_text()
	return(content)

func _ready():
	var path='res://input.txt'
	var script=load_txt(path)
	
	get_node('../screen/cols/text/script').set_text(script)
	get_node('../parse_script')._on_script_text_changed()
