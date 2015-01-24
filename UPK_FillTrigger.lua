-- by mor2000

--------------------
-- UPK_FillTrigger (fills trailers and/or shovels with specific fillType)

local UPK_FillTrigger_mt = ClassUPK(UPK_FillTrigger,UniversalProcessKit)
InitObjectClass(UPK_FillTrigger, "UPK_FillTrigger")
UniversalProcessKit.addModule("filltrigger",UPK_FillTrigger)

function UPK_FillTrigger:new(nodeId, parent)
	local self = UniversalProcessKit:new(nodeId, parent, UPK_FillTrigger_mt)
	registerObjectClassName(self, "UPK_FillTrigger")
	
	local fillFillTypeStr = getStringFromUserAttribute(nodeId, "fillType")
	if fillFillTypeStr~=nil then
		self.fillFillType = UniversalProcessKit.fillTypeNameToInt[fillFillTypeStr]
	end
	
    self.fillLitersPerSecond = getNumberFromUserAttribute(nodeId, "fillLitersPerSecond", 1500, 0)
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
		self:print('add if filling '..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(fillType)..')')
		self.addIfFilling[fillType] = true
		self.useAddIfFilling = true
	end
	
	self.removeIfFilling = {}
	self.useRemoveIfFilling = false
	local removeIfFillingArr = getArrayFromUserAttribute(nodeId, "removeIfFilling")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(removeIfFillingArr)) do
		self:print('remove if filling '..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(fillType)..')')
		self.removeIfFilling[fillType] = true
		self.useRemoveIfFilling = true
	end
	
	-- statName
	
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

	-- spawn pallets
	
	local palletType = getStringFromUserAttribute(nodeId, "spawnPalletType")
	self:print('spawnPalletType '..tostring(palletType))
	local palletTypes = {}
	palletTypes["woolPallet"] = "$data/maps/models/objects/pallets/woolPallet.i3d"
	local palletFilename=getStringFromUserAttribute(nodeId, "spawnPalletFilename")

	local filename = ""
	
	if palletType~=nil then
		filename=palletTypes[palletType]
	elseif palletFilename then
		filename=palletFilename
	end
	
	self:print('filename '..tostring(filename))
	self:print('modname '..tostring(self.i18nNameSpace))
	
	if filename~="" and self.i18nNameSpace~=nil then
		local baseDir = g_modNameToDirectory[self.i18nNameSpace]
		self.palletFilename = Utils.getFilename(filename, self.baseDirectory)
		self:print('ready to spawn '..tostring(self.palletFilename))
	end
	
	self.palletSpawnDelay = getNumberFromUserAttribute(nodeId, "palletSpawnDelay", 1, 0.1)*1000
	self.palletSpawnPosition = getVectorFromUserAttribute(nodeId, "palletSpawnPosition", "0 0 0")
	self.palletSpawnRotation = getVectorFromUserAttribute(nodeId, "palletSpawnRotation", "0 0 0")

	-- auto allow...

	local fillFillType = self:getFillType()

	self.allowedVehicles={}
	self.allowedVehicles[UniversalProcessKit.VEHICLE_TIPPER] = getBoolFromUserAttribute(nodeId, "allowTipper", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SHOVEL] = getBoolFromUserAttribute(nodeId, "allowShovel", true)
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SOWINGMACHINE] = getBoolFromUserAttribute(nodeId, "allowSowingMachine", (self.fillFillType or fillFillType)==Fillable.FILLTYPE_SEEDS)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_WATERTRAILER] = getBoolFromUserAttribute(nodeId, "allowWaterTrailer", (self.fillFillType or fillFillType)==Fillable.FILLTYPE_WATER)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRAILER] = getBoolFromUserAttribute(nodeId, "allowMilkTrailer", (self.fillFillType or fillFillType)==Fillable.FILLTYPE_MILK)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER] = getBoolFromUserAttribute(nodeId, "allowLiquidManureTrailer", (self.fillFillType or fillFillType)==Fillable.FILLTYPE_LIQUIDMANURE)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SPRAYER] = getBoolFromUserAttribute(nodeId, "allowSprayer", (self.fillFillType or fillFillType)==Fillable.FILLTYPE_FERTILIZER)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MANURESPREADER] = getBoolFromUserAttribute(nodeId, "allowManureSpreader", (self.fillFillType or fillFillType)==Fillable.FILLTYPE_MANURE)
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FUELTRAILER] = getBoolFromUserAttribute(nodeId, "allowFuelTrailer", (self.fillFillType or fillFillType)==Fillable.FILLTYPE_FUEL)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED] = getBoolFromUserAttribute(nodeId, "allowMotorized", false)
	
	self.allowPallets = getBoolFromUserAttribute(nodeId, "allowPallets", self.palletFilename~=nil)

	self.allowWalker = getBoolFromUserAttribute(nodeId, "allowWalker", false)
	
	self:addTrigger()
	
	self.dtsum=0
	
	self:print('loaded FillTrigger successfully')
	
    return self
end

function UPK_FillTrigger:delete()
	UniversalProcessKitListener.removeUpdateable(self)
	UPK_FillTrigger:superClass().delete(self)
end

function UPK_FillTrigger:postLoad()
	UPK_FillTrigger:superClass().postLoad(self)
	self:triggerUpdate(false,false)
	UniversalProcessKitListener.addUpdateable(self)
end

function UPK_FillTrigger:triggerUpdate(vehicle,isInTrigger)
	self:print('UPK_FillTrigger:triggerUpdate('..tostring(vehicle)..', '..tostring(isInTrigger)..')')
	if self.isEnabled and self.isServer then
		for k,v in pairs(self.allowedVehicles) do
			if v and UniversalProcessKit.isVehicleType(vehicle, k) then
				if isInTrigger then
					self.amountToFillOfVehicle[vehicle]=0
					--self:print('UniversalProcessKitListener.addUpdateable('..tostring(self)..')')
					UniversalProcessKitListener.addUpdateable(self)
				else
					self.amountToFillOfVehicle[vehicle]=nil
				end
			end
		end
		
		if self.allowPallets and type(vehicle)=="table" and vehicle.isPallet and vehicle.setFillLevel~=nil then
			if isInTrigger then
				self.amountToFillOfVehicle[vehicle]=0
				--self:print('UniversalProcessKitListener.addUpdateable('..tostring(self)..')')
				UniversalProcessKitListener.addUpdateable(self)
			else
				self.amountToFillOfVehicle[vehicle]=nil
			end
		end
	end
end

function UPK_FillTrigger:update(dt)
	--self:print('UPK_FillTrigger:update('..tostring(dt)..')')
	
	if not self.isServer then
		return
	end
	
	if self.isEnabled then
		if self.entitiesInTrigger==0 then
			if self.palletFilename==nil then
				self:print('UniversalProcessKitListener.removeUpdateable('..tostring(self)..')')
				UniversalProcessKitListener.removeUpdateable(self)
				return
			else
				self.dtsum=self.dtsum+dt
				if self.dtsum>self.palletSpawnDelay then
					self.dtsum=0
					local x, y, z = unpack(__c({getWorldTranslation(self.nodeId)}) + self.palletSpawnPosition)
					local y_terrain = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z) + 0.2
					y = mathmax(y, y_terrain)
					local rx, ry, rz = unpack((__c({getWorldRotation(self.nodeId)}) + self.palletSpawnRotation) * (2*math.pi))
			
					local pallet = FillablePallet:new(self.isServer, self.isClient)
					if pallet:load(self.palletFilename, x, y, z, rx, ry, rz) then
						self:print('spawning pallet in '..tostring(x)..', '..tostring(y)..', '..tostring(z))
						pallet:register()
						pallet.fillType = self.fillFillType or self:getFillType() or UniversalProcessKit.FILLTYPE_UNKNOWN
						UniversalProcessKitListener.removeUpdateable(self)
					else
						self:triggerCallback(self.nodeId, pallet.nodeId, false, false, false, pallet.nodeId) -- needed?
						pallet:delete()
					end
				end
			end
		else
			for _,trailer in pairs(self.entities) do
				--self:print('vehicle is '..tostring(trailer.upk_vehicleType))
				local deltaFillLevel = self.fillLitersPerSecond * 0.001 * dt
				local added = 0
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
							added = self:fillTrailer(trailer, deltaFillLevel)
						elseif k==UniversalProcessKit.VEHICLE_MOTORIZED then
							added = self:fillMotorized(trailer, deltaFillLevel)
						end
					end
				end
				if self.allowPallets and trailer.isPallet and trailer.setFillLevel~=nil then
					added = self:fillPallet(trailer, deltaFillLevel)
				end
				if added~=0 then
					if self.useAddIfFilling then
						for fillTypeToAdd,v in pairs(self.addIfFilling) do
							if v then
								self:addFillLevel(added,fillTypeToAdd)
							end
						end
					end
					if self.useRemoveIfFilling then
						for fillTypeToRemove,v in pairs(self.removeIfFilling) do
							if v then
								self:addFillLevel(-added,fillTypeToRemove)
							end
						end
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
	local pricePerLiterAdjustment = self.pricePerLiterMultiplier[difficulty]
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
			
			if self.fillOnlyWholeNumbers then
				self.amountToFillOfVehicle[trailer] = (self.amountToFillOfVehicle[trailer] or 0) - deltaFillLevel
				deltaFillLevel = -mathfloor(self.amountToFillOfVehicle[trailer])
				self.amountToFillOfVehicle[trailer] = self.amountToFillOfVehicle[trailer] + deltaFillLevel
			end
			
			if deltaFillLevel==0 then
				return 0
			end
			
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
					local pricePerLiter = self:getPricePerLiter(fillFillType)
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
			
			if self.fillOnlyWholeNumbers then
				self.amountToFillOfVehicle[trailer] = (self.amountToFillOfVehicle[trailer] or 0) - deltaFillLevel
				deltaFillLevel = -mathfloor(self.amountToFillOfVehicle[trailer])
				self.amountToFillOfVehicle[trailer] = self.amountToFillOfVehicle[trailer] + deltaFillLevel
			end
			
			if deltaFillLevel==0 then
				return 0
			end
			
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
					local pricePerLiter = self:getPricePerLiter(fillFillType)
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
			
			if self.fillOnlyWholeNumbers then
				self.amountToFillOfVehicle[trailer] = (self.amountToFillOfVehicle[trailer] or 0) - deltaFillLevel
				deltaFillLevel = -mathfloor(self.amountToFillOfVehicle[trailer])
				self.amountToFillOfVehicle[trailer] = self.amountToFillOfVehicle[trailer] + deltaFillLevel
			end
			
			if deltaFillLevel==0 then
				return 0
			end
			
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
					local pricePerLiter = self:getPricePerLiter(fillFillType)
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
			
			if self.fillOnlyWholeNumbers then
				self.amountToFillOfVehicle[trailer] = (self.amountToFillOfVehicle[trailer] or 0) - deltaFillLevel
				deltaFillLevel = -mathfloor(self.amountToFillOfVehicle[trailer])
				self.amountToFillOfVehicle[trailer] = self.amountToFillOfVehicle[trailer] + deltaFillLevel
			end
			
			if deltaFillLevel==0 then
				return 0
			end
			
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
					local pricePerLiter = self:getPricePerLiter(fillFillType)
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

function UPK_FillTrigger:fillPallet(trailer, deltaFillLevel) -- tippers, shovels etc
	self:print('UPK_FillTrigger:fillPallet('..tostring(trailer)..', '..tostring(deltaFillLevel)..')')
	if self.isServer and self.isEnabled then
		local fillFillType = self.fillFillType or self:getFillType() -- for single, fifo and filo
		self:print('fillFillType '..tostring(fillFillType))
		if fillFillType~=UniversalProcessKit.FILLTYPE_UNKNOWN then
			
			if self.fillOnlyWholeNumbers then
				self.amountToFillOfVehicle[trailer] = (self.amountToFillOfVehicle[trailer] or 0) - deltaFillLevel
				deltaFillLevel = -mathfloor(self.amountToFillOfVehicle[trailer])
				self.amountToFillOfVehicle[trailer] = self.amountToFillOfVehicle[trailer] + deltaFillLevel
			end
			
			if deltaFillLevel==0 then
				return 0
			end
			
			local trailerFillType = trailer:getFillType()
			local trailerFillLevel = trailer:getFillLevel()
			local fillLevel = self:getFillLevel(fillFillType)
			--self:print('fillLevel '..tostring(fillLevel))
			--self:print('trailer:allowFillType(fillFillType, false) '..tostring(trailer:allowFillType(fillFillType, false)))
			if (fillLevel>0 or self.createFillType) and
				fillFillType==trailerFillType and
				trailerFillLevel<trailer.capacity then
				
				if not self.createFillType then
					deltaFillLevel=math.min(deltaFillLevel, fillLevel)
				end
				trailer:setFillLevel(trailerFillLevel + deltaFillLevel, fillFillType)
				deltaFillLevel = trailer:getFillLevel() - trailerFillLevel
				if deltaFillLevel~=0 then
					if not self.createFillType then
						deltaFillLevel=-self:addFillLevel(-deltaFillLevel,fillFillType)
					end
					local pricePerLiter = self:getPricePerLiter(fillFillType)
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

function UPK_FillTrigger:getIsActivatable(trailer)
	local fillFillType = self.fillFillType or self:getFillType()
	if trailer:allowFillType(fillFillType, false) and
		(self:getFillLevel(fillFillType)>0 or self.createFillType) then
		return true
	end
	return false
end
