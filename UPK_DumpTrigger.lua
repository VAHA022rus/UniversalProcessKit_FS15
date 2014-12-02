-- by mor2000

-- DumpTrigger (for dumping stuff out of shovels and combines)

local UPK_DumpTrigger_mt = ClassUPK(UPK_DumpTrigger,UniversalProcessKit)
InitObjectClass(UPK_DumpTrigger, "UPK_DumpTrigger")
UniversalProcessKit.addModule("dumptrigger",UPK_DumpTrigger)

function UPK_DumpTrigger:new(id, parent)
	local self = UniversalProcessKit:new(id, parent, UPK_DumpTrigger_mt)
	registerObjectClassName(self, "UPK_DumpTrigger")

	-- acceptedFillTypes
	
	self.acceptedFillTypes = {}
	
	local acceptedFillTypesArr = getArrayFromUserAttribute(id, "acceptedFillTypes")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(acceptedFillTypesArr)) do
		self:print('accepting '..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(fillType)..')')
		self.acceptedFillTypes[fillType] = true
		--self.fillTypesConversionMatrix = self.fillTypesConversionMatrix + FillTypesConversionMatrix:new(fillType)
	end
	
	-- revenues
	
	self.revenuePerLiter = getNumberFromUserAttribute(id, "revenuePerLiter", 0)
	self.revenuesPerLiter = {}
		
	local revenuesPerLiterArr = getArrayFromUserAttribute(id, "revenuesPerLiter")
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
	
	-- dummies for combines
	
	self.fillRootNode=id
	self.exactFillRootNode=id
	self.fillAutoAimTargetNode=id
	self.exactFillRootNode=id
	self.allowFillFromAir=true
	g_currentMission.nodeToVehicle[id]=self -- combines
	g_currentMission.objectToTrailer[id]=self -- trailers

	-- check collision mask
	
	local collisionMask_old = getCollisionMask(id)
	local collisionMask_new = collisionMask_old
	
	local trigger_fillable = 8388608
	if bitAND(collisionMask_new,trigger_fillable)==0 then
		self:print('Warning: the dumptrigger shape has to be have the collision mask of a fillable object (fixed)')
		collisionMask_new = collisionMask_new + trigger_fillable
	end
	
	if collisionMask_new ~= collisionMask_old then
		self:print('Warning: set collisionMask to '..tostring(collisionMask_new)..' (you may want to fix that)')
		setCollisionMask(id,collisionMask_new)
	end
	
	self:print('loaded DumpTrigger successfully')

	return self
end

function UPK_DumpTrigger:delete()
	g_currentMission.nodeToVehicle[self.nodeId]=nil
	g_currentMission.objectToTrailer[self.nodeId]=nil
	UPK_DumpTrigger:superClass().delete(self)
end

function UPK_DumpTrigger:getAllowFillFromAir()
	--self:print('UPK_DumpTrigger:getAllowFillFromAir')
	return self.isEnabled
end

function UPK_DumpTrigger:getIsAttachedTo(combine)
	return false
end

function UPK_DumpTrigger:allowFillType(fillType, allowEmptying) -- also check for capacity
	self:print('UPK_DumpTrigger:allowFillType('..tostring(fillType)..', '..tostring(allowEmptying)..')')
	if fillType~=nil then
		newFillType=self.fillTypesConversionMatrix[Fillable.FILLTYPE_UNKNOWN][fillType] or fillType
		if UniversalProcessKit.isSpecialFillType(newFillType) then
			return true
		elseif self.storageType==UPK_Storage.SEPARATE then
			local flb=self.p_flbs[newFillType]
			if flb~=nil then
				return flb.fillLevel < flb.capacity
			else
				if self.parent~=nil then
					self:print('asking parent')
					return self.parent:allowFillType(fillType, allowEmptying)
				end
			end
		elseif self.storageType==UPK_Storage.SINGLE or self.storageType==UPK_Storage.FIFO or self.storageType==UPK_Storage.FILO then
			return self.fillLevel < self.capacity
		end
	end
	return false
end

function UPK_DumpTrigger:getAllowShovelFillType(fillType)
	return self.isEnabled and self:allowFillType(fillType)
end

function UPK_DumpTrigger:resetFillLevelIfNeeded(fillType)
	self.interestedInFillType = fillType
end

function UPK_DumpTrigger:setFillLevel(newFillLevel, fillType)
	--self:print('UPK_DumpTrigger:setFillLevel('..tostring(newFillLevel)..', '..tostring(fillType)..')')
	local oldFillLevel = self:getFillLevel(fillType)
	local deltaFillLevel = newFillLevel - oldFillLevel
	
	if deltaFillLevel~=0 and self.revenuesPerLiter[fillType]~=0 then
		local revenue = deltaFillLevel * self.revenuesPerLiter[fillType]
		g_currentMission:addSharedMoney(revenue, self.statName)
	end
	
	local ret = self:addFillLevel(deltaFillLevel, fillType)
	self.interestedInFillType = nil
	return ret
end
