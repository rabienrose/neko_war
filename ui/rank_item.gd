extends HBoxContainer

export (NodePath) var nickname_path
export (NodePath) var diamond_path
export (NodePath) var past_time_path
export (NodePath) var note_path

func _ready():
	pass # Replace with function body.

func set_data(nickname, diamond, past_time_st, note):
	get_node(nickname_path).text=nickname
	get_node(diamond_path).text=str(diamond)
	var time = OS.get_datetime_from_unix_time(past_time_st);
	var display_string =  "%d/%02d/%02d" % [time.year, time.month, time.day];
	get_node(past_time_path).text=display_string
	get_node(note_path).text=note
