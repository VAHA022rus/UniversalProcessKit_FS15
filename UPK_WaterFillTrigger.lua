-- by mor2000

--------------------
-- UPK_WaterFillTrigger (fills trailers and/or shovels with specific fillType)

local UPK_WaterFillTrigger_mt = ClassUPK(UPK_WaterFillTrigger,UniversalProcessKit)
InitObjectClass(UPK_WaterFillTrigger, "UPK_WaterFillTrigger")
UniversalProcessKit.addModule("waterfilltrigger",UPK_WaterFillTrigger)

function UPK_WaterFillTrigger:new(id, parent)
	local self = UniversalProcessKit:new(id, parent, UPK_WaterFillTrigger_mt)
	registerObjectClassName(self, "UPK_WaterFillTrigger")
	
	self.fillFillType = UniversalProcessKit.FILLTYPE_WATER
	
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
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_WATERTRAILER] = getBoolFromUserAttribute(self.nodeId, "allowWaterTrailer", true)
	
	self.allowWalker = false
	
	self:addTrigger()
	
	self:print('loaded WaterFillTrigger successfully')
	
    return self
end

function UPK_WaterFillTrigger:delete()
	UPK_WaterFillTrigger:superClass().delete(self)
end

function UPK_WaterFillTrigger:triggerUpdate(vehicle,isInTrigger)
	--self:print('UPK_WaterFillTrigger:triggerUpdate('..tostring(vehicle)..', '..tostring(isInTrigger)..')')
	if self.isEnabled and self.isClient then
		if self.allowedVehicles[UniversalProcessKit.VEHICLE_WATERTRAILER] and UniversalProcessKit.isVehicleType(vehicle, UniversalProcessKit.VEHICLE_WATERTRAILER) then
			--self:print('recognized water trailer')
			if isInTrigger then
				--self:print('is in trigger')
				if vehicle.addWaterTrailerFillTrigger~=nil and not vehicle.upk_waterFillTriggerAdded then
					--self:print('adding trigger')
					vehicle:addWaterTrailerFillTrigger(self)
					vehicle.upk_waterFillTriggerAdded = true
				end
			else
				if vehicle.removeWaterTrailerFillTrigger~=nil then
					--self:print('removing trigger')
					vehicle:removeWaterTrailerFillTrigger(self)
					vehicle.upk_waterFillTriggerAdded = false
				end
			end
		end
	end
end

UPK_WaterFillTrigger.getFillLevel = UPK_FillTrigger.getFillLevel
UPK_WaterFillTrigger.fillWater = UPK_FillTrigger.fillTrailer
UPK_WaterFillTrigger.getIsActivatable = UPK_FillTrigger.getIsActivatable

