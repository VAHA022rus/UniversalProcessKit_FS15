-- by mor2000

--------------------
-- Processor (converts stuff)

local UPK_Processor_mt = ClassUPK(UPK_Processor,UniversalProcessKit)
InitObjectClass(UPK_Processor, "UPK_Processor")
UniversalProcessKit.addModule("processor",UPK_Processor)

function UPK_Processor:new(nodeId, parent)
	printFn('UPK_Processor:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId, parent, UPK_Processor_mt)
	registerObjectClassName(self, "UPK_Processor")
	
	self.product = unpack(UniversalProcessKit.fillTypeNameToInt(getStringFromUserAttribute(nodeId, "product")))
	
	self.onlyWholeProducts = getBoolFromUserAttribute(nodeId, "onlyWholeProducts", false)
	
	self.productsPerSecond = getNumberFromUserAttribute(nodeId, "productsPerSecond", 0)
	self.productsPerMinute = getNumberFromUserAttribute(nodeId, "productsPerMinute", 0)
	self.productsPerHour = getNumberFromUserAttribute(nodeId, "productsPerHour", 0)
	self.productionHours={}
	if self.productsPerSecond>0 or self.productsPerMinute>0 or self.productsPerHour>0 then
		local productionHoursStrings = getStringFromUserAttribute(nodeId, "productionHours", "0-23")
		local productionHoursStringArr = Utils.splitString(",",productionHoursStrings)
		for _,v in pairs(productionHoursStringArr) do
			self:printAll(v)
			local productionHoursArr = Utils.splitString("-",v)
			local lowerHour = mathmin(mathmax(tonumber(productionHoursArr[1]),0),23)
			local upperHour = mathmin(mathmax(tonumber(productionHoursArr[2]),lowerHour),23)
			if lowerHour~=nil and upperHour~=nil then
				for i=lowerHour,upperHour do
					self:printInfo('produce sth at hour '..tostring(i))
					self.productionHours[i]=true
				end
			end
		end
	end
	self.productsPerDay = getNumberFromUserAttribute(nodeId, "productsPerDay" ,0)
	
	self.productionInterval = getNumberFromUserAttribute(nodeId, "productionInterval", 1, 1)
	self.currentInterval = self.productionInterval

	self.productionPrerequisite={}
	self.hasProductionPrerequisite=false
	local prerequisiteArr=getArrayFromUserAttribute(nodeId, "productionPrerequisite")
	for i=1,#prerequisiteArr,2 do
		local amount=tonumber(prerequisiteArr[i])
		local type=unpack(UniversalProcessKit.fillTypeNameToInt(prerequisiteArr[i+1]))
		self:printInfo('productionPrerequisite: '..tostring(amount)..' of '..tostring(prerequisiteArr[i+1])..' ('..tostring(type)..')')
		if amount~=nil and type~=nil then
			self.productionPrerequisite[type]=amount
			self.hasProductionPrerequisite=true
		end
	end
	
	self.productionProbability = getNumberFromUserAttribute(nodeId, "productionProbability", 1, 0, 1)
	
	local outcomeVariation=getNumberFromUserAttribute(nodeId, "outcomeVariation")
	if outcomeVariation~=nil then
		if outcomeVariation < 0 then
			self:printErr('Error: outcomeVariation cannot be lower than 0',true)
			return false
		elseif outcomeVariation>1 and outcomeVariation<=100 then
			self:printInfo('Warning: outcomeVariation is not between 0 and 1')
			outcomeVariation=outcomeVariation/100
		elseif outcomeVariation>100 then
			self:printInfo('Warning: outcomeVariation is not between 0 and 1')
			outcomeVariation=0
		end
	else
		outcomeVariation=0
	end
	self.outcomeVariation = outcomeVariation
	
	if self.outcomeVariation>0 then
		self.outcomeVariationType = getStringFromUserAttribute(nodeId, "outcomeVariationType", "uniform")
		if self.outcomeVariationType=="normal" and (self.productsPerSecond>0 or self.productsPerMinute>0) then
			self:printInfo('Notice: Its not recommended to use normal distributed outcome variation for productsPerSecond and productsPerMinute')
		end
	end
	
	self.bufferedProducts = 0
	
	self.hasRecipe=false
	self.recipe=__c()
	local recipeArr=getArrayFromUserAttribute(nodeId, "recipe")
	for i=1,#recipeArr,2 do
		local amount=tonumber(recipeArr[i])
		local fillType=unpack(UniversalProcessKit.fillTypeNameToInt(recipeArr[i+1]))
		if type(amount)=="number" and type(fillType)=="number" then
			self.recipe[fillType]=-amount
			self.hasRecipe=true
		end
	end
	
	self.hasByproducts=false
	self.byproducts=__c()
	local byproductsArr=getArrayFromUserAttribute(nodeId, "byproducts")
	for i=1,#byproductsArr,2 do
		local amount=tonumber(byproductsArr[i])
		local fillType=unpack(UniversalProcessKit.fillTypeNameToInt(byproductsArr[i+1]))
		if type(amount)=="number" and type(fillType)=="number" then
			self.byproducts[fillType]=amount
			self.hasByproducts=true
		end
	end
	
	-- if processing
	
	self.emptyFillTypesIfProcessing={}
	local emptyFillTypesIfProcessingArr = getArrayFromUserAttribute(nodeId, "emptyFillTypesIfProcessing")
	for i=1,#emptyFillTypesIfProcessingArr do
		local fillType=unpack(UniversalProcessKit.fillTypeNameToInt(emptyFillTypesIfProcessingArr[i]))
		table.insert(self.emptyFillTypesIfProcessing,fillType)
	end
	
	self.hasAddIfProcessing=false
	self.addIfProcessing={}
	local addIfProcessingArr=getArrayFromUserAttribute(nodeId, "addIfProcessing")
	for i=1,#addIfProcessingArr,2 do
		local amount=tonumber(addIfProcessingArr[i])
		local type=unpack(UniversalProcessKit.fillTypeNameToInt(addIfProcessingArr[i+1]))
		if amount~=nil and type~=nil then
			self.addIfProcessing[type]=amount
			self.hasAddIfProcessing=true
		end
	end
	
	self.hasRemoveIfProcessing=false
	self.removeIfProcessing={}
	local removeIfProcessingArr=getArrayFromUserAttribute(nodeId, "removeIfProcessing")
	for i=1,#removeIfProcessingArr,2 do
		local amount=tonumber(removeIfProcessingArr[i])
		local type=unpack(UniversalProcessKit.fillTypeNameToInt(removeIfProcessingArr[i+1]))
		if amount~=nil and type~=nil then
			self.removeIfProcessing[type]=amount
			self.hasAddIfProcessing=true
		end
	end
	
	self.enableChildrenIfProcessing = getBoolFromUserAttribute(nodeId, "enableChildrenIfProcessing", false)
	self:printAll('enableChildrenIfProcessing = ',self.enableChildrenIfProcessing)
	self.disableChildrenIfProcessing = getBoolFromUserAttribute(nodeId, "disableChildrenIfProcessing", false)
	self:printAll('disableChildrenIfProcessing = ',self.disableChildrenIfProcessing)
	
	if self.enableChildrenIfProcessing then
		self.disableChildrenIfProcessing = false
	end
	
	-- if not processing
	
	self.emptyFillTypesIfNotProcessing={}
	local emptyFillTypesIfNotProcessingArr = getArrayFromUserAttribute(nodeId, "emptyFillTypesIfNotProcessing")
	for i=1,#emptyFillTypesIfNotProcessingArr do
		local fillType=unpack(UniversalProcessKit.fillTypeNameToInt(emptyFillTypesIfNotProcessingArr[i]))
		table.insert(self.emptyFillTypesIfNotProcessing,fillType)
	end
	
	self.hasAddIfNotProcessing=false
	self.addIfNotProcessing={}
	local addIfNotProcessingArr=getArrayFromUserAttribute(nodeId, "addIfNotProcessing")
	for i=1,#addIfNotProcessingArr,2 do
		local amount=tonumber(addIfNotProcessingArr[i])
		local type=unpack(UniversalProcessKit.fillTypeNameToInt(addIfNotProcessingArr[i+1]))
		if amount~=nil and type~=nil then
			self.addIfNotProcessing[type]=amount
			self.hasAddIfNotProcessing=true
		end
	end
	
	self.hasRemoveIfNotProcessing=false
	self.removeIfNotProcessing={}
	local removeIfNotProcessingArr=getArrayFromUserAttribute(nodeId, "removeIfNotProcessing")
	for i=1,#removeIfNotProcessingArr,2 do
		local amount=tonumber(removeIfNotProcessingArr[i])
		local type=unpack(UniversalProcessKit.fillTypeNameToInt(removeIfNotProcessingArr[i+1]))
		if amount~=nil and type~=nil then
			self.removeIfNotProcessing[type]=amount
			self.hasAddIfNotProcessing=true
		end
	end
	
	self.enableChildrenIfNotProcessing = getBoolFromUserAttribute(nodeId, "enableChildrenIfNotProcessing", false)
	self:printAll('enableChildrenIfNotProcessing = ',self.enableChildrenIfNotProcessing)
	self.disableChildrenIfNotProcessing = getBoolFromUserAttribute(nodeId, "disableChildrenIfNotProcessing", false)
	self:printAll('disableChildrenIfNotProcessing = ',self.disableChildrenIfNotProcessing)
	
	if self.enableChildrenIfNotProcessing then
		self.disableChildrenIfNotProcessing = false
	end
	
	-- if production skipped
	
	self.emptyFillTypesIfProductionSkipped={}
	local emptyFillTypesIfProductionSkippedArr = getArrayFromUserAttribute(nodeId, "emptyFillTypesIfProductionSkipped")
	for i=1,#emptyFillTypesIfProductionSkippedArr do
		local fillType=unpack(UniversalProcessKit.fillTypeNameToInt(emptyFillTypesIfProductionSkippedArr[i]))
		table.insert(self.emptyFillTypesIfProductionSkipped,fillType)
	end
	
	self.hasAddIfProductionSkipped=false
	self.addIfProductionSkipped={}
	local addIfProductionSkippedArr=getArrayFromUserAttribute(nodeId, "addIfProductionSkipped")
	for i=1,#addIfProductionSkippedArr,2 do
		local amount=tonumber(addIfProductionSkippedArr[i])
		local type=unpack(UniversalProcessKit.fillTypeNameToInt(addIfProductionSkippedArr[i+1]))
		if amount~=nil and type~=nil then
			self.addIfProductionSkipped[type]=amount
			self.hasAddIfProductionSkipped=true
		end
	end
	
	self.hasRemoveIfProductionSkipped=false
	self.removeIfProductionSkipped={}
	local removeIfProductionSkippedArr=getArrayFromUserAttribute(nodeId, "removeIfProductionSkipped")
	for i=1,#removeIfProductionSkippedArr,2 do
		local amount=tonumber(removeIfProductionSkippedArr[i])
		local type=unpack(UniversalProcessKit.fillTypeNameToInt(removeIfProductionSkippedArr[i+1]))
		if amount~=nil and type~=nil then
			self.removeIfProductionSkipped[type]=amount
			self.hasAddIfProductionSkipped=true
		end
	end
	
	self.enableChildrenIfProductionSkipped = getBoolFromUserAttribute(nodeId, "enableChildrenIfProductionSkipped", false)
	self:printAll('enableChildrenIfProductionSkipped = ',self.enableChildrenIfProductionSkipped)
	self.disableChildrenIfProductionSkipped = getBoolFromUserAttribute(nodeId, "disableChildrenIfProductionSkipped", false)
	self:printAll('disableChildrenIfProductionSkipped = ',self.disableChildrenIfProductionSkipped)
	
	if self.enableChildrenIfProductionSkipped then
		self.disableChildrenIfProductionSkipped = false
	end
	
	-- stat name
	
	self.statName=getStatNameFromUserAttribute(nodeId)
	
	if self.product==UniversalProcessKit.FILLTYPE_MONEY and self.statName~="other" then
		if self.statName=="newVehiclesCost" then	
			self.product=UniversalProcessKit.FILLTYPE_NEWVEHICLESCOST
		elseif self.statName=="newAnimalsCost" then	
			self.product=UniversalProcessKit.FILLTYPE_NEWANIMALSCOST
		elseif self.statName=="constructionCost" then	
			self.product=UniversalProcessKit.FILLTYPE_CONSTRUCTIONCOST
		elseif self.statName=="vehicleRunningCost" then	
			self.product=UniversalProcessKit.FILLTYPE_VEHICLERUNNINGCOST
		elseif self.statName=="propertyMaintenance" then	
			self.product=UniversalProcessKit.FILLTYPE_PROPERTYMAINTANCE
		elseif self.statName=="wagePayment" then	
			self.product=UniversalProcessKit.FILLTYPE_WAGEPAYMENT
		elseif self.statName=="harvestIncome" then	
			self.product=UniversalProcessKit.FILLTYPE_HARVESTINCOME
		elseif self.statName=="missionIncome" then	
			self.product=UniversalProcessKit.FILLTYPE_MISSIONINCOME
		elseif self.statName=="loanInterest" then	
			self.product=UniversalProcessKit.FILLTYPE_LOANINTEREST
		end	
	end

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
	
	self.dtsum=0
	
	self:printFn('UPK_Processor:new done')
	
	return self
end

function UPK_Processor:delete()
	self:printFn('UPK_Processor:delete()')
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
	self:printFn('UPK_Processor:loadExtraNodes(',xmlFile,', ',key,')')
	self.bufferedProducts = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#bufferedProducts"),0)
	self.currentInterval = Utils.getNoNil(getXMLInt(xmlFile, key .. "#currentInterval"),1)
	return true
end

function UPK_Processor:getSaveExtraNodes(nodeIdent)
	self:printFn('UPK_Processor:getSaveExtraNodes(',nodeIdent,')')
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
	self:printFn('UPK_Processor:dayChanged()')
	if self:canProduce(true) then
		self:produce(self.productsPerDay)
	else
		self:productionSkipped()
	end
end

function UPK_Processor:hourChanged()
	self:printFn('UPK_Processor:hourChanged()')
	if self:canProduce() then
		self:produce(self.productsPerHour)
	else
		self:productionSkipped()
	end
end

function UPK_Processor:minuteChanged()
	self:printFn('UPK_Processor:minuteChanged()')
	if self:canProduce() then
		self:produce(self.productsPerMinute)
	else
		self:productionSkipped()
	end
end

function UPK_Processor:secondChanged()
	self:printFn('UPK_Processor:secondChanged()')
	if self:canProduce() then
		self:produce(self.productsPerSecond)
	else
		self:productionSkipped()
	end
end

function UPK_Processor:canProduce(ignoreProductionHours)
	self:printFn('UPK_Processor:canProduce(',ignoreProductionHours,')')
	if self.productionHours[g_currentMission.environment.currentHour] or ignoreProductionHours then
		local produce=self.productionProbability==1
		if not produce then
			local rnr = mathrandom()
			produce = rnr<=self.productionProbability
			self:printAll('random number: ',rnr,' is smaller than pprb ',round(self.productionProbability,8),'? ',produce)
		end
		if self.productionInterval>1 then
			self.currentInterval = self.currentInterval % self.productionInterval + 1
			self:printAll('self.currentInterval = ',self.currentInterval)
		end
		if produce and self.currentInterval==1 then
			return true
		end
	end
	return false
end

function UPK_Processor:produce(processed)
	self:printFn('UPK_Processor:produce(',processed,')')
	if self.isServer and self.isEnabled then
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
		local finalProducts=0
		processed=mathmin(processed,self:getCapacity(self.product)-self:getFillLevel(self.product))
		if round(processed,8)>0 then
			if self.hasRecipe then
				for k,v in pairs(self.recipe) do
					if type(v)=="number" and v>0 then
						processed=mathmin(processed,self:getFillLevel(k)/v or 0)
					end
				end
				self:addFillLevels(self.recipe*processed)
			end
			-- deal with the produced outcome
			self.bufferedProducts=self.bufferedProducts+processed
			
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
		end
		
		if round(finalProducts,8)>0 then
			local added = self:addFillLevel(finalProducts,self.product)
			self:printAll('finalProducts: ',finalProducts,', added: ',added)
			if self.hasByproducts then
				self:addFillLevels(self.byproducts*finalProducts)
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
			if self.hasRemoveIfProcessing then
				for k,v in pairs(self.removeIfProcessing) do
					if type(v)=="number" and v>0 then
						self:addFillLevel(-v,k)
					end
				end
			end
			
			-- en/disableChildrenIfProcessing
			if self.enableChildrenIfProcessing then
				self:printAll('enable children')
				self:setEnableChildren(true)
			end
			if self.disableChildrenIfProcessing then
				self:printAll('disable children')
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
			if self.hasRemoveIfNotProcessing then
				for k,v in pairs(self.removeIfNotProcessing) do
					if type(v)=="number" and v>0 then
						self:addFillLevel(-v,k)
					end
				end
			end
			
			-- en/disableChildrenIfNotProcessing
			if self.enableChildrenIfNotProcessing then
				self:printAll('enable children')
				self:setEnableChildren(true)
			end
			if self.disableChildrenIfNotProcessing then
				self:printAll('disable children')
				self:setEnableChildren(false)
			end
		end
	end
end

function UPK_Processor:productionSkipped()
	for _,v in pairs(self.emptyFillTypesIfProductionSkipped) do
		self:setFillLevel(0,v)
	end

	if self.hasAddIfProductionSkipped then
		for k,v in pairs(self.addIfProductionSkipped) do
			if type(v)=="number" and v>0 then
				self:addFillLevel(v,k)
			end
		end
	end
	
	if self.hasRemoveIfProductionSkipped then
		for k,v in pairs(self.removeIfProductionSkipped) do
			if type(v)=="number" and v>0 then
				self:addFillLevel(-v,k)
			end
		end
	end

	-- en/disableChildrenIfProductionSkipped
	if self.enableChildrenIfProductionSkipped then
		self:printAll('enable children')
		self:setEnableChildren(true)
	end
	if self.disableChildrenIfProductionSkipped then
		self:printAll('disable children')
		self:setEnableChildren(false)
	end
end
