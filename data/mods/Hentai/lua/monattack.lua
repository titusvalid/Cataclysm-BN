--[[主にモンスターの特殊攻撃関連の処理を記述する。]]--
local body_part_texts = {
	"cheeks", "lips", "ears", "fingers", "hands", "arms", "chest", "belly", "crotch", "ass", "thighs", "legs"
}

local action_texts = {
	"brushes",
	"touches",
	"tickles",
	"rubs",
	"squeezes",
	"gently pinches",
	"plays with",
	"kisses",
	"licks",
	"savors",
	"sucks on",
	"lets out a hot breath on"
}

local hip_action_texts = {
	"grinding",
	"pumping",
	"gyrating",
	"banging",
	"moving",
	"shaking",
	"swinging",
	"swaying"
}
local game = game
local trait_id = game.trait_id
local efftype_id = game.efftype_id
local species_id = game.species_id
local trait_id = game.trait_id
local morale_type = game.morale_type
local activity_id = game.activity_id
local mtype_id = game.mtype_id
--[[デバッグ用ファンクション]]--
function matk_hello(monster)
--function matk_hello(monster, target)
	--NOTE:LUA拡張版DDAはtarget引数を持つmonster_attackが無いっぽいので、monster:attack_target()で攻撃対象を取得している

	local target = monster:attack_target()

	gapi.add_msg("...who?")

	if (target == nil) then
		gapi.add_msg("who!?")
	else
		gapi.add_msg("Ah, it's you, "..target:disp_name(false, true).."!")
		gapi.add_msg(monster:disp_name(false, true)..":Hello, "..target:disp_name(false, true).."!")
	end

end

--[[↓こっから共通処理↓]]--


--[[monsterが攻撃しようとしているターゲットが射程距離内にいるかどうか判定し、可能な場合はCreatureを返す。]]--
function get_attackable_target(monster, max_range)
    
    -- First try the built-in attack_target method
    local someone = monster:attack_target()
    if someone then
        local pos1 = monster:get_pos_ms()
        local pos2 = someone:get_pos_ms()
        local dx = pos1.x - pos2.x
        local dy = pos1.y - pos2.y
        local dist = math.sqrt(dx * dx + dy * dy)
        
        if dist <= max_range then
            -- Check faction even for default target
            if someone:is_monster() then
                local target_monster = someone:as_monster()
                if monster.faction == target_monster.faction then
                    someone = nil -- Clear default target and force scan
                else
                    return someone
                end
            else
                return someone
            end
        end
    end
    
    -- If default target fails or is same faction, scan nearby tiles
    local pos = monster:get_pos_ms()
    local attacker_faction = monster.faction -- Get attacker's faction once
    
    for x = pos.x - max_range, pos.x + max_range do
        for y = pos.y - max_range, pos.y + max_range do
            -- Calculate distance
            local dx = pos.x - x
            local dy = pos.y - y
            local dist = math.sqrt(dx * dx + dy * dy)
            
            -- Skip if too far or same position
            if dist > max_range or dist == 0 then
                goto continue
            end
            
            local check_pos = game.tripoint(x, y, pos.z)
            local creature = gapi.get_creature_at(check_pos)
            
            -- Check if we found a valid target
            if creature and creature ~= monster and 
               monster:sees(creature) and
               monster:attitude_to(creature) < 0 then  -- Only target hostile attitudes (< 0)

                -- Explicitly check if the target is a monster from the same faction
                if creature:is_monster() then
                    local target_monster = creature:as_monster()
                    if attacker_faction == target_monster.faction then
                        goto continue -- Skip this creature
                    end
                end

                return creature
            end
            
            ::continue::
        end
    end
    
    return false
end

function get_attackable_chara(monster, max_range)
    local target = get_attackable_target(monster, max_range)
    
    -- First check if target is nil or a boolean value
    if target == nil or type(target) == "boolean" then
        return nil
    end
    
    -- Now it's safe to check if it's a monster
    if target:is_monster() then
        return nil
    end

    if target:is_avatar() then
        return target 
    elseif target:is_npc() then
        return target
    end
    return nil
end

function get_attackable_player(monster, max_range)
    local target = get_attackable_target(monster, max_range)
    
    -- Check if target is nil or a boolean value
    if target == nil or type(target) == "boolean" then
        return nil
    end
    
    -- Now it's safe to check if it's a monster
    if target:is_monster() then
        return nil
    end

    -- Return target if it's an avatar or NPC
    if target:is_avatar() then
        return target
    elseif target:is_npc() then
        return target
    end

    return nil
end

--[[四捨五入。実数numを、小数idp桁で丸める。ネットの拾い物]]
function math.round(num, idp)
	if (idp and idp > 0) then
		local mult = 10^idp
		return math.floor(num * mult + 0.5) / mult
	end
	return math.floor(num + 0.5)
end

--[[ハートマークの二次曲線（いわゆるLove Formura）のtripointを計算する。ネットの拾い物]]
--[[
	NOTE:CDDAの仕様として、マップの横軸xと縦軸yは
	0-->x	右へ行くほど増
	|
	V
	y		下へ行くほど増
	の関係になっているため、数学的な二次曲線グラフとはy軸を反転して考えてやる必要がある。
]]
function LoveFormula(center, radius, curvature)

	local tripoint_list = {}
	--local center = ch:get_pos_ms()

	local y
	local b = curvature			--ハート曲線の曲がり具合。0だと完全な円になる。
	local dx = 1 / radius * 2	--xのループカウント刻み。刻みを小さくすると綺麗な曲線になるが処理が重くなる...
	local pos
	local rx
	local ry

	--ハートの曲線のtripointを計算
	-- 0 <= x <= 1, 0 <= y <= 1 の部分。つまり右上
	for x = 0, 1, dx do
		y = math.sqrt(1 - x * x) + b * math.sqrt(x)

		--半径を考慮して丸めたpointを求める
		rx = math.round(x * radius, 0)
		ry = math.round(y * radius * -1, 0)

		pos = game.tripoint(rx + center.x, ry + center.y, 0)
		table.insert(tripoint_list, pos)

		--x反転箇所も確保しておく
		pos = game.tripoint(rx * -1 + center.x, ry + center.y, 0)
		table.insert(tripoint_list, pos)
	end

	-- 0 <= x <= 1, -1 <= y <= 0 の部分。つまり右下
    for x = 0, 1, dx do
        y = math.sqrt(1 - x * x) + b * math.sqrt(x)

        --半径を考慮して丸めたpointを求める
        rx = math.round(x * radius, 0)
        ry = math.round(y * radius * -1, 0)

        pos = game.tripoint(rx + center.x, ry + center.y, 0)
        table.insert(tripoint_list, pos)

        --x反転箇所も確保しておく
        pos = game.tripoint(rx * -1 + center.x, ry + center.y, 0)
        table.insert(tripoint_list, pos)
    end


	return tripoint_list
end


--[[targetがヤれる状態かどうか判定]]--
function can_wife(monster, target)
    local immobile_effect = {
        "webbed", "beartrap", "crushed", "grabbed", "in_pit", "sleep", "zapped"
    }

    if (target == nil) then
        return false, false
    end

    -- Check if target exists and is not a monster
    if (target == nil or target:is_monster()) then
        return false, false
    end

    if target:is_avatar() then
    elseif target:is_npc() then
    end
    
    -- Get the character object for proper methods
    local char = target:as_character()
    if not char then
        return false, false
    end
    
    -- Check both torso and legs for clothing
    local wearing_clothes = false

    
    local leg_l_id = game.bodypart_id("leg_l")
    local leg_r_id = game.bodypart_id("leg_r")
    if char:wearing_something_on(leg_l_id) and char:wearing_something_on(leg_r_id) then
        wearing_clothes = true
    end

    if wearing_clothes then
        if (math.random(10) <= 3) then
            add_msg(monster:disp_name(false, true).." is after "..target:disp_name(false, true)..", but they have clothes on!", H_COLOR.YELLOW)
        end
        return false, true  -- Return false with second param indicating clothes are in the way
    end


    for key, value in pairs(immobile_effect) do
        if (target:has_effect(efftype_id(value))) then
            return true, false
        end
    end
    
    return false, false  -- Not possible for other reasons
end

--[[イく判定]]--
function has_cum(me)
    --TODO:超適当な判定。

    local limit = 100		--v1.3から仕様変更。"lust"のintensityがこれを超えたら達する

    --"lust"のintensityを取得
    local intensity = me:get_effect_int(efftype_id("lust"))


    if (intensity >= limit) then
        --"lust"を取り除き、少しだけwaitを掛ける。
        add_msg(ActorName(me, "reach", "reaches").." an orgasm!", H_COLOR.GREEN)
        me:remove_effect(efftype_id("lust"))
        
        -- Only try to add morale if this is a Character (player or NPC)
        if not(me:is_monster()) then
            local char = me:as_character()
            if char then
                -- Make sure we're using the proper morale_type from game namespace
                char:add_morale(game.morale_type("morale_feeling_good"), 10, 10, 
                           TimeDuration.from_turns(100), TimeDuration.from_turns(100), false, nil)
            end
        end
        
        me:mod_moves(-50)

        return true
    end

    return false
end

--[[対象の体液タイプ（アイテム）を取得する。]]--
function get_ejacuate_item(me)
    -- Instead of trying to create an item object, just return the item ID string
    if (me:is_avatar() or me:is_npc()) then
        return "h_semen"  -- Return the string ID directly
    elseif (me:is_monster()) then
        return "d_cum"    -- Return the string ID directly
    end
    
    return nil  -- Return nil if no valid type
end

function matk_vulgar_speech(monster)
	local max_range = 30		--特殊攻撃の最大射程


	--攻撃しようとしているターゲットを取得
	local target = get_attackable_player(monster, max_range)

	if (target == nil) then
		--今回のチェックで捕捉対象を見逃した場合はテキストを表示。
		if (monster:has_effect(efftype_id("target_acquired"))) then
			local speech_texts = VULGAR_SPEECH_TEXTS.TARGET_LOST
			add_msg(speech_texts[math.random(#speech_texts)], H_COLOR.YELLOW)

			monster:remove_effect(efftype_id("target_acquired"))
		end

	else
		if (monster:has_effect(efftype_id("target_acquired"))) then
			--交戦中の場合。
			local speech_texts = VULGAR_SPEECH_TEXTS.TARGET_ENGAGE
			add_msg(speech_texts[math.random(#speech_texts)], H_COLOR.YELLOW)

		else
			--今回のチェックで初めて対象を捕捉した場合。
			local speech_texts = VULGAR_SPEECH_TEXTS.TARGET_ACQUIRE
			add_msg(speech_texts[math.random(#speech_texts)], H_COLOR.YELLOW)

			monster:add_effect(efftype_id("target_acquired"), TimeDuration.from_turns(1), "num_bp", true)
		end
	end

	return true
end

function matk_speech(monster, action_type, target, outcome)
    local max_range = 30
    
    -- Get monster information
    local monster_name = monster:disp_name(false, true):lower()
    local monster_id = nil
    
    -- Try multiple methods to get monster ID
    if monster.type and type(monster.type) == "table" and monster.type.id then
        monster_id = monster.type.id
    elseif monster.get_type_id and type(monster.get_type_id) == "function" then
        monster_id = monster:get_type_id()
    end
    
    -- Find appropriate speech table
    local speech_table = nil
    if monster_id and VULGAR_SPEECH_TEXTS[monster_id] then
        speech_table = VULGAR_SPEECH_TEXTS[monster_id]
    else
        -- Match by name patterns
        if monster_name:find("cambion") then
            if monster_name:find("female") then
                speech_table = VULGAR_SPEECH_TEXTS.mon_cambion_female
            else
                speech_table = VULGAR_SPEECH_TEXTS.mon_cambion_male
            end
        -- Check specific cubi names first
        elseif monster_name:find("domcubus") then 
            speech_table = VULGAR_SPEECH_TEXTS.mon_succubi_sadist
        elseif monster_name:find("sleepcubus") then
            speech_table = VULGAR_SPEECH_TEXTS.mon_succubi_somnophilia
        elseif monster_name:find("nudecubus") then
            speech_table = VULGAR_SPEECH_TEXTS.mon_succubi_exhibitionism
        elseif monster_name:find("milkcubus") then
            speech_table = VULGAR_SPEECH_TEXTS.mon_succubi_lactophilia
        elseif monster_name:find("nurse bot") and monster_name:find("defective") then
            speech_table = VULGAR_SPEECH_TEXTS.mon_nursebot_defective
        -- Then check for general succubus/incubus
        elseif monster_name:find("succub") then
            if monster_name:find("greater") then
                speech_table = VULGAR_SPEECH_TEXTS.mon_greater_succubi
            elseif monster_name:find("lesser") then
                speech_table = VULGAR_SPEECH_TEXTS.mon_lessor_succubi
            else
                speech_table = VULGAR_SPEECH_TEXTS.mon_succubi
            end
        elseif monster_name:find("incub") then
            -- Add specific incubus checks here if needed in the future
            speech_table = VULGAR_SPEECH_TEXTS.DEFAULT -- Placeholder, adjust as needed
        elseif monster_name:find("schoolgirl") then
            speech_table = VULGAR_SPEECH_TEXTS.mon_corrupted_schoolgirl
        elseif monster_name:find("teacher") and monster_name:find("female") then
            speech_table = VULGAR_SPEECH_TEXTS.mon_corrupted_schoolteacher_female
        end
    end
    
    -- Fallback to default
    if not speech_table then
        speech_table = VULGAR_SPEECH_TEXTS.DEFAULT
    end
    
    -- Default responses for specific actions
    local default_responses = {
        STRIP_success = "I'll take ITEMNAME off you now!",
        STRIP_naked = "Already naked for me? How thoughtful!",
        STRIP_resist_dodge = "Stop squirming! I just want to undress you!",
        STRIP_resist_strength = "Your strength is impressive, but mine is greater!", 
        WIFE_U = "Let me show you true pleasure..."
    }
    
    -- Check for action-specific speech
    local action_key = ""
    if outcome then
        action_key = action_type .. "_" .. outcome
    else
        action_key = action_type
    end
    
    -- Return appropriate dialogue
    local speech = nil
    if speech_table[action_key] and #speech_table[action_key] > 0 then
        speech = speech_table[action_key][math.random(#speech_table[action_key])]
    elseif default_responses[action_key] then
        speech = default_responses[action_key]
    else
        speech = "Come here, sweetie!"  -- Ultimate fallback
    end
    
    -- Replace ITEMNAME placeholder with actual item name if provided
    -- Check if item_name exists and is not nil before using it
    if target and item_name and speech:find("ITEMNAME") then
        speech = speech:gsub("ITEMNAME", item_name)
    end
    
    return speech
end

--[[状態異常"corrupt"をtargetに与える。]]--
function gain_corrupt(target, dur)
    -- First log what we get from target
    
    -- Cast to Character if needed to access get_int()
    local char = target:as_character()
    if not char then
        return
    end
    
    local int_val = char:get_int()

    --対象のINT値の確率で抵抗判定。判定に失敗したら"corrupt"を与える。
    if (math.random(20) > int_val) then
        target:add_effect(efftype_id("corrupt"), TimeDuration.from_turns(dur))
        if target:is_avatar() then
            gapi.add_msg(ActorName(target, "feel", "feels", false).." strangely warm from the inside!")
        end
    else
        gapi.add_msg("However "..target:disp_name(false, true).." successfully "..YouWord(target, "resist", "resists").." the temptation!")
    end
end


--[[↓こっからモンスター特殊攻撃処理↓]]--

--[[誘惑攻撃(近距離)]]--
function matk_seduce(monster)
    local max_range = 5
    
    -- Add error checking
    if not monster then
        return false
    end
    
    local target = get_attackable_chara(monster, max_range)
    
    -- Check if target is nil before trying to use disp_name
    if not target then
        return false
    end
    
    
    --ここでモンスターに行動コストを追加。
    monster:mod_moves(-100)

	--==ターゲットの回避ロール==--
	--超回避システムが発動中なら必ず回避。
    if (target:has_trait(trait_id("UNCANNY_DODGE")) or 
        target:has_effect(efftype_id("uncanny_dodge_effect"))) then
        gapi.add_msg(monster:disp_name(false, true).." tries to reach for "..target:disp_name(false, true)..", but "..pro(target, "he").." "..YouWord(target, "dodge", "dodges").." it with a tremendous momentum!")
        return true
    end
	--物理的な行動による回避ロール。player.dodge_roll()についてはmelee.cppとかを参照。
	if (math.random(100) <= target:get_dodge()) then
		gapi.add_msg(monster:disp_name(false, true).." tries to reach for "..target:disp_name(false, true)..", but "..pro(target, "he").." "..YouWord(target, "manage", "manages").." to dodge it!")
		return true
	end
	--HENTAI的なテキストを取得。
	local bp_names = {table.unpack(body_part_texts)}

	--TODO:尾とか羽とか、特別な部位（特質）がある場合はここでbp_namesに追加しようと思ったけど力尽きた
	--I gotchu homie
	local bp_text = bp_names[math.random(#bp_names)]
	local act_text = action_texts[math.random(#action_texts)]

	--HENTAI的なテキストを表示。
	--modified to show variations better
	local output_text
	
	if (bp_text == "chest" and math.random(10) <= 2) then
		output_text = monster:disp_name(false, true).." fondles "..ActorName(target, "'s", false).." "..bp_text  
    elseif (bp_text == "ears" and math.random(10) <= 2) then
		output_text = monster:disp_name(false, true).." bites "..target:disp_name(false, true).." "..bp_text.." playfully"
    elseif (bp_text == "hands" and math.random(10) <= 2) then
		output_text = monster:disp_name(false, true).." holds "..target:disp_name(false, true).." "..bp_text.." tightly"
    elseif (act_text == "kisses") then
		if (bp_text == "lips") then
			output_text = monster:disp_name(false, true).." joins "..pro(monster, "his").." lips with "..target:disp_name(false, true)..", forcing "..pro(monster, "his").." tongue inside "..pro(target, "his").." mouth and enjoying "..((target:has_trait(trait_id("FORKED_TONGUE"))) and "the feel of "..target:disp_name(false, true).." unusually forked tongue" or "entwining "..YouWord(target, "your", "their").." tongues together").." while tasting each other's saliva"
		else
			output_text = monster:disp_name(false, true).." "..act_text.." "..target:disp_name(false, true).." on "..pro(target, "his").." "..bp_text
		end
	
    elseif (math.random(10) <= 2) then
		if (target:has_trait(trait_id("TAIL_FLUFFY")) and math.random(10) <= 2) then
			output_text = monster:disp_name(false, true).." touches "..target:disp_name(false, true).." fluffy tail"
		elseif (target:has_trait(trait_id("TAIL_FIEND")) and math.random(10) <= 2) then
			output_text = monster:disp_name(false, true).." plays with "..target:disp_name(false, true).." demonic tail"
		elseif (target:has_trait(trait_id("TAIL")) and math.random(10) <= 2) then
			output_text = monster:disp_name(false, true).." brushes "..target:disp_name(false, true).." tail"
		elseif (target:has_trait(trait_id("WINGS")) and math.random(10) <= 2) then
			output_text = monster:disp_name(false, true).." plays with "..target:disp_name(false, true).." wings"
		else
			output_text = monster:disp_name(false, true).." pats "..target:disp_name(false, true).." head"
		end
    elseif (math.random(10) <= 2) then
		output_text = monster:disp_name(false, true).." brushes "..target:disp_name(false, true).." hair"
	elseif (math.random(10) <= 2) then
		output_text = monster:disp_name(false, true).." hugs "..target:disp_name(false, true).." close and breathes in "..pro(target, "his").." scent while licking "..pro(monster, "his").." lips seductively"
    else
       output_text = monster:disp_name(false, true).." "..act_text.." "..target:disp_name(false, true).." "..bp_text
    end
	--print
	add_msg(output_text, H_COLOR.PINK)

	--状態異常"lust"と"corrupt"をtargetに与える。
	--target:add_effect(efftype_id("corrupt"), TimeDuration.from_turns(100))
	gain_corrupt(target, 100)
	target:add_effect(efftype_id("lust"), TimeDuration.from_turns(5) )

	return true 
end

--[[誘惑攻撃(遠距離)]]--
function matk_tkiss(monster)
	local max_range = 10		--特殊攻撃の最大射程


	--攻撃しようとしているターゲットを取得
	local target = get_attackable_chara(monster, max_range)

	if (target == nil) then
		return false
	end

	--ここでモンスターに行動コストを追加。
	monster:mod_moves(-50)

	--==ターゲットの回避ロール==--
	--超回避システムが発動中なら必ず回避。
    if (target:has_trait(trait_id("UNCANNY_DODGE")) or 
        target:has_effect(efftype_id("uncanny_dodge_effect"))) then
        gapi.add_msg(monster:disp_name(false, true).." tries to blow a kiss at "..target:disp_name(false, true)..", but "..pro(target, "he").." "..YouWord(target, "dodge", "dodges").." it with a tremendous momentum!")
        return false
    end
	--物理的な行動による回避ロール。...投げキッスって回避するとかそういう物じゃない気もするが
	if (math.random(100) <= target:dodge_roll()) then
		gapi.add_msg(monster:disp_name(false, true).." tries to blow a kiss at "..target:disp_name(false, true)..", but "..pro(target, "he").." "..YouWord(target, "manage", "manages").." to dodge it!")
		return false
	end

	add_msg(monster:disp_name(false, true).." blows a kiss at "..target:disp_name(false, true).."!", H_COLOR.PINK)

	--状態異常"lust"と"corrupt"をtargetに与える。
	--target:add_effect(efftype_id("corrupt"), TimeDuration.from_turns(50))
	gain_corrupt(target, 50)
	target:add_effect(efftype_id("lust"), TimeDuration.from_turns(2))

	return false
end


--[[脱がす攻撃]]--
function matk_stripu(monster)
    local max_range = 1         -- Special attack maximum range
    local max_value = 250       -- Stripped item placement threshold


    -- Don't strip during intercourse
    if (monster:has_effect(efftype_id("dominate"))) then
        return true
    end
    local target = get_attackable_chara(monster, max_range)

    if (target == nil) then
        return true
    end
    -- Set naked check to disable this attack if target is already naked
    if (is_naked(target)) then
        -- Get dialogue for already naked target
        local dialogue = matk_speech(monster, "STRIP", target, "naked")
        add_msg("<color_pink>" .. dialogue .. "</color>", H_COLOR.PINK)
        return true
    end

    -- Add action cost to the monster here
    monster:mod_moves(-100)
    
    -- Target dodge roll - Uncanny dodge system always avoids if active
    if (target:has_trait(trait_id("UNCANNY_DODGE")) or 
        target:has_effect(efftype_id("uncanny_dodge_effect"))) then
        gapi.add_msg(monster:disp_name(false, true).." tries to undress "..target:disp_name(false, true)..", but "..pro(target, "he").." "..YouWord(target, "dodge", "dodges").." it with a tremendous momentum!")
		local dialogue = matk_speech(monster, "STRIP", target, "dodge_uncanny")
        gapi.add_msg(dialogue)
        return true
    end

    -- Physical action for dodging/resisting
    -- Get character object to access strength
    local char = target:as_character()
    if not char then
        return true
    end
    
    -- Get strength and dodge values
    local str_value = char:get_str()
    local dodge_value = target:dodge_roll()
    
    -- Calculate resist chance: dodge + (strength / 2)
    -- This means strength helps but not as much as dodge skill
    local resist_chance = dodge_value + math.floor(str_value / 2)
    
    
    if (math.random(100) <= resist_chance) then
        -- Choose message based on whether strength or dodge was more significant
        if (str_value > dodge_value * 2) then
            -- Strength-based resistance
            local dialogue = matk_speech(monster, "STRIP", target, "resist_strength")
            add_msg("<color_pink>" .. dialogue .. "</color>", H_COLOR.PINK)
            gapi.add_msg(dialogue)
        else
            -- Dodge-based evasion
            local dialogue = matk_speech(monster, "STRIP", target, "resist_dodge")
            add_msg("<color_pink>" .. dialogue .. "</color>", H_COLOR.PINK)
            gapi.add_msg(dialogue)
        end
        return true
    end

    -- Target is wearing one randomly chosen item
    local target_parts = {"head", "leg_l", "leg_r"}
    local item = nil
    
    -- Try each target part until we find an item
    for _, part_name in ipairs(target_parts) do
        local bp_id = game.bodypart_id(part_name)
        local part_item = get_random_wear(target, bp_id)
        if part_item then
            item = part_item
            break
        end
    end

    if (item == nil) then
        return true
    end
    
    -- Rest of the function remains the same
    local vol = item:get_volume()
    game.map:drop_creature_item(target, item)
    monster:mod_moves(-100)
    gapi.add_msg("<color_pink>"..monster:disp_name(false, true).." quickly takes off "..target:disp_name(false, true).." </color>"..item:tname().." <color_pink>and drops it on the ground!</color>")
    local dialogue = matk_speech(monster, "STRIP", target, "success")
    dialogue = dialogue:gsub("ITEMNAME", item:tname())
    add_msg("<color_pink>" .. dialogue .. "</color>", H_COLOR.PINK)
    return true
end

function matk_wifeu(monster)
	
    local max_range = 2        --特殊攻撃の最大射程
    
    local target = get_attackable_player(monster, max_range)
    if target == nil then
        return false
    end

    -- Check if the target can be attacked, and if they're wearing clothes
    local can_attack, has_clothes = can_wife(monster, target)
    
    -- If target has clothes on, redirect to strip attack instead
    if not can_attack and has_clothes then
        return matk_stripu(monster)
    end

    -- If the target can't be attacked for other reasons, just return
    if not can_attack then
        if (monster:has_effect(efftype_id("dominate"))) then
            monster:remove_effect(efftype_id("dominate"))
            target:add_effect(efftype_id("gotwifed"), TimeDuration.from_turns(-1), "num_bp", true)
        end
        return false
    end
    
    -- Continue with original attack logic if the character can be attacked
    
    -- The rest of the function remains unchanged...
    local hip_act_text = hip_action_texts[math.random(#hip_action_texts)]

    -- ヤる！
    if (monster:has_effect(efftype_id("dominate"))) then
        gapi.add_msg("<color_pink>"..monster:disp_name(false, true).." keeps "..hip_act_text.." "..pro(monster, "his").." hips...</color>")
    else
        local intensity = target:get_effect_int(efftype_id("gotwifed"))
        
        if (intensity >= 3) then
            -- ターゲットが既にお取り込み中の場合は...自主トレを行う。
            add_msg(monster:disp_name(false, true).." enjoys the show while staring at "..target:disp_name(false, true).." as "..pro(monster, "he").." plays with "..pro(monster, "himself").."...", H_COLOR.PINK)

            monster:add_effect(efftype_id("lust"), TimeDuration.from_turns(6))
            monster:mod_moves(-100)
            return true
        else
            -- スペースがあれば突っ込む。何をとは言わんが。
            
            -- Get monster-specific action description
            local monster_name = monster:disp_name(false, true):lower()
            local monster_id = nil
            
            -- Try multiple methods to get monster ID
            if monster.type and type(monster.type) == "table" and monster.type.id then
                monster_id = monster.type.id
            elseif monster.get_type_id and type(monster.get_type_id) == "function" then
                monster_id = monster:get_type_id()
            end
            
            -- Find appropriate action table
            local action_table = nil
            if monster_id and VULGAR_SPEECH_TEXTS[monster_id] then
                action_table = VULGAR_SPEECH_TEXTS[monster_id]
            else
                -- Match by name patterns (same logic as in matk_speech)
                if monster_name:find("cambion") then
                    if monster_name:find("female") then
                        action_table = VULGAR_SPEECH_TEXTS.mon_succubi
                    else
                        action_table = VULGAR_SPEECH_TEXTS.DEFAULT
                    end
                elseif monster_name:find("domcubus") then 
                    action_table = VULGAR_SPEECH_TEXTS.mon_succubi_sadist
                elseif monster_name:find("sleepcubus") then
                    action_table = VULGAR_SPEECH_TEXTS.mon_succubi_somnophilia
                elseif monster_name:find("nudecubus") then
                    action_table = VULGAR_SPEECH_TEXTS.mon_succubi_exhibitionism
                elseif monster_name:find("milkcubus") then
                    action_table = VULGAR_SPEECH_TEXTS.mon_succubi_lactophilia
                elseif monster_name:find("succub") then
                    if monster_name:find("greater") then
                        action_table = VULGAR_SPEECH_TEXTS.mon_greater_succubi
                    elseif monster_name:find("lesser") then
                        action_table = VULGAR_SPEECH_TEXTS.mon_lessor_succubi
                    else
                        action_table = VULGAR_SPEECH_TEXTS.mon_succubi
                    end
                else
                    action_table = VULGAR_SPEECH_TEXTS.DEFAULT
                end
            end
            
            -- Fallback to default if needed
            if not action_table then
                action_table = VULGAR_SPEECH_TEXTS.DEFAULT
            end
            
            -- Get random action text and format it
            local action_texts = action_table.WIFE_U_START
            if not action_texts then
                gdebug.log_warning("WIFE_U_START not found for monster, using DEFAULT WIFE_U_START")
                action_texts = VULGAR_SPEECH_TEXTS.DEFAULT.WIFE_U_START
            end

            local action_text = action_texts[math.random(#action_texts)]
            local monster_name = monster:disp_name(false, true)
            local target_name = target:disp_name(false, true)
            local target_pronoun = pro(target, "him")
            
            -- Format and display the action text
            action_text = string.format(action_text, monster_name, target_name, target_pronoun)
            add_msg(action_text, H_COLOR.PINK)
            
            -- Also display the monster's dialogue
            local dialogue = matk_speech(monster, "WIFE_U", target)
            add_msg("<color_pink>" .. dialogue .. "</color>", H_COLOR.PINK)

            -- モンスターに"dominate"を、対象に"gotwifed"を与える。
            monster:add_effect(efftype_id("dominate"), TimeDuration.from_turns(1), "num_bp", true)
            target:add_effect(efftype_id("gotwifed"), TimeDuration.from_turns(1), "num_bp", true)

            lost_virgin(target, false, monster)
        end
    end
	--状態異常"corrupt"をtargetに与える。
	--target:add_effect(efftype_id("corrupt"), TimeDuration.from_turns(200))

	gain_corrupt(target, 200)

	--状態異常"lust"をtargetとmonster両方に与える。
	target:add_effect(efftype_id("lust"), TimeDuration.from_turns(8))
	local char = target:as_character()
    if not char then
        return
    end
    local dex_val = char:get_dex()


	monster:add_effect(efftype_id("lust"), TimeDuration.from_turns(8 + dex_val))


	if (has_cum(target)) then

		local dialogue = matk_speech(monster, "WIFE_U_CUM", target)
		add_msg("<color_pink>" .. dialogue .. "</color>", H_COLOR.PINK)


		local liquid_id = get_ejacuate_item(target)
		game.map:spawn_item(target:get_pos_ms(), liquid_id, 1) 
	
		
			local liquid_id = get_ejacuate_item(monster)
			game.map:spawn_item(target:get_pos_ms(), liquid_id, 1) 
			if (is_cubi(monster)) then
				--1/5の確率で相手に"FIEND"タイプの変異を与える。どこに注がれたかはこの際考慮しない。血清注射でも変異するんだからどこの穴でも[自主規制]
				--if (1 >= math.random(5)) then
				if (math.random(5) == 1) then
					add_msg("Demonic bodily fluids cause "..target:disp_name(false, true).." body to mutate...", H_COLOR.YELLOW)
					char:mutate_category(game.mutation_category_id("FIEND"))
				end
			end
	
			--TODO:共通化したい
	
			if not(char.male) then
				if (monster:in_species(species_id("MALE")) or monster:in_species(species_id("HERM"))) then
	
					if (is_cubi(monster)) then
						char:set_value(CREAMPIE_SEED_TYPE, "FIEND")
					else
						char:set_value(CREAMPIE_SEED_TYPE, "HUMAN")
					end
	
					--判定に成功すれば孕む。失敗しても5日くらい溜まったままにする。
					if (preg_roll(char)) then
						char:add_effect(efftype_id("impregnated"), TimeDuration.from_turns(1), "num_bp", true)
					else
						char:add_effect(efftype_id("creampie"), TimeDuration.from_turns(72000))
					end
					
				end
			end
			--一時的に友好的に近づける。でないとrape loopに嵌ってしまう...
			--TODO:それでも複数に囲まれると死ぬまで嬲られるのをどうにかしたい
			monster.anger = monster.anger - 30  
			if monster.friendly ~= -1 then
                monster.friendly = -1
                monster:add_effect(efftype_id("pet"), TimeDuration.from_turns(1), "num_bp", true)
            end
            monster.morale = monster.morale - 30
			
	
			-- Add damage to torso as requested (for testing)
			local player_char = gapi.get_avatar()
			player_char:mod_part_hp_cur(game.bodypart_id("torso"), -5)
	
			--モンスターから"dominate"を外し、対象からも"gotwifed"のintensityを1つ下げる。
			monster:remove_effect(efftype_id("dominate"))
			target:add_effect(efftype_id("gotwifed"), TimeDuration.from_turns(-1), "num_bp", true)
	end
    local dialogue = matk_speech(monster, "WIFE_U", target)
    add_msg("<color_pink>" .. dialogue .. "</color>", H_COLOR.PINK)

	target:mod_moves(-10)
	monster:mod_moves(-100)
	return true
end

--[[ハート炎攻撃]]--
function matk_loveflame(monster)
	local max_range = 15		--特殊攻撃の最大射程


	--攻撃しようとしているターゲットを取得
	local target = get_attackable_target(monster, max_range)

	-- Check if target is nil OR false
	if not target then
		return false
	end

	--ここでモンスターに行動コストを追加。
	monster:mod_moves(-200)

	local tripoint_list = LoveFormula(target:get_pos_ms(), 15, 0.6)

	for key, value in pairs(tripoint_list) do
		game.map:add_field_at(value, gapi.field_type_id("fd_fire"), 10, TimeDuration.from_turns(10))
		--g:draw()
		--g:draw_ter(value)
	end

	gapi.add_msg(monster:disp_name(false, true).." casts a spell, setting the area around "..target:disp_name(false, true).." in flames!")

	return true
end

--[[露出攻撃。...攻撃？]]--
function matk_expose(monster)
    local max_range = 30     -- Special attack maximum range

    -- Get all nearby players
    local player_list = get_players()
    local target_list = {}
    local player_char = gapi.get_avatar()  -- Get the player character for visibility checks

    -- Calculate distances and build target list
    for key, value in pairs(player_list) do

        local monster_pos = monster:get_pos_ms()
        local target_pos = value:get_pos_ms()
        
        -- Calculate distance using vector components
        local dx = monster_pos.x - target_pos.x
        local dy = monster_pos.y - target_pos.y
        local dist = math.sqrt(dx * dx + dy * dy)

        -- Add target if within range
        if (dist <= max_range) then
            table.insert(target_list, value)
        end
    end

    -- If we have targets in range
    if (#target_list > 0) then
        -- Add action cost to monster
        monster:mod_moves(-500)

        -- Display message if player can see the monster
        if (player_char:sees(monster)) then
            local rnd = math.random(3)

            if (rnd == 1) then
                add_msg(monster:disp_name(false, true) .. " strips " .. pro(monster, "himself") .. " naked and begins showing off with " .. pro(monster, "his") .. " enticing bare body!", H_COLOR.PINK)
            elseif (rnd == 2) then
                add_msg(monster:disp_name(false, true) .. " keeps showcasing " .. pro(monster, "his") .. " goodies as " .. pro(monster, "he") .. " tempts the bystanders with " .. pro(monster, "his") .. " seductive voice!", H_COLOR.PINK)
            else
                add_msg(monster:disp_name(false, true) .. " reaches for " .. pro(monster, "his") .. " groin and raises " .. pro(monster, "his") .. " voice in a desperate moan!", H_COLOR.PINK)
            end
        end

        -- Apply effects to all targets that can see the monster
        for key, value in pairs(target_list) do
            if (value:sees(monster)) then
                gain_corrupt(value, 600)
                value:add_effect(efftype_id("lust"), TimeDuration.from_turns(24))
            end
        end
    end

    return true
end

--[[↓こっからは魔法系統↓]]--

--[[沈静ガス攻撃]]--
function magic_fire_circle(monster, target)

	local tripoint_list = LoveFormula(target:get_pos_ms(), 3, 0)
	for key, value in pairs(tripoint_list) do
		map:add_field(value, "relax_gas", 3, TimeDuration.from_turns(20))
	end

	if (ch:sees(monster:get_pos_ms())) then
		gapi.add_msg(monster:disp_name(false, true).." casts a spell, covering "..target:disp_name(false, true).." with a sweet-smelling gas!")
	end

	return true
end

--[[火の輪攻撃]]--
function magic_fire_circle(monster, target)

	local tripoint_list = LoveFormula(target:get_pos_ms(), 6, 0)
	for key, value in pairs(tripoint_list) do
		map:add_field(value, "fd_fire", 1, TimeDuration.from_turns(10))
	end

	if (ch:sees(monster:get_pos_ms())) then
		gapi.add_msg(monster:disp_name(false, true).." casts a spell as flames begin swirling around "..target:disp_name(false, true).."!")
	end

	return true
end


function magic_sleep(monster, target)

    local player_char = gapi.get_avatar()
    if (player_char:sees(monster)) then  -- Changed this line - now passing the monster, not its position
        gapi.add_msg(monster:disp_name(false, true).." points at "..target:disp_name(false, true).." with a curse!")
    end
    target:add_effect(efftype_id("magic_sleepy"), TimeDuration.from_turns(900))

	return true
end

--[[引き寄せ攻撃]]--
function magic_pull_close(monster, target)

	--引き寄せる場所の候補リストを取得。
	local locate_list = get_around_empty_locs(monster:get_pos_ms())
	if (#locate_list == 0) then
		--万が一引き寄せる場所が無い場合は何もしない。
		return
	end

	--場所の候補からランダムで1つ選択し、対象の位置を移動させる。
	local locale = locate_list[math.random(#locate_list)]
	target:setpos(locale)
	gapi.add_msg(ActorName(target, "teleport", "teleports").."!")


end

--[[魔法陣描き攻撃。魔法陣に限らずトラップ全般に使える？]]--
function magic_write_circle(monster, pos, str_id)

    local map = gapi.get_map()
    if not map then
        return false
    end

    -- Check if there's already a trap at this position
    local existing_trap = map:tr_at(pos)

    -- Add the trap using trap_set
    map:trap_set(pos, str_id)
    
    -- Verify the trap was placed
    local new_trap = map:tr_at(pos)

    -- Get player for visibility checks
    local player = gapi.get_avatar()
    if not player then
        return false
    end

    -- Handle visibility messages - only check if player can see the monster
    if player:sees(monster) then
        gapi.add_msg("<color_red>"..monster:disp_name(false, true).." draws a magic circle on the ground!</color>")
    else
        gapi.add_msg("<color_red>A magic circle appears on the ground!</color>")
    end

    return true
end


function spell_charge(monster)

    monster:add_effect(efftype_id("spell_charge"), TimeDuration.from_turns(EFF_SPELL_CHARGE_INT_FACTOR))

    local player_char = gapi.get_avatar()
    
    -- Check if player can see the monster directly (not its position)
    if (player_char:sees(monster)) then
        if (monster:has_effect(efftype_id("spell_charge"))) then
            gapi.add_msg(monster:disp_name(false, true).." is chanting a spell...")
        else
            gapi.add_msg(monster:disp_name(false, true).." begins chanting a spell.")
        end
    else
        gapi.add_msg("You hear someone whispering...")
    end
	return true
end


--[[魔法陣（召喚）の起動]]--
function magic_circle_summon(pos, monster_id_list)

    local map = gapi.get_map()
    if not map then
        return false
    end

    -- Get trap at position
    local trap_exists, trap_id = map:tr_at(pos)
    if not trap_exists then
        return false
    end

    
    -- Only proceed if it's our magic circle for summoning
    if trap_id == "tr_magic_circle_summon" then
        -- Check if the position is empty for monster spawning
        local creature = gapi.get_creature_at(pos)
        if creature then
            local player = gapi.get_avatar()
            -- Get any creature at the position to check visibility
            local pos_creature = gapi.get_creature_at(pos)
            if player and pos_creature and player:sees(pos_creature) then
                gapi.add_msg("The magic circle was about to summon someone, but was blocked by the obstacle.")
            end
            return false
        end

        -- Remove the magic circle trap
        map:trap_set(pos, "tr_null")

        -- Summon a random monster from the list
        local monster_id = monster_id_list[math.random(#monster_id_list)]
        local mon = map:spawn_monster(monster_id, pos)

        -- Check visibility and show message
        local player = gapi.get_avatar()
        -- After spawning, get the monster to check visibility
        local spawned_creature = gapi.get_creature_at(pos)
        if player and spawned_creature and player:sees(spawned_creature) then
            gapi.add_msg("The magic circle has summoned someone!")
        end

        -- Add movement cost to the summoned monster
        if mon then
            mon:mod_moves(-200)
        end

        return true
    end

    return false
end

--[[魔法陣（火炎）の起動]]--
function magic_circle_fire(pos, density, age)

    local map = gapi.get_map()
    if not map then
        return false
    end

    -- Get trap at position
    local trap_exists, trap_id = map:tr_at(pos)
    if not trap_exists then
        return false
    end

    
    -- Only proceed if it's our magic circle
    if trap_id == "tr_magic_circle" then
        -- Remove the magic circle trap
        map:trap_set(pos, "tr_null")

        -- Add the fire field
        map:add_field_at(pos, gapi.field_type_id("fd_fire"), density, TimeDuration.from_turns(age))

        -- Show message if player can see it
        local player = gapi.get_avatar()
        if player and player:sees(pos) then
            gapi.add_msg("The magic circle erupts with flames!")
        end
        
        return true
    end

    return false
end


--[[↓"どのモンスターが何の魔法をどのくらいの溜め・威力で使えるかを個別に設定する"↓]]--

--[[サキュバス・ソムノ]]--
function matk_magic_succubi_somnophilia(monster)
	local max_range = 20		--特殊攻撃の最大射程


	--攻撃しようとしているターゲットを取得
	local target = get_attackable_player(monster, max_range)

	if (target == nil) then
		return true
	end

	--ターゲットが既に効果に掛かっている、あるいは寝ているなら何もしない。
	if (target:has_effect(efftype_id("magic_sleepy")) or target:has_effect(efftype_id("sleep"))) then
		return true
	end

	local magic_sleep_cost = 3	--睡眠魔法の実行コスト

	--"spell_charge"のintensityを取得
	local intensity = monster:get_effect_int(efftype_id("spell_charge"))

	if (intensity >= magic_sleep_cost) then
		--intensityが規定値に到達していれば発動！
		magic_sleep(monster, target)
		monster:remove_effect(efftype_id("spell_charge"))

		monster:mod_moves(-500)

	else
		--足りなければ詠唱を続ける
		spell_charge(monster)
		monster:mod_moves(-150)
	end
	return true
end

--[[ダークウィッチ]]--
function matk_magic_dark_witch(monster)
	local max_range = 20		--特殊攻撃の最大射程


	--攻撃しようとしているターゲットを取得
	local target = get_attackable_player(monster, max_range)

	if (target == nil) then
		return true
	end

	local magic_fire_cost = 3	--魔法の実行コスト

	--"spell_charge"のintensityを取得
	local intensity = monster:get_effect_int(efftype_id("spell_charge"))

	if (intensity >= magic_fire_cost) then
		--intensityが規定値に到達していれば発動！
		magic_fire_circle(monster, target)
		monster:remove_effect(efftype_id("spell_charge"))

		monster:mod_moves(-300)

	else
		--足りなければ詠唱を続ける
		spell_charge(monster)
		monster:mod_moves(-150)
	end
	return true
end


--[[山羊頭の悪魔]]--
function matk_magic_goathead_demon(monster)
    local max_range = 10 --特殊攻撃の最大射程
    local magic_cost = 1 --魔法の実行コスト


    --攻撃しようとしているターゲットを取得
    local target = get_attackable_target(monster, max_range)

    if (target == false) then
        return true
    end

    --"spell_charge"のintensityを取得
    local intensity = monster:get_effect_int(efftype_id("spell_charge"))

    if (intensity >= magic_cost) then
        --intensityが規定値に到達していれば発動！

        if (math.random(4) == 1) then
            --周囲にある魔法陣（召喚）を起動する。
            local locs = get_around_locs(monster:get_pos_ms(), 0, 10)
            for key, value in pairs(locs) do
                magic_circle_summon(value, MON_ARCH_CUBI_LIST)
            end
        else
            --魔法陣（召喚）を設置する。
            local target_pos = target:get_pos_ms()
            local locate_list = get_around_empty_locs(target_pos)
            
            if #locate_list > 0 then
                local chosen_pos = locate_list[math.random(#locate_list)]
                local result = magic_write_circle(monster, chosen_pos, "tr_magic_circle_summon")
            else
            end
        end

        monster:remove_effect(efftype_id("spell_charge"))
        monster:mod_moves(-300)

    else
        --足りなければ詠唱を続ける
        spell_charge(monster)
        monster:mod_moves(-150)
    end
    return true
end
