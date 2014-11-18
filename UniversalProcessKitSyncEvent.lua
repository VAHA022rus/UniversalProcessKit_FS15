-- by mor2000

_g.UniversalProcessKitSyncEvent = {}
UniversalProcessKitSyncEvent_mt = Class(UniversalProcessKitSyncEvent, Event)

function UniversalProcessKitSyncEvent:emptyNew()
	local self = Event:new(UniversalProcessKitSyncEvent_mt)
	return self
end

function UniversalProcessKitSyncEvent:new(objectId, toDelete)
	local self = UniversalProcessKitSyncEvent:emptyNew()
	self.objectId = objectId
	self.toDelete = toDelete
	return self
end

function UniversalProcessKitSyncEvent:readStream(streamId, connection)
	self.objectId = streamReadInt32(streamId)
	self.toDelete = streamReadBool(streamId)
	print('reading toDelete = '..tostring(self.toDelete))
	self:run(connection)
end

function UniversalProcessKitSyncEvent:run(connection)
	if not connection:getIsServer() then -- should be
		if self.objectId~=nil then
			local object = networkGetObject(self.objectId)
			if object~=nil then
				print('Note: network object found to synchronize')
				g_server:finishRegisterObject(connection, object)
				object:raiseDirtyFlags(object.syncDirtyFlag)
			else
				print("Warning: no network object found to synchronize",true)
				--g_server:broadcastEvent(UniversalProcessKitSyncEvent:new(self.objectId,true))
			end
		end
	else
		print('CLIENT')
		local object = networkGetObject(self.objectId)
		if object~=nil and self.toDelete then
			print('has to delete object '..tostring(object.name))
			object:unregister(true)
			object:delete()
		end
	end		
end

function UniversalProcessKitSyncEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.objectId)
	print('sending toDelete = '..tostring(self.toDelete))
	streamWriteBool(streamId, self.toDelete)
end

UniversalProcessKit.InitEventClass(UniversalProcessKitSyncEvent,"UniversalProcessKitSyncEvent")