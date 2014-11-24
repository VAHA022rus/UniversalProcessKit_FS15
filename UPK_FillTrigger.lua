-- by mor2000

--------------------
-- UPK_FillTrigger (fills trailers and/or shovels with specific fillType)

local UPK_FillTrigger_mt = ClassUPK(UPK_FillTrigger,UniversalProcessKit)
InitObjectClass(UPK_FillTrigger, "UPK_FillTrigger")
UniversalProcessKit.addModule("filltrigger",UPK_FillTrigger)

function UPK_FillTrigger:new(id, parent)
	local self = UniversalProcessKit:new(id, parent, UPK_FillTrigger_mt)
	registerObjectClassName(self, "UPK_FillTrigger")

	-- find shapes to show fillType
	self.fillTypeShapes={}
	local numChildren = getNumOfChildren(id)
	for i=1,numChildren do
		local childId = getChildAt(id, i-1)
		local typeStr = getUserAttribute(childId, "fillType")
		if typeStr~=nil then
			fillType=UniversalProcessKit.fillTypeNameToInt(typeStr)
			if type(fillType)=="number" then
				self.fillTypeShapes[fillType]=childId
			end
		end
	end
	
	self.trailers={}
	self.trailersToSync={}

	local fillTypeStr = Utils.getNoNil(getUserAttribute(id, "fillType"))
	if fillTypeStr~=nil then
		local fillType=UniversalProcessKit.fillTypeNameToInt[fillTypeStr]
		if type(fillType)=="number" then
			self.fillType=fillType
		else
			self:print('Error: unknown fillType \"'..tostring(fillTypeStr)..'\" ('..tostring(fillType)..')')
		end
	end
	
    self.fillLitersPerSecond = Utils.getNoNil(getUserAttribute(id, "fillLitersPerSecond"), 1500)
	self.createFillType = tobool(getUserAttribute(id, "createFillType"))
    self.pricePerLiter = Utils.getNoNil(tonumber(getUserAttribute(id, "pricePerLiter")), 0)
	self.statName=getUserAttribute(id, "statName")
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

    self.fillMilk=false
	self.Zucht=self
		
	
    
	
	self.displayName=""
	if self.i18nNameSpace~=nil and (_g or {})[self.i18nNameSpace]~=nil then
		self.displayName=_g[self.i18nNameSpace].g_i18n:getText(l10ndisplayName)
	end
	
	self.fillTriggerActivatable = UPK_FillTriggerActivatable:new(self)
	self.trailersForActivatableObject = 0
	
	self:addTrigger()
	
	self:print('loaded FillTrigger successfully')
	
    return self
end

function UPK_FillTrigger:update(dt)
	if self.isServer and self.isEnabled then
		for k,v in pairs(self.trailers) do
			local trailer=v.vehicle
			if trailer~=nil then
				if v.vehicleType==UniversalProcessKit.VEHICLE_SHOVEL then
					--self:print('shovel in update')
					if self.allowShovel then
						self:fillShovel(trailer, dt)
					end
				elseif v.vehicleType==UniversalProcessKit.VEHICLE_FILLABLE then
					if self.allowTrailer then
						fillType=self.fillType
						self:print('my fillType is '..tostring(fillType))
						if trailer.currentFillType==fillType or trailer.currentFillType==Fillable.FILLTYPE_UNKNOWN then
							local fillLevel = trailer:getFillLevel(fillType)
							if trailer:allowFillType(fillType, false) then
								if (trailer.capacity~=nil and fillLevel==trailer.capacity) or (self.fillLevels[fillType]==0) then
									self:setTrailerFilling(k,false)
								else
									trailer:resetFillLevelIfNeeded(fillType)
									self:setTrailerFilling(k,true)
									local deltaFillLevel = self.fillLitersPerSecond * 0.001 * dt
			    					if not self.createFillType then
			    						deltaFillLevel=math.min(deltaFillLevel, self:getFillLevel(fillType))
			    					end
			    					trailer:setFillLevel(fillLevel + deltaFillLevel, fillType)
			    					local newFillLevel = trailer:getFillLevel(fillType)
			    					deltaFillLevel = newFillLevel-fillLevel
			    					if(deltaFillLevel>0 and self.pricePerLiter~=0)then
			    						g_currentMission:addSharedMoney(-deltaFillLevel*self.pricePerLiter, "other")
			    					end
			    					if not self.createFillType then
			    						self:addFillLevel(-deltaFillLevel,fillType)
			    					end
								end
		    				end
						end
					end
				end
			end
		end
	end
	
	--[[
											local fillTypeName=g_i18n:getText(UniversalProcessKit.fillTypeIntToName(fillType))
											local forageWagonCollectWarning=g_i18n:getText("forage_wagon_cant_collect")
											local text=string.format(forageWagonCollectWarning,fillTypeName)
											g_currentMission:addWarning(text, 0.018, 0.033)
	]]--
end

function UPK_FillTrigger:enableActivatableObject(trailer,fillType)
	--self:print('UPK_FillTrigger:enableActivatableObject')
	self.fillTriggerActivatable:setCurrentTrailer(trailer)
	if self.trailersForActivatableObject==1 then
		g_currentMission:addActivatableObject(self.fillTriggerActivatable)
	end
end;

function UPK_FillTrigger:disableActivatableObject()
	--self:print('UPK_FillTrigger:disableActivatableObject')
	self:setTrailerFilling(self.fillTriggerActivatable.currentTrailer,false)
	self.fillTriggerActivatable:setCurrentTrailer(nil)
	if self.trailersForActivatableObject==0 then
		g_currentMission:removeActivatableObject(self.fillTriggerActivatable)
	end
end;

function UPK_FillTrigger:findMyNodeRaycastCallback(transformId, x, y, z, distance)
	self.raycastTriggerFound = transformId==self.nodeId
	return not self.raycastTriggerFound
end

function UPK_FillTrigger:triggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if self.isEnabled then
		local vehicle=g_currentMission.objectToTrailer[otherShapeId] or g_currentMission.nodeToVehicle[otherShapeId]
		if vehicle~=nil then
			
		
			--self:print("decide what")
			--self:print("self.allowSowingMachine: "..tostring(self.allowSowingMachine))
			--self:print("vehicle.addSowingMachineFillTrigger: "..tostring(vehicle.addSowingMachineFillTrigger~=nil))
			--self:print("self.allowWaterTrailer: "..tostring(self.allowWaterTrailer))
			--self:print("vehicle.addWaterTrailerFillTrigger: "..tostring(vehicle.addWaterTrailerFillTrigger~=nil))
			--self:print("self.allowMilkTrailer: "..tostring(self.allowMilkTrailer))
			--self:print("self.allowSprayer: "..tostring(self.allowSprayer))
			--self:print("vehicle.addSprayerFillTrigger: "..tostring(vehicle.addSprayerFillTrigger~=nil))
			--self:print("self.allowFuelTrailer: "..tostring(self.allowFuelTrailer))
			--self:print("vehicle.addFuelFillTrigger: "..tostring(vehicle.addFuelFillTrigger~=nil))
			--self:print("vehicle.setFuelFillLevel: "..tostring(vehicle.setFuelFillLevel~=nil))
			--self:print("self.allowShovel: "..tostring(self.allowShovel))
			--self:print("vehicle.getAllowFillShovel: "..tostring(vehicle.getAllowFillShovel~=nil))
			--self:print("self.allowTrailer: "..tostring(self.allowTrailer))
			--self:print('self.allowLiquidManureTrailer'..tostring(self.allowLiquidManureTrailer))
			--self:print('vehicle.currentFillType '..tostring(vehicle.currentFillType))
			--self:print('vehicle.addSprayerFillTrigger ~= nil '..tostring(vehicle.addSprayerFillTrigger ~= nil))
			--self:print('vehicle.removeSprayerFillTrigger ~= nil '..tostring(vehicle.removeSprayerFillTrigger ~= nil))
			--self:print('vehicle:allowFillType(Fillable.FILLTYPE_LIQUIDMANURE) '..tostring(vehicle:allowFillType(Fillable.FILLTYPE_LIQUIDMANURE)))
			--self:print('vehicle:allowFillType(Fillable.FILLTYPE_FERTILIZER) '..tostring(vehicle:allowFillType(Fillable.FILLTYPE_FERTILIZER)))
			--self:print('vehicle:allowFillType(Fillable.FILLTYPE_WATER) '..tostring(vehicle:allowFillType(Fillable.FILLTYPE_WATER)))
			
			--self:print('UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_SHOVEL) '..tostring(UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_SHOVEL)))
			--self:print('UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_MILKTRAILER) '..tostring(UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_MILKTRAILER)))


			if UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_SOWINGMACHINE) then
				self:print('isSowingMachine')
				if self.allowSowingMachine then
					if onEnter then
						vehicle:addSowingMachineFillTrigger(self)
						self.trailers[otherShapeId]={vehicleType=UniversalProcessKit.VEHICLE_SOWINGMACHINE,vehicle=vehicle}
					else
						vehicle:removeSowingMachineFillTrigger(self)
						self.trailers[otherShapeId]=nil
					end
				end
			elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_MILKTRAILER) then
				self:print('isMilkTrailer')
				if self.allowMilkTrailer then
					if onEnter then
						self.trailersForActivatableObject=mathmax(0, (self.trailersForActivatableObject or 0)+1)
						self.trailers[otherShapeId]={vehicleType=UniversalProcessKit.VEHICLE_MILKTRAILER,vehicle=vehicle,isFilling=false}
						self:enableActivatableObject(self.trailers[otherShapeId])
					else
						self.trailersForActivatableObject=mathmax(0, (self.trailersForActivatableObject or 1)-1)
						self:disableActivatableObject()
						self.trailers[otherShapeId]=nil
					end
				end
			elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_WATERTRAILER) then
				self:print('isWaterTrailer')
				if self.allowWaterTrailer then
					if onEnter then
						vehicle:addWaterTrailerFillTrigger(self)
						self.trailers[otherShapeId]={vehicleType=UniversalProcessKit.VEHICLE_WATERTRAILER,vehicle=vehicle}
					else
						vehicle:removeWaterTrailerFillTrigger(self)
						self.trailers[otherShapeId]=nil
					end
				end
			elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER) then
				self:print('isLiquidManureTrailer')
				if self.allowLiquidManureTrailer then
					if onEnter then
						vehicle:addSprayerFillTrigger(self)
						self.trailers[otherShapeId]={vehicleType=UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER,vehicle=vehicle}
					else
						vehicle:removeSprayerFillTrigger(self)
						self.trailers[otherShapeId]=nil
					end
				end
			elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_SPRAYER) then
				self:print('isTrailer')
				if self.allowSprayer then
					if onEnter then
						vehicle:addSprayerFillTrigger(self)
						self.trailers[otherShapeId]={vehicleType=UniversalProcessKit.VEHICLE_SPRAYER,vehicle=vehicle}
					else
						vehicle:removeSprayerFillTrigger(self)
						self.trailers[otherShapeId]=nil
					end
				end
			elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_FUELTRAILER) then
				self:print('isFueltrailer')
				if self.allowFuelTrailer then
					if onEnter then
						vehicle:addFuelFillTrigger(self)
						self.trailers[otherShapeId]={vehicleType=UniversalProcessKit.VEHICLE_FUELTRAILER,vehicle=vehicle}
					else
						vehicle:removeFuelFillTrigger(self)
						self.trailers[otherShapeId]=nil
					end
				end
			elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_SHOVEL) then
				self:print('isShovel')
				if self.allowShovel then
					if onEnter then
						self:print('shovel detected!')
						self.trailers[otherShapeId]={vehicleType=UniversalProcessKit.VEHICLE_SHOVEL,vehicle=vehicle,isFilling=false}
					else
						self.trailers[otherShapeId]=nil
						self:updateFilling()
					end
				end
			elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_FILLABLE) then
				self:print('isFillable')
				if self.allowTrailer then
					if onEnter then
						self.trailers[otherShapeId]={vehicleType=UniversalProcessKit.VEHICLE_FILLABLE,vehicle=vehicle,isFilling=false}
					elseif onLeave then
						self.trailers[otherShapeId]=nil
						self:updateFilling()
					end
				end
			elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_MOTORIZED) then
				self:print('isMotorized')
				if self.allowFuelRefill then
					if onEnter then
						vehicle:addFuelFillTrigger(self)
						self.trailers[otherShapeId]={vehicleType=UniversalProcessKit.VEHICLE_MOTORIZED,vehicle=vehicle}
					else
						vehicle:removeFuelFillTrigger(self)
						self.trailers[otherShapeId]=nil
					end
				end
			end
		end
	end
end

function UPK_FillTrigger:setFillType(fillType)
	self:print('anybody?')
	local oldFillType=self.fillType
	if fillType~=nil then
		if self.fillTypeShapes[oldFillType]~=nil then
			setVisibility(oldFillLevel,false)
		end
		if self.fillTypeShapes[fillType]~=nil then
			setVisibility(fillType,true)
		end
		self.fillType = fillType
	else
		self.fillType = Fillable.FILLTYPE_UNKNOWN
	end	
end

function UPK_FillTrigger:getIsActivatable(vehicle)
	local shapeId=0
	for k,v in pairs(self.trailers) do
		if v.vehicle==vehicle then
			shapeId=k
			break
		end
	end
	if shapeId~=nil then
		local fillType=self.fillType
		local notEmpty=(self.fillLevels[fillType] > 0 or self.createFillType)
		if self.allowSowingMachine and self.trailers[shapeId].vehicleType==UniversalProcessKit.VEHICLE_SOWINGMACHINE then
			return (self.createFillType or (fillType==FruitUtil.fruitTypeToFillType[vehicle.seeds[vehicle.currentSeed]] and self:getFillLevel(fillType)>0))
		elseif self.allowWaterTrailer and self.trailers[shapeId].vehicleType==UniversalProcessKit.VEHICLE_WATERTRAILER then
			return (fillType==Fillable.FILLTYPE_WATER and notEmpty)
		elseif self.allowLiquidManureTrailer and self.trailers[shapeId].vehicleType==UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER then
			return (fillType==Fillable.FILLTYPE_LIQUIDMANURE and notEmpty)	
		elseif self.allowSprayer and self.trailers[shapeId].vehicleType==UniversalProcessKit.VEHICLE_SPRAYER then
			return (fillType==Fillable.FILLTYPE_FERTILIZER and notEmpty)
		elseif self.allowFuelTrailer and self.trailers[shapeId].vehicleType==UniversalProcessKit.VEHICLE_FUELTRAILER then
			return (fillType==Fillable.FILLTYPE_FUEL and notEmpty)
		elseif self.allowFuelRefill and self.trailers[shapeId].vehicleType==UniversalProcessKit.VEHICLE_MOTORIZED then
			return (fillType==Fillable.FILLTYPE_FUEL and notEmpty and vehicle.fuelFillLevel<(vehicle.fuelCapacity-0.1))
		end
	end
	return false
end

function UPK_FillTrigger:setTrailerFilling(shapeId, isFilling, sendNoEvent)
	--self:print('UPK_FillTrigger:setTrailerFilling')
	local trailer=nil
	local typeShapeId=type(shapeId)
	--self:print('type of shapeId '..tostring(shapeId)..' is '..tostring(typeShapeId))
	if typeShapeId=="number" then
		trailer=self.trailers[shapeId]
	elseif typeShapeId=="table" then
		for k,v in pairs(self.trailers) do
			if v.vehicle==shapeId then
				trailer=self.trailers[k]
				break
			end
		end
	end
	--self:print('trailer is '..type(trailer))
	if trailer~=nil then
		self:print('want to set isFilling to '..tostring(isFilling))
		if trailer.isFilling~=isFilling then
			trailer.isFilling=isFilling
			if not sendNoEvent then
				--self:print('want to update '..tostring(trailer.vehicle)..' to '..tostring(trailer.isFilling))
				table.insert(self.trailersToSync,{vehicle=trailer.vehicle,isFilling=trailer.isFilling})
				--self:print('raiseDirtyFlags '..tostring(self.isFillingDirtyFlag))
				self:raiseDirtyFlags(self.isFillingDirtyFlag)
			end
			self:updateFilling()
		end
	end
end

function UPK_FillTrigger:getTrailerFilling(shapeId)
	--self:print('UPK_FillTrigger:getTrailerFilling')
	local trailer=nil
	local typeShapeId=type(shapeId)
	--self:print('type of shapeId '..tostring(shapeId)..' is '..tostring(typeShapeId))
	if typeShapeId=="number" then
		return self.trailers[shapeId].isFilling
	elseif typeShapeId=="table" then
		for k,v in pairs(self.trailers) do
			if v.vehicle==shapeId then
				return self.trailers[k].isFilling
			end
		end
	end
	return false
end

function UPK_FillTrigger:updateFilling()
	--self:print('UPK_FillTrigger:updateFilling()')
	if self.isClient then
		local trailersFilling=false
		for k,v in pairs(self.trailers) do
			if v.isFilling then
				trailersFilling=true
				break
			end
		end
		--self:print('trailersFilling='..tostring(trailersFilling))
		if trailersFilling then
			if not self.siloFillSoundEnabled and self.siloFillSound ~= nil then
				setVisibility(self.siloFillSound, true)
				self.siloFillSoundEnabled = true
			end
			Utils.setEmittingState(self.dropParticleSystems, true)
			Utils.setParticleSystemTimeScale(self.lyingParticleSystems, 1)
			if self.scroller ~= nil then
				setShaderParameter(self.scroller, self.scrollerShaderParameterName, self.scrollerSpeedX, self.scrollerSpeedY, 0, 0, false)
			end
		else
			if self.siloFillSoundEnabled and self.siloFillSound ~= nil then
				setVisibility(self.siloFillSound, false)
				self.siloFillSoundEnabled = false
			end
			Utils.setEmittingState(self.dropParticleSystems, false)
			Utils.setParticleSystemTimeScale(self.lyingParticleSystems, 0)
			if self.scroller ~= nil then
				setShaderParameter(self.scroller, self.scrollerShaderParameterName, 0, 0, 0, 0, false)
			end
		end
	end
end

function UPK_FillTrigger:fillShovel(shovel, dt)
	--self:print('UPK_FillTrigger:fillShovel')
	if self.isServer and self.isEnabled then
		fillType=self.fillType
		if not shovel:allowFillType(fillType, false) then
			self:print('fillType not allowed')
			return 0
		end
		if shovel~=nil and shovel.fillShovelFromTrigger~=nil and fillType~=Fillable.FILLTYPE_UNKNOWN then
			local fillLevel = shovel:getFillLevel(fillType)
			if shovel:allowFillType(fillType, false) then
				if (shovel.capacity~=nil and fillLevel==shovel.capacity) or (self.fillLevels[fillType]==0) then
					self:setTrailerFilling(shovel,false)
				else
					self:setTrailerFilling(shovel,true)
					local oldFillLevel=shovel:getFillLevel(fillType)
					local delta = math.min(self.fillLitersPerSecond * 0.001 * dt, self.fillLevels[fillType])
					local newFillLevel=shovel:fillShovelFromTrigger(self, delta, fillType, dt)
					delta=shovel:getFillLevel(fillType) - oldFillLevel
					if delta>0 then
						if self.pricePerLiter ~= 0 then
							local price = delta * self.pricePerLiter
							g_currentMission.missionStats.expensesTotal = g_currentMission.missionStats.expensesTotal + price
							g_currentMission.missionStats.expensesSession = g_currentMission.missionStats.expensesSession + price
							g_currentMission:addSharedMoney(-price, "other")
						end
						if not self.createFillType then
							delta=-self:addFillLevel(-delta,fillType)
						end
					end
				end
			end	
		end
		return delta
	end
	return 0
end

function UPK_FillTrigger:fillSowingMachine(vehicle, delta)
	return self:fillVehicle(vehicle, delta, Fillable.FILLTYPE_SEEDS)
end

function UPK_FillTrigger:fillWater(vehicle, delta)
	return self:fillVehicle(vehicle, delta, Fillable.FILLTYPE_WATER)
end

function UPK_FillTrigger:fillSprayer(vehicle, delta)
	local fillType=Fillable.FILLTYPE_FERTILIZER
	if vehicle:allowFillType(Fillable.FILLTYPE_LIQUIDMANURE) then
		fillType=Fillable.FILLTYPE_LIQUIDMANURE
	end
	return self:fillVehicle(vehicle, delta, fillType)
end

function UPK_FillTrigger:fillFuel(vehicle, delta)
	if self.isServer and self.isEnabled then
		fillType=Fillable.FILLTYPE_FUEL
		if not self.createFillType then
			delta=-self:addFillLevel(-delta,fillType)
		end
		local delta2=delta
		if vehicle.setFuelFillLevel ~= nil then
			if self.allowFuelRefill then
				local oldFillLevel = vehicle.fuelFillLevel
				vehicle:setFuelFillLevel(oldFillLevel + delta)
				delta2 = vehicle.fuelFillLevel - oldFillLevel
			end
		else
			local oldFillLevel = vehicle:getFillLevel(Fillable.FILLTYPE_FUEL)
			vehicle:setFillLevel(oldFillLevel + delta, Fillable.FILLTYPE_FUEL, true)
			delta2=vehicle:getFillLevel(Fillable.FILLTYPE_FUEL) - oldFillLevel
		end
		if not self.createFillType and (delta-delta2)>0 then
			self:addFillLevel(delta-delta2,fillType)
		end
		if self.pricePerLiter ~= 0 then
			local price = delta2 * self.pricePerLiter
			g_currentMission.missionStats.expensesTotal = g_currentMission.missionStats.expensesTotal + price
			g_currentMission.missionStats.expensesSession = g_currentMission.missionStats.expensesSession + price
			g_currentMission:addSharedMoney(-price, self.statName)
		end
		return delta2
	end
end

function UPK_FillTrigger:fillVehicle(vehicle, delta, fillTypeTrailer)
	if self.isServer and self.isEnabled then
		local oldFillLevel = vehicle:getFillLevel(fillTypeTrailer)
		if not self.createFillType then
			delta=-self:addFillLevel(-delta,fillTypeTrailer)
		end
		vehicle:setFillLevel(oldFillLevel + delta, fillTypeTrailer, true)
		delta2=vehicle:getFillLevel(fillTypeTrailer) - oldFillLevel
		if not self.createFillType and (delta-delta2)>0 then
			self:addFillLevel(delta-delta2,fillTypeTrailer)
		end
		if self.pricePerLiter ~= 0 then
			local price = delta2 * self.pricePerLiter
			g_currentMission.missionStats.expensesTotal = g_currentMission.missionStats.expensesTotal + price
			g_currentMission.missionStats.expensesSession = g_currentMission.missionStats.expensesSession + price
			g_currentMission:addSharedMoney(-price, self.statName)
		end
		return delta2
	end
end

function UPK_FillTrigger:updateTick(dt)
	if self.isServer and self.isEnabled then
		for k,v in pairs(self.trailers) do
			local vehicle=v.vehicle
			--self:print('vehicle '..tostring(vehicle)..' is filling '..tostring(v.isFilling))
			if v.isFilling and
				(self.allowMilkTrailer and v.vehicleType==UniversalProcessKit.VEHICLE_MILKTRAILER) then
				local fillLevel=self:getFillLevel(fillType)
				local fillType = Fillable.FILLTYPE_MILK
				local trailerFillLevel = vehicle:getFillLevel(fillType)
				if trailerFillLevel < vehicle.capacity and (fillLevel>0 or self.createFillType) then
					local delta = mathmin(self.fillLitersPerSecond/1000 * dt, vehicle.capacity-trailerFillLevel)
					vehicle:setFillLevel(trailerFillLevel + delta, Fillable.FILLTYPE_MILK, true)
					self:addFillLevel(-delta, fillType)
				else
					self:setTrailerFilling(k,false)
				end
			end
		end
	end
end;

UPK_FillTriggerActivatable = {}
local UPK_FillTriggerActivatable_mt = Class(UPK_FillTriggerActivatable)
function UPK_FillTriggerActivatable:new(upkmodule)
	local self = {}
	setmetatable(self, UPK_FillTriggerActivatable_mt)
	self.upkmodule = upkmodule or {}
	self.activateText = "unknown"
	self.currentTrailer = nil
	return self
end;
function UPK_FillTriggerActivatable:getIsActivatable()
	--print('UPK_FillTriggerActivatable:getIsActivatable')
	local fillType=self.currentTrailer.vehicle.currentFillType
	local fillLevel=self.upkmodule:getFillLevel(fillType)
	if self.currentTrailer~=nil and fillType ~= nil and
		self.currentTrailer.vehicle:allowFillType(fillType) and (fillLevel>0 or self.upkmodule.createFillType) then
		self:updateActivateText()
		--print('return true')
		return true
	end
	--print('return false')
	return false
end;
function UPK_FillTriggerActivatable:onActivateObject()
	--print('UPK_FillTriggerActivatable:onActivateObject')
	if type(self.currentTrailer)=="table" then
		--print('isFilling= '..tostring(self.currentTrailer.isFilling))
		self.upkmodule:setTrailerFilling(self.currentTrailer.vehicle, not self.currentTrailer.isFilling)
		self:updateActivateText()
		g_currentMission:addActivatableObject(self)
	end
end;
function UPK_FillTriggerActivatable:drawActivate()
end;
function UPK_FillTriggerActivatable:setCurrentTrailer(trailer)
	--print('UPK_FillTriggerActivatable:setCurrentTrailer')
	self.currentTrailer = trailer
end;
function UPK_FillTriggerActivatable:updateActivateText()
	if self.currentTrailer.isFilling then
		self.activateText = string.format(g_i18n:getText("stop_refill_OBJECT"), self.upkmodule.displayName)
	else
		self.activateText = string.format(g_i18n:getText("refill_OBJECT"), self.upkmodule.displayName)
	end
end;
