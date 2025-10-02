--[[translation-related functions]]--
local trait_id = game.trait_id
--[[test/debug]]--
function testPro()
	local selected_point = pointAt()
	
	if (selected_point == nil) then
		return
	end
	
	local obj = g:critter_at(selected_point)
	if (obj:is_monster()) then
		obj = game.get_monster_at(selected_point)
	end
	
	print(ActorName(obj, "'s"))
	print(ActorName(obj, "break", "breaks"))
	print(YouWord(obj, "your", "their"))
	print(pro(obj, "he"))
	print(pro(obj, "his"))
	print(pro(obj, "him"))
	print(pro(obj, "hers"))
	print(pro(obj, "himself"))

	add_msg(ActorName(obj, "'s"), H_COLOR.PINK)
	add_msg(YouWord(obj, "your", "their"), H_COLOR.PINK)
	add_msg(ActorName(obj, "break", "breaks"), H_COLOR.PINK)
	add_msg(pro(obj, "he"), H_COLOR.PINK)
	add_msg(pro(obj, "his"), H_COLOR.PINK)
	add_msg(pro(obj, "him"), H_COLOR.PINK)
	add_msg(pro(obj, "hers"), H_COLOR.PINK)
	add_msg(pro(obj, "himself"), H_COLOR.PINK)
end

--[[
function t()
	center = ch:pos()
	for i=-1,1 do
		for j=-1,1 do
			target = tripoint(center.x + i, center.y + j, center.z)
			m = game.get_monster_at(target)
			if m ~= nil then
				print(m:disp_name( false, true ))
				mtype = m.type
				print(mtype.hp)
				print(mtype:nname())
				if (mtype:in_species(species_id("FEMALE"))) then
					print("f")
				else
					print("m")
				end

				if (mtype:has_flag("MF_DOGFOOD")) then
					print("doggo")
				end
				if (mtype:has_flag("MF_CATFOOD")) then
					print("catto")
				end
			end
		end
	end
end
]]--

-- pronoun system because english --
function _G.pro(obj, pronoun)
	local objPlayer = obj:is_avatar()
	local objMale = getGender(obj) --custom function because monsters are also subjected to this
	
    if (pronoun == "he") then
		if (objPlayer) then
			return "you"
		else
			return (objMale and pronoun or "she")
		end
    end
	if (pronoun == "his") then
		if (objPlayer) then
			return "your"
		else
			return (objMale and pronoun or "her")
		end
    end
	if (pronoun == "him") then
		if (objPlayer) then
			return "you"
		else
			return (objMale and pronoun or "her")
		end
    end
	if (pronoun == "hers") then
		if (objPlayer) then
			return "yours"
		else
			return (objMale and "his" or pronoun)
		end
    end
	if (pronoun == "himself") then
		if (objPlayer) then
			return "yourself"
		else
			return (objMale and pronoun or "herself")
		end
    end
	
	return add_msg("*Pronoun error!*", H_COLOR.RED)
end

function _G.ActorName(obj, youWord, themWord, use_possessive)
    if (themWord == nil) then --in case second args is skipped to not cause an exception
        themWord = youWord
    end
    
    -- Convert parameters to strings if they're not nil
    if youWord ~= nil then
        youWord = tostring(youWord)
    end
    if themWord ~= nil then
        themWord = tostring(themWord)
    end
    
    local out = obj:disp_name(false, false) --set actor name
    local word = YouWord(obj, youWord, themWord) --set action word for actor
    
    if (youWord == "'s") then --special case
        if (obj:is_avatar()) then
            out = "your"
            word = nil
        else
            return out..word
        end
    end
    
    if word then
        return out.." "..word
    else
        return out
    end
end

function _G.YouWord(obj, youWord, themWord)
	return (obj:is_avatar() and youWord or themWord)
end

--create speech lines during super fun time
--DOESN'T WORK WITH MONSTERS REEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
function _G.ActorSay(topic, partner, player_char)
    -- With this function and say instruction we can use json snippets
    if topic == "<fun_stuff_accept>" or topic == "<fun_stuff_shy>" then -- exceptions
        if partner:has_trait(trait_id("VIRGIN")) then -- Special cases for chaste ones
            if getGender(partner) then -- Use function just in case it's a monster
                topic = "<fun_stuff_partner_mvirgin>"
            else
                topic = "<fun_stuff_partner_fvirgin>"
            end
        elseif player_char and player_char:has_trait(trait_id("VIRGIN")) then
            -- Use the passed player_char instead of the global ch
            if player_char.male then
                topic = "<fun_stuff_player_mvirgin>"
            else
                topic = "<fun_stuff_player_fvirgin>"
            end
        end
    end
    
    -- Return the result of partner:say() with the topic
    return partner:say(topic)
end


function _G.getGender(obj)
	gdebug.log_info("species availability"..tostring(species_id))
    if obj:is_monster() then
        -- Create proper species_id objects using game.species_id
        if obj:in_species(species_id("FEMALE")) then
            return false
        elseif obj:in_species(species_id("MALE")) then  
            return true
        elseif obj:in_species(species_id("HERM")) then
            return false
        else
            return true -- default case
        end
    else
        return obj.male -- for non-monsters
    end
end

function _G.sameSex(first, second, sex)
	if sex == "FEMALE" then
		return ( getGender(first) == false and getGender(second) == false )
	else
		return ( getGender(first) == getGender(second) )
	end
end