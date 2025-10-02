--[[アクティビティ系]]--
local efftype_id = game.efftype_id
--[[*気持ちいいこと*アクティビティ]]--
SEX = {
	sex_fun_bonus,		--行為による意欲ボーナス値
	sex_partner,		--行為の相手。いなければnil。
	pseudo_device,		--行為に使う道具。なければnil。
	is_love_sex			--愛のある行為かどうか
}

SEX.init = function(fun_bonus, ptnr, dvc, love_sex)


	SEX.sex_fun_bonus = math.round(fun_bonus, 0)
	if not(ptnr == nil) then
		SEX.sex_partner = ptnr
	else
		SEX.sex_partner = nil
	end
	if not(dvc == nil) then
		SEX.pseudo_device = dvc
	else
		SEX.pseudo_device = nil
	end
	if not(love_sex == nil) then
		SEX.is_love_sex = love_sex
	else
		SEX.is_love_sex = false
	end
end

--[[*気持ちいいこと*アクティビティ中処理]]--
SEX.act_sex_do_turn = function(act, p)
    if not p then
        return
    end
    
    -- Get the character from the player parameter
    local character = p:as_character()
    if not character then
        return
    end
   
    local current_moves = character:get_moves()

    -- Only execute the turn's logic if moves are sufficient
    if current_moves > 10 then
        gdebug.log_info(string.format("Hentai DEBUG: Player %s moves before mod: %d", character:disp_name(false, true), character:get_moves()))
        character:mod_moves(-150)
        gdebug.log_info(string.format("Hentai DEBUG: Player %s moves after mod: %d", character:disp_name(false, true), character:get_moves()))
    
        -- Validate partner reference (should be safe due to pcall)
        if SEX.sex_partner then
            local ok, info = pcall(function() return SEX.sex_partner:disp_name(false, true) end)
            if ok then
            else
                gdebug.log_error("SEX.act_sex_do_turn: invalid SEX.sex_partner: " .. tostring(info))
                SEX.sex_partner = nil
            end
        end
    

        if SEX.sex_partner then

            if SEX.sex_partner.mod_moves and SEX.sex_partner.get_moves then
                gdebug.log_info(string.format("Hentai DEBUG: Partner %s moves before mod: %d", SEX.sex_partner:disp_name(false, true), SEX.sex_partner:get_moves()))
                SEX.sex_partner:mod_moves(-150)
                gdebug.log_info(string.format("Hentai DEBUG: Partner %s moves after mod: %d", SEX.sex_partner:disp_name(false, true), SEX.sex_partner:get_moves()))
            elseif SEX.sex_partner.mod_moves then
                SEX.sex_partner:mod_moves(-150)
                gdebug.log_info(string.format("Hentai DEBUG: Partner %s moves modified, get_moves not available.", SEX.sex_partner:disp_name(false, true)))
            else
                 gdebug.log_warn("Partner (" .. (SEX.sex_partner:disp_name(false, true) or "Unknown") .. ") does not have mod_moves method.")
            end
        end
    
        -- Get NPC type and select appropriate text
        local npc_type = "generic"
        local is_threesome = false
        
        -- Check if this is a threesome (only check adjacent tiles)
        local map = gapi.get_map()
        local center = character:get_pos_ms()
        local player_is_male = character.male
        local nearby_opposite_sex = 0
        
        -- Only check adjacent tiles (range of 1)
        for x = center.x - 1, center.x + 1 do
            for y = center.y - 1, center.y + 1 do
                local pos = game.tripoint(x, y, center.z)
                local someone = gapi.get_creature_at(pos)
                local pos_str = "("..x..","..y..","..center.z..")" -- Define pos_str here
                
                -- Check if someone exists and is not the character themselves
                if someone and someone ~= character then 
                    local is_opposite_sex = false -- Initialize here for each creature
                    local identified_type = "generic" -- Track type identified in this loop iteration

                    -- Check if character
                    local other_character = someone:as_character()
                    if other_character then

                        if other_character.male ~= player_is_male then
                            is_opposite_sex = true
                            -- Determine NPC type (prioritize this if found)
                            if other_character:is_npc() then
                                -- Attempt to determine NPC type from their id, type_id, or name
                                local npc_id = other_character:get_value("id") or ""
                                local npc_type_id = other_character:get_value("type_id") or ""
                                local name = other_character:disp_name(false, true):lower() -- Use lowercase for easier matching
                                
                                -- Look for class indicators (prioritize specific ones)
                                if npc_id:find("demonbeing_schoolgirl") or npc_type_id:find("demonbeing_schoolgirl") or name:find("schoolgirl") then
                                    identified_type = "demon_schoolgirl"
                                elseif npc_id:find("succubi") or npc_type_id:find("succubi") or name:find("succubus") or
                                       npc_id:find("incubi") or npc_type_id:find("incubi") or name:find("incubus") then
                                    identified_type = "succubus"
                                elseif npc_id:find("anthro_canine") or npc_type_id:find("anthro_canine") or name:find("pet %(dog%)") then
                                    identified_type = "anthro_dog"
                                elseif npc_id:find("anthro_feline") or npc_type_id:find("anthro_feline") or name:find("pet %(cat%)") then
                                    identified_type = "anthro_cat"
                                elseif npc_id:find("anthro_ursine") or npc_type_id:find("anthro_ursine") or name:find("pet %(bear%)") then
                                    identified_type = "anthro_bear"
                                elseif npc_id:find("anthro") or npc_type_id:find("anthro") or name:find("pet") then -- General pet last
                                    identified_type = "anthro"
                                elseif (npc_id:find("darkdays_children") or npc_type_id:find("darkdays_children") or name:find("child")) and not other_character.male then
                                    -- Check if this is a daughter (already confirmed female)
                                    identified_type = "daughter"
                                -- Check for zombie survivor last for NPCs
                                elseif name:find("survivor zombie") or name:find("zombie survivor") then
                                     identified_type = "zed_survivor"
                                end
                            end
                        else -- This is the corrected "else" for the gender check
                        end
                    -- Check if monster (only if not identified as NPC type yet)
                    elseif someone:is_monster() and identified_type == "generic" then
                        local monster = someone:as_monster()
                        if monster then
                            -- Attempt to get monster ID using the .type.id property
                            local monster_id_obj = monster.type
                            local monster_id = "unknown" -- Default if type or id is nil
                            if monster_id_obj and monster_id_obj.id then
                                -- Check if id has a str() method, otherwise assume it's the string
                                if type(monster_id_obj.id) == "string" then
                                    monster_id = monster_id_obj.id
                                elseif type(monster_id_obj.id) == "userdata" and monster_id_obj.id.str then
                                    monster_id = monster_id_obj.id:str()
                                else
                                     gdebug.log_warn("monster.type.id is neither string nor object with str(). Type: " .. type(monster_id_obj.id))
                                end
                            else
                                 gdebug.log_warn("monster.type or monster.type.id is nil for monster: " .. monster:disp_name(false, true):lower())
                            end

                            local monster_name = monster:disp_name(false, true):lower()

                            -- Check specific monster types using ID first, then name as fallback
                            if monster_id == "mon_zed_survivor" or monster_name:find("survivor zombie") or monster_name:find("zombie survivor") then
                                identified_type = "zed_survivor"
                                is_opposite_sex = true -- Count zed survivor as opposite sex for threesome check
                            elseif monster_id == "mon_nursebot_defective" or monster_name:find("nurse bot") then
                                identified_type = "nurse_bot"
                                is_opposite_sex = true -- Assuming nurse bot can be partner
                            elseif monster_id == "mon_broken_cyborg" or monster_name:find("insane cyborg") then -- Assumed mapping
                                identified_type = "mon_broken_cyborg"
                                is_opposite_sex = true -- Count as partner
                            elseif monster_id == "mon_prototype_cyborg" or monster_name:find("prototype cyborg") then -- Assumed mapping
                                identified_type = "mon_prototype_cyborg"
                                is_opposite_sex = true -- Count as partner
                            elseif monster_id == "mon_succubi_lactophilia" or monster_name:find("milkcubus") then
                                identified_type = "mon_succubi_lactophilia"
                                is_opposite_sex = true
                            elseif monster_id == "mon_cambion_female" or monster_name:find("cambion female") then
                                identified_type = "mon_cambion_female"
                                is_opposite_sex = true
                            elseif monster_id == "mon_lessor_succubi" or monster_name:find("lesser succubus") then
                                identified_type = "mon_lessor_succubi"
                                is_opposite_sex = true
                             elseif monster_id == "mon_succubi_sadist" or monster_name:find("domcubus") then
                                identified_type = "mon_succubi_sadist"
                                is_opposite_sex = true
                            elseif monster_id == "mon_succubi_somnophilia" or monster_name:find("sleepcubus") then
                                identified_type = "mon_succubi_somnophilia"
                                is_opposite_sex = true
                            elseif monster_id == "mon_succubi_exhibitionism" or monster_name:find("nudecubus") then
                                identified_type = "mon_succubi_exhibitionism"
                                is_opposite_sex = true
                            elseif monster_id == "mon_greater_succubi" or monster_name:find("greater succubus") then
                                identified_type = "mon_greater_succubi"
                                is_opposite_sex = true
                            elseif monster_id == "mon_corrupted_schoolgirl" or monster_name:find("corrupted schoolgirl") then
                                identified_type = "mon_corrupted_schoolgirl"
                                is_opposite_sex = true
                             elseif monster_id == "mon_corrupted_schoolteacher_female" or monster_name:find("corrupted female teacher") then
                                identified_type = "mon_corrupted_schoolteacher_female"
                                is_opposite_sex = true
                            -- General succubus check *after* specific types
                            elseif monster_id == "mon_succubi" or monster_name:find("succubus") then
                                identified_type = "mon_succubi"
                                is_opposite_sex = true

                            elseif identified_type == "generic" and (monster:in_species(species_id("ZOMBIE")) or monster:in_species(species_id("UNDEAD"))) then
                                identified_type = "default_zombie"

                            end
                        end
                    end

                    -- This is the key block
                    if is_opposite_sex then  -- This condition MUST be true if "Opposite sex DETECTED" was logged
                        nearby_opposite_sex = nearby_opposite_sex + 1
                        -- Update main npc_type
                        if identified_type ~= "generic" then
                           if npc_type == "generic" or
                              (identified_type:find("anthro") and not npc_type:find("anthro")) or 
                              (identified_type == "zed_survivor" and npc_type ~= "zed_survivor") then
                               npc_type = identified_type 
                           end
                        end
                     end
                else
                end
            end
        end
        
        -- Set threesome flag if we found more than one opposite sex character nearby
        is_threesome = nearby_opposite_sex > 1

        

        local text = ""

        local text_color = "pink"
        
        -- Select text based on threesome status and determined npc_type
        if is_threesome then
            -- Try specific type first
            if MOVINGDOING_TEXTS.threesome[npc_type] then
                 text = MOVINGDOING_TEXTS.threesome[npc_type][math.random(#MOVINGDOING_TEXTS.threesome[npc_type])]
            -- Fallback for specific anthro types if general anthro table exists
            elseif npc_type:find("anthro") and MOVINGDOING_TEXTS.threesome.anthro then
                 text = MOVINGDOING_TEXTS.threesome.anthro[math.random(#MOVINGDOING_TEXTS.threesome.anthro)]
            -- Fallback to generic threesome text
            else
                 text = MOVINGDOING_TEXTS.threesome.generic[math.random(#MOVINGDOING_TEXTS.threesome.generic)]
            end
        else -- Not a threesome
            -- Handle generic type with consent check first
            if npc_type == "generic" then
                if SEX.is_love_sex then
                    text = MOVINGDOING_TEXTS.generic[math.random(#MOVINGDOING_TEXTS.generic)]
                else
                    if MOVINGDOING_TEXTS.nonconsent_generic then
                        text = MOVINGDOING_TEXTS.nonconsent_generic[math.random(#MOVINGDOING_TEXTS.nonconsent_generic)]
                    else
                        gdebug.log_warn("nonconsent_generic table not found, falling back to generic for non-love sex!")
                        text = MOVINGDOING_TEXTS.generic[math.random(#MOVINGDOING_TEXTS.generic)]
                    end
                end
            -- Try specific type if not generic
            elseif MOVINGDOING_TEXTS[npc_type] then
                 text = MOVINGDOING_TEXTS[npc_type][math.random(#MOVINGDOING_TEXTS[npc_type])]
            -- Fallback for specific anthro types if general anthro table exists
            elseif npc_type:find("anthro") and MOVINGDOING_TEXTS.anthro then
                 text = MOVINGDOING_TEXTS.anthro[math.random(#MOVINGDOING_TEXTS.anthro)]
             -- Fallback for zombie survivor if specific table exists
             elseif npc_type:find("zed_survivor") and MOVINGDOING_TEXTS.zed_survivor then
                 text = MOVINGDOING_TEXTS.zed_survivor[math.random(#MOVINGDOING_TEXTS.zed_survivor)]
             -- Fallback for nurse bot if specific table exists
             elseif npc_type == "nurse_bot" and MOVINGDOING_TEXTS.nurse_bot then
                 text = MOVINGDOING_TEXTS.nurse_bot[math.random(#MOVINGDOING_TEXTS.nurse_bot)]
            -- Fallback to default_zombie or generic based on consent as the very last resort
            else
                 local is_default_zombie = false
                 -- Re-check the first adjacent creature found for zombie type if type is still generic (or unrecognized)
                 local first_adj_creature = nil
                 for x = center.x - 1, center.x + 1 do
                     for y = center.y - 1, center.y + 1 do
                         if x == center.x and y == center.y then goto continue end -- Skip self tile
                         local pos = game.tripoint(x, y, center.z)
                         first_adj_creature = gapi.get_creature_at(pos)
                         if first_adj_creature then goto found_first_adj end -- Found someone adjacent
                         ::continue::
                     end
                 end
                 ::found_first_adj::

                 -- Check if the found adjacent creature is a standard zombie
                 if first_adj_creature and first_adj_creature:is_monster() then
                     local monster = first_adj_creature:as_monster()
                     if monster then 
                         -- Check species ZOMBIE or UNDEAD
                         if monster:in_species(species_id("ZOMBIE")) or monster:in_species(species_id("UNDEAD")) then
                             is_default_zombie = true
                         end
                     end
                 end

                -- Use default zombie text if applicable, otherwise generic
                if is_default_zombie then
                    text = MOVINGDOING_TEXTS.default_zombie[math.random(#MOVINGDOING_TEXTS.default_zombie)]
                else
                    if SEX.is_love_sex then
                        text = MOVINGDOING_TEXTS.generic[math.random(#MOVINGDOING_TEXTS.generic)]
                    else
                        text = MOVINGDOING_TEXTS.nonconsent_generic[math.random(#MOVINGDOING_TEXTS.nonconsent_generic)]
                    end
                end
            end
        end

        
        -- Display text with pink color for all messages
        gapi.add_msg("<color_" .. text_color .. ">" .. text .. "</color>")
        
        -- Apply the morale and effect updates
        local fun_bonus = SEX.sex_fun_bonus or 50
        local fun_duration = SEX_FUN_DURATION or 3000
        local fun_decay = SEX_FUN_DECAY_START or 1000
        
        character:add_morale(game.morale_type("morale_feeling_good"), fun_bonus, 0, 
                           TimeDuration.from_turns(fun_duration), 
                           TimeDuration.from_turns(fun_decay),
                           false, nil)

        -- Add/refresh movingdoing effect for the character
        -- Consider if this duration should be shorter or managed differently
        character:add_effect(efftype_id("movingdoing"), TimeDuration.from_turns(SEX_BASE_TURN))
        
        -- Apply effect to all characters/monsters of opposite sex within a block
        for x = center.x - 1, center.x + 1 do
            for y = center.y - 1, center.y + 1 do
                local pos = game.tripoint(x, y, center.z)
                local someone = gapi.get_creature_at(pos)
                
                if someone then
                    -- Check character first
                    local other_character = someone:as_character()
                    if other_character and other_character.male ~= player_is_male then
                        other_character:add_effect(efftype_id("movingdoing"), TimeDuration.from_turns(SEX_BASE_TURN))
                        
                        -- Add morale boost to opposite sex characters if this is a love-based activity
                        if SEX.is_love_sex then
                            other_character:add_morale(game.morale_type("morale_feeling_good"), math.floor(fun_bonus / 2), 0, 
                                                TimeDuration.from_turns(fun_duration), 
                                                TimeDuration.from_turns(fun_decay),
                                                false, nil)
                        end
                    -- Check monster only if not a character
                    elseif not other_character and someone:is_monster() then
                         local monster = someone:as_monster()
                         if monster then
                             local monster_name = monster:disp_name(false, true):lower()
                             -- Apply effects to zombie survivor monster if found
                             if monster_name:find("survivor zombie") or monster_name:find("zombie survivor") then
                                 monster:add_effect(efftype_id("movingdoing"), TimeDuration.from_turns(SEX_BASE_TURN))
                                 -- Optionally add morale/other effects for zed survivor if love_sex?
                                 if monster_name:find("nurse bot") then
                                     monster:add_effect(efftype_id("movingdoing"), TimeDuration.from_turns(SEX_BASE_TURN))
                                     -- Optionally add love_sex morale for nurse bot?
                                 end
                             end
                         end
                    end
                end
            end
        end
        
        -- Still apply morale effects to the specific partner if one exists and it's love sex
        if not(SEX.sex_partner == nil) and SEX.is_love_sex then
             -- Ensure partner is a character before applying morale
             local partner_char = SEX.sex_partner:as_character()
             if partner_char then
                partner_char:add_morale(game.morale_type("morale_feeling_good"), fun_bonus, 0, 
                                         TimeDuration.from_turns(fun_duration), 
                                         TimeDuration.from_turns(fun_decay),
                                         false, nil)
             end
        end

    else
        -- Activity doesn't progress this turn if moves are too low
    end
    
end


--[[*気持ちいいこと*アクティビティ終了処理]]--
SEX.act_sex_finish = function(act, p)
    if not p then
        p = gapi.get_avatar()
        if not p then
            gdebug.log_error("Failed to get avatar in SEX.act_sex_finish")
            return
        end
    end
    
    local character = p:as_character()
    if not character then
        gdebug.log_error("Could not get character from player in SEX.act_sex_finish")
        return
    end
    
    gdebug.log_info("Hentai DEBUG: Sex finished. Cleaning up effects and moves.")
    gapi.add_msg("*Fun things* are now over.")

    character:remove_effect(efftype_id("lust"))
    character:remove_effect(efftype_id("movingdoing"))
    
    -- Remove effects from all nearby characters of the opposite sex
    local map = gapi.get_map()
    local center = character:get_pos_ms()
    local player_is_male = character.male
    
    -- Search in a block range (adjacent + 1 more block in each direction)
    for x = center.x - 2, center.x + 2 do
        for y = center.y - 2, center.y + 2 do
            local pos = game.tripoint(x, y, center.z)
            local someone = gapi.get_creature_at(pos)
            
            if someone then
                -- Check character first
                local other_character = someone:as_character()
                if other_character and other_character.male ~= player_is_male then
                    if other_character.get_moves then
                        gdebug.log_info(string.format("Hentai DEBUG: Finish. Unstucking character %s. Moves before: %d", other_character:disp_name(false, true), other_character:get_moves()))
                    end
                    other_character:set_moves(0) -- unstuck the partner
                    if other_character.get_moves then
                        gdebug.log_info(string.format("Hentai DEBUG: Finish. Unstucked character %s. Moves after: %d", other_character:disp_name(false, true), other_character:get_moves()))
                    end
                    other_character:remove_effect(efftype_id("movingdoing"))
                -- Check monster only if not character
                elseif not other_character and someone:is_monster() then
                     local monster = someone:as_monster()
                     if monster then
                         if monster.set_moves then
                             if monster.get_moves then
                                 gdebug.log_info(string.format("Hentai DEBUG: Finish. Unstucking monster %s. Moves before: %d", monster:disp_name(false, true), monster:get_moves()))
                             end
                             monster:set_moves(0)
                             if monster.get_moves then
                                 gdebug.log_info(string.format("Hentai DEBUG: Finish. Unstucked monster %s. Moves after: %d", monster:disp_name(false, true), monster:get_moves()))
                             end
                         end
                         local monster_name = monster:disp_name(false, true):lower()
                         -- Remove effects from zombie survivor monster if found
                         if monster_name:find("survivor zombie") or monster_name:find("zombie survivor") then
                             monster:remove_effect(efftype_id("movingdoing"))
                         -- Remove effects from nurse bot monster if found
                         elseif monster_name:find("nurse bot") then
                             monster:remove_effect(efftype_id("movingdoing"))
                         end
                         -- Also remove from any monster that had sex
                         if monster:has_effect(efftype_id("movingdoing")) then
                             monster:remove_effect(efftype_id("movingdoing"))
                         end
                     end
                end
            end
        end
    end

    -- Handle partner effects
    if SEX.sex_partner then
        if SEX.sex_partner.set_moves then
            if SEX.sex_partner.get_moves then
                gdebug.log_info(string.format("Hentai DEBUG: Finish. Unstucking PARTNER %s. Moves before: %d", SEX.sex_partner:disp_name(false, true), SEX.sex_partner:get_moves()))
            end
            SEX.sex_partner:set_moves(0)
            if SEX.sex_partner.get_moves then
                 gdebug.log_info(string.format("Hentai DEBUG: Finish. Unstucked PARTNER %s. Moves after: %d", SEX.sex_partner:disp_name(false, true), SEX.sex_partner:get_moves()))
            end
        end
        SEX.sex_partner:remove_effect(efftype_id("lust"))
        SEX.sex_partner:remove_effect(efftype_id("movingdoing"))

        -- Check if partner is a monster or NPC
        if SEX.sex_partner:is_monster() then
            -- Apply direct stat changes for monsters (increase friendliness regardless of consent)
            local creature_partner = SEX.sex_partner -- Keep original reference just in case
            local monster_partner = creature_partner:as_monster() -- Attempt explicit cast

            -- Add check if cast worked and monster_partner is not nil
            if not monster_partner then
                 gdebug.log_error("Failed to cast SEX.sex_partner to monster type using :as_monster(). Falling back to original reference.")
                 -- Fallback to the original reference if cast returns nil
                 monster_partner = creature_partner
            end

            -- Ensure monster_partner is valid before proceeding
            if monster_partner then

                local pacification_attempted = false
                local friendly_changed, anger_changed, morale_changed = false, false, false

                -- Try changing friendly (using the potentially re-typed monster_partner)
                local friendly_success, friendly_err = pcall(function()
                    -- Check the type of monster_partner itself before accessing members
                    if type(monster_partner) == "userdata" and type(monster_partner.friendly) == "number" then
                        if monster_partner.friendly ~= -1 then
                            monster_partner.friendly = -1
                            monster_partner:add_effect(efftype_id("pet"), TimeDuration.from_turns(1), "num_bp", true)
                        end
                        friendly_changed = true
                    elseif type(monster_partner) ~= "userdata" then
                         gdebug.log_warn("monster_partner is not userdata after cast/fallback.")
                    end
                end)
                if friendly_success and friendly_changed then
                    pacification_attempted = true
                elseif not friendly_success then
                    gdebug.log_error("Error accessing/setting monster.friendly: " .. tostring(friendly_err))
                elseif not friendly_changed then
                end

                -- Try changing anger (using the potentially re-typed monster_partner)
                local anger_success, anger_err = pcall(function()
                    if type(monster_partner) == "userdata" and type(monster_partner.anger) == "number" then
                        monster_partner.anger = math.max(0, monster_partner.anger - 30)
                        anger_changed = true
                    elseif type(monster_partner) ~= "userdata" then
                         gdebug.log_warn("monster_partner is not userdata after cast/fallback.")
                    end
                end)
                if anger_success and anger_changed then
                    pacification_attempted = true
                elseif not anger_success then
                    gdebug.log_error("Error accessing/setting monster.anger: " .. tostring(anger_err))
                elseif not anger_changed then
                end

                -- Try changing morale (using the potentially re-typed monster_partner)
                local morale_success, morale_err = pcall(function()
                    if type(monster_partner) == "userdata" and type(monster_partner.morale) == "number" then
                        monster_partner.morale = monster_partner.morale - 30
                        morale_changed = true
                    elseif type(monster_partner) ~= "userdata" then
                         gdebug.log_warn("monster_partner is not userdata after cast/fallback.")
                    end
                end)
                if morale_success and morale_changed then
                    pacification_attempted = true
                elseif not morale_success then
                    gdebug.log_error("Error accessing/setting monster.morale: " .. tostring(morale_err))
                elseif not morale_changed then
                end


                -- If no direct modification worked, try fallback (using the potentially re-typed monster_partner)
                if not pacification_attempted then
                    local make_friendly_success, make_friendly_err = pcall(function()
                        -- Check the type of monster_partner itself before calling method
                        if type(monster_partner) == "userdata" and monster_partner.make_friendly then
                             monster_partner:make_friendly() -- Call directly, pcall catches error if method missing
                        else
                             -- Raise an error within pcall if not userdata or method missing
                             error("monster_partner is not userdata or make_friendly method is nil")
                        end
                    end)

                    if make_friendly_success then
                        pacification_attempted = true
                    else
                        -- Log the specific error from pcall
                        gdebug.log_error("Failed to call make_friendly(): " .. tostring(make_friendly_err))
                        -- Don't set pacification_attempted = true here, as the fallback failed
                    end
                else
                end

                -- Final message based on whether any pacification was achieved
                if pacification_attempted then
                    -- Check species before deciding message/action
                    local species_human_id = species_id("HUMAN")
                    if monster_partner:in_species(species_human_id) then
                        local monster_pos = monster_partner:get_pos_ms()
                        local monster_name_original = monster_partner:disp_name(false, true) -- Store name before removal

                        -- Spawn the NPC at the monster's position, pass player character 'p' (not 'character')
                        local new_npc = gapi.spawn_random_npc_at(monster_pos, p) -- 'p' is the player character argument to act_sex_finish

                        if new_npc then
                            -- DEBUG: Check if creature exists at spawn point immediately after
                            local check_creature = gapi.get_creature_at(monster_pos)
                            if check_creature and check_creature:is_npc() then
                            else
                                gdebug.log_warn("DEBUG CHECK: NPC NOT found at spawn location immediately after spawn call.")
                            end
                            
                            -- Remove the original monster
                            local removed = map:remove_monster(monster_partner)
                            if removed then
                                gapi.add_msg(monster_name_original .. " reformed into a neutral survivor!")
                                -- Successfully replaced, skip default message below
                                goto skip_default_monster_message
                            else
                                gdebug.log_error("Failed to remove original monster (" .. monster_name_original .. ") after spawning NPC.")
                                gapi.add_msg("Could not fully replace " .. monster_name_original .. ".")
                                -- Still consider the monster pacified, but couldn't remove original
                            end
                        else
                            gdebug.log_error("Failed to spawn replacement NPC for " .. monster_name_original .. ".")
                            gapi.add_msg(monster_name_original .. " seems calmer now, but couldn't be replaced.")
                            -- Monster is calmer, but NPC spawn failed
                        end
                    else
                         -- Default message for non-human pacified monsters
                         gapi.add_msg(monster_partner:disp_name(false, true) .. " seems calmer now.")
                    end
                else
                    gapi.add_msg("Could not change " .. monster_partner:disp_name(false, true) .. "'s disposition (failed to access attributes/methods?).")
                end
                ::skip_default_monster_message:: -- Label to jump past default messages if replaced
                
                -- No ActorSay dialogue for monsters here
            else
                 gdebug.log_error("Could not get a valid monster object to modify after checks.")
            end
        else
            -- Original logic for NPCs
            -- Update opinion
            local opinion = SEX.sex_partner.op_of_u 
            
            -- Add safety check for opinion being nil, though it shouldn't be for NPCs
            if opinion then 
                if SEX.is_love_sex then
                    opinion.trust = opinion.trust + 2
                    opinion.value = opinion.value + 2
                    opinion.fear = opinion.fear - 1
                    opinion.anger = opinion.anger - 1
                else
                    opinion.fear = opinion.fear + 5
                    opinion.anger = opinion.anger + 1
                    opinion.trust = opinion.trust - 2
                    opinion.owed = opinion.owed - 1
                end
                SEX.sex_partner.op_of_u = opinion
                
                -- After sex dialog - Pass the player character 'p' from the function arguments
                if p then -- Check if player 'p' is valid
                    local player_char = p:as_character()
                    if player_char then
                        if SEX.is_love_sex then
                            if SEX.sex_partner:is_following() or SEX.sex_partner:is_friendly(player_char) then
                                ActorSay("<fun_stuff_love>", SEX.sex_partner, player_char)
                            else
                                ActorSay("<fun_stuff_bye>", SEX.sex_partner, player_char)
                            end
                        else
                            ActorSay("<fun_stuff_bye_fear>", SEX.sex_partner, player_char)
                        end
                    else
                        gdebug.log_error("Could not get player character for ActorSay in act_sex_finish")
                    end
                else
                    gdebug.log_error("Player parameter 'p' was nil in act_sex_finish for NPC dialogue")
                end
            else
                gdebug.log_error("Partner opinion (op_of_u) was nil for non-monster: " .. SEX.sex_partner:disp_name(false, true))
            end
        end
    end

    -- Handle production
    local liquid_of_u = gapi.create_item("h_semen", 1)

    -- Check if player has condom and ask if they want to use it
    local has_condom = false
    local condom_item = false

    -- Create menu for condom use choice
    local menu = gapi.create_uimenu()
    menu.title = "Use condom?"

-- Check for condoms using inv_dump to get all inventory items
local inv_items = character:inv_dump()
for _, item_ptr in ipairs(inv_items) do
    -- The issue is here - item:get_type() returns an ItypeId object, not a string
    -- We need to compare against the string ID of the item type
    local item_type = item_ptr:get_type():str()
    if item_type == "condom" or item_type == "CONDOM_item" then
        has_condom = true
        condom_item = item_ptr
        break
    end
end

	if has_condom and condom_item then
	else
	end
    if has_condom and condom_item then
        menu:add(1, "Yes, use condom")
        menu:add(2, "No")
        
        local choice = menu:query()
        
		if choice == 1 then
			-- Find the item in the inventory and use its index directly
			local inv_items = character:inv_dump()
			local condom_index = -1
			
			for i, item_ptr in ipairs(inv_items) do
				-- Use string comparison with the item's type ID string
				local item_type = item_ptr:get_type():str()
				if item_type == "condom" or item_type == "CONDOM_item" then
					condom_index = i - 1  -- Convert from 1-based Lua indexing to 0-based C++ indexing
					break
				end
			end
			
			if condom_index >= 0 then
				character:i_rem(condom_index)  -- Use the index instead of the item pointer
				local container = gapi.create_item("used_condom", 1)
				
				if not SEX.sex_partner or sameSex(character, SEX.sex_partner, "FEMALE") then
					gapi.add_msg("You discard the used condom.")
				else
					local finisher = (character.male and character or SEX.sex_partner)
					gapi.add_msg(ActorName(finisher, "finish", "finishes") .. " inside the condom!")
				end
				

				local map = gapi.get_map()
				map:spawn_item(character:get_pos_ms(), "used_condom", 1)
			else
				gdebug.log_error("Could not find condom to remove")
			end
		else
			-- Don't use condom, deposit on ground
			local map = gapi.get_map()
			map:spawn_item(character:get_pos_ms(), "h_semen", 1)

			if SEX.sex_partner then
				-- Pregnancy checks for primary partner
				SEX.check_preg(character, SEX.sex_partner)
				SEX.check_preg(SEX.sex_partner, character)
			end
			
			-- Also check pregnancy for all nearby opposite-sex characters
			local center = character:get_pos_ms()
			local player_is_male = character.male
			
			-- Search in a block range (adjacent + 1 more block in each direction)
			for x = center.x - 1, center.x + 1 do
				for y = center.y - 1, center.y + 1 do
					local pos = game.tripoint(x, y, center.z)
					local someone = gapi.get_creature_at(pos)
					
					if someone then
						local other_character = someone:as_character()
						-- Skip primary partner as we already checked them
						if other_character and other_character ~= SEX.sex_partner and other_character.male ~= player_is_male then
							
							if player_is_male then
								-- If player is male, they're the father
								SEX.check_preg(other_character, character)
							else
								-- If player is female, they're the mother
								SEX.check_preg(character, other_character)
							end
						end
					end
				end
			end
		end
    else
        -- No condom available, deposit on ground
        local map = gapi.get_map()
        -- Fixed: Use proper item spawn method
        map:spawn_item(character:get_pos_ms(), "h_semen", 1)

        if SEX.sex_partner then
            -- Pregnancy checks for primary partner
            SEX.check_preg(character, SEX.sex_partner)
            SEX.check_preg(SEX.sex_partner, character)
        end
        
        -- Also check pregnancy for all nearby opposite-sex characters
        local center = character:get_pos_ms()
        local player_is_male = character.male
        
        -- Search in a block range (adjacent + 1 more block in each direction)
        for x = center.x - 1, center.x + 1 do
            for y = center.y - 1, center.y + 1 do
                local pos = game.tripoint(x, y, center.z)
                local someone = gapi.get_creature_at(pos)
                
                if someone then
                    local other_character = someone:as_character()
                    -- Skip primary partner as we already checked them
                    if other_character and other_character ~= SEX.sex_partner and other_character.male ~= player_is_male then
                        
                        if player_is_male then
                            -- If player is male, they're the father
                            SEX.check_preg(other_character, character)
                        else
                            -- If player is female, they're the mother
                            SEX.check_preg(character, other_character)
                        end
                    end
                end
            end
        end
    end
end

--[[Modded: premature finish when the action was interrupted somehow, remove the effect, but no ejaculation/opinion changes/orgasms, etc]]--
--TODO: perhaps add emotional frustration or something? but that could be annoying in case of emergency
--the condom stays intact after this, is that alright? it would be annoying to waste it though
SEX.act_sex_finish_premature = function(p)
    
    -- Check if player is valid
    if not p then
        gdebug.log_error("SEX.act_sex_finish_premature called with nil player")
        
        -- Try to get avatar as fallback
        p = gapi.get_avatar()
        if not p then
            gdebug.log_error("Failed to get avatar in act_sex_finish_premature")
            return
        end
    end
    
    -- Get character from player
    local character = p:as_character()
    if not character then
        gdebug.log_error("Failed to get character from player in act_sex_finish_premature")
        return
    end
    
    gapi.add_msg("*Fun things* were ended prematurely!")
    
    -- Remove effects from character instead of global ch reference
    character:remove_effect(efftype_id("movingdoing"))
    
    
    -- Remove effects from all nearby characters of the opposite sex
    local map = gapi.get_map()
    local center = character:get_pos_ms()
    local player_is_male = character.male
    
    -- Search in a block range (adjacent + 1 more block in each direction)
    for x = center.x - 2, center.x + 2 do
        for y = center.y - 2, center.y + 2 do
            local pos = game.tripoint(x, y, center.z)
            local someone = gapi.get_creature_at(pos)
            
            if someone then
                local other_character = someone:as_character()
                if other_character and other_character.male ~= player_is_male then
                    
                    other_character:remove_effect(efftype_id("movingdoing"))
                    other_character:set_moves(0) -- unstuck the partner
                end
            end
        end
    end
    
    -- Handle partner effects if partner exists
    if not(SEX.sex_partner == nil) then
        SEX.sex_partner:remove_effect(efftype_id("movingdoing"))
        SEX.sex_partner:set_moves(0) 
        
        -- Handle dialog based on relationship type
        if SEX.is_love_sex then
            ActorSay("<fun_stuff_interrupt>", SEX.sex_partner, p)
        else
            ActorSay("<fun_stuff_bye_fear>", SEX.sex_partner, p)
        end
    end
    
end

--[[対象の妊娠判定を行う。]]--
SEX.check_preg = function(mother, father)

    --motherが母親、fatherが父親の想定。それ以外なら処理を抜ける
    if (mother == nil or father == nil) then
        return
    end

    -- Skip if either mother or father is a monster
    if mother:is_monster() or father:is_monster() then
        return
    end


    if (mother.male) then
        return
    end
    if not(father.male) then
        return
    end
    
    -- Change from popup to gapi.add_msg
    gapi.add_msg(ActorName(father, "finish", "finishes").." inside of "..mother:disp_name(false, true).."!")

    mother:set_value(CREAMPIE_SEED_TYPE, "HUMAN")

    --判定に成功すれば孕む。失敗しても5日くらい溜まったままにする。
    if (preg_roll(mother)) then
        if not mother:has_effect(efftype_id("pregnantcy")) then
            mother:add_effect(efftype_id("pregnantcy"), TimeDuration.from_days(90), nil, 9, true)
        else
        end
        local all_values = mother:get_all_values()
        for key, value in pairs(all_values) do
		end
    else
        mother:add_effect(efftype_id("creampie"), TimeDuration.from_turns(72000))
    end
end

