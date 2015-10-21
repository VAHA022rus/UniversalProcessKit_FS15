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
		self.actions['OnEmpty']['enableChildren']=enableOnEmpty
		self.actions['OnEmpty']['disableChildren']=not enableOnEmpty
		self.actions['OnPopulated']['enableChildren']=not enableOnEmpty
		self.actions['OnPopulated']['disableChildren']=enableOnEmpty
	end
	
	self.isPopulated=false
	
	self:getActionUserAttributes('OnEnter')
	self:getActionUserAttributes('OnLeave')

	self:addTrigger()
	
	self:printFn('UPK_EntityTrigger:new done')
	
	return self
end

function UPK_EntityTrigger:postLoad()
	self:printFn('UPK_EntityTrigger:postLoad()')
	
	if self.isPopulated then
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
		self:printAll('self.entitiesInTrigger=',self.entitiesInTrigger,' self.isPopulated=',self.isPopulated)
		if self.entitiesInTrigger>0 and not self.isPopulated then
			self:setIsPopulated(true)
		elseif self.entitiesInTrigger==0 and self.isPopulated then
			self:setIsPopulated(false)
		end
	end
end

function UPK_EntityTrigger:writeStream(streamId, connection)
	self:printFn('UPK_EntityTrigger:writeStream(',streamId,', ',connection,')')
	if not connection:getIsServer() then -- in connection with client
		streamWriteBool(streamId, self.isPopulated)
	end
end

function UPK_EntityTrigger:readStream(streamId, connection)
	self:printFn('UPK_EntityTrigger:readStream(',streamId,', ',connection,')')
	if connection:getIsServer() then -- in connection with server
		self.isPopulated = streamReadBool(streamId)
	end
end

function UPK_EntityTrigger:setIsPopulated(isPopulated)
	self:printFn('UPK_EntityTrigger:setIsPopulated(',isPopulated,')')
	if isPopulated~=self.isPopulated then
		if isPopulated==false then
			self.isPopulated=false
			self:operateAction('OnEmpty')
		elseif isPopulated==true then
			self.isPopulated=true
			self:operateAction('OnPopulated')
		end
	end
end

function UPK_EntityTrigger:loadExtraNodes(xmlFile, key)
	self:printFn('UPK_EntityTrigger:loadExtraNodes(',xmlFile,', ',key,')')
	self.isPopulated = getXMLBool(xmlFile, key .. "#isPopulated") or false
	return true
end;

function UPK_EntityTrigger:getSaveExtraNodes(nodeIdent)
	self:printFn('UPK_EntityTrigger:getSaveExtraNodes(',nodeIdent,')')
	local nodes=""
	nodes=nodes..' isPopulated="'..tostring(self.isPopulated)..'"'
	return nodes
end;
