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
	
	-- add/ remove if dumping
	
	self.addIfDumping = {}
	self.useAddIfDumping = false
	local addIfDumpingArr = getArrayFromUserAttribute(nodeId, "addIfDumping")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(addIfDumpingArr)) do
		self:printAll('add if dumping '..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(fillType)..')')
		self.addIfDumping[fillType] = true
		self.useAddIfDumping = true
	end
	
	self.removeIfDumping = {}
	self.useRemoveIfDumping = false
	local removeIfDumpingArr = getArrayFromUserAttribute(nodeId, "removeIfDumping")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(removeIfDumpingArr)) do
		self:printAll('remove if dumping '..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(fillType)..')')
		self.removeIfDumping[fillType] = true
		self.useRemoveIfDumping = true
	end
	
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
	self.exactFillRootNode = nodeId
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
		self:printInfo('Warning: set collisionMask to '..tostring(collisionMask_new)..' (you may want to fix that)')
		setCollisionMask(nodeId,collisionMask_new)
	end
	
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

function UPK_DumpTrigger:getAllowShovelFillType(fillType)
	self:printFn('UPK_DumpTrigger:getAllowShovelFillType(',fillType,')')
	return self.isEnabled and self:allowFillType(fillType)
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
		if self.useAddIfDumping then
			for fillTypeToAdd,v in pairs(self.addIfDumping) do
				if v then
					self:addFillLevel(deltaFillLevel,fillTypeToAdd)
				end
			end
		end
		if self.useRemoveIfDumping then
			for fillTypeToRemove,v in pairs(self.removeIfDumping) do
				if v then
					self:addFillLevel(-deltaFillLevel,fillTypeToRemove)
				end
			end
		end
	end

	return deltaFillLevel
end


