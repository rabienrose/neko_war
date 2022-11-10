local level_battle = {}
local nk = require("nakama")
local util = require("util")

function level_battle.match_init(_, params)
    local gamestate = {
        frame_id = 0,
        player_info=nil,
        user_id="",
        ready=false,
        cost=0,
        items={},
        level_name=params.level_name
    }
    local tickrate = 1
    local label = "Level"
    return gamestate, tickrate, label
end

function level_battle.match_join_attempt(_, _, _, state, presence, _)
    if state.player_info==nil then
        return state, true
    else
        return state, false
    end
end

function level_battle.match_join(_, dispatcher, _, state, presences)
    for _, presence in ipairs(presences) do
        state.player_info = util.get_user_slots(presence.user_id)
        state.ready=true
        state.user_id=presence.user_id
    end
    return state
end

local function proc_battle_result(state, b_win, battle_record, time)
    local user_info = util.get_user_info(state.user_id)
    local level_data = util.get_level_data(state.level_name)
    if level_data==nil then
        level_data={
            coin_pool=0,
            min_cost=-1,
        }
    end
    if b_win==false then
        user_info.gold=user_info.gold-state.cost
        level_data.coin_pool=level_data.coin_pool+state.cost
        util.update_level_data(state.level_name, level_data)
    else
        if user_info.levels[state.level_name] ==nil then
            local level_info = Levels_tb[state.level_name]
            local reward=level_info.reward
            user_info.gold=user_info.gold+reward
            user_info.levels[state.level_name]={
                time=time,
                cost=state.cost
            }
        end
        if level_data.min_cost==-1 or level_data.min_cost>state.cost then
            level_data.min_cost=state.cost
            level_data["user_id"]=state.user_id
            level_data["record"]=battle_record
            level_data["time"] = time
            util.update_level_data(state.level_name, level_data)
        end
        user_info.last_level=state.level_name
    end
    util.update_user_info(state.user_id, user_info)
end

function level_battle.match_leave(_, _, _, state, presences)
    if state.ready==true then
        proc_battle_result(state, false, "")
    end
    return nil
end

function level_battle.match_loop(_, dispatcher, tick, state, messages)
    for _, message in ipairs(messages) do
        local op_code = message.op_code
        local decoded = nk.json_decode(message.data)
        local msg_user_id=message.sender.user_id
        if op_code==99 then -- end match
            return nil
        elseif op_code==0 then -- new frame
            for k,v in pairs(decoded) do
                if v<5 then --chara
                    local chara_name=state.player_info.hk_slot[v+1][1]
                    local cost = Charas_tb[chara_name].build_cost
                    state.cost=state.cost+cost
                else
                    
                end
            end
        elseif op_code==2 then -- battle done
            proc_battle_result(state, decoded["b_win"], decoded["record"], decoded["time"])
            return nil
        end
    end
    return state
end

function level_battle.match_terminate(_, _, _, state, _)
    return state
end

function level_battle.match_signal(_, _, _, state, data)
	return state, data
end

Charas_tb = util.load_json("../configs/characters.json")
Levels_tb = util.load_json("../configs/levels.json")

return level_battle
