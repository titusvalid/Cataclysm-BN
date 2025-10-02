--[[いろいろ]]--
DEBUG = {
	--trueにセットするとデバッグメッセージを表示する
	enabled = false
}

--[[デバッグ用ファンクション]]--
DEBUG.hello_world = function()
	gapi.add_msg("Hello World!")
end

_G.log_info = function(message)
    if (DEBUG and DEBUG.enabled) then
        gdebug.log_info(message)
    end
end

DEBUG.chk_calendar = function()

	local cldr = game.current_turn()

	gdebug.log_info("year_length:"..cldr:year_length():get_turns())		--ターン数基準
	gdebug.log_info("season_length:"..cldr:season_length():get_turns())	--ターン数基準
	gdebug.log_info("season_ratio:"..cldr:season_ratio())					--現実世界の1季節の日数(91日)に対するゲーム内の季節の長さの比率。たとえばゲーム内1季節を14日に設定した場合、14 / 91 = 約0.1538になる。
	gdebug.log_info("season_from_default_ratio:"..cldr:season_from_default_ratio())	--ゲーム内のデフォルトの1季節の日数(14日)に対する現在の1季節日数の比率。たとえばゲーム内1季節を28日に設定した場合 28 / 14 = 2になる。
	gdebug.log_info("day_of_year:"..cldr:day_of_year())
	gdebug.log_info("get_turn:"..cldr:get_turn())
	gdebug.log_info("sunlight:"..cldr:sunlight())
	gdebug.log_info("years:"..cldr:years())

end



--[[メッセージを指定した色で表示するだけ]]--
function add_msg(message, h_color)
	gdebug.log_info("ADD MESSAGE ")
	if(h_color == nil) then
		gapi.add_msg(message)
	else
		gapi.add_msg("<color_"..h_color..">"..message.."</color>")
	end
	gdebug.log_info("MESSAGE ADDED ")
end

local g = game

function get_critters()
    local critter_list = {}
    local player_pos = gapi.get_avatar():get_pos_ms()
    local range = 60  -- Maximum distance to check for creatures
    
    -- Scan area around player to find creatures
    for x = player_pos.x - range, player_pos.x + range do
        for y = player_pos.y - range, player_pos.y + range do
            local pos = game.tripoint(x, y, player_pos.z)  -- Changed tripoint to game.tripoint
            local creature = gapi.get_creature_at(pos)
            if creature then
                table.insert(critter_list, creature)
                gdebug.log_info("Found creature: " .. creature:disp_name(false, true))
            end
        end
    end
    
    gdebug.log_info("Total creatures found: " .. #critter_list)
    return critter_list
end

function get_players()
    local player_list = {}
    
    -- Always include the avatar (player character)
    local avatar = gapi.get_avatar()
    if avatar then
        table.insert(player_list, avatar)
    end
    
    -- Get all NPCs from the area
    local player_pos = avatar:get_pos_ms()
    local range = 60  -- Maximum distance to check for NPCs
    
    for x = player_pos.x - range, player_pos.x + range do
        for y = player_pos.y - range, player_pos.y + range do
            local pos = game.tripoint(x, y, player_pos.z)  -- Changed tripoint to game.tripoint
            local npc = gapi.get_npc_at(pos)
            if npc then
                table.insert(player_list, npc)
            end
        end
    end
    
    gdebug.log_info("Total players/NPCs found: " .. #player_list)
    return player_list
end



function get_wears(chara, target_bp)
    gdebug.log_info("get_wears begin")
    if not chara then
        gdebug.log_info("get_wears: nil character")
        return {}
    end

    local char = chara:as_character()
    if not char then
        gdebug.log_info("get_wears: not a character")
        return {}
    end
    gdebug.log_info("Inspecting item object")
for k, v in pairs(getmetatable(item) or {}) do
    gdebug.log_info("Item has method/property: " .. tostring(k))
end
    local item_list = {}
    
    -- Define the body parts to check
    local body_parts = {"torso", "head", "eyes", "mouth", "arm_l", "arm_r", 
                        "hand_l", "hand_r", "leg_l", "leg_r", "foot_l", "foot_r"}
    
    -- Common flags found on wearable items
    local wearable_flags = {
        "VARSIZE", "WAIST", "OUTER", "BELTED", "SKINTIGHT",
        "OVERSIZE", "POCKETS", "HOOD", "COLLAR", "WATCH", "ALLOWS_NATURAL_ATTACKS"
    }
    
    for _, bp in ipairs(body_parts) do
        local bp_id = game.bodypart_id(bp)
        
        -- Skip if target body part specified and this isn't it
        if target_bp and bp_id ~= target_bp then
            goto continue
        end
        
        gdebug.log_info("Checking body part: " .. bp)
        
        -- Try to find items with common wearable flags on this body part
        for _, flag in ipairs(wearable_flags) do
            local flag_id = game.flag_id(flag)
            
            if char:worn_with_flag(flag_id, bp_id) then
				local item = char:item_worn_with_flag(flag_id, bp_id)
                if item then
                    local name = "unknown"
                    local type_id = "unknown"


               
                        local alt_name_success, alt_name_result = pcall(function() 
                            return item:tname()
                        end)
                        if alt_name_success then
                            name = alt_name_result
                        else
                            gdebug.log_info("Failed to get tname: " .. tostring(alt_name_result))
                        end
                   

                    gdebug.log_info("Found worn item: " .. name .. " (type: " .. type_id .. ") on " .. bp)
                    table.insert(item_list, item)
                    break  -- move to next body part once an item is found
                else
                    gdebug.log_info("Item is nil despite flag check passing for " .. bp)
                end

            end
        end
        
        ::continue::
    end
    
    gdebug.log_info("Found " .. #item_list .. " worn items total")
    return item_list
end


function get_item_by_id(ch, item_id)
    local inv_items = ch:inv_dump()
    for _, it in ipairs(inv_items) do
        -- The correct way to get the item type id as a string
        if it:get_type():str() == item_id then
            return it
        end
    end
    return nil
end




--[[Characterが着用しているアイテムの中からランダムに1つ取得する。body_partが指定されている場合はその部分を覆うもののみ対象。]]--
function get_random_wear(chara, body_part)
    local item_list = get_wears(chara, body_part)
    if item_list and #item_list > 0 then  -- Check that list exists AND has items
        return item_list[math.random(#item_list)]
    else
        return nil
    end
end

--Check if target is naked, from dda lua traits
function is_naked(chara)
	
	if not chara then 
       return true 
    end

   	local char = chara:as_character()
    if not char then
    	gdebug.log_info("Not a character type")
    	return true
   	end

    gdebug.log_info("Checking worn items")


    local worn_items = get_wears(char)
    if not worn_items or #worn_items == 0 then
        gdebug.log_info("No worn items found")
   	    return true
    end

    gdebug.log_info("Found worn items: " .. #worn_items)
	
    return false
end



--[[中心点の周囲8マスの中で誰もいないマスのリストを取得する]]--
function get_around_empty_locs(center)
    local here = gapi.get_map()
    local locs = {}
    for delta_x = -1, 1 do
        for delta_y = -1, 1 do
            local point = game.tripoint(center.x + delta_x, center.y + delta_y, center.z)
            -- Use is_passable instead of just checking for walls
            if here:is_passable(point) and not gapi.get_creature_at(point) then
                table.insert(locs, point)
            end
        end
    end
    return locs
end

--[[指定した範囲内のtripointリストを取得する。]]--
function get_around_locs(center, min_radius, max_radius)

	local locs = {}

	--ひどいネストだ...
	for ix = center.x + (-1 * max_radius), center.x + max_radius do
		if (ix <= -1 * min_radius or ix >= min_radius) then
			for iy = center.y + (-1 * max_radius), center.y + max_radius do
				if (iy <= -1 * min_radius or iy >= min_radius) then
					local point = game.tripoint(ix, iy, center.z)
					table.insert(locs, point)
				end
			end
		end
	end

	return locs
end


function getInfo(obj)
    if obj == nil then
        gdebug.log_info("obj is nil!")
        return nil
    end
    
    -- If it's a monster, return it directly
    if obj:is_monster() then
        return obj:as_monster()
    end

    -- For avatar/player, return directly
    if obj:is_avatar() then
        return obj
    end

    -- For NPCs, return directly  
    if obj:is_npc() then
        return obj
    end
    
    return nil
end

--classesに独自function実装できないかなーと弄ってうまくいかなかった残骸
--MyPlayer = {}
--MyPlayer.new = function(creature)
--	local this = debug.setmetatable(creature, debug.getmetatable(player))
--
--	this.sayHello = function(self)
--		gdebug.log_info("Hello, I'm player!")
--	end
--
--	return this
--
--end
--
--function iuse_hoge(item, active)
--
--	gdebug.log_info("hoge")
--
--	local center = ch:pos()
--	local selected_x, selected_y = game.choose_adjacent("誰に対して使用しますか？", center.x, center.y)
--	local selected_point = tripoint(selected_x, selected_y, center.z)
--
--	local someone = g:critter_at(selected_point)
--
--	gdebug.log_info(someone:disp_name( false, true ))
--
--	local hoge = MyPlayer.new(someone)
--
--	hoge:sayHello()
--
--end
--
--
--function iuse_hoge(item, active)
--
--	gdebug.log_info("hoge")
--
----	local center = ch:pos()
----	local selected_x, selected_y = game.choose_adjacent("誰に対して使用しますか？", center.x, center.y)
----	local selected_point = tripoint(selected_x, selected_y, center.z)
----
----	local someone = g:critter_at(selected_point)
----
----	gdebug.log_info(someone:disp_name( false, true ))
----
----	someone.hello()
--
--end
--
--function fuga()
--
--	local center = ch:pos()
--	local selected_x, selected_y = game.choose_adjacent("誰に対して使用しますか？", center.x, center.y)
--	local selected_point = tripoint(selected_x, selected_y, center.z)
--
--	local someone = g:critter_at(selected_point)
--
--	gdebug.log_info(someone:disp_name( false, true ))
--
--	someone.hello(someone)
--end
--
--classes.Creature.hello = function(self)
--	gdebug.log_info("hello, I'm Creature!")
--	gdebug.log_info(Creature.disp_name( false, true ))
--	gdebug.log_info(self.disp_name( false, true ))
--end
--
--classes.Character.hello = function(self)
--	gdebug.log_info("hello, I'm Character!")
--	gdebug.log_info(Character.disp_name( false, true ))
--	gdebug.log_info(self.disp_name( false, true ))
--end
--
--classes.monster.hello = function(self)
--	gdebug.log_info("hello, I'm monster!")
--	gdebug.log_info(monster.disp_name( false, true ))
--	gdebug.log_info(self.disp_name( false, true ))
--end
--
--classes.player.hello = function(self)
--	gdebug.log_info("hello, I'm player!")
--	gdebug.log_info(player.disp_name( false, true ))
--	gdebug.log_info(self.disp_name( false, true ))
--end

