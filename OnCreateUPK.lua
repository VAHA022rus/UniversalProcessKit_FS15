-- by mor2000

OnCreateUPK_mt = Class(OnCreateUPK, Object)
InitObjectClass(OnCreateUPK, "OnCreateUPK")

function OnCreateUPK:new(isServer, isClient)
	local self = Object:new(isServer, isClient, OnCreateUPK_mt)
	registerObjectClassName(self, "OnCreateUPK")
	self.isServer=isServer
	self.isClient=isClient
	self.builtIn=true
	
	self.nextSyncId = 1
	self.objectsToSyncDirtyFlag = self:getNextDirtyFlag()
	self.upkObjects = {}
	
	self.syncedClients = {}

	return self
end

function OnCreateUPK:load(id)
	printFn('OnCreateUPK:load('..tostring(id)..')')
	
	if id==nil then
		return false
	end
	
	self.nodeId=id
	
	self.base=UPK_Base:new(self.nodeId,false,true,self)
	if self.base~=false then
		self.base:findChildren(self.nodeId)
	end
	
	g_currentMission:addNodeObject(self.nodeId, self)
	--g_currentMission:addOnCreateLoadedObjectToSave(self)
	
	return true
end

function OnCreateUPK:delete()
	if self.base~=nil then
		self.base:delete()
	end
	OnCreateUPK:superClass().delete(self)
end

function OnCreateUPK:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
	printFn('OnCreateUPK:loadFromAttributesAndNodes()')
	if self.base~=nil then
		self.base:loadFromAttributesAndNodes(xmlFile, key)
	end
	
	return true
end

function OnCreateUPK:getSaveAttributesAndNodes(nodeIdent)
	printFn('OnCreateUPK:getSaveAttributesAndNodes('..tostring(nodeIdent)..')')
	local attributes=""
	local nodes=""
	
	if self.base~=nil then
		local baseAttributes, baseNodes=self.base:getSaveAttributesAndNodes(nodeIdent)
		baseNodes = string.gsub(baseNodes,"\n","\n\t\t")
		attributes=attributes .. baseAttributes
		nodes=nodes .. baseNodes
	end
	
	return attributes, nodes
end

function OnCreateUPK:getNextObjectSyncId()
	printFn('OnCreateUPK:getNextObjectSyncId()')
	local syncId = self.nextSyncId
	self.nextSyncId = syncId + 1
	return syncId
end

function OnCreateUPK:registerObjectToSync(object)
	printFn('OnCreateUPK:registerObjectToSync(',object,')')
	local syncId = self:getNextObjectSyncId()
	table.insert(self.upkObjects, syncId, object)
	object.syncId=syncId
end

function OnCreateUPK:getObjectToSync(syncId)
	return self.upkObjects[syncId]
end

function OnCreateUPK:writeStream(streamId, connection)
	printFn('OnCreateUPK:writeStream(',streamId,', ',connection,')')
	OnCreateUPK:superClass().writeStream(self, streamId, connection)
	for i=1,(self.nextSyncId-1) do
		self.upkObjects[i]:writeStream(streamId, connection)
	end
end

function OnCreateUPK:readStream(streamId, connection)
	printFn('OnCreateUPK:readStream(',streamId,', ',connection,')')
	OnCreateUPK:superClass().readStream(self, streamId, connection)
	for i=1,(self.nextSyncId-1) do
		self.upkObjects[i]:readStream(streamId, connection)
	end
end

function OnCreateUPK:writeUpdateStream(streamId, connection, dirtyMask)
	printFn('OnCreateUPK.writeUpdateStream(',self,', ',streamId,', ',connection,')')
	OnCreateUPK:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local objectsToSync = {}
		for i=1,(self.nextSyncId-1) do
			if self.upkObjects[i].dirtyMask>0 then
				table.insert(objectsToSync,i)
			end
		end
		printAll('want to sync ',#objectsToSync,' objects')
		streamWriteAuto(streamId, #objectsToSync)
		for i=1,#objectsToSync do
			local object = self.upkObjects[objectsToSync[i]]
			--print('want to sync object with syncId '..tostring(object.syncId))
			streamWriteAuto(streamId, object.syncId)
			--print('want to sync object with dirtyFlag '..tostring(object.dirtyMask))
			streamWriteAuto(streamId, object.dirtyMask)
			local syncall=bitAND(object.dirtyMask, object.syncAllDirtyFlag)~=0
			object:writeUpdateStream(streamId, connection, object.dirtyMask, syncall)
			--print('mark client '..tostring(streamId)..' as synced')
			self.syncedClients[streamId] = true
		end
		
		local allClientsSynced=true
		for _,client in pairs(g_server.clients) do
			--print('checking if client '..tostring(client)..' is synced')
			if not self.syncedClients[client] then
				--print('client '..tostring(client)..' not synced yet')
				allClientsSynced=false
				break
			end
		end
		if allClientsSynced then
			--print('all clients are synced, reseting dirtyMask')
			for i=1,#objectsToSync do
				local object = self.upkObjects[objectsToSync[i]]
				object:doAfterAllClientsAreSynced()
			end
			self.syncedClients = {}
		end
	end
end

function OnCreateUPK:readUpdateStream(streamId, timestamp, connection)
	printFn('OnCreateUPK.readUpdateStream(',self,', ',streamId,', ',connection,')')
	OnCreateUPK:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if connection:getIsServer() then
		local nrObjectsToSync = streamReadAuto(streamId)
		printAll('reading ',nrObjectsToSync,' objects')
		if nrObjectsToSync>0 then
			for i=1,nrObjectsToSync do
				local objectSyncId = streamReadAuto(streamId)
				printAll('reading sync object with syncId ',objectSyncId)
				local objectDirtyFlag = streamReadAuto(streamId)
				printAll('reading sync object with dirtyFalg ',objectDirtyFlag)
				local object = self.upkObjects[objectSyncId]
				local syncall=bitAND(object.dirtyMask, object.syncAllDirtyFlag)~=0
				object:readUpdateStream(streamId, connection, objectDirtyFlag, syncall)
			end
		end
	end
end
