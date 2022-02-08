extends Node

signal money_change(val)
signal request_spawn_chara(chara_info)
signal expend_gold(val)

var chara_tb={}
var chara_anim={}
var char_tb_file_path="res://configs/characters.json"
var char_img_file_path="res://binary/images/charas/"

func _ready():
    var f=File.new()
    f.open(char_tb_file_path, File.READ)
    var content = f.get_as_text()
    chara_tb = JSON.parse(content).result
    f.close()

func get_char_attr(char_name, lv):
    return chara_tb[char_name]["attrs"][str(lv)]

func get_char_anim_info(char_name):
    return chara_tb[char_name]["appearance"]

func get_char_anim(char_name):
    var anim_file = chara_tb[char_name]["appearance"]
    if not anim_file in chara_anim:
        chara_anim[anim_file]=load("res://anim_sprite/"+char_name+".tres")
    return chara_anim[anim_file]
