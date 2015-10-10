-- by mor2000

function UniversalProcessKit:writeStream(streamId, connection)
	self:printFn('UniversalProcessKit:writeStream(',streamId,', ',connection,')')
	if not connection:getIsServer() then -- in connection with client
		local flbsToSync = {}
		local nrFlbsToSync = 0
		for k,_ in pairs(self.p_flbs) do
			table.insert(flbsToSync,k)
			nrFlbsToSync = nrFlbsToSync + 1
		end
		streamWriteAuto(streamId, nrFlbsToSync)
		if nrFlbsToSync>0 then
			table.sort(flbsToSync)
			for i=1,nrFlbsToSync do
				local flbIndex = flbsToSync[i]
				local flb = self.p_flbs[flbIndex]
				self:printAll('flbIndex: ',flbIndex,' flb.fillLevel: ',flb.fillLevel,' flb.fillType: ',flb.fillType)
				streamWriteAuto(streamId, flbIndex, flb.fillLevel, flb.fillType)
			end
		end
		streamWriteBool(streamId, self.isEnabled)
		streamWriteBool(streamId, self.appearsOnMap)
	end
end

function UniversalProcessKit:readStream(streamId, connection)
	self:printFn('UniversalProcessKit:readStream(',streamId,', ',connection,')')
	if connection:getIsServer() then -- in connection with server
		local nrFlbsToSync = streamReadAuto(streamId)
		if nrFlbsToSync>0 then
			for i=1,nrFlbsToSync do
				local flbIndex, fillLevel, fillTypeServer = streamReadAuto(streamId)
				self:printAll('flbIndex: ',flbIndex,' fillLevel: ',fillLevel,' fillType: ',fillTypeServer)
				local fillType = UniversalProcessKit.fillTypeIntServerToClient[fillTypeServer]
				
				if self.p_flbs[flbIndex]==nil then
					self.p_flbs[flbIndex]=FillLevelBubble:new(fillLevel,fillType)
					self.p_flbs[flbIndex].capacities = self.capacities
					self.p_flbs[flbIndex].fillTypesConversionMatrix = self.fillTypesConversionMatrix
					self.p_flbs[flbIndex]:registerOnFillLevelChangeFunc(self,"p_onFillLevelChange")
				else
					local oldFillLevel = self.p_flbs[flbIndex].fillLevel
					local toAdd = fillLevel - oldFillLevel
					_=self.p_flbs[flbIndex]+{toAdd, fillType}
				end
			end
		end
		local isEnabled = streamReadBool(streamId)
		self:setEnable(isEnabled, true)
		local appearsOnMap = streamReadBool(streamId)
		self:showMapHotspot(appearsOnMap, true)
	end
end

function UniversalProcessKit:writeUpdateStream(streamId, connection, dirtyMask, syncall)
	self:printFn('UniversalProcessKit:writeUpdateStream(',streamId,', ',connection,', ',dirtyMask,', ',syncall,')')
	if not connection:getIsServer() then
		if bitAND(dirtyMask,self.fillLevelDirtyFlag)~=0 or syncall then
			nrFillLevelsToSync = #self.fillLevelsToSync
			streamWriteAuto(streamId,nrFillLevelsToSync)
			for i=1,nrFillLevelsToSync do
				self:printInfo('want to sync ',self.fillLevelsToSync[i].fillLevel,' of ',self.fillLevelsToSync[i].fillType)
				streamWriteAuto(streamId,self.fillLevelsToSync[i].fillLevel, self.fillLevelsToSync[i].fillType)
			end
		end
		if bitAND(dirtyMask,self.isEnabledDirtyFlag)~=0 or syncall then
			streamWriteBool(streamId, self.isEnabled)
		end
		if bitAND(dirtyMask,self.mapHotspotDirtyFlag)~=0 or syncall then
			streamWriteBool(streamId, self.appearsOnMap)
		end
	end
end;

function UniversalProcessKit:doAfterAllClientsAreSynced()
	self:printFn('UniversalProcessKit:doAfterAllClientsAreSynced()')
	self.dirtyMask = 0
	self.fillLevelsToSync = {}
end;

function UniversalProcessKit:readUpdateStream(streamId, connection, dirtyMask, syncall)
	self:printFn('UniversalProcessKit:readUpdateStream(',streamId,', ',connection,', ',dirtyMask,', ',syncall,')')
	if connection:getIsServer() then
		self:printAll('self.fillLevelDirtyFlag ',self.fillLevelDirtyFlag)
		self:printAll('dirtyMask ',dirtyMask)
		self:printAll('bitAND(dirtyMask,self.fillLevelDirtyFlag)~=0 ',(bitAND(dirtyMask,self.fillLevelDirtyFlag)~=0))
		if bitAND(dirtyMask,self.fillLevelDirtyFlag)~=0 or syncall then
			local nrFillTypesToSync=streamReadAuto(streamId) or 0
			for i=1,nrFillTypesToSync do
				local newFillLevel, fillTypeServer = streamReadAuto(streamId)
				local fillType = UniversalProcessKit.fillTypeIntServerToClient[fillTypeServer]
				self:printAll('reading sync ',newFillLevel,' of ',fillType)
				local oldFillLevel = self:getFillLevel(fillType)
				self:addFillLevel(newFillLevel - oldFillLevel, fillType)
			end
		end
		if bitAND(dirtyMask,self.isEnabledDirtyFlag)~=0 or syncall then
			local isEnabled = streamReadBool(streamId)
			self:setEnable(isEnabled, true)
		end
		if bitAND(dirtyMask,self.mapHotspotDirtyFlag)~=0 or syncall then
			local appearsOnMap = streamReadBool(streamId)
			self:showMapHotspot(appearsOnMap, true)
		end
	end
end;

function UniversalProcessKit:getNextDirtyFlag()
	self:printFn('UniversalProcessKit:getNextDirtyFlag()')
	return Object.getNextDirtyFlag(self)
end

function UniversalProcessKit:raiseDirtyFlags(flag)
	self:printFn('UniversalProcessKit:raiseDirtyFlags(',flag,')')
	Object.raiseDirtyFlags(self,flag)
	self.syncObj:raiseDirtyFlags(self.syncObj.objectsToSyncDirtyFlag)
end

-- events

function UniversalProcessKit:sendEvent(eventType,...)
	self:printFn('UniversalProcessKit:sendEvent(...)')
	UniversalProcessKitEvent.sendEvent(self, false, eventType, ...)
end

function UniversalProcessKit:eventCallback(eventType, ...) -- to be overwritten
	self:printFn('UniversalProcessKit:eventCallback(',eventType,'...)')
	if eventType==UniversalProcessKitEvent.TYPE_ACTION then
		local actionId, multiplier, silent = ...
		local actionName=UniversalProcessKit.actionIdToName[actionId]
		if actionName~=nil then
			self:printAll('operate action ',actionName)
			if silent then
				self:operateActionSilent(actionName, multiplier)
			else
				self:operateAction(actionName, multiplier)
			end
		end
	end
end
