-- by mor2000

--------------------
-- UPK_EmptyTrigger (fills trailers and/or shovels with specific fillType)

local UPK_EmptyTrigger_mt = ClassUPK(UPK_EmptyTrigger,UniversalProcessKit)
InitObjectClass(UPK_EmptyTrigger, "UPK_EmptyTrigger")
UniversalProcessKit.addModule("emptytrigger",UPK_EmptyTrigger)

function UPK_EmptyTrigger:new(id, parent)
	local self = UniversalProcessKit:new(id, parent, UPK_EmptyTrigger_mt)
	registerObjectClassName(self, "UPK_EmptyTrigger")
	
	self.emptyFillTypes = {}
	local emptyFillTypesArr = getArrayFromUserAttribute(id, "emptyFillTypes")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(emptyFillTypesArr)) do
		self.emptyFillTypes[fillType] = true
	end
	
    self.emptyLitersPerSecond = getNumberFromUserAttribute(id, "emptyLitersPerSecond", 1500, 0)
	
	
	
	-- revenues
	
	self.revenuePerLiter = getNumberFromUserAttribute(id, "revenuePerLiter", 0)
	self.revenuesPerLiter = {}
		
	local revenuesPerLiterArr = getArrayFromUserAttribute(id, "revenuesPerLiter")
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
	
	--[[
	FinanceStats.statNames = {
		"newVehiclesCost",
		"newAnimalsCost",
		"constructionCost",
		"vehicleRunningCost",
		"propertyMaintenance",
		"wagePayment",
		"harvestIncome",
		"missionIncome",
		"other",
		"loanInterest"
	}
	--]]
	
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
	self.allowedVehicles[UniversalProcessKit.VEHICLE_TIPPER] = getBoolFromUserAttribute(self.nodeId, "allowTipper", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SHOVEL] = getBoolFromUserAttribute(self.nodeId, "allowShovel", true)
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SOWINGMACHINE] = getBoolFromUserAttribute(self.nodeId, "allowSowingMachine", isInTable(self.emptyFillTypes, Fillable.FILLTYPE_SEEDS))
	self.allowedVehicles[UniversalProcessKit.VEHICLE_WATERTRAILER] = getBoolFromUserAttribute(self.nodeId, "allowWaterTrailer", isInTable(self.emptyFillTypes, Fillable.FILLTYPE_WATER))
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRAILER] = getBoolFromUserAttribute(self.nodeId, "allowMilkTrailer", isInTable(self.emptyFillTypes, Fillable.FILLTYPE_MILK))
	self.allowedVehicles[UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER] = getBoolFromUserAttribute(self.nodeId, "allowLiquidManureTrailer", isInTable(self.emptyFillTypes, Fillable.FILLTYPE_LIQUIDMANURE))
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SPRAYER] = getBoolFromUserAttribute(self.nodeId, "allowSprayer", isInTable(self.emptyFillTypes, Fillable.FILLTYPE_FERTILIZER))
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FUELTRAILER] = getBoolFromUserAttribute(self.nodeId, "allowFuelTrailer", isInTable(self.emptyFillTypes, Fillable.FILLTYPE_FUEL))
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED] = getBoolFromUserAttribute(self.nodeId, "allowMotorized", false)
	
	self.allowWalker = getBoolFromUserAttribute(self.nodeId, "allowWalker", false)
	
	self:addTrigger()
	
	self:print('loaded FillTrigger successfully')
	
    return self
end

function UPK_EmptyTrigger:triggerUpdate(vehicle,isInTrigger)
	if self.isEnabled and self.isServer then
		for k,v in pairs(self.allowedVehicles) do
			if v and UniversalProcessKit.isVehicleType(vehicle, k) then
				if isInTrigger then
					self:print('UniversalProcessKitListener.addUpdateable('..tostring(self)..')')
					UniversalProcessKitListener.addUpdateable(self)
				else
					if self.entitiesInTrigger==0 then
						self:print('UniversalProcessKitListener.removeUpdateable('..tostring(self)..')')
						UniversalProcessKitListener.removeUpdateable(self)
					end
				end
			end
		end
	end
end

function UPK_EmptyTrigger:update(dt)
	--self:print('UPK_EmptyTrigger:update('..tostring(dt)..')')
	if self.isServer and self.isEnabled then
		for _,vehicle in pairs(self.entities) do
			local deltaFillLevel = - (self.emptyLitersPerSecond * 0.001 * dt)
			for vehicleType, isAllowed in pairs(self.allowedVehicles) do
				if isAllowed and UniversalProcessKit.isVehicleType(vehicle, vehicleType) then
					if (vehicleType==UniversalProcessKit.VEHICLE_TIPPER or
						 vehicleType==UniversalProcessKit.VEHICLE_SHOVEL or
						 vehicleType==UniversalProcessKit.VEHICLE_SOWINGMACHINE or
						 vehicleType==UniversalProcessKit.VEHICLE_WATERTRAILER or
						 vehicleType==UniversalProcessKit.VEHICLE_MILKTRAILER or
						 vehicleType==UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER or
						 vehicleType==UniversalProcessKit.VEHICLE_SPRAYER or
						 kvehicleType==UniversalProcessKit.VEHICLE_FUELTRAILER) then
						self:emptyFillable(vehicle, deltaFillLevel)
					elseif vehicleType==UniversalProcessKit.VEHICLE_MOTORIZED then
						self:emptyMotorized(vehicle, deltaFillLevel)
					end
				end
			end
		end
	end
end

function UPK_EmptyTrigger:emptyFillable(fillable, deltaFillLevel) -- tippers, shovels etc
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
				deltaFillLevel=mathmin(deltaFillLevel, fillableFillLevel, capacity-fillLevel)
				fillable:setFillLevel(fillableFillLevel + deltaFillLevel, fillType)
				local added = self:addFillLevel(-deltaFillLevel, fillType)
				if added~=0 and self.revenuesPerLiter[fillType]~=0 then
					local revenue = added * self.revenuesPerLiter[fillType]
					g_currentMission:addSharedMoney(revenue, self.statName)
				end
			end
		end
	end
end



function UPK_EmptyTrigger:emptyMotorized(motorized, deltaFillLevel) -- motorized
	if self.isServer and self.isEnabled and self.emptyFillTypes[Fillable.FILLTYPE_FUEL] then
		local fillType = Fillable.FILLTYPE_FUEL
		local fillLevel = self:getFillLevel(fillType)
		local capacity = self:getCapacity(fillType)
		local motorizedFillLevel = motorized.fuelFillLevel
		if motorizedFillLevel>0 and capacity-fillLevel>0 then
			deltaFillLevel=mathmin(deltaFillLevel, motorizedFillLevel, capacity-fillLevel)
			motorized:setFuelFillLevel(motorizedFillLevel + deltaFillLevel)
			local added = self:addFillLevel(-deltaFillLevel, fillType)
			self:print('added: '..tostring(added))
			self:print('self.revenuesPerLiter['..tostring(fillType)..']: '..tostring(self.revenuesPerLiter[fillType]))
			if added~=0 and self.revenuesPerLiter[fillType]~=0 then
				local revenue = added * self.revenuesPerLiter[fillType]
				g_currentMission:addSharedMoney(revenue, self.statName)
			end
		end
	end
end

