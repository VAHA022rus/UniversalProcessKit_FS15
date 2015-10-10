-- by mor2000

-- UniversalProcessKitEvent

UniversalProcessKitEvent = {}
UniversalProcessKitEvent_mt = Class(UniversalProcessKitEvent, Event);
InitEventClass(UniversalProcessKitEvent, "UniversalProcessKitEvent");

UniversalProcessKitEvent.TYPE_ACTION = 1
UniversalProcessKitEvent.TYPE_INPUT = 2
UniversalProcessKitEvent.TYPE_ACTIVATOR = 3
UniversalProcessKitEvent.TYPE_FILLTYPESELECTED = 4
UniversalProcessKitEvent.TYPE_PLAY = 5
UniversalProcessKitEvent.TYPE_STOP = 6

function UniversalProcessKitEvent:emptyNew()
	printFn('UniversalProcessKitEvent:emptyNew()')
    local self = Event:new(UniversalProcessKitEvent_mt)
    return self
end

function UniversalProcessKitEvent:new(upkmodule, ...)
	printFn('UniversalProcessKitEvent:new(',upkmodule,', ...)')
	local self = UniversalProcessKitEvent:emptyNew()
	self.upkmodule = upkmodule
	self.args = {...}
	if self.upkmodule==nil then
		printErr('no upk module given to event')
		return false
	end
	return self
end

function UniversalProcessKitEvent:writeStream(streamId, connection)
	printFn('UniversalProcessKitEvent:writeStream(',streamId,', ',connection,')')
	-- syncObj, syncId
	local syncObj = self.upkmodule.syncObj
	local syncObjId = networkGetObjectId(syncObj)
	local syncId = self.upkmodule.syncId
	streamWriteAuto(streamId, syncObjId)
	streamWriteAuto(streamId, syncId)
	-- args
	streamWriteAuto(streamId, unpack(self.args))
end

function UniversalProcessKitEvent:readStream(streamId, connection)
	printFn('UniversalProcessKitEvent:readStream(',streamId,', ',connection,')')
	-- syncObj, syncId
	local syncObjId = streamReadAuto(streamId)
	local syncId = streamReadAuto(streamId)
	local syncObj = networkGetObject(syncObjId)
	self.upkmodule=syncObj:getObjectToSync(syncId)
	-- args
	self.args={streamReadAuto(streamId)}
	self:run(connection)
end;

function UniversalProcessKitEvent:run(connection)
	printFn('UniversalProcessKitEvent:run(',connection,')')
	if not connection:getIsServer() then -- if server: send after receiving
		g_server:broadcastEvent(self, false, connection)
	end
	self.upkmodule['eventCallback'](self.upkmodule,unpack(self.args))
end

function UniversalProcessKitEvent.sendEvent(upkmodule, alreadySent, ...)
	printFn('UniversalProcessKitEvent.sendEvent(',upkmodule,', ',alreadySent,',...)')
	if not alreadySent then
		if g_server ~= nil then
			printAll('broadcasting')
			g_server:broadcastEvent(UniversalProcessKitEvent:new(upkmodule, ...))
		else
			printAll('sending to server')
			g_client:getServerConnection():sendEvent(UniversalProcessKitEvent:new(upkmodule, ...))
		end
	end
end
