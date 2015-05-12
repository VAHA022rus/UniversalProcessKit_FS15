-- by mor2000

--------------------
-- TipTrigger (that trailers can tip specific fillTypes)

UPK_TipTriggerObject_mt = Class(UPK_TipTriggerObject, Object)
InitObjectClass(UPK_TipTriggerObject, "UPK_TipTriggerObject")

function UPK_TipTriggerObject:new(isServer, isClient)
	local self = Object:new(isServer, isClient, UPK_TipTriggerObject_mt)
	registerObjectClassName(self, "UPK_TipTriggerObject")
	return self
end
function UPK_TipTriggerObject:load(tipTrigger, networkNode)
	self.tipTrigger = tipTrigger
	if g_server ~= nil then
		g_server.objectIds[self.tipTrigger] = self.id
	else
		print('register as networkNode '..tostring(networkNode))
		g_client.objectIds[self.tipTrigger] = networkNode or self.id
	end
end
function UPK_TipTriggerObject:getTipInfoForTrailer(trailer, tipReferencePointIndex)
	print('UPK_TipTriggerObject:getTipInfoForTrailer()')
	local isAllowed, minDistance, bestPoint = self.tipTrigger:getTipInfoForTrailer(trailer, tipReferencePointIndex)
	print('isAllowed: '..tostring(isAllowed)..', minDistance: '..tostring(minDistance)..', bestPoint: '..tostring(bestPoint))
	return isAllowed, minDistance, bestPoint
end
function UPK_TipTriggerObject:updateTrailerTipping(trailer, fillDelta, fillType)
	self.tipTrigger:updateTrailerTipping(trailer, fillDelta, fillType)
end
function UPK_TipTriggerObject:getTipDistanceFromTrailer(trailer, tipReferencePointIndex)
	print('UPK_TipTriggerObject:getTipDistanceFromTrailer()')
	local returnDistance, bestPoint = self.tipTrigger:getTipDistanceFromTrailer(trailer, tipReferencePointIndex)
	print('returnDistance: '..tostring(returnDistance)..', bestPoint: '..tostring(bestPoint))
	return returnDistance, bestPoint
end
function UPK_TipTriggerObject:delete()
	if g_server ~= nil then
		g_server.objectIds[self.tipTrigger] = nil
	else
		g_client.objectIds[self.tipTrigger] = nil
	end
	unregisterObjectClassName(self)
	UPK_TipTriggerObject:superClass().delete(self)
end
function UPK_TipTriggerObject:writeStream(streamId, connection)
	print('UPK_TipTriggerObject:writeStream')
	if not connection:getIsServer() then -- in connection with client
		if self.tipTrigger~=nil then
			streamWriteBool(streamId, true)
			streamWriteInt32(streamId, self.id)
			local syncObj = self.tipTrigger.syncObj
			local syncObjId = networkGetObjectId(syncObj)
			print('syncObjId: '..tostring(syncObjId))
			streamWriteInt32(streamId, syncObjId)
			local syncId = self.tipTrigger.syncId
			print('syncId: '..tostring(syncId))
			streamWriteInt32(streamId, syncId)
		else
			streamWriteBool(streamId, false)
			print('no self.tipTrigger')
		end
	end
end
function UPK_TipTriggerObject:readStream(streamId, connection)
	print('UPK_TipTriggerObject:readStream')
	if connection:getIsServer() then -- in connection with server
		local hasTipTrigger = streamReadBool(streamId)
		if hasTipTrigger then
			local networkNode = streamReadInt32(streamId)
			local syncObjId = streamReadInt32(streamId)
			print('syncObjId: '..tostring(syncObjId))
			local syncObj = networkGetObject(syncObjId)
			local syncId = streamReadInt32(streamId)
			print('syncId: '..tostring(syncId))
			if syncObj~=nil then
				g_client:addObject(self, networkNode or self.id)
				local tipTrigger = syncObj:getObjectToSync(syncId)
				self:load(tipTrigger, networkNode)
				print('self.tipTrigger: '..tostring(self.tipTrigger))
			end
		else
			print('no self.tipTrigger')
		end		
	end
end


local UPK_TipTrigger_mt = ClassUPK(UPK_TipTrigger,UniversalProcessKit)
InitObjectClass(UPK_TipTrigger, "UPK_TipTrigger")
UniversalProcessKit.addModule("tiptrigger",UPK_TipTrigger)

function UPK_TipTrigger:new(nodeId, parent)
	local self = UniversalProcessKit:new(nodeId, parent, UPK_TipTrigger_mt)
	registerObjectClassName(self, "UPK_TipTrigger")
	
	-- acceptedFillTypes
	
	self.acceptedFillTypes = {}
	
	local acceptedFillTypesArr = getArrayFromUserAttribute(nodeId, "acceptedFillTypes")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(acceptedFillTypesArr)) do
		self:print('accepting '..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(fillType)..')')
		self.acceptedFillTypes[fillType] = true
		--self.fillTypesConversionMatrix = self.fillTypesConversionMatrix + FillTypesConversionMatrix:new(fillType)
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
	
	-- add/ remove if tipping
	
	self.addIfTipping = {}
	self.useAddIfTipping = false
	local addIfTippingArr = getArrayFromUserAttribute(nodeId, "addIfTipping")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(addIfTippingArr)) do
		self:print('add if tipping '..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(fillType)..')')
		self.addIfTipping[fillType] = true
		self.useAddIfTipping = true
	end
	
	self.removeIfTipping = {}
	self.useRemoveIfTipping = false
	local removeIfTippingArr = getArrayFromUserAttribute(nodeId, "removeIfTipping")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(removeIfTippingArr)) do
		self:print('remove if tipping '..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(fillType)..')')
		self.removeIfTipping[fillType] = true
		self.useRemoveIfTipping = true
	end
	
	-- texts

	self.showNotAcceptedWarning = getBoolFromUserAttribute(nodeId, "showNotAcceptedWarning", true)
	self.showCapacityReachedWarning = getBoolFromUserAttribute(nodeId, "showCapacityReachedWarning", true)

	-- use it in your modDec.xml with these l10n settings if you want to change sth
	--[[
	<l10n>
		<text name="notAcceptedHere"> <en>is not accepted here (test)</en> <de>wird hier nicht angenommen</de> </text>
		<text name="capacityReached"> <en>the maximum filllevel of %s is reached</en> <de>Die maximale Füllmenge von %s ist erreicht</de> </text>
	</l10n>
	--]]
	
	self.allowedVehicles={}
	self.allowedVehicles[UniversalProcessKit.VEHICLE_TIPPER] = getBoolFromUserAttribute(self.nodeId, "allowTipper", true)
	
	self.allowWalker = getBoolFromUserAttribute(nodeId, "allowWalker", false)
	
	-- register trigger
	
	self:addTrigger()
	self:registerUpkTipTrigger()
	
	-- for tip event syncing
	
	if g_server ~= nil then
		self.syncTipTriggerObject = UPK_TipTriggerObject:new(self.isServer, self.isClient)
		g_server:addObject(self.syncTipTriggerObject, self.syncTipTriggerObject.id)
		self.syncTipTriggerObject:load(self)
		self.syncTipTriggerObject:register(false)
	end


	self:print('loaded TipTrigger successfully')
	
	return self
end

function UPK_TipTrigger:delete()
	if self.syncTipTriggerObject~=nil then
		self.syncTipTriggerObject:unregister()
		if g_server ~= nil then
			g_server:removeObject(self.syncTipTriggerObject, self.syncTipTriggerObject.id)
			self.syncTipTriggerObject.isRegistered = false
		else
			g_client:removeObject(self.syncTipTriggerObject, self.syncTipTriggerObject.id)
			self.syncTipTriggerObject.isRegistered = false
		end
		self.syncTipTriggerObject:delete()
		self.id=nil
	end
	
	self:unregisterUpkTipTrigger()
	self:removeTrigger()
	UPK_TipTrigger:superClass().delete(self)
end

function UPK_TipTrigger:registerUpkTipTrigger()
	table.insert(g_upkTipTrigger,self)
end

function UPK_TipTrigger:unregisterUpkTipTrigger()
	removeValueFromTable(g_upkTipTrigger,self)
end

function UPK_TipTrigger:getRevenuePerLiter(fillType)
	if self.revenuesPerLiterAdjusted[fillType]~=nil then
		return self.revenuesPerLiterAdjusted[fillType]
	end
	local revenuePerLiter = self.revenuesPerLiter[fillType]
	if self.preferMapDefaultRevenue then
		revenuePerLiter = Fillable.fillTypeIndexToDesc[fillType].pricePerLiter or revenuePerLiter
	end
	local difficulty = g_currentMission.missionStats.difficulty
	local revenuePerLiterAdjustment = self.revenuePerLiterMultiplier[difficulty]
	if revenuePerLiterAdjustment~=nil then
		revenuePerLiter = revenuePerLiter * revenuePerLiterAdjustment
	end
	self.revenuesPerLiterAdjusted[fillType] = revenuePerLiter
	return revenuePerLiter
end

function UPK_TipTrigger:updateTrailerTipping(trailer, fillDelta, fillType)
	--self:print('UPK_TipTrigger:updateTrailerTipping')
	if self.isServer then
		if type(trailer)=="table" and fillDelta~=nil then
			local toomuch=0
			if fillDelta < 0 and fillType~=nil then
				self:print('fillDelta: '..tostring(fillDelta))
				local fill = self:addFillLevel(-fillDelta,fillType)
				self:print('fill: '..tostring(fill))
				
				local revenuePerLiter = self:getRevenuePerLiter(fillType)
				if fill~=0 then
					if revenuePerLiter~=0 then
						local revenue = fill * revenuePerLiter
						g_currentMission:addSharedMoney(revenue, self.statName)
					end
					if self.useAddIfTipping then
						for fillTypeToAdd,v in pairs(self.addIfTipping) do
							if v then
								self:addFillLevel(fill,fillTypeToAdd)
							end
						end
					end
					if self.useRemoveIfTipping then
						for fillTypeToRemove,v in pairs(self.removeIfTipping) do
							if v then
								self:addFillLevel(-fill,fillTypeToRemove)
							end
						end
					end
				end
				
				self:print('fill: '..tostring(fill))
				toomuch = fillDelta + fill -- max 0
			end
			self:print('toomuch: '..tostring(toomuch))
			if toomuch<=-0.00000001 then
				self:print('end tipping')
				trailer:onEndTip()
				trailer:setFillLevel(trailer:getFillLevel(fillType)-toomuch, fillType) -- put sth back
			end
		end
	end
end

function UPK_TipTrigger:getTipInfoForTrailer(trailer, tipReferencePointIndex)
	self:print('UPK_TipTrigger:getTipInfoForTrailer')
	--if trailer.currentTipTrigger==self then
		local minDistance, bestPoint = self:getTipDistanceFromTrailer(trailer, tipReferencePointIndex)
		local trailerFillType = trailer.currentFillType
		local isAllowed = --minDistance<1 and
			self.acceptedFillTypes[trailerFillType] and
			self:allowFillType(trailerFillType)
		
		self:print('isAllowed: '..tostring(isAllowed))
		--self:print('self.acceptedFillTypes[trailerFillType]: '..tostring(self.acceptedFillTypes[trailerFillType]))
		--self:print('self:allowFillType(trailerFillType): '..tostring(self:allowFillType(trailerFillType)))
		self:print('minDistance: '..tostring(minDistance))
		return isAllowed, minDistance, bestPoint
		--end
	--return false,math.huge,nil
end

function UPK_TipTrigger:getTipDistanceFromTrailer(trailer, tipReferencePointIndex)
	self:print('UPK_TipTrigger:getTipDistanceFromTrailer')
	local minDistance = math.huge
	local returnDistance = math.huge
	local bestPoint=tipReferencePointIndex
	if tipReferencePointIndex ~= nil then
		minDistance=self:getTipDistance(trailer,tipReferencePointIndex)
		if minDistance<math.huge then
			--returnDistance=0
		end
	else
		for i,_ in pairs(trailer.tipReferencePoints) do
			if minDistance>1 then
				distance=self:getTipDistance(trailer,i)
				if distance < minDistance then
					bestPoint = i
					minDistance = distance
					--returnDistance = 0
				end
			end
		end
	end
	return minDistance/1000, bestPoint -- tiptrigger shouldnt be bigger than 1000m
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
	-- self:print('UPK_TipTrigger:getNoAllowedText('..tostring(trailer)..')')
	
	local trailerFillType = trailer.currentFillType
	local fillTypeName = self.i18n[UniversalProcessKit.fillTypeIntToName[trailerFillType]]
	local fillType = self:getFillType()
	
	local flbs=self:getFillLevelBubbleShellFromFillType(trailerFillType)
		
	self:print('fillType '..tostring(fillType))
	self:print('trailerFillType '..tostring(trailerFillType))
	self:print('newFillType '..tostring(newFillType))
	
	if flbs~=nil and trailerFillType~=Fillable.FILLTYPE_UNKNOWN and self.showCapacityReachedWarning then
		local fillLevel = flbs:getFillLevel(trailerFillType)
		local capacity = flbs:getCapacity(trailerFillType)
		
		if fillLevel==capacity then
			if string.find(self.i18n["capacityReached"], "%%s")~=nil then
				return string.format(self.i18n["capacityReached"], fillTypeName)
			else
				return self.i18n["capacityReached"] -- use no specific filltype name
			end
		end
	end
	
	if flbs==nil and trailerFillType~=Fillable.FILLTYPE_UNKNOWN and self.showNotAcceptedWarning then
		if string.find(self.i18n["notAcceptedHere"], "%%s")~=nil then
			return string.format(self.i18n["notAcceptedHere"], fillTypeName)
		else
			return fillTypeName..' '..self.i18n["notAcceptedHere"] -- standard: use filltype name in front
		end
	end

	return nil
end

function UPK_TipTrigger:triggerUpdate(vehicle,isInTrigger)
	self:print('UPK_TipTrigger:triggerUpdate('..tostring(vehicle)..','..tostring(isInTrigger)..')')
	if self.isEnabled then
		if UniversalProcessKit.isVehicleType(vehicle, UniversalProcessKit.VEHICLE_TIPPER) then
			self:print('vehicle is tipper')
			if isInTrigger then
				--if vehicle.upk_currentTipTrigger==nil then
				--	vehicle.upk_currentTipTrigger={}
				--end
				--table.insert(vehicle.upk_currentTipTrigger,self)
				if g_currentMission.trailerTipTriggers[vehicle] == nil then
					g_currentMission.trailerTipTriggers[vehicle] = {}
				end
				table.insert(g_currentMission.trailerTipTriggers[vehicle], self)
			else
				--[[
				if vehicle.upk_currentTipTrigger[1]==self then
					table.remove(vehicle.upk_currentTipTrigger,1)
				end
				]]--
				
				
				local triggers = g_currentMission.trailerTipTriggers[vehicle]
				if type(triggers) == "table" then
					removeValueFromTable(triggers,self)
					if length(triggers) == 0 then
						g_currentMission.trailerTipTriggers[vehicle] = nil
					end
				end
			end
		end
	end
end




