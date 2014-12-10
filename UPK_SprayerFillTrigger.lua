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

UPK_SprayerFillTrigger.getFillLevel = UPK_FillTrigger.getFillLevel
UPK_SprayerFillTrigger.fill = UPK_FillTrigger.fillTrailer
UPK_SprayerFillTrigger.getIsActivatable = UPK_FillTrigger.getIsActivatable

