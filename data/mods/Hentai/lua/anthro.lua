--[[ペットのNPC化に関する処理系統]]--

ANTHRO = {
	--[[定数系]]--

	--[[ペットのNPC化時に表示する性別選択リスト]]--
	ANTHRO_PET_SEX_SUFFIX_LIST = {
		TITLE = "Speaking of which, is this Pet male or female?",
		LIST_ITEM = {
			{"Male", "_male"},
			{"Female", "_female"}
		}
	},

	--[[ペットのNPC化時に表示する変化系統]]--
	ANTHRO_PET_PATTERN = {
		--[[犬系]]--
		CANINE = {
			--[[オスメスの性別選択を行うかどうか]]--
			HAS_SEX_SUFFIX = true,
			--[[容姿の選択リストのタイトル]]--
			TITLE = "And how does it look like?",
			--[[容姿の選択リスト]]--
			PERSONAL_LIST = {
				{"Nearly identical to a Human", "anthro_canine_morehuman"},
				{"About Half-Half", "anthro_canine_half"},
				{"Almost like an Animal", "anthro_canine_lesshuman"}
			}
		},
		--[[猫系]]--
		FELINE = {
			HAS_SEX_SUFFIX = true,
			TITLE = "And how does it look like?",
			PERSONAL_LIST = {
				{"Nearly identical to a Human", "anthro_feline_morehuman"},
				{"About Half-Half", "anthro_feline_half"},
				{"Almost like an Animal", "anthro_feline_lesshuman"}
			}
		},
		--[[熊系]]--
		URSINE = {
			HAS_SEX_SUFFIX = true,
			TITLE = "And how does it look like?",
			PERSONAL_LIST = {
				{"Nearly identical to a Human", "anthro_ursine_morehuman"},
				{"About Half-Half", "anthro_ursine_half"},
				{"Almost like an Animal", "anthro_ursine_lesshuman"}
			}
		},
		--[[サキュバス系]]--
		SUCCUBI = {
			HAS_SEX_SUFFIX = false,
			TITLE = "And how does it look like?",
			PERSONAL_LIST = {
				{"Nearly identical to a Human", "anthro_succubi_morehuman"},
				{"Mostly like a Demon", "anthro_succubi_lesshuman"}
			}
		},
		--[[インキュバス系]]--
		INCUBI = {
			HAS_SEX_SUFFIX = false,
			TITLE = "And how does it look like?",
			PERSONAL_LIST = {
				{"Nearly identical to a Human", "anthro_incubi_morehuman"},
				{"Mostly like a Demon", "anthro_incubi_lesshuman"}
			}
		}
	}

}



--[[メイン処理]]--
ANTHRO.main = function(monster, selected_point)
    --TODO:リストメニューの選択がちょっとやっつけになっちゃってるのでそのうち見直す

    --NPC化の変化系統を取得する。
    local anthro_pet_pattern = ANTHRO.get_anthro_pet_pattern(monster)

    --リストが無ければ（変化先がなければ）キャンセル。
    if (anthro_pet_pattern == nil) then
        gapi.add_msg("This creature cannot be transformed to an NPC.")
        return
    end

    if not(gapi.query_yn("Once this pet is transformed into an NPC, you won't be able to change them again.  Confirm?")) then
        return
    end

    local npc_temp_id = ANTHRO.get_npc_temp_id(anthro_pet_pattern)

    --monsterを削除し、NPCを追加する。
    --NOTE:monsterの所持品にアイテムを追加することはできても取得することができないので、ペットに預けていたアイテムがすべて消えてしまう。
    local map = gapi.get_map()
    local ch = gapi.get_avatar()
    local npc_id = map:place_npc(selected_point.x, selected_point.y, npc_temp_id)
    gdebug.log_info("npc_id:" .. tostring(npc_id))
    
    map:remove_monster(monster)

    -- Determine gender based on the NPC template ID for the genetics function
    local is_male = false -- Default to female
    if npc_temp_id:find("_male") then is_male = true
    elseif npc_temp_id:find("incubi") then is_male = true
    -- Explicitly check for female cases, otherwise default stays false
    elseif npc_temp_id:find("_female") then is_male = false 
    elseif npc_temp_id:find("succubi") then is_male = false
    else 
        gdebug.log_warning("Could not determine gender from npc_temp_id: " .. npc_temp_id .. ". Defaulting to female.")
    end

    -- Use a hook to apply genetics after 1 turn, similar to birth_process
    gapi.add_on_every_x_hook(TimeDuration.from_turns(1), function()
        -- Use selected_point which is an upvalue
        local npc = gapi.get_npc_at(game.tripoint(selected_point.x, selected_point.y, selected_point.z)) 
        
        -- Check if NPC exists and hasn't had genetics applied yet
        if npc and npc:get_value("genetics_applied") ~= "yes" then 
            gdebug.log_info("Applying genetics via hook to: " .. npc:disp_name(false, true) .. " with is_male = " .. tostring(is_male))
            if _G.apply_genetics then -- Use _G scope explicitly
                _G.apply_genetics(npc, is_male) -- Pass determined gender
            else
                gdebug.log_error("apply_genetics function not found in hook!")
            end
            return false -- Remove hook after execution
        elseif npc then
            gdebug.log_info("Hook check: Genetics already applied (value='" .. (npc:get_value("genetics_applied") or "nil") .. "') for: " .. npc:disp_name(false, true))
            return false -- Remove hook if already applied
        else
            gdebug.log_info("NPC not found at hook execution time.")
            return false -- Remove hook if NPC disappeared
        end
    end)

    --TODO:本当はこの場でNPCの名前を変更したりしたいんだけど無理なので名前の巻物を与えてお茶をにごす
    local scroll = item("scroll_of_naming", 1)
    map:spawn_item(ch:get_pos_ms(), "scroll_of_naming", 1)
    add_msg("Something has rolled at your feet.", H_COLOR.GREEN)

    return true
end

--[[NPC化の変化系統を取得する]]--
ANTHRO.get_anthro_pet_pattern = function(monster)
    local anthro_pet_pattern = nil
    
    -- Check if monster is valid
    if not monster then
        gdebug.log_info("Monster is nil")
        return nil
    end

    -- Get monster display name for logging and checking
    local monster_name = monster:disp_name(false, true)
    local monster_name_lower = monster_name:lower()
    gdebug.log_info("Processing monster: " .. monster_name)

    -- Get faction string safely using tostring()
    local faction_str = nil
    if monster.faction then
        faction_str = tostring(monster.faction)
        gdebug.log_info("Monster faction detected. Raw tostring() output: '" .. faction_str .. "'")
    else
        gdebug.log_info("Monster has no faction.")
    end

    -- Check for monster types using display name and faction (if faction exists)
    -- Compare faction_str using string.find because tostring() output is complex (e.g., "MonsterFactionIntId[61][dog]")
    if (faction_str and string.find(faction_str, "dog", 1, true)) or monster_name_lower:find("dog") or monster_name_lower:find("wolf") or monster_name_lower:find("coyote") then
        gdebug.log_info("-->ANTHRO_CANINE" .. (faction_str and (" (Faction: " .. faction_str .. ")") or "") .. " or Name match)")
        anthro_pet_pattern = ANTHRO.ANTHRO_PET_PATTERN.CANINE
    elseif (faction_str and string.find(faction_str, "cat", 1, true)) or monster_name_lower:find("cat") or monster_name_lower:find("lynx") or monster_name_lower:find("cougar") or monster_name_lower:find("tiger") then
        gdebug.log_info("-->ANTHRO_FELINE" .. (faction_str and (" (Faction: " .. faction_str .. ")") or "") .. " or Name match)")
        anthro_pet_pattern = ANTHRO.ANTHRO_PET_PATTERN.FELINE
    elseif (faction_str and string.find(faction_str, "bear", 1, true)) or monster_name_lower:find("bear") then
	    gdebug.log_info("-->ANTHRO_URSINE" .. (faction_str and (" (Faction: " .. faction_str .. ")") or "") .. " or Name match)")
	    anthro_pet_pattern = ANTHRO.ANTHRO_PET_PATTERN.URSINE
    -- Check for cubi species (keep this logic as it's already working)
    elseif monster:in_species(species_id("CUBI")) then
        gdebug.log_info("-->ANTHRO_CUBI")
        
        if monster:in_species(species_id("FEMALE")) then
            gdebug.log_info("  -->...is FEMALE.")
            anthro_pet_pattern = ANTHRO.ANTHRO_PET_PATTERN.SUCCUBI
        elseif monster:in_species(species_id("MALE")) then
            gdebug.log_info("  -->...is MALE.")
            anthro_pet_pattern = ANTHRO.ANTHRO_PET_PATTERN.INCUBI
        else
            gdebug.log_info("  -->...is WHAT?")
        end
    end

    return anthro_pet_pattern
end

--[[NPC化の変化系統パターンから変化対象のNPCのtemplateIDを取得する]]--
ANTHRO.get_npc_temp_id = function(anthro_pet_pattern)

    local pet_sex_suffix
    --変化系統パターンにてペットの性別選択の指定がある場合は選択する
    if (anthro_pet_pattern.HAS_SEX_SUFFIX) then
        pet_sex_suffix = ANTHRO.get_sex_suffix()
    else
        pet_sex_suffix = ""
    end

    local anthro_menu_list = anthro_pet_pattern.PERSONAL_LIST

    --容姿の選択リストからnpc_template_idを取得する。
    local menu = gapi.create_uimenu()
    menu.title = anthro_pet_pattern.TITLE

    for key, value in pairs(anthro_menu_list) do
        menu:add(key-1, value[1])
    end

    local choice = menu:query(true)
    
    gdebug.log_info("Raw menu selection value: " .. tostring(choice))
    
    -- Check if a valid selection was made
    if choice == nil or choice < 0 then
        gdebug.log_info("No selection was made, defaulting to first option")
        choice = 0 -- Default to first option if no selection or invalid selection
    end
    gdebug.log_info("Final choice value: " .. tostring(choice))

    --さっき取得したペット性別接尾語をつけておく。
    local npc_temp_id = anthro_menu_list[choice+1][2]..pet_sex_suffix
    gdebug.log_info("npc_temp_id:"..npc_temp_id)

    return npc_temp_id
end

ANTHRO.get_sex_suffix = function()

    --ペットの性別を選択する。
    local menu_suffix = gapi.create_uimenu() -- Changed from game.create_uimenu
    local choice = -1 -- Initialize choice
    menu_suffix.title = ANTHRO.ANTHRO_PET_SEX_SUFFIX_LIST.TITLE

    for key, value in pairs(ANTHRO.ANTHRO_PET_SEX_SUFFIX_LIST.LIST_ITEM) do
        menu_suffix:add(key-1, value[1]) -- Changed from menu_suffix:addentry
    end

    -- Capture the return value of the query
    choice = menu_suffix:query(true) 
    -- Remove the potentially incorrect assignment: choice = menu_suffix.selected

    gdebug.log_info("Raw sex menu selection value: " .. tostring(choice))

    -- Check if a valid selection was made, default to 0 (Male) if cancelled/invalid
    if choice == nil or choice < 0 then
        gdebug.log_info("No sex selection was made or invalid, defaulting to first option (Male)")
        choice = 0 
    end
    gdebug.log_info("Final sex choice value: " .. tostring(choice))

    local pet_sex_suffix = ANTHRO.ANTHRO_PET_SEX_SUFFIX_LIST.LIST_ITEM[choice+1][2]
    gdebug.log_info("pet_sex_suffix:"..pet_sex_suffix)

    return pet_sex_suffix
end
