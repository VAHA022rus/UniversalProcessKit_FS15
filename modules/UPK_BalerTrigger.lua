-- by mor2000

--------------------
-- UPK_BalerTrigger (fills forage wagons and balers while switched on)

local UPK_BalerTrigger_mt = ClassUPK(UPK_BalerTrigger,UniversalProcessKit)
InitObjectClass(UPK_BalerTrigger, "UPK_BalerTrigger")
UniversalProcessKit.addModule("balertrigger",UPK_BalerTrigger)

function UPK_BalerTrigger:new(nodeId,parent)
	printFn('UPK_BalerTrigger:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId,parent, UPK_BalerTrigger_mt)
	registerObjectClassName(self, "UPK_BalerTrigger")
	
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

	self.allowedVehicles={}
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FORAGEWAGON] = getBoolFromUserAttribute(nodeId, "allowForageWagon", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_BALER] = getBoolFromUserAttribute(nodeId, "allowBaler", true)
	
	self.allowWalker = getBoolFromUserAttribute(nodeId, "allowWalker", false)
	
	self.isAdded = false
	
    self:addTrigger()
	
	self:printFn('UPK_UPK_BalerTrigger:new done')
	
	return self
end

function UPK_BalerTrigger:delete()
	self:printFn('UPK_BalerTrigger:delete()')
	UniversalProcessKitListener.removeUpdateable(self)
	UPK_BalerTrigger:superClass().delete(self)
end

function UPK_BalerTrigger:triggerUpdate(vehicle,isInTrigger)
	self:printFn('UPK_BalerTrigger:triggerUpdate(',vehicle,', ',isInTrigger,')')
	if self.isEnabled and self.isServer then
		for k,v in pairs(self.allowedVehicles) do
			--self:print('check for VEHICLE_FORAGEWAGON '..tostring(UniversalProcessKit.isVehicleType(vehicle, UniversalProcessKit.VEHICLE_FORAGEWAGON)))
			--self:print('check for VEHICLE_BALER '..tostring(UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_BALER)))
			if v and UniversalProcessKit.isVehicleType(vehicle, k) then
				if isInTrigger then
					--self:print('UniversalProcessKitListener.addUpdateable('..tostring(self)..')')
					self:getPickupNode(vehicle)
					if not self.isAdded then
						UniversalProcessKitListener.addUpdateable(self)
						self.isAdded = true
					end
				else
					if self.entitiesInTrigger==0 and self.isAdded then
						--self:print('UniversalProcessKitListener.removeUpdateable('..tostring(self)..')')
						UniversalProcessKitListener.removeUpdateable(self)
						self.isAdded = false
					end
				end
			end
		end
	end
end

function UPK_BalerTrigger:update(dt)
	self:printAll('UPK_BalerTrigger:update(',dt,')')
	if self.isServer and self.isEnabled then
		for _,trailer in pairs(self.entities) do
			local deltaFillLevel = self.fillLitersPerSecond * 0.001 * dt
			for k,v in pairs(self.allowedVehicles) do
				--self:print('is trailer VEHICLE_FORAGEWAGON '..tostring(UniversalProcessKit.isVehicleType(trailer, UniversalProcessKit.VEHICLE_FORAGEWAGON)))
				--self:print('is trailer VEHICLE_BALER '..tostring(UniversalProcessKit.isVehicleType(trailer,UniversalProcessKit.VEHICLE_BALER)))
				if v and UniversalProcessKit.isVehicleType(trailer, k) then
					if k==UniversalProcessKit.VEHICLE_FORAGEWAGON then
						self:fillForageWagon(trailer, deltaFillLevel)
					elseif k==UniversalProcessKit.VEHICLE_BALER then
						self:fillBaler(trailer, deltaFillLevel)
					end
				end
			end
		end
	end
end

function UPK_BalerTrigger:fillForageWagon(trailer, deltaFillLevel)
	self:printFn('UPK_BalerTrigger:fillForageWagon(',trailer,', ',deltaFillLevel,')')
	if self.isServer and self.isEnabled then
		--self:print('trailer.isTurnedOn = '..tostring(trailer.isTurnedOn))
		--self:print('trailer.upk_pickupNode = '..tostring(trailer.upk_pickupNode))
		if trailer.isTurnedOn and trailer.upk_pickupNode~=nil and trailer.upk_pickupNode~=0 then
			local fillFillType = self.fillFillType or self:getFillType() -- for single, fifo and filo
			local x,y,z=getWorldTranslation(trailer.upk_pickupNode)
			self.raycastTriggerFound=false
			raycastAll(x, y+20, z, 0, -1, 0, "findMyNodeRaycastCallback", 21, self)
			--self:print('self.raycastTriggerFound = '..tostring(self.raycastTriggerFound))
			if self.raycastTriggerFound then
				local trailerFillLevel = trailer:getFillLevel(trailer.currentFillType)
				local fillLevel = self:getFillLevel(fillFillType)
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
						self:printAll('deltaFillLevel 1: '..tostring(deltaFillLevel))
						if not self.createFillType then
							deltaFillLevel=-self:addFillLevel(-deltaFillLevel,fillFillType)
						end
						self:printAll('deltaFillLevel 2: '..tostring(deltaFillLevel))
						
						local pricePerLiter = self:getPricePerLiter(fillFillType)
						if pricePerLiter~=0 then
							local price = deltaFillLevel * pricePerLiter
							g_currentMission:addSharedMoney(-price, self.statName)
						end
					end
				end
			end
		end
	end
end

function UPK_BalerTrigger:fillBaler(trailer, deltaFillLevel)
	self:printFn('UPK_BalerTrigger:fillBaler(',trailer,', ',deltaFillLevel,')')
	if self.isServer and self.isEnabled then
		if trailer.isTurnedOn and trailer.upk_pickupNode~=nil and trailer.upk_pickupNode~=0 then
			local fillFillType = self.fillFillType or self:getFillType() -- for single, fifo and filo
			self:printAll('trailer.isTurnedOn = ',trailer.isTurnedOn)
			self:printAll('trailer.upk_pickupNode = ',trailer.upk_pickupNode)
			local x,y,z=getWorldTranslation(trailer.upk_pickupNode)
			self.raycastTriggerFound=false
			local distance = Utils.vector3Length(self.wpos[1]-x,self.wpos[2]-y,self.wpos[3]-z)
			self:printAll('distance = ',distance)
			raycastAll(x, y+20, z, 0, -1, 0, "findMyNodeRaycastCallback", 21, self)
			self:printAll('self.raycastTriggerFound = ',self.raycastTriggerFound)
			if self.raycastTriggerFound then
				local trailerFillLevel = trailer:getFillLevel(trailer.currentFillType)
				local fillLevel = self:getFillLevel(fillFillType)
				self:printAll('trailer:allowPickingUp() = ',trailer:allowPickingUp())
				if trailer:allowPickingUp() then
					if (fillLevel>0 or self.createFillType) and
						(fillFillType==trailer.currentFillType or trailer.currentFillType==UniversalProcessKit.FILLTYPE_UNKNOWN or
						(fillFillType~=trailer.currentFillType and trailerFillLevel<0.0001)) and
						trailer:allowFillType(fillFillType, false) and
						trailerFillLevel<trailer.capacity then

						trailer:resetFillLevelIfNeeded(fillFillType)
						if not self.createFillType then
							deltaFillLevel=math.min(deltaFillLevel, fillLevel)
						end
						if trailer.baleUnloadAnimationName == nil then
							local deltaTime = trailer:getTimeFromLevel(deltaFillLevel)
							trailer:moveBales(deltaTime)
						end
						trailer:setFillLevel(trailerFillLevel + deltaFillLevel, fillFillType)
						local newFillLevel = trailer:getFillLevel(fillFillType)
						deltaFillLevel = newFillLevel - trailerFillLevel
						if deltaFillLevel~=0 then
							self:printAll('deltaFillLevel 1: ',deltaFillLevel)
							if not self.createFillType then
								deltaFillLevel=-self:addFillLevel(-deltaFillLevel,fillFillType)
							end
							self:printAll('deltaFillLevel 2: ',deltaFillLevel)
							
							local pricePerLiter = self:getPricePerLiter(fillFillType)
							if pricePerLiter~=0 then
								local price = deltaFillLevel * pricePerLiter
								g_currentMission:addSharedMoney(-price, self.statName)
							end
							
						end
						if newFillLevel==trailer.capacity then
							do -- GIANTS code
								if trailer.baleAnimCurve ~= nil then
									self:printAll('try to dump bale')
									local restDeltaFillLevel=0.000001
									trailer:setFillLevel(0, fillFillType)
									trailer:createBale(fillFillType, trailer.capacity)
									local numBales = length(trailer.bales)
									local bale = trailer.bales[numBales]
									trailer:moveBale(numBales, trailer:getTimeFromLevel(restDeltaFillLevel), true)
									g_server:broadcastEvent(BalerCreateBaleEvent:new(trailer, fillFillType, bale.time), nil, nil, trailer)
								elseif trailer.baleUnloadAnimationName ~= nil then
									self:printAll('create bale')
									trailer:createBale(fillType, trailer.capacity)
									g_server:broadcastEvent(BalerCreateBaleEvent:new(trailer, fillFillType, 0), nil, nil, trailer)
								end
							end
						end
					end
				end
			end
		end
	end
end

function UPK_BalerTrigger:findMyNodeRaycastCallback(transformId, x, y, z, distance)
	self:printFn('UPK_BalerTrigger:findMyNodeRaycastCallback(',transformId,', ',x,', ',y,', ',z,', ',distance,')')
	if transformId==self.nodeId then
		self.raycastTriggerFound = true
		return false
	end
	return true
end

function UPK_BalerTrigger:getPickupNode(vehicle)
	self:printFn('UPK_BalerTrigger.getPickupNode(',vehicle,')')
	if vehicle.upk_pickupNode==nil then
		if not UniversalProcessKit.isVehicleType(vehicle, UniversalProcessKit.VEHICLE_FORAGEWAGON) and
			not UniversalProcessKit.isVehicleType(vehicle, UniversalProcessKit.VEHICLE_BALER) then
			vehicle.upk_pickupNode=0
		end
		local xmlFile = loadXMLFile("TempConfig", vehicle.configFileName)
		if not hasXMLProperty(xmlFile, "vehicle.pickupAnimation") then
			vehicle.upk_pickupNode=vehicle.nodeId
		else
			local pickupAnimationName = Utils.getNoNil(getXMLString(xmlFile, "vehicle.pickupAnimation#name"), "")
			if pickupAnimationName~="" then
				local i = 0
				while true do
					local key = string.format("vehicle.animations.animation(%d)", i)
					if not hasXMLProperty(xmlFile, key) then
						break
					end
					if getXMLString(xmlFile, key .. "#name")==pickupAnimationName then
						local keyNode = key..'.part'
						local index=getXMLString(xmlFile, keyNode .. "#node")
						vehicle.upk_pickupNode = Utils.getNoNil(Utils.indexToObject(vehicle.components, index), 0)
						break
					end
					i = i + 1
				end
			end
		end
		delete(xmlFile)
	end
	self:printInfo('vehicle.upk_pickupNode = '..tostring(vehicle.upk_pickupNode))
end

UPK_BalerTrigger.getPricePerLiter = UPK_FillTrigger.getPricePerLiter
