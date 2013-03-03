sgs.ai_skill_invoke.newqianxi = function(self, data)
 	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:distanceTo(p) == 1 and self:isEnemy(p) and not p:isKongcheng() then
			return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen.newqianxi = function(self, targets)
	local enemies = {}
	for _, target in sgs.qlist(targets) do
		if self:isEnemy(target) then
			table.insert(enemies, target)
		end
	end
	if #enemies > 0 then
		self:sort(enemies, "defense")
		if self:getCardsNum("Jink", enemies[1]) >= 1 or #enemies == 1 or
		(self:hasHeavySlashDamage(self.player, nil, enemies[1]) and enemies[1]:getHp() <= 2 or enemies[1]:getHp() > 1) then
			return enemies[1]
		end
		for _, enemy in ipairs(enemies) do
			if enemies[1]:objectName() ~= enemy:objectName() then
				if self.player:hasFlag("newqianxin_red") then
					if (self:hasSkills("longhun|qingnang|beige", enemy) and getKnownCard(enemy,"red", nil, "he") >= 1) or getCardsNum("Peach") >=1 then
						return enemy
					end
				elseif self.player:hasFlag("newqianxin_black") then
					if (enemy:hasSkill("qingguo") and not enemy:isKongcheng()) or 
						(self:hasSkills("longhun|beige", enmey) and getKnownCard(enemy,"black", nil, "he") >= 1) or
						(enemy:hasSkill("leiji") and enemy:getCardCount(true) > 0) then
						return enmey
					end
				end
			end
		end
		return enemies[1]
	end
	return targets:first()
end



