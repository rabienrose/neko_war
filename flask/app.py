
from flask import Flask, request, Response
from bson.objectid import ObjectId
import json
import hashlib
from datetime import datetime
import time
from user import UserInfo
from level_mgr import LevelMgr
from rank import Rank

app = Flask(__name__)

@app.route('/test_port',methods=['GET','POST'])
def test_port():
    return json.dumps(["ok"])

@app.route('/user_login',methods=['POST'])
def user_login():
    account=request.json["account"]
    pw=request.json["pw"]
    device_id=request.json["device_id"]
    device_type=request.json["device_type"]
    user = UserInfo("")
    ret_t = user.check_password(account, pw)
    ret={"op":"user_login"}
    if ret_t["ret"]=="ok":
        ret["ret"]="ok"
        ret["data"]={"token":user.token}
        user.update_device(device_id, device_type, request.remote_addr)
    else:
        ret["ret"]=ret_t["ret"]
        ret["desc"]=ret_t["desc"]
    return json.dumps(ret)

@app.route('/user_regist',methods=['POST'])
def user_regist():
    account=request.json["account"]
    pw=request.json["pw"]
    device_id=request.json["device_id"]
    device_type=request.json["device_type"]
    ret={"op":"user_regist"}
    user = UserInfo("")
    ret_t=user.attach_name_pw(account,account,pw)
    if ret_t["ret"]=="ok":
        ret["ret"]="ok"
        ret["data"]={"token":user.token}
        user.update_device(device_id, device_type, request.remote_addr)
        user.reset_user()
    else:
        ret["ret"]=ret_t["ret"]
        ret["desc"]=ret_t["desc"]
    return json.dumps(ret)

@app.route('/request_user_info',methods=['POST'])
def request_user_info():
    token=request.json["token"]
    ret={"op":"request_user_info"}
    user = UserInfo(token)
    ret["ret"]="ok"
    ret["data"]=user.get_info()
    print(ret["data"])
    return json.dumps(ret)

@app.route('/notify_use_items',methods=['POST'])
def notify_use_items():
    ret={"op":"update_level_stats"}
    ret["ret"]="ok"
    items=request.json["items"]
    token=request.json["token"]
    user = UserInfo(token)
    user.dec_item_count(items)
    return json.dumps(ret)

@app.route('/update_level_stats',methods=['POST'])
def update_level_stats():
    ret={"op":"update_level_stats"}
    ret["ret"]="ok"
    token=request.json["token"]
    recording_data=request.json["recording"]
    battle_time=request.json["time"]
    level_id=request.json["level_id"]
    chara_lv=request.json["chara_lv"]
    difficulty=request.json["difficulty"]
    lv_mgr=LevelMgr()
    lv_mgr.update_level_stats(token, recording_data, battle_time, level_id, chara_lv, difficulty)
    gold=lv_mgr.get_level_gold(chara_lv, difficulty, level_id)
    user = UserInfo(token)
    user.change_gold(gold)
    return json.dumps(ret)

@app.route('/request_levels_info',methods=['POST'])
def request_levels_info():
    ret={"op":"request_levels_info"}
    lv_mgr = LevelMgr()
    ret["data"]=lv_mgr.get_daliy_level()
    return json.dumps(ret)

@app.route('/update_equip_info',methods=['POST'])
def update_equip_info():
    ret={"op":"update_equip_info"}
    token=request.json["token"]
    b_chara=request.json["b_chara"]
    hk_index=request.json["hk_index"]
    name=request.json["name"]
    user = UserInfo(token)
    user.update_equip(b_chara, hk_index, name)
    return json.dumps(ret)    

@app.route('/request_rank_info',methods=['POST'])
def request_rank_info():
    ret={"op":"request_rank_info"}
    rank=Rank()
    ret["data"]=rank.get_ranks()
    return json.dumps(ret)  

@app.route('/pvp_summary',methods=['POST'])
def pvp_summary():
    ret={"op":"request_rank_info"}
    ret["ret"]="ok"
    token1=request.json["token1"]
    token2=request.json["token2"]
    diamond1=request.json["diamond1"]
    diamond2=request.json["diamond2"]
    record=request.json["recording"]
    rank=Rank()
    if not rank.pvp_summary(token1, token2, diamond1, diamond2):
        ret["ret"]="fail"
    return json.dumps(ret)  

@app.route('/get_user_setting',methods=['POST'])
def get_user_setting():
    ret={"op":"get_user_setting"}
    ret["ret"]="ok"
    token=request.json["token"]
    user=UserInfo(token)
    ret["data"]=user.get_setting()
    return json.dumps(ret)  

@app.route('/modify_user_setting',methods=['POST'])
def modify_user_setting():
    ret={"op":"modify_user_setting"}
    ret["ret"]="ok"
    token=request.json["token"]
    note=request.json["note"]
    user=UserInfo(token)
    user.modify_setting(note)
    return json.dumps(ret)  

@app.route('/notify_start_pvp',methods=['POST'])
def notify_start_pvp():
    ret={"op":"modify_user_setting"}
    ret["ret"]="ok"
    rank=Rank()
    token=request.json["token"]
    rank.notify_start_pvp(token)
    return json.dumps(ret)  

@app.route('/upgrade_chara',methods=['POST'])
def upgrade_chara():
    ret={"op":"upgrade_chara"}
    ret["ret"]="ok"
    token=request.json["token"]
    chara_name=request.json["chara_name"]
    user=UserInfo(token)
    re_data = user.upgrade_chara(chara_name)
    if re_data is None:
        ret["ret"]="fail"
    ret["data"]=re_data
    return json.dumps(ret)  

@app.route('/draw_a_lottery',methods=['POST'])
def draw_a_lottery():
    ret={"op":"draw_a_lottery"}
    ret["ret"]="ok"
    token=request.json["token"]
    user=UserInfo(token)
    ret["data"]=user.draw_lottory()
    return json.dumps(ret)  

@app.route('/buy_item',methods=['POST'])
def buy_item():
    ret={"op":"buy_item"}
    ret["ret"]="ok"
    token=request.json["token"]
    item_name=request.json["item_name"]
    user=UserInfo(token)
    re_info = user.buy_item(item_name)
    if re_info is not None:
        ret["data"]=re_info
    else:
        ret["ret"]="fail"
    return json.dumps(ret)  

@app.route('/set_tip_flag',methods=['POST'])
def set_tip_flag():
    ret={"op":"set_tip_flag"}
    ret["ret"]="ok"
    token=request.json["token"]
    tip_name=request.json["tip_name"]
    user=UserInfo(token)
    user.set_tip_flag(tip_name)
    return json.dumps(ret)  

if __name__ == '__main__':
    app.config['SECRET_KEY'] = 'xxx'
    app.config['UPLOAD_FOLDER'] = './raw'
    app.debug = True
    app.run('0.0.0.0', port=9100)
