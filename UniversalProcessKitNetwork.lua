-- by mor2000

function UniversalProcessKit:writeStream(streamId, connection)
	if not connection:getIsServer() then -- in connection with client
		local flbsToSync = {}
		local nrFlbsToSync = 0
		for k,_ in pairs(self.p_flbs) do
			table.insert(flbsToSync,k)
			nrFlbsToSync = nrFlbsToSync + 1
		end
		streamWriteInt8(streamId, nrFlbsToSync)
		if nrFlbsToSync>0 then
			table.sort(flbsToSync)
			for i=1,nrFlbsToSync do
				local flbIndex = flbsToSync[i]
				local flb = self.p_flbs[flbIndex]
				local fillLevel = flb.fillLevel
				local fillType = flb.fillType
				streamWriteInt16(streamId, flbIndex)
				streamWriteFloat32(streamId, fillLevel)
				streamWriteInt16(streamId, fillType)
			end
		end
		streamWriteBool(streamId, self.isEnabled)
		streamWriteBool(streamId, self.appearsOnMap)
	end
end

function UniversalProcessKit:readStream(streamId, connection)
	if connection:getIsServer() then -- in connection with server
		local nrFlbsToSync = streamReadInt8(streamId)
		if nrFlbsToSync>0 then
			for i=1,nrFlbsToSync do
				local flbIndex = streamReadInt16(streamId)
				local fillLevel = streamReadFloat32(streamId)
				local fillType = streamReadInt16(streamId)
				
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
		self:print('streamReadBool: isEnabled = '..tostring(isEnabled))
		self:setEnable(isEnabled, true)
		local appearsOnMap = streamReadBool(streamId)
		self:print('streamReadBool: showMapHotspot = '..tostring(appearsOnMap))
		self:showMapHotspot(appearsOnMap, true)
	end
end

function UniversalProcessKit:writeUpdateStream(streamId, connection, dirtyMask, syncall)
	self:print('UniversalProcessKit:writeUpdateStream('..tostring(streamId)..', '..tostring(connection)..', '..tostring(dirtyMask)..', '..tostring(syncall)..')')
	if not connection:getIsServer() then
		if bitAND(dirtyMask,self.fillLevelDirtyFlag)~=0 or syncall then
			nrFillLevelsToSync = #self.fillLevelsToSync
			streamWriteIntN(streamId,nrFillLevelsToSync,8)
			for i=1,nrFillLevelsToSync do
				self:print('want to sync '..tostring(self.fillLevelsToSync[i].fillLevel)..' of '..tostring(self.fillLevelsToSync[i].fillType))
				streamWriteFloat32(streamId,self.fillLevelsToSync[i].fillLevel)
				streamWriteIntN(streamId,self.fillLevelsToSync[i].fillType,12)
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
	self.dirtyMask = 0
	self.fillLevelsToSync = {}
end;

function UniversalProcessKit:readUpdateStream(streamId, connection, dirtyMask, syncall)
	self:print('UniversalProcessKit:readUpdateStream('..tostring(streamId)..', '..tostring(connection)..', '..tostring(dirtyMask)..', '..tostring(syncall)..')')
	if connection:getIsServer() then
		self:print('self.fillLevelDirtyFlag '..tostring(self.fillLevelDirtyFlag))
		self:print('dirtyMask '..tostring(dirtyMask))
		self:print('bitAND(dirtyMask,self.fillLevelDirtyFlag)~=0 '..tostring(bitAND(dirtyMask,self.fillLevelDirtyFlag)~=0))
		if bitAND(dirtyMask,self.fillLevelDirtyFlag)~=0 or syncall then
			nrFillTypesToSync=streamReadIntN(streamId,8) or 0
			for i=1,nrFillTypesToSync do
				newFillLevel = streamReadFloat32(streamId)
				fillType = streamReadIntN(streamId,12)
				self:print('reading sync '..tostring(newFillLevel)..' of '..tostring(fillType))
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
	print('UniversalProcessKit:getNextDirtyFlag()')
	return Object.getNextDirtyFlag(self)
end

function UniversalProcessKit:raiseDirtyFlags(flag)
	print('UniversalProcessKit:raiseDirtyFlags('..tostring(flag)..')')
	Object.raiseDirtyFlags(self,flag)
	self.syncObj:raiseDirtyFlags(self.syncObj.objectsToSyncDirtyFlag)
end
