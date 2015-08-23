-- by mor2000

--------------------
-- UPK_SowingMachineFillTrigger (fills sowing machines with seeds)

local UPK_SowingMachineFillTrigger_mt = ClassUPK(UPK_SowingMachineFillTrigger,UniversalProcessKit)
InitObjectClass(UPK_SowingMachineFillTrigger, "UPK_SowingMachineFillTrigger")
UniversalProcessKit.addModule("sowingmachinefilltrigger",UPK_SowingMachineFillTrigger)

function UPK_SowingMachineFillTrigger:new(nodeId, parent)
	printFn('UPK_SowingMachineFillTrigger:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId, parent, UPK_SowingMachineFillTrigger_mt)
	registerObjectClassName(self, "UPK_SowingMachineFillTrigger")
	
	self.fillFillType = UniversalProcessKit.FILLTYPE_SEEDS
	
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
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SOWINGMACHINE] = getBoolFromUserAttribute(nodeId, "allowSowingMachine", true)
	
	self.allowWalker = false
	
	self:addTrigger()
	
	self:printFn('UPK_SowingMachineFillTrigger:new done')
	
    return self
end

function UPK_SowingMachineFillTrigger:delete()
	self:printFn('UPK_SowingMachineFillTrigger:delete()')
	UPK_SowingMachineFillTrigger:superClass().delete(self)
end

function UPK_SowingMachineFillTrigger:triggerUpdate(vehicle,isInTrigger)
	self:printFn('UPK_SowingMachineFillTrigger:triggerUpdate(',vehicle,', ',isInTrigger,')')
	if self.isEnabled and self.isClient then
		if self.allowedVehicles[UniversalProcessKit.VEHICLE_SOWINGMACHINE] and UniversalProcessKit.isVehicleType(vehicle, UniversalProcessKit.VEHICLE_SOWINGMACHINE) then
			--self:print('recognized sprayer')
			if isInTrigger then
				--self:print('is in trigger')
				if vehicle.addFillTrigger~=nil and not vehicle.UPK_SowingMachineFillTriggerAdded then
					self.amountToFillOfVehicle[vehicle]=0
					self:printAll('vehicle:addFillTrigger(self)')
					vehicle:addFillTrigger(self)
					vehicle.UPK_SowingMachineFillTriggerAdded = true
				end
			else
				if vehicle.removeFillTrigger~=nil then
					self.amountToFillOfVehicle[vehicle]=nil
					self:printAll('vehicle:removeFillTrigger(self)')
					vehicle:removeFillTrigger(self)
					vehicle.UPK_SowingMachineFillTriggerAdded = false
				end
			end
		end
	end
end

UPK_SowingMachineFillTrigger.getFillLevel = UPK_FillTrigger.getFillLevel
UPK_SowingMachineFillTrigger.getPricePerLiter = UPK_FillTrigger.getPricePerLiter
UPK_SowingMachineFillTrigger.fill = UPK_FillTrigger.fillTrailer
UPK_SowingMachineFillTrigger.getIsActivatable = UPK_FillTrigger.getIsActivatable

