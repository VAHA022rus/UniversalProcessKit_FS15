-- by mor2000

--------------------
-- Processor (converts and stores stuff)

-- storage stystems
-- separate - standard
-- single - allow only 1 fillType
-- fifo - layered, first in first out
-- lifo - layered, last in last out

-- convertion rule: what recipe, what recipe
-- ie: brewery
-- convertion: beer 0.05 barley 1.1 water
-- read it like: 1 beer = 0.05 x barley + 1.1 x water
-- processing: water 0, barley 0, beer 5
-- read it like: pass water to parent with 0 liter per second (=store), barley too and beer with 5 liters per second


local UPK_Processor_mt = ClassUPK(UPK_Processor,UniversalProcessKit)
InitObjectClass(UPK_Processor, "UPK_Processor")
UniversalProcessKit.addModule("processor",UPK_Processor)

function UPK_Processor:new(id, parent)
	local self = UniversalProcessKit:new(id, parent, UPK_Processor_mt)
	registerObjectClassName(self, "UPK_Processor")
	
	self.product = unpack(UniversalProcessKit.fillTypeNameToInt(getStringFromUserAttribute(id, "product")))
	
	self.onlyWholeProducts = getBoolFromUserAttribute(id, "onlyWholeProducts", false)
	
	self.productsPerSecond = getNumberFromUserAttribute(id, "productsPerSecond", 0)
	self.productsPerMinute = getNumberFromUserAttribute(id, "productsPerMinute", 0)
	self.productsPerHour = getNumberFromUserAttribute(id, "productsPerHour", 0)
	self.productionHours={}
	if self.productsPerSecond>0 or self.productsPerMinute>0 or self.productsPerHour>0 then
		local productionHoursStrings = getStringFromUserAttribute(id, "productionHours", "0-23")
		local productionHoursStringArr = Utils.splitString(",",productionHoursStrings)
		for _,v in pairs(productionHoursStringArr) do
			self:print(v)
			local productionHoursArr = Utils.splitString("-",v)
			local lowerHour = mathmin(mathmax(tonumber(productionHoursArr[1]),0),23)
			local upperHour = mathmin(mathmax(tonumber(productionHoursArr[2]),lowerHour),23)
			if lowerHour~=nil and upperHour~=nil then
				for i=lowerHour,upperHour do
					self:print('produce sth at hour '..tostring(i))
					self.productionHours[i]=true
				end
			end
		end
	end
	self.productsPerDay = getNumberFromUserAttribute(id, "productsPerDay" ,0)
	
	self.productionInterval = getNumberFromUserAttribute(id, "productionInterval", 1, 1)
	self.currentInterval = self.productionInterval

	self.productionPrerequisite={}
	self.hasProductionPrerequisite=false
	local prerequisiteArr=getArrayFromUserAttribute(id, "productionPrerequisite")
	for i=1,#prerequisiteArr,2 do
		local amount=tonumber(prerequisiteArr[i])
		local type=unpack(UniversalProcessKit.fillTypeNameToInt(prerequisiteArr[i+1]))
		self:print('productionPrerequisite: '..tostring(amount)..' of '..tostring(prerequisiteArr[i+1])..' ('..tostring(type)..')')
		if amount~=nil and type~=nil then
			self.productionPrerequisite[type]=amount
			self.hasProductionPrerequisite=true
		end
	end
	
	self.productionProbability = getNumberFromUserAttribute(id, "productionProbability", 1, 0, 1)
	
	local outcomeVariation=getNumberFromUserAttribute(id, "outcomeVariation")
	if outcomeVariation~=nil then
		if outcomeVariation < 0 then
			self:print('Error: outcomeVariation cannot be lower than 0',true)
			return false
		elseif outcomeVariation>1 and outcomeVariation<=100 then
			self:print('Warning: outcomeVariation is not between 0 and 1')
			outcomeVariation=outcomeVariation/100
		elseif outcomeVariation>100 then
			self:print('Warning: outcomeVariation is not between 0 and 1')
			outcomeVariation=0
		end
	else
		outcomeVariation=0
	end
	self.outcomeVariation = outcomeVariation
	
	if self.outcomeVariation>0 then
		self.outcomeVariationType = getStringFromUserAttribute(id, "outcomeVariationType", "uniform")
		if self.outcomeVariationType=="normal" and (self.productsPerSecond>0 or self.productsPerMinute>0) then
			self:print('Notice: Its not recommended to use normal distributed outcome variation for productsPerSecond and productsPerMinute')
		end
	end
	
	self.bufferedProducts = 0
	
	self.hasRecipe=false
	self.recipe=__c()
	local recipeArr=getArrayFromUserAttribute(id, "recipe")
	for i=1,#recipeArr,2 do
		local amount=tonumber(recipeArr[i])
		local type=unpack(UniversalProcessKit.fillTypeNameToInt(recipeArr[i+1]))
		if amount~=nil and type~=nil then
			self.recipe[type]=amount
			self.hasRecipe=true
		end
	end
	
	self.hasByproducts=false
	self.byproducts=__c()
	local byproductsArr=getArrayFromUserAttribute(id, "byproducts")
	for i=1,#byproductsArr,2 do
		local amount=tonumber(byproductsArr[i])
		local type=unpack(UniversalProcessKit.fillTypeNameToInt(byproductsArr[i+1]))
		if amount~=nil and type~=nil then
			self.byproducts[type]=amount
			self.hasByproducts=true
		end
	end
	
	self.enableChildrenIfProcessing = getBoolFromUserAttribute(id, "enableChildrenIfProcessing", false)
	self:print('enableChildrenIfProcessing = '..tostring(self.enableChildrenIfProcessing))
	self.enableChildrenIfNotProcessing = getBoolFromUserAttribute(id, "enableChildrenIfNotProcessing", false)
	self:print('enableChildrenIfNotProcessing = '..tostring(self.enableChildrenIfNotProcessing))
	self.disableChildrenIfProcessing = getBoolFromUserAttribute(id, "disableChildrenIfProcessing", false)
	self:print('disableChildrenIfProcessing = '..tostring(self.disableChildrenIfProcessing))
	self.disableChildrenIfNotProcessing = getBoolFromUserAttribute(id, "disableChildrenIfNotProcessing", false)
	self:print('disableChildrenIfNotProcessing = '..tostring(self.disableChildrenIfNotProcessing))
	
	if self.enableChildrenIfProcessing then
		self.disableChildrenIfProcessing = false
	end
	if self.enableChildrenIfNotProcessing then
		self.disableChildrenIfNotProcessing = false
	end
	
	self.emptyFillTypesIfProcessing={}
	local emptyFillTypesIfProcessingArr = getArrayFromUserAttribute(self.nodeId, "emptyFillTypesIfProcessing")
	for i=1,#emptyFillTypesIfProcessingArr do
		local fillType=unpack(UniversalProcessKit.fillTypeNameToInt(emptyFillTypesIfProcessingArr[i]))
		table.insert(self.emptyFillTypesIfProcessing,fillType)
	end
	
	self.emptyFillTypesIfNotProcessing={}
	local emptyFillTypesIfNotProcessingArr = getArrayFromUserAttribute(self.nodeId, "emptyFillTypesIfNotProcessing")
	for i=1,#emptyFillTypesIfNotProcessingArr do
		local fillType=unpack(UniversalProcessKit.fillTypeNameToInt(emptyFillTypesIfNotProcessingArr[i]))
		table.insert(self.emptyFillTypesIfNotProcessing,fillType)
	end
	
	self.hasAddIfProcessing=false
	self.addIfProcessing={}
	local addIfProcessingArr=getArrayFromUserAttribute(id, "addIfProcessing")
	for i=1,#addIfProcessingArr,2 do
		local amount=tonumber(addIfProcessingArr[i])
		local type=unpack(UniversalProcessKit.fillTypeNameToInt(addIfProcessingArr[i+1]))
		if amount~=nil and type~=nil then
			self.addIfProcessing[type]=amount
			self.hasAddIfProcessing=true
		end
	end
	
	self.hasAddIfNotProcessing=false
	self.addIfNotProcessing={}
	local addIfNotProcessingArr=getArrayFromUserAttribute(id, "addIfNotProcessing")
	for i=1,#addIfNotProcessingArr,2 do
		local amount=tonumber(addIfNotProcessingArr[i])
		local type=unpack(UniversalProcessKit.fillTypeNameToInt(addIfNotProcessingArr[i+1]))
		if amount~=nil and type~=nil then
			self.addIfNotProcessing[type]=amount
			self.hasAddIfNotProcessing=true
		end
	end
	
	self.statName=getStringFromUserAttribute(id, "statName")
	local validStatName=false
	if self.statName~=nil then
		for _,v in pairs(FinanceStats.statNames) do
			if self.statName==v then
				validStatName=true
				break
			end
		end
	end
	if not validStatName then
		self.statName="other"
	end
	
	--[[
	FinanceStats.statNames = {
		"newVehiclesCost",
		"newAnimalsCost",
		"constructionCost",
		"vehicleRunningCost",
		"propertyMaintenance",
		"wagePayment",
		"harvestIncome",
		"missionIncome",
		"other",
		"loanInterest"
	}
	--]]

	if not moveMode then -- moveMode here?
		if self.isServer then
			if self.product~=nil and self.productsPerMinute>0 then
				UniversalProcessKitListener.addMinuteChangeListener(self)
			elseif self.product~=nil and self.productsPerHour>0 then
				UniversalProcessKitListener.addHourChangeListener(self)
			elseif self.product~=nil and self.productsPerDay>0 then
				UniversalProcessKitListener.addDayChangeListener(self)
			elseif self.product~=nil and self.productsPerSecond>0 then
				UniversalProcessKitListener.addSecondChangeListener(self)
			end
		end
	end
	
	self.dtsum=0
	
	self:print('loaded Processor successfully')
	
	return self
end

function UPK_Processor:delete()
	if self.isServer then
		if self.product~=nil and self.productsPerMinute>0 then
			UniversalProcessKitListener.removeMinuteChangeListener(self)
		elseif self.product~=nil and self.productsPerHour>0 then
			UniversalProcessKitListener.removeHourChangeListener(self)
		elseif self.product~=nil and self.productsPerDay>0 then
			UniversalProcessKitListener.removeDayChangeListener(self)
		elseif self.product~=nil and self.productsPerSecond>0 then
			UniversalProcessKitListener.removeSecondChangeListener(self)
		end
	end
	UPK_Processor:superClass().delete(self)
end

function UPK_Processor:loadExtraNodes(xmlFile, key)
	self.bufferedProducts = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#bufferedProducts"),0)
	self.currentInterval = Utils.getNoNil(getXMLInt(xmlFile, key .. "#currentInterval"),1)
	return true
end

function UPK_Processor:getSaveExtraNodes(nodeIdent)
	local nodes=""
	if self.bufferedProducts>0 then
		nodes=nodes .. " bufferedProducts=\""..tostring(mathfloor(self.bufferedProducts*1000+0.5)/1000).."\""
	end
	if self.productionInterval>1 then
		nodes=nodes .. " currentInterval=\""..tostring(self.currentInterval).."\""
	end
	return nodes
end

function UPK_Processor:dayChanged()
	self:produce(self.productsPerDay)
end

function UPK_Processor:hourChanged()
	if self.productionHours[g_currentMission.environment.currentHour] then
		self:produce(self.productsPerHour)
	end
end

function UPK_Processor:minuteChanged()
	if self.productionHours[g_currentMission.environment.currentHour] then
		self:produce(self.productsPerMinute)
	end
end

function UPK_Processor:secondChanged()
	if self.productionHours[g_currentMission.environment.currentHour] then
		self:produce(self.productsPerSecond)
	end
end

function UPK_Processor:produce(processed)
	if self.isServer and self.isEnabled then
		local produce=self.productionProbability==1
		if not produce then
			local rnr = mathrandom()
			produce = rnr<=self.productionProbability
			self:print('random number: '..tostring(rnr)..' is smaller than pprb '..round(tostring(self.productionProbability),8)..'? '..tostring(produce))
		end
		if self.productionInterval>1 then
			self.currentInterval = self.currentInterval % self.productionInterval + 1
			self:print('self.currentInterval = '..tostring(self.currentInterval))
		end
		if produce and self.currentInterval==1 then
			if self.outcomeVariation~=0 then
				if self.outcomeVariationType=="normal" then -- normal distribution
					local r=mathmin(mathmax(getNormalDistributedRandomNumber(),-3),3)/3
					processed=processed+processed*self.outcomeVariation*r
				elseif self.outcomeVariationType=="uniform" then -- equal distribution
					local r=2*mathrandom()-1
					processed=processed+processed*self.outcomeVariation*r
				end
			end
			if self.hasProductionPrerequisite then
				for k,v in pairs(self.productionPrerequisite) do
					if type(v)=="number" and v>0 then
						if self.onlyWholeProducts then
							processed=mathmin(processed,mathfloor(self:getFillLevel(k)/v))
						else
							processed=mathmin(processed,self:getFillLevel(k)/v)
						end
					end
				end
			end
			if self.product~=UniversalProcessKit.FILLTYPE_MONEY then
				processed=mathmin(processed,self:getStorageBitCapacity(self.product)-self:getFillLevel(self.product))
			end
			if round(processed,8)>0 then
				if self.hasRecipe then
					for k,v in pairs(self.recipe) do
						if type(v)=="number" and v>0 then
							processed=mathmin(processed,self:getFillLevel(k)/v or 0)
						end
					end
					local ressourcesUsed=self.recipe*processed
					for k,v in pairs(ressourcesUsed) do
						if type(v)=="number" then
							self:addFillLevel(-v,k)
						end
					end
				end
				-- deal with the produced outcome
				self.bufferedProducts=self.bufferedProducts+processed
				local finalProducts=0
				if self.onlyWholeProducts then
					local wholeProducts=mathfloor(self.bufferedProducts)
					if wholeProducts>=1 then
						finalProducts=wholeProducts
						self.bufferedProducts=self.bufferedProducts-wholeProducts
					end
				else
					finalProducts=self.bufferedProducts
					self.bufferedProducts=0
				end
				finalProducts=round(finalProducts,8)
				if finalProducts>0 then
					self:addFillLevel(finalProducts,self.product)
					if self.hasByproducts then
						for k,v in pairs(self.byproducts) do
							if type(v)=="number" and v>0 then
								self:addFillLevel(v*finalProducts,k)
							end
						end
					end
					
					-- emptyFillTypesIfProcessing
					for _,v in pairs(self.emptyFillTypesIfProcessing) do
						self:setFillLevel(0,v)
					end
					
					-- addIfProcessing
					if self.hasAddIfProcessing then
						for k,v in pairs(self.addIfProcessing) do
							if type(v)=="number" and v>0 then
								self:addFillLevel(v,k)
							end
						end
					end
					
					-- en/disableChildrenIfProcessing
					if self.enableChildrenIfProcessing then
						self:print('enable children')
						self:setEnableChildren(true)
					end
					if self.disableChildrenIfProcessing then
						self:print('disable children')
						self:setEnableChildren(false)
					end
				else
					
					-- emptyFillTypesIfNotProcessing
					for _,v in pairs(self.emptyFillTypesIfNotProcessing) do
						self:setFillLevel(0,v)
					end
					
					-- addIfNotProcessing
					if self.hasAddIfNotProcessing then
						for k,v in pairs(self.addIfNotProcessing) do
							if type(v)=="number" and v>0 then
								self:addFillLevel(v,k)
							end
						end
					end
					
					-- en/disableChildrenIfNotProcessing
					if self.enableChildrenIfNotProcessing then
						self:print('enable children')
						self:setEnableChildren(true)
					end
					if self.disableChildrenIfNotProcessing then
						self:print('disable children')
						self:setEnableChildren(false)
					end
				end
			end
		end
	end
end