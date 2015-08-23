-- by mor2000

--------------------
-- WoodTrigger


local UPK_WoodTrigger_mt = ClassUPK(UPK_WoodTrigger,UniversalProcessKit)
InitObjectClass(UPK_WoodTrigger, "UPK_WoodTrigger")
UniversalProcessKit.addModule("woodtrigger",UPK_WoodTrigger)

function UPK_WoodTrigger:new(nodeId, parent)
	printFn('UPK_WoodTrigger:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId, parent, UPK_WoodTrigger_mt)
	registerObjectClassName(self, "UPK_WoodTrigger")
	
	-- acceptedFillTypes
	
	self.acceptedFillTypes = {}
	
	local acceptedFillTypesArr = getArrayFromUserAttribute(nodeId, "acceptedFillTypes")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(acceptedFillTypesArr)) do
		self:printInfo('accepting '..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(fillType)..')')
		self.acceptedFillTypes[fillType] = true
		--self.fillTypesConversionMatrix = self.fillTypesConversionMatrix + FillTypesConversionMatrix:new(fillType)
	end
	
	self.revenuePerLiter = getNumberFromUserAttribute(nodeId, "revenuePerLiter", nil)
	self.revenuesPerLiter = {}
		
	local revenuesPerLiterArr = getArrayFromUserAttribute(nodeId, "revenuesPerLiter")
	for i=1,#revenuesPerLiterArr,2 do
		local revenue=tonumber(revenuesPerLiterArr[i])
		local fillType=unpack(UniversalProcessKit.fillTypeNameToInt(revenuesPerLiterArr[i+1]))
		if revenue~=nil and fillType~=nil then
			self.revenuesPerLiter[fillType] = revenue
		end
	end
	
	local revenues_mt = {
		__index=function(t,k)
			return self.revenuePerLiter
		end
	}
	setmetatable(self.revenuesPerLiter,revenues_mt)
	
	self.ignoreLumber = getNumberFromUserAttribute(nodeId, "ignoreLumber", 0)
	self.useFirstLumber = getBoolFromUserAttribute(nodeId, "useFirstLumber", true)
	
	self.delay = getNumberFromUserAttribute(nodeId, "delay", 0.1, 0)*1000
	
	self.allowLumber = true
	self.allowWalker = false
	self.allowedVehicles={}
	
	self.lumberInTrigger = {}
	self.nrLumberInTrigger = 0
	
	self.mode = getStringFromUserAttribute(nodeId, "mode", "sell")
	
	self.revenueMultiplier = getVectorFromUserAttribute(nodeId, "revenueMultiplier", "1 1 1")
	
	self.statName=getStatNameFromUserAttribute(nodeId)
	
	self.lumberInLine = {}
	self.runningUpdate = false

	self:addTrigger()
	
	self:printFn('UPK_WoodTrigger:new done')
	
	return self
end

function UPK_WoodTrigger:delete()
	self:printFn('UPK_WoodTrigger:delete()')
	UniversalProcessKitListener.removeUpdateable(self)
	UPK_WoodTrigger:superClass().delete(self)
end

function UPK_WoodTrigger:postLoad()
	self:printFn('UPK_WoodTrigger:postLoad()')
	UPK_WoodTrigger:superClass().postLoad(self)
	self:triggerUpdate(false,false)
end

function UPK_WoodTrigger:triggerUpdate(vehicle,isInTrigger)
	self:printFn('UPK_WoodTrigger:triggerUpdate(',vehicle,', ',isInTrigger,')')
	if self.isEnabled then
		self:printAll('vehicle is: '..tostring(vehicle))
		if type(vehicle)=="table" and vehicle:isa(Bale) then
			self:printAll('isInTrigger is: '..tostring(isInTrigger))
			if isInTrigger then
				
			else
				self.lumberInTrigger[vehicle]=nil
				self.nrLumbeInTrigger = self.nrLumberInTrigger -1
			end
		end
	end
end

function UPK_WoodTrigger:update(dt)
	self:printAll('UPK_WoodTrigger:update(',dt,')')
	self.dtsum = self.dtsum + dt
	
	if self.dtsum>self.delay then
		self.dtsum = self.dtsum-self.delay
	
		if #self.lumberInLine>self.ignoreBales then
			local lumberIndex = 1
			if not self.useFirstLumber then
				lumberIndex = #self.lumberInLine
			end

			local lumber = self.lumberInLine[lumberIndex]
			if type(lumber)=="table" and self.balesInTrigger[lumber] then
				if self.mode=="dissolve" then
				    local fillLevel = lumber:getFillLevel()
				    local fillType = lumber:getFillType()
					local added = self:addFillLevel(fillLevel, fillType)
					if added > 0 then
						self.balesInTrigger[lumber]=nil
						table.remove(self.lumberInLine,lumberIndex)
						bale:delete()
					end
				elseif self.mode=="delete" then
					self.balesInTrigger[lumber]=nil
					table.remove(self.lumberInLine,lumberIndex)
					lumber:delete()
				elseif self.mode=="save" then
					-- nothing yet
				else
					self:printAll('want to sell bale for '..tostring(lumber:getValue()))
					self.balesInTrigger[lumber]=nil
					self.nrLumberInTrigger = self.nrLumberInTrigger -1
					local fillType = lumber:getFillType()
					local difficulty = g_currentMission.missionStats.difficulty
					local revenue = 0
					if self.revenuesPerLiter[fillType]~=nil then
						revenue = self.revenuesPerLiter[fillType] * lumber.fillLevel * self.revenueMultiplier[difficulty]
					else 
						revenue = lumber:getValue() * self.revenueMultiplier[difficulty]
					end
					if revenue~=0 then
						g_currentMission:addSharedMoney(revenue, self.statName)
					end
					self.balesInTrigger[lumber]=nil
					table.remove(self.lumberInLine,lumberIndex)
					lumber:delete()
				end
			else
				self.balesInTrigger[lumber]=nil
				table.remove(self.lumberInLine,lumberIndex)
				self:update(0)
			end
		end
	end

	if #self.lumberInLine<=self.ignoreBales then
		self.runningUpdate = false
		UniversalProcessKitListener.removeUpdateable(self)
	else
		if self.dtsum>self.delay then
			self:update(0)
		end
	end
end
