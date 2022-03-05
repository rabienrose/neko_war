from bson.objectid import ObjectId
import config
import time

class UserInfo:
    token=""
    def __init__(self, token:str) -> None:
        self.token=token

    def check_password(self, account:str, password:str):
        ret={}
        ret["ret"]="ok"
        query_re = config.user_table.find_one({"account":account},{"password":1})
        if query_re is None:
            ret["ret"]="fail"
            ret["desc"]="account not exist"
        else:
            if query_re["password"]!=password:
                ret["ret"]="fail"
                ret["desc"]="password not right"
            else:
                self.token = str(query_re["_id"])
        return ret

    def attach_name_pw(self, account:str, nickname:str, password:str):
        ret={}
        ret["ret"]="ok"
        query_re = config.user_table.find_one({"account":account})
        if query_re is not None:
            ret["ret"]="fail"
            ret["desc"]="account exist"
        else:
            user_info={}
            user_info["account"]=account
            user_info["nickname"]=nickname
            user_info["password"]=password
            user_info["devices"]=[]
            self.token = str(config.user_table.insert_one(user_info).inserted_id)
        return ret

    def update_device(self, device_id, device_type, ip):
        if self.token=="":
            return
        query_re = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"devices":1})
        print(query_re)
        has_device=False
        for d in query_re["devices"]:
            if d["id"]==device_id:
                has_device=True
                d["num"]=d["num"]+1
                if ip not in d["ips"]:
                    d["ips"].append(ip)
                d["last_time"]=int(time.time())
                break
        if has_device==False:
            device_info={}
            device_info["id"]=device_id
            device_info["type"]=device_type
            device_info["num"]=1
            device_info["ips"]=[ip]
            device_info["last_time"]=int(time.time())
            query_re["devices"].append(device_info)
        config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":{"devices":query_re["devices"]}})

    def reset_user(self):
        user_info={}
        user_info["gold"]=0
        user_info["characters"]=[{"name": "sword","lv": 1}]
        user_info["equip"]={"chara": ["sword","","","", ""],"item": ["","","","",""]}
        user_info["levels"]={}
        user_info["items"]=[]
        config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":user_info})

    def get_info(self):
        query_re = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"account":0, "password":0, "devices":0})
        # query_re["token"]=self.token
        return query_re

    def update_equip(self, b_chara, index, name):
        equip_type="chara"
        if b_chara==False:
            equip_type="item"
        config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":{"equip."+equip_type+"."+str(index):name}})

    def draw_item_chara():
        pass