-- by mor2000

--------------------
-- UPK_BalerTrigger (fills forage wagons and balers while switched on)

local UPK_BalerTrigger_mt = ClassUPK(UPK_BalerTrigger,UniversalProcessKit)
InitObjectClass(UPK_BalerTrigger, "UPK_BalerTrigger")
UniversalProcessKit.addModule("balertrigger",UPK_BalerTrigger)

function UPK_BalerTrigger:new(id,parent)
	local self = UniversalProcessKit:new(id,parent, UPK_BalerTrigger_mt)
	registerObjectClassName(self, "UPK_BalerTrigger")
	
	self.fillFillType = UniversalProcessKit.fillTypeNameToInt[getStringFromUserAttribute(id, "fillType", "unknown")]
	
    self.fillLitersPerSecond = getNumberFromUserAttribute(id, "fillLitersPerSecond", 1500, 0)
	self.createFillType = getBoolFromUserAttribute(id, "createFillType", false)
    self.pricePerLiter = getNumberFromUserAttribute(id, "pricePerLiter", 0)
	
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
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FORAGEWAGON] = getBoolFromUserAttribute(id, "allowForageWagon", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_BALER] = getBoolFromUserAttribute(id, "allowBaler", true)
	
	self.allowWalker = getBoolFromUserAttribute(id, "allowWalker", false)
	
	self.isAdded = false
	
    self:addTrigger()
	
	self:print('loaded BalerTrigger successfully')
	
	return self
end

function UPK_BalerTrigger:delete()
	UniversalProcessKitListener.removeUpdateable(self)
	UPK_BalerTrigger:superClass().delete(self)
end

function UPK_BalerTrigger:triggerUpdate(vehicle,isInTrigger)
	--self:print('UPK_BalerTrigger:triggerUpdate('..tostring(vehicle)..', '..tostring(isInTrigger)..')')
	if self.isEnabled and self.isServer then
		for k,v in pairs(self.allowedVehicles) do
			--self:print('check for VEHICLE_FORAGEWAGON '..tostring(UniversalProcessKit.isVehicleType(vehicle, UniversalProcessKit.VEHICLE_FORAGEWAGON)))
			--self:print('check for VEHICLE_BALER '..tostring(UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_BALER)))
			if v and UniversalProcessKit.isVehicleType(vehicle, k) then
				if isInTrigger then
					--self:print('UniversalProcessKitListener.addUpdateable('..tostring(self)..')')
					UPK_BalerTrigger.getPickupNode(vehicle)
					if not self.isAdded then
						UniversalProcessKitListener.addUpdateable(self)
						self.isAdded = true
					end
				else
					if self.entitiesInTrigger==0 and self.isAdded then
						--self:print('UniversalProcessKitListener.removeUpdateable('..tostring(self)..')')
						UniversalProcessKitListener.removeUpdateable(self)
					end
				end
			end
		end
	end
end

function UPK_BalerTrigger:update(dt)
	--self:print('UPK_BalerTrigger:update('..tostring(dt)..')')
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
	--self:print('UPK_BalerTrigger:fillForageWagon('..tostring(trailer)..', '..tostring(deltaFillLevel)..')')
	if self.isServer and self.isEnabled then
		--self:print('trailer.isTurnedOn = '..tostring(trailer.isTurnedOn))
		--self:print('trailer.upk_pickupNode = '..tostring(trailer.upk_pickupNode))
		if trailer.isTurnedOn and trailer.upk_pickupNode~=nil and trailer.upk_pickupNode~=0 then
			local x,y,z=getWorldTranslation(trailer.upk_pickupNode)
			self.raycastTriggerFound=false
			raycastAll(x, y+20, z, 0, -1, 0, "findMyNodeRaycastCallback", 21, self)
			--self:print('self.raycastTriggerFound = '..tostring(self.raycastTriggerFound))
			if self.raycastTriggerFound then
				local trailerFillLevel = trailer:getFillLevel(self.fillFillType)
				local fillLevel = self:getFillLevel(self.fillFillType)
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
	end
end

function UPK_BalerTrigger:fillBaler(trailer, deltaFillLevel)
	if self.isServer and self.isEnabled then
		if trailer.isTurnedOn and trailer.upk_pickupNode~=nil and trailer.upk_pickupNode~=0 then
			self:print('trailer.isTurnedOn = '..tostring(trailer.isTurnedOn))
			self:print('trailer.upk_pickupNode = '..tostring(trailer.upk_pickupNode))
			local x,y,z=getWorldTranslation(trailer.upk_pickupNode)
			self.raycastTriggerFound=false
			local distance = Utils.vector3Length(self.wpos[1]-x,self.wpos[2]-y,self.wpos[3]-z)
			self:print('distance = '..tostring(distance))
			raycastAll(x, y+20, z, 0, -1, 0, "findMyNodeRaycastCallback", 21, self)
			self:print('self.raycastTriggerFound = '..tostring(self.raycastTriggerFound))
			if self.raycastTriggerFound then
				local trailerFillLevel = trailer:getFillLevel(self.fillFillType)
				local fillLevel = self:getFillLevel(self.fillFillType)
				if trailer:allowPickingUp() then
					if (fillLevel>0 or self.createFillType) and trailer:allowFillType(self.fillFillType, false) and trailerFillLevel<trailer.capacity then
						trailer:resetFillLevelIfNeeded(self.fillFillType)
						if not self.createFillType then
							deltaFillLevel=math.min(deltaFillLevel, fillLevel)
						end
						if trailer.baleUnloadAnimationName == nil then
							local deltaTime = trailer:getTimeFromLevel(deltaFillLevel)
							trailer:moveBales(deltaTime)
						end
						trailer:setFillLevel(trailerFillLevel + deltaFillLevel, self.fillFillType)
						local newFillLevel = trailer:getFillLevel(self.fillFillType)
						deltaFillLevel = newFillLevel - trailerFillLevel
						if deltaFillLevel~=0 then
							if self.pricePerLiter~=0 then
								local price = delta * self.pricePerLiter
								g_currentMission:addSharedMoney(-price, self.statName)
							end
							if not self.createFillType then
								self:addFillLevel(-deltaFillLevel,self.fillFillType)
							end
						end
						if newFillLevel==trailer.capacity then
							do -- GIANTS code
								if trailer.baleAnimCurve ~= nil then
									print('try to dump bale')
									local restDeltaFillLevel=0.000001
									trailer:setFillLevel(0, self.fillFillType)
									trailer:createBale(self.fillFillType, trailer.capacity)
									local numBales = length(trailer.bales)
									local bale = trailer.bales[numBales]
									trailer:moveBale(numBales, trailer:getTimeFromLevel(restDeltaFillLevel), true)
									g_server:broadcastEvent(BalerCreateBaleEvent:new(trailer, self.fillFillType, bale.time), nil, nil, trailer)
								elseif trailer.baleUnloadAnimationName ~= nil then
									self:print('create bale')
									trailer:createBale(fillType, trailer.capacity)
									g_server:broadcastEvent(BalerCreateBaleEvent:new(trailer, self.fillFillType, 0), nil, nil, trailer)
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
	if transformId==self.nodeId then
		self.raycastTriggerFound = true
		return false
	end
	return true
end

function UPK_BalerTrigger.getPickupNode(vehicle)
	--print('UPK_BalerTrigger.getPickupNode('..tostring(vehicle)..')')
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
	print('vehicle.upk_pickupNode = '..tostring(vehicle.upk_pickupNode))
end

