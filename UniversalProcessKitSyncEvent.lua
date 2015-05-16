-- by mor2000

_g.UniversalProcessKitSyncEvent = {}
UniversalProcessKitSyncEvent_mt = Class(UniversalProcessKitSyncEvent, Event)

function UniversalProcessKitSyncEvent:emptyNew()
	printInfo('UniversalProcessKitSyncEvent:emptyNew()')
	local self = Event:new(UniversalProcessKitSyncEvent_mt)
	return self
end

function UniversalProcessKitSyncEvent:new(objectId, toDelete)
	printInfo('UniversalProcessKitSyncEvent:new()')
	local self = UniversalProcessKitSyncEvent:emptyNew()
	self.objectId = objectId
	self.toDelete = toDelete
	return self
end

function UniversalProcessKitSyncEvent:readStream(streamId, connection)
	printInfo('UniversalProcessKitSyncEvent:readStream('..tostring(streamId)..', '..tostring(connection)..')')
	self.objectId = streamReadInt32(streamId)
	self.toDelete = streamReadBool(streamId)
	printInfo('reading toDelete = '..tostring(self.toDelete))
	self:run(connection)
end

function UniversalProcessKitSyncEvent:run(connection)
	printInfo('UniversalProcessKitSyncEvent:run('..tostring(connection)..')')
	if not connection:getIsServer() then -- should be
		if self.objectId~=nil then
			local object = networkGetObject(self.objectId)
			if object~=nil then
				printInfo('Note: network object found to synchronize')
				g_server:finishRegisterObject(connection, object)
				object:raiseDirtyFlags(object.syncDirtyFlag)
			else
				printInfo("Warning: no network object found to synchronize",true)
				--g_server:broadcastEvent(UniversalProcessKitSyncEvent:new(self.objectId,true))
			end
		end
	else
		printAll('CLIENT')
		local object = networkGetObject(self.objectId)
		if object~=nil and self.toDelete then
			printInfo('has to delete object '..tostring(object.name))
			object:unregister(true)
			object:delete()
		end
	end		
end

function UniversalProcessKitSyncEvent:writeStream(streamId, connection)
	printInfo('UniversalProcessKitSyncEvent:writeStream('..tostring(streamId)..', '..tostring(connection)..')')
	streamWriteInt32(streamId, self.objectId)
	printInfo('sending toDelete = '..tostring(self.toDelete))
	streamWriteBool(streamId, self.toDelete)
end

UniversalProcessKit.InitEventClass(UniversalProcessKitSyncEvent,"UniversalProcessKitSyncEvent")