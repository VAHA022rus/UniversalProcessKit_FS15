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

	return self
end

function OnCreateUPK:load(id)
	print('OnCreateUPK:load('..tostring(id)..')')
	
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
	print('OnCreateUPK:loadFromAttributesAndNodes()')
	if self.base~=nil then
		self.base:loadFromAttributesAndNodes(xmlFile, key)
	end
	
	return true
end

function OnCreateUPK:getSaveAttributesAndNodes(nodeIdent)
	print('OnCreateUPK:getSaveAttributesAndNodes('..tostring(nodeIdent)..')')
	local attributes=""
	local nodes=""
	
	if self.base~=nil then
		local baseAttributes, baseNodes=self.base:getSaveAttributesAndNodes(nodeIdent)
		attributes=attributes .. baseAttributes
		nodes=nodes .. baseNodes
	end
	
	return attributes, nodes
end

function OnCreateUPK:getNextObjectSyncId()
	print('OnCreateUPK:getNextObjectSyncId()')
	local syncId = self.nextSyncId
	self.nextSyncId = syncId + 1
	return syncId
end

function OnCreateUPK:registerObjectToSync(object)
	print('OnCreateUPK:registerObjectToSync('..tostring(object))
	local syncId = self:getNextObjectSyncId()
	table.insert(self.upkObjects, syncId, object)
	object.syncId=syncId
end

function OnCreateUPK:writeStream(streamId, connection)
	print('OnCreateUPK:writeStream('..tostring(streamId)..', '..tostring(connection)..')')
	OnCreateUPK:superClass().writeStream(self, streamId, connection)
	for i=1,(self.nextSyncId-1) do
		self.upkObjects[i]:writeStream(streamId, connection)
	end
end

function OnCreateUPK:readStream(streamId, connection)
	print('OnCreateUPK:readStream('..tostring(streamId)..', '..tostring(connection)..')')
	OnCreateUPK:superClass().readStream(self, streamId, connection)
	for i=1,(self.nextSyncId-1) do
		self.upkObjects[i]:readStream(streamId, connection)
	end
end

function OnCreateUPK:writeUpdateStream(streamId, connection, dirtyMask)
	print('OnCreateUPK.writeUpdateStream('..tostring(self)..', '..tostring(streamId)..', '..tostring(connection)..')')
	OnCreateUPK:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
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
			print('want to sync object with syncId '..tostring(object.syncId))
			streamWriteIntN(streamId, object.syncId, 12)
			print('want to sync object with dirtyFlag '..tostring(object.dirtyMask))
			streamWriteIntN(streamId, object.dirtyMask, 12) -- max 12 dirtyFlags
			local syncall=bitAND(object.dirtyMask, object.syncAllDirtyFlag)~=0
			object:writeUpdateStream(streamId, connection, object.dirtyMask, syncall)
			object.dirtyMask = 0
		end
	end
end

function OnCreateUPK:readUpdateStream(streamId, timestamp, connection)
	print('OnCreateUPK.readUpdateStream('..tostring(self)..', '..tostring(streamId)..', '..tostring(connection)..')')
	OnCreateUPK:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if connection:getIsServer() then
		local nrObjectsToSync = streamReadIntN(streamId, 12)
		print('reading '..tostring(nrObjectsToSync)..' objects')
		if nrObjectsToSync>0 then
			for i=1,nrObjectsToSync do
				local objectSyncId = streamReadIntN(streamId, 12)
				print('reading sync object with syncId '..tostring(objectSyncId))
				local objectDirtyFlag = streamReadIntN(streamId, 12)
				print('reading sync object with dirtyFalg '..tostring(objectDirtyFlag))
				local object = self.upkObjects[objectSyncId]
				local syncall=bitAND(object.dirtyMask, object.syncAllDirtyFlag)~=0
				object:readUpdateStream(streamId, connection, objectDirtyFlag, syncall)
			end
		end
	end
end
