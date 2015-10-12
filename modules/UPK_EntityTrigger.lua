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
	
	-- actions
	
	self:getActionUserAttributes('OnEmpty')
	self:getActionUserAttributes('OnPopulated')
	
	local enableOnEmpty = getUserAttribute(nodeId, "enableOnEmpty")
	if enableOnEmpty==true or enableOnEmpty==false then
		self:printInfo('use enableChildrenOnEmpty instead of enableOnEmpty (out-dated)')
		local action=self.actions['OnEmpty']
		action['enableChildren']=enableOnEmpty
		action['disableChildren']=not enableOnEmpty
		action['enable']={}
	end
	
	self.isTriggered=false
	
	self:getActionUserAttributes('OnEnter')
	self:getActionUserAttributes('OnLeave')

	self:addTrigger()
	
	self:printFn('UPK_EntityTrigger:now done')
	
	return self
end

function UPK_EntityTrigger:postLoad()
	self:printFn('UPK_EntityTrigger:postLoad()')
	
	if self.isTriggered then
		self:operateAction('OnEmpty')
	else
		self:operateAction('OnPopulated')
	end
	
	UPK_EntityTrigger:superClass().postLoad(self)
end

function UPK_EntityTrigger:triggerUpdate(vehicle,isInTrigger)
	self:printFn('UPK_EntityTrigger:triggerUpdate(',vehicle,', ',isInTrigger,')')
	if self.isEnabled then
		if isInTrigger then
			self:operateAction('OnEnter')
		else
			self:operateAction('OnLeave')
		end
		self:printAll('self.entitiesInTrigger=',self.entitiesInTrigger)
		if self.entitiesInTrigger>0 and not self.isTriggered then
			self:operateAction('OnPopulated')
		elseif self.entitiesInTrigger==0 and self.isTriggered then
			self:operateAction('OnEmpty')
		end
	end
end

function UPK_EntityTrigger:writeStream(streamId, connection)
	self:printFn('UPK_EntityTrigger:writeStream(',streamId,', ',connection,')')
	if not connection:getIsServer() then -- in connection with client
		streamWriteBool(streamId, self.isTriggered)
	end
end

function UPK_EntityTrigger:readStream(streamId, connection)
	self:printFn('UPK_EntityTrigger:readStream(',streamId,', ',connection,')')
	if connection:getIsServer() then -- in connection with server
		self.isTriggered = streamReadBool(streamId)
	end
end

function UPK_EntityTrigger:loadExtraNodes(xmlFile, key)
	self:printFn('UPK_EntityTrigger:loadExtraNodes(',xmlFile,', ',key,')')
	self.isTriggered = getXMLBool(xmlFile, key .. "#isTriggered") or false
	return true
end;

function UPK_EntityTrigger:getSaveExtraNodes(nodeIdent)
	self:printFn('UPK_EntityTrigger:getSaveExtraNodes(',nodeIdent,')')
	local nodes=""
	nodes=nodes..' isTriggered="'..tostring(self.isTriggered)..'"'
	return nodes
end;
