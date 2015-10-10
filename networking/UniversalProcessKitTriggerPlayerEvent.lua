-- by mor2000

UniversalProcessKitTriggerPlayerEvent = {}
UniversalProcessKitTriggerPlayerEvent_mt = Class(UniversalProcessKitTriggerPlayerEvent, Event);
InitEventClass(UniversalProcessKitTriggerPlayerEvent, "UniversalProcessKitTriggerPlayerEvent");

function UniversalProcessKitTriggerPlayerEvent:emptyNew()
	printFn('UniversalProcessKitTriggerPlayerEvent:emptyNew()')
    local self = Event:new(UniversalProcessKitTriggerPlayerEvent_mt)
    return self
end

function UniversalProcessKitTriggerPlayerEvent:new(upkmodule, isPlayerInside)
	printFn('UniversalProcessKitTriggerPlayerEvent:emptyNew(',upkmodule, ', ', isPlayerInside,')')
	local self = UniversalProcessKitTriggerPlayerEvent:emptyNew()
	self.upkmodule = upkmodule
	self.isPlayerInside = isPlayerInside
	return self
end

function UniversalProcessKitTriggerPlayerEvent:writeStream(streamId, connection)
	printFn('UniversalProcessKitTriggerPlayerEvent:writeStream(',streamId, ', ', connection,')')
	local syncObj = self.upkmodule.syncObj
	local syncObjId = networkGetObjectId(syncObj)
	printAll('syncObjId: '..tostring(syncObjId))
	streamWriteInt32(streamId, syncObjId)
	local syncId = self.upkmodule.syncId
	printAll('syncId: '..tostring(syncId))
	streamWriteInt32(streamId, syncId)
	printAll('isPlayerInside: '..tostring(self.isPlayerInside))
	streamWriteBool(streamId, self.isPlayerInside)
end

function UniversalProcessKitTriggerPlayerEvent:readStream(streamId, connection)
	printFn('UniversalProcessKitTriggerPlayerEvent:readStream(',streamId, ', ', connection,')')
	local syncObjId = streamReadInt32(streamId)
	printAll('syncObjId: '..tostring(syncObjId))
	local syncObj = networkGetObject(syncObjId)
	local syncId = streamReadInt32(streamId)
	printAll('syncId: '..tostring(syncId))
	self.upkmodule=syncObj:getObjectToSync(syncId)
	printAll('upkmodule: '..tostring(self.upkmodule))
	self.isPlayerInside = streamReadBool(streamId)
	printAll('isPlayerInside: '..tostring(self.isPlayerInside))
	self:run(connection, streamId)
end;

function UniversalProcessKitTriggerPlayerEvent:run(connection, streamId)
	printFn('UniversalProcessKitTriggerPlayerEvent:run(',streamId, ', ', connection,')')
	if not connection:getIsServer() then -- if server: send after receiving
		printAll('running as server')
		
		printAll('self.isPlayerInside is '..tostring(self.isPlayerInside))
		
		if streamId ~= nil then
			printAll('running step a')
			printAll('streamId is '..tostring(streamId))
			if self.isPlayerInside then
				self.upkmodule.playersInRange[streamId] = true
			else
				self.upkmodule.playersInRange[streamId] = nil
			end
		
			local serverIsPlayerInside = false
			for k,v in pairs(self.upkmodule.playersInRange) do
				if v then
					printAll('serverIsPlayerInside true for streamId '..tostring(k))
					serverIsPlayerInside = true
					break
				end
			end
			self.isPlayerInside = serverIsPlayerInside or self.upkmodule.playerInRangeNetworkNode
			printAll('self.isPlayerInside is '..tostring(self.isPlayerInside))
		end
		
		if self.isPlayerInside then
			self.upkmodule:triggerOnEnter(nil, true, true)
		else
			self.upkmodule:triggerOnLeave(nil, true, true)
		end
		
		g_server:broadcastEvent(self, false, connection)

	else
		printAll('running step a')
		if self.upkmodule ~= nil then
			printAll('running step b')
			
			printAll('self.isPlayerInside is '..tostring(self.isPlayerInside))
			
			if self.isPlayerInside then
				self.upkmodule:triggerOnEnter(nil, true, true)
			else
				self.upkmodule:triggerOnLeave(nil, true, true)
			end
		end
	end
end

function UniversalProcessKitTriggerPlayerEvent.sendEvent(upkmodule, isPlayerInside, alreadySent)
	printFn('UniversalProcessKitTriggerPlayerEvent.sendEvent(',upkmodule,', ',isPlayerInside,', ',alreadySent,')')
	printAll('calling event with alreadySent = '..tostring(alreadySent))
	if not alreadySent then
		if g_server ~= nil then
			printAll('broadcasting isPlayerInside = '..tostring(isPlayerInside))
			g_server:broadcastEvent(UniversalProcessKitTriggerPlayerEvent:new(upkmodule, isPlayerInside))
		else
			printAll('sending to server isPlayerInside = '..tostring(isPlayerInside))
			g_client:getServerConnection():sendEvent(UniversalProcessKitTriggerPlayerEvent:new(upkmodule, isPlayerInside))
		end
	end
end