-- by mor2000

--------------------
-- UPK_SprayerFillTrigger (fills trailers and/or shovels with specific fillType)

local UPK_SprayerFillTrigger_mt = ClassUPK(UPK_SprayerFillTrigger,UniversalProcessKit)
InitObjectClass(UPK_SprayerFillTrigger, "UPK_SprayerFillTrigger")
UniversalProcessKit.addModule("sprayerfilltrigger",UPK_SprayerFillTrigger)

function UPK_SprayerFillTrigger:new(nodeId, parent)
	printFn('UPK_SprayerFillTrigger:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId, parent, UPK_SprayerFillTrigger_mt)
	registerObjectClassName(self, "UPK_SprayerFillTrigger")
	
	self.fillFillType = UniversalProcessKit.FILLTYPE_FERTILIZER
	
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
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SPRAYER] = getBoolFromUserAttribute(nodeId, "allowSprayer", true)
	
	self.allowWalker = false
	
	self:addTrigger()
	
	self:printFn('UPK_SprayerFillTrigger:new done')
	
    return self
end

function UPK_SprayerFillTrigger:delete()
	self:printFn('UPK_SprayerFillTrigger:delete()')
	UPK_SprayerFillTrigger:superClass().delete(self)
end

function UPK_SprayerFillTrigger:triggerUpdate(vehicle,isInTrigger)
	self:printFn('UPK_SprayerFillTrigger:triggerUpdate(',vehicle,', ',isInTrigger,')')
	if self.isEnabled and self.isClient then
		if self.allowedVehicles[UniversalProcessKit.VEHICLE_SPRAYER] and UniversalProcessKit.isVehicleType(vehicle, UniversalProcessKit.VEHICLE_SPRAYER) then
			--self:print('recognized sprayer')
			if isInTrigger then
				--self:print('is in trigger')
				if vehicle.addFillTrigger~=nil and not vehicle.upk_sprayerFillTriggerAdded then
					self.amountToFillOfVehicle[vehicle]=0
					--self:print('adding trigger')
					vehicle:addFillTrigger(self)
					vehicle.upk_sprayerFillTriggerAdded = true
				end
			else
				if vehicle.removeFillTrigger~=nil then
					self.amountToFillOfVehicle[vehicle]=nil
					--self:print('removing trigger')
					vehicle:removeFillTrigger(self)
					vehicle.upk_sprayerFillTriggerAdded = false
				end
			end
		end
	end
end

UPK_SprayerFillTrigger.getFillLevel = UPK_FillTrigger.getFillLevel
UPK_SprayerFillTrigger.getPricePerLiter = UPK_FillTrigger.getPricePerLiter
UPK_SprayerFillTrigger.fill = UPK_FillTrigger.fillTrailer
UPK_SprayerFillTrigger.getIsActivatable = UPK_FillTrigger.getIsActivatable

