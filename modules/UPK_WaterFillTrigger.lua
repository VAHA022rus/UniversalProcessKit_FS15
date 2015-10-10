-- by mor2000

--------------------
-- UPK_WaterFillTrigger (fills trailers and/or shovels with specific fillType)

local UPK_WaterFillTrigger_mt = ClassUPK(UPK_WaterFillTrigger,UniversalProcessKit)
InitObjectClass(UPK_WaterFillTrigger, "UPK_WaterFillTrigger")
UniversalProcessKit.addModule("waterfilltrigger",UPK_WaterFillTrigger)

function UPK_WaterFillTrigger:new(id, parent)
	printFn('UPK_WaterFillTrigger:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(id, parent, UPK_WaterFillTrigger_mt)
	registerObjectClassName(self, "UPK_WaterFillTrigger")
	
	self.fillFillType = UniversalProcessKit.FILLTYPE_WATER
	
    self.createFillType = getBoolFromUserAttribute(id, "createFillType", false)
    self.pricePerLiter = getNumberFromUserAttribute(id, "pricePerLiter", 0)

	self.preferMapDefaultPrice = getBoolFromUserAttribute(id, "preferMapDefaultPrice", false)
	self.pricePerLiterMultiplier = getVectorFromUserAttribute(id, "pricePerLiterMultiplier", "1 1 1")
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
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_WATERTRAILER] = getBoolFromUserAttribute(self.nodeId, "allowWaterTrailer", true)
	
	self.allowWalker = false
	
	self:addTrigger()
	
	self:printFn('UPK_WaterFillTrigger:new done')
	
    return self
end

function UPK_WaterFillTrigger:delete()
	self:printFn('UPK_WaterFillTrigger:delete()')
	UPK_WaterFillTrigger:superClass().delete(self)
end

function UPK_WaterFillTrigger:triggerUpdate(vehicle,isInTrigger)
	self:printFn('UPK_WaterFillTrigger:triggerUpdate(',vehicle,', ',isInTrigger,')')
	if self.isEnabled and self.isClient then
		if self.allowedVehicles[UniversalProcessKit.VEHICLE_WATERTRAILER] and UniversalProcessKit.isVehicleType(vehicle, UniversalProcessKit.VEHICLE_WATERTRAILER) then
			--self:print('recognized water trailer')
			if isInTrigger then
				--self:print('is in trigger')
				if vehicle.addWaterTrailerFillTrigger~=nil and not vehicle.upk_waterFillTriggerAdded then
					self.amountToFillOfVehicle[vehicle]=0
					--self:print('adding trigger')
					vehicle:addWaterTrailerFillTrigger(self)
					vehicle.upk_waterFillTriggerAdded = true
				end
			else
				if vehicle.removeWaterTrailerFillTrigger~=nil then
					self.amountToFillOfVehicle[vehicle]=nil
					--self:print('removing trigger')
					vehicle:removeWaterTrailerFillTrigger(self)
					vehicle.upk_waterFillTriggerAdded = false
				end
			end
		end
	end
end

UPK_WaterFillTrigger.getFillLevel = UPK_FillTrigger.getFillLevel
UPK_WaterFillTrigger.getPricePerLiter = UPK_FillTrigger.getPricePerLiter
UPK_WaterFillTrigger.fillWater = UPK_FillTrigger.fillTrailer
UPK_WaterFillTrigger.getIsActivatable = UPK_FillTrigger.getIsActivatable

