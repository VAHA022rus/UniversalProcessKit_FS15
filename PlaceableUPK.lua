-- by mor2000

PlaceableUPK_mt = Class(PlaceableUPK, Placeable)
InitObjectClass(PlaceableUPK, "PlaceableUPK")

function PlaceableUPK:new(isServer, isClient, customMt)
	printFn('PlaceableUPK:new(',isServer,', ',isClient,', ',customMt,')')
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
	printFn('PlaceableUPK:load(',xmlFilename,', ',x,', ',y,', ',z,', ',rx,', ',ry,', ',rz,', ...)')
    if not PlaceableUPK:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, ...) then
		return false
    end
	return true
end

function PlaceableUPK:finalizePlacement(...)
	printFn('PlaceableUPK:finalizePlacement(...)')
    PlaceableUPK:superClass().finalizePlacement(self, ...)
	
	--[[
	for k,v in pairs({...}) do
		print(tostring(k)..': '..tostring(v))
	end
	]]--
	
	if self.nodeId~=nil then
		self.base=UPK_Base:new(self.nodeId,true,false,self)
		if type(self.base)=="table" then
			if getBoolFromUserAttribute(self.base.nodeId, "adjustToTerrainHeight", false) then
				UniversalProcessKit.adjustToTerrainHeight(self.base.nodeId)
			end
			self.base:findChildren(self.nodeId)
		else
			printErr('Couldn\'t initiate this placeable upk mod. See above for first error occured as reason.')
		end
	end
end

function PlaceableUPK:delete()
	printFn('PlaceableUPK:delete()')
	if self.base~=nil and type(self.base)=="table" then
		self.base:delete()
	end
	PlaceableUPK:superClass().delete(self)
end

function PlaceableUPK:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
	printFn('PlaceableUPK:loadFromAttributesAndNodes(',xmlFile,', ',key,', ',resetVehicles,')')
	if not PlaceableUPK:superClass().loadFromAttributesAndNodes(self, xmlFile, key, resetVehicles) then
		return false
	end
	
	if self.base~=nil and type(self.base)=="table" then
		self.base:loadFromAttributesAndNodes(xmlFile, key)
	end
	
	return true
end

function PlaceableUPK:getSaveAttributesAndNodes(nodeIdent)
	printFn('PlaceableUPK:getSaveAttributesAndNodes(',nodeIdent,')')
	local attributes, nodes = PlaceableUPK:superClass().getSaveAttributesAndNodes(self, nodeIdent)

	if self.base~=nil and type(self.base)=="table" then
		local baseAttributes, baseNodes=self.base:getSaveAttributesAndNodes(nodeIdent)
		baseNodes = string.gsub(baseNodes,"\n","\n\t\t")
		attributes=attributes .. baseAttributes
		nodes=nodes .. baseNodes
	end
	
	return attributes, nodes
end

function PlaceableUPK:getNextObjectSyncId()
	printFn('PlaceableUPK:getNextObjectSyncId()')
	local syncId = self.nextSyncId
	self.nextSyncId = syncId + 1
	return syncId
end

function PlaceableUPK:registerObjectToSync(object)
	printFn('PlaceableUPK:registerObjectToSync(',object,')')
	local syncId = self:getNextObjectSyncId()
	table.insert(self.upkObjects, syncId, object)
	object.syncId=syncId
end

function PlaceableUPK:getObjectToSync(syncId)
	printFn('PlaceableUPK:getObjectToSync(',syncId,')')
	return self.upkObjects[syncId]
end

function PlaceableUPK:writeStream(streamId, connection)
	printFn('PlaceableUPK:writeStream(',streamId,', ',connection,')')
	PlaceableUPK:superClass().writeStream(self, streamId, connection)
	for i=1,(self.nextSyncId-1) do
		self.upkObjects[i]:writeStream(streamId, connection)
	end
end

function PlaceableUPK:readStream(streamId, connection)
	printFn('PlaceableUPK:readStream(',streamId,', ',connection,')')
	PlaceableUPK:superClass().readStream(self, streamId, connection)
	for i=1,(self.nextSyncId-1) do
		self.upkObjects[i]:readStream(streamId, connection)
	end
end

function PlaceableUPK:writeUpdateStream(streamId, connection, dirtyMask)
	printFn('PlaceableUPK:writeUpdateStream(',streamId,', ',connection,', ',dirtyMask,')')
	PlaceableUPK:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
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
			streamWriteAuto(streamId, object.syncId, 12)
			--print('want to sync object with dirtyFlag '..tostring(object.dirtyMask))
			streamWriteAuto(streamId, object.dirtyMask, 12) -- max 12 dirtyFlags
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
	printFn('PlaceableUPK:readUpdateStream(',streamId,', ',timestamp,', ',connection,')')
	PlaceableUPK:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if connection:getIsServer() then
		local nrObjectsToSync = streamReadAuto(streamId)
		printAll('reading ',nrObjectsToSync,' objects')
		if nrObjectsToSync>0 then
			for i=1,nrObjectsToSync do
				local objectSyncId = streamReadAuto(streamId)
				printAll('reading sync object with syncId ',objectSyncId)
				local objectDirtyFlag = streamReadAuto(streamId)
				printAll('reading sync object with dirtyFlag ',objectDirtyFlag)
				local object = self.upkObjects[objectSyncId]
				local syncall=bitAND(objectDirtyFlag, object.syncAllDirtyFlag)~=0
				object:readUpdateStream(streamId, connection, objectDirtyFlag, syncall)
			end
		end
	end
end

registerPlaceableType("placeableUPK", PlaceableUPK)

