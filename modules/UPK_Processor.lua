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
	
	-- productionDays
	self.productionDays={}
	local productionDaysStrings = getStringFromUserAttribute(nodeId, "productionDays", "0-6") -- mon - sun
	local productionDaysStringArr = Utils.splitString(",",productionDaysStrings)
	for _,v in pairs(productionDaysStringArr) do
		self:printAll(v)
		local productionDaysArr = Utils.splitString("-",v)
		local lowerDay = mathmin(mathmax(tonumber(productionDaysArr[1]),0),6)
		local upperDay = mathmin(mathmax(tonumber(productionDaysArr[2]),lowerDay),6)
		if lowerDay~=nil and upperDay~=nil then
			for i=lowerDay,upperDay do
				self:printInfo('produce sth at day ',i)
				self.productionDays[i]=true
			end
		end
	end
	
	self.productionInterval = getNumberFromUserAttribute(nodeId, "productionInterval", 1, 1)
	self.currentInterval = self.productionInterval

	-- productionThreshold
	self.productionThreshold={}
	self.hasProductionThreshold=false
	local thresholdArr=getArrayFromUserAttribute(nodeId, "productionThreshold")
	for i=1,#thresholdArr,2 do
		local amount=tonumber(thresholdArr[i])
		local type=unpack(UniversalProcessKit.fillTypeNameToInt(thresholdArr[i+1]))
		self:printInfo('productionThreshold: ',amount,' of ',thresholdArr[i+1],' (',type,')')
		if amount~=nil and type~=nil then
			self.productionThreshold[type]=amount
			self.hasProductionThreshold=true
		end
	end
	
	-- productionThreshold
	
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
	
	self.delayedOutput=getBoolFromUserAttribute(nodeId, "delayedOutput", false)
	self.delayedProducts=0
	
	self.bufferedProducts = 0
	
	self.hasRecipe=false
	self.recipe=__c()
	local recipeArr=getArrayFromUserAttribute(nodeId, "recipe")
	self:printInfo('length of recipe is ',#recipeArr)
	for i=1,#recipeArr,2 do
		local amount=tonumber(recipeArr[i])
		local fillType=unpack(UniversalProcessKit.fillTypeNameToInt(recipeArr[i+1]))
		if type(amount)=="number" and type(fillType)=="number" then
			self:printInfo('adding ',amount,' of ',fillType,' to recipe')
			self.recipe[fillType]=-amount
			self:printInfo('self.recipe[',fillType,'] is ',self.recipe[fillType])
			self.hasRecipe=true
		end
	end
	
	self.hasByproducts=false
	self.byproducts=__c()
	local byproductsArr=getArrayFromUserAttribute(nodeId, "byproducts")
	for i=1,#byproductsArr,2 do
		local amount=tonumber(byproductsArr[i])
		local fillType=unpack(UniversalProcessKit.fillTypeNameToInt(byproductsArr[i+1]))
		self:printInfo('found byproduct to produce ',amount,' ',fillType)
		if type(amount)=="number" and type(fillType)=="number" then
			self.byproducts[fillType]=amount
			self.hasByproducts=true
		end
	end
	
	-- byproducts
	
	local byproducts=getStringFromUserAttribute(nodeId, "byproducts", "")
	local addIfProduced=getStringFromUserAttribute(nodeId, "addIfProduced", "")
	setUserAttribute(nodeId,"addIfProduced","String",addIfProduced.." "..byproducts)
	self:printInfo('set addIfProduced to "',addIfProduced.." "..byproducts,'"')
	
	-- actions
	
	self:getActionUserAttributes('IfProduced')
	self:getActionUserAttributes('IfProcessing')
	self:getActionUserAttributes('IfNotProcessing')
	self:getActionUserAttributes('IfProductionSkipped')
	self:getActionUserAttributes('IfProductionStarted')
	self:getActionUserAttributes('IfProductionStopped')
	
	self.isProcessing=false

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

function UPK_Processor:postLoad()
	self:printFn('UPK_Processor:postLoad()')
	
	if self.isProcessing then
		self:operateAction('IfProcessing')
	else
		self:operateAction('IfNotProcessing')
	end
	
	UPK_Processor:superClass().postLoad(self)
end;

function UPK_Processor:loadExtraNodes(xmlFile, key)
	self:printFn('UPK_Processor:loadExtraNodes(',xmlFile,', ',key,')')
	self.bufferedProducts = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#bufferedProducts"),0)
	self.currentInterval = Utils.getNoNil(getXMLInt(xmlFile, key .. "#currentInterval"),1)
	self.isProcessing = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isProcessing"),false)
	if self.delayedOutput then
		self.delayedProducts=Utils.getNoNil(getXMLFloat(xmlFile, key .. "#delayedProducts"),0)
	end
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
	if self.delayedOutput then
		nodes=nodes .. " delayedProducts=\""..tostring(self.delayedProducts).."\""
	end
	nodes=nodes .. " isProcessing=\""..tostring(self.isProcessing).."\""
	return nodes
end

function UPK_Processor:dayChanged()
	self:printFn('UPK_Processor:dayChanged()')
	self:timeframeChanged(self.productsPerDay)
end

function UPK_Processor:hourChanged()
	self:printFn('UPK_Processor:hourChanged()')
	self:timeframeChanged(self.productsPerHour)
end

function UPK_Processor:minuteChanged()
	self:printFn('UPK_Processor:minuteChanged()')
	self:timeframeChanged(self.productsPerMinute)
end

function UPK_Processor:secondChanged()
	self:printFn('UPK_Processor:secondChanged()')
	self:timeframeChanged(self.productsPerSecond)
end

function UPK_Processor:timeframeChanged(processed)
	self:printFn('UPK_Processor:timeframeChanged(',processed,')')
	if self.delayedOutput and self.delayedProducts>0 then
		local added = self:addFillLevel(self.delayedProducts,self.product)
		self:operateAction('IfProduced',added)
	end
	if self:canProduce() then
		self:produce(processed)
	else
		self:operateAction('IfProductionSkipped')
		self.isProcessing=false
	end
end

function UPK_Processor:canProduce(ignoreProductionTimes)
	self:printFn('UPK_Processor:canProduce(',ignoreProductionTimes,')')
	
	local passThreshold=true
	if self.hasProductionThreshold then
		for k,v in pairs(self.productionThreshold) do
			self:printInfo('productionThreshold ',k,': ',v)
			if type(v)=="number" and v>0 then
				if self:getFillLevel(k)<v then
					passThreshold=false
					break
				end
			end
		end
	end
	
	if (self.productionHours[g_currentMission.environment.currentHour] and self.productionDays[UniversalProcessKitEnvironment.weekday] and passThreshold) or ignoreProductionTimes then
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
				self:printInfo('productionPrerequisite ',k,': ',v)
				if type(v)=="number" and v>0 then
					if self.onlyWholeProducts then
						self:printInfo('processed=',processed,' min=',mathfloor(self:getFillLevel(k)/v))
						processed=mathmin(processed,mathfloor(self:getFillLevel(k)/v))
					else
						self:printInfo('processed=',processed,' min=',self:getFillLevel(k)/v)
						processed=mathmin(processed,-self:getFillLevel(k)/v)
					end
					if processed==0 then
						break
					end
				end
			end
		end
		local finalProducts=0
		processed=mathmin(processed,self:getCapacity(self.product)-self:getFillLevel(self.product))
		if round(processed,8)>0 then
			self:printInfo('self.hasRecipe is ',self.hasRecipe)
			if self.hasRecipe then
				for k,v in pairs(self.recipe) do
					self:printInfo('recipe has ',v,' of ',k)
					if type(v)=="number" and v<0 then
						self:printInfo('filltype ',k,' has ',self:getFillLevel(k))
						processed=mathmin(processed,-self:getFillLevel(k)/v or 0)
						if processed==0 then
							break
						end
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
			if not self.delayedOutput then
				local added = self:addFillLevel(finalProducts,self.product)
				self:operateAction('IfProduced',added)
			else
				self.delayedProducts=finalProducts
			end
			if not self.isProcessing then
				self:operateAction('IfProductionStarted')
			end
			self:operateAction('IfProcessing')
			self.isProcessing=true
		else
			if self.isProcessing then
				self:operateAction('IfProductionStopped')
			end
			self:operateAction('IfNotProcessing')
			self.isProcessing=false
		end
	end
end
