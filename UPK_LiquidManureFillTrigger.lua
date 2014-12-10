-- by mor2000

--------------------
-- UPK_LiquidManureFillTrigger (fills trailers and/or shovels with specific fillType)

local UPK_LiquidManureFillTrigger_mt = ClassUPK(UPK_LiquidManureFillTrigger,UniversalProcessKit)
InitObjectClass(UPK_LiquidManureFillTrigger, "UPK_LiquidManureFillTrigger")
UniversalProcessKit.addModule("liquidmanurefilltrigger",UPK_LiquidManureFillTrigger)

function UPK_LiquidManureFillTrigger:new(id, parent)
	local self = UniversalProcessKit:new(id, parent, UPK_LiquidManureFillTrigger_mt)
	registerObjectClassName(self, "UPK_LiquidManureFillTrigger")
	
	self.fillFillType = UniversalProcessKit.FILLTYPE_LIQUIDMANURE
	
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
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER] = getBoolFromUserAttribute(self.nodeId, "allowLiquidManureTrailer", true)
	
	self.allowWalker = false
	
	self:addTrigger()
	
	self:print('loaded LiquidManureFillTrigger successfully')
	
    return self
end

function UPK_LiquidManureFillTrigger:delete()
	UPK_LiquidManureFillTrigger:superClass().delete(self)
end

function UPK_LiquidManureFillTrigger:triggerUpdate(vehicle,isInTrigger)
	--self:print('UPK_LiquidManureFillTrigger:triggerUpdate('..tostring(vehicle)..', '..tostring(isInTrigger)..')')
	if self.isEnabled and self.isServer then
		if self.allowedVehicles[UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER] and UniversalProcessKit.isVehicleType(vehicle, UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER) then
			--self:print('recognized liquid manure trailer')
			if isInTrigger then
				--self:print('is in trigger')
				if vehicle.addFillTrigger~=nil and not vehicle.upk_liquidManureFillTriggerAdded then
					--self:print('adding trigger')
					vehicle:addFillTrigger(self)
					vehicle.upk_liquidManureFillTriggerAdded = true
				end
			else
				if vehicle.removeFillTrigger~=nil then
					--self:print('removing trigger')
					vehicle:removeFillTrigger(self)
					vehicle.upk_liquidManureFillTriggerAdded = false
				end
			end
		end
	end
end

UPK_LiquidManureFillTrigger.getFillLevel = UPK_FillTrigger.getFillLevel
UPK_LiquidManureFillTrigger.fill = UPK_FillTrigger.fillTrailer
UPK_LiquidManureFillTrigger.getIsActivatable = UPK_FillTrigger.getIsActivatable


