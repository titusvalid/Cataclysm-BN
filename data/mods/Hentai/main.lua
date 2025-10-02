 MOD = game.mod_runtime[game.current_mod]

--[[When starting a new game]]--
function on_new_player_created()

    local ch = gapi.get_avatar()
    local map = gapi.get_map()
    
    -- Get the character's inventory and check for the item
    local has_pet_item = false
    local pet_item = nil
    
    -- Check inventory for the item
    local inv_items = ch:inv_dump()
    if inv_items then
        for _, item_ptr in ipairs(inv_items) do
            -- Get the item type ID and compare it
            local item_type = item_ptr:get_type_id()
            if item_type and item_type == "fake_prof_pet" then
                has_pet_item = true
                pet_item = item_ptr
                break
            end
        end
    end

    -- Processing when starting with the "One Person and One Animal" profession
    local pet_item_index = -1
    if has_pet_item and pet_item then
        

    
        --Display pet selection menu
        local menu = gapi.create_uimenu()
        local choice = -1
        menu.title = PROF_PET_LIST.TITLE

        local counter = 0
        for key, value in pairs(PROF_PET_LIST.LIST_ITEM) do
            menu:add(counter, value.ENTRY)
            counter = counter + 1
        end

        choice = menu:query(true)
        if choice == nil or choice < 0 then
            return
        end

        --Distribute the pet and bonus items corresponding to the selected option
        local locate_list = get_around_empty_locs(ch:get_pos_ms())
        
        -- Log player position
        local player_pos = ch:get_pos_ms()
        
        if (#locate_list == 0) then
            table.insert(locate_list, ch:get_pos_ms())
        end

        local spawn_pos = locate_list[math.random(#locate_list)]
        -- Ensure spawn_pos is a proper tripoint
        spawn_pos = game.tripoint(spawn_pos.x, spawn_pos.y, spawn_pos.z)
        

        if not map then
            gdebug.log_error("Failed to get map!")
        else
            -- Spawn monster with proper tripoint
            local monster_id = PROF_PET_LIST.LIST_ITEM[choice+1].PET_ID
            local mon = map:spawn_monster(monster_id, spawn_pos)
            
            -- Check if monster spawned successfully
            if mon then
                mon.friendly = -1
                mon:add_effect(efftype_id("pet"), TimeDuration.from_turns(1), "num_bp", true)
            
                -- Check the monster type using the display name to be safe
                local mon_type = mon:disp_name(false, true):lower()
                if mon_type:find("succub") then -- Match succubus, succubi, etc.
                    mon:disable_special("WIFE_U")
                end
            
            
                for key, value in pairs(PROF_PET_LIST.LIST_ITEM[choice+1].BONUS_ITEM) do
                    -- Create item and spawn at character's position, then try to pick it up
                    local pos = game.tripoint(ch:get_pos_ms().x, ch:get_pos_ms().y, ch:get_pos_ms().z)
                    gapi.get_map():spawn_item(pos, value, 1)
                end
            
                ch:mod_moves(-200)
            else
                gdebug.log_error("Failed to spawn monster - spawn_monster returned nil")
                -- Try to get more debug info
                local existing = gapi.get_creature_at(spawn_pos)
                if existing then
                end
            end
        end

    end

    return false
end


--[[ミッションをクリアした際のコールバック]]--
MOD.on_player_mission_finished = function(player_id, mission_id)

end



function _G.preg_process(mother, father)

    -- Debug info

    -- If mother is actually male, skip entirely
    if mother.male then
        return
    end

    -- If no pregnancy marker yet, do nothing:
    if not mother:has_effect(efftype_id("pregnantcy")) and not mother:has_effect(efftype_id("impregnated")) then
        return
    end

    -- If we have 'impregnated' but not 'pregnantcy', convert it.
    if mother:has_effect(efftype_id("impregnated")) and not mother:has_effect(efftype_id("pregnantcy")) then
        mother:remove_effect(efftype_id("impregnated"))
        -- Add 'pregnantcy' with new standard: intensity 9, 90-day duration
        mother:add_effect(efftype_id("pregnantcy"), TimeDuration.from_days(90), nil, 9, true)
    end

    -- Now, handle the 'pregnantcy' effect (it should be present if we reached here either initially or after conversion)
    if mother:has_effect(efftype_id("pregnantcy")) then
        local intensity = mother:get_effect_int(efftype_id("pregnantcy"))

        -- Birth occurs when intensity has decayed to 1.
        -- The effect's own int_decay_step handles the intensity decrease from 9.
        if intensity == 1 then
            birth_process(mother, father)
            -- birth_process is expected to handle removal of the 'pregnantcy' effect.
        else
            -- No manual intensity change needed here. The effect decays naturally.
        end
    end
end



function table.contains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end



function _G.birth_process(mother, father)

    if not mother:has_effect(efftype_id("pregnantcy")) then
        return
    end
        
    local map = gapi.get_map()
    
    -- Birth probability check
    if (math.random(100) > 99) then
        mother:mod_pain(25)
        add_msg(ActorName(mother, "have", "has") .. " went into labor!", H_COLOR.RED)
        return
    end

    -- Check for spawn location
    local locate_list = get_around_empty_locs(mother:get_pos_ms())
    if (#locate_list == 0) then
        return
    end

    local locate = locate_list[math.random(#locate_list)]

    -- Remove pregnancy and update counter
    mother:remove_effect(efftype_id("pregnantcy"))
    local pregcount = tonumber(mother:get_value("hentai_pregcount")) or 0
    pregcount = pregcount + 1
    mother:set_value("hentai_pregcount", tostring(pregcount))
    
    -- Spawn child NPC
    add_msg(mother:get_name() .. " has given birth to a baby!")
    add_msg((father and father:get_name() or "Unknown") .. " is the father!")
    local child_id = map:place_npc(locate.x, locate.y, "darkdays_children")

    -- Store father's traits for the genetics callback
    local father_traits = {
        str = father and father:get_str() or 8,
        dex = father and father:get_dex() or 8,
        int = father and father:get_int() or 8,
        per = father and father:get_per() or 8,
        hair = father and father:get_value("hair") or "",
        eyes = father and father:get_value("eyes") or "",
        skin = father and father:get_value("skin") or ""
    }
    
    -- Store mother's traits
    local mother_traits = {
        str = mother:get_str() or 8,
        dex = mother:get_dex() or 8,
        int = mother:get_int() or 8,
        per = mother:get_per() or 8,
        mutations = mother:get_mutations(true)
    }

    -- Register one-time hook for genetics application
    gapi.add_on_every_x_hook(TimeDuration.from_turns(1), function()
        -- Find child NPC
        local map = gapi.get_map()
        local child = gapi.get_npc_at(game.tripoint(locate.x, locate.y, locate.z))

        if not child then
            return 
        end
        
        -- Prevent duplicate application
        if child:get_value("genetics_applied") == "yes" then
            return false
        end
        
        
        -- Determine gender
        local is_male = (math.random(100) > 50)
        
        -- Apply genetics
        apply_genetics(child, is_male, mother_traits, father_traits)
        
        -- Add virgin trait and mark as child
        child:set_mutation(trait_id("VIRGIN"))
        child:set_value("npctalk_var_typevar_contextvar_is_child", "yes")
        child:set_value("npctalk_var_typevar_contextvar_gender", is_male and "male" or "female")
        child:set_value("npctalk_var_typevar_contextvar_genetics_applied", "yes")
        
        return false  -- Stop the hook from running again
    end)

    add_msg("Then something strange has occurred and the baby grew up in an instant!")
    map:spawn_item(mother:get_pos_ms(), "scroll_of_naming", 1)
    add_msg("Something has rolled at your feet.", H_COLOR.GREEN)
    mother:mod_moves(-100)
    
    return false
end

-- Function to apply genetics to any NPC/creature
function _G.apply_genetics(target, is_male, mother_traits, father_traits)
    
    -- If no gender provided, randomly assign one
    if is_male == nil then
        is_male = (math.random(100) > 50)
    end
    
    -- Default traits if not provided
    mother_traits = mother_traits or {
        str = 8,
        dex = 8,
        int = 8,
        per = 8,
        mutations = {}
    }
    
    father_traits = father_traits or {
        str = 8,
        dex = 8,
        int = 8,
        per = 8,
        hair = "",
        eyes = "",
        skin = ""
    }
    
    -- Calculate base stats
    local child_str = math.floor((mother_traits.str + father_traits.str) / 2) + math.random(-1, 1)
    local child_dex = math.floor((mother_traits.dex + father_traits.dex) / 2) + math.random(-1, 1)
    local child_int = math.floor((mother_traits.int + father_traits.int) / 2) + math.random(-1, 1)
    local child_per = math.floor((mother_traits.per + father_traits.per) / 2) + math.random(-1, 1)
    
    -- Apply stats
    target:set_str_bonus(child_str)
    target:set_dex_bonus(child_dex)
    target:set_int_bonus(child_int)
    target:set_per_bonus(child_per)
    
    -- Extract appearance traits from mother
    local appearances = { hair = nil, eyes = nil, skin = nil }
    
    if mother_traits.mutations then
        for _, mut_id in pairs(mother_traits.mutations) do
            local mut = mut_id:obj()
            if mut and mut.types then
                if table.contains(mut.types, "eye_color") then
                    appearances.eyes = mut_id
                elseif table.contains(mut.types, "skin_tone") then
                    appearances.skin = mut_id
                end
            end
        end
    end
    
    -- Random hair style selection
    local hair_styles = {
        "hair_black_crewcut", "hair_black_mohawk", "hair_black_fro",
        "hair_black_short", "hair_black_medium", "hair_black_long",
        "hair_brown_crewcut", "hair_brown_mohawk", "hair_brown_fro",
        "hair_brown_short", "hair_brown_medium", "hair_brown_long",
        "hair_blond_crewcut", "hair_blond_mohawk", "hair_blond_fro",
        "hair_blond_short", "hair_blond_medium", "hair_blond_long",
        "hair_red_crewcut", "hair_red_mohawk", "hair_red_fro",
        "hair_red_short", "hair_red_medium", "hair_red_long",
        "hair_white_short", "hair_white_medium", "hair_white_long",
        "hair_gray_short", "hair_gray_medium", "hair_gray_long"
    }
    
    -- Gender-based hair style selection
    local selected_hair_style
    if is_male then
        -- Short hair styles for males
        local male_hair_styles = {
            "hair_black_crewcut", "hair_black_mohawk", "hair_black_fro", "hair_black_short",
            "hair_brown_crewcut", "hair_brown_mohawk", "hair_brown_fro", "hair_brown_short",
            "hair_blond_crewcut", "hair_blond_mohawk", "hair_blond_fro", "hair_blond_short",
            "hair_red_crewcut", "hair_red_mohawk", "hair_red_fro", "hair_red_short",
            "hair_white_short", "hair_gray_short"
        }
        selected_hair_style = male_hair_styles[math.random(#male_hair_styles)]
    else
        -- Medium and long hair styles for females
        local female_hair_styles = {
            "hair_black_medium", "hair_black_long",
            "hair_brown_medium", "hair_brown_long",
            "hair_blond_medium", "hair_blond_long",
            "hair_red_medium", "hair_red_long",
            "hair_white_medium", "hair_white_long",
            "hair_gray_medium", "hair_gray_long"
        }
        selected_hair_style = female_hair_styles[math.random(#female_hair_styles)]
    end
    
    target:set_mutation(trait_id(selected_hair_style))
    
    -- Eye color (50% chance from each parent)
    if math.random(100) > 50 and father_traits.eyes ~= "" then
        target:set_mutation(trait_id(father_traits.eyes))
    elseif appearances.eyes then
        target:set_mutation(appearances.eyes)
    end
    
    -- Skin tone (50% chance from each parent)
    if math.random(100) > 50 and father_traits.skin ~= "" then
        target:set_mutation(trait_id(father_traits.skin))
    elseif appearances.skin then
        target:set_mutation(appearances.skin)
    end
    
    -- Set gender and handle gender-specific traits
    target.male = is_male
    
    if is_male then
        if target:has_trait(trait_id("SMALL_BREAST")) then
            target:unset_mutation(trait_id("SMALL_BREAST"))
        end
        if target:has_trait(trait_id("BIG_BREAST")) then
            target:unset_mutation(trait_id("BIG_BREAST"))
        end
    end
    
    -- Inherit some mutations (25% chance)
    if mother_traits.mutations then
        local inherit_mutations = {}
        for _, mut_id in pairs(mother_traits.mutations) do
            local mut = mut_id:obj()
            if mut and 
               not mut.profession and 
               mut.purifiable ~= false and
               not table.contains(mut.types or {}, "hair_style") and
               not table.contains(mut.types or {}, "eye_color") and
               not table.contains(mut.types or {}, "skin_tone") and
               not table.contains(mut.types or {}, "facial_hair") then
                table.insert(inherit_mutations, mut_id)
            end
        end
        
        for _, mut in ipairs(inherit_mutations) do
            if math.random(100) <= 25 then
                target:set_mutation(mut)
            end
        end
    end
    
    target:set_value("genetics_applied", "yes")
    return true
end