sgs.ai_skill_choice.RevealGeneral = function(self, choices)
	
	if askForShowGeneral(self, choices) == "yes" then return "yes" end
	
	local anjiang = 0
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if player:getGeneralName() == "anjiang" then
			anjiang = anjiang + 1
		end
	end
	if math.random() > (anjiang + 1)/(self.room:alivePlayerCount() + 1) then
		return "yes"
	else
		return "no"
	end
end

function askForShowGeneral(self, choices)
	
	local event = self.player:getTag("event"):toInt()
	local data = self.player:getTag("event_data")
	local generals = self.player:getTag("roles"):toString():split("+")
	local players = {}
	for _, general in ipairs(generals) do
		local player = sgs.ServerPlayer(self.room)
		player:setGeneral(sgs.Sanguosha:getGeneral(general))
		table.insert(players, player)
	end
	
	if event == sgs.DamageInflicted then
		local damage = data:toDamage()
		for _, player in ipairs(players) do
			if damage and self:hasSkills(sgs.masochism_skill .. "|zhichi|zhiyu|fenyong", player) and not self:isFriend(damage.from, damage.to) then return "yes" end
			if damage and damage.damage > self.player:getHp() + self:getAllPeachNum() then return "yes" end
		end
	elseif event == sgs.CardEffected then
		local effect = data:toCardEffect()
		for _, player in ipairs(players) do
			if self.room:isProhibited(effect.from, player, effect.card) and self:isEnemy(effect.from, effect.to) then return "yes" end
			if self:hasSkills("xiangle", player) and effect.card:isKindOf("Slash") then return "yes" end
			if self:hasSkills("jiang", player) and ((effect.card:isKindOf("Slash") and effect.card:isRed()) or effect.card:isKindOf("Duel")) then return "yes" end
			if self:hasSkills("tuntian", player) then return "yes" end
		end
	end

	if self.room:alivePlayerCount() <= 3 then return "yes" end

	if sgs.getValue(self.player) < 6 then return "no" end

	local skills_to_show = "bazhen|yizhong|zaiqi|feiying|buqu|kuanggu|guanxing|luoshen|tuxi|zhiheng|qiaobian|longdan|liuli|longhun|shelie|luoying|anxian|yicong|wushuang|jueqing|niepan"

	for _, player in ipairs(players) do
		if self:hasSkills(skills_to_show, player) then return "yes" end
	end

	if self.player:getDefensiveHorse() and self.player:getArmor() and not self:isWeak() then return "yes" end
	
end


