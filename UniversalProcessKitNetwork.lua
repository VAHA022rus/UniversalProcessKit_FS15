-- by mor2000

function UniversalProcessKit:writeStream(streamId, connection)
	self:printFn('UniversalProcessKit:writeStream('..tostring(streamId)..', '..tostring(connection)..')')
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
				streamWriteIntN(streamId, flbIndex, 17)
				streamWriteFloat32(streamId, fillLevel)
				streamWriteIntN(streamId, fillType, 17)
			end
		end
		streamWriteBool(streamId, self.isEnabled)
		streamWriteBool(streamId, self.appearsOnMap)
	end
end

function UniversalProcessKit:readStream(streamId, connection)
	self:printFn('UniversalProcessKit:readStream('..tostring(streamId)..', '..tostring(connection)..')')
	if connection:getIsServer() then -- in connection with server
		local nrFlbsToSync = streamReadInt8(streamId)
		if nrFlbsToSync>0 then
			for i=1,nrFlbsToSync do
				local flbIndex = streamReadIntN(streamId,17)
				local fillLevel = streamReadFloat32(streamId)
				local fillType = UniversalProcessKit.fillTypeIntServerToClient[streamReadIntN(streamId, 17)]
				
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
	self:printFn('UniversalProcessKit:writeUpdateStream('..tostring(streamId)..', '..tostring(connection)..', '..tostring(dirtyMask)..', '..tostring(syncall)..')')
	if not connection:getIsServer() then
		if bitAND(dirtyMask,self.fillLevelDirtyFlag)~=0 or syncall then
			nrFillLevelsToSync = #self.fillLevelsToSync
			streamWriteIntN(streamId,nrFillLevelsToSync,8)
			for i=1,nrFillLevelsToSync do
				self:printInfo('want to sync '..tostring(self.fillLevelsToSync[i].fillLevel)..' of '..tostring(self.fillLevelsToSync[i].fillType))
				streamWriteFloat32(streamId,self.fillLevelsToSync[i].fillLevel)
				streamWriteIntN(streamId,self.fillLevelsToSync[i].fillType,17)
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
	self:printFn('UniversalProcessKit:readUpdateStream('..tostring(streamId)..', '..tostring(connection)..', '..tostring(dirtyMask)..', '..tostring(syncall)..')')
	if connection:getIsServer() then
		self:printAll('self.fillLevelDirtyFlag ',self.fillLevelDirtyFlag)
		self:printAll('dirtyMask ',dirtyMask)
		self:printAll('bitAND(dirtyMask,self.fillLevelDirtyFlag)~=0 ',(bitAND(dirtyMask,self.fillLevelDirtyFlag)~=0))
		if bitAND(dirtyMask,self.fillLevelDirtyFlag)~=0 or syncall then
			nrFillTypesToSync=streamReadIntN(streamId,8) or 0
			for i=1,nrFillTypesToSync do
				newFillLevel = streamReadFloat32(streamId)
				fillType = UniversalProcessKit.fillTypeIntServerToClient[streamReadIntN(streamId,17)]
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
	self:printFn('UniversalProcessKit:raiseDirtyFlags('..tostring(flag)..')')
	Object.raiseDirtyFlags(self,flag)
	self.syncObj:raiseDirtyFlags(self.syncObj.objectsToSyncDirtyFlag)
end

----------------------------------
-- object to sync fill types -----
----------------------------------

UPK_FillTypesSyncingObject = {}
UPK_FillTypesSyncingObject_mt = Class(UPK_FillTypesSyncingObject, Object)
InitObjectClass(UPK_FillTypesSyncingObject, "UPK_FillTypesSyncingObject")

function UPK_FillTypesSyncingObject:new(isServer, isClient)
	printFn('UPK_FillTypesSyncingObject:new('..tostring(isServer)..', '..tostring(isClient)..')')
	local self = Object:new(isServer, isClient, UPK_FillTypesSyncingObject_mt)
	registerObjectClassName(self, "UPK_FillTypesSyncingObject")
	printInfo('UPK_FillTypesSyncingObject id is '..tostring(self.id))
	self.fillTypeNamesToSyncDirtyFlag = self:getNextDirtyFlag()
	self.fillTypeNamesToSync = {}
	
	return self
end

UPK_FillTypesSyncingObject.load = emptyFunc
UPK_FillTypesSyncingObject.update = emptyFunc

function UPK_FillTypesSyncingObject:delete()
	printFn('UPK_FillTypesSyncingObject:delete()')
	if g_client ~= nil then
		local serverId = g_client:getObjectId(self)
		printAll('serverId = '..tostring(serverId))
	end
	
	
	--[[
	
	unregisterObjectClassName(self)
	
	self:unregister()
	if g_server ~= nil then
		g_server:unregisterObject(self)
		g_server:removeObject(self, self.id)
		--self.isRegistered = false
	else
		local serverId = g_client:getObjectId(self)
		print('serverId = '..tostring(serverId))
		print('g_client.tempClientCreatingObjects[serverId] = '..tostring(g_client.tempClientCreatingObjects[serverId]))
	--]]
		--[[
		if serverId~=nil and serverId~=0 then		
			g_client:unregisterObject(self, true)
		end
		
		local serverId = g_client:getObjectId(self)
		print('serverId = '..tostring(serverId))
		
		print('g_client.tempClientCreatingObjects[serverId] = '..tostring(g_client.tempClientCreatingObjects[serverId]))
		]]--
		--g_client:removeObject(self, self.net)
		--self.isRegistered = false
	--end
	UPK_FillTypesSyncingObject:superClass().delete(self)
end

function UPK_FillTypesSyncingObject:addFillTypeNameToSync(name)
	printFn('UPK_FillTypesSyncingObject:addFillTypeNameToSync('..tostring(name)..')')
	if type(name)=="string" and name ~= "" then
		table.insert(self.fillTypeNamesToSync, name)
		self:raiseDirtyFlags(self.fillTypeNamesToSyncDirtyFlag)
	end
end

function UPK_FillTypesSyncingObject:writeStream(streamId, connection)
	printFn('UPK_FillTypesSyncingObject:writeStream('..tostring(streamId)..', '..tostring(connection)..')')
	if not connection:getIsServer() then -- in connection with client
		printInfo('serverId = '..tostring(self.id))
		streamWriteInt32(streamId, self.id)
		
		local countFillTypes = 0
		for fillType=32768,UniversalProcessKit.NUM_FILLTYPES do
			local fillTypeName = UniversalProcessKit.fillTypeIntToName[fillType]
			if fillTypeName~=nil then
				printInfo('I have fill type \"'..tostring(fillTypeName)..'\" to sync')
				countFillTypes = countFillTypes + 1
			end
		end
		streamWriteInt16(streamId, countFillTypes)
		for fillType=32768,UniversalProcessKit.NUM_FILLTYPES do
			local fillTypeName = UniversalProcessKit.fillTypeIntToName[fillType]
			if fillTypeName~=nil then
				streamWriteIntN(streamId, fillType, 17)
				streamWriteString(streamId, fillTypeName)
			end
		end
	end
end

function UPK_FillTypesSyncingObject:readStream(streamId, connection)
	printFn('UPK_FillTypesSyncingObject:readStream('..tostring(streamId)..', '..tostring(connection)..')')
	if connection:getIsServer() then -- in connection with server
		local networkNode = streamReadInt32(streamId)
		g_client:finishRegisterObject(self, networkNode or self.id)
		local serverId = g_client:getObjectId(self)
		printInfo('serverId = '..tostring(serverId))
		printInfo('g_client.tempClientCreatingObjects[serverId] = '..tostring(g_client.tempClientCreatingObjects[serverId]))
		
		
		local countFillTypes = streamReadInt16(streamId)
		for i=1,countFillTypes do
			local fillTypeServer = streamReadIntN(streamId, 17)
			local fillTypeName = streamReadString(streamId)
			local fillTypeClient = UniversalProcessKit.fillTypeNameToInt[fillTypeName]
			printInfo('got fill type \"'..tostring(fillTypeName)..'\" with # '..tostring(fillTypeServer)..' from server, mine is '..
					tostring(fillTypeClient))
			if fillTypeServer ~= fillTypeClient then
				if fillTypeClient == nil then
					local index = UniversalProcessKit.addFillType(fillTypeName)
					if index ~= fillTypeServer then
						rawset(UniversalProcessKit.fillTypeIntServerToClient, fillTypeServer, index)
						rawset(UniversalProcessKit.fillTypeIntClientToServer, index, fillTypeServer)
					end
				elseif type(fillTypeClient)=="number" then
					rawset(UniversalProcessKit.fillTypeIntServerToClient, fillTypeServer, fillTypeClient)
					rawset(UniversalProcessKit.fillTypeIntClientToServer, fillTypeClient, fillTypeServer)
				end
			end
		end
	end
end

function UPK_FillTypesSyncingObject:writeUpdateStream(streamId, connection, dirtyMask)
	printFn('UPK_FillTypesSyncingObject:writeUpdateStream('..tostring(streamId)..', '..tostring(connection)..', '..tostring(dirtyMask)..')')
	if not connection:getIsServer() then -- in connection with client
		local fillTypeNamesToSyncNr = #self.fillTypeNamesToSync
		streamWriteInt16(streamId, fillTypeNamesToSyncNr)
		for i=1,fillTypeNamesToSyncNr do
			local fillTypeName = self.fillTypeNamesToSync[i]
			local fillType = UniversalProcessKit.fillTypeNameToInt[fillTypeName]
			streamWriteIntN(streamId, fillType, 17)
			streamWriteString(streamId, fillTypeName)
		end
		self.fillTypeNamesToSync = {}
	end
end

function UPK_FillTypesSyncingObject:readUpdateStream(streamId, timestamp, connection)
	printFn('UPK_FillTypesSyncingObject:readUpdateStream('..tostring(streamId)..', '..tostring(timestamp)..', '..tostring(connection)..')')
	if connection:getIsServer() then -- in connection with server
		local fillTypeNamesToSyncNr = streamReadInt16(streamId)
		for i=1,fillTypeNamesToSyncNr do
			local fillTypeServer = streamReadIntN(streamId, 17)
			local fillTypeName = streamReadString(streamId)
			local fillTypeClient = UniversalProcessKit.fillTypeNameToInt[fillTypeName]
			printAll('got fill type \"'..tostring(fillTypeName)..'\" with # '..tostring(fillTypeServer)..' from server, mine is '..
					tostring(fillTypeClient))
			if fillTypeServer ~= fillTypeClient then
				if fillTypeClient == nil then
					local index = UniversalProcessKit.addFillType(fillTypeName)
					if index ~= fillTypeServer then
						rawset(UniversalProcessKit.fillTypeIntServerToClient, fillTypeServer, index)
						rawset(UniversalProcessKit.fillTypeIntClientToServer, index, fillTypeServer)
					end
				elseif type(fillTypeClient)=="number" then
					rawset(UniversalProcessKit.fillTypeIntServerToClient, fillTypeServer, fillTypeClient)
					rawset(UniversalProcessKit.fillTypeIntClientToServer, fillTypeClient, fillTypeServer)
				end
			end
		end
	end
end
