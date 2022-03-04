
from flask import Flask, request, Response
from bson.objectid import ObjectId
import json
import hashlib
from datetime import datetime
import time
from user import UserInfo
from level_mgr import LevelMgr


app = Flask(__name__)

@app.route('/test_port',methods=['GET','POST'])
def test_port():
    print(request.remote_addr,request.environ.get('REMOTE_PORT'))
    return json.dumps(["ok"])

@app.route('/user_login',methods=['POST'])
def user_login():
    account=request.json["account"]
    pw=request.json["pw"]
    device_id=request.json["device_id"]
    device_type=request.json["device_type"]
    user = UserInfo("")
    ret_t = user.check_password(account, pw)
    print(ret_t)
    ret={"op":"user_login"}
    if ret_t["ret"]=="ok":
        ret["ret"]="ok"
        ret["data"]={"token":user.token}
        print("asdfasdfsfd")
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
    print(request.json)
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
    return json.dumps(ret)

@app.route('/update_level_stats',methods=['POST'])
def update_level_stats():
    token=request.json["token"]
    recording_data=request.json["recording"]
    battle_time=request.json["time"]
    level_id=request.json["level_id"]
    chara_lv=request.json["chara_lv"]
    difficulty=request.json["difficulty"]
    lv_mgr=LevelMgr()
    lv_mgr.update_level_stats(token, recording_data, battle_time, level_id, chara_lv, difficulty)

@app.route('/request_levels_info',methods=['POST'])
def request_levels_info():
    ret={"op":"request_levels_info"}
    lv_mgr = LevelMgr()
    ret["data"]=lv_mgr.get_daliy_level()
    return json.dumps(ret)

if __name__ == '__main__':
    app.config['SECRET_KEY'] = 'xxx'
    app.config['UPLOAD_FOLDER'] = './raw'
    app.debug = True
    app.run('0.0.0.0', port=9100)
