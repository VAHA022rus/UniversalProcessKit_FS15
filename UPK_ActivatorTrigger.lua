-- by mor2000

--------------------
-- ActivatorTrigger (enables children if keypressed)

local UPK_ActivatorTrigger_mt = ClassUPK(UPK_ActivatorTrigger,UniversalProcessKit)
InitObjectClass(UPK_ActivatorTrigger, "UPK_ActivatorTrigger")
UniversalProcessKit.addModule("activatortrigger",UPK_ActivatorTrigger)

function UPK_ActivatorTrigger:new(nodeId, parent)
	local self = UniversalProcessKit:new(nodeId, parent, UPK_ActivatorTrigger_mt)
	registerObjectClassName(self, "UPK_ActivatorTrigger")
	
	self:setIsActive(getBoolFromUserAttribute(nodeId, "isActive", false), true)
	
	local function returnNilIfEmptyString(str)
		if str=="" then
			return nil
		end
		return str
	end
	
	self.activateText = returnNilIfEmptyString(self.i18n[getStringFromUserAttribute(nodeId, "activateText")]) or "[activateText]"
	self.deactivateText = returnNilIfEmptyString(self.i18n[getStringFromUserAttribute(nodeId, "deactivateText")]) or "[deactivateText]"
	
	self.activatorActivatable = UPK_ActivatorTriggerActivatable:new(self)
	self.activatorActivatableAdded=false

	self:addTrigger()

	self:print('loaded ActivatorTrigger successfully')
	
	return self
end

function UPK_ActivatorTrigger:postLoad()
	UPK_ActivatorTrigger:superClass().postLoad(self)
	self:triggerUpdate(false,false)
end

function UPK_ActivatorTrigger:readStream(streamId, connection)
	UPK_ActivatorTrigger:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		local isActive = streamReadBool(streamId)
		self:print('read from stream self.isActive = '..tostring(isActive))
		self:setIsActive(isActive,true)
	end
end;

function UPK_ActivatorTrigger:writeStream(streamId, connection)
	UPK_ActivatorTrigger:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		self:print('write to stream self.isActive = '..tostring(self.isActive))
		streamWriteBool(streamId,self.isActive)
	end
end;

function UPK_ActivatorTrigger:triggerUpdate(vehicle,isInTrigger)
	print('UPK_ActivatorTrigger:triggerUpdate()')
	if self.isClient then
		self:print('self.entitiesInTrigger='..tostring(self.entitiesInTrigger))
		if self.entitiesInTrigger>0 then
			if not self.activatorActivatableAdded and self:getShowInfo() then
				self:print('addActivatableObject')
				g_currentMission:addActivatableObject(self.activatorActivatable)
				self.activatorActivatableAdded=true
			end
		else
			if self.activatorActivatableAdded then
				self:print('removeActivatableObject')
				g_currentMission:removeActivatableObject(self.activatorActivatable)
				self.activatorActivatableAdded=false
			end
		end
	end
end

function UPK_ActivatorTrigger:setIsActive(isActive,alreadySent)
	self:print('UPK_ActivatorTrigger:setIsActive('..tostring(isActive)..', '..tostring(alreadySent)..')')
	if isActive~=nil then
		self.isActive=isActive
		self:setEnableChildren(self.isActive,alreadySent)
		if not alreadySent then
			UPK_ActivatorTriggerEvent.sendEvent(self,self.isActive, alreadySent)
		end
	end
end

function UPK_ActivatorTrigger:loadExtraNodes(xmlFile, key)
	self:setIsActive(Utils.getNoNil(getXMLBool(xmlFile, key .. "#isActive"), false), true)
	return true
end;

function UPK_ActivatorTrigger:getSaveExtraNodes(nodeIdent)
	local nodes=""
	if self.isActive then
		nodes=nodes.." isActive=\"true\""
	end
	return nodes
end;


UPK_ActivatorTriggerActivatable = {}
local UPK_ActivatorTriggerActivatable_mt = Class(UPK_ActivatorTriggerActivatable)

function UPK_ActivatorTriggerActivatable:new(upkmodule)
	local self = {}
	setmetatable(self, UPK_ActivatorTriggerActivatable_mt)
	self.upkmodule = upkmodule or {}
	self.activateText = "unknown"
	return self
end;

function UPK_ActivatorTriggerActivatable:getIsActivatable()
	if self.upkmodule.isEnabled then
		self:updateActivateText()
		return true
	end
	return false
end;

function UPK_ActivatorTriggerActivatable:onActivateObject()
	if self.upkmodule.isEnabled then
		print('self.upkmodule:setIsActive('..tostring(not self.upkmodule.isActive)..')')
		self.upkmodule:setIsActive(not self.upkmodule.isActive, false)
		self:updateActivateText()
		g_currentMission:addActivatableObject(self)
	end
end;

function UPK_ActivatorTriggerActivatable:drawActivate()
end;

function UPK_ActivatorTriggerActivatable:updateActivateText()
	if self.upkmodule.isActive then
		self.activateText = self.upkmodule.deactivateText
	else
		self.activateText = self.upkmodule.activateText
	end
end;

UPK_ActivatorTriggerEvent = {}
UPK_ActivatorTriggerEvent_mt = Class(UPK_ActivatorTriggerEvent, Event);
InitEventClass(UPK_ActivatorTriggerEvent, "UPK_ActivatorTriggerEvent");

function UPK_ActivatorTriggerEvent:emptyNew()
    local self = Event:new(UPK_ActivatorTriggerEvent_mt)
    return self
end

function UPK_ActivatorTriggerEvent:new(upkmodule, isActive)
	local self = UPK_ActivatorTriggerEvent:emptyNew()
	self.upkmodule = upkmodule
	self.isActive = isActive
	return self
end

function UPK_ActivatorTriggerEvent:writeStream(streamId, connection)
	local syncObj = self.upkmodule.syncObj
	local syncObjId = networkGetObjectId(syncObj)
	print('syncObjId: '..tostring(syncObjId))
	streamWriteInt32(streamId, syncObjId)
	local syncId = self.upkmodule.syncId
	print('syncId: '..tostring(syncId))
	streamWriteInt32(streamId, syncId)
	print('isActive: '..tostring(self.isActive))
	streamWriteBool(streamId, self.isActive)
end

function UPK_ActivatorTriggerEvent:readStream(streamId, connection)
	local syncObjId = streamReadInt32(streamId)
	print('syncObjId: '..tostring(syncObjId))
	local syncObj = networkGetObject(syncObjId)
	local syncId = streamReadInt32(streamId)
	print('syncId: '..tostring(syncId))
	self.upkmodule=syncObj:getObjectToSync(syncId)
	print('upkmodule: '..tostring(self.upkmodule))
	self.isActive = streamReadBool(streamId)
	print('isActive: '..tostring(self.isActive))
	self:run(connection)
end;

function UPK_ActivatorTriggerEvent:run(connection)
	if not connection:getIsServer() then -- if server: send after receiving
		g_server:broadcastEvent(self, false, connection)
	end
	print('running step a')
	if self.upkmodule ~= nil then
		print('running step b')
		self.upkmodule:setIsActive(self.isActive, true)
	end
end

function UPK_ActivatorTriggerEvent.sendEvent(upkmodule, isActive, alreadySent)
	print('UPK_ActivatorTriggerEvent.sendEvent('..tostring(upkmodule)..', '..tostring(isActive)..', '..tostring(alreadySent)..')')
	print('calling event with alreadySent = '..tostring(alreadySent))
	if not alreadySent then
		if g_server ~= nil then
			print('broadcasting isActive = '..tostring(isActive))
			g_server:broadcastEvent(UPK_ActivatorTriggerEvent:new(upkmodule, isActive))
		else
			print('sending to server isActive = '..tostring(isActive))
			g_client:getServerConnection():sendEvent(UPK_ActivatorTriggerEvent:new(upkmodule, isActive))
		end
	end
end