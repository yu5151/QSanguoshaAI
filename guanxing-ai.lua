sgs.ai_judgestring =
{
	indulgence = "heart",
	diamond = "heart",
	supply_shortage = "club",
	spade = "club",
	club = "club",
	lightning = "spade",
}

local function getIdToCard(self, cards)
	local tocard = {}
	for _, card_id in ipairs(cards) do
		local card = sgs.Sanguosha:getCard(card_id)
		table.insert(tocard, card)
	end
	return tocard
end

local function getBackToId(self, cards)
	local cards_id = {}
	for _, card in ipairs(cards) do
		table.insert(cards_id, card:getEffectiveId())
	end
	return cards_id
end

--for test--
local function ShowGuanxingResult(self, up, bottom)
	self.room:writeToConsole("----GuanxingResult----")
	self.room:writeToConsole(string.format("up:%d", #up))
	if #up > 0 then
		for _,card in pairs(up) do
			self.room:writeToConsole(string.format("(%d)%s[%s%d]", card:getId(), card:getClassName(), card:getSuitString(), card:getNumber()))
		end
	end
	self.room:writeToConsole(string.format("down:%d", #bottom))
	if #bottom > 0 then
		for _,card in pairs(bottom) do
			self.room:writeToConsole(string.format("(%d)%s[%s%d]", card:getId(), card:getClassName(), card:getSuitString(), card:getNumber()))
		end
	end
	self.room:writeToConsole("----GuanxingEnd----")
end
--end--
local function getOwnCards(self, up, bottom, next_judge, drawCards)
	self:sortByUseValue(bottom)
	local has_slash = self:getCardsNum("Slash") > 0
	local hasNext = drawCards == 0
	local nosfuhun1, nosfuhun2
	local shuangxiong
	local has_big
	for index, gcard in ipairs(bottom) do
		if drawCards == 0 then break end
		if index - 1 >= drawCards then break end
		if #next_judge > 0 then
			table.insert(up, gcard)
			table.remove(bottom, index)
			hasNext = true
		else
			if self.player:hasSkill("nosfuhun") then
				if not nosfuhun1 and gcard:isRed() then
					table.insert(up, gcard)
					table.remove(bottom, index)
					nosfuhun1 = true
				end
				if not nosfuhun2 and gcard:isBlack() and isCard("Slash", gcard, self.player) then
					table.insert(up, gcard)
					table.remove(bottom, index)
					nosfuhun2 = true
				end
				if not nosfuhun2 and gcard:isBlack() and gcard:getTypeId() == sgs.Card_TypeEquip then
					table.insert(up, gcard)
					table.remove(bottom, index)
					nosfuhun2 = true
				end
				if not nosfuhun2 and gcard:isBlack() then
					table.insert(up, gcard)
					table.remove(bottom, index)
					nosfuhun2 = true
				end
			elseif self.player:hasSkill("shuangxiong") and self.player:getHandcardNum() >= 3 then
				local rednum, blacknum = 0, 0
				local cards = sgs.QList2Table(self.player:getHandcards())
				for _, card in ipairs(cards) do
					if card:isRed() then rednum = rednum + 1 else blacknum = blacknum + 1 end
				end
				if not shuangxiong and ((rednum > blacknum and gcard:isBlack()) or (blacknum > rednum and gcard:isRed()))
					and (isCard("Slash", gcard, self.player) or isCard("Duel", gcard, self.player)) then
					table.insert(up, gcard)
					table.remove(bottom, index)
					shuangxiong = true
				end
				if not shuangxiong and ((rednum > blacknum and gcard:isBlack()) or (blacknum > rednum and gcard:isRed())) then
					table.insert(up, gcard)
					table.remove(bottom, index)
					shuangxiong = true
				end
			elseif self.player:hasSkills("xianzhen|tianyi|dahe") then
				local maxcard = self:getMaxCard(self.player)
				has_big = maxcard and maxcard:getNumber() > 10
				if not has_big and gcard:getNumber() > 10 then
					table.insert(up, gcard)
					table.remove(bottom, index)
					has_big = true
				end
				if isCard("Slash", gcard, self.player) then
					table.insert(up, gcard)
					table.remove(bottom, index)
				end
			else
				for _, skill in sgs.qlist(self.player:getVisibleSkillList(true)) do
					local callback = sgs.ai_cardneed[skill:objectName()]
						if type(callback) == "function" and sgs.ai_cardneed[skill:objectName()](self.player, gcard, self) then
						table.insert(up, gcard)
						table.remove(bottom, index)
						continue
					end
				end
				if has_slash and not gcard:isKindOf("Slash") then
					table.insert(up, gcard)
					table.remove(bottom, index)
				elseif not has_slash and isCard("Slash", gcard, self.player) then
					table.insert(up, gcard)
					table.remove(bottom, index)
					has_slash = true
				end
			end
		end
	end

	if hasNext then
		for _, gcard in ipairs(next_judge) do
			table.insert(up, gcard)
		end
	end

	return up, bottom
end

local function GuanXing(self, cards)
	local up, bottom = {}, {}
	local has_lightning, has_judged
	local judged_list = {}
	local willSkipDrawPhase

	bottom = getIdToCard(self, cards)
	self:sortByUseValue(bottom, true)

	local judge = sgs.QList2Table(self.player:getJudgingArea())
	judge = sgs.reverse(judge)

	if not self.player:containsTrick("YanxiaoCard") then
		for judge_count, need_judge in ipairs(judge) do
			judged_list[judge_count] = 0
			if need_judge:isKindOf("Indulgence") and self.player:isSkipped(sgs.Player_Play) then continue end
			if need_judge:isKindOf("SupplyShortage") then
				willSkipDrawPhase = true
				if self.player:isSkipped(sgs.Player_Draw) then continue end
			end
			local lightning_flag = need_judge:isKindOf("Lightning")
			local judge_str = sgs.ai_judgestring[need_judge:objectName()]
			if not judge_str then
				self.room:writeToConsole(debug.traceback())
				judge_str = sgs.ai_judgestring[need_judge:getSuitString()]
			end

			for index, for_judge in ipairs(bottom) do
				if lightning_flag and not (for_judge:getNumber() >= 2 and for_judge:getNumber() <= 9 and for_judge:getSuit() == sgs.Card_Spade) then
					has_lightning = need_judge
				end
				if (judge_str == for_judge:getSuitString() and not lightning_flag)
					or (lightning_flag and not (for_judge:getNumber() >= 2 and for_judge:getNumber() <= 9 and for_judge:getSuit() == sgs.Card_Spade)) then
					table.insert(up, for_judge)
					table.remove(bottom, index)
					judged_list[judge_count] = 1
					has_judged = true
					if need_judge:isKindOf("SupplyShortage") then willSkipDrawPhase = false end
					break
				end
			end
		end

		for index = 1, #judged_list do
			if judged_list[index] == 0 then
				table.insert(up, index, table.remove(bottom, 1))
			end
		end

	end

	local conflict, AI_doNotInvoke_luoshen
	for _, skill in sgs.qlist(self.player:getVisibleSkillList()) do
		local sname = skill:objectName()
		if sname == "guanxing" or sname == "super_guanxing" then conflict = true continue end
		if conflict then
			if sname == "tuqi" then
				if self.player:getPile("retinue"):length() > 0 and self.player:getPile("retinue"):length() <= 2 then
					if #bottom > 0 then
						table.insert(up, 1, table.remove(bottom))
					else
						table.insert(up, 1, table.remove(up))
					end
				end
			elseif sname == "luoshen" then
				self.player:setFlags("AI_Luoshen_Conflict_With_Guanxing")
				if #bottom == 0 then
					self.player:setFlags("AI_doNotInvoke_luoshen")
				else
					local count = 0
					if not has_judged then up = {} end
					for i = 1, #bottom do
						if bottom[i - count]:isBlack() then
							table.insert(up, 1, bottom[i - count])
							table.remove(bottom, i - count)
							count = count + 1
						end
					end
					if count == 0 then
						AI_doNotInvoke_luoshen = true
					else self.player:setMark("AI_loushen_times", count)
					end
				end
			else
				local x = 0
				local reverse
				if sname == "zuixiang" and self.player:getMark("@sleep") > 0 then
					x = 3
				elseif sname == "guixiu" and sgs.ai_skill_invoke.guixiu then
					x = 2
				elseif sname == "qianxi" and sgs.ai_skill_invoke.qianxi then
					x = 1
					reverse = true
				elseif sname == "yinghun" then
					sgs.ai_skill_playerchosen.yinghun(self)
					if self.yinghunchoice == "dxt1" then x = self.player:getLostHp()
					elseif self.yinghunchoice == "d1tx" then x = 1
					end
					reverse = true
				end
				if x > 0 then
					if #bottom < x then
						self.player:setFlags("AI_doNotInvoke_" .. sname)
					else
						for i = 1, x do
							local index = reverse and 1 or #bottom
							table.insert(up, 1, table.remove(bottom, index))
						end
					end
				end
			end
		end
	end

	local drawCards = self:ImitateResult_DrawNCards(self.player, self.player:getVisibleSkillList(true))
	if willSkipDrawPhase then drawCards = 0 end

	if #bottom > 0 and drawCards > 0 then
		if self.player:hasSkill("zhaolie") then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if self.player:inMyAttackRange(p) then targets:append(p) end
			end
			if target:length() > 0 and sgs.ai_skill_playerchosen.zhaolie(self, targets) then
				local drawCount = drawCards - 1
				local basic = {}
				local peach = {}
				local not_basic = {}
				for _, gcard in ipairs(bottom) do
					if gcard:isKindOf("Peach") then
						table.insert(peach, gcard)
					elseif gcard:isKindOf("BasicCard") then
						table.insert(basic, gcard)
					else
						table.insert(not_basic, gcard)
					end
				end
				if #not_basic > 0 then
					bottom = {}
					for i = 1, drawCount, 1 do
						if self:isWeak() and #peach > 0 then
							table.insert(up, peach[1])
							table.remove(peach, 1)
						elseif #basic > 0 then
							table.insert(up, basic[1])
							table.remove(basic, 1)
						elseif #not_basic > 0 then
							table.insert(up, not_basic[1])
							table.remove(not_basic, 1)
						end
					end
					for index, card in ipairs(not_basic) do
						table.insert(up, card)
					end
					if #peach > 0 then
						for _, peach in ipairs(peach) do
							table.insert(bottom, peach)
						end
					end
					if #basic > 0 then
						for _, card in ipairs(basic) do
							table.insert(bottom, card)
						end
					end
					up = getBackToId(self, up)
					bottom = getBackToId(self, bottom)
					if AI_doNotInvoke_luoshen then self.player:setFlags("AI_doNotInvoke_luoshen") end
					return up, bottom
				else
					self.player:setFlags("AI_doNotInvoke_zhaolie")
				end
			end
		end
	end

	local pos = 1
	local luoshen_flag = false
	local next_judge = {}
	local next_player = self.player:getNextAlive()
	judge = sgs.QList2Table(next_player:getJudgingArea())
	judge = sgs.reverse(judge)
	if has_lightning then table.insert(judge, 1, has_lightning) end

	has_judged = false
	judged_list = {}

	while (#bottom > drawCards) do
		local lightning_flag = false
		if pos > #judge then break end
		local judge_str = sgs.ai_judgestring[judge[pos]:objectName()] or sgs.ai_judgestring[judge[pos]:getSuitString()]

		for index, for_judge in ipairs(bottom) do
			if self:isFriend(next_player) then
				if next_player:hasSkill("luoshen") then
					if for_judge:isBlack() then
						table.insert(next_judge, for_judge)
						table.remove(bottom, index)
						has_judged = true
						judged_list[pos] = 1
						break
					end
				elseif judge_str == for_judge:getSuitString() and not lightning_flag then
					table.insert(next_judge, for_judge)
					table.remove(bottom, index)
					has_judged = true
					judged_list[pos] = 1
					break
				elseif lightning_flag and not (for_judge:getNumber() >= 2 and for_judge:getNumber() <= 9 and for_judge:getSuit() == sgs.Card_Spade) then
					table.insert(next_judge, for_judge)
					table.remove(bottom, index)
					has_judged = true
					judged_list[pos] = 1
					break
				end
			else
				if next_player:hasSkill("luoshen") and for_judge:isRed() and not luoshen_flag then
					table.insert(next_judge, for_judge)
					table.remove(bottom, index)
					has_judged = true
					judged_list[pos] = 1
					luoshen_flag = true
					break
				elseif (judge_str == for_judge:getSuitString() and judge_str == "spade" and lightning_flag)
					or judge_str ~= for_judge:getSuitString() then
					table.insert(next_judge, for_judge)
					table.remove(bottom, index)
					has_judged = true
					judged_list[pos] = 1
					break
				end
			end
		end
		if not judged_list[pos] then judged_list[pos] = 0 end
		pos = pos + 1
	end

	if has_judged then
		for index = 1, #judged_list do
			if judged_list[index] == 0 then
				table.insert(next_judge, index, table.remove(bottom))
			end
		end
	end

	up, bottom = getOwnCards(self, up, bottom, next_judge, drawCards)

	up = getBackToId(self, up)
	bottom = getBackToId(self, bottom)
	if #up > 0 and AI_doNotInvoke_luoshen then self.player:setFlags("AI_doNotInvoke_luoshen") end
	return up, bottom
end

local function XinZhan(self, cards)
	local up, bottom = {}, {}
	local judged_list = {}
	local hasJudge = false
	local next_player = self.player:getNextAlive()
	local judge = next_player:getCards("j")
	judge = sgs.QList2Table(judge)
	judge = sgs.reverse(judge)

	bottom = getIdToCard(self, cards)
	for judge_count, need_judge in ipairs(judge) do
		local index = 1
		local lightning_flag = false
		local judge_str = sgs.ai_judgestring[need_judge:objectName()] or sgs.ai_judgestring[need_judge:getSuitString()]

		for _, for_judge in ipairs(bottom) do
			if judge_str == "spade" and not lightning_flag then
				has_lightning = need_judge
				if for_judge:getNumber() >= 2 and for_judge:getNumber() <= 9 then lightning_flag = true end
			end
			if self:isFriend(next_player) then
				if judge_str == for_judge:getSuitString() then
					if not lightning_flag then
						table.insert(up, for_judge)
						table.remove(bottom, index)
						judged_list[judge_count] = 1
						has_judged = true
						break
					end
				end
			else
				if judge_str ~= for_judge:getSuitString() or
					(judge_str == for_judge:getSuitString() and judge_str == "spade" and lightning_flag) then
					table.insert(up, for_judge)
					table.remove(bottom, index)
					judged_list[judge_count] = 1
					has_judged = true
				end
			end
			index = index + 1
		end
		if not judged_list[judge_count] then judged_list[judge_count] = 0 end
	end

	if has_judged then
		for index=1, #judged_list do
			if judged_list[index] == 0 then
				table.insert(up, index, table.remove(bottom))
			end
		end
	end

	while #bottom ~= 0 do
		table.insert(up, table.remove(bottom))
	end

	up = getBackToId(self, up)
	return up, {}
end

function SmartAI:askForGuanxing(cards, guanxing_type)
	--KOF模式--
	if guanxing_type ~= sgs.Room_GuanxingDownOnly then
		local func = Tactic("guanxing", self, guanxing_type == sgs.Room_GuanxingUpOnly)
		if func then return func(self, cards) end
	end
	--身份局--
	if guanxing_type == sgs.Room_GuanxingBothSides then return GuanXing(self, cards)
	elseif guanxing_type == sgs.Room_GuanxingUpOnly then return XinZhan(self, cards)
	elseif guanxing_type == sgs.Room_GuanxingDownOnly then return {}, cards
	end
	return cards, {}
end