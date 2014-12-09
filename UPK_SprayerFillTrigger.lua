-- by mor2000

--------------------
-- UPK_SprayerFillTrigger (fills trailers and/or shovels with specific fillType)

local UPK_SprayerFillTrigger_mt = ClassUPK(UPK_SprayerFillTrigger,UniversalProcessKit)
InitObjectClass(UPK_SprayerFillTrigger, "UPK_SprayerFillTrigger")
UniversalProcessKit.addModule("sprayerfilltrigger",UPK_SprayerFillTrigger)

function UPK_SprayerFillTrigger:new(id, parent)
	local self = UniversalProcessKit:new(id, parent, UPK_SprayerFillTrigger_mt)
	registerObjectClassName(self, "UPK_SprayerFillTrigger")
	
	self.fillFillType = UniversalProcessKit.FILLTYPE_FERTILIZER
	
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
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SPRAYER] = getBoolFromUserAttribute(self.nodeId, "allowSprayer", true)
	
	self.allowWalker = false
	
	self:addTrigger()
	
	self:print('loaded SprayerFillTrigger successfully')
	
    return self
end

function UPK_SprayerFillTrigger:delete()
	UPK_SprayerFillTrigger:superClass().delete(self)
end

function UPK_SprayerFillTrigger:triggerUpdate(vehicle,isInTrigger)
	--self:print('UPK_SprayerFillTrigger:triggerUpdate('..tostring(vehicle)..', '..tostring(isInTrigger)..')')
	if self.isEnabled and self.isServer then
		if self.allowedVehicles[UniversalProcessKit.VEHICLE_SPRAYER] and UniversalProcessKit.isVehicleType(vehicle, UniversalProcessKit.VEHICLE_SPRAYER) then
			--self:print('recognized sprayer')
			if isInTrigger then
				--self:print('is in trigger')
				if vehicle.addFillTrigger~=nil and not vehicle.upk_sprayerFillTriggerAdded then
					--self:print('adding trigger')
					vehicle:addFillTrigger(self)
					vehicle.upk_sprayerFillTriggerAdded = true
				end
			else
				if vehicle.removeFillTrigger~=nil then
					--self:print('removing trigger')
					vehicle:removeFillTrigger(self)
					vehicle.upk_sprayerFillTriggerAdded = false
				end
			end
		end
	end
end

function UPK_SprayerFillTrigger:getFillLevel(fillType)
	--self:print('UPK_SprayerFillTrigger:getFillLevel('..tostring(fillType)..')')
	return UPK_SprayerFillTrigger:superClass().getFillLevel(self, fillType or UniversalProcessKit.FILLTYPE_FERTILIZER) or 0
end

function UPK_SprayerFillTrigger:fill(trailer, deltaFillLevel) -- tippers, shovels etc
	--self:print('UPK_SprayerFillTrigger:fill('..tostring(trailer)..', '..tostring(deltaFillLevel)..')')
	if self.isServer and self.isEnabled then
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

function UPK_SprayerFillTrigger:getIsActivatable(trailer)
	--self:print('trailer:allowFillType(self.fillFillType, false) '..tostring(trailer:allowFillType(self.fillFillType, false)))
	--self:print('self:getFillLevel(self.fillFillType) '..tostring(self:getFillLevel(self.fillFillType)))
	if trailer:allowFillType(self.fillFillType, false) and
		(self:getFillLevel(self.fillFillType)>0 or self.createFillType) then
		return true
	end
	return false
end

