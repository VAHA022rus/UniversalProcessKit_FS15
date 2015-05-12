-- by mor2000

--------------------
-- UPK_EmptyTrigger (fills trailers and/or shovels with specific fillType)

local UPK_EmptyTrigger_mt = ClassUPK(UPK_EmptyTrigger,UniversalProcessKit)
InitObjectClass(UPK_EmptyTrigger, "UPK_EmptyTrigger")
UniversalProcessKit.addModule("emptytrigger",UPK_EmptyTrigger)

function UPK_EmptyTrigger:new(nodeId, parent)
	local self = UniversalProcessKit:new(nodeId, parent, UPK_EmptyTrigger_mt)
	registerObjectClassName(self, "UPK_EmptyTrigger")
	
	self.emptyFillTypes = {}
	local emptyFillTypesArr = getArrayFromUserAttribute(nodeId, "emptyFillTypes")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(emptyFillTypesArr)) do
		self:print('fillType from emptyFillTypesArr: '..tostring(fillType))
		self.emptyFillTypes[fillType] = true
		self:print('self.emptyFillTypes[fillType]: '..tostring(self.emptyFillTypes[fillType]))
	end
	
    self.emptyLitersPerSecond = getNumberFromUserAttribute(nodeId, "emptyLitersPerSecond", 1500, 0)

	self:print('emptyFillTypes: '..tostring(getStringFromUserAttribute(nodeId, "emptyFillTypes")))

	self.emptyOnlyWholeNumbers = getBoolFromUserAttribute(nodeId, "emptyOnlyWholeNumbers", false)
	self.amountToEmptyOfVehicle = {}
	
	-- add/ remove if emptying
	
	self.addIfEmptying = {}
	self.useAddIfEmptying = false
	local addIfEmptyingArr = getArrayFromUserAttribute(nodeId, "addIfEmptying")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(addIfEmptyingArr)) do
		self:print('add if filling '..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(fillType)..')')
		self.addIfEmptying[fillType] = true
		self.useAddIfEmptying = true
	end
	
	self.removeIfEmptying = {}
	self.useRemoveIfEmptying = false
	local removeIfEmptyingArr = getArrayFromUserAttribute(nodeId, "removeIfEmptying")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(removeIfEmptyingArr)) do
		self:print('remove if filling '..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(fillType)..')')
		self.removeIfEmptying[fillType] = true
		self.useRemoveIfEmptying = true
	end
	
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
	
	self.statName=getStringFromUserAttribute(nodeId, "statName")
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

	self.deleteEmptyPallets = getBoolFromUserAttribute(nodeId, "deleteEmptyPallets", true)

	self.allowedVehicles={}
	self.allowedVehicles[UniversalProcessKit.VEHICLE_TIPPER] = getBoolFromUserAttribute(nodeId, "allowTipper", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SHOVEL] = getBoolFromUserAttribute(nodeId, "allowShovel", true)
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SOWINGMACHINE] = getBoolFromUserAttribute(nodeId, "allowSowingMachine", self.emptyFillTypes[UniversalProcessKit.FILLTYPE_SEEDS] or false)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_WATERTRAILER] = getBoolFromUserAttribute(nodeId, "allowWaterTrailer", self.emptyFillTypes[UniversalProcessKit.FILLTYPE_WATER] or false)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRAILER] = getBoolFromUserAttribute(nodeId, "allowMilkTrailer", self.emptyFillTypes[UniversalProcessKit.FILLTYPE_MILK] or false)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER] = getBoolFromUserAttribute(nodeId, "allowLiquidManureTrailer", self.emptyFillTypes[UniversalProcessKit.FILLTYPE_LIQUIDMANURE] or false)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SPRAYER] = getBoolFromUserAttribute(nodeId, "allowSprayer", self.emptyFillTypes[UniversalProcessKit.FILLTYPE_FERTILIZER] or false)
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FUELTRAILER] = getBoolFromUserAttribute(nodeId, "allowFuelTrailer", self.emptyFillTypes[UniversalProcessKit.FILLTYPE_FUEL] or false)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED] = getBoolFromUserAttribute(nodeId, "allowMotorized", false)
	
	self.allowWalker = getBoolFromUserAttribute(nodeId, "allowWalker", false)
	
	self:addTrigger()
	
	--self:print('UniversalProcessKit.FILLTYPE_FUEL: '..tostring(UniversalProcessKit.FILLTYPE_FUEL))
	--self:print('self.emptyFillTypes[UniversalProcessKit.FILLTYPE_FUEL]: '..tostring(self.emptyFillTypes[UniversalProcessKit.FILLTYPE_FUEL]))
	--self:print('self.allowedVehicles[UniversalProcessKit.VEHICLE_FUELTRAILER]: '..tostring(self.allowedVehicles[UniversalProcessKit.VEHICLE_FUELTRAILER]))
	
	self:print('loaded EmptyTrigger successfully')
	
    return self
end

function UPK_EmptyTrigger:triggerUpdate(vehicle,isInTrigger)
	if self.isEnabled and self.isServer then
		for k,v in pairs(self.allowedVehicles) do
			if v and UniversalProcessKit.isVehicleType(vehicle, k) then
				if isInTrigger then
					self.amountToEmptyOfVehicle[vehicle]=0
					self:print('UniversalProcessKitListener.addUpdateable('..tostring(self)..')')
					UniversalProcessKitListener.addUpdateable(self)
				else
					self.amountToEmptyOfVehicle[vehicle]=nil
					if self.entitiesInTrigger==0 then
						self:print('UniversalProcessKitListener.removeUpdateable('..tostring(self)..')')
						UniversalProcessKitListener.removeUpdateable(self)
					end
				end
			end
		end
		
		if self.allowPallets and vehicle~=nil and vehicle.isPallet and vehicle.setFillLevel~=nil then
			if isInTrigger then
				self.amountToEmptyOfVehicle[vehicle]=0
				UniversalProcessKitListener.addUpdateable(self)
			else
				self.amountToEmptyOfVehicle[vehicle]=nil
				if self.entitiesInTrigger==0 then
					UniversalProcessKitListener.removeUpdateable(self)
				end
			end
		end
	end
end

function UPK_EmptyTrigger:update(dt)
	if self.isServer and self.isEnabled then
		for _,vehicle in pairs(self.entities) do
			local deltaFillLevel = - (self.emptyLitersPerSecond * 0.001 * dt)
			local added = 0
			for vehicleType, isAllowed in pairs(self.allowedVehicles) do
				if isAllowed and UniversalProcessKit.isVehicleType(vehicle, vehicleType) then
					if (vehicleType==UniversalProcessKit.VEHICLE_TIPPER or
						 vehicleType==UniversalProcessKit.VEHICLE_SHOVEL or
						 vehicleType==UniversalProcessKit.VEHICLE_SOWINGMACHINE or
						 vehicleType==UniversalProcessKit.VEHICLE_WATERTRAILER or
						 vehicleType==UniversalProcessKit.VEHICLE_MILKTRAILER or
						 vehicleType==UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER or
						 vehicleType==UniversalProcessKit.VEHICLE_SPRAYER or
						 vehicleType==UniversalProcessKit.VEHICLE_FUELTRAILER) then
						added = self:emptyFillable(vehicle, deltaFillLevel)
					elseif vehicleType==UniversalProcessKit.VEHICLE_MOTORIZED then
						added = self:emptyMotorized(vehicle, deltaFillLevel)
					end
				end
			end
			if self.allowPallets and vehicle.isPallet and vehicle.setFillLevel~=nil then
				self:print('trying to empty pallet')
				added = self:emptyPallet(vehicle, deltaFillLevel)
			end
			if added ~= 0 then
				if self.useAddIfEmptying then
					for fillTypeToAdd,v in pairs(self.addIfEmptying) do
						if v then
							self:addFillLevel(added,fillTypeToAdd)
						end
					end
				end
				if self.useRemoveIfEmptying then
					for fillTypeToRemove,v in pairs(self.removeIfEmptying) do
						if v then
							self:addFillLevel(-added,fillTypeToRemove)
						end
					end
				end
			end
		end
	end
end

UPK_EmptyTrigger.getRevenuePerLiter = UPK_TipTrigger.getRevenuePerLiter

function UPK_EmptyTrigger:emptyFillable(fillable, deltaFillLevel) -- tippers, shovels etc
	--self:print('UPK_EmptyTrigger:emptyFillable('..tostring(fillable)..', '..tostring(deltaFillLevel)..')')
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
	self:print('UPK_EmptyTrigger:emptyPallet('..tostring(fillable)..', '..tostring(deltaFillLevel)..')')
	if self.isServer and self.isEnabled then
		local fillType = fillable:getFillType()
		if not self.emptyFillTypes[fillType] then
			return 0
		end
		if fillType~=nil then
			local fillLevel = self:getFillLevel(fillType)
			local capacity = self:getCapacity(fillType)
			local fillableFillLevel = fillable:getFillLevel()
			self:print('fillableFillLevel '..tostring(fillableFillLevel))
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
				self:triggerUpdate(fillable,false)
				fillable:delete()
			end
		end
	end
	return 0
end

