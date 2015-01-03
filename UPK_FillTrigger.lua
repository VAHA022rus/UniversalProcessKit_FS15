-- by mor2000

--------------------
-- UPK_FillTrigger (fills trailers and/or shovels with specific fillType)

local UPK_FillTrigger_mt = ClassUPK(UPK_FillTrigger,UniversalProcessKit)
InitObjectClass(UPK_FillTrigger, "UPK_FillTrigger")
UniversalProcessKit.addModule("filltrigger",UPK_FillTrigger)

function UPK_FillTrigger:new(id, parent)
	local self = UniversalProcessKit:new(id, parent, UPK_FillTrigger_mt)
	registerObjectClassName(self, "UPK_FillTrigger")
	
	local fillFillTypeStr = getStringFromUserAttribute(id, "fillType")
	if fillFillTypeStr~=nil then
		self.fillFillType = UniversalProcessKit.fillTypeNameToInt[fillFillTypeStr]
	end
	
    self.fillLitersPerSecond = getNumberFromUserAttribute(id, "fillLitersPerSecond", 1500, 0)
	self.createFillType = getBoolFromUserAttribute(id, "createFillType", false)
    self.pricePerLiter = getNumberFromUserAttribute(id, "pricePerLiter", 0)
	
	self.preferMapDefaultPrice = getBoolFromUserAttribute(id, "preferMapDefaultPrice", false)
	self.pricePerLiterMultiplier = getVectorFromUserAttribute(id, "pricePerLiterMultiplier", "1 1 1")
	self.pricesPerLiter = {}
	
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

	local fillFillType = self:getFillType()

	self.allowedVehicles={}
	self.allowedVehicles[UniversalProcessKit.VEHICLE_TIPPER] = getBoolFromUserAttribute(self.nodeId, "allowTipper", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SHOVEL] = getBoolFromUserAttribute(self.nodeId, "allowShovel", true)
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SOWINGMACHINE] = getBoolFromUserAttribute(self.nodeId, "allowSowingMachine", (self.fillFillType or fillFillType)==Fillable.FILLTYPE_SEEDS)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_WATERTRAILER] = getBoolFromUserAttribute(self.nodeId, "allowWaterTrailer", (self.fillFillType or fillFillType)==Fillable.FILLTYPE_WATER)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRAILER] = getBoolFromUserAttribute(self.nodeId, "allowMilkTrailer", (self.fillFillType or fillFillType)==Fillable.FILLTYPE_MILK)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER] = getBoolFromUserAttribute(self.nodeId, "allowLiquidManureTrailer", (self.fillFillType or fillFillType)==Fillable.FILLTYPE_LIQUIDMANURE)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SPRAYER] = getBoolFromUserAttribute(self.nodeId, "allowSprayer", (self.fillFillType or fillFillType)==Fillable.FILLTYPE_FERTILIZER)
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FUELTRAILER] = getBoolFromUserAttribute(self.nodeId, "allowFuelTrailer", (self.fillFillType or fillFillType)==Fillable.FILLTYPE_FUEL)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED] = getBoolFromUserAttribute(self.nodeId, "allowMotorized", false)
	
	self.allowWalker = getBoolFromUserAttribute(self.nodeId, "allowWalker", false)
	
	self:addTrigger()
	
	self:print('loaded FillTrigger successfully')
	
    return self
end

function UPK_FillTrigger:delete()
	UniversalProcessKitListener.removeUpdateable(self)
	UPK_FillTrigger:superClass().delete(self)
end

function UPK_FillTrigger:triggerUpdate(vehicle,isInTrigger)
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

function UPK_FillTrigger:update(dt)
	--self:print('UPK_FillTrigger:update('..tostring(dt)..')')
	if self.isServer and self.isEnabled then
		for _,trailer in pairs(self.entities) do
			
			--[[
			if trailer.upk_scanned~=true then
				for k,v in pairs(trailer) do
					self:print('trailer.'..tostring(k)..' = '..tostring(v))
				end
				trailer.upk_scanned=true
			end
			]]--
			
			--self:print('vehicle is '..tostring(trailer.upk_vehicleType))
			local deltaFillLevel = self.fillLitersPerSecond * 0.001 * dt
			for k,v in pairs(self.allowedVehicles) do
				--self:print('checking for '..tostring(k)..': '..tostring(v))
				if v and UniversalProcessKit.isVehicleType(trailer, k) then
					--self:print('vehicle allowed')
					if k==UniversalProcessKit.VEHICLE_MIXERWAGONPICKUP then
						self:fillMixerWagonPickup(trailer, deltaFillLevel)
					elseif k==UniversalProcessKit.VEHICLE_MIXERWAGONTRAILER then
						self:fillMixerWagonTrailer(trailer, deltaFillLevel)
					elseif ((k==UniversalProcessKit.VEHICLE_TIPPER and not UniversalProcessKit.isVehicleType(trailer, UniversalProcessKit.VEHICLE_MIXERWAGONTRAILER)) or
						 (k==UniversalProcessKit.VEHICLE_SHOVEL and not UniversalProcessKit.isVehicleType(trailer, UniversalProcessKit.VEHICLE_MIXERWAGONPICKUP)) or
						 k==UniversalProcessKit.VEHICLE_SOWINGMACHINE or
						 k==UniversalProcessKit.VEHICLE_WATERTRAILER or
						 k==UniversalProcessKit.VEHICLE_MILKTRAILER or
						 k==UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER or
						 k==UniversalProcessKit.VEHICLE_SPRAYER or
						 k==UniversalProcessKit.VEHICLE_FUELTRAILER) then
						self:fillTrailer(trailer, deltaFillLevel)
					elseif k==UniversalProcessKit.VEHICLE_MOTORIZED then
						self:fillMotorized(trailer, deltaFillLevel)
					end
				end
			end
		end
	end
end

function UPK_FillTrigger:getFillLevel(fillType)
	--self:print('UPK_FillTrigger:getFillLevel('..tostring(fillType)..')')
	return UPK_FillTrigger:superClass().getFillLevel(self, fillType or self.fillFillType or self:getFillType()) or 0
end

function UPK_FillTrigger:getPricePerLiter(fillType)
	fillType = fillType or self.fillFillType
	if self.pricesPerLiter[fillType]~=nil then
		return self.pricesPerLiter[fillType]
	end
	local pricePerLiter = self.pricePerLiter
	if self.preferMapDefaultPrice then
		pricePerLiter = Fillable.fillTypeIndexToDesc[fillType].pricePerLiter or pricePerLiter
	end
	local difficulty = g_currentMission.missionStats.difficulty
	local pricePerLiterAdjustment = pricePerLiterMultiplier[difficulty]
	if pricePerLiterAdjustment~=nil then
		pricePerLiter = pricePerLiter * pricePerLiterAdjustment
	end
	self.pricesPerLiter[fillType] = pricePerLiter
	return pricePerLiter
end

function UPK_FillTrigger:fillTrailer(trailer, deltaFillLevel) -- tippers, shovels etc
	self:print('UPK_FillTrigger:fillTrailer('..tostring(trailer)..', '..tostring(deltaFillLevel)..')')
	if self.isServer and self.isEnabled then
		local fillFillType = self.fillFillType or self:getFillType() -- for single, fifo and filo
		self:print('fillFillType '..tostring(fillFillType))
		if fillFillType~=UniversalProcessKit.FILLTYPE_UNKNOWN then
			local trailerFillLevel = trailer:getFillLevel(trailer.currentFillType)
			local fillLevel = self:getFillLevel(fillFillType)
			--self:print('fillLevel '..tostring(fillLevel))
			--self:print('trailer:allowFillType(fillFillType, false) '..tostring(trailer:allowFillType(fillFillType, false)))
			if (fillLevel>0 or self.createFillType) and
				(fillFillType==trailer.currentFillType or trailer.currentFillType==UniversalProcessKit.FILLTYPE_UNKNOWN or
					(fillFillType~=trailer.currentFillType and trailerFillLevel<0.0001)) and
				trailer:allowFillType(fillFillType, false) and
				trailerFillLevel<trailer.capacity then
				
				trailer:resetFillLevelIfNeeded(fillFillType)
				if not self.createFillType then
					deltaFillLevel=math.min(deltaFillLevel, fillLevel)
				end
				trailer:setFillLevel(trailerFillLevel + deltaFillLevel, fillFillType)
				deltaFillLevel = trailer:getFillLevel(fillFillType) - trailerFillLevel
				if deltaFillLevel~=0 then
					if not self.createFillType then
						deltaFillLevel=-self:addFillLevel(-deltaFillLevel,fillFillType)
					end
					local pricePerLiter = getPricePerLiter(fillFillType)
					if pricePerLiter~=0 then
						local price = deltaFillLevel * pricePerLiter
						g_currentMission:addSharedMoney(-price, self.statName)
					end
					return deltaFillLevel
				end
			end
		end
	end
	return 0
end

function UPK_FillTrigger:fillMotorized(trailer, deltaFillLevel) -- motorized
	self:print('UPK_FillTrigger:fillMotorized('..tostring(trailer)..', '..tostring(deltaFillLevel)..')')
	if self.isServer and self.isEnabled then
		local fillFillType = self.fillFillType or self:getFillType() -- for single, fifo and filo
		self:print('fillFillType '..tostring(fillFillType))
		if fillFillType==UniversalProcessKit.FILLTYPE_FUEL then
			local trailerFillLevel = trailer.fuelFillLevel
			self:print('trailerFillLevel '..tostring(trailerFillLevel))
			local fillLevel = self:getFillLevel(fillFillType)
			self:print('fillLevel '..tostring(fillLevel))
			if (fillLevel>0 or self.createFillType) and round(trailerFillLevel,1)<round(trailer.fuelCapacity,1) then
				if not self.createFillType then
					deltaFillLevel=math.min(deltaFillLevel, fillLevel)
				end
				trailer:setFuelFillLevel(trailerFillLevel + deltaFillLevel)
				deltaFillLevel = trailer.fuelFillLevel - trailerFillLevel
				if deltaFillLevel~=0 then
					if not self.createFillType then
						deltaFillLevel=-self:addFillLevel(-deltaFillLevel, fillFillType)
					end
					local pricePerLiter = getPricePerLiter(fillFillType)
					if pricePerLiter~=0 then
						local price = deltaFillLevel * pricePerLiter
						g_currentMission:addSharedMoney(-price, self.statName)
					end
				end
				return deltaFillLevel
			end
		end
	end
	return 0
end

function UPK_FillTrigger:fillMixerWagonPickup(trailer, deltaFillLevel) -- mixing wagon pickups etc
	self:print('UPK_FillTrigger:fillMixerWagonPickup('..tostring(trailer)..', '..tostring(deltaFillLevel)..')')
	self:print('trailer.isTurnedOn '..tostring(trailer.isTurnedOn))
	if self.isServer and self.isEnabled and trailer.isTurnedOn==true then
		local fillFillType = self.fillFillType or self:getFillType() -- for single, fifo and filo
		self:print('fillFillType '..tostring(fillFillType))
		if fillFillType~=UniversalProcessKit.FILLTYPE_UNKNOWN then
			local trailerFillLevel = trailer:getFillLevel(fillFillType)
			local fillLevel = self:getFillLevel(fillFillType)
			--self:print('fillLevel '..tostring(fillLevel))
			--self:print('trailer:allowFillType(fillFillType, false) '..tostring(trailer:allowFillType(fillFillType, false)))
			
			if (fillLevel>0 or self.createFillType) and
				trailer:allowFillType(fillFillType, false) and
				trailer.fillLevel<trailer.capacity then
				
				trailer:resetFillLevelIfNeeded(fillFillType)
				if not self.createFillType then
					deltaFillLevel=math.min(deltaFillLevel, fillLevel)
				end
				trailer:setFillLevel(trailerFillLevel + deltaFillLevel, fillFillType)
				deltaFillLevel = trailer:getFillLevel(fillFillType) - trailerFillLevel
				if deltaFillLevel~=0 then
					if not self.createFillType then
						deltaFillLevel=-self:addFillLevel(-deltaFillLevel,fillFillType)
					end
					local pricePerLiter = getPricePerLiter(fillFillType)
					if pricePerLiter~=0 then
						local price = deltaFillLevel * pricePerLiter
						g_currentMission:addSharedMoney(-price, self.statName)
					end
					trailer.mixerWagonLastPickupTime = trailer.time
					return deltaFillLevel
				end
			end
		end
	end
	return 0
end

function UPK_FillTrigger:fillMixerWagonTrailer(trailer, deltaFillLevel) -- mixer wagon itself etc
	self:print('UPK_FillTrigger:fillMixerWagonTrailer('..tostring(trailer)..', '..tostring(deltaFillLevel)..')')
	if self.isServer and self.isEnabled then
		local fillFillType = self.fillFillType or self:getFillType() -- for single, fifo and filo
		self:print('fillFillType '..tostring(fillFillType))
		if fillFillType~=UniversalProcessKit.FILLTYPE_UNKNOWN then
			local trailerFillLevel = trailer:getFillLevel(fillFillType)
			local fillLevel = self:getFillLevel(fillFillType)
			--self:print('fillLevel '..tostring(fillLevel))
			--self:print('trailer:allowFillType(fillFillType, false) '..tostring(trailer:allowFillType(fillFillType, false)))
			
			if (fillLevel>0 or self.createFillType) and
				trailer:allowFillType(fillFillType, false) and
				trailer.fillLevel<trailer.capacity then
				
				trailer:resetFillLevelIfNeeded(fillFillType)
				if not self.createFillType then
					deltaFillLevel=math.min(deltaFillLevel, fillLevel)
				end
				trailer:setFillLevel(trailerFillLevel + deltaFillLevel, fillFillType)
				deltaFillLevel = trailer:getFillLevel(fillFillType) - trailerFillLevel
				if deltaFillLevel~=0 then
					if not self.createFillType then
						deltaFillLevel=-self:addFillLevel(-deltaFillLevel,fillFillType)
					end
					local pricePerLiter = getPricePerLiter(fillFillType)
					if pricePerLiter~=0 then
						local price = deltaFillLevel * pricePerLiter
						g_currentMission:addSharedMoney(-price, self.statName)
					end
					trailer.mixerWagonLastPickupTime = trailer.time
					return deltaFillLevel
				end
			end
		end
	end
	return 0
end

function UPK_FillTrigger:getIsActivatable(trailer)
	local fillFillType = self.fillFillType or self:getFillType()
	if trailer:allowFillType(fillFillType, false) and
		(self:getFillLevel(fillFillType)>0 or self.createFillType) then
		return true
	end
	return false
end
