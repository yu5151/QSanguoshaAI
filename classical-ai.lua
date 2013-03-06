--[[
	文件：classical-ai.lua
	主题：经典战术
]]--
--[[
	PART 01：3V3经典战术
	内容：黄金一波流
]]--
--黄金一波流--
	--相关信息
	sgs.GoldenWaveDetail = {
		KurouActor = {}, --苦肉执行者
		YijiActor = {}, --遗计执行者
		JijiuActor = {}, --急救执行者
		EruptSignal = {}, --起爆信号（五谷丰登中，急救执行者得到的红色牌）
	}
	--判断是否使用黄金一波流
	function GoldenWaveStart(self)
		local huanggai = self.player
		local room = huanggai:getRoom()
		if string.lower(room:getMode()) == "06_3v3" then
			sgs.GoldenWaveDetail.EruptSignal = {}
			if huanggai:hasSkill("kurou") then
				local guojia, huatuo
				if #self.friends_noself > 1 then
					for _,friend in pairs(self.friends_noself) do
						if friend:hasSkill("yiji") then
							guojia = friend
						elseif friend:hasSkill("jijiu") then
							huatuo = friend
						else
							room:setPlayerMark(friend, "GWF_Forbidden", 1)
						end
					end
				end
				if guojia and huatuo then
					sgs.GoldenWaveDetail.KurouActor = {huanggai:objectName()}
					sgs.GoldenWaveDetail.YijiActor = {guojia:objectName()}
					sgs.GoldenWaveDetail.JijiuActor = {huatuo:objectName()}
					room:setPlayerMark(huanggai, "GoldenWaveFlow", 1)
					room:setPlayerMark(guojia, "GoldenWaveFlow", 1)
					room:setPlayerMark(huatuo, "GoldenWaveFlow", 1)
					return true
				else
					sgs.GoldenWaveDetail.KurouActor = {}
					sgs.GoldenWaveDetail.YijiActor = {}
					sgs.GoldenWaveDetail.JijiuActor = {}
					room:setPlayerMark(huanggai, "GWF_Forbidden", 1)
					return false
				end
			end
		end
		room:setPlayerMark(huanggai, "GWF_Forbidden", 1)
		return false
	end
	--黄金苦肉
	function GWFKurouTurnUse(self)
		local huanggai = self.player
		if huanggai:getMark("GWF_Forbidden") == 0 then
			if huanggai:getMark("GoldenWaveFlow") > 0 then
				local released = sgs.GoldenWaveDetail.EruptSignal["Released"]
				if released then
					if self.getHp() > 1 then
						return sgs.Card_Parse("@KurouCard=.")
					end
				else
					return sgs.Card_Parse("@KurouCard=.")
				end
			elseif GoldenWaveStart(self) then
				return sgs.Card_Parse("@KurouCard=.")
			end
		end
	end
	--黄金遗计
	function GWFYijiAsk(player, card_ids)
		local guojia = self.player
		if guojia:getMark("GWF_Forbidden") == 0 then
			if guojia:getMark("GoldenWaveFlow") > 0 then
				local released = sgs.GoldenWaveDetail.EruptSignal["Released"]
				local huanggai = sgs.GoldenWaveDetail.KurouActor[1]
				local huatuo = sgs.GoldenWaveDetail.JijiuActor[1]
				if released then
					for _,id in ipairs(card_ids) do
						return huanggai, id
					end
				else
					for _,id in ipairs(card_ids) do
						local card = sgs.Sanguosha:getCard(id)
						if card:isKindOf("Crossbow") or card:isKindOf("AOE") or card:isKindOf("Duel") then
							return huanggai, id
						elseif card:isRed() and huatuo:isAlive() then
							return huatuo, id
						else
							return huanggai, id
						end
					end
				end
			end
		end
	end
	--黄金急救
	function GWFJijiuSignal(card, player, card_place)
		local huatuo = player
		if huatuo:getMark("GWF_Forbidden") == 0 then
			if huatuo:getMark("GoldenWaveFlow") > 0 then
				if #EruptSignal > 0 then
					if card:getId() == EruptSignal[1] then
						local cards = player:getCards("he")
						for _,id in sgs.qlist(cards) do
							if id ~= EruptSignal[1] then
								local acard = sgs.Sanguosha:getCard(id)
								if acard:isRed() then
									return false
								end
							end
						end
						sgs.GoldenWaveDetail.EruptSignal["Released"] = card:getId()
					end
				end
			end
		end
		return true
	end
	--命苦的郭嘉（未完成）
--[[
	PART 02：KOF经典战术
	内容：苦肉一波带、控底爆发
]]--
--苦肉一波带--
	--判断是否使用苦肉一波带
	function KOFKurouStart(self)
		if string.lower(self.room:getMode()) == "02_1v1" then
			local enemy = self.room:getOtherPlayers(self.player):first()
			if self:hasSkills("fankui|fenyong|zhichi|jilei", enemy) then
				self.player:speak("不行，这家伙不好对付，慢苦为妙。")
				self.room:setPlayerMark(self.player, "KKR_Forbidden", 1)
				return false
			end
			self.player:speak("看我大苦肉一波带走！")
			self.room:setPlayerMark(self.player, "KOFKurouRush", 1)
			return true
		end
		return false
	end
	--一波苦肉
	function KOFKurouTurnUse(self)
		local huanggai = self.player
		if huanggai:getMark("KKR_Forbidden") == 0 then
			if huanggai:getMark("KOFKurouRush") > 0 then
				if huanggai:getHp() > 1 then
					return sgs.Card_Parse("@KurouCard=.")
				end
				if self:getCardsNum("Analeptic") + self:getCardsNum("Peach") > 0 then
					return sgs.Card_Parse("@KurouCard=.")
				end
			elseif KOFKurouStart(self) then
				return sgs.Card_Parse("@KurouCard=.")
			end
		end
	end
--控底爆发--
	--相关信息
	sgs.KOFControlType = {} --起爆卡牌的类型
	sgs.KOFControlSuit = {} --起爆卡牌的花色
	sgs.KOFControlResult = {} --控底结果
	sgs.KOFControlDetail = { --爆发详细信息
		EruptSkill = {}, --待爆发技能名
		MaxInterval = {}, --爆发时可容忍的两起爆卡牌间间隔
		ControlFinished = {} --爆发结束标志
	}
	--判断是否使用控底爆发战术
	function KOFControlStart(player)
		local room = player:getRoom()
		if string.lower(room:getMode()) == "02_1v1" then
			if player:hasSkill("guanxing") or player:hasSkill("super_guanxing") then
				local tag = player:getTag("1v1Arrange")
				if tag then
					local followList = tag:toStringList()
					if followList then
						if #followList > 0 then
							local follow = 1
							for _,name in ipairs(followList) do
								local general = sgs.Sanguosha:getGeneral(name)
								local flag = false
								if general:hasSkill("luoshen") then
									sgs.KOFControlSuit = {sgs.Card_Spade, sgs.Card_Club}
									sgs.KOFControlDetail.EruptSkill = {"luoshen"}
									sgs.KOFControlDetail.MaxInterval = {0}
									sgs.KOFControlDetail.ControlFinished = {false}
									flag = true
								elseif general:hasSkill("jizhi") then
									sgs.KOFControlType = {"TrickCard"}
									sgs.KOFControlDetail.EruptSkill = {"jizhi"}
									sgs.KOFControlDetail.MaxInterval = {1}
									sgs.KOFControlDetail.ControlFinished = {false}
								elseif general:hasSkill("xiaoji") then
									sgs.KOFControlType = {"EquipCard"}
									sgs.KOFControlDetail.EruptSkill = {"xiaoji"}
									sgs.KOFControlDetail.MaxInterval = {2}
									sgs.KOFControlDetail.ControlFinished = {false}
								elseif general:hasSkill("guhuo") then
									sgs.KOFControlSuit = {sgs.Card_Heart}
									sgs.KOFControlDetail.EruptSkill = {"guhuo"}
									sgs.KOFControlDetail.MaxInterval = {1}
									sgs.KOFControlDetail.ControlFinished = {false}
								end
								if #sgs.KOFControlType > 0 or #sgs.KOFControlSuit > 0 then
									room:setPlayerMark(player, "KOFControl", follow)
									if flag then
										room:setPlayerMark(player, "StrictControl", 1)
									end
									return true
								end
								follow = follow + 1
							end
						end
					end
				end
			end
		end
		room:setPlayerMark(player, "KFC_Forbidden", 1)
		return false
	end
	--判断卡牌的花色是否相符
	function MatchSuit(card, suit_table)
		if #suit_table > 0 then
			local cardsuit = card:getSuit()
			for _,suit in pairs(suit_table) do
				if cardsuit == suit then
					return true
				end
			end
		end
		return false
	end
	--判断卡牌的类型是否相符
	function MatchType(card, type_table)
		if #type_table > 0 then
			for _,cardtype in pairs(type_table) do
				if card:isKindOf(cardtype) then
					return true
				end
			end
		end
		return false
	end
	--执行控底观星
	function KOFGuanxing(self, cards)
		local up = {}
		local bottom = {}
		local strict = self.player:getMark("StrictControl") > 0
		for _,id in pairs(cards) do
			local card = sgs.Sanguosha:getCard(id)
			if MatchSuit(card, sgs.KOFControlSuit) or MatchType(card, sgs.KOFControlType) then --相符
				if card:isKindOf("Peach") then --相符，但是桃子
					if self:isWeak() then --相符、桃子、虚弱
						table.insert(up, id)
					else --相符、桃子、不虚弱
						table.insert(bottom, id)
						table.insert(sgs.KOFControlResult, id)
						self.room:setPlayerMark(self.player, "KOFInterval", 0)
					end
				else --相符、不是桃子
					table.insert(bottom, id)
					table.insert(sgs.KOFControlResult, id)
					self.room:setPlayerMark(self.player, "KOFInterval", 0)
				end
			elseif strict then --不相符，严格
				table.insert(up, id)
			elseif card:isKindOf("Crossbow") then --不相符、不严格、诸葛连弩
				table.insert(bottom, id)
				table.insert(sgs.KOFControlResult, id)
				local marks = self.player:getMark("KOFInterval")
				self.room:setPlayerMark(self.player, "KOFInterval", marks+1)
			else --不相符、不严格、不为诸葛连弩
				local marks = self.player:getMark("KOFInterval")
				local maxInterval = sgs.KOFControlDetail.MaxInterval[1]
				if maxInterval and marks < maxInterval then --不相符、不严格、不为诸葛连弩、间隔较小
					local value = sgs.ai_use_value[card:objectName()]
					if value and value > 4 then --不相符、不严格、不为诸葛连弩、间隔较小、使用价值高
						table.insert(bottom, id)
						table.insert(sgs.KOFControlResult, id)
						self.room:setPlayerMark(self.player, "KOFInterval", marks+1)
					else --不相符、不严格、不为诸葛连弩、间隔较小、使用价值低
						table.insert(up, id)
					end
				else --不相符、不严格、不为诸葛连弩、间隔较大
					table.insert(up, id)
				end
			end
		end
		return up, bottom
	end
	--判断中间武将是否需要让路（待完善）
	function KOFNeedDeath(player)
		return false
	end
	--获取控底方法
	function KOFGuanxingTactic(player, up_only)
		if not up_only then 
			if player:getMark("KFC_Forbidden") == 0 then
				if player:getMark("KOFControl") > 0 then
					return KOFGuanxing
				end
				if KOFControlStart(player) then
					return KOFGuanxing
				end
			end
		end
	end
