-- by mor2000

-- DumpTrigger (for dumping stuff out of shovels and combines)

local UPK_DumpTrigger_mt = ClassUPK(UPK_DumpTrigger,UniversalProcessKit)
InitObjectClass(UPK_DumpTrigger, "UPK_DumpTrigger")
UniversalProcessKit.addModule("dumptrigger",UPK_DumpTrigger)

function UPK_DumpTrigger:new(nodeId, parent)
	printFn('UPK_DumpTrigger:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId, parent, UPK_DumpTrigger_mt)
	registerObjectClassName(self, "UPK_DumpTrigger")

	-- acceptedFillTypes
	
	self.acceptedFillTypes = {}
	
	local acceptedFillTypesArr = getArrayFromUserAttribute(nodeId, "acceptedFillTypes")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(acceptedFillTypesArr)) do
		self:printInfo('accepting '..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(fillType)..')')
		self.acceptedFillTypes[fillType] = true
		--self.fillTypesConversionMatrix = self.fillTypesConversionMatrix + FillTypesConversionMatrix:new(fillType)
	end
	
	-- texts

	-- need test which shovel unloads
	self.showNotAcceptedWarning = getBoolFromUserAttribute(nodeId, "showNotAcceptedWarning", false)
	self.showCapacityReachedWarning = getBoolFromUserAttribute(nodeId, "showCapacityReachedWarning", false)
	
	-- revenues
	
	self.revenuePerLiter = getNumberFromUserAttribute(nodeId, "revenuePerLiter", 0)
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
	
	self.preferMapDefaultRevenue = getBoolFromUserAttribute(nodeId, "preferMapDefaultRevenue", false)
	self.revenuePerLiterMultiplier = getVectorFromUserAttribute(nodeId, "revenuePerLiterMultiplier", "1 0.5 0.25")
	self.revenuesPerLiterAdjusted = {}
	
	self.statName=getStatNameFromUserAttribute(nodeId)
	
	-- dummies for combines
	
	self.fillRootNode = nodeId
	self.exactFillRootNode = nodeId
	self.fillAutoAimTargetNode = nodeId
	
	self.allowFillFromAir=true
	g_currentMission.nodeToVehicle[nodeId]=self -- combines
	g_currentMission.objectToTrailer[nodeId]=self -- trailers

	-- check collision mask
	
	local collisionMask_old = getCollisionMask(nodeId)
	local collisionMask_new = collisionMask_old
	
	local trigger_fillable = 8388608
	if bitAND(collisionMask_new,trigger_fillable)==0 then
		self:printInfo('Warning: the dumptrigger shape has to have the collision mask of a fillable object (fixed)')
		collisionMask_new = collisionMask_new + trigger_fillable
	end
	
	if collisionMask_new ~= collisionMask_old then
		self:printInfo('Warning: set collisionMask to ',collisionMask_new,' (you may want to fix that)')
		setCollisionMask(nodeId,collisionMask_new)
	end
	
	-- rigid body type
	
	if getRigidBodyType(nodeId)=="Static" then
		setRigidBodyType(nodeId,"Kinematic")
		self:printInfo('Warning: set rigid body type to kinematic (you may want to fix that)')
	end
	
	-- actions
	self:getActionUserAttributes('IfDumping')
	UniversalProcessKit.syncActionThruStream('IfDumping')
	self:getActionUserAttributes('IfDumpingStarted')
	self:getActionUserAttributes('IfDumpingStopped')
	
	-- timer
	self.isBeingFilledTimerId=nil
	
	self:printFn('UPK_DumpTrigger:new done')

	return self
end

function UPK_DumpTrigger:delete()
	self:printFn('UPK_DumpTrigger:delete()')
	g_currentMission.nodeToVehicle[self.nodeId]=nil
	g_currentMission.objectToTrailer[self.nodeId]=nil
	UPK_DumpTrigger:superClass().delete(self)
end

function UPK_DumpTrigger:getAllowFillFromAir()
	self:printFn('UPK_DumpTrigger:getAllowFillFromAir()')
	return self.isEnabled
end

function UPK_DumpTrigger:getIsAttachedTo(combine)
	self:printFn('UPK_DumpTrigger:getIsAttachedTo(',combine,')')
	return false
end

function UPK_DumpTrigger:allowFillType(fillType, allowEmptying) -- also check for capacity
	self:printFn('UPK_DumpTrigger:allowFillType(',fillType,', ',allowEmptying,')')
	if not self.acceptedFillTypes[fillType] then
		if self.showNotAcceptedWarning then
			local blinkinWarningText = ""
			local fillTypeName = self.i18n[UniversalProcessKit.fillTypeIntToName[fillType]]
			if string.find(self.i18n["notAcceptedHere"], "%%s")~=nil then
				blinkinWarningText = string.format(self.i18n["notAcceptedHere"], fillTypeName)
			else
				blinkinWarningText = fillTypeName..' '..self.i18n["notAcceptedHere"] -- standard: use filltype name in front
			end
			UniversalProcessKitListener.showBlinkingWarning(blinkinWarningText)
		end
		return false
	end
	local flbs = self:getFillLevelBubbleShellFromFillType(fillType)
	local fillLevel = flbs:getFillLevel(fillType)
	local capacity = flbs:getCapacity(fillType)
	self:printAll('fillLevel ',fillLevel)
	self:printAll('capacity ',capacity)
	if fillLevel >= capacity then
		if self.showCapacityReachedWarning then
			local blinkinWarningText = ""
			if string.find(self.i18n["capacityReached"], "%%s")~=nil then
				local fillTypeName = self.i18n[UniversalProcessKit.fillTypeIntToName[fillType]]
				blinkinWarningText = string.format(self.i18n["capacityReached"], fillTypeName)
			else
				blinkinWarningText = self.i18n["capacityReached"] -- use no specific filltype name
			end
			UniversalProcessKitListener.showBlinkingWarning(blinkinWarningText)
		end
		return false
	end
	return true
end

function UPK_DumpTrigger:getAllowShovelFillType(fillType)
	self:printFn('UPK_DumpTrigger:getAllowShovelFillType(',fillType,')')
	if not self.isEnabled then
		return false
	end
	local isAllowed = self:allowFillType(fillType)
	if not isAllowed then
		return false
	end
	
	return true
end

function UPK_DumpTrigger:resetFillLevelIfNeeded(fillType)
	self:printFn('UPK_DumpTrigger:resetFillLevelIfNeeded(',fillType,')')
	self.interestedInFillType = fillType
end

UPK_DumpTrigger.getRevenuePerLiter = UPK_TipTrigger.getRevenuePerLiter

function UPK_DumpTrigger:setFillLevel(newFillLevel, fillType)
	self:printFn('UPK_DumpTrigger:setFillLevel(',newFillLevel,', ',fillType,')')
	local oldFillLevel = self:getFillLevel(fillType)
	local deltaFillLevel = self:addFillLevel(newFillLevel - oldFillLevel, fillType)
	self.interestedInFillType = nil
	
	local revenuePerLiter = self:getRevenuePerLiter(fillType)
	if deltaFillLevel~=0 then
		if revenuePerLiter~=0 then
			local revenue = deltaFillLevel * revenuePerLiter
			g_currentMission:addSharedMoney(revenue, self.statName)
		end
		if self.isBeingFilledTimerId==nil then
			self:operateAction('IfDumpingStarted')
		end
		self.isBeingFilledTimerId=reviveTimer(self.isBeingFilledTimerId,500,"timerCallback",self) -- half second delay to recognize if still being filled
		self:operateAction('IfDumping',deltaFillLevel)
	end

	return deltaFillLevel
end

function UPK_DumpTrigger:timerCallback()
	self:operateAction('IfDumpingStopped')
	self.isBeingFilledTimerId=nil
	return false
end

