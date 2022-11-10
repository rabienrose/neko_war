extends Node

var game

var start_seg=[]
var start_ind=-1

var team_id
var ai_info
var cur_op_ind=0

func _ready():
	pass        
	
func ai_get_op():
	var inputs=[]
	var cur_time=game.frame_id*game.frame_delay
	while true:
		if cur_op_ind>=len(ai_info["ops"]):
			return inputs
		var op=ai_info["ops"][cur_op_ind]
		if op[0]<=cur_time:
			var temp_hk_config=game.chara_hotkey[team_id]
			var item=temp_hk_config[op[1]]
			var chara_info=Global.chara_tb[item["name"]]
			cur_op_ind=cur_op_ind+1
			if item["countdown"]<=0 and game.check_chara_build(chara_info["build_cost"], team_id):
				inputs.append(op[1])
		else:
			break
	return inputs

func init(_game, _ai_info):
	ai_info=_ai_info
	team_id=1
	game=_game
	for i in range(len(ai_info["slots"])):
		var temp=ai_info["slots"][i]
		var hk_info=null
		if temp=="":    
			pass
		else:
			var temp_v = temp.split("_")
			var char_name=temp_v[0]
			var char_lv=temp_v[1]
			hk_info={}
			hk_info["countdown"]=0
			hk_info["lv"]=char_lv
			hk_info["name"]=char_name
		game.chara_hotkey[team_id][i]=hk_info



