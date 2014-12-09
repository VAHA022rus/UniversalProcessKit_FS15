-- by mor2000

--------------------
-- UPK_FillTrigger (fills trailers and/or shovels with specific fillType)

local UPK_FillTrigger_mt = ClassUPK(UPK_FillTrigger,UniversalProcessKit)
InitObjectClass(UPK_FillTrigger, "UPK_FillTrigger")
UniversalProcessKit.addModule("filltrigger",UPK_FillTrigger)

function UPK_FillTrigger:new(id, parent)
	local self = UniversalProcessKit:new(id, parent, UPK_FillTrigger_mt)
	registerObjectClassName(self, "UPK_FillTrigger")
	
	self.fillFillType = UniversalProcessKit.fillTypeNameToInt[getStringFromUserAttribute(id, "fillType", "unknown")]
	
    self.fillLitersPerSecond = getNumberFromUserAttribute(id, "fillLitersPerSecond", 1500, 0)
	self.createFillType = getBoolFromUserAttribute(id, "createFillType", false)
    self.pricePerLiter = getNumberFromUserAttribute(id, "pricePerLiter", 0)
	
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
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SOWINGMACHINE] = getBoolFromUserAttribute(self.nodeId, "allowSowingMachine", self.fillFillType==Fillable.FILLTYPE_SEEDS)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_WATERTRAILER] = getBoolFromUserAttribute(self.nodeId, "allowWaterTrailer", self.fillFillType==Fillable.FILLTYPE_WATER)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRAILER] = getBoolFromUserAttribute(self.nodeId, "allowMilkTrailer", self.fillFillType==Fillable.FILLTYPE_MILK)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER] = getBoolFromUserAttribute(self.nodeId, "allowLiquidManureTrailer", self.fillFillType==Fillable.FILLTYPE_LIQUIDMANURE)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SPRAYER] = getBoolFromUserAttribute(self.nodeId, "allowSprayer", self.fillFillType==Fillable.FILLTYPE_FERTILIZER)
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FUELTRAILER] = getBoolFromUserAttribute(self.nodeId, "allowFuelTrailer", self.fillFillType==Fillable.FILLTYPE_FUEL)
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
			--self:print('vehicle is '..tostring(trailer.upk_vehicleType))
			local deltaFillLevel = self.fillLitersPerSecond * 0.001 * dt
			for k,v in pairs(self.allowedVehicles) do
				--self:print('checking for '..tostring(k)..': '..tostring(v))
				if v and UniversalProcessKit.isVehicleType(trailer, k) then
					--self:print('vehicle allowed')
					if (k==UniversalProcessKit.VEHICLE_TIPPER or
						 k==UniversalProcessKit.VEHICLE_SHOVEL or
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

function UPK_FillTrigger:fillTrailer(trailer, deltaFillLevel) -- tippers, shovels etc
	--self:print('UPK_FillTrigger:fillTrailer('..tostring(trailer)..', '..tostring(deltaFillLevel)..')')
	if self.isServer and self.isEnabled then
		local trailerFillLevel = trailer:getFillLevel(self.fillFillType)
		local fillLevel = self:getFillLevel(self.fillFillType)
		--self:print('fillLevel '..tostring(fillLevel))
		--self:print('trailer:allowFillType(self.fillFillType, false) '..tostring(trailer:allowFillType(self.fillFillType, false)))
		--self:print('trailerFillLevel<trailer.capacity '..tostring(trailerFillLevel<trailer.capacity))
		if (fillLevel>0 or self.createFillType) and trailer:allowFillType(self.fillFillType, false) and trailerFillLevel<trailer.capacity then
			trailer:resetFillLevelIfNeeded(self.fillFillType)
			if not self.createFillType then
				deltaFillLevel=math.min(deltaFillLevel, fillLevel)
			end
			trailer:setFillLevel(trailerFillLevel + deltaFillLevel, self.fillFillType)
			deltaFillLevel = trailer:getFillLevel(self.fillFillType) - trailerFillLevel
			if deltaFillLevel~=0 then
				if self.pricePerLiter~=0 then
					local price = delta * self.pricePerLiter
					g_currentMission:addSharedMoney(-price, self.statName)
				end
				if not self.createFillType then
					self:addFillLevel(-deltaFillLevel,self.fillFillType)
				end
			end
		end
	end
end

function UPK_FillTrigger:fillMotorized(trailer, deltaFillLevel) -- motorized
	--self:print('UPK_FillTrigger:fillMotorized('..tostring(trailer)..', '..tostring(deltaFillLevel)..')')
	if self.isServer and self.isEnabled and self.fillFillType==Fillable.FILLTYPE_FUEL then
		local trailerFillLevel = trailer.fuelFillLevel
		local fillLevel = self:getFillLevel(self.fillFillType)
		if (fillLevel>0 or self.createFillType) and trailerFillLevel<trailer.fuelCapacity then
			if not self.createFillType then
				deltaFillLevel=math.min(deltaFillLevel, fillLevel)
			end
			trailer:setFuelFillLevel(trailerFillLevel + deltaFillLevel)
			deltaFillLevel = trailer.fuelFillLevel - trailerFillLevel
			if(deltaFillLevel>0 and self.pricePerLiter~=0)then
				local price = delta * self.pricePerLiter
				g_currentMission:addSharedMoney(-price, self.statName)
			end
			if not self.createFillType then
				self:addFillLevel(-deltaFillLevel,self.fillFillType)
			end
		end
	end
end

