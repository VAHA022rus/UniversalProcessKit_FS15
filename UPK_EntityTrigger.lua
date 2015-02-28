-- by mor2000

--------------------
-- EntityTrigger (enables modules if vehicle or walker is present)


local UPK_EntityTrigger_mt = ClassUPK(UPK_EntityTrigger,UniversalProcessKit)
InitObjectClass(UPK_EntityTrigger, "UPK_EntityTrigger")
UniversalProcessKit.addModule("entitytrigger",UPK_EntityTrigger)

function UPK_EntityTrigger:new(nodeId, parent)
	local self = UniversalProcessKit:new(nodeId, parent, UPK_EntityTrigger_mt)
	registerObjectClassName(self, "UPK_EntityTrigger")
	
	self.enableOnEmpty = getBoolFromUserAttribute(nodeId, "enableOnEmpty", false)
	
	self:print('self.enableOnEmpty ='..tostring(self.enableOnEmpty))
	self:print('self.isEnabledChildren ='..tostring(self.isEnabledChildren))
	
	self:addTrigger()
	
	self:print('loaded EntityTrigger successfully')
	
	return self
end

function UPK_EntityTrigger:postLoad()
	UPK_EntityTrigger:superClass().postLoad(self)
	self:triggerUpdate(false,false)
	self:setEnableChildren(self.isEnabledChildren, true)
end

function UPK_EntityTrigger:triggerUpdate(vehicle,isInTrigger)
	self:print('UPK_EntityTrigger:triggerUpdate')
	if true then
		self:print('self.entitiesInTrigger='..tostring(self.entitiesInTrigger))
		if self.entitiesInTrigger>0 then
			if self.isEnabledChildren==self.enableOnEmpty then
				self:print('self:setEnableChildren '..tostring(not self.enableOnEmpty))
				self:setEnableChildren(not self.enableOnEmpty, true)
				self.isEnabledChildren=not self.enableOnEmpty
			end
		else
			self:print('self.enableOnEmpty ='..tostring(self.enableOnEmpty))
			self:print('self.isEnabledChildren ='..tostring(self.isEnabledChildren))
			self:print('self.isEnabledChildren~=self.enableOnEmpty ='..tostring(self.isEnabledChildren~=self.enableOnEmpty))
			if self.isEnabledChildren~=self.enableOnEmpty then
				self:print('self:setEnableChildren '..tostring(self.enableOnEmpty))
				self:setEnableChildren(self.enableOnEmpty, true)
				self.isEnabledChildren=self.enableOnEmpty
			end
		end
	end
end

function UPK_EntityTrigger:writeStream(streamId, connection)
	if not connection:getIsServer() then -- in connection with client
		streamWriteBool(streamId, self.isEnabledChildren)
	end
end

function UPK_EntityTrigger:readStream(streamId, connection)
	if connection:getIsServer() then -- in connection with server
		local isEnabledChildren = streamReadBool(streamId)
		self:setEnableChildren(isEnabledChildren, true)
	end
end

function UPK_EntityTrigger:loadExtraNodes(xmlFile, key)
	local isEnabledChildren = getXMLBool(xmlFile, key .. "#isEnabledChildren")
	self:print('read from save file: isEnabledChildren = '..tostring(isEnabledChildren)..' ('..type(isEnabledChildren)..')')
	self.isEnabledChildren = Utils.getNoNil(isEnabledChildren, not self.enableOnEmpty)
	self:triggerUpdate(false,false)
	self:setEnableChildren(self.isEnabledChildren, true)
	return true
end;

function UPK_EntityTrigger:getSaveExtraNodes(nodeIdent)
	local nodes=""
	if not self.isEnabledChildren then
		nodes=nodes.." isEnabledChildren=\"false\""
	end
	return nodes
end;
