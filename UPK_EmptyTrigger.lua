-- by mor2000

--------------------
-- TipTrigger (that trailers can tip specific fillTypes)


local UPK_TipTrigger_mt = ClassUPK(UPK_TipTrigger,UniversalProcessKit)
InitObjectClass(UPK_TipTrigger, "UPK_TipTrigger")
UniversalProcessKit.addModule("tiptrigger",UPK_TipTrigger)

function UPK_TipTrigger:new(id, parent)
	local self = UniversalProcessKit:new(id, parent, UPK_TipTrigger_mt)
	registerObjectClassName(self, "UPK_TipTrigger")
	
	self.fillLitersPerSecond = Utils.getNoNil(getUserAttribute(id, "fillLitersPerSecond"), 1500)

	-- acceptedFillTypes
	
	self.acceptedFillTypes = {}
	
	local acceptedFillTypesArr = getArrayFromUserAttribute(self.nodeId, "acceptedFillTypes")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(acceptedFillTypesArr)) do
		self:print('accepting '..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(fillType)..')')
		self.acceptedFillTypes[fillType] = true
		self.fillTypesConversionMatrix = self.fillTypesConversionMatrix + FillTypesConversionMatrix:new(fillType)
	end
	
	-- allowed trailers
	
	self.allowTipper = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowTipper"), true))
	self.allowWaterTrailer = self.acceptedFillTypes[Fillable.FILLTYPE_WATER]==true
	self.allowFuelTrailer = self.acceptedFillTypes[Fillable.FILLTYPE_FUEL]==true
	self.allowLiquidManureTrailer = self.acceptedFillTypes[Fillable.FILLTYPE_LIQUIDMANURE]==true
	self.allowMilkTrailer = self.acceptedFillTypes[Fillable.FILLTYPE_MILK]==true
	self.allowSprayer = self.acceptedFillTypes[Fillable.FILLTYPE_FUEL]==true
		
	-- texts

	self.getNoAllowedTextBool = getStringFromUserAttribute(self.nodeId, "showNoAllowedText")
	self.notAcceptedText = getStringFromUserAttribute(self.nodeId, "notAcceptedText", "notAcceptedHere")
	self.capacityReachedText = getStringFromUserAttribute(self.nodeId, "capacityReachedText", "capacityReached")

	self.allowedVehicles={}
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FILLABLE] = false
	self.allowedVehicles[UniversalProcessKit.VEHICLE_TIPPER] = self.allowTipper
	self.allowedVehicles[UniversalProcessKit.VEHICLE_WATERTRAILER] = self.allowWaterTrailer
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FUELTRAILER] = self.allowFuelTrailer
	self.allowedVehicles[UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER] = self.allowLiquidManureTrailer
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRAILER] = self.allowMilkTrailer

	self:addTrigger()
	self:registerUpkTipTrigger()

	self:print('loaded TipTrigger successfully')
	
	self:print('I have getTipInfoForTrailer? '..tostring(self.getTipInfoForTrailer))
	
	return self
end

function UPK_TipTrigger:delete()
	self:unregisterUpkTipTrigger()
	
	--[[
	for _,vehicle in pairs(self.trailers) do
		self:setIsTipTriggerFilling(false,vehicle)
	end
	--]]
	
	g_currentMission:removeActivatableObject(self.tipTriggerActivatable)
	self.tipTriggerActivatable=nil

	self.trailers={}
	self.liquidTrailers={}
	
	UPK_TipTrigger:superClass().delete(self)
end

function UPK_TipTrigger:registerUpkTipTrigger()
	table.insert(g_upkTipTrigger,self)
end

function UPK_TipTrigger:unregisterUpkTipTrigger()
	removeValueFromTable(g_upkTipTrigger,self)
end

function UPK_TipTrigger:updateTrailerTipping(trailer, fillDelta, fillType)
	if self.isServer then
		if type(trailer)=="table" and fillDelta~=nil then
			local toomuch=0
			if fillDelta < 0 and fillType~=nil then
				--self:print('fillDelta: '..tostring(fillDelta))
				local fill = self:addFillLevel(-fillDelta,fillType)
				--self:print('fill: '..tostring(fill))
				toomuch = fillDelta + fill -- max 0
			end
			if round(toomuch,8)<0 then
				--self:print('end tipping')
				trailer:onEndTip()
				trailer:setFillLevel(trailer:getFillLevel(fillType)-toomuch, fillType) -- put sth back
			end
		end
	end
end

function UPK_TipTrigger:getTipInfoForTrailer(trailer, tipReferencePointIndex)
	--self:print('UPK_TipTrigger:getTipInfoForTrailer')
	if trailer.upk_currentTipTrigger==self then
		--self:print('trailer.upk_currentTipTrigger==self')
		local minDistance, bestPoint = self:getTipDistanceFromTrailer(trailer, tipReferencePointIndex)
		--self:print('minDistance='..tostring(minDistance)..' bestPoint='..tostring(bestPoint))
		trailerFillType = trailer.currentFillType
		fillType = self:getFillType()
		newFillType = self.fillTypesConversionMatrix[fillType][trailerFillType]
		--self:print('fillType: '..tostring(fillType))
		--self:print('trailerFillType: '..tostring(trailerFillType))
		--self:print('newFillType: '..tostring(newFillType))
		local isAllowed = minDistance<1 and
			self.acceptedFillTypes[newFillType] and
			self:allowFillType(newFillType)
		--self:print('minDistance<1? '..tostring(minDistance<1))
		--self:print('self.acceptedFillTypes[newFillType]? '..tostring(self.acceptedFillTypes[newFillType]))
		--self:print('self:allowFillType(newFillType)? '..tostring(self:allowFillType(newFillType)))
		return isAllowed, minDistance, bestPoint
	end
	return false,math.huge,nil
end

function UPK_TipTrigger:getTipDistanceFromTrailer(trailer, tipReferencePointIndex)
	local minDistance = math.huge
	local returnDistance = math.huge
	local bestPoint=tipReferencePointIndex
	if tipReferencePointIndex ~= nil then
		minDistance=self:getTipDistance(trailer,tipReferencePointIndex)
		if minDistance<math.huge then
			returnDistance=0
		end
	else
		for i,_ in pairs(trailer.tipReferencePoints) do
			if minDistance>1 then
				distance=self:getTipDistance(trailer,i)
				if distance < minDistance then
					bestPoint = i
					minDistance = distance
					returnDistance = 0
				end
			end
		end
	end
	return returnDistance, bestPoint
end

function UPK_TipTrigger:getTipDistance(trailer,tipReferencePointIndex)
	local pointNodeX, pointNodeY, pointNodeZ = getWorldTranslation(trailer.tipReferencePoints[tipReferencePointIndex].node)
	self.raycastTriggerFound = false
	-- looks on top of the reference point if it overlaps with the trigger
	raycastAll(pointNodeX, pointNodeY+20, pointNodeZ, 0, -1, 0, "findMyNodeRaycastCallback", 21, self)
	if self.raycastTriggerFound then
		local triggerX, _, triggerZ = getWorldTranslation(self.nodeId)
		return Utils.vector2Length(pointNodeX-triggerX,pointNodeZ-triggerZ)
	end
	return math.huge
end

function UPK_TipTrigger:findMyNodeRaycastCallback(transformId, x, y, z, distance)
	if transformId==self.nodeId then
		self.raycastTriggerFound = true
		return false
	end
	return true
end

-- show text if the filltype of the trailer is not accepted
function UPK_TipTrigger:getNoAllowedText(trailer)
	local trailerFillType = trailer.currentFillType
	if self.getNoAllowedTextBool and trailerFillType~=Fillable.FILLTYPE_UNKNOWN then
		fillType=self:getFillType()
		newFillType = self.fillTypesConversionMatrix[fillType][trailerFillType]
		if self.acceptedFillTypes[newFillType]~=true then
			return g_i18n:getText(unpack(UniversalProcessKit.fillTypeIntToName(trailerFillType))) .. self.notAcceptedText
		else
			if self:getFillLevel(newFillType)>=self:getCapacity(newFillType) then
				return self.capacityReachedText .. " " ..g_i18n:getText(unpack(UniversalProcessKit.fillTypeIntToName(trailerFillType)))
			end
		end
	end
	return nil
end

function UPK_TipTrigger:triggerUpdate(vehicle,isInTrigger)
	if self.isEnabled and self.isServer then
		if UniversalProcessKit.isVehicleType(vehicle, UniversalProcessKit.VEHICLE_TIPPER) then
			if isInTrigger then
				vehicle.upk_currentTipTrigger=self
				if g_currentMission.trailerTipTriggers[vehicle] == nil then
					g_currentMission.trailerTipTriggers[vehicle] = {}
				end
				table.insert(g_currentMission.trailerTipTriggers[vehicle], self)
			else
				if vehicle.upk_currentTipTrigger==self then
					vehicle.upk_currentTipTrigger=nil
				end
				local triggers = g_currentMission.trailerTipTriggers[vehicle]
				if type(triggers) == "table" then
					removeValueFromTable(triggers,self)
					if #triggers == 0 then
						g_currentMission.trailerTipTriggers[vehicle] = nil
					end
				end
			end
		end
	end
end

-- functions for tipTriggerActivatable

function UPK_TipTrigger:update(dt)
	if self.isServer and self.isEnabled then
		if self.allowWaterTrailer or self.allowFuelTrailer or self.allowLiquidManureTrailer then
			for k,vehicle in pairs(self.liquidTrailers) do
				local fillType = vehicle.currentFillType
				if vehicle.upk_isTipTriggerFilling and
					((self.allowWaterTrailer and UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_WATERTRAILER)) or
					(self.allowFuelTrailer and UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_FUELTRAILER)) or
					(self.allowLiquidManureTrailer and UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER)) or
					(self.allowMilkTrailer and UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_MILKTRAILER))) then
					local fillLevel=self:getFillLevel(fillType)
					local trailerFillLevel = vehicle:getFillLevel(fillType)
					if trailerFillLevel > 0 and fillLevel<self.capacity then
						local delta = mathmin(self.fillLitersPerSecond/1000 * dt, trailerFillLevel)
						delta=self:addFillLevel(delta, fillType)
						vehicle:setFillLevel(trailerFillLevel - delta, fillType, true)
					else
						self:setIsTipTriggerFilling(false,vehicle)
					end
				end
			end
		end
	end
end;

function UPK_TipTrigger:enableActivatableObject(vehicle,fillType)
	self.tipTriggerActivatable:setCurrentTrailer(vehicle)
	self.tipTriggerActivatable:setFillType(vehicle.currentFillType)
	if self.trailersForActivatableObject==1 then
		g_currentMission:addActivatableObject(self.tipTriggerActivatable)
	end
end;

function UPK_TipTrigger:disableActivatableObject()
	self:setIsTipTriggerFilling(false,self.tipTriggerActivatable.currentTrailer)
	self.tipTriggerActivatable:setCurrentTrailer(nil)
	self.tipTriggerActivatable:setFillType(nil)
	if self.trailersForActivatableObject==0 then
		g_currentMission:removeActivatableObject(self.tipTriggerActivatable)
	end
end;

function UPK_TipTrigger:setIsTipTriggerFilling(isTipTriggerFilling, trailer, sendNoEvent)
	if type(trailer)=="table" and isTipTriggerFilling~=trailer.upk_isTipTriggerFilling then
		trailer.upk_isTipTriggerFilling=isTipTriggerFilling
	end
end;

UPK_TipTriggerActivatable = {}
local UPK_TipTriggerActivatable_mt = Class(UPK_TipTriggerActivatable)
function UPK_TipTriggerActivatable:new(upkmodule)
	local self = {}
	setmetatable(self, UPK_TipTriggerActivatable_mt)
	self.upkmodule = upkmodule or {}
	self.activateText = "unknown"
	self.currentTrailer = nil
	self.currentTrailerType = nil
	self.fillType = nil
	return self
end;
function UPK_TipTriggerActivatable:getIsActivatable()
	if self.upkmodule:getFillLevel(self.fillType) >= self.upkmodule:getCapacity(self.fillType) then
		return false
	end
	if self.currentTrailer~=nil and
		self.currentTrailerType~=nil and
		self.fillType ~= nil and
		self.currentTrailer:allowFillType(self.fillType) and
		self.currentTrailer:getFillLevel(self.fillType)>0 then
		self:updateActivateText()
		return true
	end
	return false
end;
function UPK_TipTriggerActivatable:onActivateObject()
	if type(self.currentTrailer)=="table" then
		self.upkmodule:setIsTipTriggerFilling(not self.currentTrailer.upk_isTipTriggerFilling, self.currentTrailer)
		self:updateActivateText()
		g_currentMission:addActivatableObject(self)
	end
end;
function UPK_TipTriggerActivatable:drawActivate()
end;
function UPK_TipTriggerActivatable:setFillType(fillType)
	self.fillType = fillType
end;
function UPK_TipTriggerActivatable:setCurrentTrailer(vehicle)
	if self.currentTrailer~=nil and self.currentTrailer.upk_isTipTriggerFilling then
		self.upkmodule:setIsTipTriggerFilling(false,self.currentTrailer)
	end
	self.currentTrailer = vehicle
	if type(vehicle)=="table" then
		if UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_WATERTRAILER) then
			self.currentTrailerType=UniversalProcessKit.VEHICLE_WATERTRAILER
		elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_SOWINGMACHINE) then
			self.currentTrailerType=UniversalProcessKit.VEHICLE_SOWINGMACHINE
		elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER) then
			self.currentTrailerType=UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER
		elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_MILKTRAILER) then
			self.currentTrailerType=UniversalProcessKit.VEHICLE_MILKTRAILER
		elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_FUELTRAILER) then
			self.currentTrailerType=UniversalProcessKit.VEHICLE_FUELTRAILER
		elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_SPRAYER) then
			self.currentTrailerType=UniversalProcessKit.VEHICLE_SPRAYER
		else
			self.currentTrailerType=nil
		end
	else
		self.currentTrailerType=nil
	end
end;
function UPK_TipTriggerActivatable:updateActivateText()
	if self.currentTrailer.upk_isTipTriggerFilling then
		self.activateText = string.format(g_i18n:getText("stop_refill_OBJECT"), self.upkmodule.displayName)
	else
		self.activateText = string.format(g_i18n:getText("refill_OBJECT"), self.upkmodule.displayName)
	end
end;

--]]


