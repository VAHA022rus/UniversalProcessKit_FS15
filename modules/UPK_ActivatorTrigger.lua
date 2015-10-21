-- by mor2000

--------------------
-- ActivatorTrigger (enables children if keypressed)

local UPK_ActivatorTrigger_mt = ClassUPK(UPK_ActivatorTrigger,UniversalProcessKit)
InitObjectClass(UPK_ActivatorTrigger, "UPK_ActivatorTrigger")
UniversalProcessKit.addModule("activatortrigger",UPK_ActivatorTrigger)

UPK_ActivatorTrigger.MODE_SWITCH=1
UPK_ActivatorTrigger.MODE_BUTTON=2
UPK_ActivatorTrigger.MODE_ONETIME=3

function UPK_ActivatorTrigger:new(nodeId, parent)
	printFn('UPK_ActivatorTrigger:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId, parent, UPK_ActivatorTrigger_mt)
	registerObjectClassName(self, "UPK_ActivatorTrigger")
	
	self.isActive=getBoolFromUserAttribute(nodeId, "isActive", false)
	
	-- activateInput
	
	self.activateInputBinding = 'ACTIVATE_OBJECT'
	local activeInput = getStringFromUserAttribute(nodeId, "activateInput", self.activateInputBinding)
	if not InputBinding[activateInput] then
		self:printErr('unknown input "',isInputSet,'" - using "ACTIVATE_OBJECT" for now')
	else
		self.activateInputBinding=activateInput
	end
	
	-- texts
	
	self.activateText = returnNilIfEmptyString(self.i18n[getStringFromUserAttribute(nodeId, "activateText")]) or "[activateText]"
	self.deactivateText = returnNilIfEmptyString(self.i18n[getStringFromUserAttribute(nodeId, "deactivateText")]) or "[deactivateText]"
	
	-- general mode
	
	local mode = getStringFromUserAttribute(nodeId, "mode")
	if mode=="button" then
		self.mode=UPK_ActivatorTrigger.MODE_BUTTON
	elseif mode=="one-time" then
		self.mode=UPK_ActivatorTrigger.MODE_ONETIME
		self.onetimeused = false
	else
		self.mode=UPK_ActivatorTrigger.MODE_SWITCH
	end
	
	-- actions
	
	self:getActionUserAttributes('OnActivate',true,false)
	self:getActionUserAttributes('OnDeactivate',false,true)
	
	--

	self.keyFunctionRegistered=false

	self:addTrigger()

	self:printFn('UPK_ActivatorTrigger:new done')
	
	return self
end

function UPK_ActivatorTrigger:delete()
	self:printFn('UPK_ActivatorTrigger:delete()')
	UniversalProcessKitListener.unregisterKeyFunction(self.activateInputBinding,self)
	UPK_ActivatorTrigger:superClass().delete(self)
end

function UPK_ActivatorTrigger:postLoad()
	self:printFn('UPK_ActivatorTrigger:postLoad()')
	
	--self:triggerUpdate(false,false)
	if self.isActive then
		self:operateAction('OnActivate')
	else
		self:operateAction('OnDeactivate')
	end
	
	UPK_ActivatorTrigger:superClass().postLoad(self)
end

function UPK_ActivatorTrigger:writeStream(streamId, connection)
	self:printFn('UPK_ActivatorTrigger:writeStream(',streamId,', ',connection,')')
	UPK_ActivatorTrigger:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		if self.mode==UPK_ActivatorTrigger.MODE_ONETIME then
			streamWriteBool(self.onetimeused)
		end
		self:printInfo('write to stream self.isActive = ',self.isActive)
		streamWriteBool(streamId,self.isActive)
	end
end;

function UPK_ActivatorTrigger:readStream(streamId, connection)
	self:printFn('UPK_ActivatorTrigger:readStream(',streamId,', ',connection,')')
	UPK_ActivatorTrigger:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		if self.mode==UPK_ActivatorTrigger.MODE_ONETIME then
			self.onetimeused = streamReadBool(streamId)
		end
		local isActive = streamReadBool(streamId)
		self:printInfo('read from stream self.isActive = ',isActive)
		self:setIsActive(isActive,true)
	end
end;

function UPK_ActivatorTrigger:triggerUpdate(vehicle,isInTrigger)
	self:printFn('UPK_ActivatorTrigger:triggerUpdate(',vehicle,', ',isInTrigger,')')
	if self.isClient then
		if self.isEnabled then
			self:printAll('self.entitiesInTrigger=',self.entitiesInTrigger)
			if self.entitiesInTrigger>0 and self:getShowInfo() then
				if not self.onetimeused and not self.keyFunctionRegistered then
					self:printAll('registerKeyFunction')
					if self.isActive and self.mode~=UPK_ActivatorTrigger.MODE_BUTTON then
						UniversalProcessKitListener.registerKeyFunction(self.activateInputBinding,self,'inputCallback',self.deactivateText)
					else
						UniversalProcessKitListener.registerKeyFunction(self.activateInputBinding,self,'inputCallback',self.activateText)
					end
					self.keyFunctionRegistered=true
				end
			else
				if self.keyFunctionRegistered then
					self:printAll('unregisterKeyFunction')
					UniversalProcessKitListener.unregisterKeyFunction(self.activateInputBinding,self)
					self.keyFunctionRegistered=false
				end
			end
		else
			UniversalProcessKitListener.unregisterKeyFunction(self.activateInputBinding,self)
			self.keyFunctionRegistered=false
		end
	end
end

function UPK_ActivatorTrigger:setEnable(isEnabled,alreadySent)
	self:printFn('UPK_ActivatorTrigger:setEnable(',isEnabled,', ',alreadySent,')')
	UPK_ActivatorTrigger:superClass().setEnable(self,isEnabled,alreadySent)
	self:triggerUpdate()
end;

function UPK_ActivatorTrigger:setIsActive(isActive,alreadySent)
	self:printFn('UPK_ActivatorTrigger:setIsActive(',isActive,', ',alreadySent,')')
	if self.onetimeused then
		UniversalProcessKitListener.unregisterKeyFunction(self.activateInputBinding,self)
		return
	end
	if isActive~=nil then
		self.isActive=isActive
		if self.isActive then
			self:operateAction('OnActivate')
			if self.mode~=UPK_ActivatorTrigger.MODE_BUTTON then
				UniversalProcessKitListener.updateKeyFunctionDisplayText(self.activateInputBinding,self,self.deactivateText)
			end
		else
			self:operateAction('OnDeactivate')
			UniversalProcessKitListener.updateKeyFunctionDisplayText(self.activateInputBinding,self,self.activateText)
		end
		
		if not alreadySent then
			self:sendEvent(UniversalProcessKitEvent.TYPE_ACTIVATOR, self.isActive)
		end
	end
end

function UPK_ActivatorTrigger:eventCallback(eventType,...)
	self:printFn('UPK_ActivatorTrigger:eventCallback(',eventType,',...)')
	if eventType==UniversalProcessKitEvent.TYPE_ACTIVATOR then
		self:printAll('UniversalProcessKitEvent.TYPE_ACTIVATOR')
		isActive = ...
		self:setIsActive(isActive, true)
	end
end

function UPK_ActivatorTrigger:inputCallback(inputName)
	self:printFn('UPK_ActivatorTrigger:inputCallback(',inputName,')')
	if self.activateInputBinding==inputName then
		if self.mode==UPK_ActivatorTrigger.MODE_BUTTON then
			self:setIsActive(true, false)
		elseif not self.onetimeused then
			self:setIsActive(not self.isActive, false)
			if self.mode==UPK_ActivatorTrigger.MODE_ONETIME then
				self.onetimeused = true
			end
		end
	end
end

function UPK_ActivatorTrigger:loadExtraNodes(xmlFile, key)
	self:printFn('UPK_ActivatorTrigger:loadExtraNodes(',xmlFile,', ',key,')')
	self.isActive=Utils.getNoNil(getXMLBool(xmlFile, key .. "#isActive"), false)
	self.onetimeused=getXMLBool(xmlFile, key .. "#onetimeused")
	return true
end;

function UPK_ActivatorTrigger:getSaveExtraNodes(nodeIdent)
	self:printFn('UPK_ActivatorTrigger:getSaveExtraNodes(',nodeIdent,')')
	local nodes=""
	if self.isActive then
		nodes=nodes.." isActive=\"true\""
	end
	if self.mode==UPK_ActivatorTrigger.MODE_ONETIME then
		nodes=nodes.." onetimeused=\""..tostring(self.onetimeused).."\""
	end
	return nodes
end;

