--[[
	技能：缓释
	描述：（3V3局）在一名己方角色的判定牌生效前，你可以打出一张牌代替之。
		（身份局）在一名角色的判定牌生效前，你可以令其选择是否由你打出一张牌代替之。
]]--
sgs.ai_skill_cardask["@huanshi-card"] = function(self, data) --询问缓释改判卡牌
	local judge = data:toJudge()

	local cards = sgs.QList2Table(self.player:getCards("he"))
	local card_id = self:getRetrialCardId(cards, judge)
	local card = sgs.Sanguosha:getCard(card_id)
	if card_id ~= -1 then
		return "@HuanshiCard[" .. card:getSuitString() .. ":" .. card:getNumberString() .. "]=" .. card_id
	end

	return "."
end

sgs.ai_skill_invoke.huanshi = function(self, data) --询问诸葛瑾是否发动缓释（为什么data是RecoverStruct类型的？）
	if self.player:isNude() then --裸奔时不能发动技能
		return false
	else
		local judge = self.room:getTag("JudgeInformation"):toJudge()
		if self:needRetrial(judge) then
			return true
		end
		--考虑明哲换牌（忽略换装备牌，只考虑换手牌）
		local cards = self.player:getCards("h") 
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		for _,c in pairs(cards) do
			if c:isRed() then
				if self:getKeepValue(c) < 1.5 then
					return true
				end
			end
		end
	end
	return false
end

sgs.ai_event_callback[sgs.AskForRetrial].huanshi = function(self, player, data)
	self.room:setTag("JudgeInformation", data)
end

sgs.ai_event_callback[sgs.FinishJudge].huanshi = function(self, player, data)
	self.room:removeTag("JudgeInformation")
end

sgs.ai_skill_choice.huanshi = function(self, choices) --判定者做选择，是否同意诸葛瑾发动缓释
	local zhugejin = self.room:findPlayerBySkillName("huanshi")
	if self:objectiveLevel(zhugejin) >= 0 then return "no" end
	return "yes"
end

sgs.ai_skill_invoke.hongyuan = function(self, data)
	return 	self.player:getHandcardNum() > 0
end
--[[
	技能：明哲
	描述：你的回合外，当你因使用、打出或弃置而失去一张红色牌时，你可以摸一张牌。 
]]--
sgs.ai_skill_invoke.mingzhe = true

sgs.ai_suit_priority.mingzhe=function(self)	
	return self.player:getPhase()==sgs.Player_NotActive and "diamond|heart|club|spade" or "club|spade|diamond|heart"
end
--[[
	技能：弘援
	描述：（3V3局）摸牌阶段，你可以少摸一张牌，令其他己方角色各摸一张牌。
		（身份局）摸牌阶段，你可以少摸一张牌，令一至两名其他角色各摸一张牌。
]]--
sgs.ai_skill_use["@@hongyuan"] = function(self, prompt)
	self:sort(self.friends_noself, "handcard")
	local first_index, second_index
	for i=1, #self.friends_noself do
		if self:needKongcheng(self.friends_noself[i]) and self.friends_noself[i]:getHandcardNum() == 0 
			or self.friends_noself[i]:hasSkill("manjuan") then
		else
			if not first_index then
				first_index = i
			else
				second_index = i
			end
		end
		if second_index then break end
	end

	if first_index and not second_index then
		local others = self.room:getOtherPlayers(self.player)
		for _, other in sgs.qlist(others) do
			if (not self:isFriend(other) and (self:needKongcheng(other) and others:getHandcardNum() == 0 or other:hasSkill("manjuan"))) and
				self.friends_noself[first_index]:objectName() ~= other:objectName() then
				return ("@HongyuanCard=.->%s+%s"):format(self.friends_noself[first_index]:objectName(), other:objectName())
			end
		end
	end

	if not second_index then return "." end

	self:log(self.friends_noself[first_index]:getGeneralName() .. "+" .. self.friends_noself[second_index]:getGeneralName())
	local first = self.friends_noself[first_index]:objectName()
	local second = self.friends_noself[second_index]:objectName()
	return ("@HongyuanCard=.->%s+%s"):format(first, second)
end

sgs.ai_card_intention.HongyuanCard = function(card, from, tos, source)
	for _, to in ipairs(tos) do
		sgs.updateIntention(from, to, -80)
	end
end

sgs.ai_suit_priority.mingzhe=function(self)	
	return self.player:getPhase()==sgs.Player_NotActive and "diamond|heart|club|spade" or "club|spade|diamond|heart"
end