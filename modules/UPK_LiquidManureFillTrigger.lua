-- by mor2000

--------------------
-- UPK_LiquidManureFillTrigger (fills trailers and/or shovels with specific fillType)

local UPK_LiquidManureFillTrigger_mt = ClassUPK(UPK_LiquidManureFillTrigger,UniversalProcessKit)
InitObjectClass(UPK_LiquidManureFillTrigger, "UPK_LiquidManureFillTrigger")
UniversalProcessKit.addModule("liquidmanurefilltrigger",UPK_LiquidManureFillTrigger)

function UPK_LiquidManureFillTrigger:new(nodeId, parent)
	printFn('UPK_LiquidManureFillTrigger:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId, parent, UPK_LiquidManureFillTrigger_mt)
	registerObjectClassName(self, "UPK_LiquidManureFillTrigger")
	
	self.fillFillType = UniversalProcessKit.FILLTYPE_LIQUIDMANURE
	
    self.createFillType = getBoolFromUserAttribute(nodeId, "createFillType", false)
    self.pricePerLiter = getNumberFromUserAttribute(nodeId, "pricePerLiter", 0)

	self.preferMapDefaultPrice = getBoolFromUserAttribute(nodeId, "preferMapDefaultPrice", false)
	self.pricePerLiterMultiplier = getVectorFromUserAttribute(nodeId, "pricePerLiterMultiplier", "1 1 1")
	self.pricesPerLiter = {}

	self.fillOnlyWholeNumbers = getBoolFromUserAttribute(nodeId, "fillOnlyWholeNumbers", false)
	self.amountToFillOfVehicle = {}
	
	-- add/ remove if filling
	
	self.addIfFilling = {}
	self.useAddIfFilling = false
	local addIfFillingArr = getArrayFromUserAttribute(nodeId, "addIfFilling")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(addIfFillingArr)) do
		self:printInfo('add if filling '..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(fillType)..')')
		self.addIfFilling[fillType] = true
		self.useAddIfFilling = true
	end
	
	self.removeIfFilling = {}
	self.useRemoveIfFilling = false
	local removeIfFillingArr = getArrayFromUserAttribute(nodeId, "removeIfFilling")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(removeIfFillingArr)) do
		self:printInfo('remove if filling '..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(fillType)..')')
		self.removeIfFilling[fillType] = true
		self.useRemoveIfFilling = true
	end
	
	-- statName
	
	self.statName=getStatNameFromUserAttribute(nodeId)

	self.allowedVehicles={}
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER] = getBoolFromUserAttribute(nodeId, "allowLiquidManureTrailer", true)
	
	self.allowWalker = false
	
	self:addTrigger()
	
	self:printFn('UPK_LiquidManureFillTrigger:now done')
	
    return self
end

function UPK_LiquidManureFillTrigger:delete()
	self:printFn('UPK_LiquidManureFillTrigger:delete()')
	UPK_LiquidManureFillTrigger:superClass().delete(self)
end

function UPK_LiquidManureFillTrigger:triggerUpdate(vehicle,isInTrigger)
	self:printFn('UPK_LiquidManureFillTrigger:triggerUpdate(',vehicle,', ',isInTrigger,')')
	if self.isEnabled and self.isClient then
		if self.allowedVehicles[UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER] and UniversalProcessKit.isVehicleType(vehicle, UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER) then
			--self:print('recognized liquid manure trailer')
			if isInTrigger then
				--self:print('is in trigger')
				if vehicle.addFillTrigger~=nil and not vehicle.upk_liquidManureFillTriggerAdded then
					self.amountToFillOfVehicle[vehicle]=0
					--self:print('adding trigger')
					vehicle:addFillTrigger(self)
					vehicle.upk_liquidManureFillTriggerAdded = true
				end
			else
				if vehicle.removeFillTrigger~=nil then
					self.amountToFillOfVehicle[vehicle]=nil
					--self:print('removing trigger')
					vehicle:removeFillTrigger(self)
					vehicle.upk_liquidManureFillTriggerAdded = false
				end
			end
		end
	end
end

UPK_LiquidManureFillTrigger.getFillLevel = UPK_FillTrigger.getFillLevel
UPK_LiquidManureFillTrigger.getPricePerLiter = UPK_FillTrigger.getPricePerLiter
UPK_LiquidManureFillTrigger.fill = UPK_FillTrigger.fillTrailer
UPK_LiquidManureFillTrigger.getIsActivatable = UPK_FillTrigger.getIsActivatable


