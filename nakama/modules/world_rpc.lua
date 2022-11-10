local nk = require("nakama")
local util = require("util")


local function new_account_cb(context, payload)
    local user_id = context.user_id
    local object_ids = {
        { collection = "user", key = "basic", user_id = user_id },
    }
    local objects = nk.storage_read(object_ids)
    if #objects==0 then
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
    local json = nk.json_decode(payload)
    return payload
end

local function request_match(context, payload)
    local limit = 1
    local isAuthoritative = true
    local min_size = 0
    local max_size = 1
    local matches = nk.match_list(limit, isAuthoritative,"PVP",min_size, max_size)
    local current_match = matches[1]
    if current_match == nil then
        return nk.match_create("pvp_battle", {})
    else
        return current_match.match_id
    end
end

local function request_level_battle(context, payload)
    return nk.match_create("level_battle", {level_name=payload})
end

local function request_a_upgrade(context, payload)
    local json = nk.json_decode(payload)
    return payload
end

local function request_a_draw(context, payload)
    local user_id=context.user_id
    local user_info = util.get_user_info(user_id)
    local lottery_cost=Global_tb["lottery_price"]
    if lottery_cost>user_info["gold"] then
        local ret_load={}
        ret_load["error"]="coin_not_enough"
        return nk.json_encode(ret_load)
    end
    user_info["gold"]=user_info["gold"]-lottery_cost
    local candis={}
    for k,v in pairs(Items_tb) do
        local change=v["chance"]
        if change==0 then
        elseif change==10000 then
            table.insert(candis,k)
        else
            local rand = math.random(0, 10000)
            if rand<=change then
                table.insert(candis,k)
            end
        end
    end
    local condi_num=#candis
    local rand = math.random(1, condi_num)
    local draw_item_name=candis[rand]
    if user_info["items"][draw_item_name]==nil then
        user_info["items"][draw_item_name]=1
    else
        user_info["items"][draw_item_name]=user_info["items"][draw_item_name]+1
    end
    util.update_user_info(user_id, user_info)
    local ret_load={}
    ret_load["item"]=draw_item_name
    return nk.json_encode(ret_load)
end

local function update_equip_slot(context, payload)
    local json = nk.json_decode(payload)
    return payload
end

-- Charas_tb = util.load_json("../configs/characters.json")
Items_tb = util.load_json("../configs/items.json")
Global_tb = util.load_json("../configs/global.json")


nk.register_rpc(request_level_battle, "request_level_battle")
nk.register_rpc(request_match, "request_match")
nk.register_rpc(update_equip_slot, "update_equip_slot")
nk.register_rpc(request_a_upgrade, "request_a_upgrade")
nk.register_rpc(request_a_draw, "request_a_draw")
nk.register_rpc(level_battle_summary, "level_battle_summary")
nk.register_req_after(new_account_cb, "AuthenticateEmail")