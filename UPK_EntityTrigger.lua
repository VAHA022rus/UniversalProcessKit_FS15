-- by mor2000

--------------------
-- EntityTrigger (enables modules if vehicle or walker is present)


local UPK_EntityTrigger_mt = ClassUPK(UPK_EntityTrigger,UniversalProcessKit)
InitObjectClass(UPK_EntityTrigger, "UPK_EntityTrigger")
UniversalProcessKit.addModule("entitytrigger",UPK_EntityTrigger)

function UPK_EntityTrigger:new(nodeId, parent)
	printFn('UPK_EntityTrigger:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId, parent, UPK_EntityTrigger_mt)
	registerObjectClassName(self, "UPK_EntityTrigger")
	
	self.enableOnEmpty = getBoolFromUserAttribute(nodeId, "enableOnEmpty", false)
	
	self:printAll('self.enableOnEmpty ='..tostring(self.enableOnEmpty))
	self:printAll('self.isEnabledChildren ='..tostring(self.isEnabledChildren))
	
	self:addTrigger()
	
	self:printFn('UPK_EntityTrigger:now done')
	
	return self
end

function UPK_EntityTrigger:postLoad()
	self:printFn('UPK_EntityTrigger:postLoad()')
	UPK_EntityTrigger:superClass().postLoad(self)
	self:triggerUpdate(false,false)
	self:setEnableChildren(self.isEnabledChildren, true)
end

function UPK_EntityTrigger:triggerUpdate(vehicle,isInTrigger)
	self:printFn('UPK_EntityTrigger:triggerUpdate(',vehicle,', ',isInTrigger,')')
	if self.isEnabled then
		self:printAll('self.entitiesInTrigger=',self.entitiesInTrigger)
		if self.entitiesInTrigger>0 then
			if self.isEnabledChildren==self.enableOnEmpty then
				self:printAll('self:setEnableChildren ',not self.enableOnEmpty)
				self:setEnableChildren(not self.enableOnEmpty, true)
				self.isEnabledChildren=not self.enableOnEmpty
			end
		else
			self:printAll('self.enableOnEmpty =',self.enableOnEmpty)
			self:printAll('self.isEnabledChildren =',self.isEnabledChildren)
			self:printAll('self.isEnabledChildren~=self.enableOnEmpty =',(self.isEnabledChildren~=self.enableOnEmpty))
			if self.isEnabledChildren~=self.enableOnEmpty then
				self:printAll('self:setEnableChildren ',self.enableOnEmpty)
				self:setEnableChildren(self.enableOnEmpty, true)
				self.isEnabledChildren=self.enableOnEmpty
			end
		end
	end
end

function UPK_EntityTrigger:writeStream(streamId, connection)
	self:printFn('UPK_EntityTrigger:writeStream(',streamId,', ',connection,')')
	if not connection:getIsServer() then -- in connection with client
		streamWriteBool(streamId, self.isEnabledChildren)
	end
end

function UPK_EntityTrigger:readStream(streamId, connection)
	self:printFn('UPK_EntityTrigger:readStream(',streamId,', ',connection,')')
	if connection:getIsServer() then -- in connection with server
		local isEnabledChildren = streamReadBool(streamId)
		self:setEnableChildren(isEnabledChildren, true)
	end
end

function UPK_EntityTrigger:loadExtraNodes(xmlFile, key)
	self:printFn('UPK_EntityTrigger:loadExtraNodes(',xmlFile,', ',key,')')
	local isEnabledChildren = getXMLBool(xmlFile, key .. "#isEnabledChildren")
	self:printAll('read from save file: isEnabledChildren = ',isEnabledChildren,' ('..type(isEnabledChildren)..')')
	self.isEnabledChildren = Utils.getNoNil(isEnabledChildren, not self.enableOnEmpty)
	self:triggerUpdate(false,false)
	self:setEnableChildren(self.isEnabledChildren, true)
	return true
end;

function UPK_EntityTrigger:getSaveExtraNodes(nodeIdent)
	self:printFn('UPK_EntityTrigger:getSaveExtraNodes(',nodeIdent,')')
	local nodes=""
	if not self.isEnabledChildren then
		nodes=nodes.." isEnabledChildren=\"false\""
	end
	return nodes
end;
