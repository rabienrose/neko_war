extends Control

var submit_cb

export (NodePath) var note_edit_path

func _ready():
    pass # Replace with function body.

func set_submit_cb(cb):
    submit_cb=cb

func set_note(text):
    get_node(note_edit_path).text=text

func _on_SubmitBtn_gui_input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            var setting_dat={}
            setting_dat["note"]=get_node(note_edit_path).text
            submit_cb.call_func(setting_dat)
            visible=false

func _on_ClearBtn_gui_input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            get_node(note_edit_path).text=""
