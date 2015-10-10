-- by mor2000

--------------------
-- UPK_EmptyTrigger (fills trailers and/or shovels with specific fillType)

local UPK_EmptyTrigger_mt = ClassUPK(UPK_EmptyTrigger,UniversalProcessKit)
InitObjectClass(UPK_EmptyTrigger, "UPK_EmptyTrigger")
UniversalProcessKit.addModule("emptytrigger",UPK_EmptyTrigger)

function UPK_EmptyTrigger:new(nodeId, parent)
	printFn('UPK_EmptyTrigger:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId, parent, UPK_EmptyTrigger_mt)
	registerObjectClassName(self, "UPK_EmptyTrigger")
	
	self.emptyFillTypes = {}
	local emptyFillTypesArr = getArrayFromUserAttribute(nodeId, "emptyFillTypes")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(emptyFillTypesArr)) do
		self:printAll('fillType from emptyFillTypesArr: '..tostring(fillType))
		self.emptyFillTypes[fillType] = true
		self:printAll('self.emptyFillTypes[fillType]: '..tostring(self.emptyFillTypes[fillType]))
	end
	
    self.emptyLitersPerSecond = getNumberFromUserAttribute(nodeId, "emptyLitersPerSecond", 1500, 0)

	self:printAll('emptyFillTypes: '..tostring(getStringFromUserAttribute(nodeId, "emptyFillTypes")))

	self.emptyOnlyWholeNumbers = getBoolFromUserAttribute(nodeId, "emptyOnlyWholeNumbers", false)
	self.amountToEmptyOfVehicle = {}
	
	-- revenues
	
	self.revenuePerLiter = getNumberFromUserAttribute(nodeId, "revenuePerLiter", 0)
	self.revenuesPerLiter = {}
		
	local revenuesPerLiterArr = getArrayFromUserAttribute(nodeId, "revenuesPerLiter")
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
	
	self.preferMapDefaultRevenue = getBoolFromUserAttribute(nodeId, "preferMapDefaultRevenue", false)
	self.revenuePerLiterMultiplier = getVectorFromUserAttribute(nodeId, "revenuePerLiterMultiplier", "1 0.5 0.25")
	self.revenuesPerLiterAdjusted = {}
	
	self.statName=getStatNameFromUserAttribute(nodeId)

	self.deleteEmptyPallets = getBoolFromUserAttribute(nodeId, "deleteEmptyPallets", true)

	self.allowedVehicles={}
	self.allowedVehicles[UniversalProcessKit.VEHICLE_TIPPER] = getBoolFromUserAttribute(nodeId, "allowTipper", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SHOVEL] = getBoolFromUserAttribute(nodeId, "allowShovel", true)
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SOWINGMACHINE] = getBoolFromUserAttribute(nodeId, "allowSowingMachine", self.emptyFillTypes[UniversalProcessKit.FILLTYPE_SEEDS] or false)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_WATERTRAILER] = getBoolFromUserAttribute(nodeId, "allowWaterTrailer", self.emptyFillTypes[UniversalProcessKit.FILLTYPE_WATER] or false)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRAILER] = getBoolFromUserAttribute(nodeId, "allowMilkTrailer", self.emptyFillTypes[UniversalProcessKit.FILLTYPE_MILK] or false)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER] = getBoolFromUserAttribute(nodeId, "allowLiquidManureTrailer", self.emptyFillTypes[UniversalProcessKit.FILLTYPE_LIQUIDMANURE] or false)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SPRAYER] = getBoolFromUserAttribute(nodeId, "allowSprayer", self.emptyFillTypes[UniversalProcessKit.FILLTYPE_FERTILIZER] or false)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MANURESPREADER] = getBoolFromUserAttribute(nodeId, "allowManureSpreader", self.emptyFillTypes[UniversalProcessKit.FILLTYPE_MANURE] or false)
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FUELTRAILER] = getBoolFromUserAttribute(nodeId, "allowFuelTrailer", self.emptyFillTypes[UniversalProcessKit.FILLTYPE_FUEL] or false)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED] = getBoolFromUserAttribute(nodeId, "allowMotorized", false)
	
	self.allowWalker = getBoolFromUserAttribute(nodeId, "allowWalker", false)
	
	self:addTrigger()
	
	-- actions
	self:getActionUserAttributes('IfEmptying')
	self.isEmptying=nil
	
	self:getActionUserAttributes('IfEmptyingStarted')
	self:getActionUserAttributes('IfEmptyingStopped')
	
	self:getActionUserAttributes('OnPalletDeleted')
	
	self:printFn('UPK_EmptyTrigger:new done')
	
    return self
end

function UPK_EmptyTrigger:triggerUpdate(vehicle,isInTrigger)
	self:printFn('UPK_EmptyTrigger:triggerUpdate(',vehicle,', ',isInTrigger,')')
	if self.isEnabled and self.isServer then
		for k,v in pairs(self.allowedVehicles) do
			if v and UniversalProcessKit.isVehicleType(vehicle, k) then
				if isInTrigger then
					self.amountToEmptyOfVehicle[vehicle]=0
					self:printAll('UniversalProcessKitListener.addUpdateable(',self,')')
					UniversalProcessKitListener.addUpdateable(self)
				else
					self.amountToEmptyOfVehicle[vehicle]=nil
				end
			end
		end
		
		if self.allowPallets and vehicle~=nil and vehicle.isPallet and vehicle.setFillLevel~=nil then
			if isInTrigger then
				self.amountToEmptyOfVehicle[vehicle]=0
				UniversalProcessKitListener.addUpdateable(self)
			else
				self.amountToEmptyOfVehicle[vehicle]=nil
			end
		end
		
		if self.entitiesInTrigger==0 then
			self:printAll('UniversalProcessKitListener.removeUpdateable(',self,')')
			UniversalProcessKitListener.removeUpdateable(self)
			if self.isEmptying then
				self:operateAction('IfEmptyingStopped')
				self.isEmptying=false
			end
		end
	end
end

function UPK_EmptyTrigger:update(dt)
	self:printAll('UPK_EmptyTrigger:update(',dt,')')
	if self.isServer and self.isEnabled then
		local isEmptying=false
		local removedTotally=0
		for _,vehicle in pairs(self.entities) do
			local deltaFillLevel = - (self.emptyLitersPerSecond * 0.001 * dt)
			for vehicleType, isAllowed in pairs(self.allowedVehicles) do
				if isAllowed and UniversalProcessKit.isVehicleType(vehicle, vehicleType) then
					local removed = 0
					if (vehicleType==UniversalProcessKit.VEHICLE_TIPPER or
						 vehicleType==UniversalProcessKit.VEHICLE_SHOVEL or
						 vehicleType==UniversalProcessKit.VEHICLE_SOWINGMACHINE or
						 vehicleType==UniversalProcessKit.VEHICLE_WATERTRAILER or
						 vehicleType==UniversalProcessKit.VEHICLE_MANURESPREADER or
						 vehicleType==UniversalProcessKit.VEHICLE_MILKTRAILER or
						 vehicleType==UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER or
						 vehicleType==UniversalProcessKit.VEHICLE_SPRAYER or
						 vehicleType==UniversalProcessKit.VEHICLE_FUELTRAILER) then
						removed = self:emptyFillable(vehicle, deltaFillLevel)
					elseif vehicleType==UniversalProcessKit.VEHICLE_MOTORIZED then
						removed = self:emptyMotorized(vehicle, deltaFillLevel)
					end
					removedTotally=removedTotally+removed
				end
			end
			if self.allowPallets and vehicle.isPallet and vehicle.setFillLevel~=nil then
				removed = self:emptyPallet(vehicle, deltaFillLevel)
				removedTotally=removedTotally+removed
			end
		end
		self:printAll('removedTotally ',removedTotally)
		if (not self.isEmptying or not isEmptying) and round(removedTotally,8)>0 then
			isEmptying=true
		end
		self:printAll('isEmptying ',isEmptying)
		if isEmptying then
			if not self.isEmptying then
				self:operateAction('IfEmptyingStarted')
				self.isEmptying=true
			end
			self:operateAction('IfEmptying',removedTotally)
		else
			if self.isEmptying then
				self:operateAction('IfEmptyingStopped')
				self.isEmptying=false
			end
		end
	end
end

UPK_EmptyTrigger.getRevenuePerLiter = UPK_TipTrigger.getRevenuePerLiter

function UPK_EmptyTrigger:emptyFillable(fillable, deltaFillLevel) -- tippers, shovels etc
	self:printFn('UPK_EmptyTrigger:emptyFillable(',fillable,', ',deltaFillLevel,')')
	if self.isServer and self.isEnabled then
		local fillType = nil
		for k,v in pairs(self.emptyFillTypes) do
			if v and fillable:allowFillType(k, false) then
				fillType = k
				break
			end
		end
		if fillType~=nil then
			local fillLevel = self:getFillLevel(fillType)
			local capacity = self:getCapacity(fillType)
			local fillableFillLevel = fillable:getFillLevel(fillType)
			if fillableFillLevel>0 and capacity-fillLevel>0 then
				deltaFillLevel=-mathmin(-deltaFillLevel, fillableFillLevel, capacity-fillLevel)
				
				if self.emptyOnlyWholeNumbers then
					self.amountToEmptyOfVehicle[fillable] = (self.amountToEmptyOfVehicle[fillable] or 0) - deltaFillLevel
					deltaFillLevel = -mathfloor(self.amountToEmptyOfVehicle[fillable])
					self.amountToEmptyOfVehicle[fillable] = self.amountToEmptyOfVehicle[fillable] + deltaFillLevel
				end
			
				if deltaFillLevel==0 then
					return 0
				end
				
				fillable:setFillLevel(fillableFillLevel + deltaFillLevel, fillType)
				local added = self:addFillLevel(-deltaFillLevel, fillType)
				
				local revenuePerLiter = self:getRevenuePerLiter(fillType)
				if added~=0 and revenuePerLiter~=0 then
					local revenue = added * revenuePerLiter
					g_currentMission:addSharedMoney(revenue, self.statName)
				end
				return added
			end
		end
	end
	return 0
end

function UPK_EmptyTrigger:emptyMotorized(motorized, deltaFillLevel) -- motorized
	self:printFn('UPK_EmptyTrigger:emptyMotorized(',motorized,', ',deltaFillLevel,')')
	if self.isServer and self.isEnabled and self.emptyFillTypes[UniversalProcessKit.FILLTYPE_FUEL] then
		local fillType = UniversalProcessKit.FILLTYPE_FUEL
		local fillLevel = self:getFillLevel(fillType)
		local capacity = self:getCapacity(fillType)
		local motorizedFillLevel = motorized.fuelFillLevel
		if motorizedFillLevel>0 and capacity-fillLevel>0 then
			deltaFillLevel=-mathmin(-deltaFillLevel, motorizedFillLevel, capacity-fillLevel)
			
			if self.emptyOnlyWholeNumbers then
				self.amountToEmptyOfVehicle[fillable] = (self.amountToEmptyOfVehicle[fillable] or 0) - deltaFillLevel
				deltaFillLevel = -mathfloor(self.amountToEmptyOfVehicle[fillable])
				self.amountToEmptyOfVehicle[fillable] = self.amountToEmptyOfVehicle[fillable] + deltaFillLevel
			end
		
			if deltaFillLevel==0 then
				return 0
			end
			
			motorized:setFuelFillLevel(motorizedFillLevel + deltaFillLevel)
			local added = self:addFillLevel(-deltaFillLevel, fillType)
			if added~=0 and self.revenuesPerLiter[fillType]~=0 then
				local revenue = added * self.revenuesPerLiter[fillType]
				g_currentMission:addSharedMoney(revenue, self.statName)
			end
			return added
		end
	end
	return 0
end

function UPK_EmptyTrigger:emptyPallet(fillable, deltaFillLevel) -- pallet
	self:printFn('UPK_EmptyTrigger:emptyPallet(',fillable,', ',deltaFillLevel,')')
	if self.isServer and self.isEnabled then
		local fillType = fillable:getFillType()
		if not self.emptyFillTypes[fillType] then
			return 0
		end
		if fillType~=nil then
			local fillLevel = self:getFillLevel(fillType)
			local capacity = self:getCapacity(fillType)
			local fillableFillLevel = fillable:getFillLevel()
			self:printAll('fillableFillLevel ',fillableFillLevel)
			if fillableFillLevel>0 and capacity-fillLevel>0 then
				deltaFillLevel=-mathmin(-deltaFillLevel, fillableFillLevel, capacity-fillLevel)
				
				if self.emptyOnlyWholeNumbers then
					self.amountToEmptyOfVehicle[fillable] = (self.amountToEmptyOfVehicle[fillable] or 0) - deltaFillLevel
					deltaFillLevel = -mathfloor(self.amountToEmptyOfVehicle[fillable])
					self.amountToEmptyOfVehicle[fillable] = self.amountToEmptyOfVehicle[fillable] + deltaFillLevel
				end
			
				if deltaFillLevel==0 then
					return 0
				end
				
				fillable:setFillLevel(fillableFillLevel + deltaFillLevel, fillType)
				local added = self:addFillLevel(-deltaFillLevel, fillType)
				
				local revenuePerLiter = self:getRevenuePerLiter(fillType)
				if added~=0 and revenuePerLiter~=0 then
					local revenue = added * revenuePerLiter
					g_currentMission:addSharedMoney(revenue, self.statName)
				end
				return added
			elseif fillableFillLevel==0 and self.deleteEmptyPallets then
				self:triggerOnLeave(fillable)
				fillable:delete()
				self:operateAction('OnPalletDeleted')
			end
		end
	end
	return 0
end

