-- by mor2000

PlaceableUPK_mt = Class(PlaceableUPK, Placeable)
InitObjectClass(PlaceableUPK, "PlaceableUPK")

function PlaceableUPK:new(isServer, isClient, customMt)
	local self = Placeable:new(isServer, isClient, customMt or PlaceableUPK_mt)
	registerObjectClassName(self, "PlaceableUPK")
	self.isServer=isServer
	self.isClient=isClient
	
	self.nextSyncId = 1
	self.objectsToSyncDirtyFlag = self:getNextDirtyFlag()
	self.upkObjects = {}

	self.syncedClients = {}

	return self
end

function PlaceableUPK:load(xmlFilename, x, y, z, rx, ry, rz, ...)
    if not PlaceableUPK:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, ...) then
		return false
    end
	return true
end

function PlaceableUPK:finalizePlacement(...)
	--print('PlaceableUPK:finalizePlacement(...)')
    PlaceableUPK:superClass().finalizePlacement(self, ...)
	
	--[[
	for k,v in pairs({...}) do
		print(tostring(k)..': '..tostring(v))
	end
	]]--
	
	if self.nodeId~=nil then
		self.base=UPK_Base:new(self.nodeId,true,false,self)
		if self.base~=false then
			self.base:findChildren(self.nodeId)
		end
	end
end

function PlaceableUPK:delete()
	if self.base~=nil and self.base~=false then
		self.base:delete()
	end
	PlaceableUPK:superClass().delete(self)
end

function PlaceableUPK:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
	if not PlaceableUPK:superClass().loadFromAttributesAndNodes(self, xmlFile, key, resetVehicles) then
		return false
	end
	
	if self.base~=nil then
		self.base:loadFromAttributesAndNodes(xmlFile, key)
	end
	
	return true
end

function PlaceableUPK:getSaveAttributesAndNodes(nodeIdent)
	local attributes, nodes = PlaceableUPK:superClass().getSaveAttributesAndNodes(self, nodeIdent)

	if self.base~=nil then
		local baseAttributes, baseNodes=self.base:getSaveAttributesAndNodes(nodeIdent)
		attributes=attributes .. baseAttributes
		nodes=nodes .. baseNodes
	end
	
	return attributes, nodes
end

function PlaceableUPK:getNextObjectSyncId()
	print('PlaceableUPK:getNextObjectSyncId()')
	local syncId = self.nextSyncId
	self.nextSyncId = syncId + 1
	return syncId
end

function PlaceableUPK:registerObjectToSync(object)
	print('PlaceableUPK:registerObjectToSync('..tostring(object))
	local syncId = self:getNextObjectSyncId()
	table.insert(self.upkObjects, syncId, object)
	object.syncId=syncId
end

function PlaceableUPK:getObjectToSync(syncId)
	return self.upkObjects[syncId]
end

function PlaceableUPK:writeStream(streamId, connection)
	print('PlaceableUPK:writeStream('..tostring(streamId)..', '..tostring(connection)..')')
	PlaceableUPK:superClass().writeStream(self, streamId, connection)
	for i=1,(self.nextSyncId-1) do
		self.upkObjects[i]:writeStream(streamId, connection)
	end
end

function PlaceableUPK:readStream(streamId, connection)
	print('PlaceableUPK:readStream('..tostring(streamId)..', '..tostring(connection)..')')
	PlaceableUPK:superClass().readStream(self, streamId, connection)
	for i=1,(self.nextSyncId-1) do
		self.upkObjects[i]:readStream(streamId, connection)
	end
end

function PlaceableUPK:writeUpdateStream(streamId, connection, dirtyMask)
	print('PlaceableUPK.writeUpdateStream('..tostring(self)..', '..tostring(streamId)..', '..tostring(connection)..')')
	PlaceableUPK:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local objectsToSync = {}
		for i=1,(self.nextSyncId-1) do
			if self.upkObjects[i].dirtyMask>0 then
				table.insert(objectsToSync,i)
			end
		end
		print('want to sync '..tostring(#objectsToSync)..' objects')
		streamWriteIntN(streamId, #objectsToSync, 12)
		for i=1,#objectsToSync do
			local object = self.upkObjects[objectsToSync[i]]
			--print('want to sync object with syncId '..tostring(object.syncId))
			streamWriteIntN(streamId, object.syncId, 12)
			--print('want to sync object with dirtyFlag '..tostring(object.dirtyMask))
			streamWriteIntN(streamId, object.dirtyMask, 12) -- max 12 dirtyFlags
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

function PlaceableUPK:readUpdateStream(streamId, timestamp, connection)
	print('PlaceableUPK.readUpdateStream('..tostring(self)..', '..tostring(streamId)..', '..tostring(connection)..')')
	PlaceableUPK:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if connection:getIsServer() then
		local nrObjectsToSync = streamReadIntN(streamId, 12)
		print('reading '..tostring(nrObjectsToSync)..' objects')
		if nrObjectsToSync>0 then
			for i=1,nrObjectsToSync do
				local objectSyncId = streamReadIntN(streamId, 12)
				print('reading sync object with syncId '..tostring(objectSyncId))
				local objectDirtyFlag = streamReadIntN(streamId, 12)
				print('reading sync object with dirtyFlag '..tostring(objectDirtyFlag))
				local object = self.upkObjects[objectSyncId]
				local syncall=bitAND(objectDirtyFlag, object.syncAllDirtyFlag)~=0
				object:readUpdateStream(streamId, connection, objectDirtyFlag, syncall)
			end
		end
	end
end


