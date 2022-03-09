extends Node

var game
var peer
var lobby
var players_info={}
var enemy_net_id=-1
var input_queue=[]
var cur_frame=0
var enemy_token=""

func _ready():
    game=get_parent()
    lobby=game.get_node(game.lobby_path)

func start_server():
    print("start_server")
    peer= NetworkedMultiplayerENet.new()
    peer.create_server(9001, 5)
    get_tree().network_peer = peer
    get_tree().connect("network_peer_connected", self, "_player_connected")
    get_tree().connect("network_peer_disconnected", self, "_player_disconnected")    

func start_clinet():
    peer = NetworkedMultiplayerENet.new()
    # peer.create_client("47.100.93.238", 9001)
    peer.create_client("127.0.0.1", 9001)
    get_tree().network_peer = peer
    lobby.visible=true
    get_tree().connect("connected_to_server", self, "_connected_to_server")
    get_tree().connect("connection_failed", self, "_connection_failed")
    get_tree().connect("server_disconnected", self, "_server_disconnected")

remote func start_battle_net(player_info):
    var other_team_id = player_info["team"]
    enemy_net_id=player_info["net_id"]
    enemy_token=player_info["token"]
    var my_team_id=-1
    if other_team_id==0:
        my_team_id=1
    else:
        my_team_id=0
    game.player_setting[other_team_id]="remote"
    game.player_setting[my_team_id]="local"
    for i in range(len(player_info["equip"])):
        game.chara_hotkey[other_team_id][i]=player_info["equip"][i].duplicate()
        game.chara_hotkey[other_team_id][i]["countdown"]=0
    game.get_node(game.lobby_path).visible=false
    game.base_hp=1000
    game.start_battle()
    var local_team_id = game.find_local_team_id()
    if local_team_id!=-1:
        # Global.user_data["diamond"]=Global.user_data["diamond"]-Global.global_data["pvp_price"]
        game.get_node(game.diamond_pool_label_path).get_parent().visible=true
        if local_team_id==0:
            game.get_node(game.diamond1_label_path).get_parent().visible=true
            game.diamond_num[0]=Global.user_data["diamond"]
            game.get_node(game.meat1_label_path).get_parent().visible=true
            game.get_node(game.diamond2_label_path).get_parent().visible=false
            game.diamond_num[1]=player_info["diamond"]
            game.get_node(game.meat2_label_path).get_parent().visible=false
            game.update_hotkey_ui(0)
        else:
            game.get_node(game.diamond1_label_path).get_parent().visible=false
            game.diamond_num[0]=player_info["diamond"]
            game.get_node(game.meat1_label_path).get_parent().visible=false
            game.get_node(game.diamond2_label_path).get_parent().visible=true
            game.diamond_num[1]=Global.user_data["diamond"]
            game.get_node(game.meat2_label_path).get_parent().visible=true
            game.update_hotkey_ui(1)
        game.meat_num[0]=Global.global_data["pvp_price"]
        game.meat_num[1]=Global.global_data["pvp_price"]
        game.update_stats_ui()
        game.init_diamond_num=game.diamond_num.duplicate()

remote func process_join(_info):
    var id = get_tree().get_rpc_sender_id()
    if id in players_info:
        return
    var find_player=false
    for player_net_id in players_info:
        if players_info[player_net_id]["status"]=="waiting":
            var start_battle_info={}
            start_battle_info["team"]=0
            start_battle_info["net_id"]=player_net_id
            start_battle_info["token"]=players_info[player_net_id]["info"]["token"]
            start_battle_info["equip"]=players_info[player_net_id]["info"]["equip"]
            start_battle_info["diamond"]=players_info[player_net_id]["info"]["diamond"]
            rpc_id(id, "start_battle_net", start_battle_info)
            start_battle_info={}
            start_battle_info["team"]=1
            start_battle_info["net_id"]=id
            start_battle_info["token"]=_info["token"]
            start_battle_info["equip"]=_info["equip"]
            start_battle_info["diamond"]=_info["diamond"]
            rpc_id(player_net_id, "start_battle_net", start_battle_info)
            players_info[player_net_id]["status"]="battle"
            players_info[id]={"status":"battle","info":_info}
            find_player=true
            break
    
    if find_player==false:
        rpc_id(id, "joint_succ")
        players_info[id]={"status":"waiting","info":_info}

func _player_connected(id):
    print("_player_connected: ",id)

func _player_disconnected(id):
    if id in players_info:
        players_info.erase(id)
    print("_player_disconnected: ",id)

func _connected_to_server():
    print("request_join")
    request_join()

func _connection_failed():
    pass

func _server_disconnected():
    pass

remote func joint_succ():
    game.get_node(game.lobby_msg_path).text="Join success, please wait."

remote func on_get_keyframe(input_dat, _frame_id):
    if len(input_queue)==_frame_id-1:
        input_queue.append(input_dat)
    else:
        print("sycn wrong!!")

func report_input(_team_id):
    if enemy_net_id<0:
        return
    if len(game.chara_inputs[_team_id])>0:
        rpc_id(enemy_net_id,"on_get_input", game.chara_inputs[_team_id], _team_id)
        game.chara_inputs[_team_id]=[]

remote func on_get_input(input_dat, _team_id):
    game.chara_inputs[_team_id]=input_dat

func check_new_keyframe():
    return !(cur_frame==len(input_queue))

func process_keyframe():
    if Global.pvp_mode:
        var _local_team=game.find_local_team_id()
        if _local_team==0:
            broadcast_keyframe()
        else:
            report_input(_local_team)
    if Global.level_mode:
        var temp_input_data=[[],[]]
        for i in range(0,2):
            if game.player_setting[i]=="ai":
                var op= game.ai_nodes[i].ai_get_op()
                if op!=null:
                    if op["type"]=="chara":
                        temp_input_data[i]=[op["ind"]]
            elif game.player_setting[i]=="local":
                temp_input_data[i]=game.chara_inputs[i]
                game.chara_inputs[i]=[]
        input_queue.append(temp_input_data)
    if check_new_keyframe():
        var inputs = input_queue[cur_frame]
        for _team_id in range(0,2):
            if len(inputs[_team_id])>0:
                for key in inputs[_team_id]:
                    var chara_name=game.chara_hotkey[_team_id][key]["name"]
                    var chara_info=Global.chara_tb[chara_name]
                    if game.chara_hotkey[_team_id][key]["countdown"]<0 and game.check_chara_build(chara_info["build_cost"],_team_id):
                        game.chara_hotkey[_team_id][key]["countdown"]=chara_info["build_time"]
                        game.spawn_chara(chara_name, game.chara_hotkey[_team_id][key]["lv"]+1, _team_id)
                        game.change_meat(-chara_info["build_cost"], _team_id)
        cur_frame=cur_frame+1
        return true
    else:
        return false

func broadcast_keyframe():
    if enemy_net_id>0:
        rpc_id(enemy_net_id,"on_get_keyframe", game.chara_inputs, len(input_queue)+1)
    on_get_keyframe(game.chara_inputs.duplicate(), len(input_queue)+1)
    for i in range(0,2):
        game.chara_inputs[i]=[]

func get_recording_data():
    var recording_data={}
    recording_data["ops"]=input_queue
    recording_data["hotkeys"]=game.chara_hotkey
    recording_data["reward_discount"]=game.reward_discount
    recording_data["init_meat_num"]=game.init_meat_num
    recording_data["init_diamond_num"]=[game.init_diamond_num[0]-game.diamond_num[0], game.init_diamond_num[1]-game.diamond_num[1]]
    recording_data["final_meat_num"]=game.meat_num
    recording_data["base_hp"]=game.base_hp
    var chara_num_stats=[{},{}]
    for c in game.char_root.get_children():
        if is_instance_valid(c)==false:
            continue
        if c.dead==true:
            continue
        if not c.chara_name in chara_num_stats[c.team_id]:
            chara_num_stats[c.team_id][c.chara_name]=0
        chara_num_stats[c.team_id][c.chara_name]=chara_num_stats[c.team_id][c.chara_name]+1
    recording_data["remain_charas"]=chara_num_stats
    return JSON.print(recording_data) 

func start_replay(replay_data):
    input_queue=replay_data["ops"]
    game.meat_num=replay_data["init_meat_num"]
    game.diamond_num=replay_data["init_diamond_num"]
    game.chara_hotkey=replay_data["hotkeys"]
    game.reward_discount=replay_data["reward_discount"]
    game.base_hp=replay_data["base_hp"]
    for i in range(0,2):
        for item in game.chara_hotkey[i]:
            if item!=null:
                item["countdown"]=0
    game.start_battle()

func exit_battle():
    get_tree().network_peer = null

func request_join():
    var join_info={}
    join_info["equip"]=[]
    for i in range(len(Global.user_data["equip"]["chara"])):
        var chara_name=Global.user_data["equip"]["chara"][i]
        if chara_name=="":
            join_info["equip"].append(null)
        else:
            var my_chara_info = Global.get_my_chara_info(chara_name)
            var lv=my_chara_info["lv"]
            var hk_info={}
            hk_info["lv"]=lv
            hk_info["name"]=chara_name
            join_info["equip"].append(hk_info)
    join_info["diamond"]=Global.user_data["diamond"]
    join_info["token"]=Global.token
    rpc_id(1,"process_join",join_info)
