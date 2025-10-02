--[[山羊頭の悪魔のイベント]]--
function event_goathead_demon(monster)
	gdebug.log_info("event_goathead_demon 1")
	if not monster then
		gdebug.log_info("Error: monster is nil in event_goathead_demon")
		return
	end
	-- Add logging before the potentially crashing line
	gdebug.log_info("Monster object exists. Type: " .. type(monster))
	if monster and monster.disp_name then
		gdebug.log_info("Monster name: " .. monster:disp_name(false, true))
	end
	-- Check if attack_target method exists
	if monster and type(monster.attack_target) == "function" then
		gdebug.log_info("attack_target method exists. Calling it...")
	else
		gdebug.log_info("attack_target method does NOT exist or is not a function.")
		return -- Prevent crash if method missing
	end
	-- Call attack_target and store result
	local target_result = monster:attack_target()
	gdebug.log_info("attack_target called. Result type: " .. type(target_result))

	-- Assign result to someone (original variable name)
	local someone = target_result
	gdebug.log_info("event_goathead_demon 2") -- Moved this log down slightly

	--相手がいなければ何もしない。
	gdebug.log_info("Before if (someone == nil) check.") -- Add log
	if (someone == nil) then
		gdebug.log_info("Inside if (someone == nil) block. Preparing to log nil case.") -- Add log
		gdebug.log_info("No target found (someone is nil).") -- Existing log
		gdebug.log_info("Preparing to return from nil case.") -- Add log
		return false -- Try returning false instead of just return
	end
	gdebug.log_info("After if (someone == nil) check (target was not nil).") -- Add log (should not be reached if nil)
	gdebug.log_info("event_goathead_demon 3")
	-- Get player character
	local player_char = gapi.get_avatar()
	if not player_char then
		gdebug.log_info("Error: Could not get player character")
		return
	end
	gdebug.log_info("event_goathead_demon 4")
	-- Get monster position
	local monster_pos = monster:get_pos_ms()
	if not monster_pos then
		gdebug.log_info("Error: Could not get monster position")
		return false
	end

	gdebug.log_info("Monster position: x=" .. monster_pos.x .. ", y=" .. monster_pos.y .. ", z=" .. monster_pos.z)

	--姿がプレイヤーに見えていなければ何もしない。相手に姿を見せてから名乗りをあげないとただの変な奴だし。
	if not(player_char:sees(monster)) then
		return false
	end

	--イベント発生用の特殊攻撃を無効化する。
	monster:disable_special("EVENT_GOATHEAD_DEMON")

	--TALK
	if (player_char:get_value("EVENT_GOATHEAD_DEMON") == "met") then
		--会ったフラグがある場合のセリフ。激おこ。
		--the last part of the sentence would be something like: "your death alone will not satisfy me, I will have you burned/tortured in the deepest parts of hell forever!"
		--but I used the more concise variant, which is also a reference
		gapi.add_msg("\"...The despicable one! How long do you plan to stand in our way before you're satisfied?!\r\nMy patience with you is wearing thin... I will never forgive you!\r\nDeath will not be your end, your soul will burn in hell forever!\"")
	else
		--会ったフラグが無い場合のセリフ。
		gapi.add_msg("\"Would you look at that... I knew there was something going on, but to think it's just some irrelevant human snooping around.\r\nA would-be hero or just someone led by the curiosity? In either case, it doesn't change the fact of your foolishness.\"")
		gapi.add_msg("\"This Sabbath is an important event for us, Demons, as we take over the earth.\r\nI don't know who you are nor I care. But I can't have you disturb us.\r\nYou will meet your end here by my hand.\"")

		if (player_char.male) then
			gapi.add_msg("\"But don't worry. After I take your soul, I will reincarnate you as my Demon underling!\r\nHaaa-ha-ha-ha!\"")
		else
			gapi.add_msg("\"But now that I take a closer look, you appear to be a fine, able-bodied woman.\r\nVery well, once I take your soul, I will offer you as a sacrifice for my Sabbath as much as I please!\r\nHaaa-ha-ha-ha!\"")
		end

		--会ったフラグを立てる。
		player_char:set_value("EVENT_GOATHEAD_DEMON", "met")
	end

	--周囲にある魔法陣を起動する。
	local locs = get_around_locs(monster_pos, 0, 10)
	gdebug.log_info("Checking locations around monster:")
	if locs then
		for key, value in pairs(locs) do
			gdebug.log_info("Checking location: x=" .. value.x .. ", y=" .. value.y .. ", z=" .. value.z)
			magic_circle_fire(value, 3, 30)
			magic_circle_summon(value, MON_ARCH_CUBI_LIST)
		end
	else
		gdebug.log_info("No locations found around monster")
	end

	monster:mod_moves(-100)
	return true
end

--[[NPC"demonbeing_schoolgirl"を呼び出すイベント]]--
--[[
	NOTE:NPCを配置する場合、そのNPCにユニーク名称を付けなければ性別を固定することができない。
	しかしそうすると同一人物が複数存在する事になってしまう...そのため、\"その人物に会った事があるかあるかどうか\"をフラグとして管理し、
	会っていない場合はNPCを生成、既に会っている場合はモンスターを生成する仕様にする。
]]--
function event_demonbeing_schoolgirl(monster)
	-- Check if monster is nil
	if not monster then
		gdebug.log_info("Error: monster is nil in event_demonbeing_schoolgirl")
		return false
	end

	-- Get monster position using get_pos_ms() instead of pos()
	local tripoint = monster:get_pos_ms()
	if not tripoint then
		gdebug.log_info("Error: Could not get monster position")
		return false
	end

	-- Get player character
	local player_char = gapi.get_avatar()
	if not player_char then
		gdebug.log_info("Error: Could not get player character")
		return false
	end

	-- Get player position
	local player_pos = player_char:get_pos_ms()
	if not player_pos then
		gdebug.log_info("Error: Could not get player position")
		return false
	end

	-- Calculate distance between monster and player using Euclidean distance
	local dx = tripoint.x - player_pos.x
	local dy = tripoint.y - player_pos.y
	local dist = math.floor(math.sqrt(dx * dx + dy * dy))
	
	if (dist > 10) then
		gdebug.log_info("Out of range.")
		return false
	end

	-- Get map instance and remove the dummy monster
	local map = gapi.get_map()
	map:remove_monster(monster)

	if (player_char:get_value("EVENT_DEMONBEING_SCHOOLGIRL") == "met") then
		-- Already met - create monster using spawn_monster
		map:spawn_monster("mon_corrupted_schoolgirl", tripoint)
	else
		-- First meeting - create NPC using place_npc
		map:place_npc(tripoint.x, tripoint.y, "demonbeing_schoolgirl")
		
		-- Use a hook to apply genetics after 1 turn
		gapi.add_on_every_x_hook(TimeDuration.from_turns(1), function()
			-- Use tripoint which is an upvalue
			local npc = gapi.get_npc_at(game.tripoint(tripoint.x, tripoint.y, tripoint.z)) 
			
			-- Check if NPC exists and hasn't had genetics applied yet
			if npc and npc:get_value("genetics_applied") ~= "yes" then 
				gdebug.log_info("Applying genetics via hook to Schoolgirl: " .. npc:disp_name(false, true))
				if _G.apply_genetics then -- Use _G scope explicitly
					_G.apply_genetics(npc, false) -- Schoolgirls are always female (is_male = false)
				else
					gdebug.log_error("apply_genetics function not found in schoolgirl hook!")
				end
				return false -- Remove hook after execution
			elseif npc then
				gdebug.log_info("Hook check: Schoolgirl genetics already applied (value='" .. (npc:get_value("genetics_applied") or "nil") .. "') for: " .. npc:disp_name(false, true))
				return false -- Remove hook if already applied
			else
				gdebug.log_info("Schoolgirl NPC not found at hook execution time.")
				return false -- Remove hook if NPC disappeared
			end
		end)

		-- Set met flag
		player_char:set_value("EVENT_DEMONBEING_SCHOOLGIRL", "met")
	end

	return true
end
