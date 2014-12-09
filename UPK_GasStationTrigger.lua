-- by mor2000

--------------------
-- UPK_GasStationTrigger (fills trailers and/or shovels with specific fillType)

local UPK_GasStationTrigger_mt = ClassUPK(UPK_GasStationTrigger,UniversalProcessKit)
InitObjectClass(UPK_GasStationTrigger, "UPK_GasStationTrigger")
UniversalProcessKit.addModule("gasstationtrigger",UPK_GasStationTrigger)

function UPK_GasStationTrigger:new(id, parent)
	local self = UniversalProcessKit:new(id, parent, UPK_GasStationTrigger_mt)
	registerObjectClassName(self, "UPK_GasStationTrigger")
	
	self.fillFillType = UniversalProcessKit.FILLTYPE_FUEL
	
    self.createFillType = getBoolFromUserAttribute(id, "createFillType", false)
    self.pricePerLiter = getNumberFromUserAttribute(id, "pricePerLiter", 0)
	
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

	self.allowedVehicles={}
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED] = getBoolFromUserAttribute(self.nodeId, "allowMotorized", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_COMBINE] = getBoolFromUserAttribute(self.nodeId, "allowCombine", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FUELTRAILER] = getBoolFromUserAttribute(self.nodeId, "allowFuelTrailer", true)
	
	self.allowWalker = false
	
	self:addTrigger()
	
	self:print('loaded GasStationTrigger successfully')
	
    return self
end

function UPK_GasStationTrigger:delete()
	UPK_GasStationTrigger:superClass().delete(self)
end

function UPK_GasStationTrigger:triggerUpdate(vehicle,isInTrigger)
	--self:print('UPK_GasStationTrigger:triggerUpdate('..tostring(vehicle)..', '..tostring(isInTrigger)..')')
	if self.isEnabled and self.isServer and vehicle~=nil then
		if isInTrigger then
			--self:print('is in trigger')
			if vehicle.addFuelFillTrigger~=nil and not vehicle.UPK_gasStationTriggerAdded then
				--self:print('adding trigger')
				vehicle:addFuelFillTrigger(self)
				vehicle.UPK_gasStationTriggerAdded = true
			end
		else
			if vehicle.removeFuelFillTrigger~=nil then
				--self:print('removing trigger')
				vehicle:removeFuelFillTrigger(self)
				vehicle.UPK_gasStationTriggerAdded = false
			end
		end
	end
end

function UPK_GasStationTrigger:getFillLevel(fillType)
	--self:print('UPK_GasStationTrigger:getFillLevel('..tostring(fillType)..')')
	return UPK_GasStationTrigger:superClass().getFillLevel(self, fillType or UniversalProcessKit.FILLTYPE_FUEL) or 0
end

function UPK_GasStationTrigger:fillFuel(trailer, deltaFillLevel) -- tippers, shovels etc
	--self:print('UPK_GasStationTrigger:fillFuel('..tostring(trailer)..', '..tostring(deltaFillLevel)..')')
	if self.isServer and self.isEnabled then
		if UniversalProcessKit.isVehicleType(trailer, UniversalProcessKit.VEHICLE_MOTORIZED) then
			return self:fillMotorized(trailer, deltaFillLevel)
		end
		local trailerFillLevel = trailer:getFillLevel(self.fillFillType)
		local fillLevel = self:getFillLevel(self.fillFillType)
		--self:print('fillLevel '..tostring(fillLevel))
		--self:print('trailer:allowFillType(self.fillFillType, false) '..tostring(trailer:allowFillType(self.fillFillType, false)))
		--self:print('trailerFillLevel<trailer.capacity '..tostring(trailerFillLevel<trailer.capacity))
		if (fillLevel>0 or self.createFillType) and trailer:allowFillType(self.fillFillType, false) then
			trailer:resetFillLevelIfNeeded(self.fillFillType)
			if not self.createFillType then
				deltaFillLevel=math.min(deltaFillLevel, fillLevel)
			end
			trailer:setFillLevel(trailerFillLevel + deltaFillLevel, self.fillFillType)
			deltaFillLevel = trailer:getFillLevel(self.fillFillType) - trailerFillLevel
			if deltaFillLevel~=0 then
				if self.pricePerLiter~=0 then
					local price = delta * self.pricePerLiter
					g_currentMission:addSharedMoney(-price, self.statName)
				end
				if not self.createFillType then
					return -self:addFillLevel(-deltaFillLevel,self.fillFillType)
				end
				return deltaFillLevel
			end
		end
	end
	return 0
end

function UPK_GasStationTrigger:fillMotorized(trailer, deltaFillLevel) -- motorized
	--self:print('UPK_GasStationTrigger:fillMotorized('..tostring(trailer)..', '..tostring(deltaFillLevel)..')')
	if self.isServer and self.isEnabled and self.fillFillType==UniversalProcessKit.FILLTYPE_FUEL then
		local trailerFillLevel = trailer.fuelFillLevel
		local fillLevel = self:getFillLevel(self.fillFillType)
		if (fillLevel>0 or self.createFillType) and trailerFillLevel<trailer.fuelCapacity then
			if not self.createFillType then
				deltaFillLevel=math.min(deltaFillLevel, fillLevel)
			end
			trailer:setFuelFillLevel(trailerFillLevel + deltaFillLevel)
			deltaFillLevel = trailer.fuelFillLevel - trailerFillLevel
			if(deltaFillLevel>0 and self.pricePerLiter~=0)then
				local price = delta * self.pricePerLiter
				g_currentMission:addSharedMoney(-price, self.statName)
			end
			if not self.createFillType then
				return -self:addFillLevel(-deltaFillLevel,self.fillFillType)
			end
			return deltaFillLevel
		end
	end
	return 0
end

function UPK_GasStationTrigger:getIsActivatable(trailer)
	--self:print('trailer:allowFillType(self.fillFillType, false) '..tostring(trailer:allowFillType(self.fillFillType, false)))
	--self:print('self:getFillLevel(self.fillFillType) '..tostring(self:getFillLevel(self.fillFillType)))
	if UniversalProcessKit.isVehicleType(trailer, UniversalProcessKit.VEHICLE_MOTORIZED) then
		return (self:getFillLevel(self.fillFillType)>0 or self.createFillType)
	end
	if trailer:allowFillType(self.fillFillType, false) and
		(self:getFillLevel(self.fillFillType)>0 or self.createFillType) then
		return true
	end
	return false
end

