local nk = require("nakama")

local function print_table(data)
    for k,v in pairs(data) do
        print(k,v)
    end
end

local function count_table(data)
    local n=0
    for _,_ in pairs(data) do
        n=n+1
    end
    return n
end


local function new_count_cb(context, payload)
    local user_id = context.user_id
    local object_ids = {
        { collection = "user", key = "basic", user_id = user_id },
    }
    local objects = nk.storage_read(object_ids)
    if count_table(objects)==0 then
        local new_user_data={}
        new_user_data["gold"]=100
        new_user_data["characters"]={["sword"]=1}
        new_user_data["items"]={}
        new_user_data["equip"]={{"sword","","","",""},{"","","","",""}}
        new_user_data["levels"]={}
        new_user_data["last_level"]=""
        new_user_data["last_pvp"]=0
        local new_objects = {
            {
                collection = "user",
                key = "basic",
                value = new_user_data,
                permission_read = 1,
                permission_write = 0,
                user_id=user_id
            }
        }
        nk.storage_write(new_objects)
        print("new user!")
    else
    end
end

local function level_battle_summary(context, payload)
    print(payload)
    local json = nk.json_decode(payload)
    print_table(json)
    return payload
end

nk.register_rpc(level_battle_summary, "level_battle_summary")
nk.register_req_after(new_count_cb, "AuthenticateEmail")