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
        user_info["diamond"]=2000        
        user_info["characters"]=[{"name": "sword","lv": 0}]
        user_info["equip"]={"chara": ["sword","","","", ""],"item": ["","","","",""]}
        user_info["levels"]={}
        user_info["items"]=[]
        config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":user_info})

    def get_nickname(self):
        query_re = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"nickname":1})
        return query_re["nickname"]

    def get_info(self):
        query_re = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"account":0, "password":0, "devices":0})
        # query_re["token"]=self.token
        return query_re

    def get_level_pass_num(self, level_name):
        query_re = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"levels":1})
        if level_name=="":
            return len(query_re["levels"])
        else:
            temp_num=0
            for key in query_re["levels"]:
                if level_name in key:
                    temp_num=temp_num+1
            return temp_num

    def update_equip(self, b_chara, index, name):
        equip_type="chara"
        if b_chara==False:
            equip_type="item"
        config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":{"equip."+equip_type+"."+str(index):name}})

    def change_gold(self, gold):
        query_re = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"gold":1})
        new_gold=query_re["gold"]+gold
        config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":{"gold":new_gold}})

    def change_diamond(self, val):
        query_re = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"diamond":1})
        new_val=query_re["diamond"]+val
        if new_val<=0:
            return False
        config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":{"diamond":new_val}})
        return True

    def set_last_pvp(self):
        config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":{"last_pvp":int(time.time())}})
        
    def get_setting(self):
        query_re = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"setting":1})
        if "setting" in query_re:
            return query_re["setting"]
        else:
            return {"note":""}

    def modify_setting(self, note_str):
        modify_data={}
        modify_data["note"]=note_str
        config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":{"setting":modify_data}})

    def draw_item_chara():
        pass