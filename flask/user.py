from bson.objectid import ObjectId
import config

class UserInfo:
    token:str
    def __init__(self, token:str) -> None:
        self.token=token
    
    def create_user(self, device_id):
        if self.token=="":
            query_re = config.user_table.find_one({"devices":device_id})
            if query_re is None:
                user_info={}
                user_info["devices"]=[device_id]
                new_token = config.user_table.insert_one(user_info).inserted_id
                print(new_token)
            else:
                print("device exist!")

    def attach_name_pw(self, account:str, nickname:str, password:str):
        query_re = config.user_table.find_one({"_id":ObjectId(self.token)})
        if query_re is None:
            return
        update_info={}
        update_info["account"]=account
        update_info["nickname"]=nickname
        update_info["password"]=password
        config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":update_info})

    def reset_user(self):
        user_info={}
        user_info["gold"]=0
        user_info["characters"]=[{"name": "sword","lv": 1}]
        user_info["equip"]={"chara": ["sword","","","", ""],"item": ["","","","",""]}
        user_info["levels"]={}
        user_info["items"]=[]
        config.user_table.update_one({"_id":ObjectId(self.token)},{"$set":user_info})

    def get_info(self):
        query_re = config.user_table.find_one({"_id":ObjectId(self.token)},{"_id":0,"account":0, "password":0})
        query_re["token"]=self.token
        return query_re

    def draw_item_chara():
        pass