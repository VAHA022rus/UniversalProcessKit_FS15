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
	
	self.revenuePerLiter = getNumberFromUserAttribute(nodeId, "revenuePerLiter", nil)
	self.revenuesPerLiter = {} -- just woodChips
	local revenues_mt = {
		__index=function(t,k)
			return self.revenuePerLiter
		end
	}
	setmetatable(self.revenuesPerLiter,revenues_mt)
	
	self.ignoreWood = getNumberFromUserAttribute(nodeId, "ignoreWood", 0)
	self.useFirstWood = getBoolFromUserAttribute(nodeId, "useFirstWood", true)
	
	-- length
	self.useLength = false
	self.acceptedMinLength = getNumberFromUserAttribute(nodeId, "acceptedMinLength", 0, 0, 999)
	self.acceptedMaxLength = getNumberFromUserAttribute(nodeId, "acceptedMaxLength", 999, self.acceptedMinLength, 999)
	if self.acceptedMinLength>0 or self.acceptedMaxLength<999 then
		self.useLength = true
	end
		
	
	self.delay = getNumberFromUserAttribute(nodeId, "delay", 0.1, 0)*1000
	
	self.allowWood = true
	self.allowWalker = false
	self.allowedVehicles={}
	
	self.woodInTrigger = {}
	self.nrWoodInTrigger = 0
	
	self.mode = getStringFromUserAttribute(nodeId, "mode", "sell")
	
	self.revenueMultiplier = getVectorFromUserAttribute(nodeId, "revenueMultiplier", "1 1 1")
	
	self.statName=getStatNameFromUserAttribute(nodeId,"harvestIncome")
	
	self.woodInLine = {}
	self.runningUpdate = false

	self:addTrigger()
	
	--actions
	self:getActionUserAttributes('OnEnter')
	self:getActionUserAttributes('OnLeave')
	self:getActionUserAttributes('OnDelete')
	
	self:getActionUserAttributes('IfDissolved')
	self:getActionUserAttributes('IfSold')
	
	
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
end

function UPK_WoodTrigger:triggerUpdate(woodId,isInTrigger)
	self:printFn('UPK_WoodTrigger:triggerUpdate(',woodId,', ',isInTrigger,')')
	if self.isEnabled and woodId~=nil then
		self:printAll('wood is: '..tostring(woodId))
		self:printAll('isInTrigger is: '..tostring(isInTrigger))
		if isInTrigger then
			-- length
			if self.useLength then
				local lenX, lenY, lenZ, _ = getSplitShapeStats(woodId)
				local length = mathmax(lenX,mathmax(lenY, lenZ))
				self:printInfo('length of wood is ',length)
				if length<self.acceptedMinLength or length>self.acceptedMaxLength then
					return
				end
			end

			self.woodInTrigger[woodId]=true
			self.nrWoodInTrigger = self.nrWoodInTrigger +1
			table.insert(self.woodInLine,woodId)
			if not self.runningUpdate and self.nrWoodInTrigger>self.ignoreWood then
				self.dtsum = 0
				if self.isServer then
					UniversalProcessKitListener.addUpdateable(self)
				end
			end
			self:operateAction('OnEnter')
		else
			if self.woodInTrigger[woodId]~=nil then
				self.woodInTrigger[woodId]=nil
				self.nrWoodInTrigger = self.nrWoodInTrigger -1
				self:operateAction('OnLeave')
			end
		end
	end
end

function UPK_WoodTrigger:update(dt)
	self:printFn('UPK_WoodTrigger:update(',dt,')')
	self.dtsum = self.dtsum + dt
	
	if self.dtsum>self.delay then
		self.dtsum = self.dtsum-self.delay
		
		if self.isServer then
			
			if #self.woodInLine>self.ignoreWood then
				local woodIndex = 1
				if not self.useFirstWood then
					woodIndex = #self.woodInLine
				end

				local woodId = self.woodInLine[woodIndex]
				if type(woodId)=="number" and woodId>0 and self.woodInTrigger[woodId] then
					local fillLevel = getVolume(woodId)*1000
					local splitType = SplitUtil.splitTypes[getSplitType(woodId)]
					local fillType = UniversalProcessKit.FILLTYPE_WOODCHIPS
					
					self:printAll('fillLevel of wood is ',fillLevel)
					if self.mode=="dissolve" then
						local added = self:addFillLevel(fillLevel*splitType.woodChipsPerLiter, fillType)
						self:operateAction('IfDissolved',added)
						self:deleteWood(woodId)
					elseif self.mode=="delete" then
						self:deleteWood(woodId)
					elseif self.mode=="save" then
						-- nothing yet
					else
						local difficulty = g_currentMission.missionStats.difficulty
						local revenue = 0
						if self.revenuesPerLiter[fillType]~=nil then
							revenue = self.revenuesPerLiter[fillType] * fillLevel * self.revenueMultiplier[difficulty]
						else
							revenue = fillLevel * splitType.pricePerLiter * self.revenueMultiplier[difficulty]
						end
						if revenue~=0 then
							g_currentMission:addSharedMoney(revenue, self.statName)
						end
						self:operateAction('IfSold',fillLevel)
						self:deleteWood(woodId)
					end
				else
					self.woodInTrigger[woodId]=nil
					table.remove(self.woodInLine,woodIndex)
					self.nrWoodInTrigger = self.nrWoodInTrigger -1
				end
			end
		end
		
		if #self.woodInLine<=self.ignoreWood then
			self.runningUpdate = false
			UniversalProcessKitListener.removeUpdateable(self)
		else
			if self.dtsum>self.delay then
				self:update(0)
			end
		end
	end
end

function UPK_WoodTrigger:deleteWood(woodId)
	self:printFn('UPK_WoodTrigger:deleteWood(',woodId,')')
	self.woodInTrigger[woodId]=nil
	table.remove(self.woodInLine,woodIndex)
	self.nrWoodInTrigger = self.nrWoodInTrigger -1
	delete(woodId)
	self:operateAction('OnDelete')
end