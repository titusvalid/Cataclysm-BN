MOD = game.mod_runtime[game.current_mod]

_G.HENTAI_MOD_DEBUG_LOGGING_ENABLED = false 


dofile("./data/mods/Hentai/lua/util.lua")
dofile("./data/mods/Hentai/lua/translation.lua")
dofile("./data/mods/Hentai/lua/const.lua")
dofile("./data/mods/Hentai/lua/activity.lua")
dofile("./data/mods/Hentai/lua/monattack.lua")
dofile("./data/mods/Hentai/lua/anthro.lua")
dofile("./data/mods/Hentai/lua/special_event.lua")
dofile("./data/mods/Hentai/main.lua")


-- Activity IDs
local ACTIVITY = {
    SEX = "ACT_SEX",
    STRIP = "ACT_STRIP",
    SEDUCE = "ACT_SEDUCE"
}




local game = game
if game.species_id then
    _G.species_id = game.species_id
    gdebug.log_error("game.species_id defined")
else
    gdebug.log_error("game.species_id not defined")
end

local trait_id = game.trait_id
local bodypart_id = game.bodypart_id
local efftype_id = game.efftype_id
local morale_type = game.morale_type
local is_love_sex			--愛のある行為かどうか
local flag_id = game.flag_id
local activity_id = gapi.activity_id
_G.trait_id = trait_id
_G.bodypart_id = bodypart_id
_G.efftype_id = efftype_id
_G.morale_type = morale_type
_G.flag_id = flag_id
_G.activity_id = activity_id



_G.item = function(id_or_item, qty)
    if type(id_or_item) == "string" then
        -- Create new item from ID string
        qty = qty or 1  -- Default to 1 if quantity not specified
        return gapi.create_item(id_or_item, qty)
    elseif type(id_or_item) == "userdata" or type(id_or_item) == "table" then
        -- Copy an existing item object
        return gapi.copy_item(id_or_item)
    else
        gdebug.log_error("item() called with invalid argument type: " .. type(id_or_item))
        return nil
    end
end


















-- This needs to be properly registered as a global dialogue effect
if not game.dialogue_effects then
    game.dialogue_effects = {}
end

-- Function to process dialogue-based sex activities
-- This will be called by a hook rather than directly by dialogue
function process_sex_dialogue_flags()
    
    
    local player = gapi.get_avatar()
    if not player then
        gdebug.log_error("No player avatar found")
        return
    end
    
    -- Get all player values and log them for debugging
    --local all_values = player:get_all_values()
    --for key, value in pairs(all_values) do
    --end
    
    -- Check if we need to evaluate consent - using full variable name with prefix
    if player:get_value("npctalk_var_general_sex_dialogue_need_check_sex_willing") == "yes" then
        
        -- Find NPC that player is talking to
        local map = gapi.get_map()
        local center = player:get_pos_ms()
        local creatures = {}
        
        -- Search in adjacent tiles for NPCs
        for x = center.x - 1, center.x + 1 do
            for y = center.y - 1, center.y + 1 do
                local pos = game.tripoint(x, y, center.z)
                local someone = gapi.get_creature_at(pos)
                if someone and someone:is_npc() then
                    local npc = someone:as_npc()
                    if npc then
                        table.insert(creatures, npc)
                    end
                end
            end
        end
        
        -- If we found an NPC, evaluate consent
        if #creatures > 0 then
            local npc = creatures[1]
            
            -- Check consent using existing function
            local is_accept, _ = is_accept_u(npc, nil, player)
            
            -- Set the check_sex_willing variable based on consent - using full variable name with prefix
            if is_accept then
                player:set_value("npctalk_var_general_sex_dialogue_check_sex_willing", "yes")
            else
                player:set_value("npctalk_var_general_sex_dialogue_check_sex_willing", "no")
            end
        else
        end
        
        -- Clear the flag so we don't check again - using full variable name with prefix
        player:set_value("npctalk_var_general_sex_dialogue_need_check_sex_willing", "no")
    end
    
    -- Check if we need to start sex activity - using full variable name with prefix
    if player:get_value("npctalk_var_general_sex_dialogue_start_sex_activity") == "yes" then
        
        -- Find NPC that player is talking to
        local map = gapi.get_map()
        local center = player:get_pos_ms()
        local creatures = {}
        
        -- Search in adjacent tiles for NPCs
        for x = center.x - 1, center.x + 1 do
            for y = center.y - 1, center.y + 1 do
                local pos = game.tripoint(x, y, center.z)
                local someone = gapi.get_creature_at(pos)
                if someone and someone:is_npc() then
                    local npc = someone:as_npc()
                    if npc then
                        table.insert(creatures, npc)
                    end
                end
            end
        end
        
        -- If we found an NPC, start sex activity
        if #creatures > 0 then
            local npc = creatures[1]
            
            -- Initialize SEX module with default values since we're coming from dialogue
            SEX.init(10, npc, nil, true)  -- Using default fun_bonus of 10, no device, and assuming love-based
            
            -- Call do_sex with the NPC
            do_sex(npc, nil, player)
            
        else
        end
        
        -- Clear the flag so we don't start again - using full variable name with prefix
        player:set_value("npctalk_var_general_sex_dialogue_start_sex_activity", "no")
    end
end

-- Register a periodic time  hook that handles both dialogue flags and activity status
function register_combined_hook()
    
    avatar = gapi.get_avatar()
    
    local has_activity
    local has_effect




    -- Register a single handler that runs every 1 turn
    gapi.add_on_every_x_hook(TimeDuration.from_turns(1), function()

        if not avatar then
            return true
        end

        
        -- Loop through each player in the list
        --for _, player in ipairs(player_list) do
        --    local all_values = player:get_all_values()
        --    for key, value in pairs(all_values) do
        --    end
        --end




        -- 1. Process dialogue flags
        process_sex_dialogue_flags()

        -- Hentai Mod initialization
        if avatar:get_value("initialized_hentai_mod") ~= "yes" then
            gdebug.log_info("Hentai Mod: First turn initialization.")
            avatar:set_value("initialized_hentai_mod", "yes")
            MOD.on_new_player_created()
        end


        

        -- 2. Process activity status
        has_activity = avatar:has_activity(activity_id("ACT_SEX"))
        has_effect = avatar:has_effect(efftype_id("movingdoing"))
        
        -- Safe string concatenation with nil check
        
        -- Process ACT_SEX activity
        if has_activity then
            
            -- Get the current counter value with nil protection
            local moves_left_str = avatar:get_value("sex_activity_moves_left") or "0"
            local moves_left = tonumber(moves_left_str) or 0
            
            -- Safe logging with nil protection
            
            if avatar:has_effect(efftype_id("movingdoing")) then
                if moves_left <= 0 then
                    -- Normal completion: activity finished because counter reached zero
                    avatar:set_value("sex_activity_moves_left", "0")
                    SEX.act_sex_finish(nil, avatar)
                    gapi.cancel_activity(avatar)
                else
                    -- Process ongoing activity
                    SEX.act_sex_do_turn(nil, avatar)

                    -- Reduce counter for next turn
                    avatar:set_value("sex_activity_moves_left", tostring(moves_left - 1))
                end
            else
                -- This is the initialization phase when activity starts
                avatar:set_value("sex_activity_moves_left", tostring(SEX_BASE_TURN))
                SEX.act_sex_do_turn(nil, avatar)
            end
        elseif has_effect then
            
            -- Modified: Be smarter about when to call premature finish
            local moves_left_str = avatar:get_value("sex_activity_moves_left") or "0"
            local moves_left = tonumber(moves_left_str) or 0
            
            -- Only perform premature finish if we're actually in the middle of the activity
            if moves_left > 0 then
                SEX.act_sex_finish_premature(avatar)
                -- Reset the counter to avoid repeated premature finishes
                avatar:set_value("sex_activity_moves_left", "0")
            end
        end
    end)
        -- Check for hourly events - outside the on_every_x_hook
        gapi.add_on_every_x_hook(TimeDuration.from_hours(24), function()
            
     
            local player_list = get_players()  
            if player_list then
                for key, value in pairs(player_list) do
                    if value then  
                        preg_process(value,avatar)
                        value:remove_effect(efftype_id("gotwifed"))
                    end
                end
            end

        end)

    return true
end



-- Call the combined hook immediately to register it
register_combined_hook()





--[[monsterのspeciesが"CUBI"かどうか判定する]]--
function _G.is_cubi(monster)
    -- Add null check to prevent errors
    if not monster then
        return false
    end

    -- Check if this is actually a monster
    if not monster:is_monster() then
        return false
    end

    -- Use direct species check method on the creature object
    
    -- Call in_species method directly on the monster object
    return monster:in_species(species_id("CUBI"))
end

--[[貞操を失う処理]]--

function _G.deflower_pain(me, is_good)
	if (getGender(me) == true) then -- currently female only
		--todo: implement male on male pain for obvious reasons? (lennyface) but then who is the taker? and do we separate anal/penile virginities? questions, questions...
		return
	end

	local deal_pain
	if (is_good) then
		deal_pain = 5
		
		if me:is_avatar() then
			add_msg("It hurts just a bit.", H_COLOR.LIGHT_GREEN)
		else
			add_msg(me:disp_name( false, true ).." writhes uncomfortably just a little.", H_COLOR.LIGHT_GREEN)
		end
	else
		deal_pain = 15
		
		if me:is_avatar() then
			add_msg("It hurts!", H_COLOR.RED)
		else
			add_msg(me:disp_name( false, true ).." whines and winces from sharp pain!", H_COLOR.RED)
		end
	end

	me:mod_pain( deal_pain ) --apparently this can cause you to stop in the middle of it at will (with safe mode?)
end

--[[妊娠判定]]--
function _G.preg_roll(mother)
	--TODO:need more improve
	--agree, it shouldn't be just a flat chance just once, ideally you should carry semen inside your body for a while and check the impregnation chance per hour or something like that

	local preg_chance = PREG_CHANCE

	--発情中なら基礎妊娠確立を+500
	if (mother:has_effect(efftype_id("estrus"))) then
		preg_chance = preg_chance + 500
	end
	--避妊中なら最終的な妊娠確立を/100
	if (mother:has_effect(efftype_id("contraception"))) then
		preg_chance = preg_chance / 100
	end

	

	if (math.random(50) <= preg_chance) then
        add_msg("Impregnated!", H_COLOR.RED)
		return true
	else
        add_msg("Not impregnated", H_COLOR.RED)
		return false
	end
end

--[[避妊具のiuse処理]]--
    iuse_yiff = function(who, item, active)

	--隣接するキャラクタを選択、取得する。
    if type(player) == "nil" then
      
    end
    
    if type(who) == "nil" then
      
    end
	local center = who:get_pos_ms()
	local chosen_pt = gapi.choose_adjacent("Choose the target direction.", center.x, center.y)
	if not chosen_pt then
		gapi.add_msg("No direction selected.")
		return
	end
	
	local selected_point = game.tripoint(chosen_pt.x, chosen_pt.y, chosen_pt.z)
    
	local someone = gapi.get_creature_at(selected_point)

	if (someone == nil) then
		gapi.add_msg("There is no one in that direction.")
		return
	end
	
	if (someone:is_monster()) then
		-- Calculate total skills for the player
		local total_skills = 0
		if who.get_str and who.get_dex and who.get_int and who.get_per then
			total_skills = who:get_str() + who:get_dex() + who:get_int() + who:get_per()
		end

		-- Get monster difficulty using power_rating instead of direct difficulty access
		local monster = someone:as_monster()
		local monster_diff = 0
		if monster then
			monster_diff = math.floor(monster:power_rating() * 15) -- Convert power rating to difficulty scale
		end


		if total_skills < monster_diff then
			gapi.add_msg("This creature is too powerful for you to attempt anything!")
			return
		end

		if (someone:has_effect(efftype_id("pet"))) then
			if (gapi.query_yn("Do you want to enjoy yourself with "..someone:disp_name(false, true).."? (NOT FULLY IMPLEMENTED!)")) then
				do_sex(someone, item, who)
			else
				return
			end
		else
			-- Allow initiating sex with hostile monsters, but add a confirmation
			if gapi.query_yn("Attempt to force yourself upon " .. someone:disp_name(false, true) .. "? This is dangerous!") then
                do_sex(someone, item, who)
			else
				gapi.add_msg("You decide against it.")
				return
			end
		end

	elseif (someone:is_avatar()) then
		if (gapi.query_yn("Use it on yourself?")) then
			do_sex(someone, item, who) -- Add who as a parameter
		else
			return
		end

	elseif (someone:is_npc()) then
		--HACK:変数someoneはCritterクラスなのでnpcクラスを再取得してやる
		--local partner = g:npc_at(someone:get_pos_ms())
		local partner = someone:as_npc()
		if not partner then
			gapi.add_msg("Error: partner is nil")
			return
		end

		local menu = gapi.create_uimenu()
		local choice = -1

		--パートナーに対して*交渉*を行う。
		menu.title = "Choose Action"

		-- Add menu entries with proper method and parameters
		
		menu:add(0, "How about we *have fun* together?")
		menu:add(1, "Never mind.")

		-- Call query without parameters and get the return value directly
		choice = menu:query()
		
		if (choice == 1) then
			return
		elseif (choice == 0) then
			local is_accept
			is_accept, item = is_accept_u(partner, item, who) 
		
			if (is_accept) then
				do_sex(partner, item, who) -- Add who as a parameter
			end
		else
			return
		end

	else
		gapi.add_msg("ERROR!")
		return
	end


	return 1
end

--[[パートナーが行為を受け入れてくれるかどうかの判定]]--
function _G.is_accept_u(partner, device, who)
    local is_accept = false
    local willing

    -- Pass "who" parameter to get_willing instead of using global player
    willing = get_willing(partner, who)
    
    if (willing > 50) then
        if (is_love_sex) then
            gapi.add_msg("Your partner responds with a great joy.")
            if partner:is_following() or partner:is_friend() then
                ActorSay("<fun_stuff_accept>", partner, who)
            else
                ActorSay("<fun_stuff_accept_wanderer>", partner, who)
            end

            if (math.random(100) <= willing) then
                if (gapi.query_yn("Seems like "..partner:get_name().." wants to enjoy it raw without the contraception.  Accept?")) then
                    device = nil
                    ActorSay("<fun_stuff_raw>", partner, who)
                end
            end
        else
            gapi.add_msg(partner:get_name().." is so terrified of you that "..pro(partner, "he").." will follow your word without a question...")
            ActorSay("<fun_stuff_fear>", partner, who)
        end
        is_accept = true
    elseif (willing > 25) then
        if (is_love_sex) then
            gapi.add_msg("Your partner agrees, albeit looking somewhat embarrassed.")
            ActorSay("<fun_stuff_shy>", partner, who)
        else
            gapi.add_msg(partner:get_name().." is too afraid to refuse you...")
            ActorSay("<fun_stuff_fear>", partner, who)
        end
        is_accept = true
    elseif (willing > 0) then
        gapi.add_msg("Your partner turns you down politely.")
        ActorSay("<fun_stuff_refuse>", partner, who)
    else
        gapi.add_msg("Your partner refuses you roughly.")
        ActorSay("<fun_stuff_refuse_rough>", partner, who)
    end

    -- Store the consent status for dialogue system
    if who and who:is_avatar() then
        if is_accept then
            who:set_value("is_accept_u", "yes")
        else
            who:set_value("is_accept_u", "no")
        end
    end

    return is_accept, device
end

--[[行為に対するパートナーの積極性を取得する]]--
--TODO:いい感じに積極性の範囲を考える。
--ステータスALL8の@が初期シェルターNPCに話しかけた場合、player:talk_skill()は16, player:intimidation()は10を返す。
function _G.get_willing(partner, who)

    -- If partner is enemy, always fail
    if (partner:is_enemy()) then
        return -999, 0, 0
    end

    local willing
    
    -- Calculate trust and fear based on available character stats
    -- Instead of using skill_id which isn't available, use direct stats
    local trust = 0
    local fear = 0
    
    -- Use intelligence and perception for trust instead of speech skill
    if who.get_int and who.get_per then
        -- Average of intelligence and perception as a proxy for social skills
        trust = (who:get_int() + who:get_per()) * 1.5
    else
        -- Fallback to a default value
        trust = 5  -- Default moderate trust value
    end
    
    -- Calculate fear based on strength + size instead of intimidation()
    if who.get_str then
        fear = who:get_str() * 1.5  -- Strength contributes to intimidation
    else
        fear = 5  -- Default fear value
    end
    

    -- Get partner's opinion of player
    local opinion = partner.op_of_u

    -- (trust * 2) + value - (anger / 2) is added to likability
    trust = trust + (opinion.trust * 2) + opinion.value - (opinion.anger / 2)
    -- (fear * 2) + (owed / 2) is added to fear
    fear = fear + (opinion.fear * 2) + (opinion.owed / 2)


    -- Based on traits and status effects
    if (partner:has_effect(efftype_id("drunk"))) then
        trust = trust * 1.2
        fear = fear * 0.8
    end

    if (partner:has_effect(efftype_id("estrus"))) then
        trust = trust * 3.0
        fear = fear / 3
    end

    -- Is the motivation love or fear? Use the higher value
    if (trust >= fear) then
        willing = trust
        is_love_sex = true
    else
        willing = fear
        is_love_sex = false
    end

    -- Corrupt status effect increases willingness
    if (partner:has_effect(efftype_id("corrupt"))) then
        local intensity = partner:get_effect_int(efftype_id("corrupt"))
        willing = willing + intensity * 5
    end

    -- Virgin trait reduces willingness
    if (partner:has_trait(trait_id("VIRGIN"))) then
        willing = willing - 30
    end

    return willing
end

--[[Sexual interaction processing]]--
function _G.do_sex(partner, device, who)

    local pseudo_device

    partner:mod_moves(-200)
    if not(device == nil) then
        pseudo_device = item(device)
    else
        pseudo_device = nil
    end

    --Calculate the number of turns for the act. The more endurance (strength) the player has, the longer it takes to finish.
    --local turn_cost = SEX_BASE_TURN * who:get_str()
    local turn_cost = SEX_BASE_TURN

    --Adjust if the maximum number of turns is exceeded. Otherwise muscle-focused players with growth mods would keep going until death...
    if (turn_cost > SEX_MAX_TURN) then
        turn_cost = SEX_MAX_TURN
    end


    --Calculate the morale bonus from the act.
    -- Revised logic: Safely get dex and use the higher value.
    local fun_base = 0 -- Default value
    local partner_dex = 0
    local who_dex = 0

    if who and who.get_dex then
        who_dex = who:get_dex()
    else
        gdebug.log_error("Initiator (who) is invalid or missing get_dex in do_sex")
    end

    if partner and partner.get_dex then
        partner_dex = partner:get_dex()
    else
        -- Partner might be nil if called incorrectly, or might lack get_dex?
    end

    -- Use the higher dexterity
    if partner_dex > who_dex then
        fun_base = partner_dex
    else
        fun_base = who_dex
    end
    
    -- Handle case where partner was nil (shouldn't happen via iuse_yiff checks, but belt-and-suspenders)
    if not partner then
       fun_base = who_dex 
    end


    local sex_fun_bonus
    -- Prevent division by zero or negative bonus if fun_base is low/zero
    if fun_base > 0 then
        sex_fun_bonus = math.max(1, math.floor(fun_base )) 
    else
        sex_fun_bonus = 20 -- Default minimum bonus
    end
    
    -- Check for consent variable
    -- Modified logic: Check if partner is a monster first
    if partner and partner:is_monster() then
        if partner:has_effect(efftype_id("pet")) then
            is_love_sex = true -- Pet monsters are considered consensual/loving
        else
            is_love_sex = false -- Hostile monsters are non-consensual
        end
    else
        -- Existing logic for NPCs/Player
        is_love_sex = who:get_value("npctalk_var_general_sex_dialogue_is_love_sex") == "yes"
    end

    SEX.init(sex_fun_bonus, partner, pseudo_device, is_love_sex)

    local turnHold = turn_cost * who:get_speed() + 1000 --Turn count * player speed gives the exact move cost in time




    -- Get character from who
    local character = who:as_character()
    if not character then
        gdebug.log_error("Failed to get character from who parameter")
        gapi.add_msg("Error: Couldn't start activity")
        return 0
    end

    -- Create and assign the activity through the proper API
    character:assign_activity(activity_id("ACT_SEX"), turnHold, 0, 0, "")
    
    








    if not(partner == nil) then
        partner:mod_moves(-100) 
    end
    
    gapi.add_msg("<color_pink>*Wait a moment please...*</color>")
    --Only lose virginity if there's a partner.
    if not(partner == nil) then
        lost_virgin(who, true, partner)
        lost_virgin(partner, is_love_sex, who) --if done by fear, obviously that's not willing
    end
	return 1
end

--[[降魔のチョーカーのiuse処理]]--
function _G.iuse_pet_cubi(who, item, active)
    local center = who:get_pos_ms()
    -- Use gapi.choose_adjacent instead of game.choose_adjacent
    local chosen_pt = gapi.choose_adjacent("Choose the target direction.", center.x, center.y)
    
    -- Handle case where no direction is selected
    if not chosen_pt then
        gapi.add_msg("No direction selected.")
        return 0
    end
    
    -- Create the tripoint from the chosen point
    local selected_point = game.tripoint(chosen_pt.x, chosen_pt.y, center.z)

    -- Use gapi.get_monster_at instead of game.get_monster_at
    local monster = gapi.get_monster_at(selected_point)

    if (monster == nil) then
        gapi.add_msg("That's impossible.")
        return 0
    end

    if not(is_cubi(monster)) then
        gapi.add_msg("You can only use this on a Demon.")
        return 0
    end

    if (monster.friendly == -1) then
        gapi.add_msg("Target is already your Pet.")
        return 0
    end

    if (monster.friendly > 0) then
        gapi.add_msg("You manage to take "..monster:disp_name(false, true).." by surprise and put on a choker on "..pro(monster, "him").."!")

        monster.friendly = -1
        monster:add_effect(efftype_id("pet"), TimeDuration.from_turns(1), "num_bp", true)
        monster:disable_special("WIFE_U")

        gapi.add_msg(monster:disp_name(false, true).." has become your Pet!")


    else
        gapi.add_msg("You try to put a choker on "..monster:disp_name(false, true)..", however "..pro(monster, "he").." resisted the attempt.  Perhaps if "..pro(monster, "he").." wasn't so alert you could've caught "..pro(monster, "him").." off guard...")
    end
    return 1
end

--[[性転換の霊薬のiuse処理]]--
function iuse_ts_elixir(item, active)


	--TODO:LUA拡張iuse処理にてアイテムの使用者を取得する方法を考える
	local target = player


	--使用者が妊娠中なら効果は無い。行き場所が無くなっちゃうので
	if (target:has_effect(efftype_id("fertilize")) or target:has_effect(efftype_id("pregnantcy"))) then
		gapi.add_msg(target:disp_name( false, true ).." drank the medicine but it had no effect.")

		if (player:has_item(item)) then
			player:i_rem(item)
		end

		return 0
	end

	target:mod_pain(math.random(200))
	--do we assume (((target))) is (you) for now?
	if (target.male) then
		target.male = false
		add_msg("A sharp pain assails your groin!  You quickly reach down for it without thinking, only to find out that something important that once belonged to you is no longer there!", H_COLOR.YELLOW)
		add_msg(ActorName(target, "are", "is").." now a woman!", H_COLOR.GREEN)
	else
		target.male = true
		add_msg("A sharp pain assails your groin!  You quickly reach down for it without thinking, only to find out that something that doesn't belong to you is growing there!", H_COLOR.YELLOW)
		add_msg(ActorName(target, "are", "is").." now a man!", H_COLOR.GREEN)
	end

	if (player:has_item(item)) then
		player:i_rem(item)
	end

	return 1
end

--[[名前の巻物のiuse処理]]--
function _G.iuse_naming_npc(who, item, active)

    -- Get position from the character using the item
    local center = who:get_pos_ms()  
    local chosen_pt = gapi.choose_adjacent("Choose the target direction.", center.x, center.y)
    
    -- Handle case where no direction is selected
    if not chosen_pt then
        gapi.add_msg("No direction selected.")
        return 0
    end
    
    local selected_point = game.tripoint(chosen_pt.x, chosen_pt.y, chosen_pt.z)
    local someone = gapi.get_npc_at(selected_point)

    if someone == nil then
        gapi.add_msg("There is no one in that direction.")
        return 0
    end
    if not someone:is_npc() then
        gapi.add_msg("You can only use this on NPC.")
        return 0
    end


    -- Create a menu for entering a name
    local menu = gapi.create_uimenu()
    menu.title = "Choose a name for " .. someone:disp_name(false, true)
    
    -- List of names to choose from - add more as needed
    local names = {
        "Bob", "Alice",  "Charlie", "David", "Eve", "Frank", "Grace", "Heidi", "Ivan", "Julie",
        "Kevin", "Linda", "Mike", "Nancy", "Oscar", "Patty", "Quinn", "Robert", "Sarah", "Tom",
        "Uma", "Victor", "Wendy", "Xavier", "Yvonne", "Zach"
    }
    
    -- Add names to the menu
    for i, name in ipairs(names) do
        menu:add(i-1, name)
    end
    
    -- Query the menu
    local choice = menu:query()
    
    -- If a choice was made
    if choice >= 0 then
        local newname = names[choice+1]
        
        -- Rename the NPC
        local oldname = someone.name
        someone.name = newname
        gapi.add_msg(oldname .. " has been given a new name: " .. newname .. ".")
        

        
        return 1
    else
        -- No choice was made
        gapi.add_msg("Name selection canceled.")
        return 0
    end
end

--[[血清(人間)のiuse処理]]--
function _G.iuse_anthromorph(who, item, active)

    --隣接するキャラクタを選択、取得する。
    local center = who:get_pos_ms()
    -- Use gapi.choose_adjacent instead of game.choose_adjacent
    local chosen_pt = gapi.choose_adjacent("Choose the target direction.", center.x, center.y)
    
    -- Handle case where no direction is selected
    if not chosen_pt then
        gapi.add_msg("No direction selected.")
        return 0  -- Changed from false to 0
    end
    
    -- Create the tripoint from the chosen point
    local selected_point = game.tripoint(chosen_pt.x, chosen_pt.y, center.z)
    
    local monster = gapi.get_monster_at(selected_point)

    if (monster == nil) then
        gapi.add_msg("There is no applicable creatures in that direction.")
        return 0  -- Changed from false to 0
    end
    if not(monster:is_monster()) then
        gapi.add_msg("That's impossible.")
        return 0  -- Changed from false to 0
    end
    if (monster.friendly > -1) then
        gapi.add_msg("You can only use this on a Pet.")
        return 0  -- Changed from false to 0
    end

    local result = ANTHRO.main(monster, selected_point)

    
    
    who:mod_moves(-200)

    return 1  -- Changed from true to 1
end

--[[アーティファクト生成のiuse処理]]--
function _G.iuse_spawn_artifact(item, active)


	map:spawn_artifact(player:get_pos_ms())

	gapi.add_msg("For a moment you were seized with a strange feeling as if the world just got distorted.")

	if (player:has_item(item)) then
		player:i_rem(item)
	end

	player:mod_moves(-100)


	return
end

if type(game.monster_attacks) ~= "table" then
  game.monster_attacks = {}
end


function _G.lost_virgin(me, is_good, p)
    if not(me:has_trait(trait_id("VIRGIN"))) then
        return
    end
	local ch = me:as_character()
    --[[todo/ideas:
    perhaps keep count of taken virginities just in case? maybe have a mutation that makes you stronger the more you consume
    speaking of that mutation, demons should totally have it
    ]]--
    if (is_good) then 
    --willing sex
        add_msg(ActorName(me, "have", "has").." lost "..pro(me, "his").." virginity!", H_COLOR.LIGHT_GREEN)
        --modded
        
        --moodlet
        -- 20 for one of a time event should be okay right?
        -- at first I thought making this pc only, but apparently npc can feel happy too so I'll let it slide
        if me:is_avatar() or me:is_npc() then
            ch:add_morale(morale_type("morale_deflower_good"), 20, 0, TimeDuration.from_turns(72000), TimeDuration.from_turns(72000), false,nil)
        end
    else 
    -- rape
        add_msg(ActorName(me, "have", "has").." been robbed of "..pro(me, "his").." virginity!", H_COLOR.RED)
        
        if me:is_avatar() or me:is_npc() then
            ch:add_morale(morale_type("morale_deflower_bad"), -20, 0,TimeDuration.from_turns(30000), TimeDuration.from_turns(30000), false,nil)
        end
    end
    
    --process pain, mostly female deflowering specifics
    deflower_pain(me, is_good)
    
	if me:is_avatar() then
		-- Call memorial hook instead of direct game.add_memorial_log
		local memorial_hooks = game.hooks.on_memorial
		if memorial_hooks then
			memorial_hooks[#memorial_hooks + 1] = {
				text = "Lost virginity to " .. p:disp_name(false, true),
				type = "virginity_lost"
			}
		end
	end
	
	if p:is_avatar() then
		local memorial_hooks = game.hooks.on_memorial
		if memorial_hooks then
			memorial_hooks[#memorial_hooks + 1] = {
				text = "Took " .. me:disp_name(false, true) .. "'s virginity",
				type = "virginity_taken" 
			}
		end
	end

    ch:unset_mutation(trait_id("VIRGIN"))
end
_G.lost_virgin = lost_virgin



























MOD.on_new_player_created = on_new_player_created
MOD.matk_vulgar_speech = matk_vulgar_speech
MOD.matk_wifeu = matk_wifeu
MOD.matk_seduce = matk_seduce
MOD.matk_tkiss = matk_tkiss
MOD.matk_stripu = matk_stripu
MOD.matk_loveflame = matk_loveflame
MOD.matk_expose = matk_expose
MOD.matk_magic_succubi_somnophilia = matk_magic_succubi_somnophilia
MOD.matk_magic_goathead_demon = matk_magic_goathead_demon
MOD.event_goathead_demon = event_goathead_demon
MOD.event_demonbeing_schoolgirl = event_demonbeing_schoolgirl
MOD.iuse_yiff = iuse_yiff
MOD.iuse_pet_cubi = iuse_pet_cubi
MOD.iuse_ts_elixir = iuse_ts_elixir

MOD.iuse_anthromorph = _G.iuse_anthromorph
MOD.iuse_spawn_artifact = iuse_spawn_artifact
MOD.iuse_naming_npc = _G.iuse_naming_npc

function on_preload()
	game.iuse_functions["IUSE_YIFF"] = function(...)
	  return MOD.iuse_yiff(...)
	end
	
	game.iuse_functions["IUSE_PET_CUBI"] = function(...)
	  return MOD.iuse_pet_cubi(...)
	end
	
	game.iuse_functions["IUSE_TS_ELIXIR"] = function(...)
	  return MOD.iuse_ts_elixir(...)
	end
	
	game.iuse_functions["IUSE_NAMING_NPC"] = function(...)
	  return MOD.iuse_naming_npc(...)
	end
	
	game.iuse_functions["IUSE_ANTHROPOMORPH"] = function(...)
	  return MOD.iuse_anthromorph(...)
	end
	
	game.iuse_functions["IUSE_SPAWN_ARTIFACT"] = function(...)
	  return MOD.iuse_spawn_artifact(...)
	end

	game.register_monattack("VULGAR_SPEECH", function(...)
		return MOD.matk_vulgar_speech(...)
	end)
	
	game.register_monattack("WIFE_U", function(...)
		return MOD.matk_wifeu(...)
	end)
	
	game.register_monattack("SEDUCE", function(...)
		return MOD.matk_seduce(...)
	end)
	
	game.register_monattack("THROW_KISS", function(...)
		return MOD.matk_tkiss(...)
	end)
	
	game.register_monattack("STRIP_U", function(monster)
		return MOD.matk_stripu(monster)
	end)
	
	game.register_monattack("LOVE_FLAME", function(...)
		return MOD.matk_loveflame(...)
	end)
	
	game.register_monattack("EXPOSE", function(...)
		return MOD.matk_expose(...)
	end)
	
	game.register_monattack("MAGIC_SUCCUBI_SOMNO", function(...)
		return MOD.matk_magic_succubi_somnophilia(...)
	end)
	
	game.register_monattack("MAGIC_GOATHEAD_DEMON", function(...)
		return MOD.matk_magic_goathead_demon(...)
	end)
	
	game.register_monattack("EVENT_GOATHEAD_DEMON", function(...)
		return MOD.event_goathead_demon(...)
	end)
	
	game.register_monattack("EVENT_DEMONBEING_SCHOOLGIRL", function(...)
		return MOD.event_demonbeing_schoolgirl(...)
	end)
	
end


on_preload()
